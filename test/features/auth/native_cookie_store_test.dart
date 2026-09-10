import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/api/api_client.dart';
import 'package:fitbirek_training/core/api/cookie_store_io.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';

class CookieAdapter implements HttpClientAdapter {
  bool offline = false;
  final requests = <RequestOptions>[];
  Future<ResponseBody> Function(RequestOptions)? respond;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (respond != null) return respond!(options);
    if (options.path == '/api/auth/login') {
      return ResponseBody.fromString(
        '',
        204,
        headers: {
          'set-cookie': [
            'fit_session=session-secret; Path=/; Secure; HttpOnly; Max-Age=3600',
            'fit_csrf=csrf-secret; Path=/; Secure; Max-Age=3600',
          ],
        },
      );
    }
    if (options.path == '/api/auth/session') {
      final authorized = (options.headers['Cookie'] as String? ?? '').contains(
        'fit_session=session-secret',
      );
      return ResponseBody.fromString(
        authorized ? '{"accountId":"account"}' : '{}',
        authorized ? 200 : 401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('', 204);
  }
}

ApiClient client(CookieAdapter adapter, {ApiCookieStore? cookies}) => ApiClient(
  Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
    ..httpClientAdapter = adapter,
  cookieStore: cookies,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'native login survives new client, offline startup and authenticated reconnect',
    () async {
      final adapter = CookieAdapter();
      await AuthRepository(
        client(adapter),
      ).login(email: 'me@example.com', password: 'secret');
      final restarted = client(adapter);
      adapter.offline = true;
      await expectLater(
        AuthRepository(restarted).getSession(),
        throwsA(isA<DioException>()),
      );
      adapter.offline = false;
      expect(
        (await AuthRepository(restarted).getSession())?.accountId,
        'account',
      );
      await restarted.post('/api/sync/push', data: {'operations': []});
      expect(
        adapter.requests.last.headers['Cookie'],
        contains('fit_session=session-secret'),
      );
      expect(adapter.requests.last.headers['X-CSRF-Token'], 'csrf-secret');
      expect(await const FlutterSecureStorage().readAll(), isNotEmpty);
    },
  );

