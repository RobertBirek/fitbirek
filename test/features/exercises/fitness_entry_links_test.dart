import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercises_list_page.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercise_variants_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/widgets/start_workout_button.dart';
import '../progress/fitness_ui_support.dart';
import 'catalog_filter_test.dart' show exercise;

void main() {
  for (final detail in [false, true]) {
    testWidgets(
      '${detail ? 'detail secondary button' : 'row menu'} opens selection without starting a workout',
      (tester) async {
        final fixture = await fitnessUiFixture();
        addTearDown(fixture.db.close);
        final router = GoRouter(
          initialLocation: '/exercises',
          routes: [
            GoRoute(
              path: '/exercises',
              builder: (_, __) => detail
                  ? const ExerciseDetailPage(exerciseId: 'cw001')
                  : const ExercisesListPage(),
            ),
            GoRoute(
              path: '/progress/run-test',
              builder: (_, state) => Scaffold(
                body: Text(
                  'Wybrane: ${state.uri.queryParameters['exerciseId']}',
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(fixture.db),
              allExercisesProvider.overrideWith(
                (ref) => Stream.value([exercise('cw001', name: 'Pompki')]),
              ),
              exerciseCatalogMetadataProvider.overrideWith(
                (ref) async => const ExerciseCatalogMetadata(),
              ),
              exerciseVariantsProvider.overrideWith(
                (ref, id) => Stream.value([]),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Dodaj do ulubionych'), findsOneWidget);
        if (detail) {
          await tester.scrollUntilVisible(
            find.byType(StartWorkoutButton),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.byType(StartWorkoutButton), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Test sprawnościowy'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
        } else {
          await tester.tap(find.byTooltip('Więcej opcji ćwiczenia'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Test sprawnościowy'));
        await tester.pumpAndSettle();
        expect(find.text('Wybrane: cw001'), findsOneWidget);
        expect(
          await fixture.db.select(fixture.db.workoutSessions).get(),
          isEmpty,
        );
        expect(await fixture.db.select(fixture.db.setsLog).get(), isEmpty);
        expect(
          await fixture.db.select(fixture.db.personalRecords).get(),
          isEmpty,
        );
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byTooltip('Dodaj do ulubionych'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
