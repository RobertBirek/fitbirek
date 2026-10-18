import 'package:fitbirek_training/features/offline/data/offline_bridge.dart';

/// Compile-only regression probe: dart2js must select the real web adapter.
/// Never execute this program against an app: prepare is deliberately reachable
/// so the compiler also checks its required JS object argument.
Future<void> main() async {
  final bridge = createOfflineBridge();
  for (final response in [
    await bridge.status(),
    await bridge.prepare('compile-only-do-not-run'),
    await bridge.cancel(),
  ]) {
    if (response is! Map) {
      throw const FormatException('Expected a JSON-serializable object');
    }
  }
}
