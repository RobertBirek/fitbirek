import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/app/constants.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/onboarding/presentation/pages/onboarding_equipment_page.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/edit_profile_page.dart';

void main() {
  test('explicit separate equipment vocabulary', () {
    expect(
      AppConstants.dostepnySprzetOpcje,
      containsAll([
        'Step',
        'Ławka do brzuszków',
        'Ławka ujemna do wyciskania',
        'Wrist roller',
        'Poduszka równoważna',
        'Roller',
        'Mata',
        'Pasy do zwisu za nogi',
        'Ławeczka',
      ]),
    );
  });
  testWidgets('onboarding has no automatic selection', (tester) async {
    List<String>? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingEquipmentPage(
          initialSelection: const [],
          onBack: () {},
          onFinish: (v) => saved = v,
        ),
      ),
    );
    await tester.tap(find.text('Zakończ konfigurację'));
    expect(saved, isEmpty);
  });
  testWidgets('profile gear edit preserves unknown fields and normal outbox', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            accountId: 'A',
            deviceId: 'device',
            offlineAccess: const Value(true),
          ),
        );
    final repo = UserProfileRepository(db);
    await repo.saveProfile(
      imie: 'Owner',
      wiek: 47,
      wzrostCm: 180.5,
      wagaKg: 94.5,
      cel: CelTreningowy.mix,
      dostepnySprzet: ['Starszy sprzęt', 'Ławka do brzuszków'],
    );
    final before = (await db.userProfileDao.watchProfileOnce())!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userProfileRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edytuj sprzęt'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Step'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Step'));
    await tester.tap(find.text('Zastosuj'));
    await tester.pumpAndSettle();
    expect(
      (await db.userProfileDao.watchProfileOnce())!.dostepnySprzet,
      before.dostepnySprzet,
    );
    await tester.ensureVisible(find.text('Zapisz'));
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    final after = (await db.userProfileDao.watchProfileOnce())!;
    expect(jsonDecode(after.dostepnySprzet), [
      'Starszy sprzęt',
      'Ławka do brzuszków',
      'Step',
    ]);
    expect(after.imie, before.imie);
    expect(after.wagaKg, before.wagaKg);
    expect(after.wzrostCm, before.wzrostCm);
    expect(after.cel, before.cel);
    expect(after.dataUtworzenia, before.dataUtworzenia);
    final pending = await db.select(db.syncOutbox).get();
    expect(pending, isNotEmpty);
    expect(pending.last.payloadJson, contains('Step'));
    expect(pending.last.payloadJson, contains('Starszy sprzęt'));
  });
}
