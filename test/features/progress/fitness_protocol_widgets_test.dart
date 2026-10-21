import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/fitness_test_widgets.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/fitness_tests_section.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/run_test_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/protocol_editor_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/protocol_detail_page.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercise_variants_providers.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'fitness_ui_support.dart';

class PendingWorkflow implements FitnessTestsWorkflow {
  PendingWorkflow(this.lease);
  final FitnessWriteLease lease;
  int captures = 0, saves = 0;
  int archives = 0;
  String? capturedProtocol;
  final pending = Completer<void>();
  DateTime? date;
  num? value;
  @override
  Future<FitnessWriteLease> captureLease({String? protocolId}) async {
    captures++;
    capturedProtocol = protocolId;
    return lease;
  }

  @override
  Future<void> archiveProtocol(FitnessWriteLease lease) async {
    expect(identical(lease, this.lease), isTrue);
    archives++;
  }

  @override
  Future<void> addLegacyResult(
    FitnessWriteLease lease, {
    required dynamic typ,
    required double value,
    required DateTime performedAt,
  }) {
    expect(identical(lease, this.lease), isTrue);
    saves++;
    date = performedAt;
    return pending.future;
  }

  @override
  Future<void> addCustomResult(
    FitnessWriteLease lease, {
    required num value,
    required DateTime performedAt,
  }) {
    expect(identical(lease, this.lease), isTrue);
    saves++;
    date = performedAt;
    this.value = value;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  final protocolJson =
      (jsonDecode(
                File(
                  'tests/fixtures/fitness_protocol_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['protocol']
          as Map<String, dynamic>;
  final protocol = FitnessProtocol.fromJson(protocolJson);
  testWidgets(
    'custom reps validates before saving a backfilled date with original lease',
    (tester) async {
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final p = await fixture.repo.createProtocol(
        await fixture.repo.captureLease(),
        FitnessProtocolDraft.fromProtocol(protocol),
      );
      final lease = await fixture.repo.captureLease(protocolId: p.id);
      final workflow = PendingWorkflow(lease);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessTestsWorkflowProvider.overrideWithValue(workflow),
            customFitnessResultsProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: MaterialApp(home: RunTestPage(protocolId: p.id)),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.scrollUntilVisible(
        field,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(field, '1.5');
      await tester.scrollUntilVisible(
        find.text('Zapisz wynik'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Zapisz wynik'));
      await tester.pumpAndSettle();
      expect(workflow.saves, 0);
      expect(find.text('Wpisz całkowitą liczbę powtórzeń.'), findsOneWidget);
      await tester.enterText(field, '0');
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '01/02/2020');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zapisz wynik'));
      await tester.pump();
      expect(workflow.saves, 1);
      expect(workflow.value, 0);
      expect(workflow.date!.year, 2020);
      expect(workflow.captures, 1);
      expect(workflow.capturedProtocol, p.id);
      workflow.pending.completeError(StateError('stale epoch'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    },
  );
  CustomFitnessResult result(FitnessProtocol p, int value, int day) =>
      CustomFitnessResult.fromRow(
        FitnessTestResultData(
          id: day,
          syncId: 'result-$day',
          syncVersion: 1,
          updatedAtUtc: DateTime.utc(2026, 1, day),
          typ: 'customFitnessTestV1',
          data: DateTime.utc(2026, 1, day),
          wynik: value.toDouble(),
          score: 0,
          customProtocolJson: jsonEncode({
            'version': 1,
            'protocolId': p.id,
            'familyId': p.familyId,
            'snapshot': p.toJson(),
          }),
        ),
      );
  testWidgets(
    'history excludes changed snapshot and archive requires confirmation',
    (tester) async {
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final workflow = PendingWorkflow(await fixture.repo.captureLease());
      final changed = FitnessProtocol.fromJson({
        ...protocolJson,
        'instructions': 'Inne zasady',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessTestsWorkflowProvider.overrideWithValue(workflow),
            fitnessProtocolsProvider.overrideWith(
              (ref) => Stream.value(
                FitnessProtocolsView(isAvailable: true, protocols: [protocol]),
              ),
            ),
            customFitnessResultsProvider.overrideWith(
              (ref) => Stream.value([
                result(protocol, 20, 2),
                result(protocol, 18, 1),
                result(changed, 999, 3),
              ]),
            ),
          ],
          child: MaterialApp(home: ProtocolDetailPage(protocolId: protocol.id)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('18 → 20 powt.'), findsOneWidget);
      final archive = find.text('Archiwizuj test');
      await tester.scrollUntilVisible(archive, 200);
      await tester.tap(archive);
      await tester.pumpAndSettle();
      expect(workflow.capturedProtocol, protocol.id);
      expect(workflow.archives, 0);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(workflow.archives, 0);
      await tester.tap(archive);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archiwizuj'));
      await tester.pumpAndSettle();
      expect(workflow.archives, 1);
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rozbieżny zapis zasad'), findsOneWidget);
    },
  );
  final exercises =
      (jsonDecode(File('assets/data/exercises.json').readAsStringSync())
              as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
  testWidgets(
    'creator offers entire catalog and independent metrics at 320px / 200%',
    (tester) async {
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final lease = await fixture.repo.captureLease();
      final workflow = PendingWorkflow(lease);
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allExercisesProvider.overrideWith((ref) => Stream.value(exercises)),
            exerciseVariantsProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: ProtocolEditorForm(
                workflow: workflow,
                lease: lease,
                exerciseId: exercises.last.id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final exerciseField = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first,
      );
      // The dropdown exposes every source row, not only workout-tracked exercises.
      final dropdown = find.descendant(
        of: find.byWidget(exerciseField),
        matching: find.byType(DropdownButton<String>),
      );
      expect(
        tester.widget<DropdownButton<String>>(dropdown).items,
        hasLength(exercises.length),
      );
      final metricField = find.byType(DropdownButtonFormField<FitnessMetric>);
      await tester.ensureVisible(metricField);
      await tester.tap(metricField);
      await tester.pumpAndSettle();
      expect(find.text('Czas (s)'), findsWidgets);
      expect(find.text('Dystans (m)'), findsWidgets);
      await tester.tap(find.text('Dystans (m)').last);
      await tester.pumpAndSettle();
      expect(workflow.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );
  test('local date combines exact requested calendar components', () {
    final date = fitnessLocalDateTime(
      DateTime(2020, 2, 29),
      const TimeOfDay(hour: 12, minute: 42),
    )!;
    expect(date, DateTime(2020, 2, 29, 12, 42));
  });
  test(
    'Warsaw spring DST gap is rejected instead of normalized',
    () {
      expect(
        fitnessLocalDateTime(
          DateTime(2026, 3, 29),
          const TimeOfDay(hour: 2, minute: 30),
        ),
        isNull,
      );
    },
    skip: DateTime(2026, 3, 29, 12).timeZoneOffset != const Duration(hours: 2),
  );
  testWidgets('date and time picker preserves a backfilled local instant', (
    tester,
  ) async {
    final past = DateTime(2020, 1, 2, 12, 34);
    DateTime? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FitnessDateField(value: past, onChanged: (v) => chosen = v),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(chosen, past);
  });
  for (final width in [320.0, 430.0, 960.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'snapshot card $width $brightness at 200% text has no overflow or artificial score',
        (tester) async {
          tester.view.physicalSize = Size(width, 1800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: CustomTestCard(
                      protocol: protocol,
                      results: const [],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Jeszcze bez wyniku'), findsOneWidget);
          expect(find.textContaining('0/100'), findsNothing);
          expect(find.text(protocol.exerciseName), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('null history is unavailable, not empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CustomTestCard(protocol: protocol, results: null)),
    );
    expect(find.text('Historia niedostępna'), findsOneWidget);
    expect(find.text('Jeszcze bez wyniku'), findsNothing);
  });
  for (final state in ['empty', 'unavailable', 'loading', 'error']) {
    testWidgets('definitions $state has distinct safe UI', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessProtocolsProvider.overrideWith(
              (ref) => state == 'loading'
                  ? const Stream.empty()
                  : state == 'error'
                  ? Stream.error(StateError('secret database exception'))
                  : Stream.value(
                      FitnessProtocolsView(isAvailable: state == 'empty'),
                    ),
            ),
            customFitnessResultsProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            legacyTestResultsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: FitnessTestsSection()),
            ),
          ),
        ),
      );
      await tester.pump();
      if (state == 'loading') {
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      }
      if (state == 'empty') {
        expect(find.text('Utwórz własny test'), findsOneWidget);
        expect(find.textContaining('Nie masz jeszcze'), findsOneWidget);
      }
      if (state == 'unavailable') {
        expect(find.text(fitnessUnavailable), findsOneWidget);
        expect(find.text('Utwórz własny test'), findsNothing);
      }
      if (state == 'error') {
        expect(find.text('Ponów odczyt'), findsOneWidget);
        expect(find.textContaining('secret'), findsNothing);
      }
    });
  }
  testWidgets(
    'legacy form keeps opening lease, blocks double save and stale retry',
    (tester) async {
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final workflow = PendingWorkflow(await fixture.repo.captureLease());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fitnessTestsWorkflowProvider.overrideWithValue(workflow)],
          child: const MaterialApp(home: RunTestPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plank (czas)'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '120');
      final save = find.text('Zapisz wynik');
      await tester.scrollUntilVisible(
        save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(workflow.captures, 1);
      expect(workflow.saves, 1);
      expect(workflow.date!.isAfter(DateTime.now()), isFalse);
      workflow.pending.completeError(StateError('account changed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Zamknij formularz'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(workflow.captures, 1);
    },
  );
}
