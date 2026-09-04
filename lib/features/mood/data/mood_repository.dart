import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/mood_table.dart';

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
  }) {
    return _db.moodDao.addEntry(
      MoodEntriesCompanion.insert(
        snGodziny: snGodziny,
        energia: energia,
        nastroj: nastroj,
        apetyt: apetyt,
        alkohol: Value(alkohol),
        alkoholJednostki: Value(alkoholJednostki),
      ),
    );
  }

  Stream<List<MoodEntryData>> watchAll() => _db.moodDao.watchAll();

  Future<MoodEntryData?> getTodayEntry() => _db.moodDao.getTodayEntry();
}
