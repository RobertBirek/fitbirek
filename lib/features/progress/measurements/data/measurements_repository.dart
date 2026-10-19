import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../core/sync/sync_store.dart';
import '../../../../core/sync/sync_quarantine.dart';
import '../../../auth/providers/auth_providers.dart';

class MeasurementConflict implements Exception {}

class MeasurementSyncPending extends MeasurementConflict {
  static const message =
      'Pomiar oczekuje na rozstrzygnięcie synchronizacji. Poczekaj na jej zakończenie lub sprawdź konflikt w stanie synchronizacji, zanim zmienisz albo usuniesz pomiar.';
}

/// Immutable baseline; never refreshed implicitly by save or confirmation.
class MeasurementEdit {
  MeasurementEdit._(this.row, this.binding, this.epoch);
  final MeasurementData row;
  final SyncStateData binding;
  final int? epoch;
}

/// Repozytorium pomiarów ciała.
///
/// Release dependency: rebuild both API and web candidates; deploy the API
/// supporting omitted measurement `data` BEFORE this client. Older APIs would
/// replace the payload without its date. No protocol/schema field is added.
/// This edit-only contract does not recover historic SQL/backup precision.
class MeasurementsRepository {
  MeasurementsRepository(this._db, {this.authority});
  final AppDatabase _db;
  final CachedAuthWriteAuthority? authority;

  bool _owns(int? epoch, String account) =>
      authority?.epoch == epoch &&
      (authority?.state == null ||
          (authority!.state!.isSignedIn &&
              authority!.state!.accountId == account));

  Future<MeasurementEdit> capture(int id) {
    // Capture before opening/queuing a transaction, not in its async callback.
    final epoch = authority?.epoch;
    return _db.transaction(() async {
      final binding = await _db.syncDao.readState();
      final row = await (_db.select(
        _db.measurements,
      )..where((m) => m.id.equals(id))).getSingleOrNull();
      if (binding == null ||
          !binding.offlineAccess ||
          !_owns(epoch, binding.accountId) ||
          row == null ||
          row.deletedAtUtc != null) {
        throw MeasurementConflict();
      }
      await _requireResolvedSync(row, binding.accountId);
      final edit = MeasurementEdit._(row, binding, epoch);
      await _check(edit);
      return edit;
    });
  }

  Future<void> _check(MeasurementEdit edit) async {
    final binding = await _db.syncDao.readState();
    if (!_owns(edit.epoch, edit.binding.accountId) ||
        binding?.offlineAccess != true ||
        binding?.accountId != edit.binding.accountId ||
        binding?.deviceId != edit.binding.deviceId) {
      throw MeasurementConflict();
    }
  }

  Future<void> _requireResolvedSync(MeasurementData row, String account) async {
    final deferred =
        await (_db.select(_db.syncDeferredRecords)..where(
              (r) =>
                  r.entityType.equals(SyncEntityType.measurement.wireName) &
                  r.entityId.equals(row.syncId),
            ))
            .getSingleOrNull();
    // apply() can advance syncVersion without applying the deferred fields or
    // tombstone. Equality is therefore unresolved too, not proof of a snapshot
    // the user has seen. Strictly older snapshots are superseded authority.
    if (deferred != null && deferred.version >= row.syncVersion) {
      throw MeasurementSyncPending();
    }
    final held = await SyncQuarantine(_db, SyncStore(_db)).heldKeys(account);
    if (held.contains('${SyncEntityType.measurement.wireName}:${row.syncId}')) {
      throw MeasurementSyncPending();
    }
  }

  Future<void> updateMeasurement(
    MeasurementEdit edit, {
    required double wagaKg,
    required double? obwodKlatki,
    required double? obwodTalii,
  }) async {
    for (final value in [wagaKg, obwodKlatki, obwodTalii]) {
      if (value != null && (!value.isFinite || value <= 0)) {
        throw ArgumentError('Nieprawidłowy pomiar');
      }
    }
    await _mutate(
      edit,
      MeasurementsCompanion(
        wagaKg: Value(wagaKg),
        obwodKlatki: Value(obwodKlatki),
        obwodTalii: Value(obwodTalii),
      ),
    );
  }

  Future<void> deleteMeasurement(MeasurementEdit edit) => _mutate(edit, null);

