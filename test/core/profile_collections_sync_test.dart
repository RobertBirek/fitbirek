import 'dart:convert';
import 'dart:async';
import 'package:drift/drift.dart' show Value, Uint8List, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/profile_payload.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/exercises/data/filter_presets_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/core/models/user_profile.dart'
    as profile_model;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

class LostCollectionAck extends CollectionServer {
  bool lose = false;
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> operations) async {
    final response = await super.push(operations);
    if (lose) {
      lose = false;
      throw StateError('Lost response after commit');
    }
    return response;
  }
}

class CollectionServer implements SyncApi {
  Map<String, dynamic>? record;
  final log = <Map<String, dynamic>>[];
  final attempts = <SyncOperation>[];
  final acknowledgements = <String, Map<String, dynamic>>{};
  Future<void> Function()? beforePush;
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> operations) async {
    await beforePush?.call();
    final accepted = <Map<String, dynamic>>[],
        conflicts = <Map<String, dynamic>>[];
    for (final op in operations) {
      attempts.add(op);
      final previous = acknowledgements[op.operationId];
      if (previous != null) {
        accepted.add({...previous, 'duplicate': true});
        continue;
      }
      if (record != null && op.baseVersion != record!['version']) {
        conflicts.add({'operationId': op.operationId, 'record': record});
        continue;
      }
      final version = (record?['version'] as int? ?? 0) + 1;
      final stamp = DateTime.now().toUtc().toIso8601String();
      record = {
        'entityType': 'profile',
        'entityId': op.entityId,
        'version': version,
        'payload': jsonDecode(jsonEncode(op.payload)),
        'updatedAt': stamp,
        'deletedAt': op.deleted ? stamp : null,
      };
      log.add(record!);
      final ack = {
        'operationId': op.operationId,
        'version': version,
        'updatedAt': stamp,
        'duplicate': false,
      };
      acknowledgements[op.operationId] = ack;
      accepted.add(ack);
    }
    return {'accepted': accepted, 'conflicts': conflicts};
  }

  @override
  Future<Map<String, dynamic>> pull(int cursor) async => {
    'cursor': log.length,
    'changes': log.skip(cursor).toList(),
  };
}

