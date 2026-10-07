import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/widgets/weight_line_chart.dart';
import 'package:fitbirek_training/core/utils/warsaw_time.dart';
import 'package:fitbirek_training/features/health/data/health_repository.dart';
import 'package:fitbirek_training/core/utils/formatters.dart';
import 'package:fitbirek_training/features/progress/presentation/pages/progress_page.dart';
import 'health_repository_test.dart' show seedSample;

void main() {
  test(
    'chart/history presentation date uses Warsaw midnight, sorting retains the instant',
    () async {
      await initializeDateFormatting('pl_PL');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final instant = DateTime.utc(2026, 9, 10, 22, 30);
      final sample = await seedSample(
        db,
        kind: 'weight',
        day: '2026-09-11',
        measuredAt: instant,
        value: 80,
      );
      final point = HealthRepository.mergeWeights([], [sample]).single;
      expect(point.date.toUtc(), instant);
      // WeightLineChart axis/tooltip and ProgressPage history use this getter.
      expect(Formatters.date(point.data), '11.09.2026');
      expect(Formatters.dayMonth(point.data), '11 września');
    },
  );
  test('Warsaw day and freshness cross midnight and both DST transitions', () {
    expect(warsawDayKey(DateTime.utc(2026, 9, 10, 23)), '2026-09-11');
    expect(formatWarsaw(DateTime.utc(2026, 3, 29, 1, 30)), '29.03.2026 03:30');
    expect(formatWarsaw(DateTime.utc(2026, 10, 25, 1, 30)), '25.10.2026 02:30');
  });
  testWidgets(
    'chart merges sources; deleting import keeps manual measurement unchanged',
    (tester) async {
      await initializeDateFormatting('pl_PL');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.measurements)
          .insert(
            MeasurementsCompanion.insert(
              wagaKg: 82,
              data: Value(DateTime.utc(2026, 9, 9)),
            ),
          );
      final manualBefore = await db.select(db.measurements).getSingle();
      await seedSample(
        db,
        kind: 'weight',
        day: '2026-09-10',
        measuredAt: DateTime.utc(2026, 9, 10),
        value: 80.5,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ProgressPage()),
        ),
      );
      await tester.pumpAndSettle();
      final chart = tester.widget<WeightLineChart>(
        find.byType(WeightLineChart),
      );
      expect(chart.measurements.map((s) => s.kg), [82, 80.5]);
      expect(chart.measurements.last.source, 'Apple Zdrowie');
      await tester.scrollUntilVisible(
        find.byTooltip('Usuń importowaną próbkę'),
        300,
      );
      await tester.ensureVisible(find.byTooltip('Usuń importowaną próbkę'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pomiar ręczny'), findsWidgets);
      await tester.tap(find.byTooltip('Usuń importowaną próbkę'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      expect(await db.select(db.measurements).getSingle(), manualBefore);
      expect(
        (await db.syncDao.pendingOperations()).single.entityType,
        SyncEntityType.healthSample,
      );
      expect((await db.syncDao.pendingOperations()).single.deleted, isTrue);
      expect(
        (await db.select(db.healthSamples).getSingle()).deletedAtUtc,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
