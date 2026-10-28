import 'package:drift/native.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/remote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/app/app.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/app/database_bootstrap.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../core/database/shared_schema_fixture.dart';

void main() {
  testWidgets(
    'RPC12 instructs full exit including this tab; optional Retry cannot promise a fresh server',
    (tester) async {
      final raw = sqlite.sqlite3.openInMemory();
      var server = DriftServer(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final old = (await tester.runAsync(() async {
        final old = OldSchemaClient(await connectSchemaClient(server));
        await old.customSelect('SELECT 1').get();
        return old;
      }))!;
      var attempts = 0;
      var childStarts = 0;
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            attempts++;
            final db = AppDatabase.forTesting(
              DatabaseConnection.delayed(connectSchemaClient(server)),
            );
            ref.onDispose(db.close);
            return db;
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await server.shutdown();
        raw.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: DatabaseBootstrap(
            child: Consumer(
              builder: (context, ref, _) {
                childStarts++;
                return const MaterialApp(home: Text('Protected deep route'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Zamknij wszystkie karty i okna FitBirek, także to, i otwórz aplikację ponownie.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('zamknij ją całkowicie'), findsOneWidget);
      expect(
        find.textContaining('opcjonalne sprawdzenie zgodności bazy'),
        findsOneWidget,
      );
      expect(find.textContaining('Zamknij wszystkie inne karty'), findsNothing);
      expect(
        find.textContaining('a następnie wybierz „Spróbuj ponownie”'),
        findsNothing,
      );
      expect(find.text('Schemat bazy: 12; wymagany: 15.'), findsOneWidget);
      expect(childStarts, 0);
      expect(container.exists(authStateProvider), isFalse);
      expect(container.exists(syncServiceProvider), isFalse);
      expect(container.exists(cachedAuthWriteAuthorityProvider), isFalse);
      await tester.tap(find.text('Spróbuj ponownie'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(childStarts, 0);
      expect(raw.userVersion, 12);
      expect(old.opens, 1);
      await tester.runAsync(old.close);
      // Reproduce the observed browser boundary: the old tab is gone but the
      // server can survive while the new blocked page remains open.
      await tester.tap(find.text('Spróbuj ponownie'));
      await tester.pumpAndSettle();
      expect(attempts, 3);
      expect(childStarts, 0);
      expect(raw.userVersion, 12);
      expect(find.text('Schemat bazy: 12; wymagany: 15.'), findsOneWidget);
      expect(find.textContaining('Jeśli blokada pozostaje'), findsOneWidget);
      expect(container.exists(authStateProvider), isFalse);
      expect(container.exists(syncServiceProvider), isFalse);
      // Explicit fresh-server positive control, NOT a simulation or guarantee
      // of browser teardown after closing only the old tab. App code never
      // invokes shutdown / terminateAll; full-exit recovery needs compiled E2E.
      await tester.runAsync(server.shutdown);
      server = DriftServer(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await tester.tap(find.text('Spróbuj ponownie'));
      await tester.pumpAndSettle();
      expect(attempts, 4);
      expect(raw.userVersion, 15);
      expect(find.text('Protected deep route'), findsOneWidget);
      expect(find.text('Spróbuj ponownie'), findsNothing);
      expect(childStarts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'whole real app stays blocked before router/auth on schema failure',
    (tester) async {
      var routerStarts = 0;
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      await db.close(); // An unreadable DB must also fail closed, not onboard.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            routerProvider.overrideWith((ref) {
              routerStarts++;
              throw StateError('router must not start');
            }),
          ],
          child: const FitBirekApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(routerStarts, 0);
      expect(find.text('Spróbuj ponownie'), findsOneWidget);
      expect(
        find.textContaining('Nie udało się bezpiecznie otworzyć'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
