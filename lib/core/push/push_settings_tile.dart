import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import 'push_provider.dart';

class PushSettingsTile extends ConsumerStatefulWidget {
  const PushSettingsTile({super.key});

  @override
  ConsumerState<PushSettingsTile> createState() => _PushSettingsTileState();
}

class _PushSettingsTileState extends ConsumerState<PushSettingsTile> {
  Map<String, dynamic> _status = {};
  Map<String, bool> _categories = {
    'karate': false,
    'training': false,
    'mood': false,
    'operations': false,
  };
  bool _busy = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_refresh);
  }

  Future<void> _refresh() => _run(
    () => ref
        .read(pushClientProvider)
        .status(ref.read(authStateProvider).accountId ?? ''),
  );

  Future<void> _run(
    Future<Map<String, dynamic>> Function() action, {
    bool test = false,
  }) async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      // Do not await anything before invoking action: enable requests browser
      // permission synchronously within the original button gesture.
      final result = await action();
      if (!mounted) return;
      setState(() {
        if (test) {
          _message =
              'Test dodany do kolejki. Sprawdź powiadomienia urządzenia.';
        } else {
          _status = result;
          if (result['categories'] is Map) {
            _categories = Map<String, bool>.from(result['categories'] as Map);
          }
          if (result['warning'] == 'local_only') {
            _message =
                'Wyłączono lokalnie. Serwer jest nieosiągalny; ponów po połączeniu.';
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = test
              ? 'Test niedostępny. Sprawdź połączenie i odczekaj 60 sekund przed kolejną próbą.'
              : 'Nie udało się zmienić push. Sprawdź połączenie i uprawnienia, następnie odśwież status.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _status['enabled'] == true;
    final server = _status['server'] as Map? ?? {};
    final ready = server['deliveryAvailable'] == true;
    final supported = _status['supported'] == true;
    final needsInstall = _status['needsInstall'] == true;
    final permission = _status['permission'];
    final account = ref.watch(authStateProvider).accountId ?? '';
    final description = !supported
        ? 'Web Push nie jest obsługiwany w tej przeglądarce.'
        : needsInstall
        ? 'Najpierw dodaj aplikację do ekranu początkowego i otwórz ją stamtąd.'
        : permission == 'denied'
        ? 'Powiadomienia zablokowane. Zmień uprawnienia witryny w ustawieniach przeglądarki/systemu.'
        : !ready
        ? 'Wysyłka niedostępna: ${server['reason'] == 'disabled' ? 'serwer nie został skonfigurowany' : 'sprawdź połączenie lub dostępność sendera'}.'
        : enabled
        ? 'Web Push włączone na tej instalacji.'
        : 'Web Push wyłączone. Wybierz kategorie i włącz.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Powiadomienia PWA (Web Push)'),
          subtitle: Text(description),
          trailing: IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież status push',
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'iPhone/iPad: Safari → Udostępnij → Do ekranu początkowego (iOS 16.4+). '
            'Android/komputer: menu przeglądarki → Zainstaluj aplikację. '
            'Godziny: Europe/Warsaw. Dostarczenie może być opóźnione przez system.',
          ),
        ),
        for (final entry in const {
          'karate': 'Karate — wtorek i czwartek, 19:30',
          'training': 'Trening — codziennie, 18:00',
          'mood': 'Samopoczucie — codziennie, 20:30',
          'operations': 'Alarmy techniczne i powrót do działania',
        }.entries)
          SwitchListTile(
            title: Text(entry.value),
            value: _categories[entry.key] ?? false,
            onChanged: _busy || !supported || needsInstall
                ? null
                : (value) {
                    final changed = {..._categories, entry.key: value};
                    if (enabled) {
                      _run(() => ref.read(pushClientProvider).save(changed));
                    } else {
                      setState(() => _categories = changed);
                    }
                  },
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (!enabled || _status['needsResubscribe'] == true)
                FilledButton(
                  onPressed:
                      _busy ||
                          !ready ||
                          !supported ||
                          needsInstall ||
                          permission == 'denied'
                      ? null
                      : () => _run(
                          () => ref
                              .read(pushClientProvider)
                              .enable(
                                server['publicKey'] as String,
                                _categories,
                                account,
                              ),
                        ),
                  child: Text(enabled ? 'Odnów subskrypcję' : 'Włącz Web Push'),
                ),
              if (enabled)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(ref.read(pushClientProvider).disable),
                  child: const Text('Wyłącz Web Push'),
                ),
              OutlinedButton(
                onPressed:
                    _busy ||
                        !enabled ||
                        !ready ||
                        _status['needsResubscribe'] == true
                    ? null
                    : () => _run(ref.read(pushClientProvider).test, test: true),
                child: const Text('Wyślij test'),
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_message!)),
      ],
    );
  }
}
