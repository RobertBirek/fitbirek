// Testy MeasurementsRepository - operacje CRUD na pomiarach ciała, na bazie
// Drift w pamięci (wzorzec z test/features/settings/backup_service_test.dart).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';

void main() {
  late AppDatabase db;
  late MeasurementsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MeasurementsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addMeasurement zapisuje pomiar z wagą jako polem wymaganym', () async {
    await repo.addMeasurement(wagaKg: 94.0);

    final latest = await repo.getLatest();
    expect(latest, isNotNull);
    expect(latest!.wagaKg, 94.0);
  });

  test(
    'addMeasurement zapisuje pola opcjonalne (obwody, tętno, ciśnienie)',
    () async {
      await repo.addMeasurement(
        wagaKg: 93.5,
        obwodTalii: 92.0,
        obwodKlatki: 105.0,
        procentTluszczu: 22.5,
        tetnoSpoczynkowe: 62,
        cisnienie: '120/80',
        notatka: 'Po treningu',
      );

      final latest = await repo.getLatest();
      expect(latest!.obwodTalii, 92.0);
      expect(latest.obwodKlatki, 105.0);
      expect(latest.procentTluszczu, 22.5);
      expect(latest.tetnoSpoczynkowe, 62);
      expect(latest.cisnienie, '120/80');
      expect(latest.notatka, 'Po treningu');
    },
  );

  test('pola nieprzekazane pozostają null', () async {
    await repo.addMeasurement(wagaKg: 90.0);

    final latest = await repo.getLatest();
    expect(latest!.obwodTalii, isNull);
    expect(latest.tetnoSpoczynkowe, isNull);
    expect(latest.notatka, isNull);
  });

  test('getLatest zwraca null gdy brak pomiarów', () async {
    final latest = await repo.getLatest();
    expect(latest, isNull);
  });

  test('watchAll emituje aktualną listę po każdym dodaniu pomiaru', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().listen((list) => emissions.add(list.length));

    await repo.addMeasurement(wagaKg: 95.0);
    await repo.addMeasurement(wagaKg: 94.5);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });

  test('watchAll zwraca pomiary sortowane od najnowszego', () async {
    await repo.addMeasurement(wagaKg: 96.0);
    await repo.addMeasurement(wagaKg: 95.0);
    await repo.addMeasurement(wagaKg: 94.0);

    final list = await repo.watchAll().first;
    expect(list, hasLength(3));
    // getLatest() i pierwszy element watchAll() powinny być zgodne (desc data)
    expect(list.first.wagaKg, 94.0);
  });

  test('getLatest zwraca najnowszy pomiar po wielu wpisach', () async {
    await repo.addMeasurement(wagaKg: 100.0);
    await repo.addMeasurement(wagaKg: 98.0);
    await repo.addMeasurement(wagaKg: 97.0);

    final latest = await repo.getLatest();
    expect(latest!.wagaKg, 97.0);
  });
}
