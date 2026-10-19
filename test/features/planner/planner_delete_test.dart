import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';

class PausedDelete extends PlannerRepository {
  PausedDelete(super.db);
  int calls = 0;
  Completer<void> result = Completer();
  @override
  Future<void> deletePlan(int id) async {
    calls++;
    await result.future;
    await super.deletePlan(id);
  }
}

void main() {
  testWidgets(
    'delete awaits completion, blocks duplicates, handles failure and retry',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = PausedDelete(db);
      final id = await repo.savePlan(
        nazwa: 'Joga',
        cwiczeniaIds: [],
        cel: 'mix',
      );
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          plannerRepositoryProvider.overrideWithValue(repo),
          userProfileStreamProvider.overrideWith((ref) => Stream.value(null)),
          allExercisesProvider.overrideWith((ref) => Stream.value([])),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(),
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
      final delete = find.widgetWithIcon(IconButton, Icons.delete_outline);
      await tester.ensureVisible(delete);
      final callback = tester.widget<IconButton>(delete).onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(tester.widget<IconButton>(delete).onPressed, isNull);
      callback();
      expect(repo.calls, 1);
      expect(find.text('Plan usunięty.'), findsNothing);
      repo.result.completeError(StateError('delete failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nie udało się usunąć planu. Spróbuj ponownie.'),
        findsOneWidget,
      );
      expect((await db.plansDao.getPlan(id))!.deletedAtUtc, isNull);
      expect(tester.takeException(), isNull);
      repo.result = Completer();
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('planner-message'), skipOffstage: false),
        findsNothing,
      );
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('planner-message')), findsNothing);
      repo.result.complete();
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.text('Plan usunięty.'), findsOneWidget);
      expect((await db.plansDao.getPlan(id))!.deletedAtUtc, isNotNull);
      await repo.savePlan(nazwa: 'Drugi plan', cwiczeniaIds: [], cel: 'mix');
      await tester.pumpAndSettle();
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('planner-message'), skipOffstage: false),
        findsNothing,
      );
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(delete).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
