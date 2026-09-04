// Testy PrsRepository - zapis rekordów osobistych z automatycznym
// przeliczeniem szacowanego 1RM (PrDetector.epley1Rm), na bazie Drift
// w pamięci.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';

void main() {
  late AppDatabase db;
  late PrsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PrsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('savePr zapisuje rekord i przelicza szacowane 1RM wg Epley', () async {
    await repo.savePr(
      exerciseId: 'wyciskanie_hantli',
      exerciseNamePl: 'Wyciskanie hantli',
      weightKg: 15.0,
      reps: 10,
    );

    final best = await repo.getBestForExercise('wyciskanie_hantli');
    expect(best, isNotNull);
    // 15 * (1 + 10/30) = 20.0
    expect(best!.szacowane1Rm, closeTo(20.0, 0.01));
  });

  test(
    'getBestForExercise zwraca null gdy brak rekordów dla ćwiczenia',
    () async {
      final best = await repo.getBestForExercise('nieistniejace_cwiczenie');
      expect(best, isNull);
    },
  );

  test(
    'getBestForExercise zwraca rekord z najwyższym szacowanym 1RM',
    () async {
      await repo.savePr(
        exerciseId: 'martwy_ciag',
        exerciseNamePl: 'Martwy ciąg',
        weightKg: 60,
        reps: 5,
      );
      await repo.savePr(
        exerciseId: 'martwy_ciag',
        exerciseNamePl: 'Martwy ciąg',
        weightKg: 70,
        reps: 3,
      );

      final best = await repo.getBestForExercise('martwy_ciag');
      expect(best, isNotNull);
      // 60*(1+5/30)=70.0 vs 70*(1+3/30)=77.0 -> wygrywa drugi
      expect(best!.ciezarKg, 70.0);
    },
  );

  test(
    'getHistoryForExercise zwraca wszystkie wpisy dla danego ćwiczenia',
    () async {
      await repo.savePr(
        exerciseId: 'przysiady',
        exerciseNamePl: 'Przysiady',
        weightKg: 40,
        reps: 8,
      );
      await repo.savePr(
        exerciseId: 'przysiady',
        exerciseNamePl: 'Przysiady',
        weightKg: 45,
        reps: 6,
      );
      await repo.savePr(
        exerciseId: 'wyciskanie',
        exerciseNamePl: 'Wyciskanie',
        weightKg: 20,
        reps: 10,
      );

      final przysiady = await repo.getHistoryForExercise('przysiady');
      expect(przysiady, hasLength(2));
    },
  );

  test('watchAll zwraca rekordy z różnych ćwiczeń', () async {
    await repo.savePr(
      exerciseId: 'a',
      exerciseNamePl: 'Ćwiczenie A',
      weightKg: 10,
      reps: 5,
    );
    await repo.savePr(
      exerciseId: 'b',
      exerciseNamePl: 'Ćwiczenie B',
      weightKg: 20,
      reps: 5,
    );

    final all = await repo.watchAll().first;
    expect(all, hasLength(2));
  });

  test('savePr z 0 powtórzeń zapisuje 1RM równe ciężarowi', () async {
    await repo.savePr(
      exerciseId: 'test_zero',
      exerciseNamePl: 'Test',
      weightKg: 50,
      reps: 0,
    );

    final best = await repo.getBestForExercise('test_zero');
    expect(best!.szacowane1Rm, 50.0);
  });
}
