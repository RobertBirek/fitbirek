import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/core/utils/profile_input.dart';
import 'package:fitbirek_training/core/utils/numeric_input.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';

class ProfileAuthority extends CachedAuthWriteAuthority {
  int generation = 0;
  String account = 'A';
  @override
  int get epoch => generation;
  @override
  AuthState get state => AuthState.signedIn(account);
  void switchTo(String next) {
    account = next;
    generation++;
  }
}

void main() {
  test(
    'profile formatter preserves the exact double without exponent input',
    () {
      for (final value in [94.5, 94.50000000000001, 1e-7, 1.234e22]) {
        final text = formatProfileNumber(value);
        expect(text, isNot(contains('e')));
        expect(parseDecimal(text), value);
        expect(validProfileNumbers(47, value, value), isTrue);
      }
    },
  );
  late AppDatabase db;
  late UserProfileRepository repo;
  late ProfileAuthority auth;
  Future<void> save({
    ProfileEdit? edit,
    int age = 47,
    double height = 180.5,
    double weight = 94.5,
    CelTreningowy goal = CelTreningowy.mix,
    bool Function()? current,
  }) => repo.saveProfile(
    imie: 'Test',
    wiek: age,
    wzrostCm: height,
    wagaKg: weight,
    cel: goal,
    dostepnySprzet: const ['Masa własna'],
    edit: edit,
    isCurrent: current,
  );
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    auth = ProfileAuthority();
    repo = UserProfileRepository(db, authority: auth);
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            accountId: 'A',
            deviceId: 'device',
            offlineAccess: const Value(true),
          ),
        );
    await save();
    await db.delete(db.syncOutbox).go();
  });
  tearDown(() async {
    auth.revision.dispose();
    await db.close();
  });

  test('repo rejects invalid numbers before SQLite or outbox writes', () async {
    final before = await db.userProfileDao.watchProfileOnce();
    for (final weight in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(save(weight: weight), throwsArgumentError);
    }
    await expectLater(save(age: 0), throwsArgumentError);
    await expectLater(save(height: double.nan), throwsArgumentError);
    expect(await db.userProfileDao.watchProfileOnce(), before);
    expect(await db.syncDao.pendingOperations(), isEmpty);
  });

  test('goal only edit keeps exact fractions and collection JSON', () async {
    const unknown = '{"version":1,"entries":[]}';
    await db
        .update(db.userProfiles)
        .write(
          const UserProfilesCompanion(exerciseVariantsJson: Value(unknown)),
        );
    final edit = await repo.captureEdit();
    await save(edit: edit, goal: CelTreningowy.values.first);
    final after = (await db.userProfileDao.watchProfileOnce())!;
    expect(after.wagaKg, 94.5);
    expect(after.wzrostCm, 180.5);
    expect(after.exerciseVariantsJson, unknown);
    expect(
      (await db.syncDao.pendingOperations()).single.payload['wagaKg'],
      94.5,
    );
  });

  test(
    'unknown collection schema refuses save without destroying newer data',
    () async {
      await db
          .update(db.userProfiles)
          .write(
            const UserProfilesCompanion(
              exerciseVariantsJson: Value(
                '{"version":99,"future":{"keep":true}}',
              ),
            ),
          );
      final edit = await repo.captureEdit();
      await expectLater(save(edit: edit), throwsFormatException);
      expect(await db.userProfileDao.watchProfileOnce(), edit.row);
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'remote row and collection changes refuse stale optimistic baseline',
    () async {
      for (final change in [
        const UserProfilesCompanion(wagaKg: Value(95.75)),
        const UserProfilesCompanion(
          weeklyScheduleJson: Value('{"version":99}'),
        ),
        const UserProfilesCompanion(syncVersion: Value(2)),
      ]) {
        final edit = await repo.captureEdit();
        await db.update(db.userProfiles).write(change);
        final remote = await db.userProfileDao.watchProfileOnce();
        await expectLater(
          save(edit: edit),
          throwsA(isA<ProfileEditConflict>()),
        );
        expect(await db.userProfileDao.watchProfileOnce(), remote);
        expect(await db.syncDao.pendingOperations(), isEmpty);
      }
    },
  );

  test(
    'device binding replacement and disabled offline access refuse save',
    () async {
      final edit = await repo.captureEdit();
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(deviceId: Value('new')));
      await expectLater(save(edit: edit), throwsA(isA<ProfileEditConflict>()));
      await db
          .update(db.syncState)
          .write(
            const SyncStateCompanion(
              deviceId: Value('device'),
              offlineAccess: Value(false),
            ),
          );
      await expectLater(save(edit: edit), throwsA(isA<ProfileEditConflict>()));
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'queued transaction rejects A-B-A even with same persistent binding',
    () async {
      final edit = await repo.captureEdit();
      final entered = Completer<void>(), release = Completer<void>();
      final block = db.transaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final pending = save(edit: edit);
      final rejected = expectLater(
        pending,
        throwsA(isA<ProfileEditConflict>()),
      );
      auth.switchTo('B');
      auth.switchTo('A');
      release.complete();
      await block;
      await rejected;
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect((await db.userProfileDao.watchProfileOnce())!.wagaKg, 94.5);
    },
  );

  test('queued load rejects A-B-A, and cancellation does not write', () async {
    final entered = Completer<void>(), release = Completer<void>();
    final block = db.transaction(() async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final pending = repo.captureEdit();
    final rejected = expectLater(pending, throwsA(isA<ProfileEditConflict>()));
    auth.switchTo('B');
    auth.switchTo('A');
    release.complete();
    await block;
    await rejected;
    final edit = await repo.captureEdit();
    await expectLater(
      save(edit: edit, current: () => false),
      throwsA(isA<ProfileEditConflict>()),
    );
    expect(await db.syncDao.pendingOperations(), isEmpty);
  });

  test(
    'legacy initial offline onboarding without binding still creates profile',
    () async {
      await db.delete(db.userProfiles).go();
      await db.delete(db.syncState).go();
      await save();
      expect((await repo.getProfileOnce())!.wagaKg, 94.5);
      expect(await db.syncDao.pendingOperations(), hasLength(1));
    },
  );

  for (final held in [false, true]) {
    test(
      '${held ? 'hold' : 'deferred record'} arriving while form open is retained and blocks edit',
      () async {
        final edit = await repo.captureEdit();
        await db
            .into(db.syncDeferredRecords)
            .insert(
              SyncDeferredRecordsCompanion.insert(
                entityType: held ? '_syncPushHold' : 'profile',
                entityId: held ? 'operation' : edit.row.syncId,
                version: edit.row.syncVersion,
                recordJson: held
                    ? jsonEncode({
                        'accountId': 'A',
                        'key': 'profile:${edit.row.syncId}',
                      })
                    : '{}',
              ),
            );
        final before = await db.select(db.syncDeferredRecords).get();
        await expectLater(
          save(edit: edit),
          throwsA(isA<ProfileEditConflict>()),
        );
        expect(await db.select(db.syncDeferredRecords).get(), before);
        expect(await db.userProfileDao.watchProfileOnce(), edit.row);
        expect(await db.syncDao.pendingOperations(), isEmpty);
      },
    );
  }
}
