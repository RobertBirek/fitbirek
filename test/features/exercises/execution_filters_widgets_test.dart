import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercises_list_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'catalog_filter_test.dart' show exercise, metadata;
import 'execution_filters_test.dart' show executionIndex;

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    bool broken = false,
    bool old = false,
    Stream<List<Exercise>>? catalog,
  }) async {
    final c = ProviderContainer(
      overrides: [
        filterPresetsAccountProvider.overrideWith((ref) => Stream.value(null)),
        allExercisesProvider.overrideWith(
          (ref) =>
              catalog ??
              Stream.value([exercise('a'), exercise('b'), exercise('custom')]),
        ),
        exerciseCatalogMetadataProvider.overrideWith((ref) async {
          if (broken) throw const FormatException('corrupt metadata');
          return old
              ? metadata
              : ExerciseCatalogMetadata.fromJson(executionIndex());
        }),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: ExercisesListPage()),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets(
    'execution chips, live AND counts, selected zero removable, reset',
    (tester) async {
      final c = await mount(tester);
      c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
        conditions: {'quiet'},
        positions: {'seated'},
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'Cichy trening'), findsOneWidget);
      expect(find.text('Wyniki: 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Filtry'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilterChip, 'Cichy trening (1)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilterChip, 'Stojąco (1)'), findsOneWidget);
      c
          .read(exerciseFiltersProvider.notifier)
          .update((f) => f.copyWith(conditions: {'quiet', 'future_condition'}));
      await tester.pumpAndSettle();
      final zero = find.widgetWithText(FilterChip, 'future_condition (0)');
      await tester.ensureVisible(zero);
      await tester.tap(zero);
      await tester.pumpAndSettle();
      expect(c.read(exerciseFiltersProvider).conditions, {'quiet'});
      await tester.tap(find.text('Wyczyść filtry'));
      await tester.pumpAndSettle();
      expect(c.read(exerciseFiltersProvider).conditions, isEmpty);
      expect(c.read(exerciseFiltersProvider).positions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'open sheet counts react to live catalog and all other criteria',
    (tester) async {
      final catalog = StreamController<List<Exercise>>();
      addTearDown(catalog.close);
      // A single-subscription stream buffers this event until mounting.
      catalog.add([exercise('a'), exercise('b')]);
      final c = await mount(tester, catalog: catalog.stream);
      c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
        conditions: {'quiet'},
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filtry'));
      await tester.pumpAndSettle();
      expect(find.text('Cichy trening (2)'), findsOneWidget);
      expect(find.text('Bez skoków (1)'), findsOneWidget);
      catalog.add([exercise('b')]);
      await tester.pumpAndSettle();
      expect(find.text('Cichy trening (1)'), findsOneWidget);
      expect(find.text('Bez skoków (1)'), findsNothing);
      c
          .read(exerciseFiltersProvider.notifier)
          .update((f) => f.copyWith(positions: {'standing'}));
      await tester.pumpAndSettle();
      expect(find.text('Cichy trening (0)'), findsOneWidget);
      final zero = find.widgetWithText(FilterChip, 'Stojąco (0)');
      await tester.ensureVisible(zero);
      await tester.tap(zero);
      await tester.pumpAndSettle();
      expect(c.read(filteredExercisesProvider).map((e) => e.id), ['b']);
    },
  );
  for (final old in [false, true]) {
    testWidgets(
      'unavailable/old metadata is explicit and does not broaden ($old)',
      (tester) async {
        final c = await mount(tester, broken: !old, old: old);
        c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
          conditions: {'quiet'},
        );
        await tester.pumpAndSettle();
        expect(c.read(filteredExercisesProvider), isEmpty);
        expect(find.textContaining('Nie można zweryfikować'), findsWidgets);
        expect(find.widgetWithText(InputChip, 'Cichy trening'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
