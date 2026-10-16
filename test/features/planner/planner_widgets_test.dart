import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercises_list_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import '../exercises/catalog_filter_test.dart' show exercise, metadata;
import 'structured_plan_persistence_test.dart' show structure;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'standalone preview restores exact blocks without presets or auth bootstrap; missing metadata blocks generation',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await PlannerRepository(db).savePlan(
        nazwa: 'Zapisana joga',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Stary', cwiczeniaIds: ['a'], cel: 'mix');
      final pending = Completer<ExerciseCatalogMetadata>();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          plannerEntryCriteriaProvider.overrideWith(
            (ref) => const ExerciseFilters(styles: {'yoga'}),
          ),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('yoga', name: 'Joga zapisana')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) => pending.future),
          userProfileStreamProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(
                imie: 'Test',
                wiek: 30,
                wzrostCm: 180,
                wagaKg: 80,
                cel: CelTreningowy.mix,
                dostepnySprzet: ['Hantle'],
                dataUtworzenia: DateTime(2026),
              ),
            ),
          ),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: PlannerPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wygeneruj plan'));
      await tester.pumpAndSettle();
      expect(find.text('Joga zapisana'), findsNothing);
      expect(find.textContaining('Poczekaj na ćwiczenia'), findsOneWidget);
      await tester.ensureVisible(find.text('Zapisana joga'));
      await tester.tap(find.text('Zapisana joga'));
      await tester.pumpAndSettle();
      expect(find.text('Joga zapisana'), findsOneWidget);
      expect(find.textContaining('2 serie × 40 s'), findsOneWidget);
      expect(find.textContaining('Stary plan — lista'), findsOneWidget);
      expect(c.exists(filterPresetsProvider), isFalse);
      expect(c.exists(authStateProvider), isFalse);
      expect(
        (await c.read(savedPlansProvider.future)).first.structure!.toJson(),
        structure.toJson(),
      );
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Wygeneruj plan'));
      await tester.tap(find.text('Wygeneruj plan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kryteriów nie pominięto'), findsOneWidget);
    },
  );
  testWidgets(
    'one Baza action snapshots criteria; latest catalog; explicit save/start',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final stream = StreamController<List<Exercise>>();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith((ref) => stream.stream),
          exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
          filterPresetsAccountProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
          userProfileStreamProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(
                imie: 'Test',
                wiek: 30,
                wzrostCm: 180,
                wagaKg: 80,
                cel: CelTreningowy.mix,
                dostepnySprzet: ['Hantle'],
                dataUtworzenia: DateTime(2026),
              ),
            ),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/exercises',
        routes: [
          GoRoute(
            path: '/exercises',
            builder: (_, __) => const ExercisesListPage(),
          ),
          GoRoute(
            path: '/settings/planner',
            builder: (_, __) => const PlannerPage(),
          ),
          GoRoute(
            path: '/workout/session',
            builder: (_, __) => const Scaffold(body: Text('Aktywna sesja')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await stream.close();
        await db.close();
      });
      c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
        styles: {'tai'},
        query: 'Ruch',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      stream.add([exercise('a', name: 'Ruch stary')]);
      await tester.pumpAndSettle();
      expect(find.text('Ułóż trening z tych ćwiczeń'), findsOneWidget);
      await tester.tap(find.text('Ułóż trening z tych ćwiczeń'));
      await tester.pumpAndSettle();
      c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
        query: 'NIE',
      );
      stream.add([
        exercise('a', name: 'Ruch aktualny'),
        exercise('b', name: 'Poza stylem'),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wygeneruj plan'));
      await tester.pumpAndSettle();
      expect(find.text('Ruch aktualny'), findsOneWidget);
      expect(find.text('Poza stylem'), findsNothing);
      expect(find.textContaining('Czas ESTYMOWANY'), findsOneWidget);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      await tester.ensureVisible(find.text('Zapisz plan'));
      await tester.tap(find.text('Zapisz plan'));
      await tester.pumpAndSettle();
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(
        (await db.select(db.workoutPlans).get()).single.structureJson,
        isNotNull,
      );
      await tester.ensureVisible(find.text('Rozpocznij trening'));
      await tester.tap(find.text('Rozpocznij trening'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(find.text('Aktywna sesja'), findsOneWidget);
      expect(
        c.read(activeWorkoutProvider).selectedExercises.single.nazwaPl,
        'Ruch aktualny',
      );
    },
  );
}
