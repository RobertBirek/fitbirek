import 'package:drift/drift.dart';

import 'sync_metadata.dart';

/// Tabela sesji treningowych.
@DataClassName('WorkoutSessionData')
class WorkoutSessions extends Table with SyncMetadata {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get dataStart => dateTime()();
  DateTimeColumn get dataKoniec => dateTime().nullable()();
  IntColumn get czasTrwaniaSekund => integer().withDefault(const Constant(0))();
  TextColumn get notatka => text().nullable()();
}

/// Tabela zalogowanych serii ćwiczeń w ramach sesji treningowej.
@DataClassName('SetLogData')
class SetsLog extends Table with SyncMetadata {
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
