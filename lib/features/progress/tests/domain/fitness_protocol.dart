import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/user_collections.dart';

enum FitnessMetric {
  reps,
  time,
  distance;

  String get wireValue => name;
  String get unitLabel => switch (this) {
    reps => 'powt.',
    time => 's',
    distance => 'm',
  };
}

enum FitnessDirection {
  higher,
  lower;

  String get wireValue => name;
}

enum FitnessLoadBasis {
  total,
  perImplement;

  String get wireValue => name;
}

enum FitnessSide {
  left,
  right,
  both;

  String get wireValue => name;
}

Never _bad() => throw const FormatException(
  'Nieprawidłowy protokół testu. Dane zachowano.',
);
Object? _freeze(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      value.map((k, v) => MapEntry(k as String, _freeze(v))),
    );
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}

Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
DateTime _date(Object? raw) {
  if (raw is! String ||
      !RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$',
      ).hasMatch(raw)) {
    _bad();
  }
  final value = DateTime.tryParse(raw);
  if (value == null ||
      value.year < 1 ||
      value.year > 9999 ||
      value.toIso8601String().substring(0, 19) != raw.substring(0, 19)) {
    _bad();
  }
  return value;
}

void _text(Object? raw, int max, {bool empty = false}) {
  if (raw is! String ||
      raw.runes.length > max ||
      (!empty && raw.trim().isEmpty)) {
    _bad();
  }
}

/// A revision owns immutable rules. Archive/update metadata is not a new rule.
final class FitnessProtocol {
  FitnessProtocol._(this._json);
  final Map<String, dynamic> _json;
  factory FitnessProtocol.fromJson(Map<String, dynamic> json) {
    const nullableKeys = {
      'supersedesId',
      'loadKg',
      'loadBasis',
      'side',
      'variantSnapshot',
      'timeLimitSeconds',
    };
    const requiredKeys = {
      'id',
      'familyId',
      'name',
      'exerciseId',
      'exerciseName',
      'metric',
      'direction',
      'instructions',
      'createdAtUtc',
      'updatedAtUtc',
    };
    if (!json.keys.toSet().containsAll(requiredKeys) ||
        json.keys.any(
          (k) =>
              !requiredKeys.contains(k) &&
              !nullableKeys.contains(k) &&
              k != 'deletedAtUtc',
        )) {
      _bad();
    }
    try {
      if (utf8.encode(jsonEncode(json)).length > 32768) _bad();
    } on JsonUnsupportedObjectError {
      _bad();
    }
    json = {for (final key in nullableKeys) key: null, ...json};
    if (!UserCollections.isUuid(json['id']) ||
        !UserCollections.isUuid(json['familyId']) ||
        (json['supersedesId'] != null &&
            (!UserCollections.isUuid(json['supersedesId']) ||
                (json['supersedesId'] as String).toLowerCase() ==
                    (json['id'] as String).toLowerCase()))) {
      _bad();
    }
    _text(json['name'], 80);
    _text(json['exerciseId'], 64);
    _text(json['exerciseName'], 200);
    _text(json['instructions'], 4000, empty: true);
    if (!FitnessMetric.values.any((v) => v.name == json['metric']) ||
        !FitnessDirection.values.any((v) => v.name == json['direction'])) {
      _bad();
    }
    final kg = json['loadKg'], basis = json['loadBasis'];
    if ((kg == null) != (basis == null) ||
        (kg != null &&
            (kg is! num ||
                !kg.isFinite ||
                kg < 0 ||
                kg > 1000 ||
                !FitnessLoadBasis.values.any((v) => v.name == basis)))) {
      _bad();
    }
    if (json['side'] != null &&
        !FitnessSide.values.any((v) => v.name == json['side'])) {
      _bad();
    }
    final limit = json['timeLimitSeconds'];
    if (limit != null && (limit is! int || limit < 1 || limit > 86400)) _bad();
    final created = _date(json['createdAtUtc']),
        updated = _date(json['updatedAtUtc']);
    if (updated.isBefore(created) ||
        (json['deletedAtUtc'] != null &&
            _date(json['deletedAtUtc']).isAfter(updated))) {
      _bad();
    }
    final variant = json['variantSnapshot'];
    if (variant != null) {
      if (variant is! Map || variant['exerciseId'] != json['exerciseId']) {
        _bad();
      }
      const allowed = {
        'id',
        'name',
        'exerciseId',
        'createdAtUtc',
        'updatedAtUtc',
        'deletedAtUtc',
        'tempo',
        'pauseSeconds',
        'loadKg',
        'rangeOfMotion',
        'cue',
      };
      if (variant.keys.any((k) => !allowed.contains(k))) _bad();
      UserCollections.validate('exerciseVariants', {
        'version': 1,
        'entries': [variant],
      });
      _date(variant['createdAtUtc']);
      _date(variant['updatedAtUtc']);
      if (variant['deletedAtUtc'] != null) _date(variant['deletedAtUtc']);
    }
    return FitnessProtocol._(_freeze(_copy(json)) as Map<String, dynamic>);
  }
  Map<String, dynamic> toJson() => _copy(_json);
  String get id => _json['id'] as String;
  String get familyId => _json['familyId'] as String;
  String? get supersedesId => _json['supersedesId'] as String?;
  String get name => _json['name'] as String;
  String get exerciseId => _json['exerciseId'] as String;
  String get exerciseName => _json['exerciseName'] as String;
  FitnessMetric get metric =>
      FitnessMetric.values.byName(_json['metric'] as String);
  FitnessDirection get direction =>
      FitnessDirection.values.byName(_json['direction'] as String);
  double? get loadKg => (_json['loadKg'] as num?)?.toDouble();
  FitnessLoadBasis? get loadBasis => _json['loadBasis'] == null
      ? null
      : FitnessLoadBasis.values.byName(_json['loadBasis'] as String);
  FitnessSide? get side => _json['side'] == null
      ? null
      : FitnessSide.values.byName(_json['side'] as String);
  Map<String, dynamic>? get variantSnapshot =>
      _json['variantSnapshot'] as Map<String, dynamic>?;
  int? get timeLimitSeconds => _json['timeLimitSeconds'] as int?;
  String get instructions => _json['instructions'] as String;
  DateTime get createdAtUtc => _date(_json['createdAtUtc']);
  DateTime get updatedAtUtc => _date(_json['updatedAtUtc']);
  DateTime? get deletedAtUtc =>
      _json['deletedAtUtc'] == null ? null : _date(_json['deletedAtUtc']);
  bool get isArchived => deletedAtUtc != null;
  String get canonicalRules {
    final map = toJson()
      ..remove('updatedAtUtc')
      ..remove('deletedAtUtc');
    return UserCollections.canonical(map);
  }

