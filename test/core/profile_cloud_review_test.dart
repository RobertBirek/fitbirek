import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Uint8List, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/features/exercises/data/filter_presets_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'profile_collections_sync_test.dart' show CollectionServer, saveProfile;

const x = '11111111-1111-4111-8111-111111111111';
const y = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> preset(
  String id,
  String name, {
  bool deleted = false,
  String stamp = '2025-01-01T00:00:00.000Z',
}) => {
  'id': id,
  'name': name,
  'filters': <String, dynamic>{},
  'createdAtUtc': '2024-01-01T00:00:00.000Z',
  'updatedAtUtc': stamp,
  if (deleted) 'deletedAtUtc': stamp,
};

/// Uses the actual client CAS loop. The server preserves absent extension keys
/// only AFTER CAS/hash, like the existing API, without changing attempted input.
class ReviewServer extends CollectionServer {
  bool blockPush = false;
  bool loseAck = false;
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> operations) async {
    if (blockPush) {
      return {
        'accepted': <dynamic>[],
        'conflicts': [
          for (final op in operations)
            {'operationId': op.operationId, 'kind': 'indeterminateOperation'},
        ],
      };
    }
    final before = record;
    final result = await super.push(operations);
    if ((result['accepted'] as List).any((a) => a['duplicate'] == false) &&
        before != null) {
      final payload = Map<String, dynamic>.from(record!['payload'] as Map);
      final old = before['payload'] as Map;
      for (final key in ['filterPresets', 'exerciseVariants']) {
        if (!payload.containsKey(key) && old.containsKey(key)) {
          payload[key] = old[key];
        }
      }
      record = {...record!, 'payload': payload};
      log[log.length - 1] = record!;
    }
    if (loseAck) {
      loseAck = false;
      throw StateError('Lost acknowledgement after commit');
    }
    return result;
  }
}

class Devices {
  final server = ReviewServer();
  final a = AppDatabase.forTesting(NativeDatabase.memory());
  final b = AppDatabase.forTesting(NativeDatabase.memory());
  late final sa = SyncService(a, server), sb = SyncService(b, server);
  Future<void> initialize({bool seed = true, bool pullB = true}) async {
    await sa.bindAccount('account');
    await sb.bindAccount('account');
    await saveProfile(a);
    if (seed) {
      await UserCollectionsRepository(a).update(
        'account',
        'filterPresets',
        (entries) => entries.add(preset(x, 'X')),
      );
      await UserCollectionsRepository(a).update(
        'account',
        'exerciseVariants',
        (entries) => entries.add({
          'id': y,
          'name': 'Variant',
          'exerciseId': 'cw001',
          'createdAtUtc': '2024-01-01T00:00:00.000Z',
          'updatedAtUtc': '2025-01-01T00:00:00.000Z',
        }),
      );
    }
    await sa.synchronize();
    if (pullB) await sb.synchronize();
  }

  Future<void> close() async {
    sa.dispose();
    sb.dispose();
    await a.close();
    await b.close();
  }
}

Future<Map<String, dynamic>> archive(AppDatabase db) async =>
    jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
        as Map<String, dynamic>;
Uint8List bytes(Map<String, dynamic> json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));
Map<String, dynamic> archivedProfile(Map<String, dynamic> json) =>
    (json['data']['userProfiles'] as List).single as Map<String, dynamic>;

