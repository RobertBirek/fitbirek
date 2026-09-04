import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Klucze SharedPreferences dla prostych ustawień aplikacji.
class _PrefKeys {
  static const themeMode = 'theme_mode';
  static const soundEnabled = 'sound_enabled';
  static const vibrationEnabled = 'vibration_enabled';
  static const gongSound = 'gong_sound';
}

/// Stan ustawień aplikacji.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.gongSound,
  });

  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String gongSound; // 'gong1' | 'gong2' | 'gong3'

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? gongSound,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      gongSound: gongSound ?? this.gongSound,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
    : super(
        const AppSettings(
          themeMode: ThemeMode.dark,
          soundEnabled: true,
          vibrationEnabled: true,
          gongSound: 'gong1',
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString(_PrefKeys.themeMode) ?? 'dark';
    final soundEnabled = prefs.getBool(_PrefKeys.soundEnabled) ?? true;
    final vibrationEnabled = prefs.getBool(_PrefKeys.vibrationEnabled) ?? true;
    final gongSound = prefs.getString(_PrefKeys.gongSound) ?? 'gong1';

    state = AppSettings(
      themeMode: _themeModeFromString(themeModeStr),
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      gongSound: gongSound,
    );
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
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
