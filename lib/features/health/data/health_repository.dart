import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/weight_entry.dart';
import '../../../core/sync/sync_models.dart';

class HealthRepository {
  HealthRepository(this.db);
  final AppDatabase db;

  Stream<List<HealthSampleData>> watchAll() =>
      (db.select(db.healthSamples)
            ..where((s) => s.deletedAtUtc.isNull())
            ..orderBy([(s) => OrderingTerm.desc(s.measuredAt)]))
          .watch();
  Stream<List<HealthSampleData>> watchWeights() =>
      watchAll().map((rows) => rows.where((s) => s.kind == 'weight').toList());
  Stream<HealthSampleData?> watchLatestWeight() =>
      watchWeights().map((s) => s.firstOrNull);
  Stream<List<HealthSampleData>> watchStepsForDay(String day) => watchAll().map(
    (rows) => rows.where((s) => s.kind == 'steps' && s.day == day).toList(),
  );
  Stream<DateTime?> watchLastImportedAt() => watchAll().map(
    (rows) => rows.isEmpty
        ? null
        : rows
              .map((s) => s.importedAt.toUtc())
              .reduce((a, b) => a.isAfter(b) ? a : b),
  );

  static List<WeightEntry> mergeWeights(
    List<MeasurementData> manual,
    List<HealthSampleData> imported,
  ) => [
    for (final m in manual) WeightEntry(date: m.data, kg: m.wagaKg),
    for (final s in imported.where(
      (s) => s.kind == 'weight' && s.deletedAtUtc == null,
    ))
      WeightEntry(
        date: s.measuredAt ?? DateTime.parse(s.day),
        kg: s.value,
        source: s.source,
        sample: s,
      ),
  ]..sort((a, b) => a.date.compareTo(b.date));

  Map<String, Object?> payloadFor(HealthSampleData s) => {
    'kind': s.kind,
    'day': s.day,
    'measuredAt': s.measuredAt?.toUtc().toIso8601String(),
    'value': s.value,
    'source': s.source,
    'method': s.method,
    'importedAt': s.importedAt.toUtc().toIso8601String(),
  };

  Future<void> deleteSample(HealthSampleData sample) =>
      db.transaction(() async {
        final current = await (db.select(
          db.healthSamples,
        )..where((s) => s.syncId.equals(sample.syncId))).getSingleOrNull();
        if (current == null || current.deletedAtUtc != null) return;
        final now = DateTime.now().toUtc();
        await (db.update(
          db.healthSamples,
        )..where((s) => s.id.equals(current.id))).write(
          HealthSamplesCompanion(
            deletedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
        await db.syncDao.enqueueDelete(
          entityType: SyncEntityType.healthSample,
          entityId: current.syncId,
          baseVersion: current.syncVersion,
          payload: payloadFor(current),
          preserveLocal: true,
        );
      });
}
