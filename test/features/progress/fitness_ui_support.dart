import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import '../../core/profile_collections_sync_test.dart' as profiles;

Future<({AppDatabase db, TestsRepository repo})> fitnessUiFixture() async {
  await initializeDateFormatting('pl_PL');
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db
      .into(db.syncState)
      .insert(
        SyncStateCompanion.insert(accountId: 'ui-test', deviceId: 'ui-device'),
      );
  await profiles.saveProfile(db);
  await db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          id: 'cw001',
          nazwaPl: 'Pompki klasyczne',
          nazwaEn: 'Push-up',
          partiaGlowna: 'Klatka',
          partieWspierajace: '[]',
          sprzet: '[]',
          typ: 'Siłowe',
          poziom: 'Średni',
          wzorzecRuchu: '',
          seriexPowtorzenia: '',
          tempo: '',
          kluczoweWskazowki: '[]',
          czesteBledy: '[]',
          progresja: '',
          regresja: '',
          zrodlo: 'Test fixture',
        ),
      );
  return (
    db: db,
    repo: TestsRepository(db, authority: CachedAuthWriteAuthority()),
  );
}
