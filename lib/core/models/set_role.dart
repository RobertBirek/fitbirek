/// NULL is historical compatibility, not a claim that a set was working.
abstract final class SetRole {
  static const working = 'working';
  static const warmup = 'warmup';

  static String? validate(Object? value) {
    if (value != null && value != working && value != warmup) {
      throw const FormatException('Nieprawidłowa rola serii.');
    }
    return value as String?;
  }

  static bool isEffectiveWorking(String? role) => role != warmup;
  static String label(String? role) => switch (role) {
    warmup => 'Rozgrzewkowa',
    working => 'Robocza',
    _ => 'Rola nieokreślona (starszy zapis)',
  };
}
