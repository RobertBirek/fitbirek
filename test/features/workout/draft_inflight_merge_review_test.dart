import 'dart:convert';
import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/workout_draft_write.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'guided_extras_review_test.dart' show planned, future, extra, reviewPlan;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;
import 'interval_save_test.dart' show PausedRoundRepository;

final b = extra.copyWith(id: 'extra-b', nazwaPl: 'Dodatkowe B');
final c = extra.copyWith(id: 'extra-c', nazwaPl: 'Dodatkowe C');
Map<String, Object?> nextTimer() {
  final cp = completedLeftTimer();
  cp['config'] = {...(cp['config'] as Map), 'work': 11};
  cp['results'] = [
    {'round': 1, 'seconds': 11, 'shortened': false},
  ];
  return cp;
}

class MergeExercises extends ExercisesRepository {
  MergeExercises(super.db);
  @override
  Stream<List<Exercise>> watchAll() =>
      Stream.value([planned, future, extra, b, c]);
}

class MergeBarrierRepository extends PausedRoundRepository {
  MergeBarrierRepository(super.db);
  final queuedRead = Completer<void>();
  @override
  Future<Map<String, Object?>?> readDraft(
    String accountId,
    String sessionSyncId,
  ) {
    if (entered.isCompleted &&
        !release.isCompleted &&
        !queuedRead.isCompleted) {
      queuedRead.complete();
    }
    return super.readDraft(accountId, sessionSyncId);
  }
}

