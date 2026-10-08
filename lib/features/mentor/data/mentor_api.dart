import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/api_client.dart';
import 'mentor_models.dart';

class MentorException implements Exception {
  const MentorException([this.code]);
  final String? code;
  @override
  String toString() => 'Mentor jest chwilowo niedostępny. Spróbuj ponownie.';
}

abstract class MentorApi {
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  });
  Future<MentorOperation?> operation(String requestId);
  void cancel();
  Future<MentorSettings> settings();
  Future<MentorSettings> saveSettings(Map<String, Object?> patch);
  Future<MentorContextOptions> contextOptions();
  Future<List<MentorSession>> sessions();
  Future<String> createSession(String id);
  Future<List<MentorMessage>> messages(String sessionId);
  Future<MentorMessage> send(
    String sessionId,
    String text, {
    required String requestId,
    int? settingsRevision,
    MentorContextSelection? context,
  });
  Future<void> deleteSession(String id);
  Future<void> saveKey(String provider, String key);
  Future<void> deleteKey(String provider);
  Future<void> testProvider(String provider);
  Future<List<MentorVoiceChoice>> refreshVoices();
  Future<String> transcribe(
    Uint8List bytes,
    String contentType,
    double duration, {
    required String requestId,
  });
  Future<Uint8List> speech(String messageId, {required String requestId});
}

class HttpMentorApi implements MentorApi {
  HttpMentorApi(this._client);
  final ApiClient _client;
  final CancelToken _cancelToken = CancelToken();
  static const _uuid = Uuid();
  Never _error(Object error) {
    String? code;
    if (error is DioException) {
      dynamic data = error.response?.data;
      try {
        if (data is List<int>) data = jsonDecode(utf8.decode(data));
        if (data is String) data = jsonDecode(data);
        if (data is Map &&
            const {
              'operation_pending',
              'result_unavailable',
              'operation_failed',
              'operation_cancelled',
              'operation_conflict',
            }.contains(data['code'])) {
          code = data['code'] as String;
        }
      } catch (_) {}
    }
    throw MentorException(code);
  }

  @override
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  }) async {
    try {
      final r = await _client.dio.get(
        '/api/mentor/operations',
        queryParameters: {
          if (sessionId != null) 'session_id': sessionId,
          if (subjectId != null) 'subject_id': subjectId,
          if (kind != null) 'kind': kind,
        },
        cancelToken: _cancelToken,
      );
      return (_map(r.data)['operations'] as List)
          .cast<Map>()
          .map(MentorOperation.fromJson)
          .toList();
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<MentorOperation?> operation(String requestId) async {
    try {
      final r = await _client.dio.get(
        '/api/mentor/operations/$requestId',
        cancelToken: _cancelToken,
      );
      return MentorOperation.fromJson(_map(r.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _error(e);
    } catch (e) {
      _error(e);
    }
  }

  Map _map(dynamic data) => data is Map ? data : throw const MentorException();

  @override
  void cancel() => _cancelToken.cancel('Mentor context changed');

  @override
  Future<MentorSettings> settings() async {
    try {
      return MentorSettings.fromJson(
        _map(
          (await _client.dio.get(
            '/api/mentor/settings',
            cancelToken: _cancelToken,
          )).data,
        ),
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<MentorSettings> saveSettings(Map<String, Object?> patch) async {
    try {
      return MentorSettings.fromJson(
        _map(
          (await _client.dio.put(
            '/api/mentor/settings',
            data: patch,
            cancelToken: _cancelToken,
          )).data,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const MentorException('settings_conflict');
      }
      _error(e);
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<MentorContextOptions> contextOptions() async {
    try {
      return MentorContextOptions.fromJson(
        _map(
          (await _client.dio.get(
            '/api/mentor/context-options',
            cancelToken: _cancelToken,
          )).data,
        ),
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<List<MentorSession>> sessions() async {
    try {
      final d = _map(
        (await _client.dio.get(
          '/api/mentor/sessions',
          cancelToken: _cancelToken,
        )).data,
      );
      return (d['sessions'] as List)
          .whereType<Map>()
          .map(MentorSession.fromJson)
          .toList();
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<String> createSession(String id) async {
    try {
      return _map(
            (await _client.dio.post(
              '/api/mentor/sessions',
              data: {'id': id},
              cancelToken: _cancelToken,
            )).data,
          )['id']
          as String;
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<List<MentorMessage>> messages(String id) async {
    try {
      final d = _map(
        (await _client.dio.get(
          '/api/mentor/sessions/$id/messages',
          cancelToken: _cancelToken,
        )).data,
      );
      return (d['messages'] as List)
          .whereType<Map>()
          .map(MentorMessage.fromJson)
          .toList();
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<MentorMessage> send(
    String id,
    String text, {
    required String requestId,
    int? settingsRevision,
    MentorContextSelection? context,
  }) async {
    try {
      return MentorMessage.fromJson(
        _map(
          (await _client.dio.post(
            '/api/mentor/sessions/$id/messages',
            data: {
              'request_id': requestId,
              'text': text,
              if (settingsRevision != null) 'settings_revision': settingsRevision,
              if (context != null && !context.isEmpty) 'context': context.toJson(),
            },
            cancelToken: _cancelToken,
            options: Options(receiveTimeout: const Duration(seconds: 55)),
          )).data,
        ),
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      await _client.dio.delete(
        '/api/mentor/sessions/$id',
        cancelToken: _cancelToken,
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<void> saveKey(String provider, String key) async {
    try {
      final origin = Uri.base.resolve(_client.dio.options.baseUrl);
      if (origin.scheme != 'https') throw const MentorException();
      await _client.dio.put(
        '/api/mentor/keys/$provider',
        data: {'key': key},
        cancelToken: _cancelToken,
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<void> deleteKey(String provider) async {
    try {
      await _client.dio.delete(
        '/api/mentor/keys/$provider',
        cancelToken: _cancelToken,
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<void> testProvider(String provider) async {
    try {
      await _client.dio.post(
        '/api/mentor/test/$provider',
        cancelToken: _cancelToken,
        data: {'request_id': _uuid.v4()},
        options: Options(receiveTimeout: const Duration(seconds: 55)),
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<List<MentorVoiceChoice>> refreshVoices() async {
    try {
      final d = _map(
        (await _client.dio.post(
          '/api/mentor/voices',
          cancelToken: _cancelToken,
          data: {'request_id': _uuid.v4()},
          options: Options(receiveTimeout: const Duration(seconds: 55)),
        )).data,
      );
      return (d['voices'] as List)
          .whereType<Map>()
          .map(MentorVoiceChoice.fromJson)
          .toList();
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<String> transcribe(
    Uint8List bytes,
    String contentType,
    double duration, {
    required String requestId,
  }) async {
    try {
      final r = await _client.dio.post(
        '/api/mentor/stt',
        cancelToken: _cancelToken,
        data: Stream.fromIterable([bytes]),
        options: Options(
          contentType: contentType,
          receiveTimeout: const Duration(seconds: 55),
          headers: {
            'X-Request-ID': requestId,
            'X-Audio-Duration': duration.toStringAsFixed(1),
          },
        ),
      );
      return _map(r.data)['text'] as String;
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<Uint8List> speech(String id, {required String requestId}) async {
    try {
      final r = await _client.dio.post(
        '/api/mentor/messages/$id/tts',
        cancelToken: _cancelToken,
        data: {'request_id': requestId},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 55),
        ),
      );
      return Uint8List.fromList(r.data as List<int>);
    } catch (e) {
      _error(e);
    }
  }
}
