import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'guided_extras_review_test.dart'
    show ReviewExercises, reviewPlan, extra, planned;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;

class DelayedDraftRepository extends WorkoutRepository {
  DelayedDraftRepository(this.db) : super(db);
  final AppDatabase db;
  Map? lateCommitted;
  bool delayNext = false;
  int rejected = 0;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<Map<String, Object?>> saveDraft({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required Map<String, Object?> payload,
    required bool Function() guard,
  }) async {
    final delayed = delayNext;
    if (delayed) {
      delayNext = false;
      entered.complete();
      await release.future; // deliberately OUTSIDE SQLite transaction
    }
    try {
      final result = await super.saveDraft(
        sessionId: sessionId,
        sessionSyncId: sessionSyncId,
        accountId: accountId,
        payload: payload,
        guard: guard,
      );
      if (delayed) {
        lateCommitted =
            jsonDecode(
                  (await db.select(db.workoutDrafts).getSingle()).payloadJson,
                )
                as Map;
      }
      return result;
    } catch (_) {
      rejected++;
      rethrow;
    }
  }
}

void main() {
  test(
    'repository rejects retired checkpoint token even with a refreshed whole-row revision',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = WorkoutRepository(db);
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.updateExerciseDraft(
        extra.id,
        {'timer': completedLeftTimer()},
        extra: true,
        side: 'left',
      );
      await n.flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!,
          id = c.read(activeWorkoutProvider).sessionId!;
      final old = (await repo.readDraft('a', uuid))!;
      final origin = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isTrue,
      );
      await n.flushDraft();
      final latest = (await repo.readDraft('a', uuid))!;
      await expectLater(
        repo.saveDraft(
          sessionId: id,
          sessionSyncId: uuid,
          accountId: 'a',
          payload: {...old, 'draftRevision': latest['draftRevision']},
          guard: () => true,
        ),
        throwsStateError,
      );
      final saved = (await repo.readDraft('a', uuid))!,
          key = c
              .read(activeWorkoutProvider)
              .extraDraftKey(extra.id, 'left', null);
      expect((saved['fields'] as Map)['extraForms'][key]['timer'], isNull);
      expect(await db.workoutDao.getAllSets(), hasLength(1));
    },
  );
  test(
    'stale restored view cannot consume a checkpoint replaced by newer unsaved work',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ProviderContainer container() => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exercisesRepositoryProvider.overrideWithValue(ReviewExercises(db)),
        ],
      );
      final c = container(), second = container();
      addTearDown(() async {
        c.dispose();
        second.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.updateExerciseDraft(
        extra.id,
        {'timer': completedLeftTimer()},
        extra: true,
        side: 'left',
      );
      await n.flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!,
          other = second.read(activeWorkoutProvider.notifier);
      expect(await other.resumeSession(uuid), isTrue);
      final old = other.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      final newer = completedLeftTimer();
      newer['config'] = {...(newer['config'] as Map), 'work': 11};
      newer['results'] = [
        {'round': 1, 'seconds': 11, 'shortened': false},
      ];
      n.updateExerciseDraft(
        extra.id,
        {'timer': newer},
        extra: true,
        side: 'left',
      );
      await n.flushDraft();
      expect(
        await other.saveIntervalRounds(old, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isFalse,
      );
      final saved = (await WorkoutRepository(db).readDraft('a', uuid))!,
          key = c
              .read(activeWorkoutProvider)
              .extraDraftKey(extra.id, 'left', null);
      expect(
        (saved['fields']
            as Map)['extraForms'][key]['timer']['results'][0]['seconds'],
        11,
      );
      expect(await db.workoutDao.getAllSets(), isEmpty);
    },
  );
  test(
    'own guided progress can rebase pending non-timer edits without losing an extra checkpoint',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DelayedDraftRepository(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.updateDraft({'side': 'left', 'rpe': 7, 'timer': completedLeftTimer()});
      n.updateExerciseDraft(
        extra.id,
        {'timer': completedLeftTimer()},
        extra: true,
        side: 'left',
      );
      await n.flushDraft();
      final extraOrigin = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      repo.delayNext = true;
      n.updateDraft({'rpe': 9});
      await repo.entered.future;
      final origin = n.captureInterval(exercise: planned, side: 'left')!;
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isTrue,
      );
      repo.release.complete();
      await n.flushDraft();
      final row = (await repo.readDraft(
        'a',
        c.read(activeWorkoutProvider).sessionSyncId!,
      ))!;
      final fields = row['fields'] as Map,
          key = c
              .read(activeWorkoutProvider)
              .extraDraftKey(extra.id, 'left', null);
      expect(fields['rpe'], 9);
      expect(fields['timer'], isNull);
      expect(fields['extraForms'][key]['timer'], isNotNull);
      expect(n.isIntervalCurrent(extraOrigin), isTrue);
      expect(repo.lateCommitted, isNull);
    },
  );
  test(
    'late full draft cannot resurrect consumed extra timer; targeted consume preserves latest other fields',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DelayedDraftRepository(db);
      final containers = <ProviderContainer>[];
      ProviderContainer container({bool delayed = false}) {
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            if (delayed) workoutRepositoryProvider.overrideWithValue(repo),
            exercisesRepositoryProvider.overrideWithValue(ReviewExercises(db)),
          ],
        );
        containers.add(c);
        return c;
      }

      addTearDown(() async {
        for (final c in containers) {
          c.dispose();
        }
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final c = container(delayed: true),
          n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.updateDraft({'side': 'left', 'rpe': 7, 'timer': completedLeftTimer()});
      n.updateExerciseDraft(
        extra.id,
        {'timer': completedLeftTimer(), 'reps': '3'},
        extra: true,
        side: 'left',
      );
      await n.flushDraft();
      final mainOrigin = n.captureInterval(exercise: planned, side: 'left')!;
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      final second = container(),
          other = second.read(activeWorkoutProvider.notifier);
      expect(await other.resumeSession(uuid), isTrue);
      final staleOrigin = other.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      // This writer has captured a full snapshot with the old complete timer.
      repo.delayNext = true;
      n.updateExerciseDraft(extra.id, {'reps': '9'}, extra: true, side: 'left');
      await repo.entered.future;
      other.updateDraft({'rpe': 9});
      await other.flushDraft();
      final origin = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isTrue,
      );
      repo.release.complete();
      await n.flushDraft();
      final saved =
          jsonDecode(
                (await db.select(db.workoutDrafts).getSingle()).payloadJson,
              )
              as Map;
      final key = c
          .read(activeWorkoutProvider)
          .extraDraftKey(extra.id, 'left', null);
      expect(saved['fields']['extraForms'][key]['timer'], isNull);
      expect(repo.lateCommitted, isNull); // the old full write itself must fail
      expect(saved['fields']['extraForms'][key]['reps'], '9');
      expect(saved['fields']['rpe'], 9);
      expect(saved['fields']['timer'], isNotNull);
      expect(
        repo.rejected,
        greaterThan(0),
      ); // stale SQLite CAS, not only UI guard
      expect(n.isIntervalCurrent(mainOrigin), isTrue);
      expect(other.isIntervalCurrent(staleOrigin), isTrue);
      expect(
        await other.saveIntervalRounds(staleOrigin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isFalse,
      );
      expect(await db.workoutDao.getAllSets(), hasLength(1));
      final reload = container(),
          resumed = reload.read(activeWorkoutProvider.notifier);
      expect(await resumed.resumeSession(uuid), isTrue);
      expect(
        reload
            .read(activeWorkoutProvider)
            .exerciseDraft(extra.id, extra: true, side: 'left')['timer'],
        isNull,
      );
      expect(await db.workoutDao.getAllSets(), hasLength(1));
    },
  );
  test(
    'queued first checkpoint after consumption is rejected, not rebased from a null timer',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DelayedDraftRepository(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      await n.flushDraft();
      repo.delayNext = true;
      n.updateExerciseDraft(
        extra.id,
        {'timer': completedLeftTimer()},
        extra: true,
        side: 'left',
      );
      await repo.entered.future;
      final origin = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isTrue,
      );
      repo.release.complete();
      await n.flushDraft();
      expect(
        n.draftSaveError,
        isNull,
      ); // discard only this owner's retired ticker data
      final saved = (await repo.readDraft(
        'a',
        c.read(activeWorkoutProvider).sessionSyncId!,
      ))!;
      final key = c
          .read(activeWorkoutProvider)
          .extraDraftKey(extra.id, 'left', null);
      expect((saved['fields'] as Map)['extraForms'][key]['timer'], isNull);
      expect(repo.lateCommitted, isNull);
      expect(await db.workoutDao.getAllSets(), hasLength(1));
    },
  );
  test(
    'concurrent edits of the same form field report conflict and preserve newer data',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ProviderContainer container() => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exercisesRepositoryProvider.overrideWithValue(ReviewExercises(db)),
        ],
      );
      final c = container(), second = container();
      addTearDown(() async {
        c.dispose();
        second.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      await n.flushDraft();
      final other = second.read(activeWorkoutProvider.notifier),
          uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      expect(await other.resumeSession(uuid), isTrue);
      n.updateExerciseDraft(extra.id, {'reps': '9'}, extra: true, side: 'left');
      await n.flushDraft();
      other.updateExerciseDraft(
        extra.id,
        {'reps': '7'},
        extra: true,
        side: 'left',
      );
      await expectLater(other.flushDraft(), throwsStateError);
      expect(other.draftSaveError, isNotNull);
      final saved = (await WorkoutRepository(db).readDraft('a', uuid))!;
      final key = c
          .read(activeWorkoutProvider)
          .extraDraftKey(extra.id, 'left', null);
      expect((saved['fields'] as Map)['extraForms'][key]['reps'], '9');
    },
  );
  test(
    'two mounted views cannot log one restored extra checkpoint twice',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ProviderContainer container() => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exercisesRepositoryProvider.overrideWithValue(ReviewExercises(db)),
        ],
      );
      final c = container(), second = container();
      addTearDown(() async {
        c.dispose();
        second.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.updateExerciseDraft(
        extra.id,
        {'timer': completedLeftTimer()},
        extra: true,
        side: 'left',
      );
      await n.flushDraft();
      final other = second.read(activeWorkoutProvider.notifier);
      expect(
        await other.resumeSession(c.read(activeWorkoutProvider).sessionSyncId!),
        isTrue,
      );
      final a = n.captureInterval(exercise: extra, side: 'left', extra: true)!,
          b = other.captureInterval(
            exercise: extra,
            side: 'left',
            extra: true,
          )!;
      const rounds = [IntervalRound(round: 1, seconds: 10, shortened: false)];
      expect(await n.saveIntervalRounds(a, rounds), isTrue);
      final later = completedLeftTimer();
      later['config'] = {...(later['config'] as Map), 'work': 11};
      later['results'] = [
        {'round': 1, 'seconds': 11, 'shortened': false},
      ];
      other.updateExerciseDraft(
        extra.id,
        {'timer': later},
        extra: true,
        side: 'left',
      );
      await expectLater(other.flushDraft(), throwsStateError);
      final saved = (await WorkoutRepository(
        db,
      ).readDraft('a', c.read(activeWorkoutProvider).sessionSyncId!))!;
      final key = c
          .read(activeWorkoutProvider)
          .extraDraftKey(extra.id, 'left', null);
      expect((saved['fields'] as Map)['extraForms'][key]['timer'], isNull);
      expect(await other.saveIntervalRounds(b, rounds), isFalse);
      expect(await db.workoutDao.getAllSets(), hasLength(1));
    },
  );
}
