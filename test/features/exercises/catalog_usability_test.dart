import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/native.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercises_list_page.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'catalog_filter_test.dart' show exercise;
import '../../helpers/min_interactive_target.dart';

void main() {
  for (final width in [1280.0, 375.0, 320.0]) {
    for (final selected in [false, true]) {
      testWidgets(
        'favorite actual48 desktop compact width=$width selected=$selected',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.linux;
          final semantics = tester.ensureSemantics();
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          try {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  appDatabaseProvider.overrideWithValue(db),
                  filterPresetsAccountProvider.overrideWith(
                    (ref) => Stream.value(null),
                  ),
                  allExercisesProvider.overrideWith(
                    (ref) =>
                        Stream.value([exercise('cw001', favorite: selected)]),
                  ),
                  exerciseCatalogMetadataProvider.overrideWith(
                    (ref) async => const ExerciseCatalogMetadata(),
                  ),
                ],
                child: MaterialApp(
                  theme: FitBirekTheme.dark,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(selected ? 2 : 1),
                      viewInsets: EdgeInsets.only(bottom: selected ? 180 : 0),
                    ),
                    child: child!,
                  ),
                  home: const ExerciseDetailPage(exerciseId: 'cw001'),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final control = find.widgetWithIcon(
              IconButton,
              selected ? Icons.star : Icons.star_border,
            );
            expectMinInteractiveTarget(tester, control);
            expect(
              find.byTooltip(
                selected ? 'Usuń z ulubionych' : 'Dodaj do ulubionych',
              ),
              findsOneWidget,
            );
            expect(tester.widget<IconButton>(control).isSelected, selected);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
            await tester.runAsync(db.close);
            semantics.dispose();
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  }
  testWidgets('320 text200 keyboard: warnings and results share one scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer(
      overrides: [
        filterPresetsAccountProvider.overrideWith((ref) => Stream.value(null)),
        allExercisesProvider.overrideWith(
          (ref) => Stream.value([exercise('a')]),
        ),
        exerciseCatalogMetadataProvider.overrideWith(
          (ref) async => throw StateError('private'),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
      conditions: {'quiet'},
      styles: {'strength'},
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 200),
            ),
            child: child!,
          ),
          home: const ExercisesListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    expect(vertical, findsOneWidget);
    expect(find.textContaining('Kryteriów nie pominięto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wyniki: 0'),
      180,
      scrollable: vertical,
    );
    await tester.pumpAndSettle();
    expect(find.text('Wyniki: 0').hitTestable(), findsOneWidget);
  });
  testWidgets('detail favorite is named and 48px, illustration at most 360', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filterPresetsAccountProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('cw001')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => throw StateError('private'),
          ),
        ],
        child: const MaterialApp(home: ExerciseDetailPage(exerciseId: 'cw001')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dodaj do ulubionych'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('Dodaj do ulubionych')).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.getSize(find.byType(Image)).width, lessThanOrEqualTo(360));
  });
  testWidgets('detail error has appbar, recovery and no raw exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allExercisesProvider.overrideWith(
            (ref) => Stream.error(StateError('private')),
          ),
        ],
        child: const MaterialApp(
          home: ExerciseDetailPage(exerciseId: 'missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);
    expect(find.text('Wróć do bazy ćwiczeń'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
  });
}
