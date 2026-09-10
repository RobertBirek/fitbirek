import 'package:drift/drift.dart';

/// Tabela bazy ćwiczeń - importowana z assets/data/exercises.json przy pierwszym starcie.
@DataClassName('ExerciseData')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get nazwaPl => text()();
  TextColumn get nazwaEn => text()();
  TextColumn get partiaGlowna => text()();
  // Listy jako JSON-encoded stringi
  TextColumn get partieWspierajace => text()();
  TextColumn get sprzet => text()();
  TextColumn get typ => text()();
  TextColumn get poziom => text()();
  TextColumn get wzorzecRuchu => text()();
  TextColumn get seriexPowtorzenia => text()();
  TextColumn get tempo => text()();
  TextColumn get kluczoweWskazowki => text()();
  TextColumn get czesteBledy => text()();
  TextColumn get progresja => text()();
  TextColumn get regresja => text()();
  TextColumn get zrodlo => text()();
  @override
  Set<Column> get primaryKey => {id};
}
