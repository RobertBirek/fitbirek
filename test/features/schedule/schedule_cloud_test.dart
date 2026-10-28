import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value, Uint8List, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/user_collections.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart' show saveProfile;
import '../../core/database/legacy_schema.dart' show removeV13Columns;
import '../../core/profile_cloud_review_test.dart' show ReviewServer;
import 'weekly_schedule_test.dart' show rule, ruleId, planId;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

// A transport failure is retryable. ReviewServer.blockPush instead
// returns an explicit indeterminateOperation, which must remain held
// until authoritative resolution; it is not an offline simulation.
Future<void> failPushTransport(SyncService sync, ReviewServer server) async {
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'explicit schedule null restore survives new scalar writes, attempted payload and CAS',
    () async {
      final a = AppDatabase.forTesting(NativeDatabase.memory()),
          b = AppDatabase.forTesting(NativeDatabase.memory());
      final server = ReviewServer();
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
      await UserCollectionsRepository(
        a,
      ).update('account', 'weeklySchedule', (e) => e.add(rule()));
      await sa.synchronize();
      await sb.synchronize();
      final backup =
          jsonDecode(utf8.decode(await BackupService(b).exportToBytes()))
              as Map<String, dynamic>;
      ((backup['data']['userProfiles'] as List).single
              as Map)['weeklyScheduleJson'] =
          null;
      expect(
        (await BackupService(b).importFromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(backup))),
        )).success,
        isTrue,
      );
      await failPushTransport(sb, server);
      final attempted = (await b.syncDao.pendingOperations()).single.toJson();
      await saveProfile(b, name: 'Po wyczyszczeniu');
      final pending = await b.syncDao.pendingOperations();
      expect(pending.first.toJson(), attempted);
      expect(pending.last.payload.containsKey('weeklySchedule'), isTrue);
      expect(pending.last.payload['weeklySchedule'], isNull);
      await saveProfile(a, height: 195);
      await sa.synchronize();
      for (var i = 0; i < 4; i++) {
        await sb.synchronize();
        await sa.synchronize();
      }
      expect(server.record!['payload']['weeklySchedule'], isNull);
      expect(
        (await b.userProfileDao.watchProfileOnce())!.weeklyScheduleJson,
        isNull,
      );
      expect(await b.syncDao.pendingOperations(), isEmpty);
      expect(sb.status, SyncStatus.idle);
    },
  );
  test(
    'Drift12 migration adds nullable schedule without rewriting old outbox',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await saveProfile(db);
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before = (await db.customSelect('SELECT * FROM sync_outbox').get())
          .map((r) => r.data)
          .toList();
      await removeV13Columns(db);
      await db.customStatement('PRAGMA user_version = 12');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      expect(
        (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson,
        isNull,
      );
      expect(db.schemaVersion, 15);
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').get())
            .map((r) => r.data)
            .toList(),
        before,
      );
    },
  );
  for (final deferred in [false, true]) {
    test(
      'two device per-ID schedule CAS, deferred=$deferred, attempted bytes immutable',
      () async {
        final a = AppDatabase.forTesting(NativeDatabase.memory()),
            b = AppDatabase.forTesting(NativeDatabase.memory());
        final server = ReviewServer();
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
        final ca = UserCollectionsRepository(a),
            cb = UserCollectionsRepository(b);
        await ca.update('account', 'weeklySchedule', (e) => e.add(rule()));
        await sa.synchronize();
        await sb.synchronize();
        await cb.update(
          'account',
          'weeklySchedule',
          (e) => e.add({...rule(), 'id': planId, 'name': 'B'}),
        );
        await ca.update('account', 'weeklySchedule', (e) {
          e[0] = rule(deleted: true, stamp: '2026-10-18T12:00:00.000Z');
        });
        await sa.synchronize();
        if (deferred) {
          await failPushTransport(sb, server);
          // Model a snapshot observed by another pull while this attempted
          // request is unresolved. A failed push does not itself run pull.
          await b.transaction(
            () => SyncStore(b).apply(Map<String, dynamic>.from(server.record!)),
          );
          expect(
            (await b.select(b.syncDeferredRecords).getSingle()).version,
            server.record!['version'],
          );
          final attempted = (await b.syncDao.pendingOperations()).single
              .toJson();
          await saveProfile(b, name: 'Późniejsza edycja');
          final pending = await b.syncDao.pendingOperations();
          expect(pending.first.toJson(), attempted);
          expect(
            pending.last.baseVersion,
            lessThan(server.record!['version'] as int),
          );
        }
        for (var i = 0; i < 4; i++) {
          await sb.synchronize();
          await sa.synchronize();
        }
        final x = await ca.load('account', 'weeklySchedule'),
            y = await cb.load('account', 'weeklySchedule');
        expect(sa.status, SyncStatus.idle);
        expect(sb.status, SyncStatus.idle);
        expect(UserCollections.canonical(x), UserCollections.canonical(y));
        expect(x['entries'], hasLength(2));
        expect(
          (x['entries'] as List).firstWhere(
            (e) => e['id'] == ruleId,
          )['deletedAtUtc'],
          isNotNull,
        );
      },
    );
  }
  test(
    'incoming omission preserves schedule, explicit null clears, old backup omission preserves',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, ReviewServer());
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await saveProfile(db);
      final c = UserCollectionsRepository(db);
      await c.update('account', 'weeklySchedule', (e) => e.add(rule()));
      await sync.synchronize();
      final p = (await db.userProfileDao.watchProfileOnce())!;
      final op = {
        'entityType': 'profile',
        'entityId': p.syncId,
        'version': 10,
        'updatedAt': '2026-10-20T00:00:00Z',
        'deletedAt': null,
        'payload': {
          'imie': p.imie,
          'wiek': p.wiek,
          'wzrostCm': p.wzrostCm,
          'wagaKg': p.wagaKg,
          'cel': p.cel,
          'dostepnySprzet': [],
          'onboardingZakonczony': true,
          'dataUtworzenia': p.dataUtworzenia.toUtc().toIso8601String(),
        },
      };
      await SyncStore(db).apply(op);
      expect(
        (await c.load('account', 'weeklySchedule'))['entries'],
        hasLength(1),
      );
      final backup =
          jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
              as Map<String, dynamic>;
      ((backup['data']['userProfiles'] as List).single as Map).remove(
        'weeklyScheduleJson',
      );
      expect(
        (await BackupService(db).importFromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(backup))),
        )).success,
        isTrue,
      );
      expect(
        (await c.load('account', 'weeklySchedule'))['entries'],
        hasLength(1),
      );
      await db.delete(db.syncOutbox).go();
      await SyncStore(db).apply({
        ...op,
        'version': 11,
        // Match the string-keyed object produced by JSON HTTP decoding.
        'payload': <String, dynamic>{
          ...op['payload'] as Map,
          'weeklySchedule': null,
        },
      });
      expect(
        (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson,
        isNull,
      );
    },
  );
  test(
    'backup roundtrip remaps schedule plan and completed session UUID references',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, ReviewServer());
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await saveProfile(db);
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Plan', cwiczeniaIds: ['cw001'], cel: 'mix');
      final plan = (await db.select(db.workoutPlans).getSingle()).syncId;
      final repo = ScheduleRepository(db);
      final day = CalendarDay.parse('2026-10-19');
      await repo.addRule(
        'account',
        planSyncId: plan,
        name: 'Plan',
        weekday: 1,
        effectiveFrom: day,
      );
      final id = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              dataStart: DateTime.now(),
              dataKoniec: Value(DateTime.now()),
            ),
          );
      await db
          .into(db.setsLog)
          .insert(
            SetsLogCompanion.insert(
              sesjaId: id,
              cwiczenieId: 'cw001',
              nazwaCwiczeniaPl: 'Cw',
              numerSerii: 1,
            ),
          );
      final s = (await db.select(db.workoutSessions).getSingle()).syncId;
      final o = (await repo.load('account')).between(day, day).single;
      await repo.complete('account', o, s);
      final bytes = await BackupService(db).exportToBytes();
      expect((await BackupService(db).importFromBytes(bytes)).success, isTrue);
      final restored = (await repo.load('account')).between(day, day).single;
      expect(restored.id, o.id);
      expect(
        await repo.completionStatus('account', restored),
        ScheduleCompletion.completed,
      );
      expect(
        restored.planSyncId,
        (await db.select(db.workoutPlans).getSingle()).syncId,
      );
    },
  );
}
