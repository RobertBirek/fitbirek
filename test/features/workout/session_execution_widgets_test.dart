import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/workout/domain/workout_progress.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/template_editor_page.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'session_tracking_test.dart' show exercise;
import 'catalog_session_continuity_test.dart' show settleDatabase;
import 'session_recovery_provider_test.dart' show RecoveryAuthority;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;

void main() {
  setUpAll(() => initializeDateFormatting('pl'));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  final extra = exercise.copyWith(id: 'extra', nazwaPl: 'Dodatkowy ruch');
  late AppDatabase db;
  late ProviderContainer c;
  late RecoveryAuthority authority;
  var extraTracking = 'reps';
  ProviderContainer container() => ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
      allExercisesProvider.overrideWith(
        (ref) => Stream.value([
          exercise.copyWith(sprzet: ['Hantle']),
          extra,
        ]),
      ),
      exerciseCatalogMetadataProvider.overrideWith(
        (ref) async => ExerciseCatalogMetadata(
          exercises: {
            exercise.id: const ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
            ),
            extra.id: ExerciseCatalogEntry(
              tracking: extraTracking,
              unilateral: extraTracking == 'rounds',
            ),
          },
        ),
      ),
    ],
  );
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    extraTracking = 'reps';
    authority = RecoveryAuthority();
    c = container();
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    for (final e in [exercise, extra]) {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: e.id,
              nazwaPl: e.nazwaPl,
              nazwaEn: '',
              partiaGlowna: '',
              partieWspierajace: '[]',
              typ: e.typ,
              sprzet: jsonEncode(e.sprzet),
              poziom: e.poziom,
              wzorzecRuchu: '',
              seriexPowtorzenia: '',
              tempo: '',
              kluczoweWskazowki: '[]',
              czesteBledy: '[]',
              progresja: '',
              regresja: '',
              zrodlo: '',
            ),
          );
    }
  });
  tearDown(() async {
    c.dispose();
    await db.close();
    authority.revision.dispose();
  });
  Future<GoRouter> mount(
    WidgetTester tester, {
    String location = '/workout/session',
  }) async {
    final router = createRouter(
      readAuthState: () => const AuthState.signedIn('a'),
      readOnboardingComplete: () => true,
      initialLocation: location,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settleDatabase(tester);
    return router;
  }

  testWidgets(
    'repeat -> catalog add -> durable extra form -> restart -> extra and target saves do not mix progress',
    (tester) async {
      final repo = WorkoutRepository(db);
      await tester.runAsync(() async {
        final source = await repo.startSession(accountId: 'a');
        await repo.logSet(
          sessionId: source,
          exerciseId: exercise.id,
          exerciseNamePl: exercise.nazwaPl,
          setNumber: 1,
          reps: 8,
          accountId: 'a',
        );
        await repo.finishSession(source, DateTime.now(), accountId: 'a');
        final n = c.read(activeWorkoutProvider.notifier);
        expect(
          await n.confirmRepeat(
            await n.previewRepeat(source, RepeatMode.execution),
          ),
          isTrue,
        );
        await n.flushDraft();
      });
      final router = await mount(tester);
      await tester.tap(find.text('Dodaj ćwiczenie z bazy'));
      await settleDatabase(tester);
      await tester.tap(find.text(extra.nazwaPl));
      await settleDatabase(tester);
      final add = find.text('Dodaj wybrane ćwiczenie i przejdź do sesji');
      await tester.scrollUntilVisible(
        add,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(add);
      await settleDatabase(tester);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/workout/session',
      );
      expect(c.read(activeWorkoutProvider).isExtraExercise(extra.id), isTrue);
      final reps = find.widgetWithText(TextField, 'Powtórzenia');
      // Repeat target has a distinct label; this is the reusable EXTRA card.
      await tester.ensureVisible(reps.last);
      await tester.enterText(reps.last, '6');
      await tester.runAsync(
        () => c.read(activeWorkoutProvider.notifier).flushDraft(),
      );
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
      c = container();
      await tester.runAsync(() async {
        expect(
          await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
          isTrue,
        );
      });
      router.go('/workout/session');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settleDatabase(tester);
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Powtórzenia').last,
      );
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Powtórzenia').last,
            )
            .controller!
            .text,
        '6',
      );
      final save = find.text('Seria wykonana (0)');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await settleDatabase(tester);
      expect(c.read(activeWorkoutProvider).repeatCompletedCount, 0);
      await tester.runAsync(() async {
        final active = c.read(activeWorkoutProvider);
        final rows = await repo.getSetsForSession(active.sessionId!);
        expect(rows.single.cwiczenieId, extra.id);
        expect(
          WorkoutProgress.from(
            liveSetIds: rows.map((s) => s.syncId),
            repeat: active.repeat,
          ).percent,
          0,
        );
      });
      await tester.scrollUntilVisible(
        find.text('Zapisz tę serię'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zapisz tę serię'));
      await settleDatabase(tester);
      expect(c.read(activeWorkoutProvider).repeatCompletedCount, 1);
      await tester.runAsync(() async {
        final rows = await repo.getSetsForSession(
          c.read(activeWorkoutProvider).sessionId!,
        );
        expect(rows.length, 2);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'empty finish offers back, template editor and confirmed discard, no fake completion',
    (tester) async {
      await tester.runAsync(() async {
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession();
        n.addExercise(exercise);
        await n.flushDraft();
      });
      final router = await mount(tester);
      await tester.tap(find.text('Zakończ'));
      await settleDatabase(tester);
      expect(find.text('Pusty trening'), findsOneWidget);
      expect(find.text('Zapisz jako szablon'), findsOneWidget);
      expect(find.text('Odrzuć pusty trening'), findsOneWidget);
      await tester.tap(find.text('Wróć'));
      await settleDatabase(tester);
      await tester.tap(find.text('Zakończ'));
      await settleDatabase(tester);
      await tester.tap(find.text('Zapisz jako szablon'));
      await settleDatabase(tester);
      await tester.tap(find.text('Nowy szablon'));
      await settleDatabase(tester);
      expect(find.byType(TemplateEditorPage), findsOneWidget);
      expect(
        await tester.runAsync(() => db.select(db.workoutPlans).get()),
        isEmpty,
      );
      router.pop();
      await settleDatabase(tester);
      // The decision dialog may remain below the editor, intentionally unsaved.
      if (find.text('Odrzuć pusty trening').evaluate().isEmpty) {
        await tester.tap(find.text('Zakończ'));
        await settleDatabase(tester);
      }
      await tester.tap(find.text('Odrzuć pusty trening'));
      await settleDatabase(tester);
      expect(find.textContaining('0 zapisanych serii'), findsOneWidget);
      expect(find.textContaining('rekordy osobiste'), findsOneWidget);
      await tester.tap(find.text('Usuń trening').last);
      await settleDatabase(tester);
      expect(find.text('Pusty trening'), findsNothing);
      expect(find.text('Odrzuć pusty trening'), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/workout');
      await tester.runAsync(() async {
        final row = (await db.select(db.workoutSessions).get()).single;
        expect(row.dataKoniec, isNull);
        expect(row.deletedAtUtc, isNotNull);
        expect(await db.select(db.setsLog).get(), isEmpty);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'partial plan shows honest progress and missing targets; finish explicitly preserves note and real sets only',
    (tester) async {
      final plan = StructuredPlan(
        criteria: const ExerciseFilters(),
        budgetSeconds: 300,
        blocks: [
          PlanBlock(
            exerciseId: exercise.id,
            section: PlanSection.main,
            prescription: const PlanPrescription(
              tracking: 'reps',
              sets: 3,
              reps: 10,
              workSeconds: 30,
              restSeconds: 0,
              transitionSeconds: 0,
              weightKg: 12,
            ),
          ),
        ],
        warnings: [],
      );
      await tester.runAsync(() async {
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(plan));
        n.addExercise(exercise);
        await n.logSet(exercise: exercise, reps: 8);
        await n.flushDraft();
      });
      await mount(tester);
      expect(find.textContaining('1/3 • 33%'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Ciężar (kg)'))
            .controller!
            .text,
        '12.0',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Ciężar (kg)'),
        '7',
      );
      await settleDatabase(tester);
      await tester.runAsync(
        () => c.read(activeWorkoutProvider.notifier).flushDraft(),
      );
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
      c = container();
      await tester.runAsync(() async {
        expect(
          await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
          isTrue,
        );
      });
      await mount(tester);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Ciężar (kg)'))
            .controller!
            .text,
        '7',
      );
      await tester.tap(find.text('Zakończ'));
      await settleDatabase(tester);
      expect(find.textContaining('Pozostałe serie celu: 2'), findsOneWidget);
      expect(find.textContaining('wyniki timera'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Krótka notatka (opcjonalna)'),
        'Częściowo, świadomie',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Zakończ').last);
      await settleDatabase(tester);
      await tester.runAsync(() async {
        final row = (await db.select(db.workoutSessions).get()).single;
        expect(row.dataKoniec, isNotNull);
        expect(row.notatka, 'Częściowo, świadomie');
        expect((await db.select(db.setsLog).get()).length, 1);
        expect(await db.select(db.workoutDrafts).get(), isEmpty);
      });
      expect(find.textContaining('1/3 • 33%'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'empty recovery offers no finish confirmation and cannot create a fake completed record',
    (tester) async {
      await tester.runAsync(
        () => WorkoutRepository(db).startSession(accountId: 'a'),
      );
      await mount(tester, location: '/workout/recovery');
      await tester.tap(find.text('Zakończ bez wznawiania'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pusty trening'), findsOneWidget);
      expect(find.text('Zakończ sesję'), findsNothing);
      expect(find.text('Odrzuć pusty trening'), findsOneWidget);
      await tester.tap(find.text('Anuluj'));
      await settleDatabase(tester);
      await tester.runAsync(() async {
        expect(
          (await db.select(db.workoutSessions).get()).single.dataKoniec,
          isNull,
        );
        expect(await db.select(db.setsLog).get(), isEmpty);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'A B A during finish dialog cannot save the old note or completion',
    (tester) async {
      await tester.runAsync(() async {
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession();
        n.addExercise(exercise);
        await n.logSet(exercise: exercise, reps: 4);
        await n.flushDraft();
      });
      await mount(tester);
      final before = await tester.runAsync(
        () => db.select(db.syncOutbox).get(),
      );
      await tester.tap(find.text('Zakończ'));
      await settleDatabase(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Krótka notatka (opcjonalna)'),
        'Stary callback',
      );
      authority.switchTo('b');
      authority.switchTo('a');
      await tester.tap(find.widgetWithText(TextButton, 'Zakończ').last);
      await settleDatabase(tester);
      await tester.runAsync(() async {
        final row = (await db.select(db.workoutSessions).get()).single;
        expect(row.dataKoniec, isNull);
        expect(row.notatka, isNull);
        expect(await db.select(db.syncOutbox).get(), before);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'repeat extra rounds checkpoint survives restart; explicit timer save never advances target',
    (tester) async {
      extraTracking = 'rounds';
      final repo = WorkoutRepository(db);
      late String uuid;
      await tester.runAsync(() async {
        final source = await repo.startSession(accountId: 'a');
        await repo.logSet(
          sessionId: source,
          exerciseId: exercise.id,
          exerciseNamePl: exercise.nazwaPl,
          setNumber: 1,
          reps: 8,
          accountId: 'a',
        );
        await repo.finishSession(source, DateTime.now(), accountId: 'a');
        final n = c.read(activeWorkoutProvider.notifier);
        expect(
          await n.confirmRepeat(
            await n.previewRepeat(source, RepeatMode.execution),
          ),
          isTrue,
        );
        n.addExercise(extra);
        n.updateExerciseDraft(
          extra.id,
          {'rpe': 6, 'timer': completedLeftTimer()},
          extra: true,
          side: 'left',
        );
        await n.flushDraft();
        uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        c.dispose();
        c = container();
        expect(
          await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
          isTrue,
        );
      });
      await mount(tester);
      final timer = find.text('Timer interwałów');
      await tester.scrollUntilVisible(
        timer,
        300,
        maxScrolls: 20,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(timer);
      await settleDatabase(tester);
      expect(find.text('Runda 1: 10 s'), findsOneWidget);
      await tester.ensureVisible(find.text('Zapisz wykonane rundy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zapisz wykonane rundy'));
      await settleDatabase(tester);
      await tester.runAsync(() async {
        await c.read(activeWorkoutProvider.notifier).flushDraft();
        final active = c.read(activeWorkoutProvider);
        final sets = await repo.getSetsForSession(active.sessionId!);
        expect(sets.single.cwiczenieId, extra.id);
        expect(sets.single.czasSekund, 10);
        expect(sets.single.side, 'left');
        expect(active.repeatCompletedCount, 0);
        expect(active.repeatTarget!.reps, 8);
        expect(
          active.exerciseDraft(extra.id, extra: true, side: 'left')['timer'],
          isNull,
        );
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
