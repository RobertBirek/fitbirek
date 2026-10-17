import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/data/filter_presets_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';

Future<void> flush() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('cached binding works offline without HTTP auth', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authStateProvider.overrideWith(
          (ref) => throw StateError('Auth bootstrap forbidden'),
        ),
        apiClientProvider.overrideWith(
          (ref) => throw StateError('HTTP forbidden'),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    final subscription = c.listen(filterPresetsProvider, (_, __) {});
    addTearDown(subscription.close);
    await flush();
    expect(c.read(filterPresetsProvider.notifier).accountId, isNull);
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(accountId: 'opaque', deviceId: 'device'),
        );
    await flush();
    await UserProfileRepository(db).saveProfile(
      imie: 'Offline',
      wiek: 40,
      wzrostCm: 180,
      wagaKg: 80,
      cel: CelTreningowy.mix,
      dostepnySprzet: [],
    );
    await c
        .read(filterPresetsProvider.notifier)
        .save('Offline', const ExerciseFilters(query: 'dom'));
    expect(c.read(filterPresetsProvider).requireValue.single.name, 'Offline');
    await db
        .update(db.syncState)
        .write(const SyncStateCompanion(offlineAccess: Value(false)));
    await flush();
    expect(c.read(filterPresetsProvider.notifier).accountId, isNull);
    expect(c.read(filterPresetsProvider).valueOrNull, isEmpty);
    await expectLater(
      c
          .read(filterPresetsProvider.notifier)
          .save('No', const ExerciseFilters()),
      throwsStateError,
    );
  });
  test('switch invalidates pending mutations and hides old account', () async {
    final binding = StreamController<String?>();
    final prefs = await SharedPreferences.getInstance();
    final gate = Completer<SharedPreferences>();
    var delay = false;
    final repository = FilterPresetsRepository(
      preferences: () => delay ? gate.future : Future.value(prefs),
    );
    await repository.save('A', 'A preset', const ExerciseFilters());
    final c = ProviderContainer(
      overrides: [
        filterPresetsAccountProvider.overrideWith((ref) => binding.stream),
        filterPresetsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await binding.close();
    });
    c.listen(filterPresetsProvider, (_, __) {});
    binding.add('A');
    await flush();
    final old = c.read(filterPresetsProvider.notifier);
    delay = true;
    final saving = old.save('Late', const ExerciseFilters());
    final deleting = old.delete('missing');
    final savingExpectation = expectLater(saving, throwsStateError);
    final deletingExpectation = expectLater(deleting, throwsStateError);
    binding.add('B');
    await flush();
    gate.complete(prefs);
    await savingExpectation;
    await deletingExpectation;
    await flush();
    expect(c.read(filterPresetsProvider).requireValue, isEmpty);
    expect(await repository.load('B'), isEmpty);
    expect(await repository.load('A'), hasLength(1));
    delay = false;
    binding.add('A');
    await flush();
    expect(c.read(filterPresetsProvider).requireValue.single.name, 'A preset');
    binding.add(null);
    await flush();
    expect(c.read(filterPresetsProvider).requireValue, isEmpty);
  });
  test('late load from A cannot publish into B or after logout', () async {
    final prefs = await SharedPreferences.getInstance();
    await FilterPresetsRepository().save(
      'A',
      'Private',
      const ExerciseFilters(),
    );
    final gate = Completer<SharedPreferences>();
    final accounts = StreamController<String?>();
    final c = ProviderContainer(
      overrides: [
        filterPresetsAccountProvider.overrideWith((ref) => accounts.stream),
        filterPresetsRepositoryProvider.overrideWithValue(
          FilterPresetsRepository(preferences: () => gate.future),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await accounts.close();
    });
    final seen = <String>[];
    c.listen(filterPresetsProvider, (_, next) {
      seen.addAll((next.valueOrNull ?? []).map((p) => p.name));
    });
    accounts.add('A');
    await flush();
    accounts.add('B');
    await flush();
    gate.complete(prefs);
    await flush();
    expect(seen, isEmpty);
    expect(c.read(filterPresetsProvider).requireValue, isEmpty);
    accounts.add(null);
    await flush();
    expect(c.read(filterPresetsProvider).requireValue, isEmpty);
  });
}
