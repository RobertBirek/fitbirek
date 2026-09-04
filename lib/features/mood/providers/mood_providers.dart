import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart' show MoodEntryData;
import '../../../core/providers/database_provider.dart';
import '../data/mood_repository.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MoodRepository(db);
});

final todayMoodEntryProvider = FutureProvider.autoDispose<MoodEntryData?>((ref) {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.getTodayEntry();
});

final allMoodEntriesProvider = StreamProvider<List<MoodEntryData>>((ref) {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.watchAll();
});
