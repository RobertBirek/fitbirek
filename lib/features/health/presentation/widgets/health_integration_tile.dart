import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/warsaw_time.dart';
import '../../data/health_integration_api.dart';
import '../../providers/health_providers.dart';
import '../pages/health_setup_guide_page.dart';

class HealthIntegrationTile extends ConsumerStatefulWidget {
  const HealthIntegrationTile({super.key});
  @override
  ConsumerState<HealthIntegrationTile> createState() =>
      _HealthIntegrationTileState();
}

class _HealthIntegrationTileState extends ConsumerState<HealthIntegrationTile>
    with WidgetsBindingObserver {
  HealthIntegrationStatus? _status;
  HealthIntegrationToken? _secret;
  bool _busy = false;
  String? _error;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_refresh);
  }

  void _forget() {
    _epoch++;
    _secret?.dispose();
    _secret = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _forget();
  }

  @override
  void dispose() {
    _forget();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || ref.read(healthAccountProvider) == null) return;
    final epoch = _epoch;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await ref.read(healthIntegrationApiProvider).getStatus();
      if (mounted && epoch == _epoch) setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = null;
          _error =
              'Nie udało się odczytać statusu integracji. Wymagane połączenie i ważna sesja online.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    var consent = false;
    final epoch = _epoch;
    final allowed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Zgoda na dane zdrowotne'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Wybrane próbki masy, źródła, daty i ręcznie potwierdzone kroki zostaną wysłane przez HTTPS na VPS FitBirek, zsynchronizowane na urządzenia i mogą trafić do kopii zapasowych. Poza Apple nie chroni ich szyfrowanie end-to-end iCloud. Rotacja natychmiast unieważni stary token.',
                ),
                CheckboxListTile(
                  value: consent,
                  onChanged: (v) => update(() => consent = v == true),
                  title: const Text(
                    'Zgadzam się na wysyłanie danych zdrowotnych na VPS.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: consent ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Generuj'),
            ),
          ],
        ),
      ),
    );
    if (allowed != true || !mounted || epoch != _epoch) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(healthIntegrationApiProvider)
          .generateToken();
      if (!mounted ||
          epoch != _epoch ||
          ref.read(healthAccountProvider) == null) {
        result.dispose();
        return;
      }
      _secret = result;
      setState(() {
        _status = result.status;
        _busy = false;
      });
      await showDialog<void>(
        context: context,
        builder: (_) => _TokenDialog(secret: result),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = null;
          _error =
              'Nie udało się wygenerować tokenu. Sprawdź sesję i połączenie. Jeśli odpowiedź zaginęła, ponów rotację — nie odzyskamy starego tokenu.';
        });
      }
    } finally {
      _secret?.dispose();
      _secret = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    final epoch = _epoch;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyłączyć import?'),
        content: const Text(
          'Token przestanie działać. Zaimportowane dane pozostaną; można je usunąć osobno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odbierz'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || epoch != _epoch) return;
    setState(() => _busy = true);
    try {
      final status = await ref.read(healthIntegrationApiProvider).revoke();
      if (mounted && epoch == _epoch) {
        setState(() {
          _status = status;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = null;
          _error =
              'Nie potwierdzono odebrania dostępu. Token może nadal działać. Połącz się i ponów.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(healthAccountProvider, (previous, next) {
      if (previous != next) {
        _forget();
        setState(() => _status = null);
      }
    });
    final account = ref.watch(healthAccountProvider);
    final available = !_busy && _status != null && account != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: const Text('Apple Zdrowie'),
          leading: const Icon(Icons.favorite_outline),
          subtitle: Text(
            account == null
                ? 'Zaloguj się online.'
                : _status == null
                ? 'Status nieznany — wymagane połączenie online'
                : _status!.enabled
                ? 'Integracja włączona'
                : 'Integracja wyłączona',
          ),
          trailing: IconButton(
            tooltip: 'Odśwież Apple Zdrowie',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
        if (_status?.lastImportAt != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ostatni import: ${formatWarsaw(_status!.lastImportAt!)} • Europe/Warsaw',
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: available ? _generate : null,
                child: Text(
                  _status?.enabled == true ? 'Obróć token' : 'Generuj token',
                ),
              ),
              OutlinedButton(
                onPressed: available && _status!.enabled ? _revoke : null,
                child: const Text('Odbierz dostęp'),
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Jak połączyć Apple Zdrowie'),
          subtitle: const Text('Instrukcja krok po kroku • dostępna offline'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const HealthSetupGuidePage()),
          ),
        ),
      ],
    );
  }
}

class _TokenDialog extends ConsumerStatefulWidget {
  const _TokenDialog({required this.secret});
  final HealthIntegrationToken secret;
  @override
  ConsumerState<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends ConsumerState<_TokenDialog>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _clear() {
    widget.secret.dispose();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _clear();
  }

  @override
  void dispose() {
    widget.secret.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(healthAccountProvider, (previous, next) {
      if (previous != next) _clear();
    });
    return AlertDialog(
      title: const Text('Token — pokazany tylko raz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Przenieś token tylko do prywatnego Skrótu (nagłówek Authorization: Bearer). Nie udostępniaj Skrótu. Aplikacja nie zapisuje tokenu. Zmiana aplikacji lub zamknięcie usuwa go z dialogu; wtedy wykonaj rotację. Kopiowanie przez menu zaznaczenia używa systemowego schowka — usuń go po wklejeniu.',
            ),
            SelectableText(
              widget.secret.token.isEmpty
                  ? 'Token ukryty — wykonaj ponowną rotację.'
                  : widget.secret.token,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clear();
            Navigator.pop(context);
          },
          child: const Text('Zamknij'),
        ),
      ],
    );
  }
}
