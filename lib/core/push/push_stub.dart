import 'push_client.dart';

PushClient createPushClient() => _UnsupportedPush();

class _UnsupportedPush implements PushClient {
  @override
  Future<Map<String, dynamic>> status(String accountId) async => {
    'supported': false,
  };
  @override
  Future<Map<String, dynamic>> enable(
    String key,
    Map<String, bool> categories,
    String accountId,
  ) => status(accountId);
  @override
  Future<Map<String, dynamic>> save(Map<String, bool> categories) => status('');
  @override
  Future<Map<String, dynamic>> disable() => status('');
  @override
  Future<Map<String, dynamic>> test() => status('');
  @override
  Future<void> logout() async {}
}
