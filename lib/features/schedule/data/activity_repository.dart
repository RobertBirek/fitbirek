import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/user_collections.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/data/user_collections_repository.dart';
import '../domain/activity_schedule.dart';
import '../domain/weekly_schedule.dart';
import 'schedule_repository.dart';

class ActivitySnapshot {
  ActivitySnapshot._(
    this.account,
    this.profileSyncId,
    this.deviceId,
    this.epoch,
    this.schedule,
  ) : rules = List.unmodifiable(
        schedule.entries
            .where(
              (e) =>
                  ['rule', 'activityRule'].contains(e['kind']) &&
                  e['deletedAtUtc'] == null,
            )
            .map(ActivityRule.fromJson),
      );
  final String account, profileSyncId, deviceId;
  final int? epoch;
  final WeeklySchedule schedule;
  final List<ActivityRule> rules;
}

class ActivityRepository {
  ActivityRepository(this.db, {this.authority});
  final AppDatabase db;
  final CachedAuthWriteAuthority? authority;
  ScheduleRepository get _schedule =>
      ScheduleRepository(db, authority: authority);

  Future<ActivitySnapshot> snapshot(
    String account, {
    bool Function()? isCurrent,
  }) {
    final epoch = authority?.epoch;
    bool guard() => authority?.epoch == epoch && (isCurrent?.call() ?? true);
    return db.transaction(() async {
      final schedule = await _schedule.load(account, isCurrent: guard);
      final profile = (await db.userProfileDao.watchProfileOnce())!;
      final binding = (await db.syncDao.readState())!;
      await _schedule.load(account, isCurrent: guard);
      return ActivitySnapshot._(
        account,
        profile.syncId,
        binding.deviceId,
        epoch,
        schedule,
      );
    });
  }

  Future<T> _write<T>(
    ActivitySnapshot lease,
    Future<T> Function(List<Map<String, dynamic>> entries) edit,
    bool Function()? isCurrent,
  ) {
    bool guard() =>
        authority?.epoch == lease.epoch && (isCurrent?.call() ?? true);
    return db.transaction(() async {
      final fresh = await snapshot(lease.account, isCurrent: guard);
      if (fresh.profileSyncId != lease.profileSyncId ||
          fresh.deviceId != lease.deviceId) {
        throw StateError('Profil został zmieniony. Otwórz formularz ponownie.');
      }
      await assertScheduleWritable(db, fresh.profileSyncId);
      final entries = fresh.schedule.entries
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final result = await edit(entries);
      if (UserCollections.canonical(entries) ==
          UserCollections.canonical(fresh.schedule.entries)) {
        return result;
      }
      await UserCollectionsRepository(db, authority: authority).update(
        lease.account,
        'weeklySchedule',
        (target) {
          target
            ..clear()
            ..addAll(entries);
        },
        isCurrent: guard,
      );
      await _schedule.load(lease.account, isCurrent: guard);
      return result;
    });
  }

  Map<String, dynamic> _baseline(
    ActivitySnapshot lease,
    String id,
    List<Map<String, dynamic>> entries,
  ) {
    final baseline = lease.rules.where((r) => r.id == id).firstOrNull;
    final current = entries.where((e) => e['id'] == id).firstOrNull;
    if (baseline == null ||
        current == null ||
        current['deletedAtUtc'] != null ||
        UserCollections.canonical(baseline.toJson()) !=
            UserCollections.canonical(current)) {
      throw StateError('Reguła została zmieniona. Odśwież formularz.');
    }
    return current;
  }

  Future<void> _validatePlan(ActivityDraft draft) async {
    if (draft.planSyncId == null) return;
    final plan =
        await (db.select(db.workoutPlans)..where(
              (p) =>
                  p.syncId.equals(draft.planSyncId!) & p.deletedAtUtc.isNull(),
            ))
            .getSingleOrNull();
    if (plan == null) {
      throw StateError(
        'Plan jest niedostępny. Wybierz istniejący zapisany plan.',
      );
    }
  }

