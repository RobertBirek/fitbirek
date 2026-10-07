import '../../../core/api/api_client.dart';

class HealthIntegrationStatus {
  const HealthIntegrationStatus({
    required this.enabled,
    this.createdAt,
    this.lastImportAt,
  });
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? lastImportAt;
  factory HealthIntegrationStatus.fromJson(Map data) => HealthIntegrationStatus(
    enabled: data['enabled'] as bool,
    createdAt: data['createdAt'] == null
        ? null
        : DateTime.parse(data['createdAt'] as String),
    lastImportAt: data['lastImportAt'] == null
        ? null
        : DateTime.parse(data['lastImportAt'] as String),
  );
}

/// A transient response, never held in providers, persistence or diagnostics.
class HealthIntegrationToken {
  HealthIntegrationToken({required this.status, required String token})
    : _token = token;
  final HealthIntegrationStatus status;
  String? _token;
  String get token => _token ?? '';
  void dispose() => _token = null;
}

class HealthIntegrationException implements Exception {
  const HealthIntegrationException([String? ignored]);
  @override
  String toString() => 'Integracja niedostępna. Sprawdź połączenie i sesję.';
}

abstract class HealthIntegrationApi {
  Future<HealthIntegrationStatus> getStatus();
  Future<HealthIntegrationToken> generateToken();
  Future<HealthIntegrationStatus> revoke();
}

class HttpHealthIntegrationApi implements HealthIntegrationApi {
  HttpHealthIntegrationApi(this.client);
  final ApiClient client;
  static const path = '/api/integrations/apple-health';
  @override
  Future<HealthIntegrationStatus> getStatus() async {
    try {
      return HealthIntegrationStatus.fromJson(
        (await client.get(path)).data as Map,
      );
    } catch (_) {
      throw const HealthIntegrationException();
    }
  }

  @override
  Future<HealthIntegrationToken> generateToken() async {
    try {
      final response = await client.post(
        '$path/token',
        data: {'consent': true},
      );
      final data = response.data as Map;
      final token = data.remove('token');
      if (token is! String || token.isEmpty) {
        throw const HealthIntegrationException();
      }
      return HealthIntegrationToken(
        status: HealthIntegrationStatus.fromJson(data),
        token: token,
      );
    } catch (_) {
      throw const HealthIntegrationException();
    }
  }

  @override
  Future<HealthIntegrationStatus> revoke() async {
    try {
      return HealthIntegrationStatus.fromJson(
        (await client.dio.delete('$path/token')).data as Map,
      );
    } catch (_) {
      throw const HealthIntegrationException();
    }
  }
}
