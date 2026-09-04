import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/exercises_providers.dart';

/// Ekran "Baza" - przeglądarka ćwiczeń z wyszukiwarką, filtrami i sortowaniem.
class ExercisesListPage extends ConsumerWidget {
  const ExercisesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExercisesProvider);
    final filters = ref.watch(exerciseFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baza ćwiczeń'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filters.activeCount > 0,
              label: Text('${filters.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Szukaj ćwiczenia...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref
                  .read(exerciseFiltersProvider.notifier)
                  .update((f) => f.copyWith(query: v)),
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Brak wyników',
                    subtitle: 'Zmień filtry lub wyszukiwaną frazę',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            ex.nazwaPl,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${ex.partiaGlowna} • ${ex.poziom}'),
                          trailing: IconButton(
                            icon: Icon(
                              ex.ulubione ? Icons.star : Icons.star_border,
                              color: ex.ulubione
                                  ? FitBirekColors.accent
                                  : Colors.grey,
                            ),
                            onPressed: () => ref
                                .read(exercisesRepositoryProvider)
                                .toggleFavorite(ex.id, !ex.ulubione),
                          ),
                          onTap: () => context.push('/exercises/${ex.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  static const partie = [
    'Klatka',
    'Plecy',
    'Barki',
    'Biceps',
    'Triceps',
    'Nogi',
    'Pośladki',
    'Brzuch',
    'Cardio',
    'Mobilność',
  ];
  static const sprzet = [
    'Masa własna',
    'Hantle',
    'Ławeczka',
    'Drążek',
    'Gumy oporowe',
    'Bieżnia',
    'Skakanka',
  ];
  static const poziomy = ['Początkujący', 'Średni', 'Zaawansowany'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(exerciseFiltersProvider);
    final notifier = ref.read(exerciseFiltersProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtry', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('Partia ciała'),
              Wrap(
                spacing: 8,
                children: partie.map((p) {
                  final sel = filters.partie.contains(p);
                  return FilterChip(
                    label: Text(p),
                    selected: sel,
                    onSelected: (v) {
                      final s = Set<String>.from(filters.partie);
                      v ? s.add(p) : s.remove(p);
                      notifier.update((f) => f.copyWith(partie: s));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Sprzęt'),
              Wrap(
                spacing: 8,
                children: sprzet.map((p) {
                  final sel = filters.sprzet.contains(p);
                  return FilterChip(
                    label: Text(p),
                    selected: sel,
                    onSelected: (v) {
                      final s = Set<String>.from(filters.sprzet);
                      v ? s.add(p) : s.remove(p);
                      notifier.update((f) => f.copyWith(sprzet: s));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Poziom'),
              Wrap(
                spacing: 8,
                children: poziomy.map((p) {
                  final sel = filters.poziomy.contains(p);
                  return FilterChip(
                    label: Text(p),
                    selected: sel,
                    onSelected: (v) {
                      final s = Set<String>.from(filters.poziomy);
                      v ? s.add(p) : s.remove(p);
                      notifier.update((f) => f.copyWith(poziomy: s));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    notifier.update((f) => const ExerciseFilters()),
                child: const Text('Wyczyść filtry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
