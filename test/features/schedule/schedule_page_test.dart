import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/schedule/presentation/schedule_page.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../exercises/catalog_filter_test.dart' show exercise;

void main() {
  testWidgets(
    'start requires preparation, exact saved plan opens existing session path without completing',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      await sync.bindAccount('account');
      await saveProfile(db);
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Mój plan', cwiczeniaIds: ['cw001'], cel: 'mix');
      final plan = (await db.select(db.workoutPlans).getSingle()).syncId;
      final day = CalendarDay.local(DateTime.now()).monday;
      final repo = ScheduleRepository(db);
      await repo.addRule(
        'account',
        planSyncId: plan,
        name: 'Mój plan',
        weekday: 1,
        effectiveFrom: day,
      );
      await db.delete(db.syncOutbox).go();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SchedulePage()),
          GoRoute(
            path: '/workout/session',
            builder: (_, _) => const Scaffold(body: Text('Sesja testowa')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        sync.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            filterPresetsAccountProvider.overrideWith(
              (ref) => Stream.value('account'),
            ),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([exercise('cw001')]),
            ),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => const ExerciseCatalogMetadata(exercises: {}),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Rozpocznij plan'));
      await tester.tap(find.text('Rozpocznij plan'));
      await tester.pumpAndSettle();
      expect(find.text('Przygotuj trening'), findsOneWidget);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await tester.tap(find.text('Rozpocznij plan'));
      await tester.pumpAndSettle();
      expect(find.text('Przygotuj trening'), findsOneWidget);
      await tester.tap(find.text('Rozpocznij trening'));
      await tester.pumpAndSettle();
      expect(find.text('Sesja testowa'), findsOneWidget);
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(
        (await repo.load('account')).between(day, day).single.sessionSyncId,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'schedule explains manual completion and never auto logs on display',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            filterPresetsAccountProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: SchedulePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ręcznie'), findsOneWidget);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.setsLog).get(), isEmpty);
    },
  );
}
