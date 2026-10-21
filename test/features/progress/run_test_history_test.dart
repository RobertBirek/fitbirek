import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/fitness_test_widgets.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/run_test_page.dart';
import 'fitness_protocol_widgets_test.dart' show PendingWorkflow;
import 'fitness_ui_support.dart';

void main() {
  final json =
      (jsonDecode(
                File(
                  'tests/fixtures/fitness_protocol_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['protocol']
          as Map<String, dynamic>;
  for (final state in ['prior', 'empty', 'loading', 'error', 'unavailable']) {
    testWidgets('custom result entry presents $state history truthfully', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final p = await fixture.repo.createProtocol(
        await fixture.repo.captureLease(),
        FitnessProtocolDraft.fromProtocol(FitnessProtocol.fromJson(json)),
      );
      final lease = await fixture.repo.captureLease(protocolId: p.id);
      await fixture.repo.addCustomResult(
        lease,
        value: 13,
        performedAt: DateTime.utc(2020, 1, 2),
      );
      final prior = CustomFitnessResult.fromRow(
        (await fixture.db.select(fixture.db.fitnessTestResults).get()).single,
      );
      final workflow = PendingWorkflow(lease);
      final Stream<List<CustomFitnessResult>?> history = switch (state) {
        'prior' => Stream.value([prior]),
        'empty' => Stream.value([]),
        'loading' => const Stream.empty(),
        'error' => Stream.error(StateError('private database details')),
        _ => Stream.value(null),
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessTestsWorkflowProvider.overrideWithValue(workflow),
            customFitnessResultsProvider.overrideWith((ref) => history),
          ],
          child: MaterialApp(home: RunTestPage(protocolId: p.id)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(switch (state) {
          'prior' => '— → 13 powt.',
          'empty' => 'Jeszcze bez wyniku',
          'loading' => 'Ładowanie historii…',
          'error' => 'Nie udało się wczytać historii.',
          _ => 'Historia niedostępna',
        }),
        findsOneWidget,
      );
      if (state != 'unavailable') {
        expect(find.text('Historia niedostępna'), findsNothing);
      }
      if (state != 'empty') {
        expect(find.text('Jeszcze bez wyniku'), findsNothing);
      }
      expect(find.textContaining('private database'), findsNothing);
      expect(workflow.captures, 1);
      expect(workflow.saves, 0);
      expect(
        identical(
          tester
              .widget<FitnessResultForm>(find.byType(FitnessResultForm))
              .lease,
          lease,
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
    'history updates preserve result draft, selected date and the opening lease',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final p = await fixture.repo.createProtocol(
        await fixture.repo.captureLease(),
        FitnessProtocolDraft.fromProtocol(FitnessProtocol.fromJson(json)),
      );
      final lease = await fixture.repo.captureLease(protocolId: p.id);
      await fixture.repo.addCustomResult(
        lease,
        value: 13,
        performedAt: DateTime.utc(2020, 1, 2),
      );
      final prior = CustomFitnessResult.fromRow(
        (await fixture.db.select(fixture.db.fitnessTestResults).get()).single,
      );
      final history = StreamController<List<CustomFitnessResult>?>.broadcast();
      addTearDown(history.close);
      final workflow = PendingWorkflow(lease);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessTestsWorkflowProvider.overrideWithValue(workflow),
            customFitnessResultsProvider.overrideWith((ref) => history.stream),
          ],
          child: MaterialApp(home: RunTestPage(protocolId: p.id)),
        ),
      );
      await tester.pumpAndSettle();
      history.add([prior]);
      await tester.pumpAndSettle();
      expect(find.text('— → 13 powt.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '19');
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller;
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '01/02/2020');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final date = tester
          .widget<FitnessDateField>(find.byType(FitnessDateField))
          .value;
      expect(date.year, 2020);
      for (final state in ['empty', 'error', 'prior', 'unavailable']) {
        if (state == 'error') {
          history.addError(StateError('account read failed'));
        } else {
          history.add(
            state == 'empty'
                ? []
                : state == 'prior'
                ? [prior]
                : null,
          );
        }
        await tester.pumpAndSettle();
        expect(
          find.text(switch (state) {
            'empty' => 'Jeszcze bez wyniku',
            'error' => 'Nie udało się wczytać historii.',
            'prior' => '— → 13 powt.',
            _ => 'Historia niedostępna',
          }),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller,
          same(controller),
        );
        expect(controller!.text, '19');
        expect(
          tester.widget<FitnessDateField>(find.byType(FitnessDateField)).value,
          date,
        );
        expect(
          tester
              .widget<FitnessResultForm>(find.byType(FitnessResultForm))
              .lease,
          same(lease),
        );
        expect(workflow.captures, 1);
        expect(workflow.saves, 0);
      }
      await tester.tap(find.text('Zapisz wynik'));
      await tester.pump();
      expect(workflow.value, 19);
      expect(workflow.date, date);
      expect(workflow.captures, 1);
      workflow.pending.completeError(StateError('original lease is stale'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
