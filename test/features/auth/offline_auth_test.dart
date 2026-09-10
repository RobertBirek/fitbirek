import 'package:dio/dio.dart';
import 'dart:async';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import '../../core/sync_service_test.dart' show FakeSyncApi;

class SessionApi implements AuthApi {
  bool offline = false;
  bool expired = false;
  @override
  Future<AuthSession?> getSession() async {
    if (offline) {
      throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    }
    return expired ? null : const AuthSession(accountId: 'account');
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => (await getSession())!;
  @override
  Future<void> logout() async {
    if (offline) throw Exception('offline');
  }
}

void main() {
  test(
    'logout persists its lock before waiting for an in-flight sync',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final gate = Completer<void>();
      final started = Completer<void>();
      final transport = FakeSyncApi()
        ..onPush = (_) async {
          started.complete();
          await gate.future;
          throw Exception('offline');
        };
      final sync = SyncService(db, transport);
      final auth = AuthController(SessionApi(), db: db, sync: sync);
      await WorkoutRepository(db).startSession();
      await auth.login('email', 'password');
      await started.future;
      final logout = auth.logout();
      // A subsequent DB read observes the durable lock even while HTTP is stuck.
      expect((await db.syncDao.readState())!.offlineAccess, isFalse);
      gate.complete();
      await logout;
      auth.dispose();
      sync.dispose();
      await db.close();
    },
  );
  test(
    'previous login survives offline restart; 401 revokes offline access',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, FakeSyncApi());
      final api = SessionApi();
      AuthController controller() => AuthController(api, db: db, sync: sync);
      final first = controller();
      await first.bootstrap();
      expect(first.state.isSignedIn, isTrue);
      first.dispose();
      api.offline = true;
      final restart = controller();
      await restart.bootstrap();
      expect(restart.state.isSignedIn, isTrue);
      restart.dispose();
      api.offline = false;
      api.expired = true;
      final expired = controller();
      await expired.bootstrap();
      expect(expired.state.isSignedOut, isTrue);
      expect((await db.syncDao.readState())!.offlineAccess, isFalse);
      expired.dispose();
      sync.dispose();
      await db.close();
    },
  );

  test(
    'first login needs network and logout stays locked after restart',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, FakeSyncApi());
      final api = SessionApi()..offline = true;
      final auth = AuthController(api, db: db, sync: sync);
      await auth.bootstrap();
      expect(auth.state.isSignedOut, isTrue);
      api.offline = false;
      await auth.login('email', 'password');
      api.offline = true;
      await auth.logout();
      api.offline = false; // stale server cookie must not undo explicit logout
      await auth.bootstrap();
      expect(auth.state.isSignedOut, isTrue);
      expect((await db.syncDao.readState())!.accountId, 'account');
      auth.dispose();
      sync.dispose();
      await db.close();
    },
  );
}
