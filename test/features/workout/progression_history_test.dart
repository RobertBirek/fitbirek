import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';

void main() {
  test(
    'history is ended-only, exact side/id, ignores both tombstones, read-only',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      for (var i = 1; i <= 5; i++) {
        final id = await db.workoutDao.createSession(
          WorkoutSessionsCompanion.insert(
            dataStart: DateTime.utc(2026, 10, i),
            dataKoniec: Value(i == 3 ? null : DateTime.utc(2026, 10, i, 1)),
            deletedAtUtc: Value(i == 4 ? DateTime.utc(2026) : null),
          ),
        );
        for (final side in <String?>[null, 'both', 'left', 'right']) {
          await db.workoutDao.addSet(
            SetsLogCompanion.insert(
              sesjaId: id,
              cwiczenieId: 'ex',
              nazwaCwiczeniaPl: 'Test',
              numerSerii: 1,
              side: Value(side),
              powtorzenia: const Value(8),
              rpe: const Value(7),
              ciezarKg: const Value(20),
              deletedAtUtc: Value(i == 5 ? DateTime.utc(2026) : null),
            ),
          );
        }
      }
      for (final side in <String?>[null, 'both', 'left', 'right']) {
        final rows = await repo.getProgressionHistory(
          'ex',
          side: side,
          excludingSessionId: 99,
        );
        expect(rows, hasLength(2));
        expect(rows.every((r) => r.side == side), isTrue);
        expect(rows.map((r) => r.sessionId).toSet(), {1, 2});
        expect(
          await repo.getProgressionHistory(
            'other',
            side: side,
            excludingSessionId: 99,
          ),
          isEmpty,
        );
        expect(
          await repo.getProgressionHistory(
            'ex',
            side: side,
            excludingSessionId: 2,
          ),
          hasLength(1),
        );
      }
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
    },
  );
}
