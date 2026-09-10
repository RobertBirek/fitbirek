import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'sync_models.dart';

/// Maps the wire UUID identity to device-local integer keys. All callers that
/// apply a page or acknowledgement use a database transaction.
class SyncStore {
  SyncStore(this.db);
  final AppDatabase db;

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

  Future<void> version(SyncEntityType type, String id, int version) async {
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
    await (db.update(db.syncOutbox)..where(
          (o) =>
              o.entityType.equals(type.wireName) &
              o.entityId.equals(id) &
              o.attempted.equals(false) &
              (preventUndelete ? o.deleted.equals(true) : const Constant(true)),
        ))
        .write(SyncOutboxCompanion(baseVersion: Value(version)));
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
    final json = Map<String, dynamic>.from(record['payload'] as Map);
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
    for (final key in ['dostepnySprzet', 'cwiczeniaIds']) {
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
    };
    // Validate complete payloads even while dirty: a bad page must not advance
    // either the observed version or cursor and become unreconcilable later.
    final dirty =
        await (db.select(db.syncOutbox)..where(
              (o) => o.entityType.equals(type.wireName) & o.entityId.equals(id),
            ))
            .get();
    if (dirty.isNotEmpty) {
      final previous = await _deferred(type, id);
      if (previous == null || previous.version <= v) {
        await db
            .into(db.syncDeferredRecords)
            .insertOnConflictUpdate(
              SyncDeferredRecordsCompanion.insert(
                entityType: type.wireName,
                entityId: id,
                version: v,
                recordJson: jsonEncode(record),
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
      await version(type, id, v);
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

  Future<void> enqueueAll({bool deleted = false}) async {
    for (final type in SyncEntityType.values) {
      final rows = await db.select(table(type)).get();
      for (final dynamic row in rows) {
        final json = Map<String, dynamic>.from(row.toJson() as Map);
        final id = json.remove('syncId') as String;
        final v = json.remove('syncVersion') as int;
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
        if (type == SyncEntityType.workoutSet) {
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
