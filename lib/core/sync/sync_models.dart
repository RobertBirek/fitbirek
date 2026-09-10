/// User-owned entities understood by the generic FitBirek sync API.
enum SyncEntityType {
  profile,
  workoutSession,
  workoutSet,
  mood,
  measurement,
  fitnessTest,
  personalRecord,
  workoutPlan,
  exerciseFavorite,
}

extension SyncEntityTypeWireName on SyncEntityType {
  String get wireName => switch (this) {
    SyncEntityType.profile => 'profile',
    SyncEntityType.workoutSession => 'workoutSession',
    SyncEntityType.workoutSet => 'workoutSet',
    SyncEntityType.mood => 'mood',
    SyncEntityType.measurement => 'measurement',
    SyncEntityType.fitnessTest => 'fitnessTest',
    SyncEntityType.personalRecord => 'personalRecord',
    SyncEntityType.workoutPlan => 'workoutPlan',
    SyncEntityType.exerciseFavorite => 'exerciseFavorite',
  };
}

SyncEntityType syncEntityTypeFromWireName(String wireName) {
  return SyncEntityType.values.firstWhere(
    (entityType) => entityType.wireName == wireName,
    orElse: () => throw FormatException('Unknown sync entity type: $wireName'),
  );
}

/// Typed representation of an outbox entry and the API push payload.
class SyncOperation {
  const SyncOperation({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.baseVersion,
    required this.payload,
    required this.deleted,
    this.preserveLocal = false,
  });

  final String operationId;
  final SyncEntityType entityType;
  final String entityId;
  final int baseVersion;
  final Map<String, Object?> payload;
  final bool deleted;

  /// Local restore intent. Never sent as part of the API payload.
  final bool preserveLocal;

  factory SyncOperation.fromPersisted({
    required String operationId,
    required String entityType,
    required String entityId,
    required int baseVersion,
    required Map<String, Object?> payload,
    required bool deleted,
    bool preserveLocal = false,
  }) {
    return SyncOperation(
      operationId: operationId,
      entityType: syncEntityTypeFromWireName(entityType),
      entityId: entityId,
      baseVersion: baseVersion,
      payload: payload,
      deleted: deleted,
      preserveLocal: preserveLocal,
    );
  }

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'entityType': entityType.wireName,
    'entityId': entityId,
    'baseVersion': baseVersion,
    'payload': payload,
    'deleted': deleted,
  };
}
