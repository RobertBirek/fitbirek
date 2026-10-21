import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';
import 'package:fitbirek_training/features/progress/measurements/presentation/pages/add_measurement_page.dart';
import 'package:fitbirek_training/features/progress/measurements/presentation/widgets/manual_measurement_actions.dart';
import 'manual_measurement_repository_test.dart' show TestAuthority;

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  Future<void> defer(AppDatabase db) async {
    final op = (await db.syncDao.pendingOperations()).single;
    await db.transaction(
      () => SyncStore(db).apply({
        'entityType': 'measurement',
        'entityId': op.entityId,
        'version': 2,
        'updatedAt': '2026-10-18T12:00:00Z',
        'deletedAt': '2026-10-18T12:00:00Z',
        'payload': <String, dynamic>{...op.payload},
      }),
    );
  }

  for (final scenario in ['retry', 'deleted', 'account', 'deferred']) {
    testWidgets('edit $scenario keeps text; duplicate save blocked', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = TestAuthority();
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'd'));
      final repo = MeasurementsRepository(db);
      await repo.addMeasurement(wagaKg: 72);
      final row = (await repo.getLatest())!;
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AddMeasurementPage(measurementId: row.id),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '76,5');
      if (scenario == 'retry') {
        await db.customStatement(
          "CREATE TRIGGER fail_outbox BEFORE INSERT ON sync_outbox BEGIN SELECT RAISE(ABORT, 'test'); END",
        );
      } else if (scenario == 'deleted') {
        await repo.deleteMeasurement(await repo.capture(row.id));
      } else if (scenario == 'deferred') {
        await defer(db);
      } else {
        authority.generation += 2;
      }
      final before = await db.select(db.syncOutbox).getSingle();
      final save = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .onPressed!;
      save();
      save();
      await tester.pumpAndSettle();
      expect(find.text('76,5'), findsOneWidget);
      expect(await db.select(db.syncOutbox).getSingle(), before);
      if (scenario == 'retry') {
        expect(find.textContaining('Spróbuj ponownie'), findsOneWidget);
        await db.customStatement('DROP TRIGGER fail_outbox');
        await tester.tap(find.text('Zapisz zmiany'));
        await tester.pumpAndSettle();
        expect((await repo.getLatest())!.wagaKg, 76.5);
      } else if (scenario == 'deferred') {
        expect(find.text(MeasurementSyncPending.message), findsOneWidget);
        expect(find.textContaining('otwórz pomiar ponownie'), findsNothing);
      } else {
        expect(find.textContaining('otwórz pomiar ponownie'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      authority.revision.dispose();
    });
  }

  testWidgets('deferred on open and delete directs to sync, not reopen loop', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'd'));
    final repo = MeasurementsRepository(db);
    await repo.addMeasurement(wagaKg: 72);
    final row = (await repo.getLatest())!;
    await defer(db);
    final before = await db.select(db.syncOutbox).getSingle();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: AddMeasurementPage(measurementId: row.id)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(MeasurementSyncPending.message), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(body: ManualMeasurementActions(measurement: row)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Usuń pomiar ręczny'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(MeasurementSyncPending.message), findsOneWidget);
    expect(await db.select(db.syncOutbox).getSingle(), before);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('double confirmation and stale account cannot delete', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final authority = TestAuthority();
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'd'));
    final repo = MeasurementsRepository(db);
    await repo.addMeasurement(wagaKg: 72);
    final row = (await repo.getLatest())!;
    final before = await db.select(db.syncOutbox).getSingle();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        ],
        child: MaterialApp(
          home: Scaffold(body: ManualMeasurementActions(measurement: row)),
        ),
      ),
    );
    final remove = tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.delete_outline),
        )
        .onPressed!;
    remove();
    remove();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    authority.generation += 2;
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(await repo.getLatest(), row);
    expect(await db.select(db.syncOutbox).getSingle(), before);
    expect(find.textContaining('konto się zmieniły'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    authority.revision.dispose();
  });
  testWidgets('real route edits manual row, cancel/delete at 320 and text 2', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'd'));
    final repo = MeasurementsRepository(db);
    await repo.addMeasurement(wagaKg: 72, obwodKlatki: 98, obwodTalii: 80);
    final original = (await repo.getLatest())!;
    await db
        .into(db.healthSamples)
        .insert(
          HealthSamplesCompanion.insert(
            kind: 'weight',
            day: '2026-10-18',
            value: 71,
            source: 'Apple Zdrowie',
            method: 'health_sample',
            importedAt: DateTime.utc(2026, 10, 18),
            measuredAt: Value(original.data),
          ),
        );
    final health = await db.select(db.healthSamples).getSingle();
    final router = createRouter(
      readAuthState: () => const AuthState.signedIn('A'),
      readOnboardingComplete: () => true,
      initialLocation: '/progress',
    );
    addTearDown(() async {
      router.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Edytuj pomiar ręczny'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.byTooltip('Edytuj pomiar ręczny'), findsOneWidget);
    expect(find.byTooltip('Usuń importowaną próbkę'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edytuj pomiar ręczny'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edytuj pomiar ręczny'));
    await tester.pumpAndSettle();
    expect(find.text('Edytuj pomiar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '73,5');
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.scrollUntilVisible(
      find.text('Zapisz zmiany'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Zapisz zmiany'));
    await tester.pumpAndSettle();
    final edited = (await repo.getLatest())!;
    expect(edited.syncId, original.syncId);
    expect(edited.wagaKg, 73.5);
    expect(edited.obwodKlatki, isNull);
    await tester.scrollUntilVisible(
      find.byTooltip('Usuń pomiar ręczny'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.byTooltip('Usuń pomiar ręczny'));
    await tester.pumpAndSettle();
    expect(find.textContaining('73.5 kg'), findsWidgets);
    final before = await db.select(db.syncOutbox).getSingle();
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(await db.select(db.syncOutbox).getSingle(), before);
    expect(await repo.getLatest(), edited);
    await tester.tap(find.byTooltip('Usuń pomiar ręczny'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(await repo.getLatest(), isNull);
    expect((await db.syncDao.pendingOperations()).single.deleted, isTrue);
    expect(await db.select(db.healthSamples).getSingle(), health);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
