import 'dart:async';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;

class TestAuthority extends CachedAuthWriteAuthority {
  int generation = 0;
  @override
  int get epoch => generation;
  @override
  AuthState get state => const AuthState.signedIn('account');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late SyncService sync;
  late ScheduleRepository repo;
  late String rule, plan;
  final day = CalendarDay.parse('2026-10-19');
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = SyncService(db, CollectionServer());
    await sync.bindAccount('account');
    await saveProfile(db);
    await PlannerRepository(
      db,
    ).savePlan(nazwa: 'Plan', cwiczeniaIds: ['cw001'], cel: 'mix');
    plan = (await db.select(db.workoutPlans).getSingle()).syncId;
    repo = ScheduleRepository(db);
    rule = await repo.addRule(
      'account',
      planSyncId: plan,
      name: 'Plan',
      weekday: 1,
      effectiveFrom: day,
    );
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });
  Future<ScheduleOccurrence> occurrence() async =>
      (await repo.load('account')).between(day, day.plus(6)).single;
  Future<String> session({bool ended = false, bool sets = false}) async {
    final id = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            dataStart: DateTime.now(),
            dataKoniec: Value(ended ? DateTime.now() : null),
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
            ),
          );
    }
    return (await (db.select(
      db.workoutSessions,
    )..where((s) => s.id.equals(id))).getSingle()).syncId;
  }

  test(
    'move is one occurrence, past allowed, original UUID is retained',
    () async {
      final o = await occurrence();
      await repo.move('account', o, day.plus(-1));
      final items = (await repo.load(
        'account',
      )).between(day.plus(-1), day.plus(13));
      expect(items.map((e) => e.date.value), ['2026-10-18', '2026-10-26']);
      expect(items.first.id, o.id);
    },
  );
  test('explicit completion rejects active and empty ended sessions', () async {
    final o = await occurrence();
    await expectLater(
      repo.complete('account', o, await session(sets: true)),
      throwsStateError,
    );
    await expectLater(
      repo.complete('account', o, await session(ended: true)),
      throwsStateError,
    );
    expect((await occurrence()).sessionSyncId, isNull);
  });
  test(
    'completion creates no sets or PR; duplicate session rejected; deleted session invalidates',
    () async {
      final o = await occurrence();
      final s = await session(ended: true, sets: true);
      await repo.complete('account', o, s);
      expect(
        await repo.completionStatus('account', await occurrence()),
        ScheduleCompletion.completed,
      );
      final next = (await repo.load(
        'account',
      )).between(day.plus(7), day.plus(7)).single;
      await expectLater(repo.complete('account', next, s), throwsStateError);
      await expectLater(repo.move('account', o, day.plus(2)), throwsStateError);
      await repo.deleteRule('account', rule);
      expect((await occurrence()).sessionSyncId, s);
      final row = await db.select(db.workoutSessions).getSingle();
      await SyncStore(db).apply({
        'entityType': 'workoutSession',
        'entityId': s,
        'version': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'payload': {
          'dataStart': row.dataStart.toUtc().toIso8601String(),
          'dataKoniec': row.dataKoniec!.toUtc().toIso8601String(),
          'czasTrwaniaSekund': 0,
          'notatka': null,
        },
      });
      expect(
        await repo.completionStatus('account', await occurrence()),
        ScheduleCompletion.invalidated,
      );
      expect(await db.select(db.setsLog).get(), hasLength(1));
      expect(await db.select(db.personalRecords).get(), isEmpty);
    },
  );
  test(
    'account guard rolls back completion and rule references must be live UUID',
    () async {
      final o = await occurrence();
      final s = await session(ended: true, sets: true);
      await expectLater(repo.complete('other', o, s), throwsStateError);
      await expectLater(
        repo.complete('account', o, s, isCurrent: () => false),
        throwsStateError,
      );
      await db
          .update(db.workoutPlans)
          .write(WorkoutPlansCompanion(deletedAtUtc: Value(DateTime.now())));
      await expectLater(
        repo.addRule(
          'account',
          planSyncId: plan,
          name: 'Gone',
          weekday: 2,
          effectiveFrom: day,
        ),
        throwsStateError,
      );
      expect((await occurrence()).sessionSyncId, isNull);
    },
  );
  test(
    'A-B-A invalidates captured authority while SQLite write is queued',
    () async {
      final authority = TestAuthority();
      final guarded = ScheduleRepository(db, authority: authority);
      final o = await occurrence();
      final s = await session(ended: true, sets: true);
      final entered = Completer<void>(), release = Completer<void>();
      final blocker = db.transaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final write = guarded.complete('account', o, s);
      final rejected = expectLater(write, throwsStateError);
      authority.generation += 2;
      release.complete();
      await blocker;
      await rejected;
      expect((await occurrence()).sessionSyncId, isNull);
    },
  );
  test(
    'independent remote completions using one session are displayed as conflict, never two completions',
    () async {
      final o = await occurrence();
      final s = await session(ended: true, sets: true);
      await repo.complete('account', o, s);
      await UserCollectionsRepository(db).update('account', 'weeklySchedule', (
        entries,
      ) {
        final completed = entries.singleWhere((e) => e['kind'] == 'override');
        entries.add({
          ...completed,
          'id': WeeklySchedule.occurrenceId(o.ruleId, day.plus(7)),
          'originalDate': day.plus(7).value,
          'movedDate': day.plus(7).value,
        });
      });
      final all = (await repo.load('account')).between(day, day.plus(7));
      expect(all, hasLength(2));
      for (final item in all) {
        expect(
          await repo.completionStatus('account', item),
          ScheduleCompletion.conflict,
        );
      }
    },
  );
}
