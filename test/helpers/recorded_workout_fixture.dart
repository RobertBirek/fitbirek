import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import 'package:fitbirek_training/core/database/app_database.dart';

/// Pre-existing recorded evidence for tests of the SESSION sync envelope.
/// No new set mutation is queued: these fixtures model an already stored set,
/// keeping the tested session request/order/count assertions unchanged.
Future<void> seedRecordedWorkoutSet(AppDatabase db, int sessionId) async {
  await db.workoutDao.addSet(
    SetsLogCompanion.insert(
      sesjaId: sessionId,
      cwiczenieId: 'fixture-evidence',
      nazwaCwiczeniaPl: 'Wcześniej zapisana seria',
      numerSerii: 1,
      powtorzenia: const Value(1),
      syncId: Value(const Uuid().v4()),
      syncVersion: const Value(1),
    ),
  );
}
