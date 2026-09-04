import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../providers/exercises_providers.dart';
import '../../../workout/providers/workout_providers.dart';

/// Szczegóły ćwiczenia: wskazówki, błędy, progresja/regresja.
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExercises = ref.watch(allExercisesProvider);

    return allExercises.when(
      data: (list) {
        final ex = list.where((e) => e.id == exerciseId).firstOrNull;
        if (ex == null) {
          return const Scaffold(body: Center(child: Text('Ćwiczenie nie znalezione')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(ex.nazwaPl),
            actions: [
              IconButton(
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(spacing: 8, children: [
                  Chip(label: Text(ex.partiaGlowna)),
                  Chip(label: Text(ex.poziom)),
                  Chip(label: Text(ex.typ)),
                ]),
                const SizedBox(height: 16),
                _section('Seria x powtórzenia', ex.seriexPowtorzenia),
                _section('Tempo', ex.tempo),
                _section('Sprzęt', ex.sprzet.join(', ')),
                _sectionList('Kluczowe wskazówki', ex.kluczoweWskazowki),
                _sectionList('Częste błędy', ex.czesteBledy),
                _section('Progresja', ex.progresja),
                _section('Regresja', ex.regresja),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Rozpocznij trening z tym ćwiczeniem',
                  icon: Icons.play_arrow,
                  onPressed: () async {
                    final notifier = ref.read(activeWorkoutProvider.notifier);
                    if (!ref.read(activeWorkoutProvider).isActive) {
                      await notifier.startSession();
                    }
                    notifier.addExercise(ex);
                    if (context.mounted) context.go('/workout/session');
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Błąd: $e'))),
    );
  }

  Widget _section(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: FitBirekColors.accent)),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: FitBirekColors.accent)),
          const SizedBox(height: 6),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(i)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
