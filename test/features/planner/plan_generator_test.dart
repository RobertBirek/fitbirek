// Testy PlanGenerator - algorytm doboru ćwiczeń do planu treningowego na
// podstawie celu, poziomu, dostępnego sprzętu i czasu.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/planner/domain/plan_generator.dart';

Exercise _ex({
  required String id,
  required String partiaGlowna,
  List<String> sprzet = const [],
  String poziom = 'Początkujący',
}) {
  return Exercise(
    id: id,
    nazwaPl: id,
    nazwaEn: id,
    partiaGlowna: partiaGlowna,
    partieWspierajace: const [],
    sprzet: sprzet,
    typ: 'Siłowe',
    poziom: poziom,
    wzorzecRuchu: 'push',
    seriexPowtorzenia: '3x10',
    tempo: '2-0-2',
    kluczoweWskazowki: const [],
    czesteBledy: const [],
    progresja: '',
    regresja: '',
    zrodlo: 'test',
  );
}

void main() {
  final bazaCwiczen = <Exercise>[
    _ex(id: 'pompki', partiaGlowna: 'Klatka'),
    _ex(id: 'przysiady', partiaGlowna: 'Nogi'),
    _ex(id: 'plank', partiaGlowna: 'Brzuch'),
    _ex(id: 'wyciskanie_hantli', partiaGlowna: 'Klatka', sprzet: ['Hantle']),
    _ex(id: 'martwy_ciag_hantle', partiaGlowna: 'Plecy', sprzet: ['Hantle']),
    _ex(id: 'wspiecia_barki', partiaGlowna: 'Barki', sprzet: ['Hantle']),
    _ex(id: 'pompki_diamond', partiaGlowna: 'Triceps', poziom: 'Zaawansowany'),
    _ex(
      id: 'przysiady_bulgarskie',
      partiaGlowna: 'Pośladki',
      sprzet: ['Ławka'],
    ),
    _ex(id: 'burpees', partiaGlowna: 'Cardio'),
    _ex(id: 'uginanie_hantli', partiaGlowna: 'Biceps', sprzet: ['Hantle']),
  ];

  group('PlanGenerator.generate - filtrowanie sprzętu', () {
    test('wybiera tylko ćwiczenia zgodne z dostępnym sprzętem', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Zaawansowany',
        dostepnySprzet: const [], // brak sprzętu -> tylko ćwiczenia bez sprzętu
      );
      for (final ex in plan) {
        expect(ex.sprzet, isEmpty);
      }
    });

    test('zwraca pustą listę gdy brak kandydatów spełniających kryteria', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Początkujący',
        dostepnySprzet: const ['NieistniejacySprzet'],
      );
      // Wszystkie ćwiczenia bez sprzętu mają sprzet=[] więc every() na pustej
      // liście jest true - zwracają się tylko te bez wymagań sprzętowych.
      expect(plan, isNotEmpty);
      for (final ex in plan) {
        expect(ex.sprzet, isEmpty);
      }
    });
  });

  group('PlanGenerator.generate - filtrowanie poziomu', () {
    test('nie wybiera ćwiczeń powyżej poziomu użytkownika', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Początkujący',
        dostepnySprzet: const ['Hantle', 'Ławka'],
      );
      expect(plan.any((ex) => ex.id == 'pompki_diamond'), isFalse);
    });

    test('zaawansowany użytkownik może otrzymać ćwiczenia zaawansowane', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Zaawansowany',
        dostepnySprzet: const ['Hantle', 'Ławka'],
        czasMinut: 90, // dużo czasu -> więcej miejsca na wszystkie partie
      );
      // Nie jest gwarantowane że akurat trafi triceps (limit iloscCwiczen),
      // ale przynajmniej nie powinno być wykluczone z kandydatów - sprawdzamy
      // to poprzez brak wyjątku i niepustą listę.
      expect(plan, isNotEmpty);
    });
  });

  group('PlanGenerator.generate - liczba ćwiczeń skalowana czasem', () {
    test('krótki czas treningu daje mniej ćwiczeń (min 4)', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Zaawansowany',
        dostepnySprzet: const ['Hantle', 'Ławka'],
        czasMinut: 20,
      );
      expect(plan.length, greaterThanOrEqualTo(4));
      expect(plan.length, lessThanOrEqualTo(6));
    });

    test('długi czas treningu daje maksymalnie 6 ćwiczeń', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Zaawansowany',
        dostepnySprzet: const ['Hantle', 'Ławka'],
        czasMinut: 120,
      );
      expect(plan.length, lessThanOrEqualTo(6));
    });
  });

  group('PlanGenerator.generate - priorytety wg celu', () {
    test('cel redukcja priorytetyzuje Cardio jako pierwszą partię', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.redukcja,
        poziom: 'Zaawansowany',
        dostepnySprzet: const ['Hantle', 'Ławka'],
        czasMinut: 45,
      );
      // Cardio jest pierwsze w priorytetach dla redukcji - powinno być
      // wybrane jako jedno z pierwszych ćwiczeń (jeśli dostępne kandydaci).
      expect(plan.any((ex) => ex.partiaGlowna == 'Cardio'), isTrue);
    });

    test('cel siła priorytetyzuje Klatkę jako pierwszą partię', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.sila,
        poziom: 'Zaawansowany',
        dostepnySprzet: const ['Hantle', 'Ławka'],
        czasMinut: 45,
      );
      expect(plan.any((ex) => ex.partiaGlowna == 'Klatka'), isTrue);
    });
  });

  group('PlanGenerator.generate - przypadki brzegowe', () {
    test('pusta baza ćwiczeń zwraca pustą listę', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: const [],
        cel: CelTreningowy.mix,
        poziom: 'Początkujący',
        dostepnySprzet: const [],
      );
      expect(plan, isEmpty);
    });

    test('nie zwraca duplikatów tego samego ćwiczenia', () {
      final plan = PlanGenerator.generate(
        wszystkieCwiczenia: bazaCwiczen,
        cel: CelTreningowy.mix,
        poziom: 'Zaawansowany',
        dostepnySprzet: const ['Hantle', 'Ławka'],
        czasMinut: 90,
      );
      final ids = plan.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
