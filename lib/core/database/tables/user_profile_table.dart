import 'package:drift/drift.dart';

/// Tabela profilu użytkownika - single user (zawsze id=1), bez rejestracji.
class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get imie => text().withDefault(const Constant('Robert'))();
  IntColumn get wiek => integer()();
  RealColumn get wzrostCm => real()();
  RealColumn get wagaKg => real()();
  // Cel treningowy jako string: redukcja/sila/masa/kondycja/mix
  TextColumn get cel => text()();
  // Sprzęt jako JSON-encoded lista stringów
  TextColumn get dostepnySprzet => text()();
  BoolColumn get onboardingZakonczony =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get dataUtworzenia =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
