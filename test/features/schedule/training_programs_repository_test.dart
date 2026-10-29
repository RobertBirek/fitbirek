import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/schedule/data/training_programs_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../../core/training_sets_programs_domain_test.dart'
    show planA, planB, planJson;
import '../exercises/catalog_filter_test.dart' show exercise;
import 'schedule_repository_test.dart' show TestAuthority;

const programMetadata = ExerciseCatalogMetadata(
  exercises: {
    'cw001': ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
  },
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late SyncService sync;
  late TrainingProgramsRepository repo;
  late String program;
  final day = CalendarDay.parse('2026-10-19');
  Future<String> create({ProgramLease? lease}) async => repo.create(
    lease ?? await repo.open('account'),
    name: 'Siła A/B',
    planSyncIds: [planA, planB],
    weekdays: {1, 3, 5},
    effectiveFrom: day,
    catalog: [exercise('cw001')],
    metadata: programMetadata,
  );
  Future<ProgramOccurrence> occurrence([int offset = 0]) async =>
      TrainingProgramSchedule(
        await repo.load('account'),
      ).between(day.plus(offset), day.plus(offset)).single;
  Future<String> session({
    bool ended = true,
    String? role = 'working',
    bool sets = true,
  }) async {
    final id = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            dataStart: DateTime.utc(2026, 10, 19),
            dataKoniec: Value(ended ? DateTime.utc(2026, 10, 19, 12) : null),
          ),
        );
    if (sets) {
      await db
          .into(db.setsLog)
          .insert(
            SetsLogCompanion.insert(
              sesjaId: id,
              cwiczenieId: 'cw001',
              nazwaCwiczeniaPl: 'Ćwiczenie',
              numerSerii: 1,
              powtorzenia: const Value(8),
              setRole: Value(role),
            ),
          );
    }
    return (await db.workoutDao.getSession(id))!.syncId;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = SyncService(db, CollectionServer());
    await sync.bindAccount('account');
    await saveProfile(db);
    for (final id in [planA, planB]) {
      await db
          .into(db.workoutPlans)
          .insert(
            WorkoutPlansCompanion.insert(
              nazwa: id == planA ? 'Plan A' : 'Plan B',
              cwiczeniaIds: '["cw001"]',
              cel: 'Własny szablon',
              syncId: Value(id),
              structureJson: Value(jsonEncode(planJson())),
            ),
          );
    }
    repo = TrainingProgramsRepository(db, today: () => day.plus(7));
    program = await create();
    await db.delete(db.syncOutbox).go();
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test(
    'open/load are read-only; rename keeps old exception snapshot and core',
    () async {
      final old = await occurrence();
      await repo.open('account', programId: program);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await repo.move('account', old, day.plus(1));
      await repo.rename(
        await repo.open('account', programId: program),
        'Nowa nazwa',
      );
      final s = TrainingProgramSchedule(await repo.load('account'));
      final moved = s.between(day, day.plus(2));
      expect(moved.first.name, 'Siła A/B');
      expect(moved.last.name, 'Nowa nazwa');
      expect(moved.first.id, old.id);
      expect(moved.first.planSyncId, planA);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
    },
  );
  test(
    'end exclusive is single assignment >=today; old overdue dates survive new program',
    () async {
      final lease = await repo.open('account', programId: program);
      await expectLater(repo.end(lease, day.plus(6)), throwsStateError);
      await repo.end(lease, day.plus(7));
      await expectLater(
        repo.end(await repo.open('account', programId: program), day.plus(8)),
        throwsStateError,
      );
      final old = TrainingProgramSchedule(
        await repo.load('account'),
      ).between(day, day.plus(13));
      expect(old.map((o) => o.date.value), [
        '2026-10-19',
        '2026-10-21',
        '2026-10-23',
      ]);
      final next = await create();
      expect(next, isNot(program));
      expect(
        TrainingProgramSchedule(
          await repo.load('account'),
        ).between(day, day).length,
        2,
      );
    },
  );
  test(
    'optimistic lease and move-away-back reject stale dialogs without outbox changes',
    () async {
      final lease = await repo.open('account', programId: program);
      final o = await occurrence();
      await repo.move('account', o, day.plus(1));
      final moved = TrainingProgramSchedule(
        await repo.load('account'),
      ).between(day.plus(1), day.plus(1)).single;
      await repo.move('account', moved, day);
      await expectLater(repo.move('account', o, day.plus(2)), throwsStateError);
      await repo.rename(lease, 'Nowsza nazwa');
      final rows = (await db.select(db.syncOutbox).get())
          .map((r) => r.toJson())
          .toList();
      await expectLater(repo.rename(lease, 'Nie nadpisuj'), throwsStateError);
      expect(
        (await db.select(db.syncOutbox).get()).map((r) => r.toJson()).toList(),
        rows,
      );
    },
  );
  for (final kind in ['active', 'empty', 'warmup']) {
    test('explicit completion rejects $kind session', () async {
      final s = await session(
        ended: kind != 'active',
        sets: kind != 'empty',
        role: kind == 'warmup' ? 'warmup' : 'working',
      );
      await expectLater(
        repo.complete('account', await occurrence(), s),
        throwsStateError,
      );
      expect((await occurrence()).sessionSyncId, isNull);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });
  }
  for (final role in [null, 'working']) {
    test(
      'manual partial completion accepts effective working $role; deletion invalidates without shifting',
      () async {
        final s = await session(role: role);
        await repo.complete('account', await occurrence(), s);
        expect(
          await repo.completionStatus('account', await occurrence()),
          ScheduleCompletion.completed,
        );
        await expectLater(
          repo.complete('account', await occurrence(2), s),
          throwsStateError,
        );
        await db
            .update(db.setsLog)
            .write(
              SetsLogCompanion(deletedAtUtc: Value(DateTime.now().toUtc())),
            );
        expect(
          await repo.completionStatus('account', await occurrence()),
          ScheduleCompletion.invalidated,
        );
        expect((await occurrence(2)).planSyncId, planB);
        expect(await db.select(db.personalRecords).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), hasLength(1));
      },
    );
  }
  for (final programFirst in [true, false]) {
    test(
      'one session cannot complete program and weekly, programFirst=$programFirst',
      () async {
        final weekly = ScheduleRepository(db);
        await weekly.addRule(
          'account',
          planSyncId: planA,
          name: 'Tydzień',
          weekday: 1,
          effectiveFrom: day,
        );
        final w = (await weekly.load('account')).between(day, day).single;
        final p = await occurrence();
        final s = await session();
        if (programFirst) {
          await repo.complete('account', p, s);
          await expectLater(weekly.complete('account', w, s), throwsStateError);
        } else {
          await weekly.complete('account', w, s);
          await expectLater(repo.complete('account', p, s), throwsStateError);
        }
      },
    );
  }
  test(
    'remote cross-collection duplicate is conflict on BOTH even if proof deleted',
    () async {
      final weekly = ScheduleRepository(db);
      await weekly.addRule(
        'account',
        planSyncId: planA,
        name: 'Tydzień',
        weekday: 1,
        effectiveFrom: day,
      );
      final w = (await weekly.load('account')).between(day, day).single;
      final s = await session();
      await repo.complete('account', await occurrence(), s);
      await UserCollectionsRepository(db).update(
        'account',
        'weeklySchedule',
        (entries) => entries.add({
          'id': w.id,
          'name': w.name,
          'kind': 'override',
          'ruleId': w.ruleId,
          'originalDate': day.value,
          'movedDate': day.value,
          'state': 'completed',
          'sessionSyncId': s,
          'ruleSnapshot': w.ruleSnapshot,
          'createdAtUtc': '2026-10-28T00:00:00Z',
          'updatedAtUtc': '2026-10-28T00:00:00Z',
        }),
      );
      await db
          .update(db.workoutSessions)
          .write(
            WorkoutSessionsCompanion(
              deletedAtUtc: Value(DateTime.now().toUtc()),
            ),
          );
      expect(
        await repo.completionStatus('account', await occurrence()),
        ScheduleCompletion.conflict,
      );
      expect(
        await weekly.completionStatus(
          'account',
          (await weekly.load('account')).between(day, day).single,
        ),
        ScheduleCompletion.conflict,
      );
    },
  );
  test(
    'missing plan, unsupported structure, missing exercise refuse create without writes',
    () async {
      for (final kind in ['missing', 'future', 'exercise']) {
        final lease = await repo.open('account');
        if (kind == 'missing') {
          await (db.update(
            db.workoutPlans,
          )..where((p) => p.syncId.equals(planA))).write(
            WorkoutPlansCompanion(deletedAtUtc: Value(DateTime.now().toUtc())),
          );
        }
        if (kind == 'future') {
          await db
              .update(db.workoutPlans)
              .write(
                WorkoutPlansCompanion(
                  deletedAtUtc: const Value(null),
                  structureJson: Value(jsonEncode(planJson(version: 9))),
                ),
              );
        }
        if (kind == 'exercise') {
          await db
              .update(db.workoutPlans)
              .write(
                WorkoutPlansCompanion(
                  structureJson: Value(jsonEncode(planJson())),
                ),
              );
        }
        await expectLater(
          repo.create(
            lease,
            name: 'Nie zapisuj',
            planSyncIds: [planA, planB],
            weekdays: {1},
            effectiveFrom: day,
            catalog: kind == 'exercise' ? [] : [exercise('cw001')],
            metadata: programMetadata,
          ),
          throwsStateError,
        );
      }
      expect((await repo.load('account')).entries, hasLength(1));
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );
  test(
    'create lease refuses a template edited while its picker was open',
    () async {
      final lease = await repo.open('account');
      await (db.update(
        db.workoutPlans,
      )..where((p) => p.syncId.equals(planA))).write(
        const WorkoutPlansCompanion(nazwa: Value('Równoległa edycja')),
      );
      await expectLater(create(lease: lease), throwsStateError);
      expect((await repo.load('account')).entries, hasLength(1));
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );
  test(
    'available legacy saved templates are not mistaken for unsupported future plans',
    () async {
      await db
          .update(db.workoutPlans)
          .write(const WorkoutPlansCompanion(structureJson: Value(null)));
      final id = await create();
      expect(id, isNot(program));
      expect((await repo.load('account')).entries, hasLength(2));
      expect(await db.select(db.workoutSessions).get(), isEmpty);
    },
  );
  test(
    'pending profile and unknown collection refuse rather than create empty fallback',
    () async {
      final lease = await repo.open('account');
      await db
          .update(db.userProfiles)
          .write(
            const UserProfilesCompanion(
              trainingProgramsJson: Value(
                '{"version":9,"entries":[],"raw":"future"}',
              ),
            ),
          );
      await expectLater(repo.load('account'), throwsFormatException);
      await expectLater(create(lease: lease), throwsFormatException);
      expect(
        (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson,
        '{"version":9,"entries":[],"raw":"future"}',
      );
      await db.delete(db.userProfiles).go();
      await expectLater(repo.open('account'), throwsStateError);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );
  test(
    'profile hold blocks all mutations but keeps local readable and attempted raw untouched',
    () async {
      final lease = await repo.open('account', programId: program);
      final o = await occurrence();
      final s = await session();
      final profile = (await db.userProfileDao.watchProfileOnce())!;
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'profile',
              entityId: profile.syncId,
              version: 1,
              recordJson: '{"future":"raw"}',
            ),
          );
      await expectLater(repo.rename(lease, 'Nie'), throwsStateError);
      await expectLater(repo.end(lease, day.plus(7)), throwsStateError);
      await expectLater(repo.move('account', o, day.plus(1)), throwsStateError);
      await expectLater(repo.complete('account', o, s), throwsStateError);
      expect((await repo.load('account')).entries, hasLength(1));
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      expect(
        (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
        '{"future":"raw"}',
      );
    },
  );
  for (final kind in ['push', 'pull']) {
    test(
      'generic $kind profile quarantine blocks program and weekly writes without changing raw or attempted',
      () async {
        await repo.rename(
          await repo.open('account', programId: program),
          'Oczekująca edycja',
        );
        final lease = await repo.open('account', programId: program);
        final pending = (await db.syncDao.pendingOperations()).single;
        final profile = (await db.userProfileDao.watchProfileOnce())!;
        final quarantine = SyncQuarantine(db, SyncStore(db));
        if (kind == 'push') {
          await db
              .update(db.syncOutbox)
              .write(const SyncOutboxCompanion(attempted: Value(true)));
          await quarantine.hold('account', pending, {
            'opaque': 'unknown response',
          });
        } else {
          await quarantine.apply(
            <String, dynamic>{
              'entityType': 'profile',
              'entityId': profile.syncId,
              'version': 3,
              'updatedAt': '2026-10-28T00:00:00Z',
              'payload': [],
            },
            'account',
            3,
            0,
          );
        }
        final raw = (await db.select(db.syncDeferredRecords).get())
            .map((r) => r.toJson())
            .toList();
        final outbox = (await db.select(db.syncOutbox).get())
            .map((r) => r.toJson())
            .toList();
        await expectLater(repo.rename(lease, 'Nie zapisuj'), throwsStateError);
        await expectLater(repo.open('account'), throwsStateError);
        await expectLater(
          ScheduleRepository(db).addRule(
            'account',
            planSyncId: planA,
            name: 'Nie zapisuj',
            weekday: 1,
            effectiveFrom: day,
          ),
          throwsStateError,
        );
        expect(
          (await repo.load('account')).entries.single['name'],
          'Oczekująca edycja',
        );
        expect(
          (await db.select(db.syncOutbox).get())
              .map((r) => r.toJson())
              .toList(),
          outbox,
        );
        expect(
          (await db.select(db.syncDeferredRecords).get())
              .map((r) => r.toJson())
              .toList(),
          raw,
        );
      },
    );
  }
  test(
    'queued A-B-A and pre-dialog lease epoch refuse; no other-account writes',
    () async {
      final auth = TestAuthority();
      repo = TrainingProgramsRepository(db, authority: auth);
      final lease = await repo.open('account', programId: program);
      final o = await occurrence();
      final entered = Completer<void>(), release = Completer<void>();
      final blocker = db.transaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final rejected = expectLater(
        repo.move('account', o, day.plus(1)),
        throwsStateError,
      );
      auth.generation += 2;
      release.complete();
      await blocker;
      await rejected;
      await expectLater(repo.rename(lease, 'Nie'), throwsStateError);
      await expectLater(repo.load('other'), throwsStateError);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );
}
