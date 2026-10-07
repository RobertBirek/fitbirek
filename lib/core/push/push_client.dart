abstract interface class PushClient {
  Future<Map<String, dynamic>> status(String accountId);
  Future<Map<String, dynamic>> enable(
    String publicKey,
    Map<String, bool> categories,
    String accountId,
  );
  Future<Map<String, dynamic>> save(Map<String, bool> categories);
  Future<Map<String, dynamic>> disable();
  Future<Map<String, dynamic>> test();
  Future<void> logout();
}