  test('offline logout erases secure credentials and cached CSRF', () async {
    final adapter = CookieAdapter();
    final api = client(adapter);
    await AuthRepository(
      api,
    ).login(email: 'me@example.com', password: 'secret');
    adapter.offline = true;
    await expectLater(
      AuthRepository(api).logout(),
      throwsA(isA<DioException>()),
    );
    adapter.offline = false;
    await api.post('/api/sync/push');
    expect(adapter.requests.last.headers['Cookie'], isNull);
    expect(adapter.requests.last.headers['X-CSRF-Token'], isNull);
    expect(await AuthRepository(client(adapter)).getSession(), isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test(
    'logout removes persistence before waiting for HTTP and ignores late cookies',
    () async {
      final adapter = CookieAdapter();
      final api = client(adapter);
      await AuthRepository(
        api,
      ).login(email: 'me@example.com', password: 'secret');
      final inFlight = Completer<void>();
      final stale = Completer<ResponseBody>();
      final logoutStarted = Completer<void>();
      final logoutReply = Completer<ResponseBody>();
      adapter.respond = (options) async {
        if (options.path == '/api/stale') {
          inFlight.complete();
          return stale.future;
        }
        logoutStarted.complete();
        return logoutReply.future;
      };
      final request = api.get('/api/stale');
      await inFlight.future;
      final logout = AuthRepository(api).logout();
      await logoutStarted.future;
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      expect(
        adapter.requests.last.headers['Cookie'],
        contains('fit_session=session-secret'),
      );
      expect(adapter.requests.last.headers['X-CSRF-Token'], 'csrf-secret');
      stale.complete(
        ResponseBody.fromString(
          '',
          204,
          headers: {
            'set-cookie': [
              'fit_session=stale; Max-Age=3600',
              'fit_csrf=stale; Max-Age=3600',
            ],
          },
        ),
      );
      logoutReply.complete(ResponseBody.fromString('', 204));
      await request;
      await logout;
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      adapter.respond = null;
      await api.post('/api/sync/push');
      expect(adapter.requests.last.headers['Cookie'], isNull);
      expect(adapter.requests.last.headers['X-CSRF-Token'], isNull);
    },
  );

  for (final useMaxAge in [false, true]) {
    test(
      '${useMaxAge ? "Max-Age (over Expires)" : "Expires"} expires persisted cookies without extending on restart',
      () async {
        var now = DateTime.utc(2026, 9, 10);
        final expires = HttpDate.format(
          now.add(Duration(seconds: useMaxAge ? 100 : 10)),
        );
        final attributes = 'Expires=$expires${useMaxAge ? "; Max-Age=10" : ""}';
        final adapter = CookieAdapter()
          ..respond = (_) async => ResponseBody.fromString(
            '',
            204,
            headers: {
              'set-cookie': [
                'fit_session=session-secret; $attributes',
                'fit_csrf=csrf-secret; $attributes',
              ],
            },
          );
        await client(
          adapter,
          cookies: NativeApiCookieStore(clock: () => now),
        ).post('/api/auth/login');
        adapter.respond = (_) async => ResponseBody.fromString('', 204);
        now = now.add(const Duration(seconds: 9));
        final restarted = client(
          adapter,
          cookies: NativeApiCookieStore(clock: () => now),
        );
        await restarted.post('/api/probe');
        expect(
          adapter.requests.last.headers['Cookie'],
          contains('fit_session=session-secret'),
        );
        expect(adapter.requests.last.headers['X-CSRF-Token'], 'csrf-secret');
        now = now.add(const Duration(seconds: 1));
        await restarted.post('/api/probe');
        expect(adapter.requests.last.headers['Cookie'], isNull);
        expect(adapter.requests.last.headers['X-CSRF-Token'], isNull);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
        await client(
          adapter,
          cookies: NativeApiCookieStore(clock: () => now),
        ).get('/api/probe');
        expect(adapter.requests.last.headers['Cookie'], isNull);
      },
    );
  }

  test(
    'legacy cookies have a finite 24-hour native persistence bound',
    () async {
      var now = DateTime.utc(2026, 9, 10);
      final adapter = CookieAdapter()
        ..respond = (_) async => ResponseBody.fromString(
          '',
          204,
          headers: {
            'set-cookie': [
              'fit_session=session-secret; Secure; HttpOnly',
              'fit_csrf=csrf-secret; Secure',
            ],
          },
        );
      await client(
        adapter,
        cookies: NativeApiCookieStore(clock: () => now),
      ).post('/api/auth/login');
      adapter.respond = (_) async => ResponseBody.fromString('', 204);
      now = now.add(const Duration(hours: 23));
      await client(
        adapter,
        cookies: NativeApiCookieStore(clock: () => now),
      ).get('/api/probe');
      expect(
        adapter.requests.last.headers['Cookie'],
        contains('fit_session=session-secret'),
      );
      now = now.add(const Duration(hours: 1));
      await client(
        adapter,
        cookies: NativeApiCookieStore(clock: () => now),
      ).get('/api/probe');
      expect(adapter.requests.last.headers['Cookie'], isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    },
  );

  test('Max-Age zero clears nonempty cookie values and cached CSRF', () async {
    final adapter = CookieAdapter();
    final api = client(adapter);
    await AuthRepository(
      api,
    ).login(email: 'me@example.com', password: 'secret');
    adapter.respond = (_) async => ResponseBody.fromString(
      '',
      204,
      headers: {
        'set-cookie': [
          'fit_session=session-secret; Max-Age=0',
          'fit_csrf=csrf-secret; Max-Age=0',
        ],
      },
    );
    await api.get('/api/expire');
    adapter.respond = null;
    await api.post('/api/probe');
    expect(adapter.requests.last.headers['Cookie'], isNull);
    expect(adapter.requests.last.headers['X-CSRF-Token'], isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test(
    'real 401 clears persisted credentials rather than restoring a revoked session',
    () async {
      final adapter = CookieAdapter();
      final api = client(adapter);
      await AuthRepository(
        api,
      ).login(email: 'me@example.com', password: 'secret');
      adapter.respond = (_) async => ResponseBody.fromString('{}', 401);
      expect(await AuthRepository(api).getSession(), isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      adapter.respond = null;
      expect(await AuthRepository(client(adapter)).getSession(), isNull);
    },
  );

  test(
    'foreign origin neither receives nor replaces native credentials',
    () async {
      final adapter = CookieAdapter();
      final api = client(adapter);
      await AuthRepository(
        api,
      ).login(email: 'me@example.com', password: 'secret');
      adapter.respond = (_) async => ResponseBody.fromString(
        '',
        204,
        headers: {
          'set-cookie': ['fit_session=foreign; Max-Age=3600'],
        },
      );
      await api.post('https://other.example/api/probe');
      expect(adapter.requests.last.headers['Cookie'], isNull);
      expect(adapter.requests.last.headers['X-CSRF-Token'], isNull);
      adapter.respond = null;
      expect(
        (await AuthRepository(client(adapter)).getSession())?.accountId,
        'account',
      );
    },
  );

  test(
    'corrupt secure storage is discarded before sending credentials',
    () async {
      final adapter = CookieAdapter();
      await AuthRepository(
        client(adapter),
      ).login(email: 'me@example.com', password: 'secret');
      const storage = FlutterSecureStorage();
      final key = (await storage.readAll()).keys.single;
      await storage.write(key: key, value: '{broken');
      expect(await AuthRepository(client(adapter)).getSession(), isNull);
      expect(await storage.readAll(), isEmpty);
    },
  );
}
