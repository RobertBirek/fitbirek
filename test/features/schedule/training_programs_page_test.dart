import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/schedule/data/training_programs_repository.dart';
import 'package:fitbirek_training/features/schedule/presentation/training_programs_page.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show CollectionServer, saveProfile;
import '../../core/training_sets_programs_domain_test.dart'
    show planA, planB, planJson;
import '../exercises/catalog_filter_test.dart' show exercise;
import 'training_programs_repository_test.dart' show programMetadata;
import 'schedule_repository_test.dart' show TestAuthority;

void main() {
  late AppDatabase db;
  late SyncService sync;
  late TrainingProgramsRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = SyncService(db, CollectionServer());
    await sync.bindAccount('account');
    await saveProfile(db);
    for (final id in [planA, planB]) {
      await db
          .into(db.workoutPlans)
          .insert(
            WorkoutPlansCompanion.insert(
              nazwa: id == planA ? 'Góra ciała' : 'Dół ciała',
              cwiczeniaIds: '["cw001"]',
              cel: 'Własny szablon',
              syncId: Value(id),
              structureJson: Value(jsonEncode(planJson())),
            ),
          );
    }
    repo = TrainingProgramsRepository(db);
    await db.delete(db.syncOutbox).go();
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });
  Future<void> mount(
    WidgetTester tester, {
    double scale = 1,
    TestAuthority? authority,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          if (authority != null)
            cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          filterPresetsAccountProvider.overrideWith(
            (ref) => Stream.value('account'),
          ),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('cw001')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => programMetadata,
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const TrainingProgramsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'create cancel is read-only, explicit create selects A/B/days/date and rename/end keep overdue',
    (tester) async {
      await mount(tester);
      expect(find.textContaining('Start'), findsWidgets);
      await tap(tester, find.text('Nowy program A/B'));
      await tap(tester, find.text('Anuluj'));
      expect((await repo.load('account')).entries, isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await tap(tester, find.text('Nowy program A/B'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa programu'),
        'Mój rytm',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Data początku (RRRR-MM-DD)'),
        CalendarDay.local(DateTime.now()).monday.plus(-7).value,
      );
      await tap(tester, find.text('Zapisz program'));
      expect((await repo.load('account')).entries.single['planSyncIds'], [
        planA,
        planB,
      ]);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(find.text('Plan A • Góra ciała'), findsWidgets);
      await tap(tester, find.text('Zmień nazwę'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa programu'),
        'Nowy rytm',
      );
      await tap(tester, find.text('Zapisz nazwę'));
      expect((await repo.load('account')).entries.single['name'], 'Nowy rytm');
      await tap(tester, find.text('Zakończ program'));
      await tap(tester, find.text('Potwierdź zakończenie'));
      final entries = (await repo.load('account')).entries;
      expect(
        entries.single['endBeforeDate'],
        CalendarDay.local(DateTime.now()).value,
      );
      final previous = CalendarDay.local(DateTime.now()).monday.plus(-7);
      expect(
        TrainingProgramSchedule(
          await repo.load('account'),
        ).between(previous, previous.plus(6)),
        hasLength(3),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    '320px and 200 percent text, keyboard form and cancel without overflow or writes',
    (tester) async {
      await repo.create(
        await repo.open('account'),
        name: 'Wąski kalendarz',
        planSyncIds: [planA, planB],
        weekdays: {1},
        effectiveFrom: CalendarDay.local(DateTime.now()).monday,
        catalog: [exercise('cw001')],
        metadata: programMetadata,
      );
      await db.delete(db.syncOutbox).go();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, scale: 2);
      await tap(tester, find.text('Nowy program A/B'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa programu'),
        'Klawiatura',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('Anuluj'));
      await tester.scrollUntilVisible(
        find.text('Rozpocznij plan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'account A-B-A while create dialog is open cannot save into recaptured account',
    (tester) async {
      final authority = TestAuthority();
      await mount(tester, authority: authority);
      await tap(tester, find.text('Nowy program A/B'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa programu'),
        'Stary formularz',
      );
      authority.generation += 2;
      await tap(tester, find.text('Zapisz program'));
      expect((await repo.load('account')).entries, isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'move keeps A identity; only explicit selected working session completes, cancel does not',
    (tester) async {
      final start = CalendarDay.local(DateTime.now()).monday;
      await repo.create(
        await repo.open('account'),
        name: 'Ręczne wykonanie',
        planSyncIds: [planA, planB],
        weekdays: {1},
        effectiveFrom: start,
        catalog: [exercise('cw001')],
        metadata: programMetadata,
      );
      for (final role in ['warmup', 'working']) {
        final id = await db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                dataStart: DateTime.now(),
                dataKoniec: Value(DateTime.now()),
                notatka: Value('Sesja $role'),
              ),
            );
        await db
            .into(db.setsLog)
            .insert(
              SetsLogCompanion.insert(
                sesjaId: id,
                cwiczenieId: 'cw001',
                nazwaCwiczeniaPl: 'Ćwiczenie',
                numerSerii: 1,
                setRole: Value(role),
              ),
            );
      }
      await mount(tester);
      final before = TrainingProgramSchedule(
        await repo.load('account'),
      ).between(start, start).single;
      await tap(tester, find.text('Przesuń termin'));
      await tap(tester, find.text('OK'));
      final moved = TrainingProgramSchedule(
        await repo.load('account'),
      ).between(start, start).single;
      expect(moved.id, before.id);
      expect(moved.planSyncId, planA);
      await tap(tester, find.text('Zalicz z sesji'));
      expect(find.textContaining('Sesja warmup'), findsNothing);
      await tap(tester, find.textContaining('Sesja working'));
      await tap(tester, find.text('Anuluj'));
      expect(
        TrainingProgramSchedule(
          await repo.load('account'),
        ).between(start, start).single.sessionSyncId,
        isNull,
      );
      await tap(tester, find.text('Zalicz z sesji'));
      await tap(tester, find.textContaining('Sesja working'));
      await tap(tester, find.text('Zalicz termin'));
      expect(find.textContaining('Zaliczone —'), findsOneWidget);
      expect(await db.select(db.workoutSessions).get(), hasLength(2));
      expect(await db.select(db.setsLog).get(), hasLength(2));
      expect(await db.select(db.personalRecords).get(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
