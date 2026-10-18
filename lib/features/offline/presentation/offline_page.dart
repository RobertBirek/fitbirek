import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/offline_snapshot.dart';
import '../providers/offline_controller.dart';
import '../providers/offline_sync_provider.dart';

class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({super.key});
  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage>
    with WidgetsBindingObserver {
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref
          .read(offlineControllerProvider.notifier)
          .setActive(state == AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _confirm(OfflineSnapshot snapshot) async {
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przygotuj do pracy offline'),
        content: Text(
          'Pobrać cały pakiet: ${snapshot.sizeLabel} (${snapshot.totalBytes} bajtów), '
          '${snapshot.totalFiles} plików, wraz ze wszystkimi ilustracjami, fontami i zasobami aplikacji? '
          'Może to zużyć transfer i miejsce na urządzeniu. Poprawne pliki już w cache zostaną wykorzystane ponownie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nie teraz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pobierz cały pakiet'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (confirmed == true) {
      await ref.read(offlineControllerProvider.notifier).prepare(snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(offlineControllerProvider);
    final controller = ref.read(offlineControllerProvider.notifier);
    final snapshot = view.snapshot;
    final phase = snapshot.phase;
    final sync = ref.watch(offlineSyncProvider);
    final canPrepare =
        view.fresh &&
        !view.busy &&
        snapshot.hasSize &&
        !snapshot.requiresFreshStatus &&
        !snapshot.inFlight &&
        phase != OfflinePhase.ready &&
        phase != OfflinePhase.unsupported;
    // A previous ready response is never shown as verified during a new check.
    final title = !view.fresh && phase == OfflinePhase.ready
        ? 'Weryfikacja zasobów…'
        : switch (phase) {
            OfflinePhase.unsupported =>
              'Ta platforma nie obsługuje pakietu offline PWA',
            OfflinePhase.notReady => 'Zasoby nie są jeszcze gotowe offline',
            OfflinePhase.checking => 'Sprawdzanie zasobów…',
            OfflinePhase.downloading => 'Pobieranie zasobów…',
            OfflinePhase.ready => 'Zasoby gotowe offline',
            OfflinePhase.error => 'Nie udało się przygotować zasobów',
            OfflinePhase.cancelled => 'Pobieranie anulowane',
          };

    return Scaffold(
      appBar: AppBar(title: const Text('Tryb offline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Zasoby aplikacji',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(title, semanticsLabel: title),
          if (snapshot.hasSize) ...[
            const SizedBox(height: 8),
            Text(
              'Cały pakiet: ${snapshot.sizeLabel} (${snapshot.totalBytes} bajtów) · ${snapshot.totalFiles} plików',
            ),
            Text(
              'Zweryfikowano: ${snapshot.cachedFiles}/${snapshot.totalFiles} plików · '
              '${(snapshot.cachedBytes / 1048576).toStringAsFixed(2)} MiB',
            ),
          ] else if (phase != OfflinePhase.unsupported)
            const Text(
              'Rozmiar pakietu nie jest jeszcze znany. Sprawdź ponownie przed pobraniem.',
            ),
          if (view.busy || snapshot.inFlight)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(
                value:
                    !view.busy &&
                        phase == OfflinePhase.downloading &&
                        snapshot.hasSize
                    ? snapshot.cachedBytes / snapshot.totalBytes
                    : null,
                semanticsLabel: 'Postęp weryfikacji pakietu',
              ),
            ),
          if (snapshot.errorCode != null)
            Text(_errorExplanation(snapshot.errorCode!)),
          if (canPrepare)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(
                onPressed: _confirming ? null : () => _confirm(snapshot),
                child: Text(
                  phase == OfflinePhase.error || phase == OfflinePhase.cancelled
                      ? 'Ponów pobieranie'
                      : 'Przygotuj do pracy offline',
                ),
              ),
            ),
          if (snapshot.inFlight)
            TextButton(
              onPressed: controller.cancel,
              child: const Text('Anuluj pobieranie'),
            ),
          TextButton(
            onPressed: view.busy || _confirming ? null : controller.refresh,
            child: const Text('Sprawdź ponownie'),
          ),
          const Divider(height: 32),
          Text(
            'Dane treningowe i synchronizacja',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          sync.when(
            loading: () => const Text('Odczyt lokalnego stanu danych…'),
            error: (_, _) => const Text(
              'Nie można odczytać lokalnej kolejki. Stan danych nie jest potwierdzony.',
            ),
            data: (summary) => Text(
              !summary.available
                  ? 'Stan danych konta nie jest dostępny. Pierwsze logowanie wymaga internetu.'
                  : summary.pending > 0 || summary.conflicts > 0
                  ? 'Dane treningowe czekają na synchronizację: ${summary.pending} zmian. '
                        'Konflikty / rekordy wymagające sprawdzenia: ${summary.conflicts}. '
                        'Gotowość zasobów nie oznacza wysłania tych danych na serwer.'
                  : 'Lokalna kolejka jest pusta. Nie jest to potwierdzenie aktualności danych na serwerze.',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pakiet zasobów nie pobiera danych konta. Ekran tylko odczytuje lokalny stan synchronizacji; '
            'nie uruchamia logowania ani synchronizacji sieciowej. Pierwsze logowanie wymaga internetu. '
            'Na iOS system może usunąć pamięć witryny, również po przygotowaniu pakietu. '
            'Sprawdź zasoby przed wyjściem bez sieci. Nie gwarantujemy trwałości pamięci ani pobierania czy pracy w tle.',
          ),
        ],
      ),
    );
  }
}

String _errorExplanation(String code) => switch (code) {
  'packageChanged' =>
    'Pakiet zmienił się od wyrażenia zgody. Nie rozpoczęto pobierania nowego pakietu. '
        'Wybierz „Sprawdź ponownie”, sprawdź aktualny rozmiar i liczbę plików, a następnie potwierdź pobranie jeszcze raz.',
  'quota' =>
    'Brak miejsca lub limit pamięci przeglądarki. Zwolnij miejsce i ponów; nie usuwaj danych treningowych bez kopii.',
  'network' =>
    'Połączenie przerwano. Sprawdź internet i ponów pobieranie; poprawne części pakietu mogą zostać użyte ponownie.',
  'integrity' =>
    'Plik nie przeszedł kontroli integralności. Zasoby nie są gotowe; ponów pobieranie przy stabilnym połączeniu.',
  'timeout' =>
    'Przekroczono czas oczekiwania. Stan nie jest potwierdzony; sprawdź ponownie lub ponów pobieranie.',
  'protocol' =>
    'Nieprawidłowa odpowiedź lub niezgodna wersja protokołu offline. Odśwież aplikację i sprawdź ponownie.',
  'bridgeUnavailable' =>
    'Most offline lub kontroler przeglądarki nie jest jeszcze gotowy. Poczekaj i sprawdź ponownie.',
  _ =>
    'Nie można potwierdzić stanu pakietu. Sprawdź ponownie; jeśli błąd wraca, odśwież aplikację.',
};
