// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseImpl _$$ExerciseImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseImpl(
      id: json['id'] as String,
      nazwaPl: json['nazwaPl'] as String,
      nazwaEn: json['nazwaEn'] as String,
      partiaGlowna: json['partiaGlowna'] as String,
      partieWspierajace: (json['partieWspierajace'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sprzet: (json['sprzet'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      typ: json['typ'] as String,
      poziom: json['poziom'] as String,
      wzorzecRuchu: json['wzorzecRuchu'] as String,
      seriexPowtorzenia: json['seriexPowtorzenia'] as String,
      tempo: json['tempo'] as String,
      kluczoweWskazowki: (json['kluczoweWskazowki'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      czesteBledy: (json['czesteBledy'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      progresja: json['progresja'] as String,
      regresja: json['regresja'] as String,
      zrodlo: json['zrodlo'] as String,
      ulubione: json['ulubione'] as bool? ?? false,
    );

Map<String, dynamic> _$$ExerciseImplToJson(_$ExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nazwaPl': instance.nazwaPl,
      'nazwaEn': instance.nazwaEn,
      'partiaGlowna': instance.partiaGlowna,
      'partieWspierajace': instance.partieWspierajace,
      'sprzet': instance.sprzet,
      'typ': instance.typ,
      'poziom': instance.poziom,
      'wzorzecRuchu': instance.wzorzecRuchu,
      'seriexPowtorzenia': instance.seriexPowtorzenia,
      'tempo': instance.tempo,
      'kluczoweWskazowki': instance.kluczoweWskazowki,
      'czesteBledy': instance.czesteBledy,
      'progresja': instance.progresja,
      'regresja': instance.regresja,
      'zrodlo': instance.zrodlo,
      'ulubione': instance.ulubione,
    };
