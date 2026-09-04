/// Czysta logika obliczania terminów powiadomień lokalnych - bez zależności
/// od `flutter_local_notifications` czy `timezone`, żeby dało się testować
/// jednostkowo na zwykłym `DateTime` (bez in-memory pluginu/platform channels).
class NotificationScheduler {
  /// Zwraca najbliższy moment wystąpienia [weekday] (np. [DateTime.tuesday])
  /// o godzinie [hour]:[minute], licząc od [from] (wyłącznie - jeśli [from]
  /// jest równe kandydatowi, przesuwamy o tydzień, żeby nigdy nie zaplanować
  /// notyfikacji w przeszłości).
  static DateTime nextWeekdayTime(
    DateTime from, {
    required int weekday,
    required int hour,
    required int minute,
  }) {
    for (var i = 0; i < 8; i++) {
      final day = DateTime(
        from.year,
        from.month,
        from.day,
      ).add(Duration(days: i));
      if (day.weekday != weekday) continue;
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      if (candidate.isAfter(from)) return candidate;
    }
    // Nie powinno się zdarzyć - każdy dzień tygodnia trafia się w ciągu 7 dni.
    throw StateError('Nie znaleziono najbliższego dnia tygodnia $weekday');
  }

  /// Zwraca najbliższy moment o godzinie [hour]:[minute] - dziś, jeśli ta
  /// godzina jeszcze nie minęła, w przeciwnym razie jutro.
  static DateTime nextDailyTime(
    DateTime from, {
    required int hour,
    required int minute,
  }) {
    var candidate = DateTime(from.year, from.month, from.day, hour, minute);
    if (!candidate.isAfter(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
