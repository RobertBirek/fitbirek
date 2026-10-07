import 'dart:typed_data';

import 'mentor_voice_types.dart';

class MentorVoice {
  bool get supported => false;

  Future<void> startRecording() => _unsupported();
  Future<MentorRecording> stopRecording() => _unsupported();
  void cancelRecording() {}
  Future<void> preparePlayback(Uint8List bytes) => _unsupported();
  Future<void> play() => _unsupported();
  void stopPlayback() {}
  void dispose() {}

  Future<T> _unsupported<T>() => Future<T>.error(
    UnsupportedError(
      'Nagrywanie głosu nie jest obsługiwane na tej platformie.',
    ),
  );
}
