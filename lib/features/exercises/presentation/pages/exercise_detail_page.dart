import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/content_layout.dart';
import '../../../../core/widgets/recovery_message.dart';
import '../exercise_illustrations.dart';
import '../../providers/exercises_providers.dart';
import '../../../workout/presentation/widgets/start_workout_button.dart';
import '../widgets/own_variants.dart';

/// Szczegóły ćwiczenia: wskazówki, błędy, progresja/regresja.
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExercises = ref.watch(allExercisesProvider);
    final catalog = ref.watch(exerciseCatalogMetadataProvider);
    Widget unavailable(String message) => Scaffold(
      appBar: AppBar(title: const Text('Szczegóły ćwiczenia')),
      body: RecoveryMessage(
        message: message,
        onRetry: () => ref.invalidate(allExercisesProvider),
        backLabel: 'Wróć do bazy ćwiczeń',
        backLocation: '/exercises',
      ),
    );

    return allExercises.when(
      data: (list) {
        final ex = list.where((e) => e.id == exerciseId).firstOrNull;
        if (ex == null) {
          return unavailable(
            'Ćwiczenie nie znalezione. Wróć do bazy lub ponów odczyt.',
          );
        }
        final illustrationAsset = exerciseIllustrationAsset(ex.id);
        final metadata = catalog.valueOrNull;
        final entry = metadata?.entryFor(ex.id);
        // Refresh/error may retain an old value: only current metadata can
        // describe alternative complete equipment sets.
        final equipmentSets = catalog.isLoading || catalog.hasError
            ? null
            : entry?.equipmentSets;
        return Scaffold(
          appBar: AppBar(
            title: Text(ex.nazwaPl),
            actions: [
              IconButton(
                tooltip: ex.ulubione
                    ? 'Usuń z ulubionych'
                    : 'Dodaj do ulubionych',
                isSelected: ex.ulubione,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(
                  ex.ulubione ? Icons.star : Icons.star_border,
                  color: ex.ulubione ? FitBirekColors.accent : null,
                ),
                onPressed: () => ref
                    .read(exercisesRepositoryProvider)
                    .toggleFavorite(ex.id, !ex.ulubione),
              ),
            ],
          ),
          body: SafeArea(
            child: ContentLayout(
              child: ListView(
                padding: ContentLayout.pagePadding(context),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(ex.partiaGlowna)),
                      Chip(label: Text(ex.poziom)),
                      Chip(label: Text(ex.typ)),
                    ],
                  ),
                  if (illustrationAsset != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 360,
                          maxHeight: 360,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            illustrationAsset,
                            semanticLabel: 'Ilustracja ćwiczenia ${ex.nazwaPl}',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (awaitingIllustrationExerciseIds.contains(ex.id)) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Ilustracja w przygotowaniu — skorzystaj z instrukcji poniżej.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (catalog.isLoading) const LinearProgressIndicator(),
                  if (catalog.hasError)
                    const Text(
                      'Klasyfikacja niedostępna — pokazano dane podstawowe.',
                    ),
                  if (entry != null) ...[
                    _section(
                      'Mięśnie główne',
                      entry.primaryMuscles
                          .map(metadata!.muscleLabel)
                          .join(', '),
                    ),
                    _section(
                      'Mięśnie wspierające',
                      entry.secondaryMuscles
                          .map(metadata.muscleLabel)
                          .join(', '),
                    ),
                  ] else ...[
                    _section(
                      'Partia główna (dane podstawowe)',
                      ex.partiaGlowna,
                    ),
                    _section(
                      'Partie wspierające (dane podstawowe)',
                      ex.partieWspierajace.join(', '),
                    ),
                  ],
                  _section('Seria x powtórzenia', ex.seriexPowtorzenia),
                  _section('Tempo', ex.tempo),
                  _section(
                    equipmentSets == null
                        ? 'Sprzęt (dane podstawowe)'
                        : 'Sprzęt (alternatywne zestawy)',
                    equipmentSets == null
                        ? ex.sprzet.join(', ')
                        : equipmentSets
                              .map((option) => option.join(' + '))
                              .join(' lub '),
                  ),
                  _sectionList('Kluczowe wskazówki', ex.kluczoweWskazowki),
                  _sectionList('Częste błędy', ex.czesteBledy),
                  _section('Progresja', ex.progresja),
                  _section('Regresja', ex.regresja),
                  OwnVariants(exercise: ex),
                  const SizedBox(height: 20),
                  StartWorkoutButton(exercise: ex),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => context.push(
                      Uri(
                        path: '/progress/run-test',
                        queryParameters: {'exerciseId': ex.id},
                      ).toString(),
                    ),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Test sprawnościowy'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Szczegóły ćwiczenia')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => unavailable('Nie udało się wczytać ćwiczenia.'),
    );
  }

  Widget _section(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: FitBirekColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _sectionList(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: FitBirekColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(i)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
