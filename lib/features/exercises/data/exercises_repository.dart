import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/exercise.dart';

/// Repozytorium bazy ćwiczeń - odpowiada za import startowy z JSON
/// oraz konwersję między wierszami Drift a modelem domenowym Exercise.
///
/// TODO: import pełnej bazy 316 ćwiczeń z Excel poprzez skrypt build_exercises.dart
/// (zobacz sekcję "Jak dodać nowe ćwiczenia" w README.md)
class ExercisesRepository {
  ExercisesRepository(this._db);

  final AppDatabase _db;

  /// Importuje ćwiczenia z assets/data/exercises.json do bazy Drift,
  /// ale tylko jeśli baza jest pusta (pierwsze uruchomienie aplikacji).
  Future<void> importFromAssetsIfEmpty() async {
    final currentCount = await _db.exercisesDao.count();
    if (currentCount > 0) return;

    final jsonString = await rootBundle.loadString(
      'assets/data/exercises.json',
    );
    final List<dynamic> data = jsonDecode(jsonString);

    final rows = data.map((raw) {
      final map = raw as Map<String, dynamic>;
      return ExercisesCompanion.insert(
        id: map['id'] as String,
        nazwaPl: map['nazwaPl'] as String,
        nazwaEn: map['nazwaEn'] as String,
        partiaGlowna: map['partiaGlowna'] as String,
        partieWspierajace: jsonEncode(map['partieWspierajace']),
        sprzet: jsonEncode(map['sprzet']),
        typ: map['typ'] as String,
        poziom: map['poziom'] as String,
        wzorzecRuchu: map['wzorzecRuchu'] as String,
        seriexPowtorzenia: map['seriexPowtorzenia'] as String,
        tempo: map['tempo'] as String,
        kluczoweWskazowki: jsonEncode(map['kluczoweWskazowki']),
        czesteBledy: jsonEncode(map['czesteBledy']),
        progresja: map['progresja'] as String,
        regresja: map['regresja'] as String,
        zrodlo: map['zrodlo'] as String,
        ulubione: Value(map['ulubione'] as bool? ?? false),
      );
    }).toList();

    await _db.exercisesDao.insertAll(rows);
  }

  Exercise _mapRowToModel(ExerciseData row) {
    return Exercise(
      id: row.id,
      nazwaPl: row.nazwaPl,
      nazwaEn: row.nazwaEn,
      partiaGlowna: row.partiaGlowna,
      partieWspierajace: List<String>.from(jsonDecode(row.partieWspierajace)),
      sprzet: List<String>.from(jsonDecode(row.sprzet)),
      typ: row.typ,
      poziom: row.poziom,
      wzorzecRuchu: row.wzorzecRuchu,
      seriexPowtorzenia: row.seriexPowtorzenia,
      tempo: row.tempo,
      kluczoweWskazowki: List<String>.from(jsonDecode(row.kluczoweWskazowki)),
      czesteBledy: List<String>.from(jsonDecode(row.czesteBledy)),
      progresja: row.progresja,
      regresja: row.regresja,
      zrodlo: row.zrodlo,
      ulubione: row.ulubione,
    );
  }

  Stream<List<Exercise>> watchAll() {
    return _db.exercisesDao.watchAll().map(
      (rows) => rows.map(_mapRowToModel).toList(),
    );
  }

  Future<Exercise?> getById(String id) async {
    final row = await _db.exercisesDao.getById(id);
    return row == null ? null : _mapRowToModel(row);
  }

  Future<void> toggleFavorite(String id, bool value) {
    return _db.exercisesDao.toggleFavorite(id, value);
  }
}
