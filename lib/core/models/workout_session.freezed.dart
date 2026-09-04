// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SetLog _$SetLogFromJson(Map<String, dynamic> json) {
  return _SetLog.fromJson(json);
}

/// @nodoc
mixin _$SetLog {
  int get id => throw _privateConstructorUsedError;
  int get sesjaId => throw _privateConstructorUsedError;
  String get cwiczenieId => throw _privateConstructorUsedError;
  String get nazwaCwiczeniaPl => throw _privateConstructorUsedError;
  int get numerSerii => throw _privateConstructorUsedError;
  double? get ciezarKg => throw _privateConstructorUsedError;
  int? get powtorzenia => throw _privateConstructorUsedError;
  int? get czasSekund =>
      throw _privateConstructorUsedError; // dla planku, wall sit itd.
  int? get rpe => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this SetLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SetLogCopyWith<SetLog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetLogCopyWith<$Res> {
  factory $SetLogCopyWith(SetLog value, $Res Function(SetLog) then) =
      _$SetLogCopyWithImpl<$Res, SetLog>;
  @useResult
  $Res call({
    int id,
    int sesjaId,
    String cwiczenieId,
    String nazwaCwiczeniaPl,
    int numerSerii,
    double? ciezarKg,
    int? powtorzenia,
    int? czasSekund,
    int? rpe,
    DateTime timestamp,
  });
}

/// @nodoc
class _$SetLogCopyWithImpl<$Res, $Val extends SetLog>
    implements $SetLogCopyWith<$Res> {
  _$SetLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sesjaId = null,
    Object? cwiczenieId = null,
    Object? nazwaCwiczeniaPl = null,
    Object? numerSerii = null,
    Object? ciezarKg = freezed,
    Object? powtorzenia = freezed,
    Object? czasSekund = freezed,
    Object? rpe = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            sesjaId: null == sesjaId
                ? _value.sesjaId
                : sesjaId // ignore: cast_nullable_to_non_nullable
                      as int,
            cwiczenieId: null == cwiczenieId
                ? _value.cwiczenieId
                : cwiczenieId // ignore: cast_nullable_to_non_nullable
                      as String,
            nazwaCwiczeniaPl: null == nazwaCwiczeniaPl
                ? _value.nazwaCwiczeniaPl
                : nazwaCwiczeniaPl // ignore: cast_nullable_to_non_nullable
                      as String,
            numerSerii: null == numerSerii
                ? _value.numerSerii
                : numerSerii // ignore: cast_nullable_to_non_nullable
                      as int,
            ciezarKg: freezed == ciezarKg
                ? _value.ciezarKg
                : ciezarKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            powtorzenia: freezed == powtorzenia
                ? _value.powtorzenia
                : powtorzenia // ignore: cast_nullable_to_non_nullable
                      as int?,
            czasSekund: freezed == czasSekund
                ? _value.czasSekund
                : czasSekund // ignore: cast_nullable_to_non_nullable
                      as int?,
            rpe: freezed == rpe
                ? _value.rpe
                : rpe // ignore: cast_nullable_to_non_nullable
                      as int?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SetLogImplCopyWith<$Res> implements $SetLogCopyWith<$Res> {
  factory _$$SetLogImplCopyWith(
    _$SetLogImpl value,
    $Res Function(_$SetLogImpl) then,
  ) = __$$SetLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int sesjaId,
    String cwiczenieId,
    String nazwaCwiczeniaPl,
    int numerSerii,
    double? ciezarKg,
    int? powtorzenia,
    int? czasSekund,
    int? rpe,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$SetLogImplCopyWithImpl<$Res>
    extends _$SetLogCopyWithImpl<$Res, _$SetLogImpl>
    implements _$$SetLogImplCopyWith<$Res> {
  __$$SetLogImplCopyWithImpl(
    _$SetLogImpl _value,
    $Res Function(_$SetLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sesjaId = null,
    Object? cwiczenieId = null,
    Object? nazwaCwiczeniaPl = null,
    Object? numerSerii = null,
    Object? ciezarKg = freezed,
    Object? powtorzenia = freezed,
    Object? czasSekund = freezed,
    Object? rpe = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _$SetLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        sesjaId: null == sesjaId
            ? _value.sesjaId
            : sesjaId // ignore: cast_nullable_to_non_nullable
                  as int,
        cwiczenieId: null == cwiczenieId
            ? _value.cwiczenieId
            : cwiczenieId // ignore: cast_nullable_to_non_nullable
                  as String,
        nazwaCwiczeniaPl: null == nazwaCwiczeniaPl
            ? _value.nazwaCwiczeniaPl
            : nazwaCwiczeniaPl // ignore: cast_nullable_to_non_nullable
                  as String,
        numerSerii: null == numerSerii
            ? _value.numerSerii
            : numerSerii // ignore: cast_nullable_to_non_nullable
                  as int,
        ciezarKg: freezed == ciezarKg
            ? _value.ciezarKg
            : ciezarKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        powtorzenia: freezed == powtorzenia
            ? _value.powtorzenia
            : powtorzenia // ignore: cast_nullable_to_non_nullable
                  as int?,
        czasSekund: freezed == czasSekund
            ? _value.czasSekund
            : czasSekund // ignore: cast_nullable_to_non_nullable
                  as int?,
        rpe: freezed == rpe
            ? _value.rpe
            : rpe // ignore: cast_nullable_to_non_nullable
                  as int?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SetLogImpl implements _SetLog {
  const _$SetLogImpl({
    required this.id,
    required this.sesjaId,
    required this.cwiczenieId,
    required this.nazwaCwiczeniaPl,
    required this.numerSerii,
    this.ciezarKg,
    this.powtorzenia,
    this.czasSekund,
    this.rpe,
    required this.timestamp,
  });

  factory _$SetLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetLogImplFromJson(json);

  @override
  final int id;
  @override
  final int sesjaId;
  @override
  final String cwiczenieId;
  @override
  final String nazwaCwiczeniaPl;
  @override
  final int numerSerii;
  @override
  final double? ciezarKg;
  @override
  final int? powtorzenia;
  @override
  final int? czasSekund;
  // dla planku, wall sit itd.
  @override
  final int? rpe;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'SetLog(id: $id, sesjaId: $sesjaId, cwiczenieId: $cwiczenieId, nazwaCwiczeniaPl: $nazwaCwiczeniaPl, numerSerii: $numerSerii, ciezarKg: $ciezarKg, powtorzenia: $powtorzenia, czasSekund: $czasSekund, rpe: $rpe, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sesjaId, sesjaId) || other.sesjaId == sesjaId) &&
            (identical(other.cwiczenieId, cwiczenieId) ||
                other.cwiczenieId == cwiczenieId) &&
            (identical(other.nazwaCwiczeniaPl, nazwaCwiczeniaPl) ||
                other.nazwaCwiczeniaPl == nazwaCwiczeniaPl) &&
            (identical(other.numerSerii, numerSerii) ||
                other.numerSerii == numerSerii) &&
            (identical(other.ciezarKg, ciezarKg) ||
                other.ciezarKg == ciezarKg) &&
            (identical(other.powtorzenia, powtorzenia) ||
                other.powtorzenia == powtorzenia) &&
            (identical(other.czasSekund, czasSekund) ||
                other.czasSekund == czasSekund) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sesjaId,
    cwiczenieId,
    nazwaCwiczeniaPl,
    numerSerii,
    ciezarKg,
    powtorzenia,
    czasSekund,
    rpe,
    timestamp,
  );

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetLogImplCopyWith<_$SetLogImpl> get copyWith =>
      __$$SetLogImplCopyWithImpl<_$SetLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetLogImplToJson(this);
  }
}

abstract class _SetLog implements SetLog {
  const factory _SetLog({
    required final int id,
    required final int sesjaId,
    required final String cwiczenieId,
    required final String nazwaCwiczeniaPl,
    required final int numerSerii,
    final double? ciezarKg,
    final int? powtorzenia,
    final int? czasSekund,
    final int? rpe,
    required final DateTime timestamp,
  }) = _$SetLogImpl;

  factory _SetLog.fromJson(Map<String, dynamic> json) = _$SetLogImpl.fromJson;

  @override
  int get id;
  @override
  int get sesjaId;
  @override
  String get cwiczenieId;
  @override
  String get nazwaCwiczeniaPl;
  @override
  int get numerSerii;
  @override
  double? get ciezarKg;
  @override
  int? get powtorzenia;
  @override
  int? get czasSekund; // dla planku, wall sit itd.
  @override
  int? get rpe;
  @override
  DateTime get timestamp;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetLogImplCopyWith<_$SetLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) {
  return _WorkoutSession.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSession {
  int get id => throw _privateConstructorUsedError;
  DateTime get dataStart => throw _privateConstructorUsedError;
  DateTime? get dataKoniec => throw _privateConstructorUsedError;
  int get czasTrwaniaSekund => throw _privateConstructorUsedError;
  String? get notatka => throw _privateConstructorUsedError;
  List<SetLog> get serie => throw _privateConstructorUsedError;

  /// Serializes this WorkoutSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
    WorkoutSession value,
    $Res Function(WorkoutSession) then,
  ) = _$WorkoutSessionCopyWithImpl<$Res, WorkoutSession>;
  @useResult
  $Res call({
    int id,
    DateTime dataStart,
    DateTime? dataKoniec,
    int czasTrwaniaSekund,
    String? notatka,
    List<SetLog> serie,
  });
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res, $Val extends WorkoutSession>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dataStart = null,
    Object? dataKoniec = freezed,
    Object? czasTrwaniaSekund = null,
    Object? notatka = freezed,
    Object? serie = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            dataStart: null == dataStart
                ? _value.dataStart
                : dataStart // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dataKoniec: freezed == dataKoniec
                ? _value.dataKoniec
                : dataKoniec // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            czasTrwaniaSekund: null == czasTrwaniaSekund
                ? _value.czasTrwaniaSekund
                : czasTrwaniaSekund // ignore: cast_nullable_to_non_nullable
                      as int,
            notatka: freezed == notatka
                ? _value.notatka
                : notatka // ignore: cast_nullable_to_non_nullable
                      as String?,
            serie: null == serie
                ? _value.serie
                : serie // ignore: cast_nullable_to_non_nullable
                      as List<SetLog>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkoutSessionImplCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$$WorkoutSessionImplCopyWith(
    _$WorkoutSessionImpl value,
    $Res Function(_$WorkoutSessionImpl) then,
  ) = __$$WorkoutSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    DateTime dataStart,
    DateTime? dataKoniec,
    int czasTrwaniaSekund,
    String? notatka,
    List<SetLog> serie,
  });
}

/// @nodoc
class __$$WorkoutSessionImplCopyWithImpl<$Res>
    extends _$WorkoutSessionCopyWithImpl<$Res, _$WorkoutSessionImpl>
    implements _$$WorkoutSessionImplCopyWith<$Res> {
  __$$WorkoutSessionImplCopyWithImpl(
    _$WorkoutSessionImpl _value,
    $Res Function(_$WorkoutSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dataStart = null,
    Object? dataKoniec = freezed,
    Object? czasTrwaniaSekund = null,
    Object? notatka = freezed,
    Object? serie = null,
  }) {
    return _then(
      _$WorkoutSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        dataStart: null == dataStart
            ? _value.dataStart
            : dataStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dataKoniec: freezed == dataKoniec
            ? _value.dataKoniec
            : dataKoniec // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        czasTrwaniaSekund: null == czasTrwaniaSekund
            ? _value.czasTrwaniaSekund
            : czasTrwaniaSekund // ignore: cast_nullable_to_non_nullable
                  as int,
        notatka: freezed == notatka
            ? _value.notatka
            : notatka // ignore: cast_nullable_to_non_nullable
                  as String?,
        serie: null == serie
            ? _value._serie
            : serie // ignore: cast_nullable_to_non_nullable
                  as List<SetLog>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSessionImpl implements _WorkoutSession {
  const _$WorkoutSessionImpl({
    required this.id,
    required this.dataStart,
    this.dataKoniec,
    required this.czasTrwaniaSekund,
    this.notatka,
    final List<SetLog> serie = const [],
  }) : _serie = serie;

  factory _$WorkoutSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionImplFromJson(json);

  @override
  final int id;
  @override
  final DateTime dataStart;
  @override
  final DateTime? dataKoniec;
  @override
  final int czasTrwaniaSekund;
  @override
  final String? notatka;
  final List<SetLog> _serie;
  @override
  @JsonKey()
  List<SetLog> get serie {
    if (_serie is EqualUnmodifiableListView) return _serie;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_serie);
  }

  @override
  String toString() {
    return 'WorkoutSession(id: $id, dataStart: $dataStart, dataKoniec: $dataKoniec, czasTrwaniaSekund: $czasTrwaniaSekund, notatka: $notatka, serie: $serie)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dataStart, dataStart) ||
                other.dataStart == dataStart) &&
            (identical(other.dataKoniec, dataKoniec) ||
                other.dataKoniec == dataKoniec) &&
            (identical(other.czasTrwaniaSekund, czasTrwaniaSekund) ||
                other.czasTrwaniaSekund == czasTrwaniaSekund) &&
            (identical(other.notatka, notatka) || other.notatka == notatka) &&
            const DeepCollectionEquality().equals(other._serie, _serie));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    dataStart,
    dataKoniec,
    czasTrwaniaSekund,
    notatka,
    const DeepCollectionEquality().hash(_serie),
  );

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      __$$WorkoutSessionImplCopyWithImpl<_$WorkoutSessionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionImplToJson(this);
  }
}

abstract class _WorkoutSession implements WorkoutSession {
  const factory _WorkoutSession({
    required final int id,
    required final DateTime dataStart,
    final DateTime? dataKoniec,
    required final int czasTrwaniaSekund,
    final String? notatka,
    final List<SetLog> serie,
  }) = _$WorkoutSessionImpl;

  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionImpl.fromJson;

  @override
  int get id;
  @override
  DateTime get dataStart;
  @override
  DateTime? get dataKoniec;
  @override
  int get czasTrwaniaSekund;
  @override
  String? get notatka;
  @override
  List<SetLog> get serie;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
