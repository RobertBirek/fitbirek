"""Read-only, bounded adapter of the client's weeklySchedule v1 wire format.

No domain records or consent are inferred/written here. All datetimes delivered
to the queue are UTC instants; gaps are skipped and folds use the first instant.
"""
import hashlib
import json
import re
from datetime import date, datetime, time, timedelta, timezone
from uuid import UUID, uuid5
from zoneinfo import ZoneInfo

from sqlalchemy import select
from app.sync.models import SyncRecord

WARSAW = ZoneInfo('Europe/Warsaw')
SOURCES = {'karate': 'legacyKarate', 'training': 'legacyTraining'}


def uuid(value):
    if not isinstance(value, str) or not re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', value):
        raise ValueError('UUID')
    return UUID(value)


def day(value):
    if not isinstance(value, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', value):
        raise ValueError('date')
    return date.fromisoformat(value)


def stamp(value):
    if not isinstance(value, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z', value):
        raise ValueError('UTC stamp')
    return datetime.fromisoformat(value[:-1] + '+00:00')


def plain(value, limit):
    return (isinstance(value, str) and bool(value.strip()) and 1 <= len(value) <= limit
            and not any(ord(c) < 32 or 127 <= ord(c) <= 159 for c in value))


def fields(r, activity=True):
    if not isinstance(r, dict):
        raise ValueError('rule')
    day(r.get('effectiveFromDate'))
    if not activity:
        uuid(r.get('planSyncId'))
        if type(r.get('weekday')) is not int or not 1 <= r['weekday'] <= 7:
            raise ValueError('weekday')
        return
    days = r.get('weekdays')
    if (r.get('activityType') not in ('external', 'fitbirek') or not isinstance(days, list)
            or not days or any(type(d) is not int or not 1 <= d <= 7 for d in days)
            or len(set(days)) != len(days) or r.get('timeZone') != 'Europe/Warsaw'
            or not isinstance(r.get('time'), str) or not re.fullmatch(r'(?:[01]\d|2[0-3]):[0-5]\d', r['time'])
            or type(r.get('enabled')) is not bool or type(r.get('reminderEnabled')) is not bool
            or type(r.get('reminderMinutesBefore')) is not int or not 0 <= r['reminderMinutesBefore'] <= 1440):
        raise ValueError('activity fields')
    duration = r.get('durationMinutes')
    if duration is not None and (type(duration) is not int or not 1 <= duration <= 1440):
        raise ValueError('duration')
    if r.get('planSyncId') is not None:
        uuid(r['planSyncId'])
        if r['activityType'] != 'fitbirek':
            raise ValueError('external plan')
    if r.get('legacySource') is not None and r['legacySource'] not in SOURCES.values():
        raise ValueError('source')


def validate(raw):
    if (not isinstance(raw, dict) or type(raw.get('version')) is not int or raw['version'] != 1
            or not isinstance(raw.get('entries'), list) or len(raw['entries']) > 500
            or len(json.dumps(raw, ensure_ascii=False, separators=(',', ':')).encode()) > 262144):
        raise ValueError('collection')
    ids = set()
    for e in raw['entries']:
        if not isinstance(e, dict):
            raise ValueError('entry')
        identifier = uuid(e.get('id'))
        if identifier in ids or not plain(e.get('name'), 80):
            raise ValueError('envelope')
        ids.add(identifier)
        created = stamp(e.get('createdAtUtc'))
        updated = stamp(e.get('updatedAtUtc'))
        if updated < created:
            raise ValueError('revision')
        if e.get('deletedAtUtc') is not None:
            if stamp(e['deletedAtUtc']) > updated:
                raise ValueError('tombstone revision')
        kind = e.get('kind')
        if kind in ('rule', 'activityRule'):
            fields(e, kind == 'activityRule')
        elif kind in ('override', 'activityOverride'):
            rid = uuid(e.get('ruleId'))
            original = day(e.get('originalDate'))
            day(e.get('movedDate'))
            snapshot = e.get('ruleSnapshot')
            fields(snapshot, kind == 'activityOverride')
            days = snapshot['weekdays'] if kind == 'activityOverride' else [snapshot['weekday']]
            if (identifier != uuid5(rid, original.isoformat()) or original.isoweekday() not in days
                    or original < day(snapshot['effectiveFromDate']) or e.get('state') not in ('planned', 'completed')):
                raise ValueError('override')
            requires_session = e['state'] == 'completed' and snapshot.get('activityType', 'fitbirek') == 'fitbirek'
            if requires_session:
                uuid(e.get('sessionSyncId'))
            elif e.get('sessionSyncId') is not None:
                raise ValueError('session')
        else:
            raise ValueError('kind')
    return raw['entries']


async def profile(database, user_id):
    rows = list(await database.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.entity_type == 'profile', SyncRecord.deleted_at.is_(None),
    ).execution_options(populate_existing=True).limit(2)))
    # Ambiguous profiles are not guessed by timestamp or another user's UUID.
    return rows[0] if len(rows) == 1 else None


