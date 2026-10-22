import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';

void main() {
  test(
    'preparation reads latest ended session/set, exact identity, without writes',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      for (var i = 1; i <= 5; i++) {
        final session = await db.workoutDao.createSession(
          WorkoutSessionsCompanion.insert(
            dataStart: DateTime.utc(2026, 10, i),
            dataKoniec: Value(i == 3 ? null : DateTime.utc(2026, 10, i, 1)),
            deletedAtUtc: Value(i == 4 ? DateTime.utc(2026, 10, 6) : null),
          ),
        );
        for (final side in <String?>[null, 'both', 'left', 'right']) {
          for (final variant in <String?>[null, 'variant']) {
            for (var n = 1; n <= 2; n++) {
              await db.workoutDao.addSet(
                SetsLogCompanion.insert(
                  sesjaId: session,
                  cwiczenieId: 'cw001',
                  nazwaCwiczeniaPl: 'Ćwiczenie',
                  numerSerii: n,
                  timestamp: Value(DateTime.utc(2026, 10, i, 0, n)),
                  side: Value(side),
                  variantId: Value(variant),
                  ciezarKg: Value(i == 2 ? (n == 2 ? 6 : 8) : (n == 2 ? 7 : 9)),
                  powtorzenia: const Value(10),
                  rpe: const Value(7),
                  deletedAtUtc: Value(
                    i == 5 ? DateTime.utc(2026, 10, 6) : null,
                  ),
                ),
              );
            }
          }
        }
      }
      for (final side in <String?>[null, 'both', 'left', 'right']) {
        for (final variant in <String?>[null, 'variant']) {
          final rows = await repo.getPreparationHistory(
            'cw001',
            side: side,
            variantId: variant,
          );
          expect(rows.map((r) => r.sessionId).toList(), [2, 2, 1, 1]);
          expect(rows.map((r) => r.weightKg).toList(), [6, 8, 7, 9]);
          expect(
            rows.every((r) => r.side == side && r.variantId == variant),
            isTrue,
          );
        }
      }
      expect(await repo.getPreparationHistory('other', side: null), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(await db.select(db.workoutSessions).get(), hasLength(5));
    },
  );
}
