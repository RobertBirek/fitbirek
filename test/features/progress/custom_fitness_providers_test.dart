import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import '../../core/profile_collections_sync_test.dart' show saveProfile;
import 'custom_fitness_data_test.dart' show FitnessAuthority;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'read providers and workflow are passive, preserve unavailable-vs-empty and revoke A-B-A lease',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = FitnessAuthority();
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
          );
      await saveProfile(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          authStateProvider.overrideWith(
            (ref) => throw StateError('HTTP bootstrap forbidden'),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final subscription = container.listen(
        fitnessProtocolsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        (await container.read(fitnessProtocolsProvider.future)).isAvailable,
        isTrue,
      );
      expect(
        await container.read(customFitnessResultsProvider.future),
        isEmpty,
      );
      expect(await container.read(legacyTestResultsProvider.future), isEmpty);
      final workflow = container.read(fitnessTestsWorkflowProvider);
      final lease = await workflow.captureLease();
      authority.generation += 2;
      authority.revision.value = authority.generation;
      await expectLater(
        workflow.addLegacyResult(
          lease,
          typ: TypTestu.maxPompki,
          value: 4,
          performedAt: DateTime.utc(2020),
        ),
        throwsStateError,
      );
      await expectLater(
        container
            .read(testsRepositoryProvider)
            .watchProtocols()
            .first
            .then((v) => v.isAvailable),
        completion(isTrue),
      );
      await db.syncDao.lockOfflineAccess();
      expect(
        await container
            .read(testsRepositoryProvider)
            .watchCustomResults()
            .first,
        isNull,
      );
      expect(
        (await container.read(testsRepositoryProvider).watchProtocols().first)
            .isAvailable,
        isFalse,
      );
    },
  );
}
