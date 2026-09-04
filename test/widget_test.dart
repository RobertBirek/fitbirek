// Podstawowe testy widgetów FitBirek.
//
// Uwaga: pełna aplikacja (FitBirekApp) wymaga zainicjalizowanej bazy Drift
// (async import ćwiczeń z assets) i providerów Riverpod, więc smoke-testy
// uruchamiamy w kontekście ProviderScope + MaterialApp z prostym widgetem,
// a nie bezpośrednio na FitBirekApp (co wymagałoby pełnego bootstrapu z main.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/widgets/primary_button.dart';
import 'package:fitbirek_training/core/widgets/empty_state.dart';
import 'package:fitbirek_training/core/utils/bmr_calculator.dart';
import 'package:fitbirek_training/core/utils/pr_detector.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';

void main() {
  testWidgets('PrimaryButton wyświetla etykietę i reaguje na tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Rozpocznij trening',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Rozpocznij trening'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('EmptyState pokazuje tytuł, podtytuł i CTA', (
    WidgetTester tester,
  ) async {
    var ctaTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.history,
            title: 'Brak historii treningów',
            subtitle: 'Zacznij pierwszy trening →',
            ctaLabel: 'Wybierz ćwiczenia',
            onCtaPressed: () => ctaTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Brak historii treningów'), findsOneWidget);
    expect(find.text('Wybierz ćwiczenia'), findsOneWidget);
    await tester.tap(find.text('Wybierz ćwiczenia'));
    await tester.pump();
    expect(ctaTapped, isTrue);
  });

  testWidgets('ProviderScope montuje się bez błędów', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: Text('OK'))),
      ),
    );
    expect(find.text('OK'), findsOneWidget);
  });

  test('BmrCalculator liczy sensowne BMR dla przykładowego profilu', () {
    final profile = UserProfile(
      imie: 'Robert',
      wiek: 47,
      wzrostCm: 180,
      wagaKg: 94,
      cel: CelTreningowy.redukcja,
      dostepnySprzet: const ['hantle'],
      dataUtworzenia: DateTime(2024, 1, 1),
    );
    final result = BmrCalculator.calculateFull(profile);
    // BMR Mifflin-St Jeor (mężczyzna): 10*94 + 6.25*180 - 5*47 + 5 = 1835.0
    // (poprzednia oczekiwana wartość 1707.5 w tym teście była błędna -
    // sam wzór w BmrCalculator jest poprawny, to literówka w asercji).
    expect(result.bmr, closeTo(1835.0, 0.5));
    expect(result.tdee, greaterThan(result.bmr));
    // Cel redukcja => kalorie docelowe niższe niż TDEE
    expect(result.celKalorii, lessThan(result.tdee));
  });

  test('PrDetector wykrywa nowy rekord przy wyższym szacowanym 1RM', () {
    final poprzedni1Rm = PrDetector.epley1Rm(15, 8);
    final isPr = PrDetector.isNewRecord(
      nowyCiezar: 15,
      nowePowtorzenia: 9,
      dotychczasowyBest1Rm: poprzedni1Rm,
    );
    expect(isPr, isTrue);
  });

  test('PrDetector nie zgłasza PR gdy wynik jest słabszy', () {
    final poprzedni1Rm = PrDetector.epley1Rm(15, 9);
    final isPr = PrDetector.isNewRecord(
      nowyCiezar: 15,
      nowePowtorzenia: 8,
      dotychczasowyBest1Rm: poprzedni1Rm,
    );
    expect(isPr, isFalse);
  });
}
