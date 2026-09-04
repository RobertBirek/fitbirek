// Testy TestsRepository - zapis wyniku testu sprawnościowego z automatycznym
// przeliczeniem score (TestScoreCalculator), na bazie Drift w pamięci.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';

void main() {
  late AppDatabase db;
  late TestsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TestsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addResult zapisuje typ i wynik testu', () async {
    await repo.addResult(typ: TypTestu.maxPompki, wynik: 30);

    final history = await repo.getHistoryForType(TypTestu.maxPompki);
    expect(history, hasLength(1));
    expect(history.first.typ, 'maxPompki');
    expect(history.first.wynik, 30.0);
  });

  test('addResult przelicza i zapisuje score automatycznie', () async {
    // maxPompki: low=10, high=50 -> wynik=30 -> score=50
    await repo.addResult(typ: TypTestu.maxPompki, wynik: 30);

    final history = await repo.getHistoryForType(TypTestu.maxPompki);
    expect(history.first.score, 50);
  });

  test('getHistoryForType filtruje po typie testu', () async {
    await repo.addResult(typ: TypTestu.maxPompki, wynik: 30);
    await repo.addResult(typ: TypTestu.plank, wynik: 90);
    await repo.addResult(typ: TypTestu.maxPompki, wynik: 35);

    final pompki = await repo.getHistoryForType(TypTestu.maxPompki);
    final plank = await repo.getHistoryForType(TypTestu.plank);

    expect(pompki, hasLength(2));
    expect(plank, hasLength(1));
  });

  test(
    'watchAll zwraca wszystkie zapisane wyniki niezależnie od typu',
    () async {
      await repo.addResult(typ: TypTestu.maxPompki, wynik: 25);
      await repo.addResult(typ: TypTestu.cooper12min, wynik: 2400);

      final all = await repo.watchAll().first;
      expect(all, hasLength(2));
    },
  );

  test('getHistoryForType zwraca puste gdy brak wyników dla typu', () async {
    await repo.addResult(typ: TypTestu.maxPompki, wynik: 25);

    final history = await repo.getHistoryForType(TypTestu.deadHang);
    expect(history, isEmpty);
  });

  test(
    'kilka wyników tego samego typu zachowuje osobne wpisy i score',
    () async {
      await repo.addResult(typ: TypTestu.plank, wynik: 30); // score 0
      await repo.addResult(typ: TypTestu.plank, wynik: 240); // score 100

      final history = await repo.getHistoryForType(TypTestu.plank);
      expect(history, hasLength(2));
      final scores = history.map((h) => h.score).toSet();
      expect(scores, containsAll([0, 100]));
    },
  );
}
