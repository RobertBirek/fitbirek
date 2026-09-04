// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonalRecordImpl _$$PersonalRecordImplFromJson(Map<String, dynamic> json) =>
    _$PersonalRecordImpl(
      id: (json['id'] as num).toInt(),
      cwiczenieId: json['cwiczenieId'] as String,
      nazwaCwiczeniaPl: json['nazwaCwiczeniaPl'] as String,
      ciezarKg: (json['ciezarKg'] as num).toDouble(),
      powtorzenia: (json['powtorzenia'] as num).toInt(),
      data: DateTime.parse(json['data'] as String),
      szacowane1Rm: (json['szacowane1Rm'] as num).toDouble(),
    );

Map<String, dynamic> _$$PersonalRecordImplToJson(
  _$PersonalRecordImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'cwiczenieId': instance.cwiczenieId,
  'nazwaCwiczeniaPl': instance.nazwaCwiczeniaPl,
  'ciezarKg': instance.ciezarKg,
  'powtorzenia': instance.powtorzenia,
  'data': instance.data.toIso8601String(),
  'szacowane1Rm': instance.szacowane1Rm,
};
