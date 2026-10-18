import 'offline_bridge_stub.dart'
    if (dart.library.js_interop) 'offline_bridge_web.dart'
    as platform;

/// v1 methods return JSON-serializable OBJECTS, not JSON strings.
abstract interface class OfflineBridge {
  Future<Object?> status();

  /// Consent is bound to this exact package; never retry without the argument.
  Future<Object?> prepare(String expectedPackageId);
  Future<Object?> cancel();
}

OfflineBridge createOfflineBridge() => platform.createOfflineBridge();
