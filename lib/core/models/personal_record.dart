import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_record.freezed.dart';
part 'personal_record.g.dart';

/// Rekord osobisty (PR) dla danego ćwiczenia - auto-wykrywany podczas sesji.
@freezed
class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    required int id,
    required String cwiczenieId,
    required String nazwaCwiczeniaPl,
    required double ciezarKg,
    required int powtorzenia,
    required DateTime data,
    // szacowany 1RM wg formuły Epley: ciezar * (1 + powtorzenia/30)
    required double szacowane1Rm,
  }) = _PersonalRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);
}
