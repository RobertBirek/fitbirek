enum MentorProposalKind { startWorkout, logSet, navigateExercises }

class MentorProposal {
  const MentorProposal({
    required this.id,
    required this.kind,
    this.exerciseId,
    this.weightKg,
    this.reps,
  });

  final String id;
  final MentorProposalKind kind;
  final String? exerciseId;
  final double? weightKg;
  final int? reps;

  bool get isSafeToConfirm => switch (kind) {
    MentorProposalKind.startWorkout => true,
    MentorProposalKind.navigateExercises => true,
    MentorProposalKind.logSet =>
      exerciseId != null &&
          exerciseId!.isNotEmpty &&
          weightKg != null &&
          weightKg!.isFinite &&
          weightKg! >= 0 &&
          weightKg! <= 500 &&
          reps != null &&
          reps! > 0 &&
          reps! <= 100,
  };

  factory MentorProposal.fromJson(Map<dynamic, dynamic> json) {
    final kind = switch (json['kind']) {
      'start_workout' => MentorProposalKind.startWorkout,
      'log_set' => MentorProposalKind.logSet,
      'navigate_exercises' => MentorProposalKind.navigateExercises,
      _ => throw const FormatException('Nieprawidłowa propozycja mentora.'),
    };
    return MentorProposal(
      id: json['id'] as String,
      kind: kind,
      exerciseId: json['exercise_id'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
    );
  }
}

class MentorMessage {
  const MentorMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.proposal,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;
  final MentorProposal? proposal;
  bool get isAssistant => role == 'assistant';

  factory MentorMessage.fromJson(Map<dynamic, dynamic> json) => MentorMessage(
    id: json['id'] as String,
    role: json['role'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    proposal: json['proposal'] is Map
        ? MentorProposal.fromJson(json['proposal'] as Map)
        : null,
  );
}

class MentorSession {
  const MentorSession({required this.id, required this.createdAt});
  final String id;
  final DateTime createdAt;
  factory MentorSession.fromJson(Map<dynamic, dynamic> json) => MentorSession(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class MentorVoiceChoice {
  const MentorVoiceChoice({required this.id, required this.name});
  final String id;
  final String name;
  factory MentorVoiceChoice.fromJson(Map<dynamic, dynamic> json) =>
      MentorVoiceChoice(
        id: json['voice_id'] as String,
        name: json['name'] as String,
      );
}

class MentorSettings {
  const MentorSettings({
    required this.available,
    required this.openAiConfigured,
    required this.elevenLabsConfigured,
    required this.consentText,
    required this.consentVoice,
    required this.memory,
    required this.model,
    required this.ttsModel,
    required this.sttModel,
    required this.voiceId,
    required this.models,
    required this.ttsModels,
    required this.sttModels,
    required this.voices,
    this.limits = const {},
    this.usage = const {},
  });
  final bool available,
      openAiConfigured,
      elevenLabsConfigured,
      consentText,
      consentVoice;
  final String memory, model, ttsModel, sttModel, voiceId;
  final List<String> models, ttsModels, sttModels;
  final List<MentorVoiceChoice> voices;
  final Map<String, int> limits, usage;

  factory MentorSettings.fromJson(Map<dynamic, dynamic> json) => MentorSettings(
    available: json['available'] as bool? ?? false,
    openAiConfigured: json['openai_configured'] as bool? ?? false,
    elevenLabsConfigured: json['elevenlabs_configured'] as bool? ?? false,
    consentText: json['consent_text'] as bool? ?? false,
    consentVoice: json['consent_voice'] as bool? ?? false,
    memory: json['memory'] as String? ?? '',
    model: json['model'] as String? ?? '',
    ttsModel: json['tts_model'] as String? ?? '',
    sttModel: json['stt_model'] as String? ?? '',
    voiceId: json['voice_id'] as String? ?? '',
    limits: Map<String, int>.from(json['limits'] as Map? ?? const {}),
    usage: Map<String, int>.from(json['usage'] as Map? ?? const {}),
    models: List<String>.from(json['models'] as List? ?? const []),
    ttsModels: List<String>.from(json['tts_models'] as List? ?? const []),
    sttModels: List<String>.from(json['stt_models'] as List? ?? const []),
    voices: (json['voices'] as List? ?? const [])
        .whereType<Map>()
        .map(MentorVoiceChoice.fromJson)
        .toList(),
  );
}

class MentorOperation {
  const MentorOperation({
    required this.requestId,
    required this.kind,
    required this.state,
    this.sessionId,
    this.subjectId,
    this.userText,
    this.response,
    this.createdAt,
  });
  final String requestId, kind, state;
  final String? sessionId, subjectId, userText;
  final MentorMessage? response;
  final DateTime? createdAt;
  factory MentorOperation.fromJson(Map json) => MentorOperation(
    requestId: json['request_id'] as String,
    kind: json['kind'] == 'message' ? 'chat' : json['kind'] as String,
    state: json['state'] as String,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    sessionId: json['session_id'] as String?,
    subjectId: json['subject_id'] as String?,
    userText: json['user_text'] as String?,
    response: json['response'] is Map
        ? MentorMessage.fromJson(json['response'] as Map)
        : null,
  );
}
