import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import 'weekly_schedule_test.dart' show rule;

void main() {
  test(
    'schedule writes its own nullable profile column and ordinary edits preserve it',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final sync = SyncService(db, CollectionServer());
      addTearDown(sync.dispose);
      await sync.bindAccount('account');
      await saveProfile(db);
      await UserCollectionsRepository(
        db,
      ).update('account', 'weeklySchedule', (entries) => entries.add(rule()));
      await saveProfile(db, name: 'Edytowany');
      final json = (await db.userProfileDao.watchProfileOnce())!.toJson();
      expect(json['weeklyScheduleJson'], isNotNull);
      expect(
        (jsonDecode(json['weeklyScheduleJson'] as String)['entries'] as List)
            .single,
        rule(),
      );
      expect(
        (await db.syncDao.pendingOperations()).last.payload['weeklySchedule'],
        isNotNull,
      );
    },
  );
}
