import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/exercise.dart';
import '../../../core/sync/sync_models.dart';

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
  /// - nigdy nie nadpisuje/nie usuwa istniejących wierszy; favorite flags
  ///   live separately in `ExerciseFavorites` and therefore survive refreshes.
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
          );
        })
        .toList();

    if (rows.isEmpty) return;
    await _db.exercisesDao.insertAll(rows);
  }

  Exercise _mapRowToModel(ExerciseData row, bool ulubione) {
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
      ulubione: ulubione,
    );
  }

  Stream<List<Exercise>> watchAll() {
    return _db.exercisesDao.watchAllWithFavorites().map(
      (rows) => rows.map((row) => _mapRowToModel(row.$1, row.$2)).toList(),
    );
  }

  Future<Exercise?> getById(String id) async {
    final row = await _db.exercisesDao.getByIdWithFavorite(id);
    return row == null ? null : _mapRowToModel(row.$1, row.$2);
  }

  Future<void> toggleFavorite(String id, bool value) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final existing = await _db.exercisesDao.getFavorite(id);
      if (!value && existing == null) return;
      final syncId =
          existing?.syncId ?? await _db.syncDao.singletonId('favorite:$id');
      final syncVersion = existing?.syncVersion ?? 0;
      await _db.exercisesDao.upsertFavorite(
        ExerciseFavoritesCompanion(
          exerciseId: Value(id),
          syncId: Value(syncId),
          syncVersion: Value(syncVersion),
          updatedAtUtc: Value(now),
          deletedAtUtc: value ? const Value(null) : Value(now),
        ),
      );
      final payload = <String, Object?>{'exerciseId': id};
      if (value) {
        await _db.syncDao.enqueueUpsert(
          entityType: SyncEntityType.exerciseFavorite,
          entityId: syncId,
          baseVersion: syncVersion,
          payload: payload,
        );
      } else {
        await _db.syncDao.enqueueDelete(
          entityType: SyncEntityType.exerciseFavorite,
          entityId: syncId,
          baseVersion: syncVersion,
          payload: payload,
        );
      }
    });
  }
}
