import 'dart:typed_data';

class MentorRecording {
  const MentorRecording({
    required this.bytes,
    required this.contentType,
    required this.durationSeconds,
  });

  final Uint8List bytes;
  final String contentType;
  final double durationSeconds;
}
