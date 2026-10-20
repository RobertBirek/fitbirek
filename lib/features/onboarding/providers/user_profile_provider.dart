import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/profile_payload.dart';
import '../../../core/utils/profile_input.dart';
import '../../../core/sync/sync_quarantine.dart';
import '../../../core/sync/sync_store.dart';
import '../../auth/providers/auth_providers.dart';

class ProfileEditConflict implements Exception {}

/// Entire Drift row is the optimistic baseline, including unknown collections.
class ProfileEdit {
  ProfileEdit._(this.row, this.profile, this.binding, this.epoch);
  final UserProfileData row;
  final UserProfile profile;
  final SyncStateData binding;
  final int? epoch;
}

class UserProfileRepository {
  UserProfileRepository(this._db, {this.authority});
  final AppDatabase _db;
  final CachedAuthWriteAuthority? authority;

  Future<void> checkEditAuthority(ProfileEdit edit) => _check(edit);

  void _owns(int? epoch, String account) {
    final auth = authority?.state;
    if (authority?.epoch != epoch ||
        (auth != null && (!auth.isSignedIn || auth.accountId != account))) {
      throw ProfileEditConflict();
    }
  }

  Future<void> _check(ProfileEdit edit) async {
    _owns(edit.epoch, edit.binding.accountId);
    final binding = await _db.syncDao.readState();
    _owns(edit.epoch, edit.binding.accountId);
    if (binding?.offlineAccess != true ||
        binding?.accountId != edit.binding.accountId ||
        binding?.deviceId != edit.binding.deviceId) {
      throw ProfileEditConflict();
    }
  }

  Future<void> _resolved(UserProfileData row, String account) async {
    final deferred =
        await (_db.select(_db.syncDeferredRecords)..where(
              (r) =>
                  r.entityType.equals('profile') &
                  r.entityId.equals(row.syncId),
            ))
            .getSingleOrNull();
    final held = await SyncQuarantine(_db, SyncStore(_db)).heldKeys(account);
    if ((deferred != null && deferred.version >= row.syncVersion) ||
        held.contains('profile:${row.syncId}')) {
      throw ProfileEditConflict();
    }
  }

  Future<ProfileEdit> captureEdit() {
    final epoch = authority?.epoch;
    return _db.transaction(() async {
      final binding = await _db.syncDao.readState();
      final row = await _db.userProfileDao.watchProfileOnce();
      if (binding == null ||
          !binding.offlineAccess ||
          row == null ||
          row.deletedAtUtc != null) {
        throw ProfileEditConflict();
      }
      _owns(epoch, binding.accountId);
      final edit = ProfileEdit._(row, _mapRow(row), binding, epoch);
      await _resolved(row, binding.accountId);
      await _check(edit);
      return edit;
    });
  }

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
    ProfileEdit? edit,
    bool Function()? isCurrent,
  }) async {
    if (!validProfileNumbers(wiek, wzrostCm, wagaKg)) {
      throw ArgumentError('Nieprawidłowe dane profilu');
    }
    void current() {
      if (!(isCurrent?.call() ?? true)) throw ProfileEditConflict();
      if (edit != null) _owns(edit.epoch, edit.binding.accountId);
    }

    current();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      current();
      if (edit != null) await _check(edit);
      final existing = await _db.userProfileDao.watchProfileOnce();
      current();
      if (edit != null) {
        if (existing != edit.row) throw ProfileEditConflict();
        await _resolved(edit.row, edit.binding.accountId);
        await _check(edit);
        current();
      }
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
        baseVersion: await profileWriteBaseVersion(_db, syncId, syncVersion),
        payload: profilePayload((await _db.userProfileDao.watchProfileOnce())!),
      );
      if (edit != null) await _check(edit);
      current();
    });
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserProfileRepository(
    db,
    authority: ref.watch(cachedAuthWriteAuthorityProvider),
  );
});

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.watchProfile();
});
