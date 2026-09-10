import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../exercises/providers/exercises_providers.dart';

import '../../../core/api/api_client.dart';
import '../data/auth_repository.dart';

enum AuthStatus { loading, signedOut, signedIn }

class AuthState {
  const AuthState._(this.status, [this.accountId]);

  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.signedOut() : this._(AuthStatus.signedOut);
  const AuthState.signedIn(String accountId)
    : this._(AuthStatus.signedIn, accountId);

  final AuthStatus status;
  final String? accountId;

  bool get isLoading => status == AuthStatus.loading;
  bool get isSignedOut => status == AuthStatus.signedOut;
  bool get isSignedIn => status == AuthStatus.signedIn;

  @override
  bool operator ==(Object other) {
    return other is AuthState &&
        other.status == status &&
        other.accountId == accountId;
  }

  @override
  int get hashCode => Object.hash(status, accountId);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api, {this.db, this.sync, this.prepare})
    : super(const AuthState.loading());

  final AuthApi _api;
  final AppDatabase? db;
  final SyncService? sync;
  final Future<void> Function()? prepare;

  Future<void> _accept(String accountId) async {
    await sync?.bindAccount(accountId);
    final database = db;
    if (database != null) {
      await database
          .update(database.syncState)
          .write(const SyncStateCompanion(offlineAccess: Value(true)));
    }
    await prepare?.call();
    state = AuthState.signedIn(accountId);
    sync?.start();
  }

  Future<void> unauthorized() async {
    final database = db;
    if (database != null) {
      await database
          .update(database.syncState)
          .write(const SyncStateCompanion(offlineAccess: Value(false)));
    }
    state = const AuthState.signedOut();
  }

  Future<void> bootstrap() async {
    final cached = await db?.syncDao.readState();
    if (cached != null && !cached.offlineAccess) {
      state = const AuthState.signedOut();
      return;
    }
    try {
      final session = await _api.getSession();
      if (session == null) {
        await sync?.stop();
        await unauthorized();
      } else {
        await _accept(session.accountId);
      }
    } on DioException catch (e) {
      if (e.response == null && cached != null && cached.offlineAccess) {
        await _accept(cached.accountId);
      } else {
        state = const AuthState.signedOut();
      }
    } catch (_) {
      state = const AuthState.signedOut();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final session = await _api.login(email: email, password: password);
      await _accept(session.accountId);
    } on AuthFailure {
      state = const AuthState.signedOut();
      rethrow;
    }
  }

  Future<void> logout() async {
    await unauthorized();
    final stopping = sync?.stop();
    try {
      await _api.logout();
    } catch (_) {
      // Local lock is durable even if the server cannot be reached.
    } finally {
      await stopping;
      state = const AuthState.signedOut();
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.sameOrigin());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final StateNotifierProvider<AuthController, AuthState> authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      final controller = AuthController(
        ref.watch(authRepositoryProvider),
        db: ref.watch(appDatabaseProvider),
        sync: ref.watch(syncServiceProvider.notifier),
        prepare: () => ref.read(exercisesRepositoryProvider).syncFromAssets(),
      );
      Future<void>.microtask(controller.bootstrap);
      return controller;
    });

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  return SyncService(
    ref.watch(appDatabaseProvider),
    HttpSyncApi(ref.watch(apiClientProvider)),
    currentAccountId: () async =>
        (await ref.read(authRepositoryProvider).getSession())?.accountId,
    onUnauthorized: () => ref.read(authStateProvider.notifier).unauthorized(),
  );
});
