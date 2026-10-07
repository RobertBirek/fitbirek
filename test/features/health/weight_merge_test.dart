// Łączenie ręcznych pomiarów i importowanych próbek Apple Zdrowie do jednej
// listy punktów wagi: ręczne pomiary pozostają nietknięte, import ma widoczne
// źródło, brak pola measuredAt uzupełniany z dnia.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart'
    show HealthSampleData, MeasurementData;
import 'package:fitbirek_training/features/health/data/health_repository.dart';

void main() {
  MeasurementData insertManual(double kg, DateTime when) {
    return MeasurementData(
      id: 1,
      syncId: 'manual-sync',
      syncVersion: 0,
      updatedAtUtc: when,
      deletedAtUtc: null,
      data: when,
      wagaKg: kg,
      obwodKlatki: null,
      obwodTalii: null,
      obwodBioder: null,
      obwodBicepsuP: null,
      obwodBicepsuL: null,
      obwodUdaP: null,
      obwodUdaL: null,
      obwodLydkiP: null,
      obwodLydkiL: null,
      procentTluszczu: null,
      tetnoSpoczynkowe: null,
      cisnienie: null,
      notatka: null,
    );
  }

  HealthSampleData sample({
    required String kind,
    required String day,
    DateTime? measuredAt,
    required double value,
  }) {
    return HealthSampleData(
      id: 1,
      syncId: 'sample-sync',
      syncVersion: 1,
      updatedAtUtc: DateTime.utc(2026, 9, 10),
      deletedAtUtc: null,
      kind: kind,
      day: day,
      measuredAt: measuredAt,
      value: value,
      source: 'Apple Zdrowie',
      method: 'health_sample',
      importedAt: DateTime.utc(2026, 9, 10),
    );
  }

  test('merges manual and imported weights sorted ascending by date', () {
    final manual = [insertManual(80.0, DateTime(2026, 9, 5))];
    final imported = [
      sample(
        kind: 'weight',
        day: '2026-09-08',
        measuredAt: DateTime.utc(2026, 9, 8, 6),
        value: 79.2,
      ),
    ];

    final entries = HealthRepository.mergeWeights(manual, imported);

    expect(entries, hasLength(2));
    expect(entries.first.kg, 80.0);
    expect(entries.first.imported, isFalse);
    expect(entries.first.source, isNull);
    expect(entries.last.kg, 79.2);
    expect(entries.last.imported, isTrue);
    expect(entries.last.source, 'Apple Zdrowie');
  });

  test('falls back to the day key when measuredAt is missing', () {
    final entries = HealthRepository.mergeWeights([], [
      sample(kind: 'weight', day: '2026-09-01', value: 81.5),
    ]);

    expect(entries.single.date, DateTime(2026, 9, 1));
    expect(entries.single.imported, isTrue);
  });

  test('does not mutate or tag manual measurements as imported', () {
    final manual = insertManual(77.0, DateTime(2026, 9, 2));
    final copy = [manual];

    final entries = HealthRepository.mergeWeights(copy, []);

    expect(entries.single.sample, isNull);
    expect(entries.single.source, isNull);
    expect(entries.single.date, manual.data);
    expect(entries.single.kg, manual.wagaKg);
  });
}
