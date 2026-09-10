import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_models.dart';

/// Repozytorium dziennika samopoczucia.
class MoodRepository {
  MoodRepository(this._db);
  final AppDatabase _db;

  Future<void> addEntry({
    required double snGodziny,
    required int energia,
    required int nastroj,
    required int apetyt,
    required bool alkohol,
    required int alkoholJednostki,
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    await _db.transaction(() async {
      await _db.moodDao.addEntry(
        MoodEntriesCompanion.insert(
          data: Value(now),
          snGodziny: snGodziny,
          energia: energia,
          nastroj: nastroj,
          apetyt: apetyt,
          alkohol: Value(alkohol),
          alkoholJednostki: Value(alkoholJednostki),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.mood,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'data': now.toIso8601String(),
          'snGodziny': snGodziny,
          'energia': energia,
          'nastroj': nastroj,
          'apetyt': apetyt,
          'alkohol': alkohol,
          'alkoholJednostki': alkoholJednostki,
        },
      );
    });
  }

  Stream<List<MoodEntryData>> watchAll() => _db.moodDao.watchAll();

  Future<MoodEntryData?> getTodayEntry() => _db.moodDao.getTodayEntry();
}
