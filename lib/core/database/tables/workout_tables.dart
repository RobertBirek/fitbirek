import 'package:drift/drift.dart';

/// Tabela sesji treningowych.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get dataStart => dateTime()();
  DateTimeColumn get dataKoniec => dateTime().nullable()();
  IntColumn get czasTrwaniaSekund => integer().withDefault(const Constant(0))();
  TextColumn get notatka => text().nullable()();
}

/// Tabela zalogowanych serii ćwiczeń w ramach sesji treningowej.
class SetsLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sesjaId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get cwiczenieId => text()();
  TextColumn get nazwaCwiczeniaPl => text()();
  IntColumn get numerSerii => integer()();
  RealColumn get ciezarKg => real().nullable()();
  IntColumn get powtorzenia => integer().nullable()();
  IntColumn get czasSekund => integer().nullable()();
  IntColumn get rpe => integer().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}
