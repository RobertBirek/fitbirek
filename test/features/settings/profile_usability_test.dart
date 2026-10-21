import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:go_router/go_router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/onboarding/presentation/pages/onboarding_profile_page.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/edit_profile_page.dart';
import 'package:fitbirek_training/features/calculator/presentation/pages/calculator_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/run_test_page.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import '../progress/fitness_ui_support.dart';

final profile = UserProfile(
  imie: 'Test',
  wiek: 47,
  wzrostCm: 180.5,
  wagaKg: 94.5,
  cel: CelTreningowy.mix,
  dostepnySprzet: const [],
  dataUtworzenia: DateTime.utc(2026),
);

void main() {
  testWidgets('onboarding rejects fractional/nonfinite age and parses comma', (
    tester,
  ) async {
    var advanced = 0;
    double? weight;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingProfilePage(
          initialWiek: 47,
          initialWzrost: 180.5,
          initialWaga: 94.5,
          initialCel: CelTreningowy.mix,
          onBack: () {},
          onNext: () => advanced++,
          onDataChanged: (_, __, w, ___) => weight = w,
        ),
      ),
    );
    for (final age in ['47.5', '47,5', 'NaN', 'Infinity', '1e2']) {
      await tester.enterText(find.byType(TextFormField).first, age);
      await tester.ensureVisible(find.text('Dalej'));
      await tester.tap(find.text('Dalej'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(advanced, 0);
    }
    await tester.enterText(find.byType(TextFormField).first, ' 47 ');
    await tester.enterText(find.byType(TextFormField).at(2), ' 94,5 ');
    await tester.ensureVisible(find.text('Dalej'));
    await tester.tap(find.text('Dalej'));
    await tester.pump();
    expect(advanced, 1);
    expect(weight, 94.5);
  });

  testWidgets('edit preserves fractional fields', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            accountId: 'A',
            deviceId: 'device',
            offlineAccess: const Value(true),
          ),
        );
    await UserProfileRepository(db).saveProfile(
      imie: profile.imie,
      wiek: profile.wiek,
      wzrostCm: profile.wzrostCm,
      wagaKg: profile.wagaKg,
      cel: profile.cel,
      dostepnySprzet: profile.dostepnySprzet,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[1].controller!.text, '180.5');
    expect(fields[2].controller!.text, '94.5');
    await tester.tap(find.byType(DropdownButtonFormField<CelTreningowy>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siła').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect((await db.userProfileDao.watchProfileOnce())!.wagaKg, 94.5);
    expect((await db.userProfileDao.watchProfileOnce())!.wzrostCm, 180.5);
    expect((await db.userProfileDao.watchProfileOnce())!.cel, 'sila');
  });

  for (final width in [320.0, 375.0, 768.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('calculator $width dark=$dark text200 has no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileStreamProvider.overrideWith(
                (ref) => Stream.value(profile),
              ),
            ],
            child: MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: const CalculatorPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(ListView)).width,
          lessThanOrEqualTo(640),
        );
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel('BMR (spoczynkowe)'), findsOneWidget);
        semantics.dispose();
      });
    }
  }

  testWidgets('test change clears draft but same choice retains it', (
    tester,
  ) async {
    final fixture = await fitnessUiFixture();
    addTearDown(fixture.db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [testsRepositoryProvider.overrideWithValue(fixture.repo)],
        child: const MaterialApp(home: RunTestPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plank (czas)'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '60');
    await tester.tap(find.text('Plank (czas)'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '60',
    );
    await tester.tap(find.text('Max pompki'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.textContaining('wyczyszczony'), findsOneWidget);
  });

  for (final mode in ['success', 'failure', 'cancel']) {
    final fail = mode == 'failure';
    testWidgets('real routed edit validates and handles $mode', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(
              accountId: 'A',
              deviceId: 'device',
              offlineAccess: const Value(true),
            ),
          );
      final repo = UserProfileRepository(db);
      await repo.saveProfile(
        imie: profile.imie,
        wiek: profile.wiek,
        wzrostCm: profile.wzrostCm,
        wagaKg: profile.wagaKg,
        cel: profile.cel,
        dostepnySprzet: profile.dostepnySprzet,
      );
      await db.delete(db.syncOutbox).go();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/edit'),
                child: const Text('Open'),
              ),
            ),
          ),
          GoRoute(path: '/edit', builder: (_, __) => const EditProfilePage()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      for (final invalid in ['47.5', '47,5', 'NaN', '1e2']) {
        await tester.enterText(find.byType(TextFormField).first, invalid);
        await tester.tap(find.text('Zapisz'));
        await tester.pumpAndSettle();
        expect(await db.syncDao.pendingOperations(), isEmpty);
        expect(find.textContaining('pełnych latach'), findsOneWidget);
      }
      await tester.enterText(find.byType(TextFormField).first, ' 47 ');
      await tester.enterText(find.byType(TextFormField).at(2), 'abc');
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      await tester.enterText(find.byType(TextFormField).at(2), ' 94,5 ');
      if (fail) {
        await db.customStatement(
          "CREATE TRIGGER deny_profile BEFORE UPDATE ON user_profiles BEGIN SELECT RAISE(FAIL, 'test failure'); END",
        );
      }
      final entered = Completer<void>(), release = Completer<void>();
      final block = db.transaction(() async {
        entered.complete();
        await release.future;
      });
      await tester.runAsync(() => entered.future);
      await tester.tap(find.text('Zapisz'));
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );
      await tester.tap(find.byType(ElevatedButton));
      if (mode == 'cancel') {
        router.pop();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
      }
      release.complete();
      await tester.runAsync(() => block);
      await tester.pumpAndSettle();
      if (mode == 'cancel') {
        expect(find.text('Open'), findsOneWidget);
        expect(await db.syncDao.pendingOperations(), isEmpty);
      } else if (fail) {
        expect(find.byType(EditProfilePage), findsOneWidget);
        expect(
          find.text('Nie udało się zapisać profilu. Spróbuj ponownie.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(2))
              .controller!
              .text,
          ' 94,5 ',
        );
        expect(await db.syncDao.pendingOperations(), isEmpty);
      } else {
        expect(find.text('Open'), findsOneWidget);
        final after = (await repo.getProfileOnce())!;
        expect(after.wagaKg, 94.5);
        expect(after.wzrostCm, 180.5);
        expect(await db.syncDao.pendingOperations(), hasLength(1));
      }
    });
  }
}
