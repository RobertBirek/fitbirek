import 'dart:js_interop';

import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';
import 'cookie_store_base.dart';
export 'cookie_store_base.dart';

class BrowserApiCookieStore implements ApiCookieStore {
  @override
  int generation = 0;
  @override
  Future<void> initialize() async {}
  @override
  String? get cookieHeader => null;
  @override
  String? get csrfToken => readCsrfCookie();
  @override
  Future<void> save(Headers headers, {required int generation}) async {}
  // HttpOnly session cookies remain exclusively browser-owned. Logout's HTTP
  // response clears them; Dart only invalidates in-flight response generations.
  @override
  Future<void> clear() async {
    generation++;
  }
}

ApiCookieStore createCookieStore() => BrowserApiCookieStore();

// Paths already begin with '/'; a '/' base creates a cross-origin '//api/...'.
String get apiBaseUrl => '';

String? get apiOrigin => null;

String? readCsrfCookie() {
  final cookies = _documentCookie;
  if (cookies == null || cookies.isEmpty) return null;
  for (final cookie in cookies.split(';')) {
    final pair = cookie.trim().split('=');
    if (pair.length == 2 && pair.first == 'fit_csrf') return pair.last;
  }
  return null;
}

@JS('document.cookie')
external String? get _documentCookie;

void configureWebCredentials(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