  Map<String, dynamic> _newEntry(ActivityDraft draft) {
    final stamp = UserCollectionsRepository.nextTimestamp(null);
    return {
      ...draft.toFields(),
      'kind': 'activityRule',
      'id': const Uuid().v4(),
      'createdAtUtc': stamp,
      'updatedAtUtc': stamp,
    };
  }

  void _tombstone(Map<String, dynamic> entry) {
    final stamp = UserCollectionsRepository.nextTimestamp(entry);
    entry
      ..['updatedAtUtc'] = stamp
      ..['deletedAtUtc'] = stamp;
  }

  Future<String> create(
    ActivitySnapshot lease,
    ActivityDraft draft, {
    bool Function()? isCurrent,
  }) => _write(lease, (entries) async {
    await _validatePlan(draft);
    final entry = _newEntry(draft);
    entries.add(entry);
    return entry['id'] as String;
  }, isCurrent);

  /// Consent is captured outside this transaction. A deterministic tombstone
  /// is a permanent migration marker, not an invitation to restore defaults.
  Future<void> seedLegacy(
    ActivitySnapshot lease, {
    required bool karate,
    required bool training,
    bool Function()? isCurrent,
  }) => _write(lease, (entries) async {
    for (final source in LegacyActivitySource.values) {
      final id = legacyActivityRuleId(lease.profileSyncId, source);
      if (entries.any((e) => e['id'] == id)) continue;
      final external = source == LegacyActivitySource.legacyKarate;
      final optedIn = external ? karate : training;
      final entry = _newEntry(
        ActivityDraft(
          name: external ? 'Karate' : 'Trening FitBirek',
          activityType: external
              ? ActivityType.external
              : ActivityType.fitbirek,
          weekdays: external ? {2, 4} : {1, 2, 3, 4, 5, 6, 7},
          time: external ? '20:00' : '18:00',
          effectiveFrom: CalendarDay.parse('1970-01-01'),
          enabled: optedIn,
          reminderEnabled: optedIn,
          reminderMinutesBefore: external ? 30 : 0,
        ),
      );
      entry['id'] = id;
      entry['legacySource'] = source.name;
      entries.add(entry);
    }
  }, isCurrent);

  Future<String> update(
    ActivitySnapshot lease,
    String ruleId,
    ActivityDraft draft, {
    bool Function()? isCurrent,
  }) => _write(lease, (entries) async {
    final old = _baseline(lease, ruleId, entries);
    await _validatePlan(draft);
    final entry = _newEntry(draft);
    _tombstone(old);
    entries.add(entry);
    return entry['id'] as String;
  }, isCurrent);

  Future<void> delete(
    ActivitySnapshot lease,
    String ruleId, {
    bool Function()? isCurrent,
  }) => _write(lease, (entries) async {
    _tombstone(_baseline(lease, ruleId, entries));
  }, isCurrent);

  /// Replace identity even for enable toggles; saved override snapshots must
  /// never inherit a changed enabled flag (or any other changed rule field).
  Future<String> setEnabled(
    ActivitySnapshot lease,
    String ruleId,
    bool enabled, {
    bool Function()? isCurrent,
  }) => _write(lease, (entries) async {
    final old = _baseline(lease, ruleId, entries);
    if (old['kind'] == 'rule') {
      throw StateError('Najpierw edytuj starszą regułę i wybierz godzinę.');
    }
    if ((old['enabled'] != false) == enabled) return ruleId;
    final stamp = UserCollectionsRepository.nextTimestamp(old);
    final replacement = {
      ...old,
      'id': const Uuid().v4(),
      'enabled': enabled,
      'createdAtUtc': stamp,
      'updatedAtUtc': stamp,
    }..remove('legacySource');
    _tombstone(old);
    entries.add(replacement);
    return replacement['id'] as String;
  }, isCurrent);
}
