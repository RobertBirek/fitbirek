import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

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
  }) {
    return _db.measurementsDao.addMeasurement(
      MeasurementsCompanion.insert(
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
      ),
    );
  }

  Stream<List<MeasurementData>> watchAll() => _db.measurementsDao.watchAll();

  Future<MeasurementData?> getLatest() => _db.measurementsDao.getLatest();
}
