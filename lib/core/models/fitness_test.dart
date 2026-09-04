import 'package:freezed_annotation/freezed_annotation.dart';

part 'fitness_test.freezed.dart';
part 'fitness_test.g.dart';

/// Definicja predefiniowanego testu sprawnościowego (11 testów wg brief).
enum TypTestu {
  maxPompki,
  pullUp,
  chinUp,
  plank,
  wallSit,
  deadHang,
  przysiady60s,
  skakanka,
  cooper12min,
  sklon,
  glebokiPrzysiad,
}

extension TypTestuLabel on TypTestu {
  String get label {
    switch (this) {
      case TypTestu.maxPompki:
        return 'Max pompki';
      case TypTestu.pullUp:
        return 'Pull-up (max powt.)';
      case TypTestu.chinUp:
        return 'Chin-up (max powt.)';
      case TypTestu.plank:
        return 'Plank (czas)';
      case TypTestu.wallSit:
        return 'Wall sit (czas)';
      case TypTestu.deadHang:
        return 'Dead hang (czas)';
      case TypTestu.przysiady60s:
        return 'Przysiady w 60s';
      case TypTestu.skakanka:
        return 'Skakanka (max czas)';
      case TypTestu.cooper12min:
        return 'Test Coopera (12 min)';
      case TypTestu.sklon:
        return 'Skłon w przód';
      case TypTestu.glebokiPrzysiad:
        return 'Głęboki przysiad (mobilność)';
    }
  }

  /// Jednostka wyniku - "powt" dla powtórzeń, "s" dla sekund, "m" dla metrów.
  String get jednostka {
    switch (this) {
      case TypTestu.maxPompki:
      case TypTestu.pullUp:
      case TypTestu.chinUp:
      case TypTestu.przysiady60s:
        return 'powt';
      case TypTestu.plank:
      case TypTestu.wallSit:
      case TypTestu.deadHang:
      case TypTestu.skakanka:
        return 's';
      case TypTestu.cooper12min:
        return 'm';
      case TypTestu.sklon:
      case TypTestu.glebokiPrzysiad:
        return 'cm';
    }
  }
}

/// Wynik jednego testu w ramach sesji testowej.
@freezed
class FitnessTestResult with _$FitnessTestResult {
  const factory FitnessTestResult({
    required int id,
    required TypTestu typ,
    required DateTime data,
    required double wynik,
    @Default(0) int score,
  }) = _FitnessTestResult;

  factory FitnessTestResult.fromJson(Map<String, dynamic> json) =>
      _$FitnessTestResultFromJson(json);
}
