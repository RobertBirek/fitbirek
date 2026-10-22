import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

/// Strict, versioned allow-list. Decode the entire manifest before opening the
/// import transaction; an unknown revision must never partially update a device.
class ExerciseCatalogCorrection {
  ExerciseCatalogCorrection._(this.exerciseId, this.fields);
  final String exerciseId;
  final Map<String, Object> fields;

  static const _ids = {'cw009', 'cw123', 'cw135', 'cw136', 'cw165', 'cw267'};
  static const _lists = {'sprzet', 'kluczoweWskazowki', 'czesteBledy'};
  static const _strings = {'nazwaPl', 'progresja', 'regresja'};

  static List<ExerciseCatalogCorrection> parse(String source) {
    final root = jsonDecode(source);
    Never invalid() =>
        throw const FormatException('Nieprawidłowy manifest korekt katalogu.');
    if (root is! Map<String, dynamic> ||
        root.length != 2 ||
        root['schemaVersion'] is! int ||
        root['schemaVersion'] != 1 ||
        root['corrections'] is! List) {
      invalid();
    }
    final seen = <String>{};
    final result = <ExerciseCatalogCorrection>[];
    for (final item in root['corrections'] as List) {
      if (item is! Map<String, dynamic> ||
          item.length != 3 ||
          item['exerciseId'] is! String ||
          !_ids.contains(item['exerciseId']) ||
          !seen.add(item['exerciseId'] as String) ||
          item['revision'] is! int ||
          item['revision'] != 1 ||
          item['fields'] is! Map<String, dynamic>) {
        invalid();
      }
      final fields = item['fields'] as Map<String, dynamic>;
      if (fields.isEmpty) invalid();
      for (final entry in fields.entries) {
        final value = entry.value;
        if (_strings.contains(entry.key)) {
          if (value is! String || value.trim().isEmpty) invalid();
        } else if (_lists.contains(entry.key)) {
          if (value is! List ||
              value.isEmpty ||
              value.any((e) => e is! String || e.trim().isEmpty)) {
            invalid();
          }
        } else {
          invalid();
        }
      }
      result.add(
        ExerciseCatalogCorrection._(
          item['exerciseId'] as String,
          Map<String, Object>.from(fields),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  ExercisesCompanion get update => ExercisesCompanion(
    nazwaPl: _text('nazwaPl'),
    sprzet: _json('sprzet'),
    kluczoweWskazowki: _json('kluczoweWskazowki'),
    czesteBledy: _json('czesteBledy'),
    progresja: _text('progresja'),
    regresja: _text('regresja'),
  );

  /// A re-import must not count as a write when all approved fields already
  /// have their effective values. Absent companion fields never participate.
  Expression<bool> differsFrom($ExercisesTable table) {
    final columns = <String, GeneratedColumn<String>>{
      'nazwaPl': table.nazwaPl,
      'sprzet': table.sprzet,
      'kluczoweWskazowki': table.kluczoweWskazowki,
      'czesteBledy': table.czesteBledy,
      'progresja': table.progresja,
      'regresja': table.regresja,
    };
    return fields.entries
        .map((entry) {
          final value = _lists.contains(entry.key)
              ? jsonEncode(entry.value)
              : entry.value as String;
          return columns[entry.key]!.equals(value).not();
        })
        .reduce((a, b) => a | b);
  }

  Value<String> _text(String key) => fields.containsKey(key)
      ? Value(fields[key] as String)
      : const Value.absent();
  Value<String> _json(String key) => fields.containsKey(key)
      ? Value(jsonEncode(fields[key]))
      : const Value.absent();
}
