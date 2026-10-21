import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'profile_collections_sync_test.dart' show saveProfile;

/// In-memory transport with real CAS and idempotent lost-ack retries. All client
/// persistence/merge/push/pull is exercised through the production SyncService.
class FitnessServer implements SyncApi {
  final records = <String, Map<String, dynamic>>{};
  final changes = <Map<String, dynamic>>[];
  final acks = <String, Map<String, dynamic>>{};
  final requests = <Map<String, dynamic>>[];
  bool loseAck = false;
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> operations) async {
    final accepted = <Map<String, dynamic>>[],
        conflicts = <Map<String, dynamic>>[];
    for (final op in operations) {
      requests.add(op.toJson());
      final ack = acks[op.operationId];
      if (ack != null) {
        accepted.add({...ack, 'duplicate': true});
        continue;
      }
      final key = '${op.entityType.name}:${op.entityId}',
          old = records['${op.entityType.name}:${op.entityId}'];
      if ((old?['version'] ?? 0) != op.baseVersion) {
        conflicts.add({'operationId': op.operationId, 'record': old});
        continue;
      }
      final stamp = DateTime.now().toUtc().toIso8601String();
      final record = <String, dynamic>{
        'entityType': op.entityType.name,
        'entityId': op.entityId,
        'version': op.baseVersion + 1,
        'updatedAt': stamp,
        'deletedAt': op.deleted ? stamp : null,
        'payload': jsonDecode(jsonEncode(op.payload)),
      };
      records[key] = record;
      changes.add(record);
      final value = {
        'operationId': op.operationId,
        'version': record['version'],
        'updatedAt': stamp,
        'duplicate': false,
      };
      acks[op.operationId] = value;
      accepted.add(value);
    }
    if (loseAck) {
      loseAck = false;
      throw StateError('Response lost after commit');
    }
    return {'accepted': accepted, 'conflicts': conflicts};
  }

  @override
  Future<Map<String, dynamic>> pull(int cursor) async => {
    'cursor': changes.length,
    'changes': changes.skip(cursor).toList(),
  };
}

