// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: (json['id'] as num?)?.toInt() ?? 1,
      imie: json['imie'] as String,
      wiek: (json['wiek'] as num).toInt(),
      wzrostCm: (json['wzrostCm'] as num).toDouble(),
      wagaKg: (json['wagaKg'] as num).toDouble(),
      cel: $enumDecode(_$CelTreningowyEnumMap, json['cel']),
      dostepnySprzet: (json['dostepnySprzet'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      onboardingZakonczony: json['onboardingZakonczony'] as bool? ?? false,
      dataUtworzenia: DateTime.parse(json['dataUtworzenia'] as String),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imie': instance.imie,
      'wiek': instance.wiek,
      'wzrostCm': instance.wzrostCm,
      'wagaKg': instance.wagaKg,
      'cel': _$CelTreningowyEnumMap[instance.cel]!,
      'dostepnySprzet': instance.dostepnySprzet,
      'onboardingZakonczony': instance.onboardingZakonczony,
      'dataUtworzenia': instance.dataUtworzenia.toIso8601String(),
    };

const _$CelTreningowyEnumMap = {
  CelTreningowy.redukcja: 'redukcja',
  CelTreningowy.sila: 'sila',
  CelTreningowy.masa: 'masa',
  CelTreningowy.kondycja: 'kondycja',
  CelTreningowy.mix: 'mix',
};
