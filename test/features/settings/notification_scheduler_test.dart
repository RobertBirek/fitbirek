import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/services/notification_scheduler.dart';

void main() {
  group('NotificationScheduler.nextWeekdayTime', () {
    test('zwraca ten samy dzien, jesli godzina jeszcze nie minela', () {
      // Wtorek 2025-01-07, 10:00 -> szukamy najblizszego wtorku 19:30.
      final from = DateTime(2025, 1, 7, 10, 0);
      final result = NotificationScheduler.nextWeekdayTime(
        from,
        weekday: DateTime.tuesday,
        hour: 19,
        minute: 30,
      );
      expect(result, DateTime(2025, 1, 7, 19, 30));
    });

    test('przeskakuje do nastepnego tygodnia, jesli godzina juz minela', () {
      // Wtorek 2025-01-07, 20:00 -> 19:30 juz minelo, nastepny wtorek za tydzien.
      final from = DateTime(2025, 1, 7, 20, 0);
      final result = NotificationScheduler.nextWeekdayTime(
        from,
        weekday: DateTime.tuesday,
        hour: 19,
        minute: 30,
      );
      expect(result, DateTime(2025, 1, 14, 19, 30));
    });

    test('znajduje najblizszy czwartek z poniedzialku', () {
      // Poniedzialek 2025-01-06 -> najblizszy czwartek to 2025-01-09.
      final from = DateTime(2025, 1, 6, 8, 0);
      final result = NotificationScheduler.nextWeekdayTime(
        from,
        weekday: DateTime.thursday,
        hour: 19,
        minute: 30,
      );
      expect(result, DateTime(2025, 1, 9, 19, 30));
    });

    test('dziala poprawnie tuz przed granica minuty (rownosc = przeskok)', () {
      // Dokladnie w momencie docelowym -> traktujemy jako "juz minelo",
      // przeskakujemy o tydzien (unikamy planowania notyfikacji w przeszlosci).
      final from = DateTime(2025, 1, 7, 19, 30);
      final result = NotificationScheduler.nextWeekdayTime(
        from,
        weekday: DateTime.tuesday,
        hour: 19,
        minute: 30,
      );
      expect(result, DateTime(2025, 1, 14, 19, 30));
    });
  });

  group('NotificationScheduler.nextDailyTime', () {
    test('zwraca dzisiaj, jesli godzina jeszcze nie minela', () {
      final from = DateTime(2025, 1, 7, 10, 0);
      final result = NotificationScheduler.nextDailyTime(
        from,
        hour: 18,
        minute: 0,
      );
      expect(result, DateTime(2025, 1, 7, 18, 0));
    });

    test('przeskakuje na jutro, jesli godzina juz minela', () {
      final from = DateTime(2025, 1, 7, 20, 0);
      final result = NotificationScheduler.nextDailyTime(
        from,
        hour: 18,
        minute: 0,
      );
      expect(result, DateTime(2025, 1, 8, 18, 0));
    });

    test('rownosc traktowana jako "juz minelo" - przeskok na jutro', () {
      final from = DateTime(2025, 1, 7, 18, 0);
      final result = NotificationScheduler.nextDailyTime(
        from,
        hour: 18,
        minute: 0,
      );
      expect(result, DateTime(2025, 1, 8, 18, 0));
    });

    test('poprawne przejscie przez granice miesiaca', () {
      final from = DateTime(2025, 1, 31, 21, 0);
      final result = NotificationScheduler.nextDailyTime(
        from,
        hour: 20,
        minute: 30,
      );
      expect(result, DateTime(2025, 2, 1, 20, 30));
    });
  });
}
