import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/working_sets.dart';
import '../domain/training_trend.dart';

/// No catalog/profile join: deleted variants and missing exercises retain their
/// historical labels and exact identities. This adapter never writes anything.
class TrainingTrendRepository {
  TrainingTrendRepository(this.db);
  final AppDatabase db;

  JoinedSelectStatement _query(TrendScope? scope) {
    final sets = db.setsLog, sessions = db.workoutSessions;
    final query =
        db.select(sets).join([
          innerJoin(sessions, sessions.id.equalsExp(sets.sesjaId)),
        ])..where(
          sessions.dataKoniec.isNotNull() &
              sessions.deletedAtUtc.isNull() &
              sets.deletedAtUtc.isNull() &
              effectiveWorkingSets(sets),
        );
    if (scope != null) {
      query.where(
        sets.cwiczenieId.equals(scope.exerciseId) &
            (scope.side == null
                ? sets.side.isNull()
                : sets.side.equals(scope.side!)) &
            (scope.variantId == null
                ? sets.variantId.isNull()
                : sets.variantId.equals(scope.variantId!)),
      );
    }
    query.orderBy([
      OrderingTerm.asc(sessions.dataKoniec),
      OrderingTerm.asc(sessions.id),
      OrderingTerm.asc(sets.numerSerii),
      OrderingTerm.asc(sets.id),
    ]);
    return query;
  }

  List<TrendRow> _map(List<TypedResult> rows) => rows.map((r) {
    final s = r.readTable(db.setsLog),
        session = r.readTable(db.workoutSessions);
    return TrendRow(
      scope: (exerciseId: s.cwiczenieId, side: s.side, variantId: s.variantId),
      sessionId: session.id,
      setId: s.id,
      endedAt: session.dataKoniec!,
      setNumber: s.numerSerii,
      exerciseName: s.nazwaCwiczeniaPl,
      variantLabel: s.variantLabel,
      load: s.ciezarKg,
      reps: s.powtorzenia,
      seconds: s.czasSekund,
      rpe: s.rpe,
    );
  }).toList();
  Future<List<TrendRow>> readHistory({TrendScope? scope}) async =>
      _map(await _query(scope).get());
  Stream<List<TrendRow>> watchHistory() => _query(null).watch().map(_map);
}
