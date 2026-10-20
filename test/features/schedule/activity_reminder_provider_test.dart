import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/core/services/notification_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_reminders.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/providers/activity_reminder_provider.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;

class RecordingActivities extends NotificationService {
  RecordingActivities() : super(FlutterLocalNotificationsPlugin());
  final batches = <List<ActivityReminder>>[];
  int permissions = 0, legacy = 0, mood = 0;
  @override
  Future<void> init() async {
    data.initializeTimeZones();
  }

  @override
  Future<bool> requestPermission() async {
    permissions++;
    return true;
  }

  @override
  Future<void> setKarateReminder(bool enabled) async {
    legacy++;
  }

  @override
  Future<void> setWorkoutReminder(
    bool enabled, {
    int hour = 18,
    int minute = 0,
  }) async {
    legacy++;
  }

  @override
  Future<void> setMoodCheckReminder(
    bool enabled, {
    int hour = 20,
    int minute = 30,
  }) async {
    mood++;
  }

  @override
  Future<void> replaceActivities(
    List<ActivityReminder> reminders, {
    required bool Function() isCurrent,
    bool migrated = true,
  }) async {
    if (isCurrent()) batches.add(reminders);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'startup, account-bound DB edits and durable logout reconcile dynamic alarms without old 100/101/200 or mood',
    () async {
      SharedPreferences.setMockInitialValues({
        'notif_karate': true,
        'notif_workout': false,
      });
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      await sync.bindAccount('account');
      await saveProfile(db);
      final service = RecordingActivities();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(service),
        ],
      );
      final listener = c.listen(
        activityReminderSyncProvider,
        (_, next) {},
        fireImmediately: true,
      );
      Future<void> until(bool Function() condition) async {
        for (var i = 0; i < 200 && !condition(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(condition(), isTrue);
      }

      try {
        await until(() => service.batches.any((b) => b.isNotEmpty));
        expect(service.permissions, 0);
        expect(service.legacy, 0);
        expect(service.mood, 0);
        final repo = ActivityRepository(db);
        final lease = await repo.snapshot('account');
        final karate = lease.rules.singleWhere(
          (r) => r.activityType == ActivityType.external,
        );
        final count = service.batches.length;
        await repo.setEnabled(lease, karate.id, false);
        await until(
          () => service.batches.length > count && service.batches.last.isEmpty,
        );
        final countBeforeLogout = service.batches.length;
        await db.syncDao.lockOfflineAccess();
        await until(
          () =>
              service.batches.length > countBeforeLogout &&
              service.batches.last.isEmpty,
        );
        expect(service.mood, 0);
        expect(service.permissions, 0);
      } finally {
        listener.close();
        c.dispose();
        sync.dispose();
        await db.close();
      }
    },
  );
}
