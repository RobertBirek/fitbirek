import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as data;
import 'package:fitbirek_training/core/services/notification_service.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  late NotificationService service;
  bool granted = true;
  Completer<void>? scheduled;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    data.initializeTimeZones();
    calls = [];
    granted = true;
    scheduled = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'pendingNotificationRequests') {
            return [
              {
                'id': 12345,
                'title': 'old',
                'body': 'old',
                'payload': 'activity:old',
              },
              {'id': 300, 'title': 'mood', 'body': 'mood', 'payload': null},
            ];
          }
          if (call.method == 'zonedSchedule' && scheduled != null) {
            await scheduled!.future;
          }
          return granted;
        });
    service = NotificationService(FlutterLocalNotificationsPlugin());
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  ActivityReminder reminder() => ActivityReminder(
    998877,
    'occurrence',
    'Basen',
    '12:30',
    tz.TZDateTime(tz.getLocation('Europe/Warsaw'), 2027, 1, 1, 12, 30),
  );
  List<int> cancelled() => calls
      .where((c) => c.method == 'cancel')
      .map((c) => (c.arguments as Map)['id'] as int)
      .toList();
  test(
    'native reconciles owned IDs only, cancels legacy after success, no automatic permission',
    () async {
      await service.replaceActivities([reminder()], isCurrent: () => true);
      expect(cancelled(), containsAll([12345, 100, 101, 200]));
      expect(cancelled(), isNot(contains(300)));
      expect(
        calls.where(
          (c) =>
              c.method == 'cancelAll' ||
              c.method == 'requestNotificationsPermission',
        ),
        isEmpty,
      );
      final schedule =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(schedule['id'], 998877);
      expect(schedule['matchDateTimeComponents'], isNull);
      await service.replaceActivities(
        [],
        isCurrent: () => true,
        migrated: false,
      );
      expect(cancelled(), contains(998877));
    },
  );
  test(
    'denied permission reports error and does not cancel still-working legacy',
    () async {
      granted = false;
      await expectLater(
        service.replaceActivities([reminder()], isCurrent: () => true),
        throwsStateError,
      );
      expect(cancelled(), isNot(contains(100)));
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    },
  );
  test(
    'logout while platform call pending cancels captured dynamic IDs, not mood',
    () async {
      var current = true;
      scheduled = Completer<void>();
      final operation = service.replaceActivities([
        reminder(),
      ], isCurrent: () => current);
      while (!calls.any((c) => c.method == 'zonedSchedule')) {
        await Future<void>.delayed(Duration.zero);
      }
      current = false;
      scheduled!.complete();
      await operation;
      expect(cancelled(), contains(998877));
      expect(cancelled(), isNot(contains(300)));
      expect(cancelled(), isNot(contains(100)));
    },
  );
}
