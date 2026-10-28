import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../exercises/data/user_collections_repository.dart';

/// One proof namespace across weekly schedules and A/B programs. Read both
/// collections strictly: an unreadable sibling must never authorize reuse.
class SessionCompletionProof {
  SessionCompletionProof(this.db, this.collections);
  final AppDatabase db;
  final UserCollectionsRepository collections;

  Future<int> references(
    String account,
    String sessionSyncId, {
    bool Function()? isCurrent,
  }) async {
    var count = 0;
    for (final key in ['weeklySchedule', 'trainingPrograms']) {
      final value = await collections.load(account, key, isCurrent: isCurrent);
      count += (value['entries'] as List).where((e) =>
        {'override', 'activityOverride', 'programOverride'}.contains(e['kind']) &&
        e['deletedAtUtc'] == null && e['state'] == 'completed' &&
        (e['sessionSyncId'] as String?)?.toLowerCase() == sessionSyncId.toLowerCase()
      ).length;
    }
    return count;
  }

  Future<bool> isActual(String id) async {
    final session = await (db.select(db.workoutSessions)..where((s) =>
      s.syncId.equals(id) & s.deletedAtUtc.isNull() & s.dataKoniec.isNotNull()
    )).getSingleOrNull();
    if (session == null) return false;
    final set = await (db.select(db.setsLog)..where((s) =>
      s.sesjaId.equals(session.id) & s.deletedAtUtc.isNull() &
      (s.setRole.isNull() | s.setRole.equals('working'))
    )..limit(1)).getSingleOrNull();
    return set != null;
  }

  Future<List<WorkoutSessionData>> eligibleSessions() async {
    final ended = await (db.select(db.workoutSessions)..where((s) =>
      s.deletedAtUtc.isNull() & s.dataKoniec.isNotNull()
    )).get();
    final sets = await (db.select(db.setsLog)..where((s) =>
      s.deletedAtUtc.isNull() & (s.setRole.isNull() | s.setRole.equals('working'))
    )).get();
    final actual = sets.map((s) => s.sesjaId).toSet();
    return ended.where((s) => actual.contains(s.id)).toList()
      ..sort((a, b) => b.dataStart.compareTo(a.dataStart));
  }
}
