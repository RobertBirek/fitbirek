import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/profile_payload.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/user_collections.dart';
import '../../auth/providers/auth_providers.dart';

/// Account ownership is checked against SQLite and passive auth on every await.
class UserCollectionsRepository {
  UserCollectionsRepository(this.db, {this.authority});
  final AppDatabase db;
  final CachedAuthWriteAuthority? authority;

  Future<UserProfileData> _profile(
    String account,
    int? epoch,
    bool Function()? current,
  ) async {
    void guard() {
      final auth = authority?.state;
      if (account.isEmpty ||
          !(current?.call() ?? true) ||
          authority?.epoch != epoch ||
          (auth != null && (!auth.isSignedIn || auth.accountId != account))) {
        throw StateError('Konto zostało zmienione.');
      }
    }

    guard();
    final binding = await db.syncDao.readState();
    guard();
    if (binding?.accountId != account || binding?.offlineAccess != true) {
      throw StateError('Brak dostępu do konta.');
    }
    final row = await db.userProfileDao.watchProfileOnce();
    guard();
    if (row == null || row.deletedAtUtc != null) {
      throw StateError('Brak aktywnego profilu.');
    }
    return row;
  }

  Map<String, dynamic> readRow(UserProfileData row, String key) {
    final raw = row.toJson()['${key}Json'] as String?;
    return UserCollections.validate(
      key,
      raw == null ? UserCollections.empty() : jsonDecode(raw),
    );
  }

  Future<Map<String, dynamic>> load(
    String account,
    String key, {
    bool Function()? isCurrent,
  }) async {
    final epoch = authority?.epoch;
    return readRow(await _profile(account, epoch, isCurrent), key);
  }

  Future<T> update<T>(
    String account,
    String key,
    T Function(List<Map<String, dynamic>>) edit, {
    bool Function()? isCurrent,
  }) {
    final epoch = authority?.epoch;
    return db.transaction(() async {
      final row = await _profile(account, epoch, isCurrent);
      final collection = readRow(row, key);
      final entries = (collection['entries'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final result = edit(entries);
      final value = UserCollections.validate(key, {
        'version': 1,
        'entries': entries,
      });
      if (key == 'fitnessProtocols') {
        // edit() receives mutable maps, including nested variant snapshots.
        // Re-decode the immutable row baseline instead of comparing an aliased
        // collection that the callback could already have changed in memory.
        UserCollections.requireFitnessPreserved(readRow(row, key), value);
      }
      final raw = jsonEncode(value);
      await (db.update(
        db.userProfiles,
      )..where((p) => p.id.equals(row.id))).write(
        UserProfilesCompanion(
          filterPresetsJson: key == 'filterPresets'
              ? Value(raw)
              : const Value.absent(),
          exerciseVariantsJson: key == 'exerciseVariants'
              ? Value(raw)
              : const Value.absent(),
          weeklyScheduleJson: key == 'weeklySchedule'
              ? Value(raw)
              : const Value.absent(),
          fitnessProtocolsJson: key == 'fitnessProtocols'
              ? Value(raw)
              : const Value.absent(),
          updatedAtUtc: Value(DateTime.now().toUtc()),
        ),
      );
      final fresh = await _profile(account, epoch, isCurrent);
      await db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.profile,
        entityId: fresh.syncId,
        baseVersion: await profileWriteBaseVersion(
          db,
          fresh.syncId,
          fresh.syncVersion,
        ),
        payload: profilePayload(fresh),
      );
      await _profile(account, epoch, isCurrent);
      return result;
    });
  }

  static String nextTimestamp(Map<String, dynamic>? old) {
    final now = DateTime.now().toUtc();
    final previous = old == null
        ? null
        : DateTime.parse(old['updatedAtUtc'] as String);
    return (previous != null && !now.isAfter(previous)
            ? previous.add(const Duration(microseconds: 1))
            : now)
        .toIso8601String();
  }
}
