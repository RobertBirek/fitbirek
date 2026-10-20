import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/data/activity_migration.dart';
import 'dart:async';
import 'dart:io';
import '../../core/push_settings_test.dart' show FakePush;
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import 'schedule_repository_test.dart' show TestAuthority;

class MigrationPush extends FakePush {
  final response = Completer<Map<String, dynamic>>();
  final started = Completer<void>();
  @override
  Future<Map<String, dynamic>> status(String accountId) {
    started.complete();
    return response.future;
  }
}

void main() {
  late AppDatabase db;
  late SyncService sync;
  late ActivityRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = SyncService(db, CollectionServer());
    await sync.bindAccount('account');
    await saveProfile(db);
    repo = ActivityRepository(db);
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });
  test(
    'migration preserves attempted operation bytes and refuses deferred profile or revoked offline access',
    () async {
      final lease = await repo.snapshot('account');
      await db
          .update(db.syncOutbox)
          .write(const SyncOutboxCompanion(attempted: Value(true)));
      final attempted = (await db.syncDao.pendingOperations()).single.toJson();
      await repo.seedLegacy(lease, karate: false, training: true);
      expect((await db.syncDao.pendingOperations()).first.toJson(), attempted);
      expect(await db.syncDao.pendingOperations(), hasLength(2));
      final seeded = await repo.snapshot('account');
      final before = (await db.select(db.syncOutbox).get())
          .map((e) => e.toJson())
          .toList();
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'profile',
              entityId: lease.profileSyncId,
              version: 3,
              recordJson: '{"payload":{"weeklySchedule":{"version":2}}}',
            ),
          );
      await expectLater(
        migrateLegacyActivities(
          repo,
          'account',
          isCurrent: () => true,
          karate: true,
          training: true,
        ),
        throwsStateError,
      );
      expect(
        (await db.select(db.syncOutbox).get()).map((e) => e.toJson()).toList(),
        before,
      );
      expect(
        (await repo.snapshot('account')).schedule.toJson(),
        seeded.schedule.toJson(),
      );
      await db.syncDao.lockOfflineAccess();
      await expectLater(
        repo.seedLegacy(seeded, karate: true, training: true),
        throwsStateError,
      );
      expect(
        (await db.select(db.syncOutbox).get()).map((e) => e.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'two devices seed same profile once, sync deletion and restart never resurrects',
    () async {
      final directory = await Directory.systemTemp.createTemp('fit-migration-');
      final file = File('${directory.path}/device.sqlite');
      final server = CollectionServer();
      final a = AppDatabase.forTesting(NativeDatabase.memory());
      var b = AppDatabase.forTesting(NativeDatabase(file));
      final sa = SyncService(a, server);
      var sb = SyncService(b, server);
      try {
        await sa.bindAccount('account');
        await sb.bindAccount('account');
        await saveProfile(a);
        await sa.synchronize();
        await sb.synchronize();
        final ar = ActivityRepository(a);
        var br = ActivityRepository(b);
        await ar.seedLegacy(
          await ar.snapshot('account'),
          karate: true,
          training: false,
        );
        await br.seedLegacy(
          await br.snapshot('account'),
          karate: false,
          training: true,
        );
        for (var n = 0; n < 3; n++) {
          await sa.synchronize();
          await sb.synchronize();
        }
        expect((await ar.snapshot('account')).rules, hasLength(2));
        expect((await br.snapshot('account')).rules, hasLength(2));
        final lease = await ar.snapshot('account');
        await ar.delete(
          lease,
          legacyActivityRuleId(
            lease.profileSyncId,
            LegacyActivitySource.legacyKarate,
          ),
        );
        await sa.synchronize();
        await sb.synchronize();
        sb.dispose();
        await b.close();
        b = AppDatabase.forTesting(NativeDatabase(file));
        sb = SyncService(b, server);
        br = ActivityRepository(b);
        final reopened = await br.snapshot('account');
        await br.seedLegacy(reopened, karate: true, training: true);
        expect((await br.snapshot('account')).rules, hasLength(1));
        expect((await br.snapshot('account')).schedule.entries, hasLength(2));
      } finally {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'PWA unknown offline never infers false or suppresses legacy, explicit retry succeeds',
    () async {
      final push = MigrationPush();
      final operation = migrateLegacyActivities(
        repo,
        'account',
        isCurrent: () => true,
        push: push,
      );
      await push.started.future;
      final before = (await db.select(db.syncOutbox).get())
          .map((e) => e.toJson())
          .toList();
      push.response.complete({
        'supported': true,
        'enabled': true,
        'categories': {'karate': true, 'training': false},
        'server': {'reason': 'offline'},
      });
      await expectLater(operation, throwsStateError);
      expect((await repo.snapshot('account')).rules, isEmpty);
      expect(
        (await db.select(db.syncOutbox).get()).map((e) => e.toJson()).toList(),
        before,
      );
      final retry = MigrationPush();
      final done = migrateLegacyActivities(
        repo,
        'account',
        isCurrent: () => true,
        push: retry,
      );
      await retry.started.future;
      retry.response.complete({
        'supported': true,
        'enabled': true,
        'categories': {'karate': true, 'training': false},
        'server': {'reason': 'ready'},
      });
      final result = await done;
      expect(
        result.rules
            .singleWhere((r) => r.activityType == ActivityType.external)
            .reminderEnabled,
        isTrue,
      );
      expect(
        result.rules
            .singleWhere((r) => r.activityType == ActivityType.fitbirek)
            .reminderEnabled,
        isFalse,
      );
      expect(push.enables, 0);
      expect(retry.enables, 0);
    },
  );
  test(
    'PWA lease captured before HTTP rejects A B A while response pending',
    () async {
      final authority = TestAuthority();
      repo = ActivityRepository(db, authority: authority);
      final push = MigrationPush();
      final operation = migrateLegacyActivities(
        repo,
        'account',
        isCurrent: () => true,
        push: push,
      );
      await push.started.future;
      authority.generation += 2;
      push.response.complete({
        'supported': true,
        'enabled': true,
        'categories': {'karate': true, 'training': true},
        'server': {'reason': 'ready'},
      });
      await expectLater(operation, throwsStateError);
      expect((await ActivityRepository(db).snapshot('account')).rules, isEmpty);
    },
  );
  test(
    'deterministic migration idempotent and keeps tombstone on restart',
    () async {
      final lease = await repo.snapshot('account');
      await repo.seedLegacy(lease, karate: true, training: false);
      var fresh = await repo.snapshot('account');
      expect(fresh.rules, hasLength(2));
      final karate = fresh.rules.singleWhere(
        (r) => r.activityType == ActivityType.external,
      );
      expect(
        karate.id,
        legacyActivityRuleId(
          lease.profileSyncId,
          LegacyActivitySource.legacyKarate,
        ),
      );
      expect(karate.time, '20:00');
      expect(karate.weekdays, {2, 4});
      expect(karate.reminderMinutesBefore, 30);
      expect(karate.reminderEnabled, isTrue);
      final training = fresh.rules.singleWhere(
        (r) => r.activityType == ActivityType.fitbirek,
      );
      expect(training.time, '18:00');
      expect(training.enabled, isFalse);
      expect(training.reminderEnabled, isFalse);
      await repo.delete(fresh, karate.id);
      fresh = await repo.snapshot('account');
      final before = (await db.select(db.syncOutbox).get())
          .map((e) => e.toJson())
          .toList();
      await ActivityRepository(
        db,
      ).seedLegacy(fresh, karate: true, training: true);
      final after = await repo.snapshot('account');
      expect(after.rules, hasLength(1));
      expect(after.rules.single.reminderEnabled, isFalse);
      expect(after.schedule.toJson(), fresh.schedule.toJson());
      expect(
        (await db.select(db.syncOutbox).get()).map((e) => e.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'captured account epoch forbids A B A migration without outbox writes',
    () async {
      final authority = TestAuthority();
      repo = ActivityRepository(db, authority: authority);
      final lease = await repo.snapshot('account');
      authority.generation += 2;
      final before = (await db.select(db.syncOutbox).get())
          .map((e) => e.toJson())
          .toList();
      await expectLater(
        repo.seedLegacy(lease, karate: true, training: true),
        throwsStateError,
      );
      expect(
        (await db.select(db.syncOutbox).get()).map((e) => e.toJson()).toList(),
        before,
      );
      expect((await ActivityRepository(db).snapshot('account')).rules, isEmpty);
    },
  );
}
