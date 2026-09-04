// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MoodEntryImpl _$$MoodEntryImplFromJson(Map<String, dynamic> json) =>
    _$MoodEntryImpl(
      id: (json['id'] as num).toInt(),
      data: DateTime.parse(json['data'] as String),
      snGodziny: (json['snGodziny'] as num).toDouble(),
      energia: (json['energia'] as num).toInt(),
      nastroj: (json['nastroj'] as num).toInt(),
      apetyt: (json['apetyt'] as num).toInt(),
      alkohol: json['alkohol'] as bool,
      alkoholJednostki: (json['alkoholJednostki'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MoodEntryImplToJson(_$MoodEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': instance.data.toIso8601String(),
      'snGodziny': instance.snGodziny,
      'energia': instance.energia,
      'nastroj': instance.nastroj,
      'apetyt': instance.apetyt,
      'alkohol': instance.alkohol,
      'alkoholJednostki': instance.alkoholJednostki,
    };
