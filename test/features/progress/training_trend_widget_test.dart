import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/progress/trends/domain/training_trend.dart';
import 'package:fitbirek_training/features/progress/trends/providers/training_trend_providers.dart';
import 'package:fitbirek_training/features/progress/trends/presentation/training_trends_page.dart';

void main() {
  testWidgets('result before filters and methodology, friendly scope labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainingTrendHistoryProvider.overrideWith(
            (ref) async => [
              TrendRow(
                scope: (exerciseId: 'cw001', side: null, variantId: null),
                sessionId: 1,
                setId: 1,
                endedAt: DateTime.utc(2026),
                setNumber: 1,
                exerciseName: 'Pompki',
                reps: 10,
              ),
            ],
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(),
          ),
        ],
        child: const MaterialApp(home: TrainingTrendsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Strona nieokreślona'), findsOneWidget);
    expect(find.textContaining('NULL'), findsNothing);
    expect(find.textContaining('cw001'), findsNothing);
    expect(
      tester.getTopLeft(find.textContaining('Za mało danych:')).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('trend-exercise'))).dy),
    );
    expect(
      find.widgetWithText(ExpansionTile, 'Jak czytać wyniki i wyłączenia'),
      findsOneWidget,
    );
  });
  testWidgets('UI never shows delayed old-account history', (tester) async {
    final revision = StateProvider((ref) => 0);
    final delayed = Completer<List<TrendRow>?>();
    final c = ProviderContainer(
      overrides: [
        trainingTrendHistoryProvider.overrideWith((ref) async {
          final epoch = ref.watch(revision);
          return epoch == 0 ? delayed.future : null;
        }),
        exerciseCatalogMetadataProvider.overrideWith(
          (ref) async => const ExerciseCatalogMetadata(),
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: TrainingTrendsPage()),
      ),
    );
    c.read(revision.notifier).state++;
    await tester.pumpAndSettle();
    delayed.complete([
      TrendRow(
        scope: (exerciseId: 'secret', side: null, variantId: null),
        sessionId: 1,
        setId: 1,
        endedAt: DateTime.utc(2026),
        setNumber: 1,
        exerciseName: 'Secret',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Secret'), findsNothing);
    expect(find.textContaining('Konto niedostępne'), findsOneWidget);
  });
  Future<void> show(WidgetTester tester, List<TrendRow>? rows) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainingTrendHistoryProvider.overrideWith((ref) async => rows),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(),
          ),
        ],
        child: const MaterialApp(home: TrainingTrendsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty and account unavailable are distinct', (tester) async {
    await show(tester, []);
    expect(find.text('Brak zakończonej historii'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await show(tester, null);
    expect(find.textContaining('Konto niedostępne'), findsOneWidget);
  });
  testWidgets(
    'actual scope switches retain deleted UUID snapshot, base independent',
    (tester) async {
      await show(tester, [
        for (final v in <String?>[null, 'deleted-uuid'])
          TrendRow(
            scope: (exerciseId: 'ex', side: null, variantId: v),
            sessionId: 1,
            setId: v == null ? 1 : 2,
            endedAt: DateTime.utc(2026, 10, 17),
            setNumber: 1,
            exerciseName: 'Test',
            variantLabel: v == null ? null : 'Dawna nazwa',
            reps: 8,
          ),
      ]);
      expect(find.text('Wariant bazowy'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trend-variant')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Dawna nazwa').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Jak czytać wyniki i wyłączenia'));
      await tester.tap(find.text('Jak czytać wyniki i wyłączenia'));
      await tester.pumpAndSettle();
      expect(find.textContaining('deleted-uuid'), findsWidgets);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-10-17'), findsWidgets);
      expect(
        find.textContaining('brak zapisanego pełnego protokołu'),
        findsWidgets,
      );
    },
  );
  testWidgets(
    'exercise and NULL/both side switches show only exact observations',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester, [
        for (final entry in [
          ('a', null, 11),
          ('a', 'both', 22),
          ('b', null, 33),
        ])
          TrendRow(
            scope: (exerciseId: entry.$1, side: entry.$2, variantId: null),
            sessionId: 1,
            setId: entry.$3,
            endedAt: DateTime.utc(2026),
            setNumber: 1,
            exerciseName: entry.$1,
            reps: entry.$3,
          ),
      ]);
      expect(find.textContaining('Powtórzenia: 11'), findsOneWidget);
      expect(find.textContaining('Powtórzenia: 22'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('trend-side-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obie').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Powtórzenia: 22'), findsOneWidget);
      expect(find.textContaining('Powtórzenia: 11'), findsNothing);
      await tester.tap(find.byKey(const Key('trend-exercise')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('b').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Powtórzenia: 33'), findsOneWidget);
      expect(find.textContaining('Powtórzenia: 22'), findsNothing);
    },
  );
}
