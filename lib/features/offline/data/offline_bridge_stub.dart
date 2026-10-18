import 'offline_bridge.dart';

OfflineBridge createOfflineBridge() => UnsupportedOfflineBridge();

class UnsupportedOfflineBridge implements OfflineBridge {
  @override
  Future<Object?> status() async => {
    'protocolVersion': 1,
    'state': 'unsupported',
    'packageId': null,
    'totalFiles': 0,
    'cachedFiles': 0,
    'totalBytes': 0,
    'cachedBytes': 0,
    'errorCode': null,
    'message': null,
  };
  @override
  Future<Object?> prepare(String expectedPackageId) => status();
  @override
  Future<Object?> cancel() => status();
}
