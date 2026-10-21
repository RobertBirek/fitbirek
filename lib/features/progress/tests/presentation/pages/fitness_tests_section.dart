import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/test_score_chart.dart';
import '../../providers/tests_providers.dart';
import '../fitness_test_widgets.dart';

class FitnessTestsSection extends ConsumerWidget {
  const FitnessTestsSection({super.key, this.exerciseId});
  final String? exerciseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocols = ref.watch(fitnessProtocolsProvider);
    final results = ref.watch(customFitnessResultsProvider);
    final resultRows = results.isLoading || results.hasError
        ? null
        : results.valueOrNull;
    final legacy = ref.watch(legacyTestResultsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Twoje zasady. Twój punkt odniesienia.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'FitnessTestDisplay',
            fontFamilyFallback: const ['Inter'],
          ),
        ),
        const Text(
          'Powtórzenia, czas lub dystans — niezależnie od treningów i PR.',
        ),
        const SizedBox(height: 16),
        protocols.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Ładowanie testów',
            ),
          ),
          error: (_, __) => Column(
            children: [
              const Text('Nie udało się wczytać testów.'),
              TextButton(
                onPressed: () => ref.invalidate(fitnessProtocolsProvider),
                child: const Text('Ponów odczyt'),
              ),
            ],
          ),
          data: (view) {
            if (!view.isAvailable) return const Text(fitnessUnavailable);
            final active = view.active.where(
              (p) => exerciseId == null || p.exerciseId == exerciseId,
            );
            final archived = view.archived.where(
              (p) => exerciseId == null || p.exerciseId == exerciseId,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => context.push(
                    Uri(
                      path: '/progress/tests/new',
                      queryParameters: exerciseId == null
                          ? null
                          : {'exerciseId': exerciseId!},
                    ).toString(),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Utwórz własny test'),
                ),
                if (active.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nie masz jeszcze własnego testu. Wybierz dowolne ćwiczenie i określ, co chcesz mierzyć.',
                    ),
                  ),
                if (results.isLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Ładowanie historii',
                  ),
                if (results.hasError)
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(customFitnessResultsProvider),
                    child: const Text('Nie wczytano historii. Ponów odczyt'),
                  ),
                for (final p in active)
                  CustomTestCard(
                    protocol: p,
                    results: resultRows,
                    onTap: () => context.push('/progress/tests/${p.id}'),
                  ),
                if (archived.isNotEmpty)
                  ExpansionTile(
                    title: const Text('Archiwum testów'),
                    children: [
                      for (final p in archived)
                        CustomTestCard(
                          protocol: p,
                          results: resultRows,
                          onTap: () => context.push('/progress/tests/${p.id}'),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        // Results retain their snapshots even if their definition is unavailable.
        if (resultRows != null) ...[
          for (final _ in resultRows.where((r) => !r.isAvailable))
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Wynik niedostępny'),
              subtitle: Text(
                'Nie można odczytać zapisanych zasad. Dane zachowano.',
              ),
            ),
          for (final p in {
            for (final r in resultRows)
              if (r.isAvailable &&
                  r.protocol != null &&
                  (exerciseId == null ||
                      r.protocol!.exerciseId == exerciseId) &&
                  !(protocols.valueOrNull?.protocols ?? []).any(
                    (p) => p.id == r.protocol!.id,
                  ))
                r.protocol!.id: r.protocol!,
          }.values)
            CustomTestCard(
              protocol: p,
              results: resultRows,
              onTap: () => context.push('/progress/tests/${p.id}'),
            ),
        ],
        const SizedBox(height: 24),
        ExpansionTile(
          title: const Text('Dotychczasowe testy (11)'),
          subtitle: const Text('Starsze wyniki • protokół nie został zapisany'),
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/progress/run-test'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Dodaj dotychczasowy test'),
            ),
            legacy.when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () => const CircularProgressIndicator(),
              error: (_, __) =>
                  const Text('Nie udało się wczytać starszych wyników.'),
              data: (list) => list == null
                  ? const Text('Historia niedostępna')
                  : TestScoreChart(allResults: list),
            ),
          ],
        ),
      ],
    );
  }
}
