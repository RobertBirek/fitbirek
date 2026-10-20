import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import 'schedule_repository_test.dart' show TestAuthority;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late SyncService sync;
  late ActivityRepository repo;
  final day = CalendarDay.parse('2026-10-19');
  ActivityDraft draft({
    String name = 'Basen',
    ActivityType type = ActivityType.external,
  }) => ActivityDraft(
    name: name,
    activityType: type,
    weekdays: {1, 7},
    time: '12:30',
    effectiveFrom: day,
  );
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
  Future<String> create() async =>
      repo.create(await repo.snapshot('account'), draft());
  Future<List<Map<String, dynamic>>> outbox() async =>
      (await db.select(db.syncOutbox).get()).map((r) => r.toJson()).toList();

  test(
    'legacy edits require explicit time before enable toggle and keep original UUID tombstone',
    () async {
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Legacy', cwiczeniaIds: ['cw001'], cel: 'mix');
      final plan = (await db.select(db.workoutPlans).getSingle()).syncId;
      final id = await ScheduleRepository(db).addRule(
        'account',
        planSyncId: plan,
        name: 'Legacy',
        weekday: 1,
        effectiveFrom: day,
      );
      final lease = await repo.snapshot('account');
      expect(lease.rules.single.time, isNull);
      final before = await outbox();
      await expectLater(repo.setEnabled(lease, id, false), throwsStateError);
      expect(await outbox(), before);
      final replacement = await repo.update(
        lease,
        id,
        draft(type: ActivityType.fitbirek),
      );
      final fresh = await repo.snapshot('account');
      expect(fresh.rules.single.id, replacement);
      expect(fresh.rules.single.time, '12:30');
      expect(fresh.rules.single.isLegacy, isFalse);
      expect(
        fresh.schedule.entries.singleWhere(
          (e) => e['id'] == id,
        )['deletedAtUtc'],
        isNotNull,
      );
    },
  );

  test(
    'replacement respects 500 entries including tombstones and rolls transaction back',
    () async {
      final id = await create();
      final seed = (await repo.snapshot('account')).rules.single.toJson();
      await UserCollectionsRepository(db).update('account', 'weeklySchedule', (
        entries,
      ) {
        for (var n = 1; n < 500; n++) {
          entries.add({
            ...seed,
            'id': const Uuid().v5(id, '$n'),
            'deletedAtUtc': seed['updatedAtUtc'],
          });
        }
      });
      final lease = await repo.snapshot('account');
      final raw =
          (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson;
      final pending = await outbox();
      await expectLater(
        repo.update(lease, id, draft(name: 'Over limit')),
        throwsFormatException,
      );
      expect(
        (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson,
        raw,
      );
      expect(await outbox(), pending);
      await repo.delete(lease, id);
      expect((await repo.snapshot('account')).rules, isEmpty);
    },
  );

  test(
    'CRUD replaces UUID atomically, stale full baseline cannot overwrite; tombstones persist',
    () async {
      final id = await create();
      final lease = await repo.snapshot('account');
      final replacement = await repo.update(lease, id, draft(name: 'Nowy'));
      expect(replacement, isNot(id));
      final fresh = await repo.snapshot('account');
      expect(fresh.rules.single.id, replacement);
      expect(
        fresh.schedule.entries.singleWhere(
          (e) => e['id'] == id,
        )['deletedAtUtc'],
        isNotNull,
      );
      final before = await outbox();
      await expectLater(
        repo.update(lease, id, draft(name: 'Stary')),
        throwsStateError,
      );
      expect(await outbox(), before);
      await repo.delete(fresh, replacement);
      expect((await repo.snapshot('account')).rules, isEmpty);
    },
  );
  test(
    'external completion has no session/set/PR; disable and replacement preserve exact history',
    () async {
      final id = await create();
      final scheduleRepo = ScheduleRepository(db);
      final o = (await scheduleRepo.load('account')).between(day, day).single;
      await scheduleRepo.completeExternal('account', o);
      final history = (await scheduleRepo.load(
        'account',
      )).entries.singleWhere((e) => e['kind'] == 'activityOverride');
      final disabled = await repo.setEnabled(
        await repo.snapshot('account'),
        id,
        false,
      );
      final snapshot = await repo.snapshot('account');
      expect(snapshot.rules.single.id, disabled);
      final occurrences = snapshot.schedule.between(day, day.plus(7));
      expect(occurrences, hasLength(1));
      expect(occurrences.single.externalCompleted, isTrue);
      expect(
        await scheduleRepo.completionStatus('account', occurrences.single),
        ScheduleCompletion.completed,
      );
      expect(
        snapshot.schedule.entries.singleWhere(
          (e) => e['kind'] == 'activityOverride',
        ),
        history,
      );
      await expectLater(
        scheduleRepo.move('account', o, day.plus(1)),
        throwsStateError,
      );
      await expectLater(
        scheduleRepo.complete(
          'account',
          o,
          '11111111-1111-4111-8111-111111111111',
        ),
        throwsStateError,
      );
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
    },
  );
  test('untemplated fitbirek still needs actual completion proof', () async {
    await repo.create(
      await repo.snapshot('account'),
      draft(type: ActivityType.fitbirek),
    );
    final old = ScheduleRepository(db);
    final o = (await old.load('account')).between(day, day).single;
    await expectLater(old.completeExternal('account', o), throwsStateError);
    await expectLater(
      old.complete('account', o, '11111111-1111-4111-8111-111111111111'),
      throwsStateError,
    );
  });
  test(
    'deferred or held profile refuses all mutation and keeps attempted row bytes',
    () async {
      final id = await create();
      final lease = await repo.snapshot('account');
      await db
          .update(db.syncOutbox)
          .write(const SyncOutboxCompanion(attempted: Value(true)));
      final before = await outbox();
      final profile = await db.userProfileDao.watchProfileOnce();
      final raw = profile!.weeklyScheduleJson;
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'profile',
              entityId: profile.syncId,
              version: 3,
              recordJson: jsonEncode({
                '_profileCollectionConflict': {},
                'payload': {
                  'weeklySchedule': {'version': 2},
                },
              }),
            ),
          );
      await expectLater(repo.create(lease, draft()), throwsStateError);
      await expectLater(repo.update(lease, id, draft()), throwsStateError);
      await expectLater(repo.delete(lease, id), throwsStateError);
      final old = ScheduleRepository(db);
      final o = lease.schedule.between(day, day).single;
      await expectLater(old.move('account', o, day.plus(1)), throwsStateError);
      await expectLater(old.completeExternal('account', o), throwsStateError);
      expect(
        (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson,
        raw,
      );
      expect(await outbox(), before);
    },
  );
  test(
    'quarantined local JSON is not repaired and invalid draft rolls back',
    () async {
      final lease = await repo.snapshot('account');
      final before = await outbox();
      await expectLater(
        repo.create(
          lease,
          ActivityDraft(
            name: '',
            activityType: ActivityType.external,
            weekdays: {1},
            time: '12:30',
            effectiveFrom: day,
          ),
        ),
        throwsFormatException,
      );
      expect(await outbox(), before);
      await db
          .update(db.userProfiles)
          .write(
            const UserProfilesCompanion(
              weeklyScheduleJson: Value('{"version":2,"entries":[]}'),
            ),
          );
      await expectLater(repo.create(lease, draft()), throwsFormatException);
      expect(
        (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson,
        '{"version":2,"entries":[]}',
      );
    },
  );
  test(
    'lease invalid after A-B-A, including queued write and false dialog guard',
    () async {
      final authority = TestAuthority();
      repo = ActivityRepository(db, authority: authority);
      final lease = await repo.snapshot('account');
      final entered = Completer<void>(), release = Completer<void>();
      final blocker = db.transaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final rejected = expectLater(
        repo.create(lease, draft()),
        throwsStateError,
      );
      authority.generation += 2;
      release.complete();
      await blocker;
      await rejected;
      await expectLater(repo.create(lease, draft()), throwsStateError);
      await expectLater(
        repo.create(
          await repo.snapshot('account'),
          draft(),
          isCurrent: () => false,
        ),
        throwsStateError,
      );
      expect((await repo.snapshot('account')).rules, isEmpty);
    },
  );
  test('concurrent changed baseline and immutable draft snapshot', () async {
    final id = await create();
    final lease = await repo.snapshot('account');
    final leaked = lease.rules.single.toJson();
    (leaked['weekdays'] as List).clear();
    expect(lease.rules.single.weekdays, {1, 7});
    await UserCollectionsRepository(db).update('account', 'weeklySchedule', (
      entries,
    ) {
      entries.single['name'] = 'Remote';
    });
    await expectLater(repo.delete(lease, id), throwsStateError);
    expect((await repo.snapshot('account')).rules.single.name, 'Remote');
  });
  test(
    'stable per profile/source migration ID remains present as tombstone after edit',
    () async {
      final profile = (await db.userProfileDao.watchProfileOnce())!.syncId;
      final id = legacyActivityRuleId(
        profile,
        LegacyActivitySource.legacyKarate,
      );
      expect(
        legacyActivityRuleId(profile, LegacyActivitySource.legacyKarate),
        id,
      );
      expect(
        legacyActivityRuleId(profile, LegacyActivitySource.legacyTraining),
        isNot(id),
      );
      final stamp = DateTime.now().toUtc().toIso8601String();
      await UserCollectionsRepository(db).update('account', 'weeklySchedule', (
        entries,
      ) {
        entries.add({
          ...draft().toFields(),
          'kind': 'activityRule',
          'id': id,
          'legacySource': 'legacyKarate',
          'createdAtUtc': stamp,
          'updatedAtUtc': stamp,
        });
      });
      await repo.update(
        await repo.snapshot('account'),
        id,
        draft(name: 'Inny'),
      );
      final marker = (await repo.snapshot(
        'account',
      )).schedule.entries.singleWhere((e) => e['id'] == id);
      expect(marker['deletedAtUtc'], isNotNull);
      expect(marker['legacySource'], 'legacyKarate');
    },
  );
}
