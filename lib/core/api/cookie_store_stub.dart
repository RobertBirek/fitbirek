import 'package:dio/dio.dart';
import 'cookie_store_base.dart';
export 'cookie_store_base.dart';

class UnsupportedApiCookieStore implements ApiCookieStore {
  @override
  int generation = 0;
  @override
  Future<void> initialize() async {}
  @override
  String? get cookieHeader => null;
  @override
  String? get csrfToken => null;
  @override
  Future<void> save(Headers headers, {required int generation}) async {}
  @override
  Future<void> clear() async {
    generation++;
  }
}

ApiCookieStore createCookieStore() => UnsupportedApiCookieStore();

String get apiBaseUrl => 'https://fit.birek.online/';

String? get apiOrigin => 'https://fit.birek.online';

String? readCsrfCookie() => null;

void configureWebCredentials(Dio dio) {}
