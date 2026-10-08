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

class MentorModelProfile {
  const MentorModelProfile({
    required this.key,
    required this.identifier,
    required this.label,
    required this.qualityClass,
    required this.costWarning,
  });

  final String key, identifier, label, qualityClass, costWarning;

  factory MentorModelProfile.fromJson(Map<dynamic, dynamic> json) =>
      MentorModelProfile(
        key: json['key'] as String? ?? '',
        identifier: json['identifier'] as String? ?? '',
        label: json['label'] as String? ?? '',
        qualityClass: json['quality_class'] as String? ?? '',
        costWarning: json['cost_warning'] as String? ?? '',
      );
}

class MentorContextConsents {
  const MentorContextConsents({
    this.training = false,
    this.profile = false,
    this.weight = false,
    this.note = false,
    this.appleHealth = false,
  });

  final bool training, profile, weight, note, appleHealth;

  factory MentorContextConsents.fromJson(Map<dynamic, dynamic>? json) =>
      MentorContextConsents(
        training: json?['training'] as bool? ?? false,
        profile: json?['profile'] as bool? ?? false,
        weight: json?['weight'] as bool? ?? false,
        note: json?['note'] as bool? ?? false,
        appleHealth: json?['apple_health'] as bool? ?? false,
      );
}

class MentorContextAvailability {
  const MentorContextAvailability({required this.available, this.summary});

  final bool available;
  final String? summary;

  factory MentorContextAvailability.fromJson(Map<dynamic, dynamic>? json) =>
      MentorContextAvailability(
        available: json?['available'] as bool? ?? false,
        summary: json?['summary'] as String?,
      );
}

class MentorContextWeightOption {
  const MentorContextWeightOption({
    required this.selectionId,
    required this.source,
    required this.summary,
  });

  final String selectionId, source, summary;

  factory MentorContextWeightOption.fromJson(Map<dynamic, dynamic> json) =>
      MentorContextWeightOption(
        selectionId: json['selection_id'] as String,
        source: json['source'] as String,
        summary: json['summary'] as String? ?? '',
      );
}

class MentorContextNoteOption {
  const MentorContextNoteOption({
    required this.selectionId,
    required this.summary,
    required this.preview,
  });

  final String selectionId, summary, preview;

  factory MentorContextNoteOption.fromJson(Map<dynamic, dynamic> json) =>
      MentorContextNoteOption(
        selectionId: json['selection_id'] as String,
        summary: json['summary'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
      );
}

/// Preview values remain in the auto-disposed composer only.
class MentorContextOptions {
  const MentorContextOptions({
    required this.settingsRevision,
    required this.training,
    required this.profile,
    required this.appleHealth,
    required this.weights,
    required this.workoutNotes,
  });

  final int settingsRevision;
  final MentorContextAvailability training, profile, appleHealth;
  final List<MentorContextWeightOption> weights;
  final List<MentorContextNoteOption> workoutNotes;

  factory MentorContextOptions.fromJson(Map<dynamic, dynamic> json) {
    final options = json['options'] as Map? ?? const {};
    return MentorContextOptions(
      settingsRevision: json['settings_revision'] as int? ?? 0,
      training: MentorContextAvailability.fromJson(options['training'] as Map?),
      profile: MentorContextAvailability.fromJson(options['profile'] as Map?),
      appleHealth: MentorContextAvailability.fromJson(
        options['apple_health'] as Map?,
      ),
      weights: (options['weight'] as List? ?? const [])
          .whereType<Map>()
          .map(MentorContextWeightOption.fromJson)
          .toList(),
      workoutNotes: (options['workout_notes'] as List? ?? const [])
          .whereType<Map>()
          .map(MentorContextNoteOption.fromJson)
          .toList(),
    );
  }
}

/// Only booleans and opaque selectors cross the message API boundary.
class MentorContextSelection {
  const MentorContextSelection({
    this.training = false,
    this.profile = false,
    this.appleHealth = false,
    this.weight,
    this.note,
  });

  final bool training, profile, appleHealth;
  final MentorContextWeightOption? weight;
  final MentorContextNoteOption? note;

  bool get isEmpty => !training && !profile && !appleHealth && weight == null && note == null;

  Map<String, Object?> toJson() => {
    'training': training,
    'profile': profile,
    'apple_health': appleHealth,
    if (weight != null)
      'weight': {'source': weight!.source, 'selection_id': weight!.selectionId},
    if (note != null) 'note': {'selection_id': note!.selectionId},
  };
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
    this.persona = '',
    this.revision = 0,
    this.activeModelProfileKey,
    this.modelProfiles = const [],
    this.contextPolicyVersion = 0,
    this.contextConsentsActive = false,
    this.contextConsents = const MentorContextConsents(),
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
  final String persona;
  final int revision;
  final String? activeModelProfileKey;
  final List<MentorModelProfile> modelProfiles;
  final int contextPolicyVersion;
  final bool contextConsentsActive;
  final MentorContextConsents contextConsents;
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
    persona: json['persona'] as String? ?? '',
    revision: json['revision'] as int? ?? 0,
    activeModelProfileKey: json['active_model_profile_key'] as String?,
    modelProfiles: (json['model_profiles'] as List? ?? const [])
        .whereType<Map>()
        .map(MentorModelProfile.fromJson)
        .toList(),
    contextPolicyVersion: json['context_policy_version'] as int? ?? 0,
    contextConsentsActive: json['context_consents_active'] as bool? ?? false,
    contextConsents: MentorContextConsents.fromJson(
      json['context_consents'] as Map?,
    ),
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
