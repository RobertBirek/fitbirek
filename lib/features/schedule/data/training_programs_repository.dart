import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/exercise.dart';
import '../../../core/sync/user_collections.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/data/user_collections_repository.dart';
import '../../exercises/domain/exercise_catalog_metadata.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/domain/plan_catalog_validation.dart';
import '../domain/training_program.dart';
import '../domain/training_program_schedule.dart';
import '../domain/weekly_schedule.dart';
import 'schedule_repository.dart';
import 'session_completion_proof.dart';

/// Read-only modal lease, including explicit absence for creation. No pending
/// profile write/session is created until the user's confirmed command.
class ProgramLease {
  ProgramLease._(this.accountId, this.epoch, this.deviceId, this.profileSyncId,
    this.programId, this.baseline);
  final String accountId, profileSyncId;
  final String? deviceId, programId, baseline;
  final int? epoch;
}

class TrainingProgramsRepository {
  TrainingProgramsRepository(this.db, {this.authority, CalendarDay Function()? today})
      : today = today ?? (() => CalendarDay.local(DateTime.now()));
  final AppDatabase db;
  final CachedAuthWriteAuthority? authority;
  final CalendarDay Function() today;
  UserCollectionsRepository get _collections => UserCollectionsRepository(db, authority: authority);
  SessionCompletionProof get proof => SessionCompletionProof(db, _collections);

  Future<TrainingPrograms> load(String account, {bool Function()? isCurrent}) async =>
      TrainingPrograms.fromJson(await _collections.load(account, 'trainingPrograms', isCurrent: isCurrent));

  /// Serialized reads here deliberately perform no writes. The same account,
  /// profile and binding guards apply to start validation and all mutations.
  Future<T> _access<T>(String account,
    Future<T> Function(TrainingPrograms, UserProfileData, String?, bool Function()) action,
    {bool Function()? isCurrent, bool writable = true}) {
    final epoch = authority?.epoch;
    bool guard() => epoch == authority?.epoch && (isCurrent?.call() ?? true);
    return db.transaction(() async {
      final programs = await load(account, isCurrent: guard);
      final profile = (await db.userProfileDao.watchProfileOnce())!;
      final binding = await db.syncDao.readState();
      if (writable) await assertScheduleWritable(db, profile.syncId);
      final result = await action(programs, profile, binding?.deviceId, guard);
      await load(account, isCurrent: guard);
      final after = await db.userProfileDao.watchProfileOnce();
      final state = await db.syncDao.readState();
      if (!guard() || after?.syncId != profile.syncId ||
          state?.accountId != binding?.accountId ||
          state?.deviceId != binding?.deviceId || state?.offlineAccess != true) {
        throw StateError('Konto lub profil zmieniły się. Otwórz program ponownie.');
      }
      return result;
    });
  }

  Map<String, dynamic> _program(TrainingPrograms programs, String id) {
    final p = programs.entries.where((e) => e['id'] == id &&
      e['kind'] == 'program' && e['deletedAtUtc'] == null).firstOrNull;
    if (p == null) throw StateError('Program jest niedostępny.');
    return p;
  }

  Future<ProgramLease> open(String account, {String? programId, bool Function()? isCurrent}) =>
      _access(account, (programs, profile, device, guard) async => ProgramLease._(
        account, authority?.epoch, device, profile.syncId, programId,
        programId == null ? null : UserCollections.canonical(_program(programs, programId)),
      ), isCurrent: isCurrent);

  void _checkLease(ProgramLease lease, TrainingPrograms programs, UserProfileData profile, String? device) {
    if (lease.epoch != authority?.epoch || device != lease.deviceId ||
        profile.syncId != lease.profileSyncId ||
        (lease.programId != null && UserCollections.canonical(_program(programs, lease.programId!)) != lease.baseline)) {
      throw StateError('Program lub konto zmieniły się. Otwórz formularz ponownie.');
    }
  }

  Future<void> _put(String account, Map<String, dynamic> entry, bool Function() guard) =>
      _collections.update(account, 'trainingPrograms', (entries) {
        entries.removeWhere((e) => e['id'] == entry['id']); entries.add(entry);
      }, isCurrent: guard);

  /// No generator fallback; also checks deferred/quarantined template leases.
  Future<void> validatePlan(String syncId, List<Exercise> catalog, ExerciseCatalogMetadata metadata) async {
    final planner = PlannerRepository(db);
    final row = await planner.snapshot(syncId);
    final saved = await planner.getBySyncId(syncId);
    if (row == null || saved == null || saved.isUnavailable || saved.cwiczeniaIds.isEmpty ||
        saved.structure == null || saved.cwiczeniaIds.any((id) => !catalog.any((e) => e.id == id))) {
      throw StateError('Szablon lub ćwiczenie jest niedostępne. Nie generujemy zamiennika.');
    }
    await planner.checkTemplate(row);
    validatePerSetCatalog(saved.structure!, catalog, metadata);
  }

