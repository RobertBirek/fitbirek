import 'dart:convert';
import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/providers/schedule_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/fixed_load_progression.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/workout_preparation.dart';
import 'package:fitbirek_training/features/workout/preparation/providers/preparation_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../../exercises/catalog_filter_test.dart' show exercise;
import '../../planner/manual_templates_test.dart' show MutableAuthority;
import '../../planner/planner_workflow_test.dart' show PausedStart;

class PausedPreparationHistory extends WorkoutRepository {
  PausedPreparationHistory(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<List<ProgressionPerformance>> getPreparationHistory(
    String exerciseId, {
    required String? side,
    String? variantId,
  }) async {
    entered.complete();
    await release.future;
    return super.getPreparationHistory(
      exerciseId,
      side: side,
      variantId: variantId,
    );
  }
}

class PreparationFixture {
  PreparationFixture(this.db, this.container, this.authority, this.planId);
  final AppDatabase db;
  final ProviderContainer container;
  final MutableAuthority authority;
  final String planId;
  WorkoutPreparationWorkflow get workflow =>
      container.read(workoutPreparationWorkflowProvider);
  static final plan = StructuredPlan(
    criteria: const ExerciseFilters(),
    budgetSeconds: 600,
    equipment: const ['Hantle'],
    blocks: [
      for (final id in ['a', 'b'])
        PlanBlock(
          exerciseId: id,
          section: PlanSection.main,
          prescription: const PlanPrescription(
            tracking: 'reps',
            sets: 3,
            reps: 10,
            workSeconds: 30,
            restSeconds: 30,
            transitionSeconds: 15,
          ),
        ),
    ],
    warnings: const [],
  );

  static Future<PreparationFixture> create({
    bool legacy = false,
    List<Exercise> Function()? catalogReader,
    WorkoutRepository Function(AppDatabase)? repositoryFactory,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            accountId: 'A',
            deviceId: 'device',
            offlineAccess: const Value(true),
          ),
        );
    await db
        .into(db.userProfiles)
        .insert(
          UserProfilesCompanion.insert(
            wiek: 40,
            wzrostCm: 180,
            wagaKg: 80,
            cel: 'sila',
            dostepnySprzet: '["Hantle"]',
            syncId: const Value('11111111-1111-4111-8111-111111111111'),
          ),
        );
    final catalog = [
      for (final id in ['a', 'b', 'c', 'd'])
        exercise(id, name: 'Ruch $id').copyWith(
          seriexPowtorzenia: '3×8–12',
          wzorzecRuchu: 'Pull horyzontalny',
        ),
    ];
    final metadata = ExerciseCatalogMetadata(
      exercises: {
        for (final e in catalog)
          e.id: const ExerciseCatalogEntry(
            tracking: 'reps',
            unilateral: true,
            primaryMuscles: ['back'],
          ),
      },
    );
    final authority = MutableAuthority();
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        if (repositoryFactory != null)
          workoutRepositoryProvider.overrideWithValue(repositoryFactory(db)),
        allExercisesProvider.overrideWith(
          (ref) => Stream.value(catalogReader?.call() ?? catalog),
        ),
        exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
      ],
    );
    await c
        .read(plannerRepositoryProvider)
        .savePlan(
          nazwa: 'Trening',
          cwiczeniaIds: plan.exerciseIds,
          cel: 'sila',
          structure: legacy ? null : plan,
        );
    return PreparationFixture(
      db,
      c,
      authority,
      (await c.read(plannerRepositoryProvider).readAll()).single.syncId!,
    );
  }

  Future<void> close() async {
    final active =
        container.exists(activeWorkoutProvider) &&
        container.read(activeWorkoutProvider).isActive;
    if (active) {
      await container.read(activeWorkoutProvider.notifier).flushDraft();
    }
    container.dispose();
    await db.close();
  }
}

