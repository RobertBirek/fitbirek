import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_entry.freezed.dart';
part 'mood_entry.g.dart';

/// Wpis dziennika samopoczucia - szybki formularz na ekranie "Dziś".
@freezed
class MoodEntry with _$MoodEntry {
  const factory MoodEntry({
    required int id,
    required DateTime data,
    required double snGodziny,
    required int energia, // 1-10
    required int nastroj, // 1-10
    required int apetyt, // 1-10
    required bool alkohol,
    @Default(0) int alkoholJednostki,
  }) = _MoodEntry;

  factory MoodEntry.fromJson(Map<String, dynamic> json) =>
      _$MoodEntryFromJson(json);
}
