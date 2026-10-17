import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/exercise.dart';
import '../../providers/exercise_variants_providers.dart';
import '../../providers/filter_presets_providers.dart';
import '../../providers/exercises_providers.dart';

String variantDescription(Map<String, dynamic> e) => [
  if (e['loadKg'] != null) '${e['loadKg']} kg (domyślne)',
  if (e['tempo'] != null) 'Tempo: ${e['tempo']}',
  if (e['pauseSeconds'] != null) 'Pauza: ${e['pauseSeconds']} s',
  if (e['rangeOfMotion'] != null) 'Zakres: ${e['rangeOfMotion']}',
  if (e['cue'] != null) 'Wskazówka: ${e['cue']}',
].join(' • ');

class OwnVariants extends ConsumerWidget {
  const OwnVariants({super.key, required this.exercise});
  final Exercise exercise;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(filterPresetsAccountProvider).valueOrNull;
    final variants = ref.watch(exerciseVariantsProvider(exercise.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moje warianty', style: Theme.of(context).textTheme.titleLarge),
        const Text(
          'Parametry definiują osobną historię. Zmiana protokołu wymaga nowego wariantu, nie zmienia wcześniejszych serii.',
        ),
        if (account == null)
          const Text('Zaloguj się lub odblokuj dostęp offline.'),
        variants.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          data: (items) => Column(
            children: [
              for (final e
                  in account == null ? <Map<String, dynamic>>[] : items)
                ListTile(
                  title: Text(e['name'] as String),
                  subtitle: Text(variantDescription(e)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Usuń wariant',
                    onPressed: account == null
                        ? null
                        : () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Usunąć wariant?'),
                                content: const Text(
                                  'Historia i nazwy zapisanych serii pozostaną dostępne.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Anuluj'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Usuń'),
                                  ),
                                ],
                              ),
                            );
                            if (yes != true ||
                                !context.mounted ||
                                ref
                                        .read(filterPresetsAccountProvider)
                                        .valueOrNull !=
                                    account) {
                              return;
                            }
                            try {
                              await ref
                                  .read(exerciseVariantsRepositoryProvider)
                                  .delete(
                                    account,
                                    e['id'] as String,
                                    isCurrent: () =>
                                        context.mounted &&
                                        ref
                                                .read(
                                                  filterPresetsAccountProvider,
                                                )
                                                .valueOrNull ==
                                            account,
                                  );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$error')),
                                );
                              }
                            }
                          },
                  ),
                ),
            ],
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
        ),
        TextButton.icon(
          onPressed: account == null
              ? null
              : () => _create(context, ref, account),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj wariant'),
        ),
      ],
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    String account,
  ) async {
    final fields = {
      for (final k in ['name', 'load', 'tempo', 'pause', 'range', 'cue'])
        k: TextEditingController(),
    };
    final weighted =
        exercise.sprzet.any(const {'Hantle', 'Sandbag'}.contains) &&
        ref
                .read(exerciseCatalogMetadataProvider)
                .valueOrNull
                ?.entryFor(exercise.id)
                ?.tracking ==
            'reps';
    final epoch = ref.read(userCollectionsRepositoryProvider).authority?.epoch;
    bool current() =>
        context.mounted &&
        ref.read(filterPresetsAccountProvider).valueOrNull == account &&
        ref.read(userCollectionsRepositoryProvider).authority?.epoch == epoch;
    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => Consumer(
        builder: (c, dialogRef, _) {
          final visible =
              dialogRef.watch(filterPresetsAccountProvider).valueOrNull ==
                  account &&
              current();
          return AlertDialog(
            title: const Text('Nowy wariant'),
            content: visible
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in <String, String>{
                          'name': 'Nazwa',
                          if (weighted)
                            'load': 'Domyślne obciążenie kg (opcjonalne)',
                          'tempo': 'Tempo (opcjonalne)',
                          'pause': 'Pauza s (opcjonalna)',
                          'range': 'Zakres ruchu (opcjonalny)',
                          'cue': 'Wskazówka (opcjonalna)',
                        }.entries)
                          TextField(
                            controller: fields[item.key],
                            maxLength: item.key == 'name' ? 80 : 1000,
                            decoration: InputDecoration(labelText: item.value),
                          ),
                      ],
                    ),
                  )
                : const Text('Konto zostało zmienione.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: visible ? () => Navigator.pop(c, true) : null,
                child: const Text('Utwórz'),
              ),
            ],
          );
        },
      ),
    );
    try {
      if (saved != true || !current()) return;
      String? optional(String key) =>
          fields[key]!.text.trim().isEmpty ? null : fields[key]!.text.trim();
      final load = optional('load'), pause = optional('pause');
      final kg = load == null
          ? null
          : double.tryParse(load.replaceAll(',', '.'));
      final seconds = pause == null ? null : int.tryParse(pause);
      if ((load != null && kg == null) || (pause != null && seconds == null)) {
        throw ArgumentError('Nieprawidłowa liczba.');
      }
      await ref
          .read(exerciseVariantsRepositoryProvider)
          .create(
            account,
            exercise.id,
            fields['name']!.text,
            loadKg: kg,
            tempo: optional('tempo'),
            pauseSeconds: seconds,
            rangeOfMotion: optional('range'),
            cue: optional('cue'),
            isCurrent: current,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      for (final f in fields.values) {
        f.dispose();
      }
    }
  }
}