  bool hasSameRevisionRules(FitnessProtocol other) =>
      id == other.id && canonicalRules == other.canonicalRules;

  static void validateValue(FitnessMetric metric, num value) {
    if (!value.isFinite ||
        value < 0 ||
        value > 1e9 ||
        (metric == FitnessMetric.reps && value != value.truncateToDouble())) {
      throw ArgumentError('Nieprawidłowy wynik testu.');
    }
  }

  static DateTime validateUtcDate(Object? value) => _date(value);

  /// Shared by sync, restore and defensive row readers; no catalog dependency.
  static FitnessProtocol validateResultPayload(
    Map<String, dynamic> payload, {
    bool stored = false,
  }) {
    const fields = {'typ', 'data', 'wynik', 'score', 'customProtocol'};
    if (payload.length != fields.length ||
        payload.keys.any((k) => !fields.contains(k))) {
      _bad();
    }
    final custom = payload['customProtocol'];
    if (payload['typ'] != 'customFitnessTestV1' ||
        custom is! Map ||
        custom.length != 4 ||
        custom['version'] is! int ||
        custom['version'] != 1 ||
        custom['snapshot'] is! Map ||
        payload['score'] is! num ||
        payload['score'] != 0) {
      _bad();
    }
    final protocol = FitnessProtocol.fromJson(
      Map<String, dynamic>.from(custom['snapshot'] as Map),
    );
    if (custom['protocolId'] != protocol.id ||
        custom['familyId'] != protocol.familyId) {
      _bad();
    }
    _date(payload['data']);
    final value = payload['wynik'];
    if (value is! num) _bad();
    try {
      validateValue(protocol.metric, value);
    } on ArgumentError {
      _bad();
    }
    return protocol;
  }
}

