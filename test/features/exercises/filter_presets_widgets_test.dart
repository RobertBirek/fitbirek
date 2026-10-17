import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/data/filter_presets_repository.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercises_list_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'catalog_filter_test.dart' show exercise, metadata;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    Stream<List<Exercise>>? catalog,
    Stream<String?>? account,
  }) async {
    final c = ProviderContainer(
      overrides: [
        filterPresetsRepositoryProvider.overrideWithValue(
          FilterPresetsRepository(),
        ),
        filterPresetsAccountProvider.overrideWith(
          (ref) => account ?? Stream.value('opaque-A'),
        ),
        allExercisesProvider.overrideWith(
          (ref) => catalog ?? Stream.value([exercise('a', name: 'Dłonie')]),
        ),
        exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: ExercisesListPage()),
      ),
    );
    await tester.pump();
    if (catalog == null) await tester.pumpAndSettle();
    return c;
  }

  testWidgets('presets describe offline access and authenticated sync', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Zestawy są dostępne offline dla bieżącego konta i synchronizowane po zalogowaniu.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('tylko na tym urządzeniu'), findsNothing);
  });

  testWidgets('save, validate, overwrite, apply and reset', (tester) async {
    final stream = StreamController<List<Exercise>>();
    addTearDown(stream.close);
    final c = await mount(tester, catalog: stream.stream);
    stream.add([exercise('a', name: 'Dłonie')]);
    c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
      query: 'dłonie',
      styles: {'tai'},
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz aktualne'));
    await tester.pumpAndSettle();
    expect(find.text('Nazwa musi mieć od 1 do 80 znaków.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('preset-name')), '  Dom  ');
    await tester.tap(find.text('Zapisz aktualne'));
    await tester.pumpAndSettle();
    expect(find.text('Dom'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('preset-name')), 'dom');
    await tester.tap(find.text('Zapisz aktualne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Zastąpić zestaw „Dom”?'), findsOneWidget);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(await FilterPresetsRepository().load('opaque-A'), hasLength(1));
    await tester.tap(find.text('Zapisz aktualne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Zastąp'));
    await tester.pumpAndSettle();
    expect(await FilterPresetsRepository().load('opaque-A'), hasLength(1));
    await tester.tap(find.text('Zamknij'));
    await tester.pumpAndSettle();
    c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
      query: 'nothing',
    );
    stream.add([
      exercise('a', name: 'Dłonie'),
      exercise('new', name: 'Nowe dłonie'),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Wczytaj dom'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'dłonie',
    );
    expect(find.widgetWithText(InputChip, 'Tai chi'), findsOneWidget);
    // The new record has no style classification; removing style includes it.
    expect(c.read(exerciseFiltersProvider).styles, {'tai'});
    c
        .read(exerciseFiltersProvider.notifier)
        .update((f) => f.copyWith(styles: {}));
    await tester.pumpAndSettle();
    expect(c.read(filteredExercisesProvider), hasLength(2));
    expect(c.read(exerciseFacetsProvider).styles, {'tai': 1});
    await tester.tap(find.byTooltip('Filtry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wyczyść filtry'));
    await tester.tap(find.byTooltip('Zamknij filtry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    expect(find.text('dom'), findsOneWidget);
    await tester.tap(find.byTooltip('Usuń dom'));
    await tester.pumpAndSettle();
    expect(await FilterPresetsRepository().load('opaque-A'), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('switch/logout hides presets and disables saving', (
    tester,
  ) async {
    await FilterPresetsRepository().save(
      'opaque-A',
      'Secret A',
      const ExerciseFilters(),
    );
    final accounts = StreamController<String?>();
    addTearDown(accounts.close);
    await mount(tester, account: accounts.stream);
    accounts.add('opaque-A');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    expect(find.text('Secret A'), findsOneWidget);
    accounts.add('B');
    await tester.pumpAndSettle();
    expect(find.text('Secret A'), findsNothing);
    expect(find.text('Zapisz aktualne'), findsNothing);
    await tester.tap(find.text('Zamknij'));
    await tester.pumpAndSettle();
    accounts.add(null);
    await tester.pumpAndSettle();
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Zapisane filtry'),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('switch redacts overwrite confirmation', (tester) async {
    await FilterPresetsRepository().save(
      'opaque-A',
      'Private name',
      const ExerciseFilters(),
    );
    final accounts = StreamController<String?>();
    addTearDown(accounts.close);
    await mount(tester, account: accounts.stream);
    accounts.add('opaque-A');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('preset-name')),
      'Private name',
    );
    await tester.tap(find.text('Zapisz aktualne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Zastąpić zestaw'), findsOneWidget);
    accounts.add('B');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Private name'), findsNothing);
    expect(find.text('Zastąp'), findsNothing);
  });
  testWidgets('restore applies criteria to live catalog', (tester) async {
    await FilterPresetsRepository().save(
      'opaque-A',
      'Live',
      const ExerciseFilters(query: 'dłonie', sprzet: {'Krzesło'}),
    );
    final catalog = StreamController<List<Exercise>>();
    addTearDown(catalog.close);
    final c = await mount(tester, catalog: catalog.stream);
    catalog.add([
      exercise('fresh', name: 'Nowe dłonie', equipment: ['Krzesło']),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zapisane filtry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Wczytaj Live'));
    await tester.pumpAndSettle();
    expect(c.read(filteredExercisesProvider).map((e) => e.id), ['fresh']);
    expect(c.read(exerciseFacetsProvider).equipment, {'Krzesło': 1});
    expect(find.widgetWithText(InputChip, 'Krzesło'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'dłonie',
    );
    catalog.add([
      exercise('fresh', name: 'Nowe dłonie', equipment: ['Krzesło']),
      exercise('newer', name: 'Kolejne dłonie', equipment: ['Krzesło']),
      exercise('unrelated', name: 'Przysiad'),
    ]);
    await tester.pumpAndSettle();
    expect(c.read(filteredExercisesProvider).map((e) => e.id).toSet(), {
      'fresh',
      'newer',
    });
    expect(c.read(exerciseFacetsProvider).equipment, {'Krzesło': 2});
    expect(find.text('Wyniki: 2'), findsOneWidget);
  });
}
