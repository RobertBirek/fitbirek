import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/exercise_filter_engine.dart';
import '../domain/filter_preset.dart';
import 'user_collections_repository.dart';

class DuplicatePresetName implements Exception {
  const DuplicatePresetName(this.existing);
  final FilterPreset existing;
}

class FilterPresetsRepository {
  FilterPresetsRepository({
    Future<SharedPreferences> Function()? preferences,
    this.cloud,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  final UserCollectionsRepository? cloud;
  Future<void> _tail = Future.value();
  bool Function() _capture(bool Function()? current) {
    final authority = cloud?.authority, epoch = cloud?.authority?.epoch;
    return () => (current?.call() ?? true) && authority?.epoch == epoch;
  }

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

  List<FilterPreset> _readForImport(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['version'] != 1 || json['presets'] is! List) {
        throw const FormatException('Invalid legacy presets');
      }
      final items = (json['presets'] as List)
          .map(
            (e) => FilterPreset.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      if (items.map((e) => e.id).toSet().length != items.length) {
        throw const FormatException('Duplicate legacy IDs');
      }
      return items;
    } catch (_) {
      throw const FormatException(
        'Nie można zaimportować lokalnych filtrów. Dane źródłowe zachowano.',
      );
    }
  }

  Future<List<FilterPreset>> load(
    String account, {
    bool Function()? isCurrent,
  }) async {
    isCurrent = _capture(isCurrent);
    _guard(account, isCurrent);
    final key = storageKey(account);
    final prefs = await _preferences();
    _guard(account, isCurrent);
    if (cloud != null) {
      final marker = '$key.drift-imported';
      if (prefs.getBool(marker) != true) {
        final legacy = _readForImport(prefs, key);
        if (legacy.isNotEmpty) {
          await cloud!.update(account, 'filterPresets', (entries) {
            for (final preset in legacy) {
              if (entries.any((e) => e['id'] == preset.id)) continue;
              // The old format has no trustworthy edit time. Import is not a
              // new user edit: an unseen cloud value/tombstone must outrank it.
              // Explicit save after import still receives the real current UTC.
              const stamp = '1970-01-01T00:00:00.000Z';
              entries.add({
                ...preset.toJson(),
                'createdAtUtc': stamp,
                'updatedAtUtc': stamp,
              });
            }
          }, isCurrent: isCurrent);
        } else {
          // Require an available, validated profile before marking migration.
          await cloud!.load(account, 'filterPresets', isCurrent: isCurrent);
        }
        _guard(account, isCurrent);
        if (!await prefs.setBool(marker, true)) {
          throw StateError('Nie zapisano znacznika migracji.');
        }
      }
      final collection = await cloud!.load(
        account,
        'filterPresets',
        isCurrent: isCurrent,
      );
      _guard(account, isCurrent);
      return (collection['entries'] as List)
          .where((e) => e['deletedAtUtc'] == null)
          .map(
            (e) => FilterPreset.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }
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
    isCurrent = _capture(isCurrent);
    // Snapshot mutable caller sets before any await or queued work.
    final clean = FilterPreset.validateName(name);
    final snapshot = FilterPreset(
      id: const Uuid().v4(),
      name: clean,
      filters: filters,
    );
    return _serial(() async {
      _guard(account, isCurrent);
      if (cloud != null) {
        await load(account, isCurrent: isCurrent);
        return cloud!.update(account, 'filterPresets', (entries) {
          final live = entries.where((e) => e['deletedAtUtc'] == null).toList();
          final matches = live.where(
            (e) => (e['name'] as String).toLowerCase() == clean.toLowerCase(),
          );
          final existing = matches.isEmpty ? null : matches.first;
          if (existing != null && existing['id'] != overwriteId) {
            throw DuplicatePresetName(FilterPreset.fromJson(existing));
          }
          if (overwriteId != null && existing?['id'] != overwriteId) {
            throw StateError('Zestaw do zastąpienia zmienił się.');
          }
          final saved = FilterPreset(
            id: existing?['id'] as String? ?? snapshot.id,
            name: clean,
            filters: snapshot.filters,
          );
          final stamp = UserCollectionsRepository.nextTimestamp(existing);
          entries.removeWhere((e) => e['id'] == saved.id);
          entries.add({
            ...saved.toJson(),
            'createdAtUtc': existing?['createdAtUtc'] ?? stamp,
            'updatedAtUtc': stamp,
          });
          return saved;
        }, isCurrent: isCurrent);
      }
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

  Future<void> delete(String account, String id, {bool Function()? isCurrent}) {
    isCurrent = _capture(isCurrent);
    return _serial(() async {
      _guard(account, isCurrent);
      if (cloud != null) {
        await load(account, isCurrent: isCurrent);
        await cloud!.update(account, 'filterPresets', (entries) {
          for (final e in entries.where(
            (e) => e['id'] == id && e['deletedAtUtc'] == null,
          )) {
            final stamp = UserCollectionsRepository.nextTimestamp(e);
            e.addAll({'updatedAtUtc': stamp, 'deletedAtUtc': stamp});
          }
        }, isCurrent: isCurrent);
        return;
      }
      final key = storageKey(account);
      final prefs = await _preferences();
      _guard(account, isCurrent);
      final items = _read(prefs, key)..removeWhere((p) => p.id == id);
      await _write(prefs, key, items);
      _guard(account, isCurrent);
    });
  }
}
