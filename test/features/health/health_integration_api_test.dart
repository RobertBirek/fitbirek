// Klient integracji Apple Zdrowie: status/rotacja/revoke. Token pojawia się
// wyłącznie w jednej odpowiedzi i jest trzymany tylko w pamięci; błędy sieci
// mapowane na generyczny wyjątek bez szczegółów żądania Dio.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/api/api_client.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/health/data/health_integration_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'HttpSyncApi explicitly opts into health history with the cursor',
    () async {
      final adapter = _QueuedAdapter([
        ResponseBody.fromString(
          '{"cursor":77,"changes":[]}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      ]);
      final api = HttpSyncApi(
        ApiClient(
          Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
            ..httpClientAdapter = adapter,
        ),
      );
      await api.pull(77);
      expect(
        adapter.requestPaths.single,
        '/api/sync/pull?cursor=77&include_health=true',
      );
      expect(adapter.methods.single, 'GET');
    },
  );

  HealthIntegrationApi clientFor(List<ResponseBody> responses) {
    final adapter = _QueuedAdapter(responses);
    final dio = Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
      ..httpClientAdapter = adapter;
    return HttpHealthIntegrationApi(ApiClient(dio));
  }

  ResponseBody jsonResponse(String body, [int status = 200]) =>
      ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  test('reads an enabled status with optional timestamps', () async {
    final api = clientFor([
      jsonResponse(
        '{"enabled":true,"createdAt":"2026-09-01T10:00:00Z",'
        '"lastImportAt":"2026-09-10T07:30:00Z"}',
      ),
    ]);

    final status = await api.getStatus();
    expect(status.enabled, isTrue);
    expect(status.lastImportAt, DateTime.utc(2026, 9, 10, 7, 30));
  });

  test('reads a disabled status with null timestamps', () async {
    final api = clientFor([
      jsonResponse('{"enabled":false,"createdAt":null,"lastImportAt":null}'),
    ]);

    final status = await api.getStatus();
    expect(status.enabled, isFalse);
    expect(status.lastImportAt, isNull);
  });

  test('generates a token once with explicit consent', () async {
    final adapter = _QueuedAdapter([
      jsonResponse(
        '{"enabled":true,"createdAt":"2026-09-01T10:00:00Z",'
        '"lastImportAt":null,"token":"tok-123"}',
      ),
    ]);
    final api = HttpHealthIntegrationApi(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
          ..httpClientAdapter = adapter,
      ),
    );

    final result = await api.generateToken();
    expect(result.status.enabled, isTrue);
    expect(result.token, 'tok-123');
    expect(adapter.requestBodies.single, {'consent': true});
    expect(adapter.requestPaths.single, '/api/integrations/apple-health/token');
  });

  test('revokes via DELETE and returns the status', () async {
    final adapter = _QueuedAdapter([
      jsonResponse(
        '{"enabled":false,"createdAt":"2026-09-01T10:00:00Z",'
        '"lastImportAt":null}',
      ),
    ]);
    final api = HttpHealthIntegrationApi(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'https://fit.birek.online/'))
          ..httpClientAdapter = adapter,
      ),
    );

    final status = await api.revoke();
    expect(status.enabled, isFalse);
    expect(adapter.requestPaths.single, '/api/integrations/apple-health/token');
    expect(adapter.methods.single, 'DELETE');
  });

  test(
    'maps network failures to a generic exception without request data',
    () async {
      final api = clientFor([ResponseBody.fromString('', 503)]);
      await expectLater(
        api.getStatus(),
        throwsA(isA<HealthIntegrationException>()),
      );
    },
  );

  test('a token response without a token field cannot be used', () async {
    final api = clientFor([
      jsonResponse('{"enabled":true,"createdAt":null,"lastImportAt":null}'),
    ]);
    await expectLater(
      api.generateToken(),
      throwsA(isA<HealthIntegrationException>()),
    );
  });
}

class _QueuedAdapter implements HttpClientAdapter {
  _QueuedAdapter(this._responses);

  final List<ResponseBody> _responses;
  final List<String> requestPaths = [];
  final List<String> methods = [];
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
    methods.add(options.method);
    if (options.data is Map<String, dynamic>) requestBodies.add(options.data);
    return _responses.removeAt(0);
  }
}
