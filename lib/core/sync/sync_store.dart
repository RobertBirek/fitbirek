import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'sync_models.dart';
import 'user_collections.dart';
import 'profile_payload.dart';
import '../../features/planner/domain/structured_plan.dart';
import '../../features/planner/data/plan_sync_payload.dart';
import '../../features/workout/domain/workout_guidance.dart';

/// Maps the wire UUID identity to device-local integer keys. All callers that
/// apply a page or acknowledgement use a database transaction.
class SyncStore {
  SyncStore(this.db);
  final AppDatabase db;

  // Device-local metadata in the existing deferred envelope, never a wire key
  // or part of an attempted request. The original rejected request stays in
  // outbox until explicit recovery can safely merge its current local intent.
  static const profileCollectionHold = '_profileCollectionConflict';

  Future<Set<String>> heldProfileIds() async {
    final rows = await (db.select(
      db.syncDeferredRecords,
    )..where((r) => r.entityType.equals('profile'))).get();
    return {
      for (final r in rows)
        if ((jsonDecode(r.recordJson) as Map)[profileCollectionHold] != null)
          r.entityId,
    };
  }

  Future<void> holdProfileConflict(
    Map<String, dynamic> record,
    String rejectedOperationId,
  ) async {
    final id = record['entityId'] as String;
    final previous = await _deferred(SyncEntityType.profile, id);
    final old = previous == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(previous.recordJson) as Map);
    final metadata = old?[profileCollectionHold] as Map?;
    final rejected = {
      ...?((metadata?['rejectedOperationIds'] as List?)?.cast<String>()),
      rejectedOperationId,
    };
    await apply({
      ...(previous != null && previous.version > (record['version'] as int)
          ? old!
          : record),
      profileCollectionHold: {
        'rejectedOperationIds': rejected.toList()..sort(),
        'quarantinedRecord': metadata?['quarantinedRecord'] ?? record,
      },
    });
  }

  /// Explicit recovery only, called inside an account-guarded transaction.
  /// Never releases unknown attempted outcomes or sends the confirmed rejected
  /// operation again. All validation precedes deletion of any local intent.
  Future<void> retryHeldProfile(String id) async {
    final deferred = await _deferred(SyncEntityType.profile, id);
    if (deferred == null) {
      throw StateError('Brak wstrzymanego konfliktu profilu.');
    }
    final record = Map<String, dynamic>.from(
      jsonDecode(deferred.recordJson) as Map,
    );
    final hold = record.remove(profileCollectionHold) as Map?;
    if (hold == null || record['deletedAt'] != null) {
      throw StateError('Profil wymaga ręcznej weryfikacji.');
    }
    final rejected = (hold['rejectedOperationIds'] as List)
        .cast<String>()
        .toSet();
    final rows = await db
        .customSelect(
          'SELECT * FROM sync_outbox WHERE entity_type = ? AND entity_id = ? ORDER BY rowid DESC',
          variables: [Variable('profile'), Variable(id)],
        )
        .get();
    if (rows.any(
      (r) =>
          r.read<bool>('deleted') ||
          (r.read<bool>('attempted') &&
              !rejected.contains(r.read<String>('operation_id'))),
    )) {
      throw StateError(
        'Najpierw rozstrzygnij usunięcie lub nieznany wynik próby profilu.',
      );
    }
    final local = await db.userProfileDao.watchProfileOnce();
    if (local == null || local.syncId != id || local.deletedAtUtc != null) {
      throw StateError('Brak aktywnego profilu.');
    }
    final remote = Map<String, dynamic>.from(record['payload'] as Map);
    final merged = Map<String, dynamic>.from(remote);
    var changed = false;
    for (final key in UserCollections.keys) {
      if (remote[key] != null) UserCollections.validate(key, remote[key]);
      final raw = local.toJson()['${key}Json'] as String?;
      final latest = rows
          .map((r) => jsonDecode(r.read<String>('payload_json')) as Map)
          .where((p) => p.containsKey(key))
          .firstOrNull;
      if (raw == null && latest != null && latest[key] == null) {
        merged[key] = null;
        if (remote[key] != null) changed = true;
      } else if (raw != null) {
        final value = UserCollections.merge(key, jsonDecode(raw), remote[key]);
        merged[key] = value;
        if (UserCollections.canonical(value) !=
            UserCollections.canonical(remote[key])) {
          changed = true;
        }
      }
    }
    final preserveLocal =
        rows.any((r) => r.read<bool>('preserve_local')) && !changed;
    final payload = preserveLocal
        ? <String, dynamic>{
            ...profilePayload(local),
            for (final key in UserCollections.keys)
              if (merged.containsKey(key)) key: merged[key],
          }
        : merged;
    // Validate local siblings too, including a corrupt raw column that was not
    // involved in the original remote failure. No partial recovery or clear.
    for (final key in UserCollections.keys) {
      if (payload[key] != null) UserCollections.validate(key, payload[key]);
    }
    await (db.delete(
          db.syncOutbox,
        )..where((o) => o.entityType.equals('profile') & o.entityId.equals(id)))
        .go();
    await _forgetDeferred(SyncEntityType.profile, id, deferred.version);
    await apply({...record, 'payload': payload});
    await db.syncDao.enqueueUpsert(
      entityType: SyncEntityType.profile,
      entityId: id,
      baseVersion: deferred.version,
      payload: payload,
      preserveLocal: preserveLocal,
    );
  }

  TableInfo table(SyncEntityType type) => switch (type) {
    SyncEntityType.profile => db.userProfiles,
    SyncEntityType.workoutSession => db.workoutSessions,
    SyncEntityType.workoutSet => db.setsLog,
    SyncEntityType.mood => db.moodEntries,
    SyncEntityType.measurement => db.measurements,
    SyncEntityType.fitnessTest => db.fitnessTestResults,
    SyncEntityType.personalRecord => db.personalRecords,
    SyncEntityType.workoutPlan => db.workoutPlans,
    SyncEntityType.exerciseFavorite => db.exerciseFavorites,
    SyncEntityType.healthSample => db.healthSamples,
  };

  Future<Map<String, dynamic>?> row(SyncEntityType type, String id) async {
    final t = table(type);
    final result = await db
        .customSelect(
          'SELECT * FROM ${t.actualTableName} WHERE sync_id = ?',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    if (result == null) return null;
    final dynamic mapped = await t.map(result.data);
    return Map<String, dynamic>.from(mapped.toJson() as Map);
  }

  Future<void> version(
    SyncEntityType type,
    String id,
    int version, {
    bool rebasePending = true,
  }) async {
    final acknowledgedVersion = version;
    final t = table(type);
    final current = await row(type, id);
    final known = current?['syncVersion'] as int? ?? 0;
    final preventUndelete =
        type == SyncEntityType.workoutSession &&
        current?['deletedAtUtc'] != null;
    if (known > version) version = known;
    await db.customUpdate(
      'UPDATE ${t.actualTableName} SET sync_version = MAX(sync_version, ?) WHERE sync_id = ?',
      variables: [Variable(version), Variable(id)],
      updates: {t},
    );
    // Only unsent requests can change. Attempted requests are immutable until
    // their exact outcome is known (including across process restarts).
    if (!rebasePending) return;
    var pendingBase = version;
    if (type == SyncEntityType.profile) {
      final deferred = await _deferred(type, id);
      if (deferred != null && acknowledgedVersion < deferred.version) {
        pendingBase = deferred.version - 1;
      }
    }
    await (db.update(db.syncOutbox)..where(
          (o) =>
              o.entityType.equals(type.wireName) &
              o.entityId.equals(id) &
              o.attempted.equals(false) &
              (preventUndelete ? o.deleted.equals(true) : const Constant(true)),
        ))
        .write(SyncOutboxCompanion(baseVersion: Value(pendingBase)));
  }

  Future<void> apply(Map<String, dynamic> record) async {
    final type = syncEntityTypeFromWireName(record['entityType'] as String);
    final id = record['entityId'] as String;
    final v = record['version'] as int;
    final existing = await row(type, id);
    if (existing == null && record['deletedAt'] != null) return;
    if (existing != null && (existing['syncVersion'] as int) > v) {
      return;
    }
    // Deleting an existing plan requires only its sync identity. Retain raw
    // local data even if an older client already stored an invalid structure.
    final planTombstone =
        type == SyncEntityType.workoutPlan && record['deletedAt'] != null;
    final json = planTombstone
        ? Map<String, dynamic>.from(existing!)
        : Map<String, dynamic>.from(record['payload'] as Map);
    json.remove('id');
    json.remove('sesjaId');
    json.addAll({
      'syncId': id,
      'syncVersion': v,
      'updatedAtUtc': record['updatedAt'],
      'deletedAtUtc': record['deletedAt'],
    });
    if (type != SyncEntityType.exerciseFavorite) {
      final max = await db
          .customSelect(
            'SELECT COALESCE(MAX(id), 0) + 1 AS next FROM ${table(type).actualTableName}',
          )
          .getSingle();
      json['id'] =
          existing?['id'] ??
          (type == SyncEntityType.profile ? 1 : max.read<int>('next'));
    }
    var cascadeDelete = false;
    if (type == SyncEntityType.profile) {
      for (final key in UserCollections.keys) {
        final column = '${key}Json';
        if (!json.containsKey(key)) {
          json[column] = existing?[column];
        } else {
          final value = json.remove(key);
          if (value != null && record['deletedAt'] == null) {
            try {
              UserCollections.validate(key, value);
            } on FormatException {
              // Quarantine below, without clearing a valid sibling collection.
            }
          }
          // Quarantine each invalid collection separately. Defensive repository
          // readers report it; ordinary profile/history and cursor remain usable.
          json[column] = value == null ? null : jsonEncode(value);
        }
      }
    }
    if ((type == SyncEntityType.workoutSet ||
            type == SyncEntityType.personalRecord) &&
        record['deletedAt'] == null) {
      UserCollections.validateVariantPair(json);
    }
    if (type == SyncEntityType.workoutSet) {
      final session = await row(
        SyncEntityType.workoutSession,
        json.remove('sessionSyncId') as String,
      );
      if (session == null) throw const FormatException('Missing session UUID');
      json['sesjaId'] = session['id'];
      if (session['deletedAtUtc'] != null && record['deletedAt'] == null) {
        // The backend has no FK cascade. A late child of a removed session
        // stays hidden locally and gets its own durable deletion operation.
        json['deletedAtUtc'] = session['deletedAtUtc'];
        cascadeDelete = true;
      }
    }
    if (type == SyncEntityType.workoutPlan && !planTombstone) {
      final structure = json.remove('structure');
      if (structure != null) {
        StructuredPlan.validateJson(
          structure,
          exerciseIds: json['cwiczeniaIds'],
        );
      }
      json['structureJson'] = structure == null ? null : jsonEncode(structure);
    }
    if (type == SyncEntityType.workoutSession) {
      final guidance = json.remove('guidance');
      if (record['deletedAt'] == null && guidance != null) {
        try {
          WorkoutGuidance.validateJson(guidance);
        } on FormatException {
          // Quarantine the original JSON in this row, not the entire pull page.
          // Defensive readers expose an explicit guidance error while legacy
          // session/set history and the cursor remain usable. New writes and
          // restore still require full validation; no silent legacy conversion.
        }
      }
      json['guidanceJson'] = guidance == null ? null : jsonEncode(guidance);
    }
    for (final key in ['dostepnySprzet', 'cwiczeniaIds']) {
      if (planTombstone) continue;
      if (json.containsKey(key)) json[key] = jsonEncode(json[key] as List);
    }
    // Generated parsers validate required fields and types before writing.
    final Insertable<dynamic> data = switch (type) {
      SyncEntityType.profile => UserProfileData.fromJson(json),
      SyncEntityType.workoutSession => WorkoutSessionData.fromJson(json),
      SyncEntityType.workoutSet => SetLogData.fromJson(json),
      SyncEntityType.mood => MoodEntryData.fromJson(json),
      SyncEntityType.measurement => MeasurementData.fromJson(json),
      SyncEntityType.fitnessTest => FitnessTestResultData.fromJson(json),
      SyncEntityType.personalRecord => PersonalRecordData.fromJson(json),
      SyncEntityType.workoutPlan => WorkoutPlanData.fromJson(json),
      SyncEntityType.exerciseFavorite => ExerciseFavoriteData.fromJson(json),
      SyncEntityType.healthSample => HealthSampleData.fromJson(json),
    };
    // Validate complete payloads even while dirty: a bad page must not advance
    // either the observed version or cursor and become unreconcilable later.
    final dirty =
        await (db.select(db.syncOutbox)..where(
              (o) => o.entityType.equals(type.wireName) & o.entityId.equals(id),
            ))
            .get();
    final previous = await _deferred(type, id);
    final hold = type == SyncEntityType.profile
        ? record[profileCollectionHold] ??
              (previous == null
                  ? null
                  : (jsonDecode(previous.recordJson)
                        as Map)[profileCollectionHold])
        : null;
    if (dirty.isNotEmpty || hold != null) {
      if (previous == null || previous.version <= v) {
        await db
            .into(db.syncDeferredRecords)
            .insertOnConflictUpdate(
              SyncDeferredRecordsCompanion.insert(
                entityType: type.wireName,
                entityId: id,
                version: v,
                recordJson: jsonEncode({
                  ...record,
                  if (hold != null) profileCollectionHold: hold,
                }),
              ),
            );
      }
      if (data is WorkoutSessionData && data.deletedAtUtc != null) {
        // Keep local fields and attempted requests intact, but make the remote
        // deletion effective for transactional write guards and active UI now.
        await (db.update(
          db.workoutSessions,
        )..where((s) => s.syncId.equals(id))).write(
          WorkoutSessionsCompanion(deletedAtUtc: Value(data.deletedAtUtc)),
        );
      }
      // Force the final queued profile edit through CAS too: rebasing it here
      // would silently overwrite remote collection entries before their merge.
      await version(type, id, v, rebasePending: type != SyncEntityType.profile);
      return;
    }
    if (cascadeDelete) {
      await db.syncDao.enqueueDelete(
        entityType: type,
        entityId: id,
        baseVersion: v,
        payload: Map<String, Object?>.from(record['payload'] as Map),
        preserveLocal: true,
      );
    }
    // A remote snapshot replaces nullable fields too. Generated data classes
    // omit nulls for inserts, which otherwise leaves an old deletion marker
    // (or optional value) in place when replaying a later live snapshot.
    final Insertable<dynamic> snapshot = switch (data) {
      UserProfileData value => value.toCompanion(false),
      WorkoutSessionData value => value.toCompanion(false),
      SetLogData value => value.toCompanion(false),
      MoodEntryData value => value.toCompanion(false),
      MeasurementData value => value.toCompanion(false),
      FitnessTestResultData value => value.toCompanion(false),
      PersonalRecordData value => value.toCompanion(false),
      WorkoutPlanData value => value.toCompanion(false),
      ExerciseFavoriteData value => value.toCompanion(false),
      HealthSampleData value => value.toCompanion(false),
      _ => throw StateError('Unknown synchronized data type'),
    };
    await db.into(table(type)).insertOnConflictUpdate(snapshot);
    await _forgetDeferred(type, id, v);
  }

  Future<SyncDeferredRecordData?> _deferred(SyncEntityType type, String id) =>
      (db.select(db.syncDeferredRecords)..where(
            (r) => r.entityType.equals(type.wireName) & r.entityId.equals(id),
          ))
          .getSingleOrNull();

  Future<void> _forgetDeferred(
    SyncEntityType type,
    String id,
    int throughVersion,
  ) async {
    await (db.delete(db.syncDeferredRecords)..where(
          (r) =>
              r.entityType.equals(type.wireName) &
              r.entityId.equals(id) &
              r.version.isSmallerOrEqualValue(throughVersion),
        ))
        .go();
  }

  /// Called in the same transaction as the acknowledgement/conflict outcome.
  /// A newer accepted local mutation supersedes earlier remote snapshots; an
  /// older duplicate only resolves that operation, not the newer server state.
  Future<void> reconcile(
    SyncEntityType type,
    String id, {
    int? acceptedVersion,
    SyncOperation? acceptedOperation,
  }) async {
    final snapshot = await _deferred(type, id);
    if (snapshot == null) return;
    if (type == SyncEntityType.profile &&
        (jsonDecode(snapshot.recordJson) as Map)[profileCollectionHold] !=
            null) {
      return;
    }
    if (acceptedVersion != null && acceptedVersion >= snapshot.version) {
      if (type == SyncEntityType.workoutSession &&
          acceptedOperation != null &&
          !acceptedOperation.deleted) {
        final current = await row(type, id);
        final pendingDeletes =
            await (db.select(db.syncOutbox)..where(
                  (o) =>
                      o.entityType.equals(type.wireName) &
                      o.entityId.equals(id) &
                      o.deleted.equals(true),
                ))
                .get();
        if (current != null &&
            current['deletedAtUtc'] != null &&
            (current['syncVersion'] as int) <= acceptedVersion &&
            pendingDeletes.isEmpty) {
          // An older tombstone in the change log may have temporarily blocked
          // this session before a later, accepted live operation was resolved.
          // Restore only that marker, preserving any later local payload edits.
          await (db.update(db.workoutSessions)
                ..where((s) => s.syncId.equals(id)))
              .write(const WorkoutSessionsCompanion(deletedAtUtc: Value(null)));
          await version(type, id, acceptedVersion);
        }
      }
      await _forgetDeferred(type, id, acceptedVersion);
      return;
    }
    final pending =
        await (db.select(db.syncOutbox)..where(
              (o) => o.entityType.equals(type.wireName) & o.entityId.equals(id),
            ))
            .get();
    if (pending.isNotEmpty) return;
    await apply(
      Map<String, dynamic>.from(jsonDecode(snapshot.recordJson) as Map),
    );
    await _forgetDeferred(type, id, snapshot.version);
  }

  Future<void> enqueueAll({
    bool deleted = false,
    Set<String> profileCollectionClears = const {},
  }) => db.transaction(
    () => _enqueueAll(
      deleted: deleted,
      profileCollectionClears: profileCollectionClears,
    ),
  );

  Future<void> _enqueueAll({
    required bool deleted,
    required Set<String> profileCollectionClears,
  }) async {
    if (profileCollectionClears.any(
      (key) => !UserCollections.keys.contains(key),
    )) {
      throw ArgumentError('Unknown profile collection clear');
    }
    for (final type in SyncEntityType.values) {
      // Restore cannot create/revive server-owned imports or mass-delete them.
      // Explicit sample deletions have their own durable outbox operations.
      if (type == SyncEntityType.healthSample) continue;
      final rows = await db.select(table(type)).get();
      for (final dynamic row in rows) {
        final json = Map<String, dynamic>.from(row.toJson() as Map);
        final id = json.remove('syncId') as String;
        var v = json.remove('syncVersion') as int;
        final tombstone = json.remove('deletedAtUtc') != null;
        json.remove('updatedAtUtc');
        json.remove('id');
        for (final key in [
          'data',
          'dataStart',
          'dataKoniec',
          'dataUtworzenia',
          'timestamp',
        ]) {
          if (json[key] is int) {
            json[key] = DateTime.fromMillisecondsSinceEpoch(
              json[key] as int,
              isUtc: true,
            ).toIso8601String();
          }
        }
        if (type == SyncEntityType.personalRecord && json['side'] == null) {
          json.remove('side');
        }
        if (type == SyncEntityType.profile) {
          if (!deleted && !tombstone) {
            v = await profileWriteBaseVersion(db, id, v);
          }
          UserCollections.columnsToWire(
            json,
            validateLive: !deleted && !tombstone,
          );
          if (!deleted && !tombstone) {
            for (final key in profileCollectionClears) {
              if (!json.containsKey(key)) json[key] = null;
            }
          }
        }
        if (type == SyncEntityType.workoutSet ||
            type == SyncEntityType.personalRecord) {
          if (!deleted && !tombstone) UserCollections.validateVariantPair(json);
          if (json['variantId'] == null) {
            json.remove('variantId');
            json.remove('variantLabel');
          }
        }
        if (type == SyncEntityType.workoutPlan) {
          final structure = json.remove('structureJson') as String?;
          if (deleted || tombstone) {
            await db.syncDao.enqueueDelete(
              entityType: type,
              entityId: id,
              baseVersion: v,
              payload: workoutPlanDeletePayload(row as WorkoutPlanData),
              preserveLocal: true,
            );
            continue;
          }
          if (structure != null) {
            final value = jsonDecode(structure);
            StructuredPlan.validateJson(
              value,
              exerciseIds: jsonDecode(json['cwiczeniaIds'] as String),
            );
            json['structure'] = value;
          }
        }
        if (type == SyncEntityType.workoutSession) {
          final raw = json.remove('guidanceJson') as String?;
          if (!deleted && !tombstone && raw != null) {
            final guidance = WorkoutGuidance.validateJson(jsonDecode(raw));
            json['guidance'] = guidance.toJson();
          }
        }
        if (type == SyncEntityType.workoutSet) {
          // Optional wire field: legacy sets stay unclassified. This only
          // constructs new operations; never rewrites attempted payloads.
          if (json['side'] == null) json.remove('side');
          final session = await db.workoutDao.getSession(
            json.remove('sesjaId') as int,
          );
          if (session == null) throw StateError('Missing session');
          json['sessionSyncId'] = session.syncId;
        }
        for (final key in ['dostepnySprzet', 'cwiczeniaIds']) {
          if (json.containsKey(key)) {
            json[key] = jsonDecode(json[key] as String);
          }
        }
        if (deleted || tombstone) {
          await db.syncDao.enqueueDelete(
            entityType: type,
            entityId: id,
            baseVersion: v,
            payload: json,
            preserveLocal: true,
          );
        } else {
          await db.syncDao.enqueueUpsert(
            entityType: type,
            entityId: id,
            baseVersion: v,
            payload: json,
            preserveLocal: true,
          );
        }
      }
    }
  }
}
