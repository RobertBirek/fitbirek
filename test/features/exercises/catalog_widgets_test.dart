import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercises_list_page.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/providers/session_recovery_provider.dart';
import 'catalog_filter_test.dart' show metadata, exercise;

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    Stream<List<Exercise>>? stream,
    ExerciseFilters filters = const ExerciseFilters(),
    bool metadataError = false,
    Widget page = const ExercisesListPage(),
    List<Override> overrides = const [],
  }) async {
    final container = ProviderContainer(
      overrides: [
        allExercisesProvider.overrideWith(
          (ref) =>
              stream ??
              Stream.value([
                exercise('a', name: 'Płynące dłonie'),
                exercise('b', name: 'Wyciskanie', equipment: ['Krzesło']),
              ]),
        ),
        exerciseCatalogMetadataProvider.overrideWith((ref) async {
          if (metadataError) throw StateError('fixture error');
          return metadata;
        }),
        exerciseFiltersProvider.overrideWith((ref) => filters),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: page),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets(
    'sheet filters LIVE, exposes counts, expands OR, and resets visible search',
    (tester) async {
      final container = await mount(tester);
      await tester.enterText(find.byType(TextField), 'movement');
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Tai chi (1)'));
      await tester.pumpAndSettle();
      expect(container.read(filteredExercisesProvider).map((e) => e.id), ['a']);
      expect(find.text('Filtry • wyniki: 1'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Siłowy (1)'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Siłowy (1)'));
      await tester.pumpAndSettle();
      expect(container.read(filteredExercisesProvider), hasLength(2));
      expect(find.text('Filtry • wyniki: 2'), findsOneWidget);
      await tester.tap(find.text('Wyczyść filtry'));
      await tester.pumpAndSettle();
      expect(container.read(exerciseFiltersProvider).query, '');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected zero option remains removable and active chips outside sheet',
    (tester) async {
      final container = await mount(
        tester,
        filters: const ExerciseFilters(styles: {'tai'}, sprzet: {'Krzesło'}),
      );
      expect(find.widgetWithText(InputChip, 'Tai chi'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Tai chi (0)'));
      await tester.pumpAndSettle();
      expect(container.read(exerciseFiltersProvider).styles, isEmpty);
    },
  );

  testWidgets('loading and stream errors are not false empty results', (
    tester,
  ) async {
    final stream = StreamController<List<Exercise>>();
    addTearDown(stream.close);
    await mount(tester, stream: stream.stream);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Brak wyników'), findsNothing);
    stream.addError(StateError('offline fixture'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nie udało się wczytać ćwiczeń'),
      findsOneWidget,
    );
    expect(find.text('Brak wyników'), findsNothing);
  });

  testWidgets('metadata error explains fallback without hiding records', (
    tester,
  ) async {
    await mount(tester, metadataError: true);
    await tester.pumpAndSettle();
    expect(find.text('Płynące dłonie'), findsOneWidget);
    expect(find.textContaining('Klasyfikacja niedostępna'), findsOneWidget);
  });

  testWidgets(
    'metadata error suspends classification choices but keeps other filters',
    (tester) async {
      final container = await mount(
        tester,
        metadataError: true,
        filters: const ExerciseFilters(
          styles: {'strength'},
          muscles: {'back'},
          sprzet: {'Krzesło'},
          query: 'movement',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wyciskanie'), findsOneWidget);
      expect(container.read(filteredExercisesProvider).map((e) => e.id), ['b']);
      expect(container.read(exerciseFiltersProvider).styles, {'strength'});
      expect(container.read(exerciseFiltersProvider).muscles, {'back'});
      expect(find.textContaining('czasowo pomijane'), findsOneWidget);
    },
  );

  testWidgets(
    'muscle selected while pending stays canonical and matches after load',
    (tester) async {
      final completer = Completer<ExerciseCatalogMetadata>();
      final muscleMetadata = ExerciseCatalogMetadata.fromJson({
        'schemaVersion': 1,
        'styles': [],
        'muscles': [
          {
            'id': 'biceps',
            'label': 'Biceps',
            'aliases': ['dwugłowy ramienia'],
          },
        ],
        'exercises': {
          'a': {
            'styles': [],
            'primaryMuscles': ['biceps'],
            'secondaryMuscles': [],
            'aliases': [],
            'tracking': 'reps',
            'unilateral': false,
          },
        },
      });
      final container = ProviderContainer(
        overrides: [
          allExercisesProvider.overrideWith(
            (ref) =>
                Stream.value([exercise('a').copyWith(partiaGlowna: 'Biceps')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ExercisesListPage()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Biceps (1)'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(FilterChip, 'Biceps (1)'));
      await tester.pump();
      expect(container.read(exerciseFiltersProvider).muscles, {'biceps'});
      expect(container.read(filteredExercisesProvider).map((e) => e.id), ['a']);
      completer.complete(muscleMetadata);
      await tester.pumpAndSettle();
      expect(container.read(exerciseFiltersProvider).muscles, {'biceps'});
      expect(container.read(filteredExercisesProvider).map((e) => e.id), ['a']);
      expect(find.widgetWithText(FilterChip, 'Biceps (1)'), findsOneWidget);
      expect(container.read(exerciseFacetsProvider).muscles, {'biceps': 1});
    },
  );

  testWidgets(
    'small screen sheet scrolls without overflow and closes keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester);
      await tester.tap(find.byType(TextField));
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail distinguishes primary and supporting muscles', (
    tester,
  ) async {
    await mount(
      tester,
      page: const ExerciseDetailPage(exerciseId: 'a'),
      overrides: [
        // This is a metadata fixture, not a database/bootstrap integration test.
        sessionRecoveryProvider.overrideWith((ref) {
          final authority = ref.read(cachedAuthWriteAuthorityProvider);
          return Stream.value(
            SessionRecovery(
              authority.state?.accountId,
              authority.epoch,
              const [],
            ),
          );
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Mięśnie główne'), findsOneWidget);
    expect(find.text('Mięśnie wspierające'), findsOneWidget);
    expect(find.text('Ramiona'), findsOneWidget);
  });

  testWidgets(
    'late offline metadata refreshes filters and results without reopening sheet',
    (tester) async {
      final completer = Completer<ExerciseCatalogMetadata>();
      final container = ProviderContainer(
        overrides: [
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('a')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => await completer.future,
          ),
          exerciseFiltersProvider.overrideWith(
            (ref) => const ExerciseFilters(styles: {'tai'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ExercisesListPage()),
        ),
      );
      await tester.pump();
      expect(find.text('Brak wyników'), findsNothing);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pump(const Duration(milliseconds: 350));
      completer.complete(metadata);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Tai chi (1)'), findsOneWidget);
      expect(find.text('Filtry • wyniki: 1'), findsOneWidget);
    },
  );
}
