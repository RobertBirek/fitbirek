import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/exercise.dart';

/// Repozytorium bazy ćwiczeń - odpowiada za import (przyrostowy) z JSON
/// oraz konwersję między wierszami Drift a modelem domenowym Exercise.
class ExercisesRepository {
  ExercisesRepository(this._db);

  final AppDatabase _db;

  /// Synchronizuje ćwiczenia z assets/data/exercises.json do bazy Drift.
  ///
  /// Import jest PRZYROSTOWY: wstawia tylko ćwiczenia, których `id` nie
  /// istnieje jeszcze w bazie. Dzięki temu:
  /// - na pierwszym uruchomieniu wgrywa cały starter pack,
  /// - po aktualizacji aplikacji z rozszerzoną bazą (np. 38 -> 316) dopisuje
  ///   tylko nowe pozycje na urządzeniach, które już mają starsze dane,
  /// - nigdy nie nadpisuje/nie usuwa istniejących wierszy, więc pole
  ///   `ulubione` ustawione wcześniej przez użytkownika jest zachowane.
  Future<void> syncFromAssets() async {
    final existingIds = await _db.exercisesDao.getAllIds();

    final jsonString = await rootBundle.loadString(
      'assets/data/exercises.json',
    );
    final List<dynamic> data = jsonDecode(jsonString);

    final rows = data
        .cast<Map<String, dynamic>>()
        .where((map) => !existingIds.contains(map['id'] as String))
        .map((map) {
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
        })
        .toList();

    if (rows.isEmpty) return;
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
