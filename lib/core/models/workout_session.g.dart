// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SetLogImpl _$$SetLogImplFromJson(Map<String, dynamic> json) => _$SetLogImpl(
  id: (json['id'] as num).toInt(),
  sesjaId: (json['sesjaId'] as num).toInt(),
  cwiczenieId: json['cwiczenieId'] as String,
  nazwaCwiczeniaPl: json['nazwaCwiczeniaPl'] as String,
  numerSerii: (json['numerSerii'] as num).toInt(),
  ciezarKg: (json['ciezarKg'] as num?)?.toDouble(),
  powtorzenia: (json['powtorzenia'] as num?)?.toInt(),
  czasSekund: (json['czasSekund'] as num?)?.toInt(),
  rpe: (json['rpe'] as num?)?.toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$SetLogImplToJson(_$SetLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sesjaId': instance.sesjaId,
      'cwiczenieId': instance.cwiczenieId,
      'nazwaCwiczeniaPl': instance.nazwaCwiczeniaPl,
      'numerSerii': instance.numerSerii,
      'ciezarKg': instance.ciezarKg,
      'powtorzenia': instance.powtorzenia,
      'czasSekund': instance.czasSekund,
      'rpe': instance.rpe,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: (json['id'] as num).toInt(),
      dataStart: DateTime.parse(json['dataStart'] as String),
      dataKoniec: json['dataKoniec'] == null
          ? null
          : DateTime.parse(json['dataKoniec'] as String),
      czasTrwaniaSekund: (json['czasTrwaniaSekund'] as num).toInt(),
      notatka: json['notatka'] as String?,
      serie:
          (json['serie'] as List<dynamic>?)
              ?.map((e) => SetLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
  _$WorkoutSessionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'dataStart': instance.dataStart.toIso8601String(),
  'dataKoniec': instance.dataKoniec?.toIso8601String(),
  'czasTrwaniaSekund': instance.czasTrwaniaSekund,
  'notatka': instance.notatka,
  'serie': instance.serie,
};
