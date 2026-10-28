import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/data/user_collections_repository.dart';
import '../domain/weekly_schedule.dart';
import '../domain/activity_schedule.dart';
import 'session_completion_proof.dart';

/// Deferred includes quarantine/hold. Do not change local bytes or outbox/CAS
/// while the profile has an unapplied server snapshot, even if locally readable.
Future<void> assertScheduleWritable(
  AppDatabase db,
  String profileSyncId,
) async {
  final deferred =
      await (db.select(db.syncDeferredRecords)..where(
            (r) =>
                r.entityType.equals('profile') &
                r.entityId.equals(profileSyncId),
          ))
          .getSingleOrNull();
  if (deferred != null) {
    throw StateError(
      'Harmonogram oczekuje na rozwiązanie konfliktu synchronizacji.',
    );
  }
}

enum ScheduleCompletion { planned, completed, invalidated, conflict }

/// Owns profile definitions only. Never writes workout sessions, sets or PRs.
class ScheduleRepository {
  ScheduleRepository(this.db, {this.authority});
  final AppDatabase db;
  final CachedAuthWriteAuthority? authority;
  UserCollectionsRepository get _collections =>
      UserCollectionsRepository(db, authority: authority);
  SessionCompletionProof get _proof => SessionCompletionProof(db, _collections);

  Future<WeeklySchedule> load(
    String account, {
    bool Function()? isCurrent,
  }) async => WeeklySchedule.fromJson(
    await _collections.load(account, 'weeklySchedule', isCurrent: isCurrent),
  );

  Future<T> _write<T>(
    String account,
    Future<T> Function(WeeklySchedule schedule, bool Function() guard) edit,
    bool Function()? isCurrent,
  ) {
    final epoch = authority?.epoch;
    bool guard() => epoch == authority?.epoch && (isCurrent?.call() ?? true);
    return db.transaction(() async {
      final schedule = await load(account, isCurrent: guard);
      final profile = (await db.userProfileDao.watchProfileOnce())!;
      await assertScheduleWritable(db, profile.syncId);
      final result = await edit(schedule, guard);
      await load(account, isCurrent: guard);
      return result;
    });
  }

  Future<void> _put(
    String account,
    Map<String, dynamic> entry,
    bool Function() guard,
  ) => _collections.update(account, 'weeklySchedule', (entries) {
    entries.removeWhere((e) => e['id'] == entry['id']);
    entries.add(entry);
  }, isCurrent: guard);

  Future<String> addRule(
    String account, {
    required String planSyncId,
    required String name,
    required int weekday,
    required CalendarDay effectiveFrom,
    bool Function()? isCurrent,
  }) => _write(account, (schedule, guard) async {
    final plan =
        await (db.select(db.workoutPlans)..where(
              (p) => p.syncId.equals(planSyncId) & p.deletedAtUtc.isNull(),
            ))
            .getSingleOrNull();
    if (plan == null) {
      throw StateError(
        'Plan jest niedostępny. Wybierz istniejący zapisany plan.',
      );
    }
    final id = const Uuid().v4();
    final stamp = UserCollectionsRepository.nextTimestamp(null);
    await _put(account, {
      'id': id,
      'name': name,
      'kind': 'rule',
      'createdAtUtc': stamp,
      'updatedAtUtc': stamp,
      'planSyncId': planSyncId,
      'weekday': weekday,
      'effectiveFromDate': effectiveFrom.value,
    }, guard);
    return id;
  }, isCurrent);

  Future<void> deleteRule(
    String account,
    String ruleId, {
    bool Function()? isCurrent,
  }) => _write(account, (schedule, guard) async {
    final e = schedule.entries
        .where((e) => e['id'] == ruleId && e['kind'] == 'rule')
        .firstOrNull;
    if (e == null || e['deletedAtUtc'] != null) return;
    final stamp = UserCollectionsRepository.nextTimestamp(e);
    await _put(account, {
      ...e,
      'updatedAtUtc': stamp,
      'deletedAtUtc': stamp,
    }, guard);
  }, isCurrent);

