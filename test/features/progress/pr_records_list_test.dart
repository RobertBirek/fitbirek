import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import 'package:fitbirek_training/features/progress/prs/providers/prs_providers.dart';
import 'package:fitbirek_training/features/progress/prs/presentation/pr_records_list.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets(
    'best and history show all four scopes, including unclassified records',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PrsRepository(db);
      final rows = await tester.runAsync(() async {
        for (final side in [null, 'left', 'right', 'both']) {
          for (final weight in [20.0, 30.0]) {
            await repo.savePr(
              exerciseId: 'x',
              exerciseNamePl: 'Test',
              weightKg: weight,
              reps: 5,
              side: side,
            );
          }
        }
        return repo.watchAll().first;
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPrsProvider.overrideWith((ref) => Stream.value(rows!)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: PrRecordsList())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNWidgets(4));
      for (final label in ['Bez oznaczenia', 'Lewa', 'Prawa', 'Obie']) {
        expect(find.text('Test • $label'), findsOneWidget);
      }
      await tester.tap(find.text('Test • Bez oznaczenia'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('20.0 kg × 5 • Bez oznaczenia'),
        findsOneWidget,
      );
      expect(
        find.textContaining('30.0 kg × 5 • Bez oznaczenia'),
        findsOneWidget,
      );
    },
  );
}
