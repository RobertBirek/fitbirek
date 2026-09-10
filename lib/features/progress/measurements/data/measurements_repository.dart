import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';

/// Repozytorium pomiarów ciała.
class MeasurementsRepository {
  MeasurementsRepository(this._db);
  final AppDatabase _db;

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