  Future<String> create(ProgramLease lease, {required String name,
    required List<String> planSyncIds, required Set<int> weekdays,
    required CalendarDay effectiveFrom, required List<Exercise> catalog,
    required ExerciseCatalogMetadata metadata, bool Function()? isCurrent}) =>
      _access(lease.accountId, (programs, profile, device, guard) async {
        _checkLease(lease, programs, profile, device);
        if (lease.programId != null) throw StateError('Nowy program wymaga nowego formularza.');
        final id = const Uuid().v4();
        final stamp = UserCollectionsRepository.nextTimestamp(null);
        final entry = <String, dynamic>{
          'id': id, 'kind': 'program', 'name': name.trim(),
          'createdAtUtc': stamp, 'updatedAtUtc': stamp,
          'planSyncIds': List<String>.of(planSyncIds), 'weekdays': weekdays.toList()..sort(),
          'effectiveFromDate': effectiveFrom.value,
        };
        UserCollections.validate('trainingPrograms', {'version': 1, 'entries': [entry]});
        for (final plan in planSyncIds) { await validatePlan(plan, catalog, metadata); }
        await _put(lease.accountId, entry, guard);
        return id;
      }, isCurrent: () => lease.epoch == authority?.epoch && (isCurrent?.call() ?? true));

  Future<void> rename(ProgramLease lease, String name, {bool Function()? isCurrent}) =>
      _edit(lease, (p) => {...p, 'name': name.trim()}, isCurrent);

  Future<void> end(ProgramLease lease, CalendarDay endBefore, {bool Function()? isCurrent}) =>
      _edit(lease, (p) {
        if (p['endBeforeDate'] != null || endBefore.compareTo(today()) < 0) {
          throw StateError('Zakończenie jest jednorazowe, z granicą nie wcześniejszą niż dziś.');
        }
        return {...p, 'endBeforeDate': endBefore.value};
      }, isCurrent);

  Future<void> _edit(ProgramLease lease, Map<String, dynamic> Function(Map<String, dynamic>) edit,
      bool Function()? isCurrent) => _access(lease.accountId, (programs, profile, device, guard) async {
    _checkLease(lease, programs, profile, device);
    final p = _program(programs, lease.programId ?? '');
    await _put(lease.accountId, {...edit(p), 'updatedAtUtc': UserCollectionsRepository.nextTimestamp(p)}, guard);
  }, isCurrent: () => lease.epoch == authority?.epoch && (isCurrent?.call() ?? true));

  ProgramOccurrence _current(TrainingPrograms programs, ProgramOccurrence requested) {
    final current = TrainingProgramSchedule(programs).between(requested.date, requested.date)
        .where((o) => o.id == requested.id).firstOrNull;
    if (current == null || current.isCompleted || current.mutationBaseline != requested.mutationBaseline) {
      throw StateError('Termin zmienił się lub został już zaliczony. Odśwież program.');
    }
    return current;
  }

  Future<void> validateOccurrence(String account, ProgramOccurrence o, {bool Function()? isCurrent}) =>
      _access(account, (programs, profile, device, guard) async { _current(programs, o); }, isCurrent: isCurrent);

  Map<String, dynamic> _override(TrainingPrograms programs, ProgramOccurrence o, CalendarDay date, {String? session}) {
    final old = programs.entries.where((e) => e['id'] == o.id).firstOrNull;
    final stamp = UserCollectionsRepository.nextTimestamp(old);
    return {
      'id': o.id, 'name': o.name, 'kind': 'programOverride',
      'createdAtUtc': old?['createdAtUtc'] ?? stamp, 'updatedAtUtc': stamp,
      'programId': o.programId, 'originalDate': o.originalDate.value, 'movedDate': date.value,
      'state': session == null ? 'planned' : 'completed',
      if (session != null) 'sessionSyncId': session,
      'programSnapshot': o.programSnapshot,
    };
  }

  Future<void> move(String account, ProgramOccurrence requested, CalendarDay date, {bool Function()? isCurrent}) =>
      _access(account, (programs, profile, device, guard) async {
        final o = _current(programs, requested);
        await _put(account, _override(programs, o, date), guard);
      }, isCurrent: isCurrent);

  Future<void> complete(String account, ProgramOccurrence requested, String sessionSyncId, {bool Function()? isCurrent}) =>
      _access(account, (programs, profile, device, guard) async {
        final o = _current(programs, requested);
        if (await proof.references(account, sessionSyncId, isCurrent: guard) > 0) {
          throw StateError('Ta sesja zalicza już inny termin programu lub harmonogramu.');
        }
        if (!await proof.isActual(sessionSyncId)) {
          throw StateError('Wybierz zakończoną, nieusuniętą sesję z co najmniej jedną serią roboczą (także historyczną bez roli).');
        }
        await _put(account, _override(programs, o, o.date, session: sessionSyncId), guard);
      }, isCurrent: isCurrent);

  Future<ScheduleCompletion> completionStatus(String account, ProgramOccurrence o) =>
      _access(account, (programs, profile, device, guard) async {
        if (o.sessionSyncId == null) return ScheduleCompletion.planned;
        if (await proof.references(account, o.sessionSyncId!, isCurrent: guard) > 1) return ScheduleCompletion.conflict;
        return await proof.isActual(o.sessionSyncId!) ? ScheduleCompletion.completed : ScheduleCompletion.invalidated;
      }, writable: false);
}
