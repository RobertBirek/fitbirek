import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/user_collections.dart';
import 'user_collections_repository.dart';
import '../domain/exercise_catalog_metadata.dart';

/// Immutable protocol per UUID. Protocol changes always create a fork.
class ExerciseVariantsRepository {
  ExerciseVariantsRepository(this.collections);
  final UserCollectionsRepository collections;

  Future<List<Map<String, dynamic>>> load(
    String account,
    String exerciseId, {
    bool Function()? isCurrent,
  }) async {
    final value = await collections.load(
      account,
      'exerciseVariants',
      isCurrent: isCurrent,
    );
    return (value['entries'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(
          (e) => e['exerciseId'] == exerciseId && e['deletedAtUtc'] == null,
        )
        .toList();
  }

  Future<String> create(
    String account,
    String exerciseId,
    String name, {
    double? loadKg,
    String? tempo,
    int? pauseSeconds,
    String? rangeOfMotion,
    String? cue,
    bool Function()? isCurrent,
  }) async {
    final authority = collections.authority,
        epoch = collections.authority?.epoch;
    final callerGuard = isCurrent;
    isCurrent = () =>
        (callerGuard?.call() ?? true) && authority?.epoch == epoch;
    final exercise = await (collections.db.select(
      collections.db.exercises,
    )..where((e) => e.id.equals(exerciseId))).getSingleOrNull();
    if (exercise == null) throw StateError('Nieznane ćwiczenie bazowe.');
    final equipment = (jsonDecode(exercise.sprzet) as List).cast<String>();
    if (loadKg != null &&
        (exercise.typ == 'Izometria' ||
            !equipment.any((s) => s == 'Hantle' || s == 'Sandbag'))) {
      throw ArgumentError('Obciążenie wariantu tylko dla hantli lub sandbaga.');
    }
    if (loadKg != null) {
      final catalog = ExerciseCatalogMetadata.fromJson(
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/exercise_catalog_metadata.json',
              ),
            )
            as Map<String, dynamic>,
      );
      if (catalog.entryFor(exerciseId)?.tracking != 'reps') {
        throw ArgumentError(
          'Domyślne kg tylko dla bazowego śledzenia ciężaru i powtórzeń.',
        );
      }
    }
    final id = const Uuid().v4();
    final stamp = UserCollectionsRepository.nextTimestamp(null);
    final entry = <String, dynamic>{
      'id': id,
      'exerciseId': exerciseId,
      'name': name.trim(),
      'createdAtUtc': stamp,
      'updatedAtUtc': stamp,
      if (loadKg != null) 'loadKg': loadKg,
      if (tempo != null) 'tempo': tempo,
      if (pauseSeconds != null) 'pauseSeconds': pauseSeconds,
      if (rangeOfMotion != null) 'rangeOfMotion': rangeOfMotion,
      if (cue != null) 'cue': cue,
    };
    UserCollections.validate('exerciseVariants', {
      'version': 1,
      'entries': [entry],
    });
    return collections.update(account, 'exerciseVariants', (entries) {
      entries.add(entry);
      return id;
    }, isCurrent: isCurrent);
  }

  Future<void> delete(
    String account,
    String id, {
    bool Function()? isCurrent,
  }) => collections.update(account, 'exerciseVariants', (entries) {
    for (final e in entries.where(
      (e) => e['id'] == id && e['deletedAtUtc'] == null,
    )) {
      final stamp = UserCollectionsRepository.nextTimestamp(e);
      e.addAll({'updatedAtUtc': stamp, 'deletedAtUtc': stamp});
    }
  }, isCurrent: isCurrent);

  /// Only presentation metadata is editable. Core protocol fields have no
  /// update API: callers create another UUID using [create] instead.
  Future<void> rename(
    String account,
    String id,
    String name, {
    String? cue,
    bool Function()? isCurrent,
  }) => collections.update(account, 'exerciseVariants', (entries) {
    final e = entries.firstWhere(
      (e) => e['id'] == id && e['deletedAtUtc'] == null,
      orElse: () => throw StateError('Wariant niedostępny.'),
    );
    e.addAll({
      'name': name.trim(),
      'updatedAtUtc': UserCollectionsRepository.nextTimestamp(e),
    });
    if (cue != null) e['cue'] = cue;
  }, isCurrent: isCurrent);

  /// Within the same transaction as a new set/PR. Historical readers never use
  /// this guard: deleted/unknown UUIDs and label snapshots remain readable.
  static Future<String?> requireLive(
    AppDatabase db,
    String exerciseId,
    String? id, {
    String? accountId,
  }) async {
    if (id == null) return null;
    if (!UserCollections.isUuid(id)) throw StateError('Nieprawidłowy wariant.');
    final binding = await db.syncDao.readState();
    if (binding == null ||
        !binding.offlineAccess ||
        (accountId != null && binding.accountId != accountId)) {
      throw StateError('Brak dostępu do konta wariantu.');
    }
    final profile = await db.userProfileDao.watchProfileOnce();
    if (profile == null ||
        profile.deletedAtUtc != null ||
        profile.exerciseVariantsJson == null) {
      throw StateError('Wariant niedostępny.');
    }
    final value = UserCollections.validate(
      'exerciseVariants',
      jsonDecode(profile.exerciseVariantsJson!),
    );
    for (final e in value['entries'] as List) {
      if (e['id'] == id &&
          e['exerciseId'] == exerciseId &&
          e['deletedAtUtc'] == null) {
        return e['name'] as String;
      }
    }
    throw StateError(
      'Wariant usunięty lub należy do innego ćwiczenia. Wybierz wariant bazowy.',
    );
  }
}
