import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/api/api_client.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';

void main() {
  test('settings save sends the supplied partial patch unchanged', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    Map<String, dynamic>? body;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          body = Map<String, dynamic>.from(request.data as Map);
          handler.resolve(Response(requestOptions: request, data: {}));
        },
      ),
    );

    await HttpMentorApi(
      ApiClient(dio),
    ).saveSettings({'expected_revision': 4, 'persona': ''});

    expect(body, {'expected_revision': 4, 'persona': ''});
  });
  test('settings conflict has a safe dedicated error code', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 409,
              data: {'detail': 'SECRET stale revision'},
            ),
          ),
        ),
      ),
    );

    await expectLater(
      HttpMentorApi(
        ApiClient(dio),
      ).saveSettings({'expected_revision': 4, 'persona': 'Nowa persona'}),
      throwsA(
        isA<MentorException>()
            .having((error) => error.code, 'code', 'settings_conflict')
            .having(
              (error) => error.toString(),
              'safe message',
              isNot(contains('SECRET')),
            ),
      ),
    );
  });
  test(
    'STT sends explicit logical ID unchanged across transport retries',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      final ids = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            ids.add(request.headers['X-Request-ID'] as String);
            handler.resolve(
              Response(requestOptions: request, data: {'text': 'Szkic'}),
            );
          },
        ),
      );
      final api = HttpMentorApi(ApiClient(dio));
      for (var i = 0; i < 2; i++) {
        await api.transcribe(
          Uint8List(1),
          'audio/webm',
          1,
          requestId: 'same-recording',
        );
      }
      expect(ids, ['same-recording', 'same-recording']);
    },
  );
  test('key submission refuses insecure transport before request', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    var requests = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );
    await expectLater(
      HttpMentorApi(ApiClient(dio)).saveKey('openai', 'test-secret'),
      throwsA(isA<MentorException>()),
    );
    expect(requests, 0);
  });
  test('message context sends only opaque selectors and settings revision', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    Map<String, dynamic>? body;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          body = Map<String, dynamic>.from(request.data as Map);
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'id': 'answer',
                'role': 'assistant',
                'text': 'OK',
                'created_at': '2026-10-08T00:00:00Z',
              },
            ),
          );
        },
      ),
    );
    final context = MentorContextSelection(
      training: true,
      weight: const MentorContextWeightOption(
        selectionId: 'opaque-weight-selector-that-is-long-enough',
        source: 'measurement',
        summary: '73 kg · 2026-10-08',
      ),
      note: const MentorContextNoteOption(
        selectionId: 'opaque-note-selector-that-is-long-enough',
        summary: '2026-10-07',
        preview: 'Prywatna notatka',
      ),
    );

    await HttpMentorApi(ApiClient(dio)).send(
      'session',
      'Jak trenować?',
      requestId: 'request',
      settingsRevision: 4,
      context: context,
    );

    expect(body, {
      'request_id': 'request',
      'text': 'Jak trenować?',
      'settings_revision': 4,
      'context': {
        'training': true,
        'profile': false,
        'apple_health': false,
        'weight': {
          'source': 'measurement',
          'selection_id': 'opaque-weight-selector-that-is-long-enough',
        },
        'note': {'selection_id': 'opaque-note-selector-that-is-long-enough'},
      },
    });
    expect(jsonEncode(body), isNot(contains('73 kg')));
    expect(jsonEncode(body), isNot(contains('Prywatna notatka')));
  });
  test(
    'every endpoint carries revocable token and errors never expose secrets',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      final api = HttpMentorApi(ApiClient(dio));
      final tokens = <CancelToken>[];
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.cancelToken, isNotNull);
            tokens.add(request.cancelToken!);
            handler.reject(
              DioException(
                requestOptions: request,
                error: 'SECRET provider response',
              ),
            );
          },
        ),
      );
      final calls = <Future<Object?> Function()>[
        () => api.operations(sessionId: 'session'),
        () => api.operation('stable-id'),
        api.settings,
        () => api.saveSettings({}),
        api.sessions,
        () => api.createSession('id'),
        () => api.messages('id'),
        () => api.send('id', 'private', requestId: 'stable-id'),
        () => api.deleteSession('id'),
        () => api.saveKey('openai', 'SECRET'),
        () => api.deleteKey('openai'),
        () => api.testProvider('openai'),
        api.refreshVoices,
        () =>
            api.transcribe(Uint8List(1), 'audio/webm', 1, requestId: 'request'),
        () => api.speech('id', requestId: 'request'),
      ];
      for (final call in calls) {
        await expectLater(
          call(),
          throwsA(
            isA<MentorException>().having(
              (e) => e.toString(),
              'safe error',
              isNot(contains('SECRET')),
            ),
          ),
        );
      }
      expect(tokens, hasLength(calls.length));
      api.cancel();
      expect(tokens.every((token) => token.isCancelled), isTrue);
      await expectLater(api.settings(), throwsA(isA<MentorException>()));
    },
  );
  test(
    'voice uses caller request ID and only allowlisted generic codes survive byte error bodies',
    () async {
      for (final code in [
        'operation_pending',
        'result_unavailable',
        'operation_failed',
        'operation_cancelled',
        'operation_conflict',
        'SECRET',
      ]) {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              expect(request.data, {'request_id': 'stable-voice'});
              handler.reject(
                DioException(
                  requestOptions: request,
                  response: Response(
                    requestOptions: request,
                    statusCode: 409,
                    data: utf8.encode(
                      jsonEncode({
                        'code': code,
                        'detail': 'SECRET vendor body',
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        );
        await expectLater(
          HttpMentorApi(
            ApiClient(dio),
          ).speech('answer', requestId: 'stable-voice'),
          throwsA(
            isA<MentorException>()
                .having(
                  (e) => e.code,
                  'generic code',
                  code == 'SECRET' ? null : code,
                )
                .having(
                  (e) => e.toString(),
                  'safe message',
                  isNot(contains('SECRET')),
                ),
          ),
        );
      }
    },
  );
}