void main() {
  test(
    'parallel exercise history reads do not compete for the planner write lock',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final snapshot = await f.workflow.open(planSyncId: f.planId);
      final results = await Future.wait([
        for (final id in ['a', 'b'])
          f.workflow.readHistory(snapshot, id, side: 'both', variantId: null),
      ]);
      expect(results, [isEmpty, isEmpty]);
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    },
  );
  for (final change in ['remove', 'equipment', 'replacement']) {
    test('catalog change $change invalidates prepared start', () async {
      var current = [
        for (final id in ['a', 'b', 'c', 'd'])
          exercise(id, name: 'Ruch $id').copyWith(
            seriexPowtorzenia: '3×8–12',
            wzorzecRuchu: 'Pull horyzontalny',
          ),
      ];
      final f = await PreparationFixture.create(catalogReader: () => current);
      addTearDown(f.close);
      var draft = PreparationDraft(await f.workflow.open(planSyncId: f.planId));
      if (change == 'replacement') {
        draft = draft.replace(0, 'c', ReplacementScope.sessionOnly);
        current = current.where((e) => e.id != 'c').toList();
      } else if (change == 'remove') {
        current = current.where((e) => e.id != 'a').toList();
      } else {
        current = [
          for (final e in current)
            if (e.id == 'a') e.copyWith(sprzet: ['Wyciąg']) else e,
        ];
      }
      f.container.invalidate(allExercisesProvider);
      await f.container.read(allExercisesProvider.future);
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsStateError,
      );
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    });
  }
  test(
    'prepared goals survive actual durable draft resume without new results',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft =
          PreparationDraft(await f.workflow.open(planSyncId: f.planId))
              .setTarget(
                0,
                const PreparedTarget(weightKg: 7.25, reps: 8, side: 'both'),
              )
              .setTarget(
                1,
                const PreparedTarget(weightKg: 8.25, reps: 9, side: 'both'),
              );
      await f.workflow.start(draft, isCurrent: () => true);
      final session = f.container.read(activeWorkoutProvider).sessionSyncId!;
      final notifier = f.container.read(activeWorkoutProvider.notifier);
      notifier.discardSession();
      await notifier.resumeSession(session);
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '7.25');
      expect(f.container.read(activeWorkoutProvider).draft['reps'], '8');
      expect(notifier.moveGuided(1), isTrue);
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '8.25');
      expect(f.container.read(activeWorkoutProvider).draft['reps'], '9');
      expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
      expect(await f.db.select(f.db.setsLog).get(), isEmpty);
      expect(await f.db.select(f.db.personalRecords).get(), isEmpty);
    },
  );
  test(
    'opening and discarding preparation leaves plan, session and outbox untouched',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final plans = await f.db.select(f.db.workoutPlans).get();
      final operations = await f.db.select(f.db.syncOutbox).get();
      final snapshot = await f.workflow.open(planSyncId: f.planId);
      PreparationDraft(
        snapshot,
      ).setTarget(0, const PreparedTarget(weightKg: 7.25, side: 'both'));
      expect(await f.db.select(f.db.workoutPlans).get(), plans);
      expect(await f.db.select(f.db.syncOutbox).get(), operations);
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
      expect(await f.db.select(f.db.workoutDrafts).get(), isEmpty);
      expect(f.container.read(activeWorkoutProvider).isActive, isFalse);
    },
  );

  test(
    'mixed scopes save only explicit template replacement and start one prepared session',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft =
          PreparationDraft(await f.workflow.open(planSyncId: f.planId))
              .replace(0, 'c', ReplacementScope.sessionOnly)
              .replace(1, 'd', ReplacementScope.templateAndSession)
              .setTarget(
                0,
                const PreparedTarget(weightKg: 7.25, reps: 10, side: 'both'),
              );
      expect(draft.sessionPlan!.exerciseIds, ['c', 'd']);
      expect(draft.templatePlan!.exerciseIds, ['a', 'd']);
      await f.workflow.start(draft, isCurrent: () => true);
      final saved =
          (await f.container.read(plannerRepositoryProvider).readAll()).single;
      expect(saved.cwiczeniaIds, ['a', 'd']);
      expect(saved.structure!.blocks.first.prescription.weightKg, isNull);
      final session = (await f.db.select(f.db.workoutSessions).get()).single;
      expect(WorkoutGuidance.tryRead(session.guidanceJson)!.plan.exerciseIds, [
        'c',
        'd',
      ]);
      final state = f.container.read(activeWorkoutProvider);
      expect(state.draft['weight'], '7.25');
      expect(state.draft['side'], 'both');
      expect(await f.db.select(f.db.workoutDrafts).get(), hasLength(1));
      expect(await f.db.select(f.db.setsLog).get(), isEmpty);
      expect(await f.db.select(f.db.personalRecords).get(), isEmpty);
      expect(
        (await f.db.select(f.db.syncOutbox).get()).where(
          (r) => r.entityType == 'workoutSession',
        ),
        hasLength(1),
      );
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsStateError,
      );
      expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
    },
  );

  test('session-only replacement never changes the saved template', () async {
    final f = await PreparationFixture.create();
    addTearDown(f.close);
    final original = (await f.db.select(f.db.workoutPlans).get()).single;
    final draft = PreparationDraft(
      await f.workflow.open(planSyncId: f.planId),
    ).replace(0, 'c', ReplacementScope.sessionOnly);
    expect(draft.templatePlan, isNull);
    await f.workflow.start(draft, isCurrent: () => true);
    expect((await f.db.select(f.db.workoutPlans).get()).single, original);
  });

  test(
    'mixed scope cannot duplicate A in a template after session-only A to C',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      ).replace(0, 'c', ReplacementScope.sessionOnly);
      expect(
        () => draft.replace(1, 'a', ReplacementScope.templateAndSession),
        throwsStateError,
      );
    },
  );

  test(
    'A to B to A invalidates the opening lease without creating a session',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      );
      f.authority.generation += 2;
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsStateError,
      );
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
      await expectLater(
        f.workflow.readHistory(
          draft.snapshot,
          'a',
          side: 'both',
          variantId: null,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'remote template change while modal is open rejects stale prepared start',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      );
      final repo = f.container.read(plannerRepositoryProvider);
      await repo.updateTemplate(
        (await repo.snapshot(f.planId))!,
        name: 'Zmieniony',
        plan: PreparationFixture.plan,
      );
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsStateError,
      );
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    },
  );

  test(
    'rollback after RAM start leaves neither orphaned RAM nor database session',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      );
      var current = true;
      final subscription = f.container.listen(activeWorkoutProvider, (_, next) {
        if (next.isActive) current = false;
      });
      addTearDown(subscription.close);
      final before = await f.db.select(f.db.syncOutbox).get();
      await expectLater(
        f.workflow.start(draft, isCurrent: () => current),
        throwsStateError,
      );
      expect(f.container.read(activeWorkoutProvider).isActive, isFalse);
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
      expect(await f.db.select(f.db.syncOutbox).get(), before);
    },
  );

  test(
    'prepared both/base load is not copied into a new left or variant form',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft =
          PreparationDraft(await f.workflow.open(planSyncId: f.planId))
              .setTarget(0, const PreparedTarget(weightKg: 7.25, side: 'both'))
              .setTarget(1, const PreparedTarget(weightKg: 8.25, side: 'both'));
      await f.workflow.start(draft, isCurrent: () => true);
      final notifier = f.container.read(activeWorkoutProvider.notifier);
      expect(notifier.moveGuided(1), isTrue);
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '8.25');
      expect(notifier.moveGuided(0), isTrue);
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '7.25');
      expect(
        notifier.selectGuidedIdentity('a', side: 'left', variantId: null),
        isTrue,
      );
      expect(
        f.container.read(activeWorkoutProvider).draft['weight'],
        isNot('7.25'),
      );
      expect(
        notifier.selectGuidedIdentity('a', side: 'both', variantId: null),
        isTrue,
      );
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '7.25');
    },
  );

  test(
    'legacy list-only plan keeps an unguided start, never fabricated goals',
    () async {
      final f = await PreparationFixture.create(legacy: true);
      addTearDown(f.close);
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      );
      expect(draft.sessionPlan, isNull);
      expect(
        () => draft.replace(0, 'c', ReplacementScope.sessionOnly),
        throwsStateError,
      );
      await f.workflow.start(draft, isCurrent: () => true);
      expect(
        (await f.db.select(f.db.workoutSessions).get()).single.guidanceJson,
        isNull,
      );
      expect(
        f.container
            .read(activeWorkoutProvider)
            .selectedExercises
            .map((e) => e.id),
        ['a', 'b'],
      );
    },
  );

  test(
    'changed scheduled occurrence rejects prepared start without automatic completion',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final repo = f.container.read(scheduleRepositoryProvider);
      final day = CalendarDay.parse('2026-10-21');
      await repo.addRule(
        'A',
        planSyncId: f.planId,
        name: 'Trening',
        weekday: day.weekday,
        effectiveFrom: day,
      );
      final chosen = (await repo.load('A')).between(day, day).single;
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId, occurrence: chosen),
      );
      await repo.move('A', chosen, day.plus(1));
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsStateError,
      );
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
      expect(
        jsonDecode(
          (await f.db.select(f.db.userProfiles).get())
              .single
              .weeklyScheduleJson!,
        )['entries'],
        hasLength(2),
      );
    },
  );

  test(
    'captured snapshot exercise list cannot be changed through its saved model',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final snapshot = await f.workflow.open(planSyncId: f.planId);
      expect(
        () => snapshot.savedPlan!.cwiczeniaIds[0] = 'd',
        throwsUnsupportedError,
      );
      expect(snapshot.exerciseIds, ['a', 'b']);
    },
  );

  test(
    'changing replacement scope retains the chosen exercise and manual target',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft =
          PreparationDraft(await f.workflow.open(planSyncId: f.planId))
              .replace(0, 'c', ReplacementScope.sessionOnly)
              .setTarget(0, const PreparedTarget(weightKg: 7.25, side: 'both'));
      final changed = draft.replace(
        0,
        'c',
        ReplacementScope.templateAndSession,
      );
      expect(changed.templatePlan!.exerciseIds, ['c', 'b']);
      expect(changed.targets[0]?.weightKg, 7.25);
    },
  );

  test(
    'a replacement preserves dose but never the previous exercise load',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final original = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      ).setTarget(0, const PreparedTarget(weightKg: 7.25, side: 'both'));
      final changed = original.replace(0, 'c', ReplacementScope.sessionOnly);
      expect(changed.targets.containsKey(0), isFalse);
      final dose = changed.sessionPlan!.blocks[0].prescription;
      expect(dose.sets, 3);
      expect(dose.reps, 10);
      expect(dose.restSeconds, 30);
      expect(dose.weightKg, isNull);
    },
  );

  test(
    'account changes during an awaited history read discard its result',
    () async {
      late PausedPreparationHistory paused;
      final f = await PreparationFixture.create(
        repositoryFactory: (db) => paused = PausedPreparationHistory(db),
      );
      addTearDown(f.close);
      final snapshot = await f.workflow.open(planSyncId: f.planId);
      final request = f.workflow.readHistory(
        snapshot,
        'a',
        side: 'both',
        variantId: null,
      );
      final rejected = expectLater(request, throwsStateError);
      await paused.entered.future;
      f.authority.generation += 2;
      paused.release.complete();
      await rejected;
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    },
  );

  test(
    'two taps during an awaiting start create exactly one session',
    () async {
      late PausedStart paused;
      final f = await PreparationFixture.create(
        repositoryFactory: (db) => paused = PausedStart(db),
      );
      addTearDown(f.close);
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: f.planId),
      );
      final first = f.workflow.start(draft, isCurrent: () => true);
      await paused.entered.future;
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsStateError,
      );
      paused.release.complete();
      await first;
      expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
    },
  );

  test(
    'free start does not invent a structured plan or silently select a saved template',
    () async {
      final f = await PreparationFixture.create();
      addTearDown(f.close);
      final draft = PreparationDraft(await f.workflow.open());
      expect(draft.snapshot.exerciseIds, isEmpty);
      expect(draft.sessionPlan, isNull);
      await f.workflow.start(draft, isCurrent: () => true);
      expect(
        (await f.db.select(f.db.workoutSessions).get()).single.guidanceJson,
        isNull,
      );
      expect(
        f.container.read(activeWorkoutProvider).selectedExercises,
        isEmpty,
      );
    },
  );
}
