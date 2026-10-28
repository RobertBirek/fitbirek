import 'dart:convert';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/core/sync/profile_payload.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'profile_collections_sync_test.dart' show saveProfile, CollectionServer;
import 'training_sets_programs_domain_test.dart'
    show collection, programEntry, planJson;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'same program immutable CAS conflict holds attempted bytes and remote raw across retries',
    () async {
      final server = CollectionServer();
      final a = AppDatabase.forTesting(NativeDatabase.memory());
      final b = AppDatabase.forTesting(NativeDatabase.memory());
      final sa = SyncService(a, server), sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
      });
      await sa.bindAccount('a');
      await sb.bindAccount('a');
      await saveProfile(a);
      await sa.synchronize();
      await sb.synchronize();
      await UserCollectionsRepository(a).update(
        'a',
        'trainingPrograms',
        (entries) => entries.add(programEntry()),
      );
      await UserCollectionsRepository(b).update(
        'a',
        'trainingPrograms',
        (entries) => entries.add({
          ...programEntry(),
          'weekdays': [2],
        }),
      );
      await sb.synchronize();
      final before = (await a.select(a.syncOutbox).get()).single;
      await sa.synchronize();
      expect(sa.status, SyncStatus.conflict);
      expect(
        (await a.select(a.syncOutbox).get()).single.payloadJson,
        before.payloadJson,
      );
      expect(await SyncStore(a).heldProfileIds(), isNotEmpty);
      final held =
          (await a.select(a.syncDeferredRecords).get()).single.recordJson;
      expect(
        jsonDecode(held)[SyncStore
            .profileCollectionHold]['quarantinedRecord']['payload']['trainingPrograms'],
        server.record!['payload']['trainingPrograms'],
      );
      await sa.synchronize();
      expect(
        (await a.select(a.syncDeferredRecords).get()).single.recordJson,
        held,
      );
      expect(
        (await a.select(a.syncOutbox).get()).single.payloadJson,
        before.payloadJson,
      );
    },
  );
  test(
    'profile optional program omission, clear and quarantine retain siblings',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await saveProfile(db);
      await db.delete(db.syncOutbox).go();
      final row = (await db.userProfileDao.watchProfileOnce())!;
      final payload = profilePayload(row);
      var v = 0;
      Future<void> apply(Map<String, dynamic> changes) => SyncStore(db).apply({
        'entityType': 'profile',
        'entityId': row.syncId,
        'version': ++v,
        'updatedAt': '2026-10-28T00:00:00Z',
        'deletedAt': null,
        'payload': {...payload, ...changes},
      });
      await apply({'trainingPrograms': collection([])});
      await apply({});
      expect(
        (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson,
        jsonEncode(collection([])),
      );
      await apply({'trainingPrograms': null});
      expect(
        (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson,
        isNull,
      );
      final future = {'version': 9, 'entries': [], 'future': 'retained'};
      await apply({'trainingPrograms': future});
      final raw = (await db.userProfileDao.watchProfileOnce())!;
      expect(jsonDecode(raw.trainingProgramsJson!), future);
      expect(raw.imie, row.imie);
      expect(() => profilePayload(raw), throwsFormatException);
    },
  );
  test(
    'future structured plan pull is quarantined per row, never converted to legacy',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final future = planJson(version: 3);
      final record = <String, dynamic>{
        'entityType': 'workoutPlan',
        'entityId': 'plan-future',
        'version': 1,
        'updatedAt': '2026-10-28T00:00:00Z',
        'deletedAt': null,
        'payload': {
          'nazwa': 'Future',
          'cwiczeniaIds': ['cw001'],
          'cel': 'mix',
          'dataUtworzenia': '2026-10-28T00:00:00Z',
          'structure': future,
        },
      };
      final quarantine = SyncQuarantine(db, SyncStore(db));
      await quarantine.apply(record, 'a', 1, 0);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      final raw = jsonDecode(
        (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
      );
      expect(raw['raw'], record);
      expect(
        await quarantine.heldKeys('a'),
        contains('workoutPlan:plan-future'),
      );
      expect(await quarantine.recover('a'), isTrue);
      expect(
        jsonDecode(
          (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
        )['raw'],
        record,
      );
    },
  );
}
