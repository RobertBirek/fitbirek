import 'package:dio/dio.dart';

/// Shared asynchronous contract; platform implementations own credential access.
abstract interface class ApiCookieStore {
  int get generation;
  String? get cookieHeader;
  String? get csrfToken;
  Future<void> initialize();
  Future<void> save(Headers headers, {required int generation});
  Future<void> clear();
}
