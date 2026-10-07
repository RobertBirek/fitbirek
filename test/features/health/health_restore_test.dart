import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/health/data/health_repository.dart';
import 'health_repository_test.dart' show seedSample;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());
  test(
    'legacy restore preserves imports and attempted deletion verbatim',
    () async {
      final keep = await seedSample(
        db,
        kind: 'weight',
        day: '2026-09-09',
        value: 80,
      );
      final deleted = await seedSample(
        db,
        kind: 'steps',
        day: '2026-09-10',
        value: 4200,
      );
      await HealthRepository(db).deleteSample(deleted);
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before = (await db.syncDao.pendingOperations()).single.toJson();
      final result = await BackupService(db).importFromBytes(
        Uint8List.fromList(utf8.encode('{"schemaVersion":1,"data":{}}')),
      );
      expect(result.success, isTrue);
      expect((await db.syncDao.pendingOperations()).single.toJson(), before);
      final rows = await db.select(db.healthSamples).get();
      expect(
        rows.singleWhere((s) => s.syncId == keep.syncId).deletedAtUtc,
        isNull,
      );
      expect(
        rows.singleWhere((s) => s.syncId == deleted.syncId).deletedAtUtc,
        isNotNull,
      );
      expect(result.message, contains('nie są odtwarzane'));
    },
  );
  test(
    'export archives imports but restore on a new account does not invent them',
    () async {
      await seedSample(db, kind: 'weight', day: '2026-09-09', value: 80);
      final bytes = await BackupService(db).exportToBytes();
      final decoded = jsonDecode(utf8.decode(bytes)) as Map;
      expect(decoded['data']['healthSamples'], hasLength(1));
      expect(
        decoded['data']['healthSamples'].single.containsKey('syncId'),
        isFalse,
      );
      final other = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(other.close);
      final result = await BackupService(other).importFromBytes(bytes);
      expect(result.success, isTrue);
      expect(await other.select(other.healthSamples).get(), isEmpty);
      expect(
        (await other.syncDao.pendingOperations()).where(
          (o) => o.entityType == SyncEntityType.healthSample,
        ),
        isEmpty,
      );
    },
  );
  test(
    'client cannot enqueue a health upsert even with restore intent',
    () async {
      expect(
        () => db.syncDao.enqueueUpsert(
          entityType: SyncEntityType.healthSample,
          entityId: 'import',
          baseVersion: 0,
          payload: {},
          preserveLocal: true,
        ),
        throwsStateError,
      );
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );
}
