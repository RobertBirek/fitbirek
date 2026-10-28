// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'set_role.dart';

part 'workout_session.freezed.dart';
part 'workout_session.g.dart';

/// Pojedyncza wykonana seria ćwiczenia w ramach sesji treningowej.
@freezed
class SetLog with _$SetLog {
  const factory SetLog({
    required int id,
    required int sesjaId,
    required String cwiczenieId,
    required String nazwaCwiczeniaPl,
    required int numerSerii,
    double? ciezarKg,
    int? powtorzenia,
    int? czasSekund, // dla planku, wall sit itd.
    @JsonKey(includeIfNull: false) String? side,
    @JsonKey(includeIfNull: false) String? setRole,
    @JsonKey(includeIfNull: false) String? variantId,
    @JsonKey(includeIfNull: false) String? variantLabel,
    int? rpe,
    required DateTime timestamp,
  }) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) =>
      _$SetLogFromJson(_validatedSetLogJson(json));
}

Map<String, dynamic> _validatedSetLogJson(Map<String, dynamic> json) {
  SetRole.validate(json['setRole']);
  return json;
}

/// Sesja treningowa - jeden trening złożony z wielu serii.
@freezed
class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required int id,
    required DateTime dataStart,
    DateTime? dataKoniec,
    required int czasTrwaniaSekund,
    String? notatka,
    @Default([]) List<SetLog> serie,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
}