void main() {
  test(
    'targeted consume merge preserves every unrelated namespace and a newer target nonce',
    () {
      for (var seed = 0; seed < 100; seed++) {
        final old = {
          'timer': {
            'nonce': 'a-$seed',
            'results': [seed],
          },
          'timerBinding': {'nonce': 'old-$seed'},
        };
        final current = <String, Object?>{
          'timer': {'main': seed},
          'note': 'note-$seed',
          'future': {
            'nested': [seed, seed + 1],
          },
          'extraForms': {
            'a': {...old, 'reps': '$seed'},
            'b': {
              'reps': '${seed + 9}',
              'timer': {'nonce': 'b-$seed'},
            },
          },
          'extraSelections': {
            'a': {'side': 'right'},
            'b': {'variantId': 'variant-$seed'},
          },
        };
        final before = jsonDecode(jsonEncode(current));
        final expected = Map<String, Object?>.from(
          jsonDecode(jsonEncode(current)) as Map,
        );
        (expected['extraForms'] as Map)['a'].addAll({
          'timer': null,
          'timerBinding': null,
        });
        final merged = mergeConsumedCheckpointFields(
          current,
          key: 'a',
          extra: true,
          expectedForm: old,
        );
        expect(merged, expected);
        expect(current, before);
        expect(
          mergeConsumedCheckpointFields(
            merged,
            key: 'a',
            extra: true,
            expectedForm: old,
          ),
          merged,
        );
        final newer = Map<String, Object?>.from(
          jsonDecode(jsonEncode(current)) as Map,
        );
        (newer['extraForms'] as Map)['a']['timerBinding'] = {
          'nonce': 'new-$seed',
        };
        expect(
          mergeConsumedCheckpointFields(
            newer,
            key: 'a',
            extra: true,
            expectedForm: old,
          ),
          newer,
        );
        final main = <String, Object?>{...current, ...old};
        final mainResult = mergeConsumedCheckpointFields(
          main,
          key: 'main',
          extra: false,
          expectedForm: old,
        );
        expect(mainResult, {...main, 'timer': null, 'timerBinding': null});
      }
    },
  );
  for (final cancel in [false, true]) {
    test(
      'B edits during A SQL transaction survive ${cancel ? 'rollback' : 'consumption'}, flush and restart',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final repo = MergeBarrierRepository(db);
        ProviderContainer container({bool paused = false}) => ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            if (paused) workoutRepositoryProvider.overrideWithValue(repo),
            exercisesRepositoryProvider.overrideWithValue(MergeExercises(db)),
          ],
        );
        final view = container(paused: true), reload = container();
        addTearDown(() async {
          view.dispose();
          reload.dispose();
          await db.close();
        });
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        final n = view.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
        n.addExercise(extra);
        n.addExercise(b);
        n.updateDraft({'side': 'left', 'timer': completedLeftTimer()});
        n.updateExerciseDraft(
          extra.id,
          {'timer': completedLeftTimer()},
          extra: true,
          side: 'left',
        );
        n.updateExerciseDraft(b.id, {'reps': '3'}, extra: true, side: 'right');
        await n.flushDraft();
        final uuid = view.read(activeWorkoutProvider).sessionSyncId!;
        final main = view.read(activeWorkoutProvider).draft['timer'];
        final aOrigin = n.captureInterval(
          exercise: extra,
          extra: true,
          side: 'left',
        )!;
        var allowed = true;
        final write = n.saveIntervalRounds(aOrigin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ], guard: () => allowed);
        await repo
            .entered
            .future; // logSet wrote inside the still-open batch transaction
        expect(
          n.captureInterval(exercise: extra, extra: true, side: 'left'),
          isNull,
        );
        expect(
          n.updateIntervalCheckpoint(aOrigin, nextTimer()),
          isFalse,
        ); // old nonce
        expect(
          () => n.updateExerciseDraft(
            extra.id,
            {'timer': nextTimer()},
            extra: true,
            side: 'left',
          ),
          throwsStateError,
        );
        final bOrigin = n.captureInterval(
          exercise: b,
          extra: true,
          side: 'right',
        )!;
        n.updateExerciseDraft(b.id, {'reps': '9'}, extra: true, side: 'right');
        expect(n.updateIntervalCheckpoint(bOrigin, nextTimer()), isTrue);
        n.updateDraft({
          'note': 'during await',
          'futureField': {'nested': 42},
        });
        n.addExercise(c);
        n.updateExerciseDraft(c.id, {'reps': '5'}, extra: true, side: 'left');
        n.updateExerciseDraft(
          extra.id,
          {'reps': '4'},
          extra: true,
          side: 'right',
        );
        expect(
          view
              .read(activeWorkoutProvider)
              .exerciseDraft(b.id, extra: true, side: 'right')['reps'],
          '9',
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          repo.queuedRead.isCompleted,
          isTrue,
        ); // B really entered the durable queue before A finished
        allowed = !cancel;
        repo.release.complete();
        expect(await write, !cancel);
        await n.flushDraft();
        void retained(ActiveWorkoutState state) {
          expect(
            state.exerciseDraft(b.id, extra: true, side: 'right')['reps'],
            '9',
          );
          expect(
            state.exerciseDraft(b.id, extra: true, side: 'right')['timer'],
            nextTimer(),
          );
          expect(
            state.exerciseDraft(c.id, extra: true, side: 'left')['reps'],
            '5',
          );
          expect(state.extraSelection(extra.id)['side'], 'right');
          expect(
            state.exerciseDraft(extra.id, extra: true, side: 'right')['reps'],
            '4',
          );
          expect(
            state.exerciseDraft(extra.id, extra: true, side: 'left')['timer'],
            cancel ? completedLeftTimer() : null,
          );
          expect(state.draft['timer'], main);
          expect(state.draft['note'], 'during await');
          expect(state.draft['futureField'], {'nested': 42});
          expect(state.selectedExercises.map((e) => e.id), contains(c.id));
        }

        retained(view.read(activeWorkoutProvider));
        final resumed = reload.read(activeWorkoutProvider.notifier);
        expect(await resumed.resumeSession(uuid), isTrue);
        retained(reload.read(activeWorkoutProvider));
        expect(await db.workoutDao.getAllSets(), hasLength(cancel ? 0 : 1));
        expect(
          await n.saveIntervalRounds(aOrigin, [
            const IntervalRound(round: 1, seconds: 10, shortened: false),
          ]),
          isFalse,
        );
      },
    );
  }
}
