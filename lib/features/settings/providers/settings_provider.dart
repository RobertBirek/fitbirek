import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/notification_provider.dart';
import '../../../core/services/notification_service.dart';

/// Klucze SharedPreferences dla prostych ustawień aplikacji.
class _PrefKeys {
  static const themeMode = 'theme_mode';
  static const soundEnabled = 'sound_enabled';
  static const vibrationEnabled = 'vibration_enabled';
  static const gongSound = 'gong_sound';
  static const notifKarate = 'notif_karate';
  static const notifWorkout = 'notif_workout';
  static const notifMood = 'notif_mood';
}

/// Stan ustawień aplikacji.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.gongSound,
    required this.notifKarate,
    required this.notifWorkout,
    required this.notifMood,
  });

  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String gongSound; // 'gong1' | 'gong2' | 'gong3'
  final bool notifKarate;
  final bool notifWorkout;
  final bool notifMood;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? gongSound,
    bool? notifKarate,
    bool? notifWorkout,
    bool? notifMood,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      gongSound: gongSound ?? this.gongSound,
      notifKarate: notifKarate ?? this.notifKarate,
      notifWorkout: notifWorkout ?? this.notifWorkout,
      notifMood: notifMood ?? this.notifMood,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._notificationService)
    : super(
        const AppSettings(
          themeMode: ThemeMode.dark,
          soundEnabled: true,
          vibrationEnabled: true,
          gongSound: 'gong1',
          notifKarate: false,
          notifWorkout: false,
          notifMood: false,
        ),
      ) {
    _load();
  }

  final NotificationService _notificationService;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString(_PrefKeys.themeMode) ?? 'dark';
    final soundEnabled = prefs.getBool(_PrefKeys.soundEnabled) ?? true;
    final vibrationEnabled = prefs.getBool(_PrefKeys.vibrationEnabled) ?? true;
    final gongSound = prefs.getString(_PrefKeys.gongSound) ?? 'gong1';
    final notifKarate = prefs.getBool(_PrefKeys.notifKarate) ?? false;
    final notifWorkout = prefs.getBool(_PrefKeys.notifWorkout) ?? false;
    final notifMood = prefs.getBool(_PrefKeys.notifMood) ?? false;

    state = AppSettings(
      themeMode: _themeModeFromString(themeModeStr),
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      gongSound: gongSound,
      notifKarate: notifKarate,
      notifWorkout: notifWorkout,
      notifMood: notifMood,
    );

    // Re-zastosuj harmonogram przy starcie (np. po restarcie urządzenia
    // exact alarmy Androida mogłyby zostać wyczyszczone poza BOOT_COMPLETED
    // receiver, więc lepiej odtworzyć je jawnie przy każdym starcie appki).
    await _notificationService.init();
    if (notifKarate) await _notificationService.setKarateReminder(true);
    if (notifWorkout) await _notificationService.setWorkoutReminder(true);
    if (notifMood) await _notificationService.setMoodCheckReminder(true);
  }

  ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.themeMode, _themeModeToString(mode));
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.soundEnabled, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    state = state.copyWith(vibrationEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.vibrationEnabled, value);
  }

  Future<void> setGongSound(String value) async {
    state = state.copyWith(gongSound: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.gongSound, value);
  }

  /// Włącza/wyłącza przypomnienie karate (wt/czw 19:30). Przy włączaniu
  /// żąda uprawnienia do notyfikacji (Android 13+) - jeśli użytkownik
  /// odmówi, przełącznik i tak zostaje ustawiony (harmonogram po prostu
  /// nie wyświetli notyfikacji do momentu przyznania uprawnienia w
  /// ustawieniach systemowych).
  Future<void> setNotifKarate(bool value) async {
    if (value) await _notificationService.requestPermission();
    state = state.copyWith(notifKarate: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.notifKarate, value);
    await _notificationService.setKarateReminder(value);
  }

  Future<void> setNotifWorkout(bool value) async {
    if (value) await _notificationService.requestPermission();
    state = state.copyWith(notifWorkout: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.notifWorkout, value);
    await _notificationService.setWorkoutReminder(value);
  }

  Future<void> setNotifMood(bool value) async {
    if (value) await _notificationService.requestPermission();
    state = state.copyWith(notifMood: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.notifMood, value);
    await _notificationService.setMoodCheckReminder(value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(ref.watch(notificationServiceProvider));
});
