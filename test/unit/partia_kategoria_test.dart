// Testy mapToKategoria() - redukcja granularnej wartości Exercise.partiaGlowna
// (~163 unikalne wartości w prawdziwej bazie 316 ćwiczeń) do 10 prostych
// kategorii UI używanych przez filtry i PlanGenerator.

import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/utils/partia_kategoria.dart';

void main() {
  group('mapToKategoria - dopasowania podstawowe', () {
    test('Klatka piersiowa -> Klatka', () {
      expect(mapToKategoria('Klatka piersiowa'), 'Klatka');
    });

    test('Latissimus dorsi -> Plecy', () {
      expect(mapToKategoria('Latissimus dorsi'), 'Plecy');
    });

    test('Boczne aktony barków -> Barki', () {
      expect(mapToKategoria('Boczne aktony barków'), 'Barki');
    });

    test('Rotatory (infraspinatus, teres minor) -> Barki', () {
      expect(mapToKategoria('Rotatory (infraspinatus, teres minor)'), 'Barki');
    });

    test('Biceps (długa głowa) -> Biceps', () {
      expect(mapToKategoria('Biceps (długa głowa)'), 'Biceps');
    });

    test('Triceps (przyśrodkowa głowa) -> Triceps', () {
      expect(mapToKategoria('Triceps (przyśrodkowa głowa)'), 'Triceps');
    });

    test(
      'Kwadryceps, Pośladki -> Pośladki (pośladki sprawdzane przed nogami)',
      () {
        expect(mapToKategoria('Kwadryceps, Pośladki'), 'Pośladki');
      },
    );

    test('Pośladki (glute medius) -> Pośladki', () {
      expect(mapToKategoria('Pośladki (glute medius)'), 'Pośladki');
    });

    test('Nogi (eksplozja) -> Nogi', () {
      expect(mapToKategoria('Nogi (eksplozja)'), 'Nogi');
    });

    test('Skośne brzucha -> Brzuch', () {
      expect(mapToKategoria('Skośne brzucha'), 'Brzuch');
    });

    test('Cardio (HIIT) -> Cardio', () {
      expect(mapToKategoria('Cardio (HIIT)'), 'Cardio');
    });

    test('Kręgosłup (mobilność) -> Mobilność', () {
      expect(mapToKategoria('Kręgosłup (mobilność)'), 'Mobilność');
    });
  });

  group('mapToKategoria - Full body zależny od wzorca ruchu', () {
    test('Full body + wzorzec Explosive -> Cardio', () {
      expect(
        mapToKategoria('Full body', wzorzecRuchu: 'Full body explosive'),
        'Cardio',
      );
    });

    test('Full body + wzorzec bez cardio/explosive -> Nogi (fallback)', () {
      expect(mapToKategoria('Full body', wzorzecRuchu: 'Flow'), 'Nogi');
    });
  });

  group('mapToKategoria - przypadki resztkowe (fallback Mobilność)', () {
    test('Zginacze bioder (iliopsoas) -> Mobilność', () {
      expect(mapToKategoria('Zginacze bioder (iliopsoas)'), 'Mobilność');
    });

    test('Głębokie zginacze szyi -> Mobilność', () {
      expect(mapToKategoria('Głębokie zginacze szyi'), 'Mobilność');
    });
  });

  test('funkcja jest case-insensitive', () {
    expect(mapToKategoria('KLATKA PIERSIOWA'), 'Klatka');
    expect(mapToKategoria('latissimus dorsi'), 'Plecy');
  });
}