FitnessProtocolDraft draft() => FitnessProtocolDraft.fromProtocol(
  FitnessProtocol.fromJson(
    (jsonDecode(
              File(
                'tests/fixtures/fitness_protocol_v1.json',
              ).readAsStringSync(),
            )
            as Map)['protocol']
        as Map<String, dynamic>,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'two offline forks merge via CAS; raw attempts survive lost response; custom result retains snapshot',
    () async {
      final server = FitnessServer();
      final a = AppDatabase.forTesting(NativeDatabase.memory()),
          b = AppDatabase.forTesting(NativeDatabase.memory());
      final sa = SyncService(a, server), sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
      });
      await sa.bindAccount('a');
      await sb.bindAccount('a');
      await ExercisesRepository(a).syncFromAssets();
      await ExercisesRepository(b).syncFromAssets();
      await saveProfile(a);
      final ar = TestsRepository(a), br = TestsRepository(b);
      final parent = await ar.createProtocol(await ar.captureLease(), draft());
      await sa.synchronize();
      await sb.synchronize();
      final al = await ar.captureLease(protocolId: parent.id),
          bl = await br.captureLease(protocolId: parent.id);
      final ap = await ar.reviseProtocol(al, draft()),
          bp = await br.reviseProtocol(bl, draft());
      await sa.synchronize();
      await sb.synchronize();
      await sa.synchronize();
      await sb.synchronize();
      expect(
        (await ar.watchProtocols().first).active.map((p) => p.id).toSet(),
        {parent.id, ap.id, bp.id},
      );
      expect(
        (await br.watchProtocols().first).active.map((p) => p.id).toSet(),
        {parent.id, ap.id, bp.id},
      );
      await br.addCustomResult(
        await br.captureLease(protocolId: bp.id),
        value: 18.0,
        performedAt: DateTime.utc(2020, 1, 1, 16, 30),
      );
      server.loseAck = true;
      await sb.synchronize();
      final attempted = (await b.select(b.syncOutbox).get()).single;
      expect(attempted.attempted, isTrue);
      await br.reviseProtocol(
        await br.captureLease(protocolId: parent.id),
        draft(),
      );
      expect(
        (await b.select(b.syncOutbox).get())
            .firstWhere((r) => r.operationId == attempted.operationId)
            .payloadJson,
        attempted.payloadJson,
      );
      await sb.synchronize();
      await sa.synchronize();
      final result = (await ar.watchCustomResults().first)!.single;
      expect(result.protocol!.id, bp.id);
      expect(result.value, 18);
      expect(result.performedAt, DateTime.utc(2020, 1, 1, 16, 30));
      expect(await b.syncDao.pendingOperations(), isEmpty);
      final copies = server.requests
          .where((r) => r['operationId'] == attempted.operationId)
          .toList();
      expect(copies, hasLength(2));
      expect(copies[0], copies[1]);
      await ar.archiveProtocol(await ar.captureLease(protocolId: parent.id));
      await sa.synchronize();
      await sb.synchronize();
      await expectLater(
        br.addCustomResult(bl, value: 3, performedAt: DateTime.utc(2020)),
        throwsStateError,
      );
      expect((await br.watchProtocols().first).archived.single.id, parent.id);
      expect((await br.watchCustomResults().first)!.single.protocol!.id, bp.id);
      expect(await a.select(a.workoutSessions).get(), isEmpty);
      expect(await a.select(a.setsLog).get(), isEmpty);
      expect(await a.select(a.personalRecords).get(), isEmpty);
    },
  );
  test(
    'immutable same-id conflict holds profile raw and attempted bytes but pulls independent custom result',
    () async {
      final server = FitnessServer(),
          db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, server);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('a');
      await ExercisesRepository(db).syncFromAssets();
      await saveProfile(db);
      final repo = TestsRepository(db);
      final parent = await repo.createProtocol(
        await repo.captureLease(),
        draft(),
      );
      await sync.synchronize();
      final child = await repo.reviseProtocol(
        await repo.captureLease(protocolId: parent.id),
        draft(),
      );
      await db
          .update(db.syncOutbox)
          .write(const SyncOutboxCompanion(attempted: Value(true)));
      final attempted = (await db.syncDao.pendingOperations()).single.toJson();
      final key =
          'profile:${(await db.userProfileDao.watchProfileOnce())!.syncId}';
      final remote =
          jsonDecode(jsonEncode(server.records[key])) as Map<String, dynamic>;
      remote['version'] = 2;
      remote['payload']['fitnessProtocols']['entries'][0]['instructions'] =
          'Remote collision';
      remote['payload']['fitnessProtocols']['entries'][0]['updatedAtUtc'] =
          DateTime.now().toUtc().toIso8601String();
      server.records[key] = remote;
      server.changes.add(remote);
      final raw =
          jsonDecode(
                File(
                  'tests/fixtures/fitness_protocol_v1.json',
                ).readAsStringSync(),
              )
              as Map;
      server.changes.add({
        'entityType': 'fitnessTest',
        'entityId': '22222222-2222-4222-8222-222222222222',
        'version': 1,
        'updatedAt': '2026-10-21T12:00:00Z',
        'deletedAt': null,
        'payload': raw['result'],
      });
      await sync.synchronize();
      expect(sync.status, SyncStatus.conflict);
      expect((await db.syncDao.pendingOperations()).single.toJson(), attempted);
      final view = await repo.watchProtocols().first;
      expect(view.isAvailable, isFalse);
      final local = jsonDecode(
        (await db.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson!,
      );
      expect((local['entries'] as List).map((p) => p['id']).toSet(), {
        parent.id,
        child.id,
      });
      expect(
        (local['entries'] as List).firstWhere(
          (p) => p['id'] == parent.id,
        )['instructions'],
        parent.instructions,
      );
      expect(
        (await repo.watchCustomResults().first)!.single.isAvailable,
        isTrue,
      );
      final deferred = jsonDecode(
        (await db.select(db.syncDeferredRecords).get()).single.recordJson,
      );
      expect(
        deferred['payload']['fitnessProtocols']['entries'][0]['instructions'],
        'Remote collision',
      );
    },
  );
}
