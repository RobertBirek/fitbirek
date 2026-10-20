import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/providers/activity_reminder_provider.dart';
import 'package:fitbirek_training/features/schedule/presentation/activity_list_page.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../../core/push_settings_test.dart' show FakePush;
import '../auth/offline_auth_test.dart' show SessionApi;
import 'schedule_router_start_test.dart' show LocalNotifications;
import 'schedule_repository_test.dart' show TestAuthority;

class SwitchingAuth extends AuthController {
  SwitchingAuth() : super(SessionApi());
  final authority = TestAuthority();
  void switchTo(String account) {
    authority.generation++;
    authority.revision.value++;
    state = AuthState.signedIn(account);
  }
}

void main() {
  for (final narrow in [false, true]) {
    testWidgets(
      'real settings router CRUD, multi-day 6/18 and swimming; no sessions; narrow=$narrow',
      (tester) async {
        Future<void> visible(Finder finder) async {
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
          await tester.pumpAndSettle();
        }

        if (narrow) {
          tester.view.physicalSize = const Size(320, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final sync = SyncService(db, CollectionServer());
        await sync.bindAccount('account');
        await saveProfile(db);
        final auth = SwitchingAuth();
        await auth.bootstrap();
        final c = ProviderContainer(
          overrides: [
            // CRUD/router fixture has no installation reminder migration.
            activityReminderSyncProvider.overrideWith(
              (ref) => Stream.value(''),
            ),
            cachedAuthWriteAuthorityProvider.overrideWithValue(auth.authority),
            appDatabaseProvider.overrideWithValue(db),
            authStateProvider.overrideWith((ref) => auth),
            syncServiceProvider.overrideWith((ref) => sync),
            pushClientProvider.overrideWithValue(FakePush()),
            notificationServiceProvider.overrideWithValue(LocalNotifications()),
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
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Harmonogram aktywności'),
          180,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Harmonogram aktywności')),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Harmonogram aktywności'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dodaj aktywność zewnętrzną'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nazwa'),
          'Basen',
        );
        await visible(find.text('Nd'));
        await tester.tap(find.text('Nd'));
        await visible(find.widgetWithText(TextFormField, 'Godzina HH:mm'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Godzina HH:mm'),
          '12:30',
        );
        await visible(find.text('Zapisz'));
        final savePosition = tester.getCenter(find.text('Zapisz'));
        await tester.tapAt(savePosition);
        await tester.tapAt(savePosition);
        await tester.pumpAndSettle();
        final rules = (await ActivityRepository(db).snapshot('account')).rules;
        expect(rules.single.name, 'Basen');
        expect(rules.single.weekdays, {7});
        expect(rules.single.time, '12:30');
        expect(rules.single.reminderEnabled, false);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        await visible(find.widgetWithText(TextButton, 'Edytuj').first);
        await tester.tap(find.widgetWithText(TextButton, 'Edytuj').first);
        await tester.pumpAndSettle();
        await visible(
          find.widgetWithText(TextFormField, 'Czas trwania (min, opcjonalnie)'),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Czas trwania (min, opcjonalnie)'),
          '45',
        );
        await visible(find.text('Zapisz'));
        await tester.tap(find.text('Zapisz'));
        await tester.pumpAndSettle();
        final edited = (await ActivityRepository(
          db,
        ).snapshot('account')).rules.single;
        expect(edited.durationMinutes, 45);
        expect(edited.id, isNot(rules.single.id));
        await visible(find.widgetWithText(TextButton, 'Wyłącz'));
        await tester.tap(find.widgetWithText(TextButton, 'Wyłącz'));
        await tester.pumpAndSettle();
        expect(
          (await ActivityRepository(
            db,
          ).snapshot('account')).rules.single.enabled,
          false,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Włącz'));
        await tester.pumpAndSettle();
        expect(
          (await ActivityRepository(
            db,
          ).snapshot('account')).rules.single.enabled,
          true,
        );
        await visible(find.text('Dodaj aktywność zewnętrzną'));
        await tester.tap(find.text('Dodaj aktywność zewnętrzną'));
        await tester.pumpAndSettle();
        await visible(find.text('Anuluj'));
        await visible(find.text('Anuluj'));
        await tester.tap(find.text('Anuluj'));
        await tester.pumpAndSettle();
        expect(
          (await ActivityRepository(db).snapshot('account')).rules,
          hasLength(1),
        );
        for (final hour in ['06:00', '18:00']) {
          await visible(find.text('Dodaj trening FitBirek'));
          await tester.tap(find.text('Dodaj trening FitBirek'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Nazwa'),
            'Trening $hour',
          );
          await visible(find.text('Pn'));
          await tester.tap(find.text('Pn'));
          await tester.tap(find.text('Wt'));
          await visible(find.widgetWithText(TextFormField, 'Godzina HH:mm'));
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Godzina HH:mm'),
            hour,
          );
          await visible(find.text('Zapisz'));
          await tester.tap(find.text('Zapisz'));
          await tester.pumpAndSettle();
        }
        final repo = ActivityRepository(db);
        final created = await repo.snapshot('account');
        expect(
          created.rules.where((r) => r.weekdays.contains(1)).map((r) => r.time),
          containsAll(['06:00', '18:00']),
        );
        expect(
          created.rules.where((r) => r.weekdays.contains(2)),
          hasLength(2),
        );
        expect(
          created.rules.every(
            (r) => r.planSyncId == null && !r.reminderEnabled,
          ),
          true,
        );
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        expect(await db.select(db.personalRecords).get(), isEmpty);

        // A parallel writer changes the original rule while this editor is open.
        final edit = find.widgetWithText(TextButton, 'Edytuj').first;
        await visible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nazwa'),
          'Basen prywatna edycja',
        );
        await repo.setEnabled(
          created,
          created.rules.firstWhere((r) => r.name == 'Basen').id,
          false,
        );
        await visible(find.text('Zapisz'));
        await tester.tap(find.text('Zapisz'));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityListPage), findsNothing);
        expect(
          (tester.widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Nazwa'),
          )).controller!.text,
          'Basen prywatna edycja',
        );
        expect(
          (await repo.snapshot(
            'account',
          )).rules.any((r) => r.name == 'Basen prywatna edycja'),
          false,
        );
        await visible(find.text('Anuluj'));
        await tester.tap(find.text('Anuluj'));
        await tester.pumpAndSettle();
        final remove = find.widgetWithText(TextButton, 'Usuń').first;
        await visible(remove);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Anuluj'));
        await tester.pumpAndSettle();
        expect((await repo.snapshot('account')).rules, hasLength(3));
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
        await tester.pumpAndSettle();
        expect((await repo.snapshot('account')).rules, hasLength(2));
        await visible(find.text('Dodaj aktywność zewnętrzną'));
        await tester.tap(find.text('Dodaj aktywność zewnętrzną'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nazwa'),
          'Prywatny sekret',
        );
        final beforeSwitch = await db.select(db.syncOutbox).get();
        auth.switchTo('other');
        auth.switchTo('account');
        await tester.pumpAndSettle();
        expect(find.text('Prywatny sekret'), findsNothing);
        expect(find.textContaining('Formularz wyczyszczono'), findsOneWidget);
        expect(find.text('Zapisz'), findsNothing);
        expect(await db.select(db.syncOutbox).get(), beforeSwitch);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
        await tester.pumpAndSettle();
      },
    );
  }
}
