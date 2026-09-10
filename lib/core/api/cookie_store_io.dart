import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cookie_store_base.dart';
export 'cookie_store_base.dart';

class NativeApiCookieStore implements ApiCookieStore {
  NativeApiCookieStore({
    FlutterSecureStorage? storage,
    DateTime Function()? clock,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _clock = clock ?? DateTime.now;

  static const _key = 'fitbirek.apiCookies.v1';
  static const _names = {'fit_session', 'fit_csrf'};
  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;
  final Map<String, ({String value, DateTime expires})> _cookies = {};
  Future<void> _pending = Future.value();
  bool _loaded = false;
  int _generation = 0;
  @override
  int get generation => _generation;

  Future<void> _serialize(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  bool _expire() {
    final count = _cookies.length;
    final now = _clock().toUtc();
    _cookies.removeWhere((_, cookie) => !cookie.expires.isAfter(now));
    return count != _cookies.length;
  }

  Future<void> _persist() async {
    if (_cookies.isEmpty) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'version': 1,
          'cookies': {
            for (final entry in _cookies.entries)
              entry.key: {
                'value': entry.value.value,
                'expiresAt': entry.value.expires.millisecondsSinceEpoch,
              },
          },
        }),
      );
    }
  }

  Future<void> _load() async {
    if (!_loaded) {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        try {
          final json = jsonDecode(raw) as Map;
          if (json['version'] != 1) {
            throw const FormatException('Cookie storage version');
          }
          final cookies = json['cookies'] as Map;
          for (final name in _names) {
            final item = cookies[name];
            if (item == null) continue;
            final value = item['value'] as String;
            if (value.isEmpty || RegExp(r'[;\r\n]').hasMatch(value)) {
              throw const FormatException('Cookie storage value');
            }
            _cookies[name] = (
              value: value,
              expires: DateTime.fromMillisecondsSinceEpoch(
                item['expiresAt'] as int,
                isUtc: true,
              ),
            );
          }
        } catch (_) {
          _cookies.clear();
          await _storage.delete(key: _key);
        }
      }
      _loaded = true;
    }
    if (_expire()) await _persist();
  }

  @override
  Future<void> initialize() => _serialize(_load);

  @override
  String? get cookieHeader {
    _expire();
    if (_cookies.isEmpty) return null;
    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value.value}')
        .join('; ');
  }

  @override
  String? get csrfToken {
    _expire();
    return _cookies['fit_csrf']?.value;
  }

  @override
  Future<void> save(Headers headers, {required int generation}) =>
      _serialize(() async {
        await _load();
        if (generation != _generation) return;
        var changed = false;
        for (final header in headers['set-cookie'] ?? const <String>[]) {
          Cookie cookie;
          try {
            cookie = Cookie.fromSetCookieValue(header);
          } on FormatException {
            continue;
          }
          if (!_names.contains(cookie.name)) continue;
          final now = _clock().toUtc();
          // Legacy backend responses were session cookies without expiry. Bound
          // their native persistence to the backend's default 24-hour lifetime.
          final expires = cookie.maxAge != null
              ? now.add(Duration(seconds: cookie.maxAge!))
              : cookie.expires?.toUtc() ?? now.add(const Duration(hours: 24));
          if (cookie.value.isEmpty || !expires.isAfter(now)) {
            _cookies.remove(cookie.name);
          } else {
            _cookies[cookie.name] = (value: cookie.value, expires: expires);
          }
          changed = true;
        }
        if (changed) await _persist();
      });

  @override
  Future<void> clear() {
    _generation++;
    _cookies.clear();
    return _serialize(() async {
      _cookies.clear();
      _loaded = true;
      await _storage.delete(key: _key);
    });
  }
}

ApiCookieStore createCookieStore() => NativeApiCookieStore();

String get apiBaseUrl => 'https://fit.birek.online/';

String? get apiOrigin => 'https://fit.birek.online';

String? readCsrfCookie() => null;

void configureWebCredentials(Dio dio) {}
