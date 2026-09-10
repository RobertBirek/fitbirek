import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class AuthSession {
  const AuthSession({required this.accountId});

  final String accountId;
}

class AuthFailure implements Exception {
  const AuthFailure();
}

abstract class AuthApi {
  Future<AuthSession?> getSession();
  Future<AuthSession> login({required String email, required String password});
  Future<void> logout();
}

class AuthRepository implements AuthApi {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthSession?> getSession() async {
    try {
      final response = await _apiClient.get('/api/auth/session');
      return _sessionFromResponse(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final session = await getSession();
      if (session == null) throw const AuthFailure();
      return session;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 422 ||
          error.response?.statusCode == 429) {
        throw const AuthFailure();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() => _apiClient.logout();

  AuthSession _sessionFromResponse(dynamic data) {
    if (data is! Map<String, dynamic>) throw const AuthFailure();
    final accountId = data['accountId'];
    if (accountId is! String || accountId.isEmpty) throw const AuthFailure();
    return AuthSession(accountId: accountId);
  }
}
