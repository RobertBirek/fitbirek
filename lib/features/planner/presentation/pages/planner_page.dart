import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/constants.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../onboarding/providers/user_profile_provider.dart';
import '../../domain/plan_generator.dart';
import '../../providers/planner_providers.dart';

/// Ekran "Generator planu treningowego" (funkcja Premium).
///
/// Na podstawie celu, poziomu, czasu i dostępnego sprzętu użytkownika
/// (z profilu) proponuje zbalansowany plan 4-6 ćwiczeń. Plan można
/// zapisać do historii.
class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  int _czasMinut = 45;
  String _poziom = 'Średni';
  List<Exercise>? _wygenerowanyPlan;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final exercisesAsync = ref.watch(allExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generator planu')),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Brak profilu',
                subtitle: 'Dokończ onboarding, aby wygenerować plan',
              );
            }
            return exercisesAsync.when(
              data: (allExercises) =>
                  _buildForm(context, profile, allExercises),
              loading: () => const ShimmerLoading(),
              error: (e, st) => Center(child: Text('Błąd bazy ćwiczeń: $e')),
            );
          },
          loading: () => const ShimmerLoading(),
          error: (e, st) => Center(child: Text('Błąd profilu: $e')),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    UserProfile profile,
    List<Exercise> allExercises,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parametry planu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('Cel: ${profile.cel.label}'),
                  Text('Sprzęt: ${profile.dostepnySprzet.join(", ")}'),
                  const SizedBox(height: 16),
                  const Text('Poziom'),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.poziomyOpcje.map((p) {
                      return ChoiceChip(
                        label: Text(p),
                        selected: _poziom == p,
                        onSelected: (_) => setState(() => _poziom = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Czas na trening: $_czasMinut min'),
                  Slider(
                    value: _czasMinut.toDouble(),
                    min: 20,
                    max: 90,
                    divisions: 14,
                    label: '$_czasMinut min',
                    onChanged: (v) => setState(() => _czasMinut = v.round()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Wygeneruj plan',
            icon: Icons.auto_awesome,
            onPressed: () {
              final plan = PlanGenerator.generate(
                wszystkieCwiczenia: allExercises,
                cel: profile.cel,
                poziom: _poziom,
                dostepnySprzet: profile.dostepnySprzet,
                czasMinut: _czasMinut,
              );
              setState(() => _wygenerowanyPlan = plan);
            },
          ),
          const SizedBox(height: 24),
          if (_wygenerowanyPlan != null) _buildResult(context, profile),
          const SizedBox(height: 24),
          _buildHistory(context),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, UserProfile profile) {
    final plan = _wygenerowanyPlan!;
    if (plan.isEmpty) {
      return const EmptyState(
        icon: Icons.error_outline,
        title: 'Nie udało się zbudować planu',
        subtitle:
            'Za mało ćwiczeń zgodnych z Twoim sprzętem i poziomem.\nDodaj więcej sprzętu w ustawieniach.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Twój plan (${plan.length} ćwiczeń)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...plan.map(
          (ex) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.fitness_center,
                color: FitBirekColors.accent,
              ),
              title: Text(ex.nazwaPl),
              subtitle: Text('${ex.partiaGlowna} • ${ex.seriexPowtorzenia}'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Zapisz plan',
          icon: Icons.save_outlined,
          outlined: true,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await ref
                .read(plannerRepositoryProvider)
                .savePlan(
                  nazwa:
                      'Plan ${profile.cel.label} • ${DateTime.now().day}.${DateTime.now().month}',
                  cwiczeniaIds: plan.map((e) => e.id).toList(),
                  cel: profile.cel.name,
                );
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Plan zapisany ✅')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHistory(BuildContext context) {
    final savedPlansAsync = ref.watch(savedPlansProvider);
    return savedPlansAsync.when(
      data: (plans) {
        if (plans.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zapisane plany',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...plans.map(
              (p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(p.nazwa),
                  subtitle: Text('${p.cwiczeniaIds.length} ćwiczeń'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(plannerRepositoryProvider).deletePlan(p.id),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
