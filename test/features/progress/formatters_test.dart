// Testy Formatters - formatowanie dat/liczb zgodne z polską lokalizacją.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fitbirek_training/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    // Wymagane przez DateFormat z locale 'pl_PL' - inicjalizacja danych
    // lokalizacyjnych intl przed użyciem w testach (poza kontekstem widgetu).
    await initializeDateFormatting('pl_PL');
  });

  group('Formatters.date', () {
    test('formatuje datę jako dd.MM.yyyy', () {
      expect(Formatters.date(DateTime(2026, 1, 15)), '15.01.2026');
    });

    test('dopełnia zerami dzień i miesiąc jednocyfrowy', () {
      expect(Formatters.date(DateTime(2026, 3, 5)), '05.03.2026');
    });
  });

  group('Formatters.dateTime', () {
    test('formatuje datę i czas jako dd.MM.yyyy HH:mm', () {
      expect(
        Formatters.dateTime(DateTime(2026, 1, 15, 19, 30)),
        '15.01.2026 19:30',
      );
    });
  });

  group('Formatters.time', () {
    test('formatuje czas jako HH:mm', () {
      expect(Formatters.time(DateTime(2026, 1, 15, 8, 5)), '08:05');
    });
  });

  group('Formatters.dayMonth', () {
    test('formatuje dzień i miesiąc słownie po polsku', () {
      expect(Formatters.dayMonth(DateTime(2026, 1, 15)), '15 stycznia');
    });
  });

  group('Formatters.weekday', () {
    test('formatuje dzień tygodnia słownie po polsku', () {
      // 2026-01-15 to czwartek
      expect(Formatters.weekday(DateTime(2026, 1, 15)), 'czwartek');
    });
  });

  group('Formatters.duration', () {
    test('formatuje sekundy jako mm:ss gdy poniżej godziny', () {
      expect(Formatters.duration(65), '01:05');
    });

    test('formatuje 0 sekund jako 00:00', () {
      expect(Formatters.duration(0), '00:00');
    });

    test('formatuje sekundy jako hh:mm:ss gdy godzina lub więcej', () {
      expect(Formatters.duration(3665), '01:01:05');
    });

    test('formatuje równo 60 sekund jako 01:00', () {
      expect(Formatters.duration(60), '01:00');
    });

    test('formatuje równo 3600 sekund jako 01:00:00', () {
      expect(Formatters.duration(3600), '01:00:00');
    });
  });

  group('Formatters.weight', () {
    test('formatuje wagę z jedną cyfrą po przecinku i sufiksem kg', () {
      expect(Formatters.weight(94.5), '94.5 kg');
    });

    test('dopełnia całą liczbę zerem po przecinku', () {
      expect(Formatters.weight(94), '94.0 kg');
    });

    test('zaokrągla do jednej cyfry po przecinku', () {
      expect(Formatters.weight(94.567), '94.6 kg');
    });
  });

  group('Formatters.deltaPercent', () {
    test('dodaje znak + dla wartości dodatniej', () {
      expect(Formatters.deltaPercent(2.3), '+2.3%');
    });

    test('nie dubluje znaku - dla wartości ujemnej', () {
      expect(Formatters.deltaPercent(-1.1), '-1.1%');
    });

    test('dodaje znak + dla zera (zero traktowane jako nieujemne)', () {
      expect(Formatters.deltaPercent(0), '+0.0%');
    });
  });
}
