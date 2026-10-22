import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercise_variants_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/workout/providers/session_recovery_provider.dart';
import 'catalog_filter_test.dart' show exercise;

const alternatives = ExerciseCatalogMetadata(
  exercises: {
    'cw009': ExerciseCatalogEntry(
      tracking: 'reps',
      unilateral: false,
      equipmentSets: [
        ['Masa własna', 'Ławeczka'],
        ['Masa własna', 'Step'],
        ['Masa własna', 'Krzesło'],
      ],
    ),
  },
);
const completeOptions =
    'Masa własna + Ławeczka lub Masa własna + Step lub Masa własna + Krzesło';

Future<ProviderContainer> mountDetail(
  WidgetTester tester,
  Future<ExerciseCatalogMetadata> Function() load,
) async {
  final container = ProviderContainer(
    overrides: [
      allExercisesProvider.overrideWith(
        (ref) => Stream.value([
          exercise('cw009').copyWith(sprzet: ['Masa własna', 'Ławeczka']),
        ]),
      ),
      exerciseCatalogMetadataProvider.overrideWith((ref) => load()),
      filterPresetsAccountProvider.overrideWith((ref) => Stream.value(null)),
      exerciseVariantsProvider('cw009').overrideWith((ref) => Stream.value([])),
      sessionRecoveryProvider.overrideWith((ref) {
        final authority = ref.read(cachedAuthWriteAuthorityProvider);
        return Stream.value(
          SessionRecovery(
            authority.state?.accountId,
            authority.epoch,
            const [],
          ),
        );
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ExerciseDetailPage(exerciseId: 'cw009')),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.drag(find.byType(ListView).first, const Offset(0, -450));
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

void main() {
  testWidgets('detail displays OR of complete AND equipment sets', (
    tester,
  ) async {
    await mountDetail(tester, () async => alternatives);
    await tester.pumpAndSettle();
    expect(find.text(completeOptions), findsOneWidget);
    expect(find.text('Masa własna, Ławeczka, Step, Krzesło'), findsNothing);
  });

  testWidgets('absent equipment metadata explicitly shows canonical fallback', (
    tester,
  ) async {
    await mountDetail(tester, () async => const ExerciseCatalogMetadata());
    await tester.pumpAndSettle();
    expect(find.text('Sprzęt (dane podstawowe)'), findsOneWidget);
    expect(find.text('Masa własna, Ławeczka'), findsOneWidget);
    expect(find.text(completeOptions), findsNothing);
  });

  testWidgets('refresh loading and error never present stale alternatives', (
    tester,
  ) async {
    var next = Future.value(alternatives);
    final container = await mountDetail(tester, () => next);
    await tester.pumpAndSettle();
    expect(find.text(completeOptions), findsOneWidget);
    final pending = Completer<ExerciseCatalogMetadata>();
    next = pending.future;
    container.invalidate(exerciseCatalogMetadataProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(exerciseCatalogMetadataProvider).isLoading, isTrue);
    expect(
      container.read(exerciseCatalogMetadataProvider).valueOrNull,
      same(alternatives),
    );
    expect(find.text(completeOptions), findsNothing);
    expect(find.text('Sprzęt (dane podstawowe)'), findsOneWidget);
    expect(find.text('Masa własna, Ławeczka'), findsOneWidget);
    pending.completeError(StateError('metadata unavailable'));
    await tester.pumpAndSettle();
    expect(container.read(exerciseCatalogMetadataProvider).hasError, isTrue);
    expect(
      container.read(exerciseCatalogMetadataProvider).valueOrNull,
      same(alternatives),
    );
    expect(find.text(completeOptions), findsNothing);
    expect(find.text('Sprzęt (dane podstawowe)'), findsOneWidget);
    expect(find.text('Masa własna, Ławeczka'), findsOneWidget);
  });
}
