// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FitnessTestResultImpl _$$FitnessTestResultImplFromJson(
  Map<String, dynamic> json,
) => _$FitnessTestResultImpl(
  id: (json['id'] as num).toInt(),
  typ: $enumDecode(_$TypTestuEnumMap, json['typ']),
  data: DateTime.parse(json['data'] as String),
  wynik: (json['wynik'] as num).toDouble(),
  score: (json['score'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$FitnessTestResultImplToJson(
  _$FitnessTestResultImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'typ': _$TypTestuEnumMap[instance.typ]!,
  'data': instance.data.toIso8601String(),
  'wynik': instance.wynik,
  'score': instance.score,
};

const _$TypTestuEnumMap = {
  TypTestu.maxPompki: 'maxPompki',
  TypTestu.pullUp: 'pullUp',
  TypTestu.chinUp: 'chinUp',
  TypTestu.plank: 'plank',
  TypTestu.wallSit: 'wallSit',
  TypTestu.deadHang: 'deadHang',
  TypTestu.przysiady60s: 'przysiady60s',
  TypTestu.skakanka: 'skakanka',
  TypTestu.cooper12min: 'cooper12min',
  TypTestu.sklon: 'sklon',
  TypTestu.glebokiPrzysiad: 'glebokiPrzysiad',
};