  Future<void> _mutate(
    MeasurementEdit edit,
    MeasurementsCompanion? changes,
  ) => _db.transaction(() async {
    await _check(edit);
    final current = await (_db.select(
      _db.measurements,
    )..where((m) => m.id.equals(edit.row.id))).getSingleOrNull();
    if (current != null) {
      await _requireResolvedSync(current, edit.binding.accountId);
    }
    // Generated Drift equality includes UUID, version, timestamps and every field.
    if (current == null ||
        current.deletedAtUtc != null ||
        current != edit.row) {
      throw MeasurementConflict();
    }
    final now = DateTime.now().toUtc();
    var updated = current.copyWithCompanion(
      changes ?? MeasurementsCompanion(deletedAtUtc: Value(now)),
    );
    final payload = _payload(updated);
    if (current.syncVersion > 0) {
      // Requires the server-first measurement omission contract. SQL dates
      // have second precision; only the current live server record owns data.
      // Keep omission in op.payload across retries and conflict rebases.
      payload.remove('data');
    } else {
      final pending = (await _db.syncDao.pendingOperations())
          .where(
            (op) =>
                op.entityType == SyncEntityType.measurement &&
                op.entityId == current.syncId,
          )
          .toList();
      final creates = pending.where(
        (op) => op.baseVersion == 0 && op.payload['data'] is String,
      );
      if (creates.isNotEmpty) {
        // Attempted operations sort first and are never rewritten. Carry the
        // original create timestamp through unsent coalescing and later ACK.
        payload['data'] = creates.first.payload['data'];
      } else if (pending.isEmpty) {
        // No exact authority survives for this legacy local row. Its known
        // SQL date is only a new-create value, never a repair of an old UUID.
        updated = updated.copyWith(syncId: Uuid().v4());
      } else {
        throw MeasurementSyncPending();
      }
    }
    await (_db.update(_db.measurements)..where((m) => m.id.equals(current.id)))
        .write(updated.copyWith(updatedAtUtc: now).toCompanion(false));
    if (changes == null) {
      await _db.syncDao.enqueueDelete(
        entityType: SyncEntityType.measurement,
        entityId: updated.syncId,
        baseVersion: current.syncVersion,
        payload: payload,
      );
    } else {
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.measurement,
        entityId: updated.syncId,
        baseVersion: current.syncVersion,
        payload: payload,
      );
    }
    // A passive auth transition while awaiting SQL must roll back both writes.
    await _check(edit);
  });

  Map<String, Object?> _payload(MeasurementData m) => {
    'data': m.data.toUtc().toIso8601String(),
    'wagaKg': m.wagaKg,
    'obwodKlatki': m.obwodKlatki,
    'obwodTalii': m.obwodTalii,
    'obwodBioder': m.obwodBioder,
    'obwodBicepsuP': m.obwodBicepsuP,
    'obwodBicepsuL': m.obwodBicepsuL,
    'obwodUdaP': m.obwodUdaP,
    'obwodUdaL': m.obwodUdaL,
    'obwodLydkiP': m.obwodLydkiP,
    'obwodLydkiL': m.obwodLydkiL,
    'procentTluszczu': m.procentTluszczu,
    'tetnoSpoczynkowe': m.tetnoSpoczynkowe,
    'cisnienie': m.cisnienie,
    'notatka': m.notatka,
  };

  Future<void> addMeasurement({
    required double wagaKg,
    double? obwodKlatki,
    double? obwodTalii,
    double? obwodBioder,
    double? obwodBicepsuP,
    double? obwodBicepsuL,
    double? obwodUdaP,
    double? obwodUdaL,
    double? obwodLydkiP,
    double? obwodLydkiL,
    double? procentTluszczu,
    int? tetnoSpoczynkowe,
    String? cisnienie,
    String? notatka,
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    final payload = <String, Object?>{
      'data': now.toIso8601String(),
      'wagaKg': wagaKg,
      'obwodKlatki': obwodKlatki,
      'obwodTalii': obwodTalii,
      'obwodBioder': obwodBioder,
      'obwodBicepsuP': obwodBicepsuP,
      'obwodBicepsuL': obwodBicepsuL,
      'obwodUdaP': obwodUdaP,
      'obwodUdaL': obwodUdaL,
      'obwodLydkiP': obwodLydkiP,
      'obwodLydkiL': obwodLydkiL,
      'procentTluszczu': procentTluszczu,
      'tetnoSpoczynkowe': tetnoSpoczynkowe,
      'cisnienie': cisnienie,
      'notatka': notatka,
    };
    await _db.transaction(() async {
      await _db.measurementsDao.addMeasurement(
        MeasurementsCompanion.insert(
          data: Value(now),
          wagaKg: wagaKg,
          obwodKlatki: Value(obwodKlatki),
          obwodTalii: Value(obwodTalii),
          obwodBioder: Value(obwodBioder),
          obwodBicepsuP: Value(obwodBicepsuP),
          obwodBicepsuL: Value(obwodBicepsuL),
          obwodUdaP: Value(obwodUdaP),
          obwodUdaL: Value(obwodUdaL),
          obwodLydkiP: Value(obwodLydkiP),
          obwodLydkiL: Value(obwodLydkiL),
          procentTluszczu: Value(procentTluszczu),
          tetnoSpoczynkowe: Value(tetnoSpoczynkowe),
          cisnienie: Value(cisnienie),
          notatka: Value(notatka),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.measurement,
        entityId: syncId,
        baseVersion: 0,
        payload: payload,
      );
    });
  }

  Stream<List<MeasurementData>> watchAll() => _db.measurementsDao.watchAll();

  Future<MeasurementData?> getLatest() => _db.measurementsDao.getLatest();
}
