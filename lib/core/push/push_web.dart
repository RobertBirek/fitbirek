import 'dart:convert';
import 'dart:js_interop';

import 'push_client.dart';

@JS('fitPush.status')
external JSPromise<JSString> _status(JSString accountId);
@JS('fitPush.enable')
external JSPromise<JSString> _enable(
  JSString key,
  JSString categories,
  JSString accountId,
);
@JS('fitPush.save')
external JSPromise<JSString> _save(JSString categories);
@JS('fitPush.disable')
external JSPromise<JSString> _disable();
@JS('fitPush.test')
external JSPromise<JSString> _test();
@JS('fitPush.logout')
external JSPromise<JSString> _logout();

PushClient createPushClient() => _BrowserPush();

class _BrowserPush implements PushClient {
  Future<Map<String, dynamic>> _decode(JSPromise<JSString> result) async =>
      jsonDecode((await result.toDart).toDart) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> status(String accountId) =>
      _decode(_status(accountId.toJS));
  @override
  Future<Map<String, dynamic>> enable(
    String key,
    Map<String, bool> categories,
    String accountId,
  ) => _decode(_enable(key.toJS, jsonEncode(categories).toJS, accountId.toJS));
  @override
  Future<Map<String, dynamic>> save(Map<String, bool> categories) =>
      _decode(_save(jsonEncode(categories).toJS));
  @override
  Future<Map<String, dynamic>> disable() => _decode(_disable());
  @override
  Future<Map<String, dynamic>> test() => _decode(_test());
  @override
  Future<void> logout() async {
    await _logout().toDart;
  }
}