final class FitnessProtocolDraft {
  FitnessProtocolDraft({
    required this.name,
    required this.exerciseId,
    required this.exerciseName,
    required this.metric,
    required this.direction,
    this.loadKg,
    this.loadBasis,
    this.side,
    Map<String, dynamic>? variantSnapshot,
    this.timeLimitSeconds,
    this.instructions = '',
  }) : variantSnapshot = variantSnapshot == null
           ? null
           : _freeze(_copy(variantSnapshot)) as Map<String, dynamic>;
  factory FitnessProtocolDraft.fromProtocol(FitnessProtocol p) =>
      FitnessProtocolDraft(
        name: p.name,
        exerciseId: p.exerciseId,
        exerciseName: p.exerciseName,
        metric: p.metric,
        direction: p.direction,
        loadKg: p.loadKg,
        loadBasis: p.loadBasis,
        side: p.side,
        variantSnapshot: p.variantSnapshot,
        timeLimitSeconds: p.timeLimitSeconds,
        instructions: p.instructions,
      );
  final String name, exerciseId, exerciseName, instructions;
  final FitnessMetric metric;
  final FitnessDirection direction;
  final double? loadKg;
  final FitnessLoadBasis? loadBasis;
  final FitnessSide? side;
  final Map<String, dynamic>? variantSnapshot;
  final int? timeLimitSeconds;
}

final class FitnessProtocolsView {
  FitnessProtocolsView({
    required this.isAvailable,
    this.unavailableReason,
    this.rawJson,
    List<FitnessProtocol> protocols = const [],
  }) : protocols = List.unmodifiable(protocols);
  final bool isAvailable;
  final String? unavailableReason, rawJson;
  final List<FitnessProtocol> protocols;
  List<FitnessProtocol> get active =>
      List.unmodifiable(protocols.where((p) => !p.isArchived));
  List<FitnessProtocol> get archived =>
      List.unmodifiable(protocols.where((p) => p.isArchived));
}

final class CustomFitnessResult {
  CustomFitnessResult._(this.rawRow, this.protocol, this.unavailableReason);
  factory CustomFitnessResult.fromRow(FitnessTestResultData row) {
    try {
      final raw = row.customProtocolJson;
      if (raw == null) _bad();
      final p = FitnessProtocol.validateResultPayload({
        'typ': row.typ,
        'data': row.data.toUtc().toIso8601String(),
        'wynik': row.wynik,
        'score': row.score,
        'customProtocol': jsonDecode(raw),
      }, stored: true);
      return CustomFitnessResult._(row, p, null);
    } catch (_) {
      return CustomFitnessResult._(
        row,
        null,
        'Zasady tego wyniku są niedostępne. Dane zachowano.',
      );
    }
  }
  final FitnessTestResultData rawRow;
  final FitnessProtocol? protocol;
  final String? unavailableReason;
  bool get isAvailable => protocol != null;
  DateTime get performedAt => rawRow.data.toUtc();
  double get value => rawRow.wynik;
}

final class FitnessComparison {
  FitnessComparison(this.latest, this.previous);
  final CustomFitnessResult? latest, previous;
  double? get delta => latest == null || previous == null
      ? null
      : latest!.value - previous!.value;
  bool? get improved => delta == null
      ? null
      : (latest!.protocol!.direction == FitnessDirection.higher
            ? delta! > 0
            : delta! < 0);
}

FitnessComparison compareFitnessResults(
  FitnessProtocol protocol,
  Iterable<CustomFitnessResult> results,
) {
  final rows =
      results
          .where(
            (r) => r.isAvailable && protocol.hasSameRevisionRules(r.protocol!),
          )
          .toList()
        ..sort((a, b) {
          final c = b.performedAt.compareTo(a.performedAt);
          return c != 0 ? c : b.rawRow.id.compareTo(a.rawRow.id);
        });
  return FitnessComparison(rows.firstOrNull, rows.length > 1 ? rows[1] : null);
}
