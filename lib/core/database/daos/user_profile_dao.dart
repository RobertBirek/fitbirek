import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_profile_table.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfiles])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  /// Zawsze mamy jednego użytkownika (id=1) - single user app.
  Future<UserProfileData?> watchProfileOnce() {
    return (select(
      userProfiles,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  Stream<UserProfileData?> watchProfile() {
    return (select(userProfiles)
          ..where((t) => t.id.equals(1) & t.deletedAtUtc.isNull()))
        .watchSingleOrNull();
  }

  Future<void> upsertProfile(UserProfilesCompanion profile) {
    return into(userProfiles).insertOnConflictUpdate(profile);
  }
}
