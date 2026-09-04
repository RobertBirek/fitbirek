import 'package:freezed_annotation/freezed_annotation.dart';

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
    int? rpe,
    required DateTime timestamp,
  }) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) =>
      _$SetLogFromJson(json);
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
