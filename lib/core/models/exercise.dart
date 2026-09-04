import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

/// Model ćwiczenia z bazy 316 ćwiczeń (starter pack: 38 reprezentatywnych).
/// TODO: import pełnej bazy 316 ćwiczeń z Excel poprzez skrypt build_exercises.dart (patrz README.md)
@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String nazwaPl,
    required String nazwaEn,
    required String partiaGlowna,
    required List<String> partieWspierajace,
    required List<String> sprzet,
    required String typ,
    required String poziom,
    required String wzorzecRuchu,
    required String seriexPowtorzenia,
    required String tempo,
    required List<String> kluczoweWskazowki,
    required List<String> czesteBledy,
    required String progresja,
    required String regresja,
    required String zrodlo,
    @Default(false) bool ulubione,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}
