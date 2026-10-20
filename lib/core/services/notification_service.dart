import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_scheduler.dart';
import '../../features/schedule/domain/activity_reminders.dart';

/// ID kanałów/notyfikacji - stałe, żeby przy re-planowaniu móc bezpiecznie
/// anulować i podmienić konkretny wpis bez wpływu na pozostałe.
class NotificationIds {
  static const karateWtorek = 100;
  static const karateCzwartek = 101;
  static const workoutReminder = 200;
  static const moodCheck = 300;
}

/// Serwis powiadomień lokalnych FitBirek.
///
/// Uwaga: `flutter_local_notifications` na platformie Web jest no-op
/// (sam plugin sprawdza `kIsWeb` wewnątrz `initialize()`/`zonedSchedule()`),
/// więc nie owijamy każdego wywołania osobno - ale i tak sprawdzamy `kIsWeb`
/// przy inicjalizacji strefy czasowej, żeby nie dotykać `timezone` bez
/// potrzeby na Web.
///
/// Strefa czasowa jest zahardkodowana na `Europe/Warsaw` - to osobisty
/// asystent dla jednego użytkownika (Robert, Polska), nie generyczna
/// wielo-userowa aplikacja, więc wykrywanie strefy urządzenia byłoby
/// niepotrzebną złożonością (i wymagałoby dodatkowego pakietu, którego
/// nie ma w zablokowanym środowisku).
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  static const _channelId = 'fitbirek_reminders';
  static const _channelName = 'Przypomnienia FitBirek';
  static const _channelDescription = 'Aktywności, treningi i dziennik samopoczucia';

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Żąda uprawnienia do wyświetlania notyfikacji (Android 13+).
  /// Zwraca `true` jeśli przyznane (lub gdy platforma tego nie wymaga).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<bool> activityPermissionGranted() async {
    if (kIsWeb) return false;
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  Future<void> _activityTail = Future.value();
  final Set<int> _activityIds = {};

  Future<void> replaceActivities(
    List<ActivityReminder> reminders, {
    required bool Function() isCurrent,
    bool migrated = true,
  }) {
    final operation = _activityTail.then((_) async {
      await init();
      final pending = await _plugin.pendingNotificationRequests();
      final ids = {
        ..._activityIds,
        for (final p in pending)
          if (p.payload?.startsWith('activity:') == true) p.id,
      };
      for (final id in ids) {
        await cancel(id);
      }
      _activityIds.clear();
      if (!isCurrent()) return;
      try {
        final otherIds = pending
            .map((p) => p.id)
            .where((id) => !ids.contains(id))
            .toSet();
        if (reminders.length > 60 || otherIds.length + reminders.length > 64) {
          throw StateError(
            'Limit urządzenia: 64 oczekujące powiadomienia (maks. 60 harmonogramu). Ogranicz przypomnienia.',
          );
        }
        if (reminders.any((r) => otherIds.contains(r.id)) ||
            reminders.map((r) => r.id).toSet().length != reminders.length) {
          throw StateError(
            'Kolizja identyfikatorów powiadomień. Nie nadpisano innych alarmów.',
          );
        }
        if (reminders.isNotEmpty && !await activityPermissionGranted()) {
          throw StateError(
            'Brak uprawnień powiadomień. Włącz je jawnie w ustawieniach.',
          );
        }
        for (final r in reminders) {
          if (!isCurrent()) break;
          _activityIds.add(r.id);
          await _plugin.zonedSchedule(
            r.id,
            r.title,
            r.body,
            r.at,
            _defaultDetails,
            payload: 'activity:${r.occurrenceId}',
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
        if (!isCurrent()) {
          for (final id in _activityIds.toList()) {
            await cancel(id);
          }
          _activityIds.clear();
          return;
        }
        if (migrated) {
          for (final id in [100, 101, 200]) {
            if (!isCurrent()) return;
            await cancel(id);
          }
        }
      } catch (_) {
        for (final id in _activityIds.toList()) {
          await cancel(id);
        }
        _activityIds.clear();
        rethrow;
      }
    });
    _activityTail = operation.catchError((Object _) {});
    return operation;
  }

  NotificationDetails get _defaultDetails => const NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Planuje/anuluje cotygodniowe przypomnienie karate (wt+czw, 19:30),
  /// powtarzane automatycznie przez [DateTimeComponents.dayOfWeekAndTime].
  Future<void> setKarateReminder(bool enabled) async {
    if (!enabled) {
      await cancel(NotificationIds.karateWtorek);
      await cancel(NotificationIds.karateCzwartek);
      return;
    }
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);

    final wtorek = NotificationScheduler.nextWeekdayTime(
      now,
      weekday: DateTime.tuesday,
      hour: 19,
      minute: 30,
    );
    final czwartek = NotificationScheduler.nextWeekdayTime(
      now,
      weekday: DateTime.thursday,
      hour: 19,
      minute: 30,
    );

    await _plugin.zonedSchedule(
      NotificationIds.karateWtorek,
      'Karate za 30 minut 🥋',
      'Trening o 20:00 - czas się szykować!',
      tz.TZDateTime.from(wtorek, tz.local),
      _defaultDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    await _plugin.zonedSchedule(
      NotificationIds.karateCzwartek,
      'Karate za 30 minut 🥋',
      'Trening o 20:00 - czas się szykować!',
      tz.TZDateTime.from(czwartek, tz.local),
      _defaultDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Planuje/anuluje codzienne przypomnienie o treningu domowym o [hour]:[minute].
  Future<void> setWorkoutReminder(
    bool enabled, {
    int hour = 18,
    int minute = 0,
  }) async {
    if (!enabled) {
      await cancel(NotificationIds.workoutReminder);
      return;
    }
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    final next = NotificationScheduler.nextDailyTime(
      now,
      hour: hour,
      minute: minute,
    );

    await _plugin.zonedSchedule(
      NotificationIds.workoutReminder,
      'Czas na trening 💪',
      'Sprawdź dzisiejszy plan i zrób serię.',
      tz.TZDateTime.from(next, tz.local),
      _defaultDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Planuje/anuluje codzienny prompt dziennika samopoczucia o [hour]:[minute].
  Future<void> setMoodCheckReminder(
    bool enabled, {
    int hour = 20,
    int minute = 30,
  }) async {
    if (!enabled) {
      await cancel(NotificationIds.moodCheck);
      return;
    }
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    final next = NotificationScheduler.nextDailyTime(
      now,
      hour: hour,
      minute: minute,
    );

    await _plugin.zonedSchedule(
      NotificationIds.moodCheck,
      'Jak się dziś czujesz? 📝',
      'Zapisz szybki wpis: sen, energia, nastrój, apetyt.',
      tz.TZDateTime.from(next, tz.local),
      _defaultDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
