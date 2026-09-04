import 'package:drift/drift.dart';

/// Tabela szablonów planów treningowych (generator planu - funkcja premium).
class WorkoutPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nazwa => text()();
  // JSON-encoded lista ID ćwiczeń w planie
  TextColumn get cwiczeniaIds => text()();
  TextColumn get cel => text()();
  DateTimeColumn get dataUtworzenia =>
      dateTime().withDefault(currentDateAndTime)();
}
