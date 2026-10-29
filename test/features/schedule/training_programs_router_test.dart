import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/home/presentation/pages/main_shell.dart';
import 'package:fitbirek_training/features/schedule/data/training_programs_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/presentation/training_programs_page.dart';
import 'package:fitbirek_training/features/schedule/providers/activity_reminder_provider.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../../core/push_settings_test.dart' show FakePush;
import '../auth/offline_auth_test.dart' show SessionApi;
import '../exercises/catalog_filter_test.dart' show exercise;
import '../../core/training_sets_programs_domain_test.dart'
    show planA, planB, planJson;
import 'training_programs_repository_test.dart' show programMetadata;
import 'schedule_router_start_test.dart' show LocalNotifications;

void main() {
  testWidgets(
    'templates → programs → preparation cancel/start uses actual production shell and v2 session, never auto completes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await initializeDateFormatting('pl_PL');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      await sync.bindAccount('account');
      await saveProfile(db);
      for (final id in [planA, planB]) {
        await db
            .into(db.workoutPlans)
            .insert(
              WorkoutPlansCompanion.insert(
                nazwa: 'Szablon ${id == planA ? 'A' : 'B'}',
                cwiczeniaIds: '["cw001"]',
                cel: 'Własny szablon',
                syncId: Value(id),
                structureJson: Value(jsonEncode(planJson())),
              ),
            );
      }
      final repo = TrainingProgramsRepository(db);
      final day = CalendarDay.local(DateTime.now()).monday;
      await repo.create(
        await repo.open('account'),
        name: 'Rytm A/B',
        planSyncIds: [planA, planB],
        weekdays: {1},
        effectiveFrom: day,
        catalog: [exercise('cw001')],
        metadata: programMetadata,
      );
      await db.delete(db.syncOutbox).go();
      final auth = AuthController(SessionApi());
      await auth.bootstrap();
      final c = ProviderContainer(
        overrides: [
          activityReminderSyncProvider.overrideWith((ref) => Stream.value('')),
          appDatabaseProvider.overrideWithValue(db),
          authStateProvider.overrideWith((ref) => auth),
          syncServiceProvider.overrideWith((ref) => sync),
          pushClientProvider.overrideWithValue(FakePush()),
          notificationServiceProvider.overrideWithValue(LocalNotifications()),
          healthAccountProvider.overrideWithValue(null),
          allExercisesProvider.overrideWith(
            (ref) =>
                Stream.value([exercise('cw001', name: 'Ćwiczenie programu')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => programMetadata,
          ),
        ],
      );
      final router = createRouter(
        readAuthState: () => c.read(authStateProvider),
        readOnboardingComplete: () => true,
        initialLocation: '/workout/templates',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final shell = tester.element(find.byType(MainShell));
      await tester.ensureVisible(find.text('Programy A/B'));
      await tester.tap(find.text('Programy A/B'));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingProgramsPage), findsOneWidget);
      await tester.ensureVisible(find.text('Rozpocznij plan'));
      await tester.tap(find.text('Rozpocznij plan'));
      await tester.pumpAndSettle();
      expect(find.text('Przygotuj trening'), findsOneWidget);
      await tester.tap(find.byTooltip('Zamknij przygotowanie'));
      await tester.pumpAndSettle();
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      final position = tester.getCenter(find.text('Rozpocznij plan'));
      await tester.tapAt(position);
      await tester.tapAt(position);
      await tester.pumpAndSettle();
      expect(find.text('Przygotuj trening'), findsOneWidget);
      await tester.ensureVisible(find.text('Rozpocznij trening'));
      await tester.tap(find.text('Rozpocznij trening'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveSessionPage), findsOneWidget);
      expect(find.text('Aktywny trening'), findsOneWidget);
      expect(tester.element(find.byType(MainShell)), same(shell));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/workout/session',
      );
      expect(c.read(activeWorkoutProvider).currentTarget!.targetId, 'a');
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.workoutDrafts).get(), hasLength(1));
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(
        TrainingProgramSchedule(
          await repo.load('account'),
        ).between(day, day).single.sessionSyncId,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
