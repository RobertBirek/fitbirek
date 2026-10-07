import 'dart:js_interop';
import 'dart:typed_data';

import 'mentor_voice_types.dart';

@JS('fitMentorVoice.isSupported')
external bool _isSupported();
@JS('fitMentorVoice.startRecording')
external JSPromise<JSAny?> _startRecording();
@JS('fitMentorVoice.stopRecording')
external JSPromise<_JsRecording> _stopRecording();
@JS('fitMentorVoice.cancelRecording')
external void _cancelRecording();
@JS('fitMentorVoice.preparePlayback')
external JSPromise<JSAny?> _preparePlayback(JSUint8Array bytes);
@JS('fitMentorVoice.play')
external JSPromise<JSAny?> _play();
@JS('fitMentorVoice.stopPlayback')
external void _stopPlayback();
@JS('fitMentorVoice.dispose')
external void _dispose();

extension type _JsRecording._(JSObject _) implements JSObject {
  external JSUint8Array get bytes;
  external JSString get contentType;
  external JSNumber get durationSeconds;
}

class MentorVoice {
  bool get supported {
    try {
      return _isSupported();
    } catch (_) {
      // A stale offline shell may not have loaded the optional bridge yet.
      return false;
    }
  }

  Future<void> startRecording() async {
    await _startRecording().toDart;
  }

  Future<MentorRecording> stopRecording() async {
    final result = await _stopRecording().toDart;
    return MentorRecording(
      bytes: result.bytes.toDart,
      contentType: result.contentType.toDart,
      durationSeconds: result.durationSeconds.toDartDouble,
    );
  }

  void cancelRecording() {
    try {
      _cancelRecording();
    } catch (_) {
      // Cleanup must also work without the optional browser bridge.
    }
  }

  Future<void> preparePlayback(Uint8List bytes) async {
    await _preparePlayback(bytes.toJS).toDart;
  }

  Future<void> play() async {
    await _play().toDart;
  }

  void stopPlayback() {
    try {
      _stopPlayback();
    } catch (_) {
      // No bridge means no audio to stop.
    }
  }

  void dispose() {
    try {
      _dispose();
    } catch (_) {
      // Classic offline navigation never depends on voice availability.
    }
  }
}
