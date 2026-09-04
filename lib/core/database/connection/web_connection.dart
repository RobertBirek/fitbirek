import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Połączenie z bazą SQLite dla platformy web - używa WasmDatabase
/// (WebAssembly + IndexedDB/OPFS w zależności od możliwości przeglądarki).
/// Wymaga plików `sqlite3.wasm` i `drift_worker.dart.js` w katalogu web/.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'fitbirek_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );

      if (result.missingFeatures.isNotEmpty && kDebugMode) {
        debugPrint(
          'FitBirek: przeglądarka nie wspiera: ${result.missingFeatures} '
          '- użyto ${result.chosenImplementation}',
        );
      }

      return result.resolvedExecutor;
    }),
  );
}
