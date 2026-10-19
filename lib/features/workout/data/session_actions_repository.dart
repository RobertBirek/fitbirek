import 'package:drift/drift.dart';
import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_quarantine.dart';
import '../../../core/sync/sync_store.dart';
import '../../auth/providers/auth_providers.dart';
import 'workout_repository.dart';

class SessionConflict extends StateError {
  SessionConflict()
    : super(
        'Trening, szkic, konto lub synchronizacja zmieniły się. Otwórz aktualny trening ponownie.',
      );
}

/// Snapshot shown BEFORE confirmation; no implicit refresh at commit.
class SessionEdit {
  SessionEdit(this.row, this.sets, this.drafts, this.binding, this.epoch);
  final WorkoutSessionData row;
  final List<SetLogData> sets;
  final List<WorkoutDraftData> drafts;
  final SyncStateData binding;
  final int epoch;
}

class SessionActionsRepository {
  SessionActionsRepository(this.db, this.authority);
  final AppDatabase db;
  final CachedAuthWriteAuthority authority;

  Future<void> _owns(SessionEdit edit) async {
    final binding = await db.syncDao.readState();
    if (authority.epoch != edit.epoch ||
        (authority.state != null &&
            (!authority.state!.isSignedIn ||
                authority.state!.accountId != edit.binding.accountId)) ||
        binding?.offlineAccess != true ||
        binding?.accountId != edit.binding.accountId ||
        binding?.deviceId != edit.binding.deviceId) {
      throw SessionConflict();
    }
  }

  Future<SessionEdit> capture(int id) {
    final epoch = authority.epoch;
    return db.transaction(() async {
      final binding = await db.syncDao.readState();
      final row = await db.workoutDao.getSession(id);
      if (binding == null ||
          !binding.offlineAccess ||
          row == null ||
          row.deletedAtUtc != null) {
        throw SessionConflict();
      }
      final sets = await db.workoutDao.getSetsForSession(id);
      final drafts = await (db.select(
        db.workoutDrafts,
      )..where((d) => d.sessionSyncId.equals(row.syncId))).get();
      final edit = SessionEdit(
        row,
        List.unmodifiable(sets),
        List.unmodifiable(drafts),
        binding,
        epoch,
      );
      await check(edit);
      return edit;
    });
  }

  Future<void> check(SessionEdit edit) async {
    await _owns(edit);
    final row = await db.workoutDao.getSession(edit.row.id);
    final sets = await db.workoutDao.getSetsForSession(edit.row.id);
    final drafts = await (db.select(
      db.workoutDrafts,
    )..where((d) => d.sessionSyncId.equals(edit.row.syncId))).get();
    bool same(List<Object> a, List<Object> b) =>
        a.length == b.length &&
        List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
    if (row != edit.row ||
        row?.deletedAtUtc != null ||
        !same(sets, edit.sets) ||
        !same(drafts, edit.drafts) ||
        drafts.any((d) => d.accountId != edit.binding.accountId)) {
      throw SessionConflict();
    }
    final keys = {
      'workoutSession:${edit.row.syncId}',
      for (final s in sets) 'workoutSet:${s.syncId}',
    };
    final deferred = await db.select(db.syncDeferredRecords).get();
    // A quarantined/deferred NEW child may not have a visible set row yet.
    // Its parent UUID still makes it part of this deletion's conflict scope.
    bool unseenChild(SyncDeferredRecordData d) {
      final raw = jsonDecode(d.recordJson);
      if (raw is! Map) return d.entityType == 'workoutSet';
      if ((raw['accountId'] != null &&
              raw['accountId'] != edit.binding.accountId) ||
          raw['recovered'] == true) {
        return false;
      }
      final record = raw['raw'] is Map ? raw['raw'] as Map : raw;
      final payload = record['payload'];
      return (d.entityType == 'workoutSet' ||
              record['entityType'] == 'workoutSet') &&
          payload is Map &&
          payload['sessionSyncId'] == edit.row.syncId;
    }

    for (final op in await db.syncDao.pendingOperations()) {
      if (op.entityType == SyncEntityType.workoutSet &&
          op.payload['sessionSyncId'] == edit.row.syncId) {
        keys.add('workoutSet:${op.entityId}');
      }
    }
    final held = await SyncQuarantine(
      db,
      SyncStore(db),
    ).heldKeys(edit.binding.accountId);
    if (deferred.any(
          (d) =>
              keys.contains('${d.entityType}:${d.entityId}') || unseenChild(d),
        ) ||
        held.any(keys.contains)) {
      throw SessionConflict();
    }
    await _owns(edit);
  }

  Future<void> delete(SessionEdit edit) => db.transaction(() async {
    await check(edit);
    final now = DateTime.now().toUtc();
    for (final s in edit.sets) {
      await (db.update(db.setsLog)..where((t) => t.id.equals(s.id))).write(
        SetsLogCompanion(deletedAtUtc: Value(now), updatedAtUtc: Value(now)),
      );
      await db.syncDao.enqueueDelete(
        entityType: SyncEntityType.workoutSet,
        entityId: s.syncId,
        baseVersion: s.syncVersion,
        payload: {
          'sessionSyncId': edit.row.syncId,
          'cwiczenieId': s.cwiczenieId,
          'nazwaCwiczeniaPl': s.nazwaCwiczeniaPl,
          'numerSerii': s.numerSerii,
          'ciezarKg': s.ciezarKg,
          'powtorzenia': s.powtorzenia,
          'czasSekund': s.czasSekund,
          'rpe': s.rpe,
          'timestamp': s.timestamp.toUtc().toIso8601String(),
          if (s.side != null) 'side': s.side,
          if (s.variantId != null) ...{
            'variantId': s.variantId,
            'variantLabel': s.variantLabel,
          },
        },
      );
    }
    final s = edit.row;
    await db.workoutDao.updateSession(
      s.id,
      WorkoutSessionsCompanion(
        deletedAtUtc: Value(now),
        updatedAtUtc: Value(now),
      ),
    );
    await db.syncDao.enqueueDelete(
      entityType: SyncEntityType.workoutSession,
      entityId: s.syncId,
      baseVersion: s.syncVersion,
      payload: {
        'dataStart': s.dataStart.toUtc().toIso8601String(),
        'dataKoniec': s.dataKoniec?.toUtc().toIso8601String(),
        'czasTrwaniaSekund': s.czasTrwaniaSekund,
        'notatka': s.notatka,
      },
    );
    await (db.delete(
      db.workoutDrafts,
    )..where((d) => d.sessionSyncId.equals(s.syncId))).go();
    await _owns(edit);
  });

  Future<void> finish(
    SessionEdit edit, {
    String? note,
    bool preserveRecordedDuration = true,
    bool Function()? guard,
  }) => db.transaction(() async {
    await check(edit);
    await WorkoutRepository(db).finishSession(
      edit.row.id,
      edit.row.dataStart,
      expectedSyncId: edit.row.syncId,
      accountId: edit.binding.accountId,
      note: note,
      preserveRecordedDuration: preserveRecordedDuration,
      guard: () => authority.epoch == edit.epoch && (guard?.call() ?? true),
    );
    await _owns(edit);
  });
}