Future<void> saveProfile(
  AppDatabase db, {
  String name = 'Robert',
  double height = 180,
}) => UserProfileRepository(db).saveProfile(
  imie: name,
  wiek: 40,
  wzrostCm: height,
  wagaKg: 80,
  cel: CelTreningowy.mix,
  dostepnySprzet: ['Hantle'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'queued cloud preference save cannot cross an account switch while awaiting preferences',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('a');
      await saveProfile(db);
      await db.delete(db.syncOutbox).go();
      final prefs = await SharedPreferences.getInstance();
      final entered = Completer<void>(),
          release = Completer<SharedPreferences>();
      var current = true;
      final repository = FilterPresetsRepository(
        cloud: UserCollectionsRepository(db),
        preferences: () {
          if (!entered.isCompleted) entered.complete();
          return release.future;
        },
      );
      final saving = repository.save(
        'a',
        'Nie publikuj',
        const ExerciseFilters(),
        isCurrent: () => current,
      );
      final rejected = expectLater(saving, throwsStateError);
      await entered.future;
      current = false;
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(accountId: Value('b')));
      await db
          .update(db.userProfiles)
          .write(const UserProfilesCompanion(imie: Value('Konto B')));
      release.complete(prefs);
      await rejected;
      expect((await db.userProfileDao.watchProfileOnce())!.imie, 'Konto B');
      expect(
        (await db.userProfileDao.watchProfileOnce())!.filterPresetsJson,
        isNull,
      );
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(
        prefs.getBool(
          '${FilterPresetsRepository.storageKey('a')}.drift-imported',
        ),
        isNull,
      );
    },
  );
  test(
    'collection conflict never resurrects deleted profile, including preserveLocal restore intent',
    () async {
      final server = CollectionServer();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, server);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('a');
      await saveProfile(db);
      await sync.synchronize();
      await FilterPresetsRepository(
        cloud: UserCollectionsRepository(db),
      ).save('a', 'Pending', const ExerciseFilters());
      await db
          .update(db.syncOutbox)
          .write(const SyncOutboxCompanion(preserveLocal: Value(true)));
      server.record = {
        ...server.record!,
        'version': 2,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      };
      server.log.add(server.record!);
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(
        (await db.userProfileDao.watchProfileOnce())!.deletedAtUtc,
        isNotNull,
      );
      expect(server.attempts, hasLength(2));
    },
  );
  test(
    'profile backup + reopen + duplicate acknowledgement leaves attempted snapshot immutable',
    () async {
      final raw = sqlite.sqlite3.openInMemory(), server = LostCollectionAck();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      var sync = SyncService(db, server);
      await sync.bindAccount('account');
      await saveProfile(db);
      await sync.synchronize();
      final repository = FilterPresetsRepository(
        cloud: UserCollectionsRepository(db),
      );
      await repository.save(
        'account',
        'Trwałe',
        const ExerciseFilters(query: 'all'),
      );
      final payload = profilePayload(
        (await db.userProfileDao.watchProfileOnce())!,
      );
      // The existing public model deliberately ignores optional extension keys.
      expect(
        profile_model.UserProfile.fromJson({...payload, 'id': 1}).imie,
        'Robert',
      );
      server.lose = true;
      await sync.synchronize();
      final attempted = (await db.syncDao.pendingOperations()).single.toJson();
      final backup = await BackupService(db).exportToBytes();
      sync.dispose();
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      sync = SyncService(db, server);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      expect((await db.syncDao.pendingOperations()).single.toJson(), attempted);
      expect((await BackupService(db).importFromBytes(backup)).success, isTrue);
      expect((await db.syncDao.pendingOperations()).first.toJson(), attempted);
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(
        (await FilterPresetsRepository(
          cloud: UserCollectionsRepository(db),
        ).load('account')).single.name,
        'Trwałe',
      );
      expect(
        server.attempts
            .where((o) => o.operationId == attempted['operationId'])
            .map((o) => o.toJson())
            .toList(),
        [attempted, attempted],
      );
    },
  );
  test(
    'two devices merge different entries and server scalar wins, tombstone never resurrects',
    () async {
      final server = CollectionServer();
      final a = AppDatabase.forTesting(NativeDatabase.memory()),
          b = AppDatabase.forTesting(NativeDatabase.memory());
      final sa = SyncService(a, server), sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
      });
      await sa.bindAccount('account');
      await sb.bindAccount('account');
      await saveProfile(a);
      await sa.synchronize();
      await sb.synchronize();
      final ra = FilterPresetsRepository(cloud: UserCollectionsRepository(a));
      final rb = FilterPresetsRepository(cloud: UserCollectionsRepository(b));
      final first = await ra.save(
        'account',
        'Urządzenie A',
        const ExerciseFilters(query: 'A'),
      );
      await rb.save(
        'account',
        'Urządzenie B',
        const ExerciseFilters(query: 'B'),
      );
      await saveProfile(a, height: 190);
      await sa.synchronize();
      await sb.synchronize();
      await sa.synchronize();
      expect((await ra.load('account')).map((e) => e.name).toSet(), {
        'Urządzenie A',
        'Urządzenie B',
      });
      expect((await rb.load('account')).length, 2);
      expect((await b.userProfileDao.watchProfileOnce())!.wzrostCm, 190);
      expect(await b.syncDao.pendingOperations(), isEmpty);
      await ra.delete('account', first.id);
      await rb.save(
        'account',
        'Urządzenie B',
        const ExerciseFilters(query: 'new'),
        overwriteId: (await rb.load(
          'account',
        )).firstWhere((e) => e.name == 'Urządzenie B').id,
      );
      await sa.synchronize();
      await sb.synchronize();
      await sa.synchronize();
      expect((await ra.load('account')).map((e) => e.name), ['Urządzenie B']);
      final entries =
          jsonDecode(
                (await b.userProfileDao.watchProfileOnce())!.filterPresetsJson!,
              )['entries']
              as List;
      expect(
        entries.firstWhere((e) => e['id'] == first.id)['deletedAtUtc'],
        isNotNull,
      );
      expect(
        server.attempts.where((e) => e.entityType != SyncEntityType.profile),
        isEmpty,
      );
    },
  );

  test(
    'later pending scalar and collections survive first conflict and final merge',
    () async {
      final server = CollectionServer();
      final a = AppDatabase.forTesting(NativeDatabase.memory()),
          b = AppDatabase.forTesting(NativeDatabase.memory());
      final sa = SyncService(a, server), sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
      });
      await sa.bindAccount('account');
      await sb.bindAccount('account');
      await saveProfile(a);
      await sa.synchronize();
      await sb.synchronize();
      final ra = FilterPresetsRepository(cloud: UserCollectionsRepository(a)),
          rb = FilterPresetsRepository(cloud: UserCollectionsRepository(b));
      await ra.save('account', 'A', const ExerciseFilters());
      await sa.synchronize();
      await rb.save('account', 'B', const ExerciseFilters());
      var once = true;
      server.beforePush = () async {
        if (once) {
          once = false;
          await rb.save('account', 'C', const ExerciseFilters());
          await saveProfile(b, name: 'Późniejszy');
        }
      };
      await sb.synchronize();
      expect((await rb.load('account')).map((e) => e.name).toSet(), {
        'A',
        'B',
        'C',
      });
      // Existing profile scalar policy: final rejected edit takes server scalar.
      expect((await b.userProfileDao.watchProfileOnce())!.imie, 'Robert');
      expect(await b.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'migration account-scoped once, profile save, old omission, invalid sibling, backup preservation',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('a');
      await saveProfile(db);
      final legacy = FilterPresetsRepository();
      final item = await legacy.save(
        'a',
        'Dom',
        const ExerciseFilters(query: 'local'),
      );
      await legacy.save('b', 'Obce', const ExerciseFilters());
      final cloud = FilterPresetsRepository(
        cloud: UserCollectionsRepository(db),
      );
      expect((await cloud.load('a')).single.id, item.id);
      await cloud.delete('a', item.id);
      expect(await cloud.load('a'), isEmpty);
      expect((await legacy.load('a')).single.id, item.id);
      await saveProfile(db, name: 'Nowe imię');
      final row = (await db.userProfileDao.watchProfileOnce())!;
      expect(jsonDecode(row.filterPresetsJson!)['entries'], hasLength(1));
      await db.delete(db.syncOutbox).go();
      final wire = profilePayload(row)..remove('filterPresets');
      final record = {
        'entityType': 'profile',
        'entityId': row.syncId,
        'version': 10,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'deletedAt': null,
        'payload': wire,
      };
      await db.transaction(() => SyncStore(db).apply(record));
      expect(
        (await db.userProfileDao.watchProfileOnce())!.filterPresetsJson,
        row.filterPresetsJson,
      );
      wire['exerciseVariants'] = {'version': 999, 'entries': []};
      await db.transaction(
        () => SyncStore(db).apply({...record, 'version': 11}),
      );
      expect(await cloud.load('a'), isEmpty);
      await expectLater(
        UserCollectionsRepository(db).load('a', 'exerciseVariants'),
        throwsFormatException,
      );
      await db
          .update(db.userProfiles)
          .write(
            const UserProfilesCompanion(exerciseVariantsJson: Value(null)),
          );
      final backup =
          jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
              as Map<String, dynamic>;
      final backupProfile =
          (backup['data']['userProfiles'] as List).single as Map;
      backupProfile.remove('filterPresetsJson');
      backupProfile.remove('exerciseVariantsJson');
      expect(
        (await BackupService(db).importFromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(backup))),
        )).success,
        isTrue,
      );
      expect(
        (await db.userProfileDao.watchProfileOnce())!.filterPresetsJson,
        row.filterPresetsJson,
      );
    },
  );
}
