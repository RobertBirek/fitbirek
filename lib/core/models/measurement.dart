import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement.freezed.dart';
part 'measurement.g.dart';

/// Pomiar ciała - waga, obwody, tętno, ciśnienie.
@freezed
class Measurement with _$Measurement {
  const factory Measurement({
    required int id,
    required DateTime data,
    required double wagaKg,
    double? obwodKlatki,
    double? obwodTalii,
    double? obwodBioder,
    double? obwodBicepsuP,
    double? obwodBicepsuL,
    double? obwodUdaP,
    double? obwodUdaL,
    double? obwodLydkiP,
    double? obwodLydkiL,
    double? procentTluszczu,
    int? tetnoSpoczynkowe,
    String? cisnienie, // np. "120/80"
    String? notatka,
  }) = _Measurement;

  factory Measurement.fromJson(Map<String, dynamic> json) =>
      _$MeasurementFromJson(json);
}
