import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/exercise_filter_engine.dart';
import '../domain/filter_preset.dart';

class DuplicatePresetName implements Exception {
  const DuplicatePresetName(this.existing);
  final FilterPreset existing;
}

class FilterPresetsRepository {
  FilterPresetsRepository({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  Future<void> _tail = Future.value();

  static String storageKey(String accountId) =>
      'exercise_filter_presets.v1.${base64Url.encode(utf8.encode(accountId))}';

  void _guard(String account, bool Function()? isCurrent) {
    if (account.trim().isEmpty || !(isCurrent?.call() ?? true)) {
      throw StateError('Brak aktywnego konta.');
    }
  }

  List<FilterPreset> _read(SharedPreferences prefs, String key) {
    try {
      final raw = prefs.getString(key);
      if (raw == null) return [];
      final json = jsonDecode(raw);
      if (json is! Map || json['version'] != 1 || json['presets'] is! List) {
        return [];
      }
      final result = <FilterPreset>[];
      for (final entry in json['presets'] as List) {
        try {
          final preset = FilterPreset.fromJson(entry as Map<String, dynamic>);
          if (!result.any(
            (p) =>
                p.id == preset.id ||
                p.name.toLowerCase() == preset.name.toLowerCase(),
          )) {
            result.add(preset);
          }
        } catch (_) {
          // A broken entry must not hide valid siblings.
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<FilterPreset>> load(
    String account, {
    bool Function()? isCurrent,
  }) async {
    _guard(account, isCurrent);
    final key = storageKey(account);
    final prefs = await _preferences();
    _guard(account, isCurrent);
    return _read(prefs, key);
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> _write(
    SharedPreferences prefs,
    String key,
    List<FilterPreset> items,
  ) async {
    final ok = await prefs.setString(
      key,
      jsonEncode({
        'version': 1,
        'presets': items.map((p) => p.toJson()).toList(),
      }),
    );
    if (!ok) throw StateError('Nie udało się zapisać filtrów.');
  }

  Future<FilterPreset> save(
    String account,
    String name,
    ExerciseFilters filters, {
    String? overwriteId,
    bool Function()? isCurrent,
  }) async {
    // Snapshot mutable caller sets before any await or queued work.
    final clean = FilterPreset.validateName(name);
    final snapshot = FilterPreset(
      id: const Uuid().v4(),
      name: clean,
      filters: filters,
    );
    return _serial(() async {
      _guard(account, isCurrent);
      final key = storageKey(account);
      final prefs = await _preferences();
      _guard(account, isCurrent);
      final items = _read(prefs, key);
      final matches = items.where(
        (p) => p.name.toLowerCase() == clean.toLowerCase(),
      );
      final existing = matches.isEmpty ? null : matches.first;
      if (existing != null && existing.id != overwriteId) {
        throw DuplicatePresetName(existing);
      }
      if (overwriteId != null && existing?.id != overwriteId) {
        throw StateError('Zestaw do zastąpienia zmienił się.');
      }
      final saved = FilterPreset(
        id: existing?.id ?? snapshot.id,
        name: clean,
        filters: snapshot.filters,
      );
      items.removeWhere((p) => p.id == saved.id);
      items.add(saved);
      _guard(account, isCurrent);
      await _write(prefs, key, items);
      _guard(account, isCurrent);
      return saved;
    });
  }

  Future<void> delete(
    String account,
    String id, {
    bool Function()? isCurrent,
  }) => _serial(() async {
    _guard(account, isCurrent);
    final key = storageKey(account);
    final prefs = await _preferences();
    _guard(account, isCurrent);
    final items = _read(prefs, key)..removeWhere((p) => p.id == id);
    await _write(prefs, key, items);
    _guard(account, isCurrent);
  });
}
