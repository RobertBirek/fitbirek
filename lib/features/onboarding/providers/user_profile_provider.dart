import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/sync/sync_models.dart';

class UserProfileRepository {
  UserProfileRepository(this._db);
  final AppDatabase _db;

  UserProfile _mapRow(UserProfileData row) {
    return UserProfile(
      id: row.id,
      imie: row.imie,
      wiek: row.wiek,
      wzrostCm: row.wzrostCm,
      wagaKg: row.wagaKg,
      cel: CelTreningowy.values.firstWhere(
        (c) => c.name == row.cel,
        orElse: () => CelTreningowy.mix,
      ),
      dostepnySprzet: List<String>.from(jsonDecode(row.dostepnySprzet)),
      onboardingZakonczony: row.onboardingZakonczony,
      dataUtworzenia: row.dataUtworzenia,
    );
  }

  Stream<UserProfile?> watchProfile() {
    return _db.userProfileDao.watchProfile().map(
      (row) => row == null ? null : _mapRow(row),
    );
  }

  Future<UserProfile?> getProfileOnce() async {
    final row = await _db.userProfileDao.watchProfileOnce();
    return row == null || row.deletedAtUtc != null ? null : _mapRow(row);
  }

  Future<void> saveProfile({
    required String imie,
    required int wiek,
    required double wzrostCm,
    required double wagaKg,
    required CelTreningowy cel,
    required List<String> dostepnySprzet,
    bool onboardingZakonczony = true,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final existing = await _db.userProfileDao.watchProfileOnce();
      final syncId =
          existing?.syncId ?? await _db.syncDao.singletonId('profile');
      final syncVersion = existing?.syncVersion ?? 0;
      final createdAt = existing?.dataUtworzenia ?? now;
      final encodedEquipment = jsonEncode(dostepnySprzet);
      await _db.userProfileDao.upsertProfile(
        UserProfilesCompanion(
          id: const Value(1),
          imie: Value(imie),
          wiek: Value(wiek),
          wzrostCm: Value(wzrostCm),
          wagaKg: Value(wagaKg),
          cel: Value(cel.name),
          dostepnySprzet: Value(encodedEquipment),
          onboardingZakonczony: Value(onboardingZakonczony),
          dataUtworzenia: Value(createdAt),
          syncId: Value(syncId),
          syncVersion: Value(syncVersion),
          updatedAtUtc: Value(now),
          deletedAtUtc: const Value(null),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.profile,
        entityId: syncId,
        baseVersion: syncVersion,
        payload: {
          'imie': imie,
          'wiek': wiek,
          'wzrostCm': wzrostCm,
          'wagaKg': wagaKg,
          'cel': cel.name,
          'dostepnySprzet': dostepnySprzet,
          'onboardingZakonczony': onboardingZakonczony,
          'dataUtworzenia': createdAt.toUtc().toIso8601String(),
        },
      );
    });
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserProfileRepository(db);
});

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.watchProfile();
});
