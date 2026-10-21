import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/content_layout.dart';
import '../../domain/fitness_protocol.dart';
import '../../providers/tests_providers.dart';
import '../fitness_test_widgets.dart';

class ProtocolDetailPage extends ConsumerStatefulWidget {
  const ProtocolDetailPage({super.key, required this.protocolId});
  final String protocolId;
  @override
  ConsumerState<ProtocolDetailPage> createState() => _ProtocolDetailPageState();
}

class _ProtocolDetailPageState extends ConsumerState<ProtocolDetailPage> {
  bool _busy = false;
  String? _error;
  Future<void> _archive() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final workflow = ref.read(fitnessTestsWorkflowProvider);
      final lease = await workflow.captureLease(protocolId: widget.protocolId);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Archiwizować test?'),
          content: const Text(
            'Zasady i historia pozostaną dostępne. Nie dodasz nowych prób do tej wersji.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Archiwizuj'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) await workflow.archiveProtocol(lease);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Nie można archiwizować testu. Dostęp lub zasady mogły się zmienić. Otwórz ekran ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final definitions = ref.watch(fitnessProtocolsProvider);
    final history = ref.watch(customFitnessResultsProvider);
    final definitionsData = definitions.isLoading || definitions.hasError
        ? null
        : definitions.valueOrNull;
    final historyRows = history.isLoading || history.hasError
        ? null
        : history.valueOrNull;
    final definition = definitionsData?.protocols
        .where((p) => p.id == widget.protocolId)
        .firstOrNull;
    final p =
        definition ??
        historyRows
            ?.where((r) => r.protocol?.id == widget.protocolId)
            .firstOrNull
            ?.protocol;
    return Scaffold(
      appBar: fitnessAppBar(context, 'Zasady i historia'),
      body: SafeArea(
        child: ContentLayout(
          child: ListView(
            padding: ContentLayout.pagePadding(context),
            children: [
              if (p == null) ...[
                if (definitions.isLoading || history.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  const Text(
                    'Nie można odczytać tego testu. Sprawdź dostęp do konta lub wróć do listy testów.',
                  ),
                TextButton(
                  onPressed: () {
                    ref.invalidate(fitnessProtocolsProvider);
                    ref.invalidate(customFitnessResultsProvider);
                  },
                  child: const Text('Ponów odczyt'),
                ),
              ] else ...[
                CustomTestCard(protocol: p, results: historyRows),
                if (p.instructions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(p.instructions),
                  ),
                if (p.variantSnapshot != null) ...[
                  const Text('Zapisane warunki wariantu'),
                  for (final key in [
                    'tempo',
                    'pauseSeconds',
                    'loadKg',
                    'rangeOfMotion',
                    'cue',
                  ])
                    if (p.variantSnapshot![key] != null)
                      Text('${_variantLabel(key)}: ${p.variantSnapshot![key]}'),
                ],
                Text(
                  'Wersja zasad: ${p.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (p.supersedesId != null)
                  TextButton(
                    onPressed: () =>
                        context.push('/progress/tests/${p.supersedesId}'),
                    child: const Text('Poprzednie zasady'),
                  ),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/exercises/${Uri.encodeComponent(p.exerciseId)}',
                  ),
                  child: const Text('Pełna karta ćwiczenia'),
                ),
                if (definition != null &&
                    definitionsData?.isAvailable == true &&
                    !definition.isArchived) ...[
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => context.push(
                            '/progress/run-test?protocolId=${p.id}',
                          ),
                    child: const Text('Dodaj wynik'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => context.push('/progress/tests/${p.id}/edit'),
                    child: const Text('Utwórz nową wersję zasad'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _archive,
                    child: Text(_busy ? 'Archiwizowanie…' : 'Archiwizuj test'),
                  ),
                ],
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
                const SizedBox(height: 24),
                Text(
                  'Historia tej rodziny testu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Inna wersja lub inne zasady nie wchodzą do porównania.',
                ),
                history.when(
                  skipLoadingOnReload: false,
                  skipLoadingOnRefresh: false,
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text(
                    'Nie udało się wczytać historii. Wróć do testów i ponów odczyt.',
                  ),
                  data: (rows) {
                    if (rows == null) return const Text('Historia niedostępna');
                    final family = rows
                        .where(
                          (r) =>
                              r.protocol?.familyId == p.familyId ||
                              r.protocol?.id == p.id,
                        )
                        .toList();
                    if (family.isEmpty) {
                      return const Text(
                        'Brak zapisanych prób. Dodaj pierwszy wynik.',
                      );
                    }
                    return Column(
                      children: [
                        for (final r in family) _historyRow(context, p, r),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow(
    BuildContext context,
    FitnessProtocol p,
    CustomFitnessResult r,
  ) {
    final compatible =
        r.isAvailable &&
        r.protocol != null &&
        p.hasSameRevisionRules(r.protocol!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${fitnessNumber(r.value)} ${r.protocol?.metric.unitLabel ?? ''} • ${fitnessDate(r.performedAt)}',
            ),
            Text(
              compatible
                  ? 'Identyczne zasady • wynik porównywalny'
                  : !r.isAvailable
                  ? 'Nie można odczytać wyniku — wyłączony z porównania.'
                  : r.protocol?.id == p.id
                  ? 'Rozbieżny zapis zasad — wyłączony z porównania.'
                  : 'Inna wersja zasad — wyłączona z porównania.',
            ),
            if (!compatible && r.protocol != null)
              ExpansionTile(
                title: const Text('Zasady zapisane przy tej próbie'),
                children: [
                  Text(r.protocol!.name),
                  Text(r.protocol!.exerciseName),
                  Text(fitnessConditions(r.protocol!)),
                  Text(r.protocol!.instructions),
                  if (r.protocol!.variantSnapshot != null)
                    for (final key in [
                      'tempo',
                      'pauseSeconds',
                      'loadKg',
                      'rangeOfMotion',
                      'cue',
                    ])
                      if (r.protocol!.variantSnapshot![key] != null)
                        Text(
                          '${_variantLabel(key)}: ${r.protocol!.variantSnapshot![key]}',
                        ),
                ],
              ),
            if (!compatible && r.protocol != null && r.protocol!.id != p.id)
              TextButton(
                onPressed: () =>
                    context.push('/progress/tests/${r.protocol!.id}'),
                child: const Text('Zobacz zasady tej próby'),
              ),
          ],
        ),
      ),
    );
  }
}

String _variantLabel(String key) => switch (key) {
  'tempo' => 'Tempo',
  'pauseSeconds' => 'Pauza (s)',
  'loadKg' => 'Domyślne kg wariantu',
  'rangeOfMotion' => 'Zakres ruchu',
  _ => 'Wskazówka',
};
