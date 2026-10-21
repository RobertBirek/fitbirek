import 'dart:convert';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'custom_fitness_devices_test.dart' show FitnessServer, draft;
import 'profile_collections_sync_test.dart' show saveProfile;

class InterleavedFitnessServer extends FitnessServer {
  Future<void> Function(List<SyncOperation>)? duringPush;
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> operations) async {
    final callback = duringPush;
    duringPush = null;
    await callback?.call(operations);
    return super.push(operations);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  for (final collision in [false, true]) {
    test(
      collision
          ? 'interleaved CAS still holds a real immutable UUID collision and retains attempted/raw evidence'
          : 'interleaved CAS with a later local revision converges all offline branches without a profile hold',
      () async {
        final server = InterleavedFitnessServer();
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
        await ExercisesRepository(a).syncFromAssets();
        await ExercisesRepository(b).syncFromAssets();
        await saveProfile(a);
        final ar = TestsRepository(a), br = TestsRepository(b);
        final parent = await ar.createProtocol(
          await ar.captureLease(),
          draft(),
        );
        await sa.synchronize();
        await sb.synchronize();
        final remoteBranch = await br.reviseProtocol(
          await br.captureLease(protocolId: parent.id),
          draft(),
        );
        await sb.synchronize();
        final localBranch = await ar.reviseProtocol(
          await ar.captureLease(protocolId: parent.id),
          draft(),
        );
        String? attemptedId, attemptedBytes, laterBytes, laterBranchId, laterId;
        Map<String, dynamic>? attemptedRequest, laterRequest;
        server.duringPush = (operations) async {
          final op = operations.single;
          attemptedId = op.operationId;
          attemptedRequest = op.toJson();
          final before = (await a.select(a.syncOutbox).get()).single;
          expect(before.attempted, isTrue);
          attemptedBytes = before.payloadJson;
          laterBranchId = (await ar.reviseProtocol(
            await ar.captureLease(protocolId: parent.id),
            draft(),
          )).id;
          final queue = await a.select(a.syncOutbox).get();
          expect(
            queue
                .firstWhere((r) => r.operationId == op.operationId)
                .payloadJson,
            attemptedBytes,
          );
          final later = queue.singleWhere(
            (r) => r.operationId != op.operationId,
          );
          expect(later.attempted, isFalse);
          laterBytes = later.payloadJson;
          laterId = later.operationId;
          laterRequest = (await a.syncDao.pendingOperations())
              .singleWhere((o) => o.operationId == laterId)
              .toJson();
          if (!collision) {
            server.duringPush = (next) async {
              // Before the successor CAS, defer must still contain the real
              // remote authority, not a synthetic snapshot with local entries.
              final deferred = jsonDecode(
                (await a.select(a.syncDeferredRecords).get()).single.recordJson,
              );
              expect(
                (deferred['payload']['fitnessProtocols']['entries'] as List)
                    .map((p) => p['id'])
                    .toSet(),
                {parent.id, remoteBranch.id},
              );
              expect(await SyncStore(a).heldProfileIds(), isEmpty);
              expect(next.single.toJson(), laterRequest);
            };
          }
          if (collision) {
            final profile = (await a.userProfileDao.watchProfileOnce())!;
            final key = 'profile:${profile.syncId}';
            final bad =
                jsonDecode(jsonEncode(server.records[key]))
                    as Map<String, dynamic>;
            bad['version'] = (bad['version'] as int) + 1;
            final entry =
                (bad['payload']['fitnessProtocols']['entries'] as List)
                    .singleWhere((p) => p['id'] == parent.id);
            entry['instructions'] = 'Real conflicting rules';
            entry['updatedAtUtc'] = DateTime.now().toUtc().toIso8601String();
            server.records[key] = bad;
            server.changes.add(bad);
          }
        };
        await sa.synchronize();
        await sa.synchronize();
        if (collision) {
          expect(sa.status, SyncStatus.conflict);
          expect(await SyncStore(a).heldProfileIds(), isNotEmpty);
          final queue = await a.select(a.syncOutbox).get();
          expect(
            queue.firstWhere((r) => r.operationId == attemptedId).payloadJson,
            attemptedBytes,
          );
          expect(
            queue.singleWhere((r) => r.operationId != attemptedId).payloadJson,
            laterBytes,
          );
          final raw = jsonDecode(
            (await a.select(a.syncDeferredRecords).get()).single.recordJson,
          );
          expect(
            (raw['payload']['fitnessProtocols']['entries'] as List).singleWhere(
              (p) => p['id'] == parent.id,
            )['instructions'],
            'Real conflicting rules',
          );
          final local = jsonDecode(
            (await a.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson!,
          );
          expect(
            (local['entries'] as List).singleWhere(
              (p) => p['id'] == parent.id,
            )['instructions'],
            parent.instructions,
          );
        } else {
          expect(await SyncStore(a).heldProfileIds(), isEmpty);
          expect(await a.syncDao.pendingOperations(), isEmpty);
          await sb.synchronize();
          await sa.synchronize();
          final expected = {
            parent.id,
            remoteBranch.id,
            localBranch.id,
            laterBranchId,
          };
          for (final repo in [ar, br]) {
            final view = await repo.watchProtocols().first;
            expect(view.isAvailable, isTrue);
            expect(view.protocols.map((p) => p.id).toSet(), expected);
          }
          expect(await b.syncDao.pendingOperations(), isEmpty);
          expect(await SyncStore(b).heldProfileIds(), isEmpty);
          expect(
            server.requests
                .where((r) => r['operationId'] == attemptedId)
                .single,
            attemptedRequest,
          );
          expect(
            server.requests.singleWhere((r) => r['operationId'] == laterId),
            laterRequest,
          );
        }
      },
    );
  }
  test(
    'clean authoritative profile still holds pruning of previously published fitness history',
    () async {
      final server = FitnessServer();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
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
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      final profile = (await db.userProfileDao.watchProfileOnce())!;
      final key = 'profile:${profile.syncId}';
      final pruned =
          jsonDecode(jsonEncode(server.records[key])) as Map<String, dynamic>;
      pruned['version'] = (pruned['version'] as int) + 1;
      pruned['payload']['fitnessProtocols']['entries'] = [];
      server.records[key] = pruned;
      server.changes.add(pruned);
      await sync.synchronize();
      expect(sync.status, SyncStatus.conflict);
      expect(await SyncStore(db).heldProfileIds(), {profile.syncId});
      final local = jsonDecode(
        (await db.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson!,
      );
      expect((local['entries'] as List).map((p) => p['id']).toSet(), {
        parent.id,
        child.id,
      });
      final raw = jsonDecode(
        (await db.select(db.syncDeferredRecords).get()).single.recordJson,
      );
      expect(raw['payload']['fitnessProtocols']['entries'], isEmpty);
    },
  );
}
