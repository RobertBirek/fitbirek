import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_page.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/presentation/widgets/today_schedule.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../../core/push_settings_test.dart' show FakePush;
import '../auth/offline_auth_test.dart' show SessionApi;
import '../mentor/mentor_flow_test.dart' as mentor;
import 'schedule_router_start_test.dart' show LocalNotifications;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  for (final path in ['/today', '/today/classic']) {
    testWidgets(
      'actual Today $path orders rules; external confirmation logs nothing; stale start is refused; free start is explicit',
      (tester) async {
        await initializeDateFormatting('pl_PL');
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final sync = SyncService(db, CollectionServer());
        await sync.bindAccount('account');
        await saveProfile(db);
        final repo = ActivityRepository(db);
        final day = CalendarDay.local(DateTime.now());
        Future<String> create(
          String name,
          String time,
          ActivityType type,
        ) async => repo.create(
          await repo.snapshot('account'),
          ActivityDraft(
            name: name,
            activityType: type,
            weekdays: {DateTime.now().weekday},
            time: time,
            effectiveFrom: day,
          ),
        );
        await create('Wieczorny', '18:00', ActivityType.fitbirek);
        await create('Basen', '12:30', ActivityType.external);
        final morning = await create('Poranny', '06:00', ActivityType.fitbirek);
        final auth = AuthController(SessionApi());
        await auth.bootstrap();
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authStateProvider.overrideWith((ref) => auth),
            syncServiceProvider.overrideWith((ref) => sync),
            notificationServiceProvider.overrideWithValue(LocalNotifications()),
            pushClientProvider.overrideWithValue(FakePush()),
            healthAccountProvider.overrideWithValue(null),
            allExercisesProvider.overrideWith((ref) => Stream.value([])),
            mentorSettingsProvider.overrideWith(
              (ref) async => mentor.mentorSettings(enabled: false),
            ),
            mentorVoiceProvider.overrideWithValue(mentor.VoiceFake()),
          ],
        );
        final router = createRouter(
          readAuthState: () => c.read(authStateProvider),
          readOnboardingComplete: () => true,
          initialLocation: path,
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
        if (path.endsWith('classic')) {
          await tester.scrollUntilVisible(find.byType(TodaySchedule), 180);
          await tester.pumpAndSettle();
        }
        expect(find.byType(TodaySchedule), findsOneWidget);
        final cards = tester
            .widgetList<ScheduleOccurrenceCard>(
              find.byType(ScheduleOccurrenceCard),
            )
            .toList();
        expect(cards.map((c) => c.occurrence.name), [
          'Poranny',
          'Basen',
          'Wieczorny',
        ]);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        Future<void> click(String text) async {
          await tester.ensureVisible(find.text(text).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(text).first);
          await tester.pumpAndSettle();
        }

        await click('Potwierdź wykonanie');
        await tester.tap(find.text('Anuluj'));
        await tester.pumpAndSettle();
        expect(
          (await repo.snapshot(
            'account',
          )).schedule.entries.where((e) => e['kind'] == 'activityOverride'),
          isEmpty,
        );
        final scheduleRepo = ScheduleRepository(db);
        Future<ScheduleOccurrence> named(String name) async =>
            (await scheduleRepo.load(
              'account',
            )).between(day, day.plus(6)).firstWhere((o) => o.name == name);
        // Keep the occurrence visible by moving away and back while the date
        // picker is open. Equal displayed values do not renew its baseline.
        await click('Przesuń termin');
        await scheduleRepo.move('account', await named('Poranny'), day.plus(1));
        await scheduleRepo.move('account', await named('Poranny'), day);
        final beforePicker = (await db.select(db.syncOutbox).get())
            .map((e) => e.toJson())
            .toList();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(
          (await db.select(db.syncOutbox).get())
              .map((e) => e.toJson())
              .toList(),
          beforePicker,
        );
        await click('Przesuń termin');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(
          (await db.select(db.syncOutbox).get())
              .map((e) => e.toJson())
              .toList(),
          isNot(beforePicker),
        );
        await click('Potwierdź wykonanie');
        await scheduleRepo.move('account', await named('Basen'), day.plus(1));
        await scheduleRepo.move('account', await named('Basen'), day);
        final beforeConfirm = (await db.select(db.syncOutbox).get())
            .map((e) => e.toJson())
            .toList();
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(
          (await db.select(db.syncOutbox).get())
              .map((e) => e.toJson())
              .toList(),
          beforeConfirm,
        );
        expect((await named('Basen')).isCompleted, false);
        await click('Potwierdź wykonanie');
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(find.text('Zaliczone ręcznie'), findsOneWidget);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        expect(await db.select(db.personalRecords).get(), isEmpty);
        await click('Rozpocznij swobodny');
        // Remote tombstone while the confirmation is open must invalidate the
        // chosen snapshot, not silently start the next occurrence in the list.
        await repo.delete(await repo.snapshot('account'), morning);
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        await click('Rozpocznij swobodny');
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ActiveSessionPage), findsOneWidget);
        expect(await db.select(db.workoutSessions).get(), hasLength(1));
        expect(await db.select(db.setsLog).get(), isEmpty);
        expect(
          (await repo.snapshot('account')).schedule.entries.where(
            (e) =>
                e['kind'] == 'activityOverride' && e['sessionSyncId'] != null,
          ),
          isEmpty,
        );
        router.go('/schedule');
        await tester.pumpAndSettle();
        await click('Rozpocznij swobodny');
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(await db.select(db.workoutSessions).get(), hasLength(1));
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/schedule',
        );

        await create('Drugi', '19:00', ActivityType.fitbirek);
        final actualId = await db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                dataStart: DateTime.now(),
                dataKoniec: Value(DateTime.now()),
                notatka: const Value('Rzeczywista sesja'),
              ),
            );
        await db
            .into(db.setsLog)
            .insert(
              SetsLogCompanion.insert(
                sesjaId: actualId,
                cwiczenieId: 'cw001',
                nazwaCwiczeniaPl: 'Ćwiczenie',
                numerSerii: 1,
              ),
            );
        await tester.pumpAndSettle();
        await click('Zalicz z sesji');
        await tester.tap(find.textContaining('Rzeczywista sesja'));
        await tester.pumpAndSettle();
        await scheduleRepo.move('account', await named('Poranny'), day.plus(1));
        await scheduleRepo.move('account', await named('Poranny'), day);
        final beforeFitConfirm = (await db.select(db.syncOutbox).get())
            .map((e) => e.toJson())
            .toList();
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(
          (await db.select(db.syncOutbox).get())
              .map((e) => e.toJson())
              .toList(),
          beforeFitConfirm,
        );
        expect((await named('Poranny')).isCompleted, false);
        await click('Zalicz z sesji');
        await tester.tap(find.textContaining('Rzeczywista sesja'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(find.text('Zaliczone — powiązana sesja'), findsOneWidget);
        await click('Zalicz z sesji');
        await tester.tap(find.textContaining('Rzeczywista sesja'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Potwierdź'));
        await tester.pumpAndSettle();
        expect(
          (await repo.snapshot(
            'account',
          )).schedule.entries.where((e) => e['sessionSyncId'] != null),
          hasLength(1),
        );
        expect(await db.select(db.workoutSessions).get(), hasLength(2));
        expect(await db.select(db.setsLog).get(), hasLength(1));

        final planner = PlannerRepository(db);
        await planner.savePlan(
          nazwa: 'Znikający plan',
          cwiczeniaIds: ['cw001'],
          cel: 'mix',
        );
        final plan = (await db.select(db.workoutPlans).getSingle()).syncId;
        await repo.create(
          await repo.snapshot('account'),
          ActivityDraft(
            name: 'Brakujący szablon',
            activityType: ActivityType.fitbirek,
            weekdays: {DateTime.now().weekday},
            time: '20:00',
            effectiveFrom: day,
            planSyncId: plan,
          ),
        );
        await planner.deleteTemplate((await planner.snapshot(plan))!);
        await tester.pumpAndSettle();
        final missing = find.text('Brakujący szablon');
        await tester.ensureVisible(missing);
        await tester.pumpAndSettle();
        final card = find.ancestor(of: missing, matching: find.byType(Card));
        expect(
          find.descendant(
            of: card,
            matching: find.textContaining('Plan niedostępny'),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextButton>(
                find.descendant(
                  of: card,
                  matching: find.byWidgetPredicate(
                    (w) => w is TextButton && w.onPressed == null,
                  ),
                ),
              )
              .onPressed,
          isNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
