import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/core/services/notification_service.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/home/presentation/pages/main_shell.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/presentation/schedule_page.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../../core/push_settings_test.dart' show FakePush;
import '../auth/offline_auth_test.dart' show SessionApi;
import '../exercises/catalog_filter_test.dart' show exercise;
import '../planner/structured_plan_persistence_test.dart' show structure;

class LocalNotifications extends NotificationService {
  LocalNotifications() : super(FlutterLocalNotificationsPlugin());
  @override
  Future<void> init() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });

  testWidgets(
    'production shell settings → planner → schedule confirm renders actual ActiveSessionPage with one UUID, not an empty shell',
    (tester) async {
      await initializeDateFormatting('pl_PL');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      await sync.bindAccount('account');
      await saveProfile(db);
      await PlannerRepository(db).savePlan(
        nazwa: 'Plan z harmonogramu',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      final planId = (await db.select(db.workoutPlans).getSingle()).syncId;
      final day = CalendarDay.local(DateTime.now()).monday;
      final schedule = ScheduleRepository(db);
      await schedule.addRule(
        'account',
        planSyncId: planId,
        name: 'Plan z harmonogramu',
        weekday: 1,
        effectiveFrom: day,
      );
      // Only fixture profile/plan/rule operations are removed before measuring start.
      await db.delete(db.syncOutbox).go();
      final auth = AuthController(SessionApi());
      await auth.bootstrap();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authStateProvider.overrideWith((ref) => auth),
          syncServiceProvider.overrideWith((ref) => sync),
          pushClientProvider.overrideWithValue(FakePush()),
          notificationServiceProvider.overrideWithValue(LocalNotifications()),
          healthAccountProvider.overrideWithValue(null),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([
              exercise('yoga', name: 'Ćwiczenie harmonogramu'),
            ]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(
              exercises: {
                'yoga': ExerciseCatalogEntry(
                  tracking: 'time',
                  unilateral: false,
                ),
              },
            ),
          ),
        ],
      );
      final router = createRouter(
        readAuthState: () => c.read(authStateProvider),
        readOnboardingComplete: () => true,
        initialLocation: '/settings',
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
      await tester.ensureVisible(find.text('Generator planu treningowego'));
      await tester.tap(find.text('Generator planu treningowego'));
      await tester.pumpAndSettle();
      expect(find.byType(PlannerPage), findsOneWidget);
      await tester.tap(find.byTooltip('Rytm tygodnia'));
      await tester.pumpAndSettle();
      expect(find.byType(SchedulePage), findsOneWidget);
      await tester.ensureVisible(find.text('Rozpocznij plan'));
      await tester.tap(find.text('Rozpocznij plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      // Two presses before rebuilding must open just one dialog and one workflow.
      final startPosition = tester.getCenter(find.text('Rozpocznij plan'));
      await tester.tapAt(startPosition);
      await tester.tapAt(startPosition);
      await tester.pumpAndSettle();
      expect(find.text('Rozpocząć zapisany plan?'), findsOneWidget);
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveSessionPage), findsOneWidget);
      expect(find.text('Aktywny trening'), findsOneWidget);
      expect(find.text('Ćwiczenie harmonogramu'), findsWidgets);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/workout/session',
      );
      expect(tester.element(find.byType(MainShell)), same(shell));
      final session = await db.select(db.workoutSessions).getSingle();
      expect(c.read(activeWorkoutProvider).sessionId, session.id);
      final draft = await db.select(db.workoutDrafts).getSingle();
      expect(draft.sessionSyncId, session.syncId);
      expect(jsonDecode(draft.payloadJson), isNotEmpty);
      final operations = await db.syncDao.pendingOperations();
      expect(operations, hasLength(1));
      expect(operations.single.entityType, SyncEntityType.workoutSession);
      expect(operations.single.entityId, session.syncId);
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(
        (await schedule.load('account')).between(day, day).single.sessionSyncId,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await tester.pumpAndSettle();
    },
  );
}
