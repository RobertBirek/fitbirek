import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/mood_table.dart';

part 'mood_dao.g.dart';

@DriftAccessor(tables: [MoodEntries])
class MoodDao extends DatabaseAccessor<AppDatabase> with _$MoodDaoMixin {
  MoodDao(super.db);

  Future<int> addEntry(MoodEntriesCompanion entry) {
    return into(moodEntries).insert(entry);
  }

  Stream<List<MoodEntryData>> watchAll() {
    return (select(moodEntries)..orderBy([
          (t) => OrderingTerm.desc(t.data),
          (t) => OrderingTerm.desc(t.id),
        ]))
        .watch();
  }

  /// Wpis z dzisiejszego dnia (jeśli istnieje) - do sprawdzenia czy user już wypełnił.
  Future<MoodEntryData?> getTodayEntry() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows =
        await (select(moodEntries)
              ..where((t) => t.data.isBiggerOrEqualValue(startOfDay))
              ..orderBy([(t) => OrderingTerm.desc(t.data)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first;
  }
}
