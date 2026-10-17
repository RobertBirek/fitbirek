import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'plan_explanation_fixtures.dart';

void main() {
  for (final accept in [false, true]) {
    testWidgets(
      'replacement requires explicit ${accept ? "accept" : "cancel"}; no writes',
      (tester) async {
        final plan = explanationPlan();
        final before = plan.toJson();
        final c = ProviderContainer(
          overrides: [
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([
                explanationExercise('a'),
                explanationExercise('b').copyWith(sprzet: ['Krzesło']),
              ]),
            ),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => explanationMetadata,
            ),
            userProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                UserProfile(
                  imie: 'Test',
                  wiek: 30,
                  wzrostCm: 180,
                  wagaKg: 80,
                  cel: CelTreningowy.mix,
                  dostepnySprzet: ['Mata', 'Krzesło'],
                  dataUtworzenia: DateTime(2026),
                ),
              ),
            ),
            savedPlansProvider.overrideWith(
              (ref) => Stream.value([
                SavedPlan(
                  id: 1,
                  nazwa: 'Podgląd',
                  cwiczeniaIds: plan.exerciseIds,
                  cel: 'mix',
                  dataUtworzenia: DateTime(2026),
                  structure: plan,
                ),
              ]),
            ),
          ],
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: PlannerPage()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Podgląd'));
        await tester.tap(find.text('Podgląd'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Dlaczego to ćwiczenie?'));
        await tester.tap(find.byTooltip('Dlaczego to ćwiczenie?'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Mięśnie główne: Plecy'), findsOneWidget);
        await tester.tap(find.text('Zamknij'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Wymień ćwiczenie'));
        await tester.pumpAndSettle();
        expect(find.text('Zamień Ruch a na Ruch b?'), findsOneWidget);
        expect(
          find.textContaining('Ten sam czas ESTYMOWANY: 195 s'),
          findsOneWidget,
        );
        expect(find.textContaining('Sprzęt: Mata → Krzesło'), findsOneWidget);
        expect(find.text('Ruch a'), findsOneWidget);
        expect(find.text('Ruch b'), findsNothing);
        await tester.tap(find.text(accept ? 'Zamień' : 'Anuluj'));
        await tester.pumpAndSettle();
        expect(find.text(accept ? 'Ruch b' : 'Ruch a'), findsOneWidget);
        expect(find.text(accept ? 'Ruch a' : 'Ruch b'), findsNothing);
        expect(plan.toJson(), before);
        expect(c.exists(plannerWorkflowProvider), isFalse);
        expect(c.exists(plannerRepositoryProvider), isFalse);
        expect(c.exists(authStateProvider), isFalse);
      },
    );
  }

  testWidgets('catalog changes during confirmation leave preview unchanged', (
    tester,
  ) async {
    final stream = StreamController<List<Exercise>>();
    final plan = explanationPlan();
    final c = ProviderContainer(
      overrides: [
        allExercisesProvider.overrideWith((ref) => stream.stream),
        exerciseCatalogMetadataProvider.overrideWith(
          (ref) async => explanationMetadata,
        ),
        userProfileStreamProvider.overrideWith(
          (ref) => Stream.value(
            UserProfile(
              imie: 'Test',
              wiek: 30,
              wzrostCm: 180,
              wagaKg: 80,
              cel: CelTreningowy.mix,
              dostepnySprzet: ['Mata'],
              dataUtworzenia: DateTime(2026),
            ),
          ),
        ),
        savedPlansProvider.overrideWith(
          (ref) => Stream.value([
            SavedPlan(
              id: 1,
              nazwa: 'Podgląd',
              cwiczeniaIds: plan.exerciseIds,
              cel: 'mix',
              dataUtworzenia: DateTime(2026),
              structure: plan,
            ),
          ]),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await stream.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: PlannerPage()),
      ),
    );
    stream.add([explanationExercise('a'), explanationExercise('b')]);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Podgląd'));
    await tester.tap(find.text('Podgląd'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Wymień ćwiczenie'));
    await tester.tap(find.byTooltip('Wymień ćwiczenie'));
    await tester.pumpAndSettle();
    stream.add([explanationExercise('a')]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zamień'));
    await tester.pumpAndSettle();
    expect(find.text('Ruch a'), findsOneWidget);
    expect(find.text('Ruch b'), findsNothing);
    expect(find.textContaining('Dane zmieniły się'), findsOneWidget);
  });
}
