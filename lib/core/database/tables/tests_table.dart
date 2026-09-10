import 'package:drift/drift.dart';

import 'sync_metadata.dart';

/// Tabela wyników testów sprawnościowych (11 predefiniowanych testów).
@DataClassName('FitnessTestResultData')
class FitnessTestResults extends Table with SyncMetadata {
  IntColumn get id => integer().autoIncrement()();
  // Nazwa enuma TypTestu jako string, np. "maxPompki"
  TextColumn get typ => text()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
  RealColumn get wynik => real()();
  IntColumn get score => integer().withDefault(const Constant(0))();
}
