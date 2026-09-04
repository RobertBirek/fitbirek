import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/user_profile_table.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/database_provider.dart';

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
    return _db.userProfileDao.watchProfile().map((row) => row == null ? null : _mapRow(row));
  }

  Future<UserProfile?> getProfileOnce() async {
    final row = await _db.userProfileDao.watchProfileOnce();
    return row == null ? null : _mapRow(row);
  }

  Future<void> saveProfile({
    required String imie,
    required int wiek,
    required double wzrostCm,
    required double wagaKg,
    required CelTreningowy cel,
    required List<String> dostepnySprzet,
    bool onboardingZakonczony = true,
  }) {
    return _db.userProfileDao.upsertProfile(
      UserProfilesCompanion(
        id: const Value(1),
        imie: Value(imie),
        wiek: Value(wiek),
        wzrostCm: Value(wzrostCm),
        wagaKg: Value(wagaKg),
        cel: Value(cel.name),
        dostepnySprzet: Value(jsonEncode(dostepnySprzet)),
        onboardingZakonczony: Value(onboardingZakonczony),
      ),
    );
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
