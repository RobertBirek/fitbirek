import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' show PersonalRecordData;
import '../../../../core/providers/database_provider.dart';
import '../data/prs_repository.dart';

final prsRepositoryProvider = Provider<PrsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PrsRepository(db);
});

final allPrsProvider = StreamProvider<List<PersonalRecordData>>((ref) {
  final repo = ref.watch(prsRepositoryProvider);
  return repo.watchAll();
});
