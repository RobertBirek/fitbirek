import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/presentation/pages/login_page.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/progress/presentation/pages/progress_page.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import '../../core/database/shared_schema_fixture.dart';
import '../../core/sync_service_test.dart' show FakeSyncApi;
import 'offline_auth_test.dart' show SessionApi;

void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDown(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  for (final change in ['generation', 'account', 'removal']) {
    test(
      'signed-in UI rejects remote $change without requiring a lock flag',
      () async {
        final server = DriftServer(NativeDatabase.memory());
        final a = AppDatabase.forTesting(await connectSchemaClient(server));
        final b = AppDatabase.forTesting(await connectSchemaClient(server));
        final sync = SyncService(b, FakeSyncApi());
        final auth = AuthController(SessionApi(), db: b, sync: sync);
        addTearDown(() async {
          auth.dispose();
          sync.dispose();
          await a.close();
          await b.close();
          await server.shutdown();
        });
        await auth.login('e', 'p');
        final revoked = Completer<void>();
        auth.addListener((s) {
          if (s.isSignedOut && !revoked.isCompleted) revoked.complete();
        });
        switch (change) {
          case 'generation':
            await a
                .update(a.syncState)
                .write(const SyncStateCompanion(deviceId: Value('new')));
          case 'account':
            await a
                .update(a.syncState)
                .write(const SyncStateCompanion(accountId: Value('B')));
          case 'removal':
            await a.delete(a.syncState).go();
        }
        final changed = await a.syncDao.readState();
        await revoked.future.timeout(const Duration(seconds: 2));
        expect(await b.syncDao.readState(), changed);
      },
    );
  }
  test(
    'remote Drift lock revokes another controller without a write echo',
    () async {
      final server = DriftServer(NativeDatabase.memory());
      final a = AppDatabase.forTesting(await connectSchemaClient(server));
      final b = AppDatabase.forTesting(await connectSchemaClient(server));
      final sa = SyncService(a, FakeSyncApi());
      final sb = SyncService(b, FakeSyncApi());
      final api = SessionApi();
      final ca = AuthController(SessionApi(), db: a, sync: sa);
      final cb = AuthController(api, db: b, sync: sb);
      addTearDown(() async {
        ca.dispose();
        cb.dispose();
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
        await server.shutdown();
      });
      await ca.login('email', 'password');
      await cb.bootstrap();
      final revoked = Completer<void>();
      cb.addListener((s) {
        if (s.isSignedOut && !revoked.isCompleted) revoked.complete();
      });
      final reads = api.sessionReads;
      await ca.logout();
      final locked = await a.syncDao.readState();
      await revoked.future.timeout(const Duration(seconds: 2));
      expect(cb.state.isSignedOut, isTrue);
      expect(await b.syncDao.readState(), locked);
      expect(api.sessionReads, reads);
    },
  );

  test(
    'remote lock hides UI and disables local sync while a push is pending',
    () async {
      final server = DriftServer(NativeDatabase.memory());
      final a = AppDatabase.forTesting(await connectSchemaClient(server));
      final b = AppDatabase.forTesting(await connectSchemaClient(server));
      final entered = Completer<void>();
      final gate = Completer<void>();
      final api = FakeSyncApi()
        ..onPush = (_) async {
          entered.complete();
          await gate.future;
          throw Exception('offline');
        };
      final sync = SyncService(b, api);
      final auth = AuthController(SessionApi(), db: b, sync: sync);
      addTearDown(() async {
        auth.dispose();
        sync.dispose();
        await a.close();
        await b.close();
        await server.shutdown();
      });
      await WorkoutRepository(b).startSession();
      await auth.login('e', 'p');
      await entered.future;
      final revoked = Completer<void>();
      auth.addListener((s) {
        if (s.isSignedOut && !revoked.isCompleted) revoked.complete();
      });
      await a.syncDao.lockOfflineAccess();
      await revoked.future.timeout(const Duration(seconds: 2));
      // synchronize returns immediately only when disabled, not the pending push.
      await sync.synchronize().timeout(const Duration(seconds: 2));
      expect(api.requests, hasLength(1));
      expect(await b.syncDao.pendingOperations(), hasLength(1));
      gate.complete();
      await sync.stop();
      expect(await b.syncDao.pendingOperations(), hasLength(1));
    },
  );

  test(
    'disposed controller ignores a delayed session and cancels observation',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = DelayedApi();
      final auth = AuthController(api, db: db);
      final pending = auth.bootstrap();
      await api.started.future;
      auth.dispose();
      api.gate.complete(const AuthSession(accountId: 'account'));
      await pending;
      await db.syncDao.lockOfflineAccess();
      await db.close();
    },
  );

  for (final phase in ['bootstrap', 'login', 'prepare']) {
    for (final remote in [false, true]) {
      test(
        '$phase cannot resurrect auth after ${remote ? 'remote' : 'local'} logout and A-B-A',
        () async {
          final server = DriftServer(NativeDatabase.memory());
          final a = AppDatabase.forTesting(await connectSchemaClient(server));
          final b = AppDatabase.forTesting(await connectSchemaClient(server));
          final sync = SyncService(b, FakeSyncApi());
          await a
              .into(a.syncState)
              .insert(
                SyncStateCompanion.insert(
                  accountId: 'account',
                  deviceId: 'original',
                ),
              );
          final api = DelayedApi();
          final prepareStarted = Completer<void>();
          final prepareGate = Completer<void>();
          final auth = AuthController(
            api,
            db: b,
            sync: sync,
            prepare: () async {
              if (phase == 'prepare' && !prepareStarted.isCompleted) {
                prepareStarted.complete();
                await prepareGate.future;
              }
            },
          );
          addTearDown(() async {
            auth.dispose();
            sync.dispose();
            await a.close();
            await b.close();
            await server.shutdown();
          });
          final pending = phase == 'bootstrap'
              ? auth.bootstrap()
              : auth.login('e', 'p');
          await api.started.future;
          if (phase == 'prepare') {
            api.gate.complete(const AuthSession(accountId: 'account'));
            await prepareStarted.future;
          }
          if (remote) {
            await a.syncDao.lockOfflineAccess();
          } else {
            await auth.logout();
          }
          // Coalesced notifications may only expose the final A. The durable
          // device generation, not account equality alone, must revoke the intent.
          await a
              .update(a.syncState)
              .write(const SyncStateCompanion(accountId: Value('B')));
          await a
              .update(a.syncState)
              .write(
                const SyncStateCompanion(
                  accountId: Value('account'),
                  offlineAccess: Value(true),
                ),
              );
          final newer = await a.syncDao.readState();
          if (phase == 'prepare') {
            prepareGate.complete();
          } else {
            api.gate.complete(const AuthSession(accountId: 'account'));
          }
          await pending;
          expect(auth.state.isSignedOut, isTrue);
          expect(
            await b.syncDao.readState(),
            newer,
            reason: 'do not revoke the newer login',
          );
          await auth.login('new', 'intent');
          expect(auth.state.isSignedIn, isTrue);
        },
      );
    }
  }

  testWidgets(
    'real auth providers and router remove private progress on remote logout',
    (tester) async {
      await initializeDateFormatting('pl_PL');
      final server = DriftServer(NativeDatabase.memory());
      late AppDatabase a;
      late AppDatabase b;
      await tester.runAsync(() async {
        a = AppDatabase.forTesting(await connectSchemaClient(server));
        b = AppDatabase.forTesting(await connectSchemaClient(server));
        await a
            .into(a.userProfiles)
            .insert(
              UserProfilesCompanion.insert(
                imie: const Value('Private'),
                wiek: 30,
                wzrostCm: 180,
                wagaKg: 80,
                cel: 'mix',
                dostepnySprzet: '[]',
                onboardingZakonczony: const Value(true),
              ),
            );
      });
      ProviderContainer container(AppDatabase db) => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(TestRepository()),
          exercisesRepositoryProvider.overrideWithValue(NoAssetImport()),
          syncServiceProvider.overrideWith(
            (ref) => SyncService(db, FakeSyncApi()),
          ),
        ],
      );
      final first = container(a);
      final second = container(b);
      final authority = second.read(cachedAuthWriteAuthorityProvider);
      expect(authority.state, isNull);
      expect(
        second.exists(authStateProvider),
        isFalse,
        reason: 'cached authority is passive',
      );
      Future<void> signedIn(ProviderContainer c) async {
        final ready = Completer<void>();
        final sub = c.listen(authStateProvider, (_, s) {
          if (s.isSignedIn && !ready.isCompleted) ready.complete();
        }, fireImmediately: true);
        await ready.future.timeout(const Duration(seconds: 5));
        sub.close();
      }

      await tester.runAsync(() async {
        await signedIn(first);
        await signedIn(second);
        await second
            .read(userProfileStreamProvider.future)
            .timeout(const Duration(seconds: 5));
      });
      final router = second.read(routerProvider);
      router.go('/progress');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: second,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProgressPage), findsOneWidget);
      final epoch = authority.epoch;
      final mentorRegistry = second.read(mentorOperationRegistryProvider);
      expect(mentorRegistry.accountId, 'account');
      await tester.runAsync(() async {
        final revoked = Completer<void>();
        final sub = second.listen(authStateProvider, (_, s) {
          if (s.isSignedOut && !revoked.isCompleted) revoked.complete();
        });
        await first
            .read(authStateProvider.notifier)
            .logout()
            .timeout(const Duration(seconds: 5));
        await revoked.future.timeout(const Duration(seconds: 2));
        sub.close();
      });
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(ProgressPage), findsNothing);
      expect(authority.state!.isSignedOut, isTrue);
      expect(authority.epoch, greaterThan(epoch));
      expect(
        second.read(mentorOperationRegistryProvider),
        isNot(same(mentorRegistry)),
      );
      expect(second.read(mentorOperationRegistryProvider).accountId, isEmpty);
      router.go('/progress');
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        router.dispose();
        first.dispose();
        second.dispose();
        await a.close().timeout(const Duration(seconds: 5));
        await b.close().timeout(const Duration(seconds: 5));
        await server.shutdown().timeout(const Duration(seconds: 5));
      });
    },
  );
}

class DelayedApi extends SessionApi {
  final started = Completer<void>();
  final gate = Completer<AuthSession>();
  @override
  Future<AuthSession?> getSession() {
    if (!started.isCompleted) started.complete();
    return gate.future;
  }
}

class TestRepository extends SessionApi implements AuthRepository {}

class NoAssetImport implements ExercisesRepository {
  @override
  Future<void> syncFromAssets() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
