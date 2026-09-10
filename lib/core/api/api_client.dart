import 'package:dio/dio.dart';

import 'cookie_store.dart';

typedef CsrfTokenReader = String? Function();

/// Same-origin API client that carries browser credentials and CSRF protection.
class ApiClient {
  ApiClient(
    this.dio, {
    CsrfTokenReader? csrfTokenReader,
    ApiCookieStore? cookieStore,
  }) : _csrfTokenReader = csrfTokenReader ?? readCsrfCookie,
       _cookieStore = cookieStore ?? createCookieStore() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            if (_isTrustedApi(options)) {
              await _cookieStore.initialize();
              options.extra[_epoch] = _cookieStore.generation;
              if (options.extra[_logout] != true) {
                final cookieHeader = _cookieStore.cookieHeader;
                if (cookieHeader != null) {
                  options.headers['Cookie'] = cookieHeader;
                }
                if (_isApiMutation(options)) {
                  final csrf = _csrfTokenReader() ?? _cookieStore.csrfToken;
                  if (csrf != null) options.headers['X-CSRF-Token'] = csrf;
                }
              }
              if (_isApiMutation(options) && apiOrigin != null) {
                options.headers['Origin'] = apiOrigin;
              }
            }
            handler.next(options);
          } catch (error, stack) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
                stackTrace: stack,
              ),
            );
          }
        },
        onResponse: (response, handler) async {
          try {
            await _cacheCookies(response);
            handler.next(response);
          } catch (error, stack) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: error,
                stackTrace: stack,
              ),
            );
          }
        },
        onError: (error, handler) async {
          try {
            final options = error.requestOptions;
            if (error.response?.statusCode == 401 &&
                _isTrustedApi(options) &&
                options.extra[_epoch] == _cookieStore.generation &&
                options.extra[_logout] != true) {
              await _cookieStore.clear();
            } else if (error.response != null) {
              await _cacheCookies(error.response!);
            }
            handler.next(error);
          } catch (storageError, stack) {
            handler.next(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: storageError,
                stackTrace: stack,
              ),
            );
          }
        },
      ),
    );
  }

  factory ApiClient.sameOrigin() {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    configureWebCredentials(dio);
    return ApiClient(dio);
  }

  final Dio dio;
  final CsrfTokenReader _csrfTokenReader;
  final ApiCookieStore _cookieStore;
  static const _epoch = 'fitCookieGeneration';
  static const _logout = 'fitExplicitLogout';

  Future<Response<dynamic>> get(String path) => dio.get(path);

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return dio.post(path, data: data);
  }

  Future<Response<dynamic>> logout() async {
    await _cookieStore.initialize();
    final cookie = _cookieStore.cookieHeader;
    final csrf = _csrfTokenReader() ?? _cookieStore.csrfToken;
    // Keep only this request's transient snapshot for server revocation. The
    // secure store is empty before any network wait, including offline logout.
    await _cookieStore.clear();
    return dio.post(
      '/api/auth/logout',
      options: Options(
        extra: {_logout: true},
        headers: {
          if (cookie != null) 'Cookie': cookie,
          if (csrf != null) 'X-CSRF-Token': csrf,
        },
      ),
    );
  }

  Future<void> _cacheCookies(Response<dynamic> response) async {
    final options = response.requestOptions;
    if (_isTrustedApi(options) && options.extra[_logout] != true) {
      await _cookieStore.save(
        response.headers,
        generation: options.extra[_epoch] as int,
      );
    }
  }

  bool _isTrustedApi(RequestOptions options) {
    if (!options.uri.path.startsWith('/api/')) return false;
    return apiOrigin == null ||
        options.uri.origin == Uri.parse(apiOrigin!).origin;
  }

  bool _isApiMutation(RequestOptions options) {
    const mutationMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};
    return mutationMethods.contains(options.method) &&
        options.path.startsWith('/api/');
  }
}
