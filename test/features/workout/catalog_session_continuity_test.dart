import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/providers/session_recovery_provider.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/workout_recovery_page.dart';
import 'package:fitbirek_training/core/widgets/primary_button.dart';
import 'session_tracking_test.dart' show exercise;
import 'session_recovery_provider_test.dart' show RecoveryAuthority;

class WaitingCatalogStart extends WorkoutRepository {
  WaitingCatalogStart(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  int calls = 0;
  @override
  Future<int> startSession({
    bool Function()? guard,
    String? accountId,
    WorkoutGuidance? guidance,
    bool requireNoActiveSession = false,
  }) async {
    calls++;
    entered.complete();
    await release.future;
    return super.startSession(
      guard: guard,
      accountId: accountId,
      guidance: guidance,
      requireNoActiveSession: requireNoActiveSession,
    );
  }
}

Future<void> settleDatabase(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pl'));
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  for (final mode in ['fresh', 'ram', 'draft', 'orphan']) {
    testWidgets('catalog real router preserves base exercise: $mode', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ProviderContainer container() => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith((ref) => Stream.value([exercise])),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(),
          ),
        ],
      );
      var c = container();
      var initialSets = <SetLogData>[];
      String? previous;
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        if (mode == 'orphan') {
          final id = await WorkoutRepository(db).startSession(accountId: 'a');
          await WorkoutRepository(db).logSet(
            sessionId: id,
            exerciseId: exercise.id,
            exerciseNamePl: exercise.nazwaPl,
            setNumber: 1,
            reps: 1,
            accountId: 'a',
          );
          previous = (await db.workoutDao.getSession(id))!.syncId;
        } else if (mode != 'fresh') {
          await c.read(activeWorkoutProvider.notifier).startSession();
          await c.read(activeWorkoutProvider.notifier).flushDraft();
          previous = c.read(activeWorkoutProvider).sessionSyncId;
          if (mode == 'draft') {
            c.dispose();
            c = container();
          }
        }
      });
      initialSets = (await tester.runAsync(() => db.select(db.setsLog).get()))!;
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('a'),
        readOnboardingComplete: () => true,
        initialLocation: mode == 'fresh'
            ? '/exercises'
            : '/exercises/${exercise.id}',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settleDatabase(tester);
      if (mode == 'fresh') {
        await tester.tap(find.text(exercise.nazwaPl));
        await settleDatabase(tester);
      }
      final start = find.text(
        mode == 'ram'
            ? 'Dodaj wybrane ćwiczenie i przejdź do sesji'
            : 'Rozpocznij trening z tym ćwiczeniem',
      );
      await tester.scrollUntilVisible(
        start,
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(start);
      await settleDatabase(tester);
      if (mode == 'draft' || mode == 'orphan') {
        expect(
          find.text('Wybrane ćwiczenie: ${exercise.nazwaPl} (bazowe)'),
          findsOneWidget,
        );
        expect(c.read(activeWorkoutProvider).selectedExercises, isEmpty);
        if (mode == 'draft') {
          await tester.tap(find.text('Wznów trening'));
          await settleDatabase(tester);
          expect(c.read(activeWorkoutProvider).selectedExercises, isEmpty);
          expect(c.read(activeWorkoutProvider).sessionSyncId, previous);
          await tester.tap(
            find.text('Dodaj wybrane ćwiczenie i przejdź do sesji'),
          );
        } else {
          await tester.tap(find.text('Zakończ bez wznawiania'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Anuluj'));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            expect(
              (await db.select(db.workoutSessions).get()).single.dataKoniec,
              isNull,
            );
          });
          await tester.tap(find.text('Zakończ bez wznawiania'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Zakończ sesję'));
          await settleDatabase(tester);
          await tester.tap(find.text('Rozpocznij trening z tym ćwiczeniem'));
        }
        await settleDatabase(tester);
      }
      expect(tester.takeException(), isNull);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/workout/session',
      );
      final active = c.read(activeWorkoutProvider);
      expect(active.isActive, isTrue);
      expect(active.selectedExercises.map((e) => e.id), [exercise.id]);
      if (mode == 'ram' || mode == 'draft') {
        expect(active.sessionSyncId, previous);
      }
      await tester.runAsync(() async {
        await c.read(activeWorkoutProvider.notifier).flushDraft();
        expect(
          (await db.select(db.workoutSessions).get()).length,
          mode == 'orphan' ? 2 : 1,
        );
        expect(await db.select(db.setsLog).get(), initialSets);
        expect(await db.select(db.personalRecords).get(), isEmpty);
      });
      if (mode == 'fresh') {
        final reps = find.widgetWithText(TextField, 'Powtórzenia');
        await tester.ensureVisible(reps);
        await tester.pumpAndSettle();
        await tester.enterText(reps, '8');
        final save = find.text('Seria wykonana (0)');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await settleDatabase(tester);
        await tester.runAsync(() async {
          final row = (await db.select(db.setsLog).get()).single;
          expect(row.cwiczenieId, exercise.id);
          expect(row.variantId, isNull);
          expect(row.variantLabel, isNull);
          expect(row.powtorzenia, 8);
        });
      }
    });
  }

  testWidgets(
    'home shows orphan without draft at 320 text2 and routes to safe recovery',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        await WorkoutRepository(db).startSession(accountId: 'a');
      });
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('a'),
        readOnboardingComplete: () => true,
        initialLocation: '/workout',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
          ),
        ),
      );
      await settleDatabase(tester);
      expect(find.text('Niedokończony trening'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final recovery = find.text('Odzyskaj lub zakończ');
      await tester.ensureVisible(recovery);
      await tester.pumpAndSettle();
      await tester.tap(recovery);
      await settleDatabase(tester);
      expect(find.byType(WorkoutRecoveryPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Zakończ bez wznawiania'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Zakończ bez wznawiania'), findsOneWidget);
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final withDraft in [false, true]) {
    testWidgets(
      'RAM S1 keeps other S2 visible and explicit finish preserves S1 draft=$withDraft',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([exercise]),
            ),
          ],
        );
        late int otherId;
        late String currentId;
        late String otherUuid;
        late Object beforeState;
        late Map<String, dynamic> beforeRow;
        late List<Object?> beforeOutbox;
        late List<SetLogData> beforeSets;
        await tester.runAsync(() async {
          await db
              .into(db.syncState)
              .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
          final n = c.read(activeWorkoutProvider.notifier);
          await n.startSession();
          n.addExercise(exercise);
          n.updateDraft({'reps': '9', 'side': 'left'});
          await n.flushDraft();
          currentId = c.read(activeWorkoutProvider).sessionSyncId!;
          otherId = await WorkoutRepository(db).startSession(accountId: 'a');
          await WorkoutRepository(db).logSet(
            sessionId: otherId,
            exerciseId: exercise.id,
            exerciseNamePl: exercise.nazwaPl,
            setNumber: 1,
            reps: 1,
            accountId: 'a',
          );
          otherUuid = (await db.workoutDao.getSession(otherId))!.syncId;
          if (withDraft) {
            // A second local/synced session may also carry a valid recoverable draft.
            final draft = (await db.select(db.workoutDrafts).get()).single;
            await db
                .into(db.workoutDrafts)
                .insert(draft.copyWith(sessionSyncId: otherUuid));
          }
          beforeState = c.read(activeWorkoutProvider);
          beforeSets = await db.select(db.setsLog).get();
          beforeRow = (await db.workoutDao.getSession(
            c.read(activeWorkoutProvider).sessionId!,
          ))!.toJson();
          beforeOutbox = (await db.syncDao.pendingOperations())
              .map((op) => op.toJson())
              .toList();
          expect(await n.finishPendingSession(currentId), isNull);
        });
        final router = createRouter(
          readAuthState: () => const AuthState.signedIn('a'),
          readOnboardingComplete: () => true,
          initialLocation: '/workout',
        );
        addTearDown(() async {
          router.dispose();
          c.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await settleDatabase(tester);
        expect(find.text('Sesja: $otherUuid'), findsOneWidget);
        expect(find.text('Sesja: $currentId'), findsNothing);
        await tester.ensureVisible(find.text('Odzyskaj lub zakończ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Odzyskaj lub zakończ'));
        await settleDatabase(tester);
        expect(find.byType(WorkoutRecoveryPage), findsOneWidget);
        expect(find.text('Sesja: $otherUuid'), findsOneWidget);
        expect(find.text('Sesja: $currentId'), findsNothing);
        final resume = find.widgetWithText(FilledButton, 'Wznów trening');
        if (withDraft) {
          expect(tester.widget<FilledButton>(resume).onPressed, isNull);
        }
        await tester.runAsync(() async {
          expect(
            await c
                .read(activeWorkoutProvider.notifier)
                .resumeSession(otherUuid),
            isFalse,
          );
        });
        await tester.ensureVisible(find.text('Zakończ bez wznawiania'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zakończ bez wznawiania'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Anuluj'));
        await settleDatabase(tester);
        await tester.runAsync(() async {
          expect((await db.workoutDao.getSession(otherId))!.dataKoniec, isNull);
          expect(
            (await db.syncDao.pendingOperations())
                .map((op) => op.toJson())
                .toList(),
            beforeOutbox,
          );
        });
        expect(c.read(activeWorkoutProvider), same(beforeState));
        await tester.tap(find.text('Zakończ bez wznawiania'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Zakończ sesję'));
        await settleDatabase(tester);
        expect(c.read(activeWorkoutProvider), same(beforeState));
        await tester.runAsync(() async {
          expect(
            (await db.workoutDao.getSession(otherId))!.dataKoniec,
            isNotNull,
          );
          expect(
            (await db.workoutDao.getSession(
              c.read(activeWorkoutProvider).sessionId!,
            ))!.toJson(),
            beforeRow,
          );
          final operations = await db.syncDao.pendingOperations();
          expect(
            operations
                .where((op) => op.entityId == currentId)
                .map((op) => op.toJson())
                .toList(),
            beforeOutbox
                .whereType<Map<String, dynamic>>()
                .where((op) => op['entityId'] == currentId)
                .toList(),
          );
          expect(await db.select(db.setsLog).get(), beforeSets);
          expect(await db.select(db.personalRecords).get(), isEmpty);
        });
        expect(find.text('Wróć do aktywnej sesji'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    'loading-error',
    'authority',
    'double',
    'collision',
    'cancel',
  ]) {
    testWidgets('catalog intent safety: $scenario', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = RecoveryAuthority();
      final repo = WaitingCatalogStart(db);
      final recovery = StreamController<SessionRecovery>();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          if (scenario != 'cancel')
            workoutRepositoryProvider.overrideWithValue(repo),
          if (scenario == 'loading-error')
            sessionRecoveryProvider.overrideWith((ref) => recovery.stream),
          allExercisesProvider.overrideWith((ref) => Stream.value([exercise])),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(),
          ),
        ],
      );
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        if (scenario == 'cancel') {
          await WorkoutRepository(db).startSession(accountId: 'a');
        }
      });
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('a'),
        readOnboardingComplete: () => true,
        initialLocation: '/exercises/${exercise.id}',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        unawaited(recovery.close());
        authority.revision.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      // A loading recovery intentionally keeps its spinner running.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      if (scenario != 'loading-error') await settleDatabase(tester);
      final button = find.byWidgetPredicate(
        (w) =>
            w is PrimaryButton &&
            w.label == 'Rozpocznij trening z tym ćwiczeniem',
      );
      await tester.scrollUntilVisible(
        button,
        400,
        scrollable: find.byType(Scrollable).last,
      );
      if (scenario != 'loading-error') await settleDatabase(tester);
      if (scenario == 'loading-error') {
        expect(tester.widget<PrimaryButton>(button).onPressed, isNull);
        recovery.addError(StateError('private database error'));
        await settleDatabase(tester);
        expect(tester.widget<PrimaryButton>(button).onPressed, isNull);
        expect(find.textContaining('private database error'), findsNothing);
        expect(repo.calls, 0);
      } else {
        expect(tester.widget<PrimaryButton>(button).onPressed, isNotNull);
        await tester.tap(button);
        if (scenario == 'cancel') {
          await settleDatabase(tester);
          expect(
            find.text('Wybrane ćwiczenie: ${exercise.nazwaPl} (bazowe)'),
            findsOneWidget,
          );
          router.pop();
          await settleDatabase(tester);
          expect(
            router.routeInformationProvider.value.uri.path,
            '/exercises/${exercise.id}',
          );
        } else {
          await tester.runAsync(
            () => repo.entered.future.timeout(const Duration(seconds: 3)),
          );
          if (scenario == 'double') {
            // Same pre-rebuild callback: the synchronous busy guard must work too.
            tester.widget<PrimaryButton>(button).onPressed?.call();
          }
          if (scenario == 'authority') {
            authority.switchTo('b');
            authority.switchTo('a');
          }
          if (scenario == 'collision') {
            await tester.runAsync(
              () => WorkoutRepository(db).startSession(accountId: 'a'),
            );
          }
          repo.release.complete();
          await settleDatabase(tester);
          expect(repo.calls, 1);
          if (scenario == 'collision') {
            expect(find.byType(WorkoutRecoveryPage), findsOneWidget);
            expect(find.text('Zakończ bez wznawiania'), findsOneWidget);
          }
        }
      }
      expect(
        c.read(activeWorkoutProvider).selectedExercises.map((e) => e.id),
        scenario == 'double' ? [exercise.id] : isEmpty,
      );
      await tester.runAsync(() async {
        final sessions = await db.select(db.workoutSessions).get();
        expect(
          sessions.length,
          ['cancel', 'collision', 'double'].contains(scenario) ? 1 : 0,
        );
        expect(sessions.where((s) => s.dataKoniec != null), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        expect(await db.select(db.personalRecords).get(), isEmpty);
      });
      expect(tester.takeException(), isNull);
    });
  }
}
