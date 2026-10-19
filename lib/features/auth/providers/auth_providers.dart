import 'dart:async';
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../exercises/providers/exercises_providers.dart';

import '../../../core/api/api_client.dart';
import '../../../core/push/push_provider.dart';
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

/// Passive, synchronous authority for local writes. Reading it never creates
/// authStateProvider or bootstraps HTTP. Once auth is initialized, every state
/// transition invalidates captures, including departure and return to one ID.
class CachedAuthWriteAuthority {
  /// Passive invalidation only; observing this never initializes HTTP/auth.
  final revision = ValueNotifier<int>(0);
  AuthState? _state;
  int _epoch = 0;

  AuthState? get state => _state;
  int get epoch => _epoch;

  void _observe(AuthState next) {
    if (_state == next) return;
    _state = next;
    _epoch++;
    revision.value = _epoch;
  }
}

final cachedAuthWriteAuthorityProvider = Provider<CachedAuthWriteAuthority>((
  ref,
) {
  final authority = CachedAuthWriteAuthority();
  ref.onDispose(authority.revision.dispose);
  return authority;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._api, {
    this.db,
    this.sync,
    this.prepare,
    this.preparePush,
    this.disablePush,
  }) : super(const AuthState.loading()) {
    final database = db;
    if (database != null) {
      _bindingSubscription = database
          .tableUpdates(TableUpdateQuery.onTable(database.syncState))
          .listen((_) => unawaited(_checkPersistentBinding()));
    }
  }

  final AuthApi _api;
  final AppDatabase? db;
  final SyncService? sync;
  final Future<void> Function()? prepare;
  final Future<void> Function(String)? preparePush;
  final Future<void> Function()? disablePush;
  bool _loggingOut = false;
  int _intent = 0;
  bool _hasBinding = false;
  SyncStateData? _binding;
  StreamSubscription<Set<TableUpdate>>? _bindingSubscription;

  bool _current(int intent) => mounted && intent == _intent;

  bool _sameBinding(SyncStateData? a, SyncStateData? b) =>
      a?.accountId == b?.accountId &&
      a?.deviceId == b?.deviceId &&
      a?.offlineAccess == b?.offlineAccess;

  // Observation is read-only: echoing lockOfflineAccess here would rotate the
  // generation forever between tabs, and could revoke a newer explicit login.
  void _invalidate() {
    if (!mounted) return;
    _intent++;
    _hasBinding = false;
    state = const AuthState.signedOut();
    unawaited(sync?.stop());
  }

  Future<void> _checkPersistentBinding() async {
    final intent = _intent;
    final expected = _binding;
    try {
      final latest = await db?.syncDao.readState();
      if (_current(intent) &&
          _hasBinding &&
          identical(expected, _binding) &&
          !_sameBinding(expected, latest)) {
        _invalidate();
      }
    } catch (_) {
      if (_current(intent)) _invalidate();
    }
  }

  Future<bool> _captureBinding(int intent) async {
    final binding = await db?.syncDao.readState();
    if (!_current(intent)) return false;
    if (_hasBinding && !_sameBinding(_binding, binding)) {
      _invalidate();
      return false;
    }
    _binding = binding;
    _hasBinding = true;
    return true;
  }

  Future<void> _accept(String accountId, int intent) async {
    final database = db;
    if (!_current(intent)) return;
    if (database == null) {
      await sync?.bindAccount(accountId);
    } else {
      // Check + bind + unlock are one shared-server transaction. A delayed
      // session response must never unlock a generation revoked in another tab.
      await database.transaction(() async {
        final latest = await database.syncDao.readState();
        if (!_current(intent)) return;
        if (!_sameBinding(_binding, latest)) {
          _invalidate();
          return;
        }
        await sync?.bindAccount(accountId);
        if (!_current(intent)) return;
        await database
            .update(database.syncState)
            .write(const SyncStateCompanion(offlineAccess: Value(true)));
        final accepted = await database.syncDao.readState();
        if (_current(intent)) _binding = accepted;
      });
    }
    if (!_current(intent)) return;
    await prepare?.call();
    await _checkPersistentBinding();
    if (!_current(intent)) return;
    state = AuthState.signedIn(accountId);
    sync?.start();
    final push = preparePush;
    if (push != null) unawaited(push(accountId).catchError((Object _) {}));
  }

  Future<void> _lockOfflineAccess() async {
    final database = db;
    if (database != null) {
      await database.syncDao.lockOfflineAccess();
    }
  }

  Future<void> unauthorized() async {
    final expected = _binding;
    _invalidate();
    final intent = _intent;
    final database = db;
    if (database != null) {
      final locked = await database.transaction(() async {
        final latest = await database.syncDao.readState();
        if (!_current(intent) || !_sameBinding(expected, latest)) {
          return false;
        }
        await _lockOfflineAccess();
        return true;
      });
      if (!locked) return;
    }
    if (_current(intent)) await _revokePush();
  }

  Future<void> _revokePush() async {
    try {
      await disablePush?.call().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Push failure must not prevent the durable local account lock.
    }
  }

  Future<void> bootstrap() async {
    if (!mounted || _loggingOut) return;
    final intent = ++_intent;
    if (!await _captureBinding(intent)) return;
    final cached = _binding;
    if (cached != null && !cached.offlineAccess) {
      // Repair a shutdown between the Drift lock and the separate consent DB
      // commit. This path must not depend on session restoration or connectivity.
      await _revokePush();
      if (_current(intent)) state = const AuthState.signedOut();
      return;
    }
    try {
      final session = await _api.getSession();
      await _checkPersistentBinding();
      if (!_current(intent)) return;
      if (session == null) {
        await unauthorized();
      } else {
        await _accept(session.accountId, intent);
      }
    } on DioException catch (e) {
      if (!_current(intent)) return;
      if (e.response == null && cached != null && cached.offlineAccess) {
        await _accept(cached.accountId, intent);
      } else {
        state = const AuthState.signedOut();
      }
    } catch (_) {
      if (_current(intent)) state = const AuthState.signedOut();
    }
  }

  Future<void> login(String email, String password) async {
    if (!mounted || _loggingOut) return;
    final intent = ++_intent;
    if (state.isSignedIn) state = const AuthState.loading();
    if (!await _captureBinding(intent)) return;
    try {
      final session = await _api.login(email: email, password: password);
      await _accept(session.accountId, intent);
    } catch (_) {
      if (_current(intent)) state = const AuthState.signedOut();
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    _intent++;
    _hasBinding = false;
    // Wait for cookie revocation and the bounded local consent commit, not
    // PushManager cleanup. A slow bridge must not delay revoking the session.
    state = const AuthState.loading();
    final disabling = _revokePush();
    await _lockOfflineAccess();
    final stopping = sync?.stop();
    try {
      await _api.logout();
    } catch (_) {
      // Local lock is durable even if the server cannot be reached.
    } finally {
      await stopping;
      await disabling;
      _loggingOut = false;
      if (mounted) state = const AuthState.signedOut();
    }
  }

  @override
  void dispose() {
    _intent++;
    unawaited(_bindingSubscription?.cancel());
    super.dispose();
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
        preparePush: (account) async {
          await ref.read(pushClientProvider).status(account);
        },
        disablePush: () => ref.read(pushClientProvider).logout(),
      );
      final authority = ref.read(cachedAuthWriteAuthorityProvider);
      final removeListener = controller.addListener(authority._observe);
      ref.onDispose(() {
        removeListener();
        authority._observe(const AuthState.loading());
      });
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