// A retryable transport failure is NOT the explicit indeterminateOperation
// returned by blockPush. Seed a concurrently observed snapshot separately:
// the failed push itself does not execute pull.
Future<void> observeDeferredAfterTransportFailure(
  AppDatabase db,
  SyncService sync,
  ReviewServer server,
) async {
  server.beforePush = () async => throw DioException.connectionError(
    requestOptions: RequestOptions(path: '/api/sync/push'),
    reason: 'Simulated connection loss',
  );
  try {
    await sync.synchronize();
    expect(sync.status, SyncStatus.offline);
  } finally {
    server.beforePush = null;
  }
  await db.transaction(
    () => SyncStore(db).apply(Map<String, dynamic>.from(server.record!)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final edit in ['ordinary profile', 'new preset', 'backup restore']) {
    test(
      'HIGH: $edit after deferred remote snapshot cannot claim its unapplied version',
      () async {
        final d = Devices();
        addTearDown(d.close);
        await d.initialize();
        await saveProfile(d.b, name: 'Dirty B');
        await UserCollectionsRepository(d.a).update(
          'account',
          'filterPresets',
          (entries) {
            entries.clear();
            entries.addAll([
              preset(x, 'X', deleted: true, stamp: '2025-02-01T00:00:00.000Z'),
              preset(y, 'Y'),
            ]);
          },
        );
        await saveProfile(d.a, height: 195);
        await d.sa.synchronize();
        expect(d.server.record!['version'], 2);
        await observeDeferredAfterTransportFailure(d.b, d.sb, d.server);
        expect((await d.b.userProfileDao.watchProfileOnce())!.syncVersion, 2);
        expect(
          (await d.b.select(d.b.syncDeferredRecords).getSingle()).version,
          2,
        );
        final attempted = (await d.b.syncDao.pendingOperations()).single
            .toJson();
        if (edit == 'ordinary profile') {
          await saveProfile(d.b, name: 'Extra edit after defer');
        } else if (edit == 'new preset') {
          await FilterPresetsRepository(
            cloud: UserCollectionsRepository(d.b),
          ).save('account', 'Z', const ExerciseFilters());
        } else {
          expect(
            (await BackupService(
              d.b,
            ).importFromBytes(bytes(await archive(d.b)))).success,
            isTrue,
          );
        }
        final pending = await d.b.syncDao.pendingOperations();
        expect(
          pending.first.toJson(),
          attempted,
          reason: 'attempted operation stays byte-for-byte immutable',
        );
        expect(
          pending.last.baseVersion,
          lessThan(2),
          reason: 'observed v2 was NOT applied to the local payload',
        );
        await d.b.transaction(
          () => SyncStore(
            d.b,
          ).version(SyncEntityType.profile, pending.last.entityId, 1),
        );
        expect(
          (await d.b.userProfileDao.watchProfileOnce())!.syncVersion,
          2,
          reason:
              'observed watermark never regresses on an older acknowledgement',
        );
        expect(
          (await d.b.syncDao.pendingOperations()).last.baseVersion,
          lessThan(2),
          reason:
              'older ack cannot bless the unapplied observed version either',
        );
        await d.sb.synchronize();
        await d.sa.synchronize();
        final entries =
            (d.server.record!['payload']['filterPresets']['entries'] as List);
        expect(
          entries.firstWhere((e) => e['id'] == x)['deletedAtUtc'],
          isNotNull,
        );
        expect(entries.any((e) => e['id'] == y && e['name'] == 'Y'), isTrue);
        if (edit == 'new preset') {
          expect(entries.any((e) => e['name'] == 'Z'), isTrue);
        }
        // An explicit whole-backup scalar restore has the existing preserveLocal
        // policy; ordinary profile/preset edits retain server-authoritative CAS.
        expect(
          (await d.b.userProfileDao.watchProfileOnce())!.wzrostCm,
          edit == 'backup restore' ? 180 : 195,
        );
        expect(await d.b.syncDao.pendingOperations(), isEmpty);
      },
    );
  }

  for (final laterEdit in [false, true]) {
    test(
      'MEDIUM: explicit NULL restore is sent and survives coalescing/CAS (later profile edit=$laterEdit)',
      () async {
        final d = Devices();
        addTearDown(d.close);
        await d.initialize();
        final backup = await archive(d.b);
        archivedProfile(
          backup,
        ).addAll({'filterPresetsJson': null, 'exerciseVariantsJson': null});
        expect(
          (await BackupService(d.b).importFromBytes(bytes(backup))).success,
          isTrue,
        );
        if (laterEdit) await saveProfile(d.b, name: 'After clear');
        var pending = (await d.b.syncDao.pendingOperations()).single;
        for (final key in ['filterPresets', 'exerciseVariants']) {
          expect(
            pending.payload.containsKey(key),
            isTrue,
            reason: '$key explicit clear is NOT omission',
          );
          expect(pending.payload[key], isNull);
        }
        // Unrelated concurrent scalar edit forces a real conflict/rebase.
        await saveProfile(d.a, height: 195);
        await d.sa.synchronize();
        await d.sb.synchronize();
        await d.sa.synchronize();
        expect(d.server.record!['payload']['filterPresets'], isNull);
        expect(d.server.record!['payload']['exerciseVariants'], isNull);
        expect(
          (await d.b.userProfileDao.watchProfileOnce())!.filterPresetsJson,
          isNull,
        );
        expect(
          (await d.b.userProfileDao.watchProfileOnce())!.exerciseVariantsJson,
          isNull,
        );
        expect((await d.b.userProfileDao.watchProfileOnce())!.wzrostCm, 195);
        expect(await d.b.syncDao.pendingOperations(), isEmpty);
      },
    );
  }

  test(
    'CONTROL: old backup missing fields does not clear unknown remote extensions before first pull',
    () async {
      final d = Devices();
      addTearDown(d.close);
      await d.initialize(pullB: false);
      await saveProfile(d.b);
      final backup = await archive(d.b);
      archivedProfile(backup).remove('filterPresetsJson');
      archivedProfile(backup).remove('exerciseVariantsJson');
      expect(
        (await BackupService(d.b).importFromBytes(bytes(backup))).success,
        isTrue,
      );
      final pending = (await d.b.syncDao.pendingOperations()).single;
      expect(pending.payload.containsKey('filterPresets'), isFalse);
      expect(pending.payload.containsKey('exerciseVariants'), isFalse);
      await d.sb.synchronize();
      expect(
        d.server.record!['payload']['filterPresets']['entries'],
        hasLength(1),
      );
      expect(
        d.server.record!['payload']['exerciseVariants']['entries'],
        hasLength(1),
      );
      expect(
        (await d.b.userProfileDao.watchProfileOnce())!.filterPresetsJson,
        isNotNull,
      );
    },
  );

  test(
    'clear merge retry cannot regain scalar restore authority on a second conflict',
    () async {
      final d = Devices();
      addTearDown(d.close);
      await d.initialize();
      final backup = await archive(d.b);
      archivedProfile(
        backup,
      ).addAll({'filterPresetsJson': null, 'exerciseVariantsJson': null});
      expect(
        (await BackupService(d.b).importFromBytes(bytes(backup))).success,
        isTrue,
      );
      await saveProfile(d.a, height: 195);
      await d.sa.synchronize();
      var calls = 0;
      d.server.beforePush = () async {
        if (++calls == 2) {
          // Another valid server snapshot after the first rejected CAS: the
          // collections are cleared, but a scalar edit is newer than our merge.
          d.server.record = {
            ...d.server.record!,
            'version': 3,
            'payload': {
              ...Map<String, dynamic>.from(d.server.record!['payload'] as Map),
              'filterPresets': null,
              'exerciseVariants': null,
              'wzrostCm': 200.0,
            },
          };
          d.server.log.add(d.server.record!);
        }
      };
      await d.sb.synchronize();
      expect(d.server.record!['payload']['wzrostCm'], 200);
      expect((await d.b.userProfileDao.watchProfileOnce())!.wzrostCm, 200);
      expect(d.server.record!['payload']['filterPresets'], isNull);
      expect(await d.b.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'explicit clear survives lost ACK, SQLite reopen, newer deferred version and later scalar edit without attempted rewrite',
    () async {
      final d = Devices();
      addTearDown(d.close);
      await d.initialize(pullB: false);
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      var sync = SyncService(db, d.server);
      await sync.bindAccount('account');
      await sync.synchronize();
      final backup = await archive(db);
      archivedProfile(
        backup,
      ).addAll({'filterPresetsJson': null, 'exerciseVariantsJson': null});
      expect(
        (await BackupService(db).importFromBytes(bytes(backup))).success,
        isTrue,
      );
      d.server.loseAck = true;
      await sync.synchronize();
      final attempted = (await db.syncDao.pendingOperations()).single.toJson();
      expect(
        (attempted['payload'] as Map).containsKey('filterPresets'),
        isTrue,
      );
      sync.dispose();
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      sync = SyncService(db, d.server);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      // A second device applies the clear, then publishes unrelated scalar v3.
      await d.sa.synchronize();
      await saveProfile(d.a, height: 195);
      await d.sa.synchronize();
      expect(d.server.record!['version'], 3);
      await observeDeferredAfterTransportFailure(db, sync, d.server);
      expect((await db.userProfileDao.watchProfileOnce())!.syncVersion, 3);
      await saveProfile(db, name: 'Later after reopen');
      final pending = await db.syncDao.pendingOperations();
      expect(pending.first.toJson(), attempted);
      expect(pending.last.payload.containsKey('filterPresets'), isTrue);
      expect(pending.last.payload.containsKey('exerciseVariants'), isTrue);
      expect(pending.last.baseVersion, lessThan(3));
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(d.server.record!['payload']['filterPresets'], isNull);
      expect(d.server.record!['payload']['exerciseVariants'], isNull);
      expect(
        d.server.attempts
            .where((o) => o.operationId == attempted['operationId'])
            .map((o) => o.toJson())
            .toList(),
        [attempted, attempted],
      );
    },
  );

  for (final intentionalEdit in [false, true]) {
    test(
      'MEDIUM: unseen remote deletion beats automatic legacy import (intentional edit=$intentionalEdit)',
      () async {
        final d = Devices();
        addTearDown(d.close);
        await d.initialize(seed: false, pullB: false);
        final legacy = await FilterPresetsRepository().save(
          'account',
          'Legacy X',
          const ExerciseFilters(),
        );
        await UserCollectionsRepository(d.a).update(
          'account',
          'filterPresets',
          (entries) {
            entries.addAll([
              preset(legacy.id, 'Legacy X', deleted: true),
              preset(y, 'Remote Y'),
            ]);
          },
        );
        await d.sa
            .synchronize(); // tombstone is on server, never yet pulled by B
        await saveProfile(d.b);
        final repo = FilterPresetsRepository(
          cloud: UserCollectionsRepository(d.b),
        );
        expect((await repo.load('account')).single.id, legacy.id);
        if (intentionalEdit) {
          await repo.save(
            'account',
            'Legacy X',
            const ExerciseFilters(query: 'intentional new edit'),
            overwriteId: legacy.id,
          );
        }
        await d.sb.synchronize();
        final entries =
            d.server.record!['payload']['filterPresets']['entries'] as List;
        final entry = entries.firstWhere((e) => e['id'] == legacy.id);
        expect(
          entry['deletedAtUtc'],
          intentionalEdit ? isNull : isNotNull,
          reason: 'automatic migration is not a new user edit',
        );
        expect(entries.any((e) => e['id'] == y), isTrue);
        expect(
          (await FilterPresetsRepository().load('account')).single.id,
          legacy.id,
        );
      },
    );
  }
}
