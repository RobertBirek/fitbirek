import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/health/data/health_repository.dart';

Map<String, dynamic> record(int v, {bool deleted = false}) => {
  'entityType': 'healthSample',
  'entityId': 'imported-steps',
  'version': v,
  'updatedAt': '2026-09-10T08:00:00Z',
  'deletedAt': deleted ? '2026-09-10T09:00:00Z' : null,
  'payload': {
    'kind': 'steps',
    'day': '2026-09-10',
    'measuredAt': null,
    'value': 7500,
    'source': 'Apple Health',
    'method': 'manual_verified_total',
    'importedAt': '2026-09-10T08:00:00Z',
  },
};

class _Api implements SyncApi {
  bool offline = false;
  final requests = <SyncOperation>[];
  @override
  Future<Map<String, dynamic>> pull(int cursor) async => {
    'cursor': 1,
    'changes': cursor == 0 ? [record(1)] : [],
  };
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> ops) async {
    requests.addAll(ops);
    if (offline) throw StateError('offline');
    return {
      'accepted': [
        for (final o in ops) {'operationId': o.operationId, 'version': 2},
      ],
      'conflicts': [],
    };
  }
}

void main() {
  test(
    'pull ISO/null timestamps, offline delete retry is immutable and never revives',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = _Api();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await sync.synchronize();
      expect(sync.status, SyncStatus.idle);
      final row = await db.select(db.healthSamples).getSingle();
      expect(row.measuredAt, isNull);
      expect(row.importedAt.toUtc(), DateTime.utc(2026, 9, 10, 8));
      await HealthRepository(db).deleteSample(row);
      api.offline = true;
      await sync.synchronize();
      final pending = (await db.syncDao.pendingOperations()).single;
      await db.transaction(() => SyncStore(db).apply(record(1)));
      expect(await HealthRepository(db).watchAll().first, isEmpty);
      api.offline = false;
      await sync.synchronize();
      expect(api.requests.last.toJson(), pending.toJson());
      expect(api.requests.every((o) => o.deleted), isTrue);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(await HealthRepository(db).watchAll().first, isEmpty);
    },
  );
}
