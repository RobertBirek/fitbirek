// Karta „Dziś” dla Apple Zdrowie: brak danych to myślnik, nie zero; świeżość
// pokazuje czas importu w Europe/Warsaw po konwersji z UTC.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart'
    show HealthSampleData;
import 'package:fitbirek_training/features/health/presentation/widgets/health_today_card.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/health/data/health_integration_api.dart';

class _StatusApi implements HealthIntegrationApi {
  int calls = 0;
  bool offline = false;
  @override
  Future<HealthIntegrationStatus> getStatus() async {
    calls++;
    if (offline) throw const HealthIntegrationException();
    return HealthIntegrationStatus(
      enabled: true,
      lastImportAt: DateTime.utc(2026, 9, 11, 12),
    );
  }

  @override
  Future<HealthIntegrationToken> generateToken() => throw UnimplementedError();
  @override
  Future<HealthIntegrationStatus> revoke() => throw UnimplementedError();
}

HealthSampleData weight(
  double value,
  DateTime measuredAt,
  DateTime importedAt,
) {
  return HealthSampleData(
    id: 1,
    syncId: 'w1',
    syncVersion: 1,
    updatedAtUtc: importedAt,
    deletedAtUtc: null,
    kind: 'weight',
    day: '2026-09-10',
    measuredAt: measuredAt,
    value: value,
    source: 'Apple Zdrowie',
    method: 'health_sample',
    importedAt: importedAt,
  );
}

HealthSampleData steps(int value, String day, DateTime importedAt) {
  return HealthSampleData(
    id: 2,
    syncId: 's1',
    syncVersion: 1,
    updatedAtUtc: importedAt,
    deletedAtUtc: null,
    kind: 'steps',
    day: day,
    measuredAt: null,
    value: value.toDouble(),
    source: 'Apple Zdrowie',
    method: 'manual_verified_total',
    importedAt: importedAt,
  );
}

Widget _scaffold({
  HealthSampleData? latestWeight,
  HealthSampleData? todaySteps,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: HealthTodayCard(
          latestWeight: latestWeight,
          stepsOfDay: todaySteps == null ? const [] : [todaySteps],
          lastImportedAt: latestWeight?.importedAt ?? todaySteps?.importedAt,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'server successful replay freshness, offline local fallback, no timer HTTP or signed-out HTTP',
    (tester) async {
      final api = _StatusApi();
      final account = StateProvider<String?>((ref) => 'account');
      final container = ProviderContainer(
        overrides: [
          healthAccountProvider.overrideWith((ref) => ref.watch(account)),
          healthIntegrationApiProvider.overrideWithValue(api),
          healthSamplesProvider.overrideWith(
            (ref) => Stream.value([
              weight(
                80.5,
                DateTime.utc(2026, 9, 10, 6),
                DateTime.utc(2026, 9, 10, 8),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HealthTodaySection())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ostatni udany import: 11.09.2026 14:00'),
        findsOneWidget,
      );
      final calls = api.calls;
      await tester.pump(const Duration(minutes: 2));
      expect(api.calls, calls);
      api.offline = true;
      await tester.tap(find.byTooltip('Odśwież status importu'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('ostatnie lokalne dane: 10.09.2026 10:00'),
        findsOneWidget,
      );
      expect(find.textContaining('Ostatni udany import:'), findsNothing);
      container.read(account.notifier).state = null;
      await tester.pumpAndSettle();
      final signedOutCalls = api.calls;
      await tester.tap(find.byTooltip('Odśwież status importu'));
      await tester.pumpAndSettle();
      expect(api.calls, signedOutCalls);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('absent values render as missing, never zero', (tester) async {
    await tester.pumpWidget(_scaffold());

    expect(find.textContaining('—'), findsWidgets);
    expect(find.textContaining('0 kg'), findsNothing);
    expect(find.textContaining('0 '), findsNothing);
  });

  testWidgets('formats weight with the visible source label', (tester) async {
    final importedAt = DateTime.utc(2026, 9, 10, 8, 15);
    await tester.pumpWidget(
      _scaffold(
        latestWeight: weight(80.5, DateTime.utc(2026, 9, 10, 6), importedAt),
      ),
    );

    expect(find.textContaining('80.5 kg'), findsOneWidget);
    expect(find.textContaining('Apple Zdrowie'), findsWidgets);
  });

  testWidgets('renders steps and import freshness converted to Europe/Warsaw', (
    tester,
  ) async {
    final importedAt = DateTime.utc(2026, 9, 10, 12, 30);
    await tester.pumpWidget(
      _scaffold(todaySteps: steps(7500, '2026-09-10', importedAt)),
    );

    expect(find.textContaining('7500'), findsOneWidget);
    // UTC 12:30 → Warsaw 14:30 (CEST)
    expect(find.textContaining('14:30'), findsOneWidget);
  });
}
