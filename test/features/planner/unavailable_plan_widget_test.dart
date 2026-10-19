import 'package:drift/drift.dart' show Value;
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
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'structured_plan_persistence_test.dart' show structure;

void main() {
  testWidgets(
    'unavailable plan is explicit, cannot preview/start/replace, but can delete',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = PlannerRepository(db);
      await repo.savePlan(
        nazwa: 'good',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      await repo.savePlan(nazwa: 'legacy', cwiczeniaIds: ['old'], cel: 'mix');
      final bad = await repo.savePlan(
        nazwa: 'damaged',
        cwiczeniaIds: ['bad'],
        cel: 'mix',
      );
      await (db.update(db.workoutPlans)..where((p) => p.id.equals(bad))).write(
        const WorkoutPlansCompanion(structureJson: Value('{}')),
      );
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
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
      expect(find.text('good'), findsOneWidget);
      expect(find.text('legacy'), findsOneWidget);
      expect(find.text('damaged'), findsOneWidget);
      expect(find.textContaining('Plan niedostępny'), findsOneWidget);
      expect(find.textContaining('Stary plan —'), findsOneWidget);
      final tile = find.ancestor(
        of: find.text('damaged'),
        matching: find.byType(ListTile),
      );
      expect(tester.widget<ListTile>(tile).onTap, isNull);
      expect(find.text('Rozpocznij trening'), findsNothing);
      expect(find.byTooltip('Wymień ćwiczenie'), findsNothing);
      final delete = find.descendant(
        of: tile,
        matching: find.byTooltip('Usuń plan'),
      );
      await tester.ensureVisible(delete);
      final planBefore = await db.plansDao.getPlan(bad);
      final outboxBefore = await db.select(db.syncOutbox).get();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.text('Usunąć plan „damaged”?'), findsOneWidget);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(await db.plansDao.getPlan(bad), planBefore);
      expect(
        await db.select(db.syncOutbox).get(),
        unorderedEquals(outboxBefore),
      );
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      expect(find.text('Plan usunięty.'), findsOneWidget);
      expect((await db.plansDao.getPlan(bad))!.deletedAtUtc, isNotNull);
      final deleted = (await db.syncDao.pendingOperations()).where(
        (op) => op.entityId == planBefore!.syncId,
      );
      expect(deleted.single.deleted, isTrue);
      expect(find.text('damaged'), findsNothing);
      expect(find.text('good'), findsOneWidget);
      expect(
        (await db.select(db.workoutPlans).get())
            .singleWhere((p) => p.id == bad)
            .structureJson,
        '{}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
