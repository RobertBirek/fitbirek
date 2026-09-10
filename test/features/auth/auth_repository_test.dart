import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fitbirek_training/core/api/api_client.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  group('AuthController', () {
    test(
      'keeps the user signed out when login credentials are invalid',
      () async {
        final controller = AuthController(
          _FakeAuthApi(loginError: const AuthFailure()),
        );

        await expectLater(
          controller.login('me@example.com', 'incorrect'),
          throwsA(isA<AuthFailure>()),
        );

        expect(controller.state, const AuthState.signedOut());
      },
    );

    test('restores a signed-in session during bootstrap', () async {
      final controller = AuthController(
        _FakeAuthApi(session: const AuthSession(accountId: 'me@example.com')),
      );

      await controller.bootstrap();

      expect(controller.state, const AuthState.signedIn('me@example.com'));
    });

    test(
      'logs out remotely before clearing local authentication state',
      () async {
        final api = _FakeAuthApi(
          session: const AuthSession(accountId: 'me@example.com'),
        );
        final controller = AuthController(api);
        await controller.bootstrap();

        await controller.logout();

        expect(api.didLogout, isTrue);
        expect(controller.state, const AuthState.signedOut());
      },
    );
  });

  test('adds the readable CSRF cookie to API mutations', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(dio, csrfTokenReader: () => 'csrf-value');

    await client.post('/api/auth/logout');

    expect(adapter.requestHeaders['X-CSRF-Token'], 'csrf-value');
  });

  test('adds the trusted Origin header to native API mutations', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(dio, csrfTokenReader: () => 'csrf-value');

    await client.post('/api/auth/logout');

    expect(adapter.requestHeaders['Origin'], 'https://fit.birek.online');
  });

  test('rejects a restored session that has no account ID', () async {
    final adapter = _QueuedAdapter([
      _jsonResponse('{"email":"me@example.com"}'),
    ]);
    final repository = AuthRepository(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
          ..httpClientAdapter = adapter,
      ),
    );

    await expectLater(repository.getSession(), throwsA(isA<AuthFailure>()));
  });

  test('logs in with credentials and restores the UUID account ID', () async {
    const accountId = 'c11da0c2-e308-4d9b-a63c-e790ec4d1e49';
    final adapter = _QueuedAdapter([
      ResponseBody.fromString('', 204),
      _jsonResponse('{"accountId":"$accountId","email":"me@example.com"}'),
    ]);
    final repository = AuthRepository(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
          ..httpClientAdapter = adapter,
      ),
    );

    final session = await repository.login(
      email: 'me@example.com',
      password: 'password',
    );

    expect(session.accountId, accountId);
    expect(adapter.requestPaths, ['/api/auth/login', '/api/auth/session']);
    expect(adapter.requestBodies.single, {
      'email': 'me@example.com',
      'password': 'password',
    });
  });

  test('maps an HTTP invalid-login response to AuthFailure', () async {
    final adapter = _QueuedAdapter([ResponseBody.fromString('', 401)]);
    final repository = AuthRepository(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
          ..httpClientAdapter = adapter,
      ),
    );

    await expectLater(
      repository.login(email: 'me@example.com', password: 'incorrect'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('posts logout through the API client', () async {
    final adapter = _QueuedAdapter([ResponseBody.fromString('', 204)]);
    final repository = AuthRepository(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
          ..httpClientAdapter = adapter,
      ),
    );

    await repository.logout();

    expect(adapter.requestPaths, ['/api/auth/logout']);
  });

  test('creates a usable absolute API base URL on native platforms', () {
    final client = ApiClient.sameOrigin();

    expect(client.dio.options.baseUrl, 'https://fit.birek.online/');
  });
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.session, this.loginError});

  final AuthSession? session;
  final AuthFailure? loginError;
  bool didLogout = false;

  @override
  Future<AuthSession?> getSession() async => session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return const AuthSession(accountId: 'me@example.com');
  }

  @override
  Future<void> logout() async {
    didLogout = true;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  final Map<String, dynamic> requestHeaders = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestHeaders.addAll(options.headers);
    return ResponseBody.fromString('', 204);
  }
}

class _QueuedAdapter implements HttpClientAdapter {
  _QueuedAdapter(this._responses);

  final List<ResponseBody> _responses;
  final List<String> requestPaths = [];
  final List<Map<String, dynamic>> requestBodies = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPaths.add(options.path);
    if (options.data is Map<String, dynamic>) requestBodies.add(options.data);
    return _responses.removeAt(0);
  }
}

ResponseBody _jsonResponse(String body) {
  return ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
