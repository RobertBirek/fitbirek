import 'package:drift/drift.dart';

/// Tabela rekordów osobistych (PR) - auto-wykrywane podczas sesji treningowej.
class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cwiczenieId => text()();
  TextColumn get nazwaCwiczeniaPl => text()();
  RealColumn get ciezarKg => real()();
  IntColumn get powtorzenia => integer()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
  RealColumn get szacowane1Rm => real()();
}
