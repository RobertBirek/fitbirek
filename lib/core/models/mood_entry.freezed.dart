// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MoodEntry _$MoodEntryFromJson(Map<String, dynamic> json) {
  return _MoodEntry.fromJson(json);
}

/// @nodoc
mixin _$MoodEntry {
  int get id => throw _privateConstructorUsedError;
  DateTime get data => throw _privateConstructorUsedError;
  double get snGodziny => throw _privateConstructorUsedError;
  int get energia => throw _privateConstructorUsedError; // 1-10
  int get nastroj => throw _privateConstructorUsedError; // 1-10
  int get apetyt => throw _privateConstructorUsedError; // 1-10
  bool get alkohol => throw _privateConstructorUsedError;
  int get alkoholJednostki => throw _privateConstructorUsedError;

  /// Serializes this MoodEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MoodEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoodEntryCopyWith<MoodEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoodEntryCopyWith<$Res> {
  factory $MoodEntryCopyWith(MoodEntry value, $Res Function(MoodEntry) then) =
      _$MoodEntryCopyWithImpl<$Res, MoodEntry>;
  @useResult
  $Res call({
    int id,
    DateTime data,
    double snGodziny,
    int energia,
    int nastroj,
    int apetyt,
    bool alkohol,
    int alkoholJednostki,
  });
}

/// @nodoc
class _$MoodEntryCopyWithImpl<$Res, $Val extends MoodEntry>
    implements $MoodEntryCopyWith<$Res> {
  _$MoodEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoodEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = null,
    Object? snGodziny = null,
    Object? energia = null,
    Object? nastroj = null,
    Object? apetyt = null,
    Object? alkohol = null,
    Object? alkoholJednostki = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            snGodziny: null == snGodziny
                ? _value.snGodziny
                : snGodziny // ignore: cast_nullable_to_non_nullable
                      as double,
            energia: null == energia
                ? _value.energia
                : energia // ignore: cast_nullable_to_non_nullable
                      as int,
            nastroj: null == nastroj
                ? _value.nastroj
                : nastroj // ignore: cast_nullable_to_non_nullable
                      as int,
            apetyt: null == apetyt
                ? _value.apetyt
                : apetyt // ignore: cast_nullable_to_non_nullable
                      as int,
            alkohol: null == alkohol
                ? _value.alkohol
                : alkohol // ignore: cast_nullable_to_non_nullable
                      as bool,
            alkoholJednostki: null == alkoholJednostki
                ? _value.alkoholJednostki
                : alkoholJednostki // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoodEntryImplCopyWith<$Res>
    implements $MoodEntryCopyWith<$Res> {
  factory _$$MoodEntryImplCopyWith(
    _$MoodEntryImpl value,
    $Res Function(_$MoodEntryImpl) then,
  ) = __$$MoodEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    DateTime data,
    double snGodziny,
    int energia,
    int nastroj,
    int apetyt,
    bool alkohol,
    int alkoholJednostki,
  });
}

/// @nodoc
class __$$MoodEntryImplCopyWithImpl<$Res>
    extends _$MoodEntryCopyWithImpl<$Res, _$MoodEntryImpl>
    implements _$$MoodEntryImplCopyWith<$Res> {
  __$$MoodEntryImplCopyWithImpl(
    _$MoodEntryImpl _value,
    $Res Function(_$MoodEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoodEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = null,
    Object? snGodziny = null,
    Object? energia = null,
    Object? nastroj = null,
    Object? apetyt = null,
    Object? alkohol = null,
    Object? alkoholJednostki = null,
  }) {
    return _then(
      _$MoodEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        snGodziny: null == snGodziny
            ? _value.snGodziny
            : snGodziny // ignore: cast_nullable_to_non_nullable
                  as double,
        energia: null == energia
            ? _value.energia
            : energia // ignore: cast_nullable_to_non_nullable
                  as int,
        nastroj: null == nastroj
            ? _value.nastroj
            : nastroj // ignore: cast_nullable_to_non_nullable
                  as int,
        apetyt: null == apetyt
            ? _value.apetyt
            : apetyt // ignore: cast_nullable_to_non_nullable
                  as int,
        alkohol: null == alkohol
            ? _value.alkohol
            : alkohol // ignore: cast_nullable_to_non_nullable
                  as bool,
        alkoholJednostki: null == alkoholJednostki
            ? _value.alkoholJednostki
            : alkoholJednostki // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoodEntryImpl implements _MoodEntry {
  const _$MoodEntryImpl({
    required this.id,
    required this.data,
    required this.snGodziny,
    required this.energia,
    required this.nastroj,
    required this.apetyt,
    required this.alkohol,
    this.alkoholJednostki = 0,
  });

  factory _$MoodEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoodEntryImplFromJson(json);

  @override
  final int id;
  @override
  final DateTime data;
  @override
  final double snGodziny;
  @override
  final int energia;
  // 1-10
  @override
  final int nastroj;
  // 1-10
  @override
  final int apetyt;
  // 1-10
  @override
  final bool alkohol;
  @override
  @JsonKey()
  final int alkoholJednostki;

  @override
  String toString() {
    return 'MoodEntry(id: $id, data: $data, snGodziny: $snGodziny, energia: $energia, nastroj: $nastroj, apetyt: $apetyt, alkohol: $alkohol, alkoholJednostki: $alkoholJednostki)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.snGodziny, snGodziny) ||
                other.snGodziny == snGodziny) &&
            (identical(other.energia, energia) || other.energia == energia) &&
            (identical(other.nastroj, nastroj) || other.nastroj == nastroj) &&
            (identical(other.apetyt, apetyt) || other.apetyt == apetyt) &&
            (identical(other.alkohol, alkohol) || other.alkohol == alkohol) &&
            (identical(other.alkoholJednostki, alkoholJednostki) ||
                other.alkoholJednostki == alkoholJednostki));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    data,
    snGodziny,
    energia,
    nastroj,
    apetyt,
    alkohol,
    alkoholJednostki,
  );

  /// Create a copy of MoodEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodEntryImplCopyWith<_$MoodEntryImpl> get copyWith =>
      __$$MoodEntryImplCopyWithImpl<_$MoodEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MoodEntryImplToJson(this);
  }
}

abstract class _MoodEntry implements MoodEntry {
  const factory _MoodEntry({
    required final int id,
    required final DateTime data,
    required final double snGodziny,
    required final int energia,
    required final int nastroj,
    required final int apetyt,
    required final bool alkohol,
    final int alkoholJednostki,
  }) = _$MoodEntryImpl;

  factory _MoodEntry.fromJson(Map<String, dynamic> json) =
      _$MoodEntryImpl.fromJson;

  @override
  int get id;
  @override
  DateTime get data;
  @override
  double get snGodziny;
  @override
  int get energia; // 1-10
  @override
  int get nastroj; // 1-10
  @override
  int get apetyt; // 1-10
  @override
  bool get alkohol;
  @override
  int get alkoholJednostki;

  /// Create a copy of MoodEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoodEntryImplCopyWith<_$MoodEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
