import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/interval_timer_screen.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';

void main() {
  testWidgets('target timer starts from its own seconds and fixes one round', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IntervalTimerScreen(
          label: 'Robocza 2',
          singleRound: true,
          initialWorkSeconds: 47,
        ),
      ),
    );
    final rounds = tester.widget<TextFormField>(
      find.byKey(const Key('rounds')),
    );
    expect(rounds.controller!.text, '1');
    expect(rounds.enabled, isFalse);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('work')))
          .controller!
          .text,
      '47',
    );
    expect(find.textContaining('Jeden wybrany cel'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'a multi-round checkpoint is not converted into a guided target',
    (tester) async {
      final old = IntervalTimer(
        IntervalConfig(preparation: 0, work: 20, rest: 0, rounds: 3),
      )..start();
      await tester.pumpWidget(
        MaterialApp(
          home: IntervalTimerScreen(
            label: 'Robocza',
            singleRound: true,
            checkpoint: old.checkpoint(),
          ),
        ),
      );
      expect(find.textContaining('Wyniki odrzucono'), findsOneWidget);
      expect(find.text('Rozpocznij interwały'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
