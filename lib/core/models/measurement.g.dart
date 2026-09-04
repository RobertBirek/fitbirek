// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeasurementImpl _$$MeasurementImplFromJson(Map<String, dynamic> json) =>
    _$MeasurementImpl(
      id: (json['id'] as num).toInt(),
      data: DateTime.parse(json['data'] as String),
      wagaKg: (json['wagaKg'] as num).toDouble(),
      obwodKlatki: (json['obwodKlatki'] as num?)?.toDouble(),
      obwodTalii: (json['obwodTalii'] as num?)?.toDouble(),
      obwodBioder: (json['obwodBioder'] as num?)?.toDouble(),
      obwodBicepsuP: (json['obwodBicepsuP'] as num?)?.toDouble(),
      obwodBicepsuL: (json['obwodBicepsuL'] as num?)?.toDouble(),
      obwodUdaP: (json['obwodUdaP'] as num?)?.toDouble(),
      obwodUdaL: (json['obwodUdaL'] as num?)?.toDouble(),
      obwodLydkiP: (json['obwodLydkiP'] as num?)?.toDouble(),
      obwodLydkiL: (json['obwodLydkiL'] as num?)?.toDouble(),
      procentTluszczu: (json['procentTluszczu'] as num?)?.toDouble(),
      tetnoSpoczynkowe: (json['tetnoSpoczynkowe'] as num?)?.toInt(),
      cisnienie: json['cisnienie'] as String?,
      notatka: json['notatka'] as String?,
    );

Map<String, dynamic> _$$MeasurementImplToJson(_$MeasurementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': instance.data.toIso8601String(),
      'wagaKg': instance.wagaKg,
      'obwodKlatki': instance.obwodKlatki,
      'obwodTalii': instance.obwodTalii,
      'obwodBioder': instance.obwodBioder,
      'obwodBicepsuP': instance.obwodBicepsuP,
      'obwodBicepsuL': instance.obwodBicepsuL,
      'obwodUdaP': instance.obwodUdaP,
      'obwodUdaL': instance.obwodUdaL,
      'obwodLydkiP': instance.obwodLydkiP,
      'obwodLydkiL': instance.obwodLydkiL,
      'procentTluszczu': instance.procentTluszczu,
      'tetnoSpoczynkowe': instance.tetnoSpoczynkowe,
      'cisnienie': instance.cisnienie,
      'notatka': instance.notatka,
    };
