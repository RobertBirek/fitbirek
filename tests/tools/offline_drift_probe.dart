// Focused browser fixture: compile with the pinned SDK, not a Flutter build.
import 'dart:convert';
import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

@JS('fitDriftProbe')
external set _probe(JSFunction value);

class _FixtureUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<JSString> _run(JSString suffix) async {
  final name = 'fit_offline_worker_fixture_${suffix.toDart}';
  final sqlite = Uri.parse('sqlite3.wasm');
  // Distinct URLs force fresh upstream workers for each call so the offline
  // check cannot reuse a SQLite module loaded by an earlier online worker.
  final worker = Uri.parse('drift_worker.dart.js?fixture=${suffix.toDart}');
  final WasmDatabaseResult result;
  if (suffix.toDart.startsWith('dedicated-')) {
    final probe = await WasmDatabase.probe(
      databaseName: name,
      sqlite3Uri: sqlite,
      driftWorkerUri: worker,
    );
    const dedicated = WasmStorageImplementation.unsafeIndexedDb;
    if (!probe.availableStorages.contains(dedicated)) {
      throw StateError('Dedicated Drift implementation unavailable in fixture');
    }
    result = WasmDatabaseResult(
      await probe.open(dedicated, name),
      dedicated,
      probe.missingFeatures,
    );
  } else {
    result = await WasmDatabase.open(
      databaseName: name,
      sqlite3Uri: sqlite,
      driftWorkerUri: worker,
    );
  }
  final executor = result.resolvedExecutor.executor;
  try {
    await executor.ensureOpen(_FixtureUser());
    final rows = await executor.runSelect('SELECT 41 + 1 AS answer', []);
    return jsonEncode({
      'implementation': result.chosenImplementation.name,
      'missingFeatures': result.missingFeatures.map((e) => e.name).toList(),
      'answer': rows.single['answer'],
    }).toJS;
  } finally {
    await executor.close();
  }
}

void main() {
  _probe = ((JSString suffix) => _run(suffix).toJS).toJS;
}
