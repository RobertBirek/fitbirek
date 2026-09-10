import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/measurements_table.dart';

part 'measurements_dao.g.dart';

@DriftAccessor(tables: [Measurements])
class MeasurementsDao extends DatabaseAccessor<AppDatabase>
    with _$MeasurementsDaoMixin {
  MeasurementsDao(super.db);

  Future<int> addMeasurement(MeasurementsCompanion measurement) {
    return into(measurements).insert(measurement);
  }

  Stream<List<MeasurementData>> watchAll() {
    return (select(measurements)
          ..where((t) => t.deletedAtUtc.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.data),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<MeasurementData?> getLatest() async {
    final rows =
        await (select(measurements)
              ..where((t) => t.deletedAtUtc.isNull())
              ..orderBy([
                (t) => OrderingTerm.desc(t.data),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first;
  }
}
