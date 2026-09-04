import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Globalny provider instancji bazy danych - jeden na całą aplikację.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
