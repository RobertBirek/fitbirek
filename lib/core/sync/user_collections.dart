import 'dart:convert';
import '../../features/exercises/domain/filter_preset.dart';

/// Profile-owned versioned collections. Never prune tombstones or malformed data.
abstract final class UserCollections {
  static const keys = ['filterPresets', 'exerciseVariants'];
  static const maxEntries = 500;
  static const maxBytes = 262144;
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static Map<String, dynamic> empty() => {'version': 1, 'entries': <dynamic>[]};
  static bool isUuid(Object? value) => value is String && _uuid.hasMatch(value);

  static Map<String, dynamic> validate(String key, Object? value) {
    Never bad() =>
        throw FormatException('Nieprawidłowa kolekcja $key. Dane zachowano.');
    if (!keys.contains(key) ||
        value is! Map ||
        value['version'] != 1 ||
        value['entries'] is! List) {
      bad();
    }
    final map = Map<String, dynamic>.from(value);
    final entries = map['entries'] as List;
    if (entries.length > maxEntries ||
        utf8.encode(jsonEncode(map)).length > maxBytes) {
      bad();
    }
    final ids = <String>{};
    DateTime date(Object? v) {
      if (v is! String || !v.endsWith('Z')) bad();
      final d = DateTime.tryParse(v);
      if (d == null) bad();
      return d;
    }

    for (final raw in entries) {
      if (raw is! Map) bad();
      final e = Map<String, dynamic>.from(raw);
      if (!isUuid(e['id']) || !ids.add(e['id'] as String)) bad();
      final name = e['name'];
      if (name is! String || name.trim().isEmpty || name.runes.length > 80) {
        bad();
      }
      final created = date(e['createdAtUtc']);
      final updated = date(e['updatedAtUtc']);
      if (updated.isBefore(created)) bad();
      if (e['deletedAtUtc'] != null &&
          date(e['deletedAtUtc']).isAfter(updated)) {
        bad();
      }
      if (key == 'filterPresets') {
        if (e['filters'] is! Map) bad();
        FilterPreset.decodeFilters(
          Map<String, dynamic>.from(e['filters'] as Map),
        );
      } else {
        if (e['exerciseId'] is! String || (e['exerciseId'] as String).isEmpty) {
          bad();
        }
        for (final field in ['tempo', 'rangeOfMotion', 'cue']) {
          final s = e[field];
          if (s != null && (s is! String || s.runes.length > 1000)) bad();
        }
        final load = e['loadKg'];
        if (load != null &&
            (load is! num || !load.isFinite || load <= 0 || load > 1000)) {
          bad();
        }
        final pause = e['pauseSeconds'];
        if (pause != null && (pause is! int || pause < 0 || pause > 3600)) {
          bad();
        }
      }
    }
    return jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
  }

  static String canonical(Object? v) {
    Object? sorted(Object? x) {
      if (x is Map) {
        final keys = x.keys.cast<String>().toList()..sort();
        return {for (final k in keys) k: sorted(x[k])};
      }
      if (x is List) return x.map(sorted).toList();
      return x;
    }

    return jsonEncode(sorted(v));
  }

  static Map<String, dynamic> merge(String key, Object? local, Object? remote) {
    final a = validate(key, local ?? empty());
    final b = validate(key, remote ?? empty());
    final byId = <String, Map<String, dynamic>>{};
    for (final raw in [...a['entries'] as List, ...b['entries'] as List]) {
      final e = Map<String, dynamic>.from(raw as Map);
      final id = e['id'] as String;
      final old = byId[id];
      if (old == null) {
        byId[id] = e;
        continue;
      }
      var cmp = DateTime.parse(
        e['updatedAtUtc'] as String,
      ).compareTo(DateTime.parse(old['updatedAtUtc'] as String));
      if (cmp == 0) {
        cmp = (e['deletedAtUtc'] != null ? 1 : 0).compareTo(
          old['deletedAtUtc'] != null ? 1 : 0,
        );
      }
      if (cmp == 0) cmp = canonical(e).compareTo(canonical(old));
      if (cmp > 0) byId[id] = e;
    }
    final ids = byId.keys.toList()..sort();
    return validate(key, {
      'version': 1,
      'entries': [for (final id in ids) byId[id]],
    });
  }

  static void columnsToWire(
    Map<String, dynamic> json, {
    bool validateLive = true,
  }) {
    for (final key in keys) {
      final raw = json.remove('${key}Json');
      if (raw == null) continue;
      final value = jsonDecode(raw as String);
      json[key] = validateLive ? validate(key, value) : value;
    }
  }

  static void validateVariantPair(Map<String, dynamic> json) {
    final id = json['variantId'];
    if (id == null) {
      json['variantLabel'] = null;
      return;
    }
    final label = json['variantLabel'];
    if (!isUuid(id) ||
        label is! String ||
        label.trim().isEmpty ||
        label.runes.length > 80) {
      throw const FormatException('Nieprawidłowy wariant serii / rekordu.');
    }
  }
}
