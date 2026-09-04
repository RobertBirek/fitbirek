// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fitness_test.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FitnessTestResult _$FitnessTestResultFromJson(Map<String, dynamic> json) {
  return _FitnessTestResult.fromJson(json);
}

/// @nodoc
mixin _$FitnessTestResult {
  int get id => throw _privateConstructorUsedError;
  TypTestu get typ => throw _privateConstructorUsedError;
  DateTime get data => throw _privateConstructorUsedError;
  double get wynik => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;

  /// Serializes this FitnessTestResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FitnessTestResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FitnessTestResultCopyWith<FitnessTestResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FitnessTestResultCopyWith<$Res> {
  factory $FitnessTestResultCopyWith(
    FitnessTestResult value,
    $Res Function(FitnessTestResult) then,
  ) = _$FitnessTestResultCopyWithImpl<$Res, FitnessTestResult>;
  @useResult
  $Res call({int id, TypTestu typ, DateTime data, double wynik, int score});
}

/// @nodoc
class _$FitnessTestResultCopyWithImpl<$Res, $Val extends FitnessTestResult>
    implements $FitnessTestResultCopyWith<$Res> {
  _$FitnessTestResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FitnessTestResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? typ = null,
    Object? data = null,
    Object? wynik = null,
    Object? score = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            typ: null == typ
                ? _value.typ
                : typ // ignore: cast_nullable_to_non_nullable
                      as TypTestu,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            wynik: null == wynik
                ? _value.wynik
                : wynik // ignore: cast_nullable_to_non_nullable
                      as double,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FitnessTestResultImplCopyWith<$Res>
    implements $FitnessTestResultCopyWith<$Res> {
  factory _$$FitnessTestResultImplCopyWith(
    _$FitnessTestResultImpl value,
    $Res Function(_$FitnessTestResultImpl) then,
  ) = __$$FitnessTestResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, TypTestu typ, DateTime data, double wynik, int score});
}

/// @nodoc
class __$$FitnessTestResultImplCopyWithImpl<$Res>
    extends _$FitnessTestResultCopyWithImpl<$Res, _$FitnessTestResultImpl>
    implements _$$FitnessTestResultImplCopyWith<$Res> {
  __$$FitnessTestResultImplCopyWithImpl(
    _$FitnessTestResultImpl _value,
    $Res Function(_$FitnessTestResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FitnessTestResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? typ = null,
    Object? data = null,
    Object? wynik = null,
    Object? score = null,
  }) {
    return _then(
      _$FitnessTestResultImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        typ: null == typ
            ? _value.typ
            : typ // ignore: cast_nullable_to_non_nullable
                  as TypTestu,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        wynik: null == wynik
            ? _value.wynik
            : wynik // ignore: cast_nullable_to_non_nullable
                  as double,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FitnessTestResultImpl implements _FitnessTestResult {
  const _$FitnessTestResultImpl({
    required this.id,
    required this.typ,
    required this.data,
    required this.wynik,
    this.score = 0,
  });

  factory _$FitnessTestResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$FitnessTestResultImplFromJson(json);

  @override
  final int id;
  @override
  final TypTestu typ;
  @override
  final DateTime data;
  @override
  final double wynik;
  @override
  @JsonKey()
  final int score;

  @override
  String toString() {
    return 'FitnessTestResult(id: $id, typ: $typ, data: $data, wynik: $wynik, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FitnessTestResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.typ, typ) || other.typ == typ) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.wynik, wynik) || other.wynik == wynik) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, typ, data, wynik, score);

  /// Create a copy of FitnessTestResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FitnessTestResultImplCopyWith<_$FitnessTestResultImpl> get copyWith =>
      __$$FitnessTestResultImplCopyWithImpl<_$FitnessTestResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FitnessTestResultImplToJson(this);
  }
}

abstract class _FitnessTestResult implements FitnessTestResult {
  const factory _FitnessTestResult({
    required final int id,
    required final TypTestu typ,
    required final DateTime data,
    required final double wynik,
    final int score,
  }) = _$FitnessTestResultImpl;

  factory _FitnessTestResult.fromJson(Map<String, dynamic> json) =
      _$FitnessTestResultImpl.fromJson;

  @override
  int get id;
  @override
  TypTestu get typ;
  @override
  DateTime get data;
  @override
  double get wynik;
  @override
  int get score;

  /// Create a copy of FitnessTestResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FitnessTestResultImplCopyWith<_$FitnessTestResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
