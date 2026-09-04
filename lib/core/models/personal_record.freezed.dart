// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) {
  return _PersonalRecord.fromJson(json);
}

/// @nodoc
mixin _$PersonalRecord {
  int get id => throw _privateConstructorUsedError;
  String get cwiczenieId => throw _privateConstructorUsedError;
  String get nazwaCwiczeniaPl => throw _privateConstructorUsedError;
  double get ciezarKg => throw _privateConstructorUsedError;
  int get powtorzenia => throw _privateConstructorUsedError;
  DateTime get data =>
      throw _privateConstructorUsedError; // szacowany 1RM wg formuły Epley: ciezar * (1 + powtorzenia/30)
  double get szacowane1Rm => throw _privateConstructorUsedError;

  /// Serializes this PersonalRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalRecordCopyWith<PersonalRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalRecordCopyWith<$Res> {
  factory $PersonalRecordCopyWith(
    PersonalRecord value,
    $Res Function(PersonalRecord) then,
  ) = _$PersonalRecordCopyWithImpl<$Res, PersonalRecord>;
  @useResult
  $Res call({
    int id,
    String cwiczenieId,
    String nazwaCwiczeniaPl,
    double ciezarKg,
    int powtorzenia,
    DateTime data,
    double szacowane1Rm,
  });
}

/// @nodoc
class _$PersonalRecordCopyWithImpl<$Res, $Val extends PersonalRecord>
    implements $PersonalRecordCopyWith<$Res> {
  _$PersonalRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cwiczenieId = null,
    Object? nazwaCwiczeniaPl = null,
    Object? ciezarKg = null,
    Object? powtorzenia = null,
    Object? data = null,
    Object? szacowane1Rm = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            cwiczenieId: null == cwiczenieId
                ? _value.cwiczenieId
                : cwiczenieId // ignore: cast_nullable_to_non_nullable
                      as String,
            nazwaCwiczeniaPl: null == nazwaCwiczeniaPl
                ? _value.nazwaCwiczeniaPl
                : nazwaCwiczeniaPl // ignore: cast_nullable_to_non_nullable
                      as String,
            ciezarKg: null == ciezarKg
                ? _value.ciezarKg
                : ciezarKg // ignore: cast_nullable_to_non_nullable
                      as double,
            powtorzenia: null == powtorzenia
                ? _value.powtorzenia
                : powtorzenia // ignore: cast_nullable_to_non_nullable
                      as int,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            szacowane1Rm: null == szacowane1Rm
                ? _value.szacowane1Rm
                : szacowane1Rm // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PersonalRecordImplCopyWith<$Res>
    implements $PersonalRecordCopyWith<$Res> {
  factory _$$PersonalRecordImplCopyWith(
    _$PersonalRecordImpl value,
    $Res Function(_$PersonalRecordImpl) then,
  ) = __$$PersonalRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String cwiczenieId,
    String nazwaCwiczeniaPl,
    double ciezarKg,
    int powtorzenia,
    DateTime data,
    double szacowane1Rm,
  });
}

/// @nodoc
class __$$PersonalRecordImplCopyWithImpl<$Res>
    extends _$PersonalRecordCopyWithImpl<$Res, _$PersonalRecordImpl>
    implements _$$PersonalRecordImplCopyWith<$Res> {
  __$$PersonalRecordImplCopyWithImpl(
    _$PersonalRecordImpl _value,
    $Res Function(_$PersonalRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cwiczenieId = null,
    Object? nazwaCwiczeniaPl = null,
    Object? ciezarKg = null,
    Object? powtorzenia = null,
    Object? data = null,
    Object? szacowane1Rm = null,
  }) {
    return _then(
      _$PersonalRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        cwiczenieId: null == cwiczenieId
            ? _value.cwiczenieId
            : cwiczenieId // ignore: cast_nullable_to_non_nullable
                  as String,
        nazwaCwiczeniaPl: null == nazwaCwiczeniaPl
            ? _value.nazwaCwiczeniaPl
            : nazwaCwiczeniaPl // ignore: cast_nullable_to_non_nullable
                  as String,
        ciezarKg: null == ciezarKg
            ? _value.ciezarKg
            : ciezarKg // ignore: cast_nullable_to_non_nullable
                  as double,
        powtorzenia: null == powtorzenia
            ? _value.powtorzenia
            : powtorzenia // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        szacowane1Rm: null == szacowane1Rm
            ? _value.szacowane1Rm
            : szacowane1Rm // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalRecordImpl implements _PersonalRecord {
  const _$PersonalRecordImpl({
    required this.id,
    required this.cwiczenieId,
    required this.nazwaCwiczeniaPl,
    required this.ciezarKg,
    required this.powtorzenia,
    required this.data,
    required this.szacowane1Rm,
  });

  factory _$PersonalRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalRecordImplFromJson(json);

  @override
  final int id;
  @override
  final String cwiczenieId;
  @override
  final String nazwaCwiczeniaPl;
  @override
  final double ciezarKg;
  @override
  final int powtorzenia;
  @override
  final DateTime data;
  // szacowany 1RM wg formuły Epley: ciezar * (1 + powtorzenia/30)
  @override
  final double szacowane1Rm;

  @override
  String toString() {
    return 'PersonalRecord(id: $id, cwiczenieId: $cwiczenieId, nazwaCwiczeniaPl: $nazwaCwiczeniaPl, ciezarKg: $ciezarKg, powtorzenia: $powtorzenia, data: $data, szacowane1Rm: $szacowane1Rm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cwiczenieId, cwiczenieId) ||
                other.cwiczenieId == cwiczenieId) &&
            (identical(other.nazwaCwiczeniaPl, nazwaCwiczeniaPl) ||
                other.nazwaCwiczeniaPl == nazwaCwiczeniaPl) &&
            (identical(other.ciezarKg, ciezarKg) ||
                other.ciezarKg == ciezarKg) &&
            (identical(other.powtorzenia, powtorzenia) ||
                other.powtorzenia == powtorzenia) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.szacowane1Rm, szacowane1Rm) ||
                other.szacowane1Rm == szacowane1Rm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    cwiczenieId,
    nazwaCwiczeniaPl,
    ciezarKg,
    powtorzenia,
    data,
    szacowane1Rm,
  );

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalRecordImplCopyWith<_$PersonalRecordImpl> get copyWith =>
      __$$PersonalRecordImplCopyWithImpl<_$PersonalRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalRecordImplToJson(this);
  }
}

abstract class _PersonalRecord implements PersonalRecord {
  const factory _PersonalRecord({
    required final int id,
    required final String cwiczenieId,
    required final String nazwaCwiczeniaPl,
    required final double ciezarKg,
    required final int powtorzenia,
    required final DateTime data,
    required final double szacowane1Rm,
  }) = _$PersonalRecordImpl;

  factory _PersonalRecord.fromJson(Map<String, dynamic> json) =
      _$PersonalRecordImpl.fromJson;

  @override
  int get id;
  @override
  String get cwiczenieId;
  @override
  String get nazwaCwiczeniaPl;
  @override
  double get ciezarKg;
  @override
  int get powtorzenia;
  @override
  DateTime get data; // szacowany 1RM wg formuły Epley: ciezar * (1 + powtorzenia/30)
  @override
  double get szacowane1Rm;

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalRecordImplCopyWith<_$PersonalRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
