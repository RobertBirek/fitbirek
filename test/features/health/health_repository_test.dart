// HealthRepository: czyta próbki Apple Zdrowie z osobnej tabeli Drift, a jedyną
// operacją w sync jaką użytkownik może wykonać na próbce jest jej usunięcie
// (tombstone). Tworzenie/modyfikowanie próbek pochodzi wyłącznie z importu HTTP.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/health/data/health_repository.dart';

Future<HealthSampleData> seedSample(
  AppDatabase db, {
  required String kind,
  required String day,
  DateTime? measuredAt,
  required double value,
  String source = 'Apple Zdrowie',
  String? method,
  DateTime? importedAt,
}) {
  final now = importedAt ?? DateTime.utc(2026, 9, 10, 10);
  return db
      .into(db.healthSamples)
      .insert(
        HealthSamplesCompanion.insert(
          syncId: Value('sample-$kind-$day'),
          kind: kind,
          day: day,
          measuredAt: Value(measuredAt),
          value: value,
          source: source,
          method:
              method ??
              (kind == 'steps' ? 'manual_verified_total' : 'health_sample'),
          importedAt: now,
        ),
      )
      .then((id) async {
        return (db.select(
          db.healthSamples,
        )..where((s) => s.id.equals(id))).getSingle();
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HealthRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HealthRepository(db);
  });

  tearDown(() async => db.close());

  test('schema exposes the separate healthSamples table at version 5', () {
    expect(db.schemaVersion, 7);
    expect(db.healthSamples.actualTableName, 'health_samples');
  });

  test('latest weight ignores steps samples and tombstones', () async {
    await seedSample(
      db,
      kind: 'weight',
      day: '2026-09-09',
      measuredAt: DateTime.utc(2026, 9, 9, 7),
      value: 80.2,
    );
    await seedSample(db, kind: 'steps', day: '2026-09-10', value: 9100);
    await seedSample(
      db,
      kind: 'weight',
      day: '2026-09-10',
      measuredAt: DateTime.utc(2026, 9, 10, 6),
      value: 80.4,
    );

    final latest = await repo.watchLatestWeight().first;
    expect(latest, isNotNull);
    expect(latest!.value, 80.4);
    expect(latest.source, 'Apple Zdrowie');

    await repo.deleteSample(latest);
    final after = await repo.watchLatestWeight().first;
    expect(after?.value, 80.2);
  });

  test('steps lookup is scoped to the Warsaw day key', () async {
    await seedSample(db, kind: 'steps', day: '2026-09-10', value: 5400);
    await seedSample(db, kind: 'steps', day: '2026-09-11', value: 1200);

    final today = await repo.watchStepsForDay('2026-09-10').first;
    expect(today.single.value, 5400);
  });

  test(
    'delete marks a tombstone and enqueues only a delete operation',
    () async {
      final sample = await seedSample(
        db,
        kind: 'steps',
        day: '2026-09-10',
        value: 5400,
      );
      await repo.deleteSample(sample);

      final row = await (db.select(
        db.healthSamples,
      )..where((s) => s.syncId.equals(sample.syncId))).getSingle();
      expect(row.deletedAtUtc, isNotNull);

      final pending = await db.syncDao.pendingOperations();
      expect(pending, hasLength(1));
      final operation = pending.single;
      expect(operation.entityType, SyncEntityType.healthSample);
      expect(operation.deleted, isTrue);
      expect(operation.entityId, sample.syncId);
      expect(operation.payload['kind'], 'steps');
      expect(operation.payload['day'], '2026-09-10');
      expect(operation.payload['value'], 5400);
      expect(operation.payload['source'], 'Apple Zdrowie');
      expect(operation.payload['method'], 'manual_verified_total');
    },
  );

  test('payload round-trips ISO datetimes understood by sync', () async {
    final measuredAt = DateTime.utc(2026, 9, 10, 6, 30);
    final importedAt = DateTime.utc(2026, 9, 10, 8, 0);
    final sample = await seedSample(
      db,
      kind: 'weight',
      day: '2026-09-10',
      measuredAt: measuredAt,
      value: 77.7,
      importedAt: importedAt,
    );

    final payload = repo.payloadFor(sample);

    expect(payload['measuredAt'], measuredAt.toIso8601String());
    expect(payload['importedAt'], importedAt.toIso8601String());
    expect(payload['kind'], 'weight');
  });

  test('last import freshness aggregates visible samples only', () async {
    final old = await seedSample(
      db,
      kind: 'weight',
      day: '2026-09-09',
      measuredAt: DateTime.utc(2026, 9, 9, 6),
      value: 90,
      importedAt: DateTime.utc(2026, 9, 9, 12),
    );
    await seedSample(
      db,
      kind: 'steps',
      day: '2026-09-10',
      value: 2000,
      importedAt: DateTime.utc(2026, 9, 10, 12, 30),
    );

    final freshness = await repo.watchLastImportedAt().first;
    expect(freshness, DateTime.utc(2026, 9, 10, 12, 30));

    await repo.deleteSample(old);
    final afterDelete = await repo.watchLastImportedAt().first;
    expect(afterDelete, DateTime.utc(2026, 9, 10, 12, 30));
  });
}