  /// Reload identity inside SQLite, not the stale UI snapshot. An exception
  /// snapshot remains authoritative after its recurrence is changed/deleted.
  ScheduleOccurrence _current(
    WeeklySchedule schedule,
    ScheduleOccurrence requested,
  ) {
    final current = schedule
        .between(requested.date, requested.date)
        .where((o) => o.id == requested.id)
        .firstOrNull;
    if (current == null ||
        current.isCompleted ||
        requested.sourceRevision == null ||
        current.mutationBaseline != requested.mutationBaseline) {
      throw StateError(
        'Wystąpienie zmieniło się, jest już zaliczone lub niedostępne. Odśwież harmonogram i ponów akcję.',
      );
    }
    return current;
  }

  Map<String, dynamic> _override(
    WeeklySchedule schedule,
    ScheduleOccurrence o, {
    required CalendarDay date,
    String? session,
    bool externalCompleted = false,
  }) {
    final old = schedule.entries.where((e) => e['id'] == o.id).firstOrNull;
    final stamp = UserCollectionsRepository.nextTimestamp(old);
    return {
      'id': o.id,
      'name': o.name,
      'kind': o.isActivity ? 'activityOverride' : 'override',
      'createdAtUtc': old?['createdAtUtc'] ?? stamp,
      'updatedAtUtc': stamp,
      'ruleId': o.ruleId,
      'originalDate': o.originalDate.value,
      'movedDate': date.value,
      'state': session == null && !externalCompleted ? 'planned' : 'completed',
      if (session != null) 'sessionSyncId': session,
      'ruleSnapshot': o.ruleSnapshot,
    };
  }

  Future<void> move(
    String account,
    ScheduleOccurrence occurrence,
    CalendarDay date, {
    bool Function()? isCurrent,
  }) => _write(account, (schedule, guard) async {
    final o = _current(schedule, occurrence);
    await _put(account, _override(schedule, o, date: date), guard);
  }, isCurrent);

  Future<void> complete(
    String account,
    ScheduleOccurrence occurrence,
    String sessionSyncId, {
    bool Function()? isCurrent,
  }) => _write(account, (schedule, guard) async {
    final o = _current(schedule, occurrence);
    if (o.activityType != ActivityType.fitbirek) {
      throw StateError(
        'Aktywność zewnętrzna wymaga ręcznego potwierdzenia, nie sesji.',
      );
    }
    if (await _proof.references(account, sessionSyncId, isCurrent: guard) > 0) {
      throw StateError(
        'Ta sesja zalicza już inne wystąpienie. Wybierz inną sesję.',
      );
    }
    if (!await _proof.isActual(sessionSyncId)) {
      throw StateError(
        'Wybierz zakończoną, nieusuniętą sesję z co najmniej jedną serią roboczą (także historyczną bez roli).',
      );
    }
    // Both proof and ownership are captured in this write transaction.
    await load(account, isCurrent: guard);
    await _put(
      account,
      _override(schedule, o, date: o.date, session: sessionSyncId),
      guard,
    );
  }, isCurrent);

  Future<void> completeExternal(
    String account,
    ScheduleOccurrence occurrence, {
    bool Function()? isCurrent,
  }) => _write(account, (schedule, guard) async {
    final o = _current(schedule, occurrence);
    if (o.activityType != ActivityType.external) {
      throw StateError(
        'Trening FitBirek wymaga rzeczywistej zakończonej sesji.',
      );
    }
    await _put(
      account,
      _override(schedule, o, date: o.date, externalCompleted: true),
      guard,
    );
  }, isCurrent);

  Future<ScheduleCompletion> completionStatus(
    String account,
    ScheduleOccurrence o,
  ) async {
    await load(account);
    if (o.externalCompleted) return ScheduleCompletion.completed;
    if (o.sessionSyncId == null) return ScheduleCompletion.planned;
    final duplicates = await _proof.references(account, o.sessionSyncId!);
    if (duplicates > 1) return ScheduleCompletion.conflict;
    return await _proof.isActual(o.sessionSyncId!)
        ? ScheduleCompletion.completed
        : ScheduleCompletion.invalidated;
  }
}
