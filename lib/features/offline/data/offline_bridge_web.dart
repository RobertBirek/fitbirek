import 'dart:js_interop';

import 'offline_bridge.dart';

@JS('window.fitOffline')
external JSObject? get _bridge;
@JS('window.fitOffline.status')
external JSPromise<JSAny?> _status();
@JS('window.fitOffline.prepare')
external JSPromise<JSAny?> _prepare(_PrepareOptions options);
@JS('window.fitOffline.cancel')
external JSPromise<JSAny?> _cancel();

extension type _PrepareOptions._(JSObject _) implements JSObject {
  external factory _PrepareOptions({required JSString packageId});
}

OfflineBridge createOfflineBridge() => _WebOfflineBridge();

class _WebOfflineBridge implements OfflineBridge {
  Future<Object?> _call(JSPromise<JSAny?> Function() operation) async {
    if (_bridge == null) {
      // Bridge/controller may not be installed yet: retry, never claim ready.
      return {
        'protocolVersion': 1,
        'state': 'notReady',
        'packageId': null,
        'totalFiles': 0,
        'cachedFiles': 0,
        'totalBytes': 0,
        'cachedBytes': 0,
        'errorCode': 'bridgeUnavailable',
        'message': null,
      };
    }
    return (await operation().toDart).dartify();
  }

  @override
  Future<Object?> status() => _call(() => _status());
  @override
  Future<Object?> prepare(String expectedPackageId) =>
      _call(() => _prepare(_PrepareOptions(packageId: expectedPackageId.toJS)));
  @override
  Future<Object?> cancel() => _call(() => _cancel());
}
