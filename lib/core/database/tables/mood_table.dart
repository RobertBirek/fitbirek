import 'package:drift/drift.dart';

/// Tabela dziennika samopoczucia - szybki wpis codzienny.
@DataClassName('MoodEntryData')
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
  RealColumn get snGodziny => real()();
  IntColumn get energia => integer()(); // 1-10
  IntColumn get nastroj => integer()(); // 1-10
  IntColumn get apetyt => integer()(); // 1-10
  BoolColumn get alkohol => boolean().withDefault(const Constant(false))();
  IntColumn get alkoholJednostki => integer().withDefault(const Constant(0))();
}