def events(record, now):
    """Return (legacy categories suppressed, eligible dynamic queue messages)."""
    if record is None:
        return set(), []
    raw = record.payload.get('weeklySchedule') if isinstance(record.payload, dict) else None
    if raw is None:
        return set(), []
    # Presence markers are authoritative even if a future codec cannot read it.
    suppressed = set()
    if isinstance(raw, dict) and isinstance(raw.get('entries'), list):
        for category, source in SOURCES.items():
            marker = str(uuid5(record.entity_id, f'FitBirek/activity/{source}'))
            if any(isinstance(e, dict) and e.get('id') == marker for e in raw['entries']):
                suppressed.add(category)
    try:
        entries = validate(raw)
    except (ValueError, TypeError, OverflowError):
        return suppressed, []
    live = {e['id']: e for e in entries if not e.get('deletedAtUtc')}
    overrides = {e['id']: e for e in entries if e['kind'] == 'activityOverride'}
    result = []
    local = now.astimezone(WARSAW).date()
    for r in live.values():
        if r['kind'] != 'activityRule' or not r['enabled'] or not r['reminderEnabled']:
            continue
        candidates = {date.fromordinal(ordinal) for d in (-1, 0, 1, 2)
                      if date.min.toordinal() <= (ordinal := local.toordinal() + d) <= date.max.toordinal()}
        candidates.update(day(o['originalDate']) for o in overrides.values()
                          if o['ruleId'] == r['id'] and not o.get('deletedAtUtc'))
        for original in candidates:
            oid = str(uuid5(UUID(r['id']), original.isoformat()))
            override = overrides.get(oid)
            if override and override.get('deletedAtUtc'):
                override = None
            snapshot = override['ruleSnapshot'] if override else r
            if override and override['state'] != 'planned':
                continue
            if (not snapshot['enabled'] or not snapshot['reminderEnabled']
                    or original < day(snapshot['effectiveFromDate']) or original.isoweekday() not in snapshot['weekdays']):
                continue
            target = day(override['movedDate']) if override else original
            wall = datetime.combine(target, time.fromisoformat(snapshot['time']))
            start = wall.replace(tzinfo=WARSAW, fold=0)
            try:
                utc_start = start.astimezone(timezone.utc)
                if utc_start.astimezone(WARSAW).replace(tzinfo=None) != wall:
                    continue  # nonexistent spring wall time: never silently shift it
                due = utc_start - timedelta(minutes=snapshot['reminderMinutesBefore'])
            except OverflowError:
                # A valid wall date (e.g. 0001-01-01) can map to UTC year0,
                # or its lead can cross that boundary. Skip only this occurrence;
                # retain migration suppression and independent rules/profiles.
                continue
            if not timedelta(0) <= now - due < timedelta(minutes=15):
                continue
            revision = json.dumps([str(record.entity_id), r, override, original.isoformat()], sort_keys=True, ensure_ascii=False)
            key = 'activity:' + hashlib.sha256(revision.encode()).hexdigest()
            category = 'karate' if snapshot['activityType'] == 'external' else 'training'
            result.append(dict(key=key, category=category, due=due,
                               title=override['name'] if override else r['name'],
                               body=f"{snapshot['time']} · Europe/Warsaw"))
    return suppressed, result


async def valid_job(database, subscription, job, now):
    record = await profile(database, subscription.user_id)
    suppressed, current = events(record, now)
    if job.event_key.startswith('activity:'):
        return any(e['key'] == job.event_key and e['category'] == job.category for e in current)
    return not (job.category in suppressed and job.event_key.startswith(job.category + ':'))
