import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database_names.dart';

/// Połączenie z bazą SQLite dla platform natywnych (Android/iOS/desktop)
/// - używa sqlite3_flutter_libs (FFI) i zapisuje plik w katalogu dokumentów.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, nativeDatabaseName));
    return NativeDatabase.createInBackground(file);
  });
}
