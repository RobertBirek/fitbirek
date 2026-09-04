import 'package:drift/drift.dart';

/// Tabela pomiarów ciała - waga, obwody, tętno, ciśnienie.
@DataClassName('MeasurementData')
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
  RealColumn get wagaKg => real()();
  RealColumn get obwodKlatki => real().nullable()();
  RealColumn get obwodTalii => real().nullable()();
  RealColumn get obwodBioder => real().nullable()();
  RealColumn get obwodBicepsuP => real().nullable()();
  RealColumn get obwodBicepsuL => real().nullable()();
  RealColumn get obwodUdaP => real().nullable()();
  RealColumn get obwodUdaL => real().nullable()();
  RealColumn get obwodLydkiP => real().nullable()();
  RealColumn get obwodLydkiL => real().nullable()();
  RealColumn get procentTluszczu => real().nullable()();
  IntColumn get tetnoSpoczynkowe => integer().nullable()();
  TextColumn get cisnienie => text().nullable()();
  TextColumn get notatka => text().nullable()();
}
