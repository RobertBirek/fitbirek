import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mentor_models.dart';
import '../../providers/mentor_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/mentor_api.dart';

const _counterLabels = {
  'requests': 'Żądania',
  'tts_chars': 'Znaki syntezy mowy',
  'stt_bytes': 'Bajty nagrań',
  'stt_seconds': 'Sekundy nagrań',
  'output_tokens': 'Tokeny odpowiedzi',
};

class MentorSettingsPage extends ConsumerStatefulWidget {
  const MentorSettingsPage({super.key});
  @override
  ConsumerState<MentorSettingsPage> createState() => _MentorSettingsPageState();
}

class _MentorSettingsPageState extends ConsumerState<MentorSettingsPage> {
  final _memory = TextEditingController();
  bool _loaded = false, _saving = false;
  DateTime? _voicesRefreshed;
  @override
  void dispose() {
    _memory.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _save(
    MentorSettings current, {
    bool? text,
    bool? voice,
    String? model,
    String? tts,
    String? stt,
    String? voiceId,
    bool saveMemory = false,
  }) async {
    setState(() => _saving = true);
    try {
      await ref.read(mentorApiProvider).saveSettings({
        'consent_text': text ?? current.consentText,
        'consent_voice': voice ?? current.consentVoice,
        'memory': saveMemory ? _memory.text.trim() : current.memory,
        'model': model ?? current.model,
        'tts_model': tts ?? current.ttsModel,
        'stt_model': stt ?? current.sttModel,
        'voice_id': voiceId ?? current.voiceId,
      });
      ref.invalidate(mentorSettingsProvider);
    } catch (_) {
      if (mounted) _message('Nie udało się zapisać ustawień.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _keyDialog(String provider, bool configured) async {
    await showDialog<void>(
      context: context,
      builder: (context) => MentorKeyDialog(
        provider: provider,
        configured: configured,
        api: ref.read(mentorApiProvider),
      ),
    );
    if (mounted) ref.invalidate(mentorApiProvider);
  }

  Future<void> _test(String provider) async {
    setState(() => _saving = true);
    try {
      await ref.read(mentorApiProvider).testProvider(provider);
      if (mounted) _message('Test zakończony pomyślnie.');
    } catch (_) {
      if (mounted) _message('Test nie powiódł się.');
    } finally {
      if (mounted) {
        ref.invalidate(mentorSettingsProvider);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous != next) {
        _memory.clear();
        _loaded = false;
      }
    });
    final async = ref.watch(mentorSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia mentora')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Ustawienia mentora są teraz niedostępne.'),
          ),
        ),
        data: (settings) {
          if (!_loaded) {
            _memory.text = settings.memory;
            _loaded = true;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!settings.available)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Mentor nie jest skonfigurowany na serwerze. Trening offline nadal działa bez zmian.',
                    ),
                  ),
                ),
              const Text(
                'Prywatność i zgody',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Rozmowy tekstowe'),
                subtitle: const Text(
                  'OpenAI otrzymuje świadomie wysłany tekst, zatwierdzoną pamięć i ograniczony, zweryfikowany kontekst treningowy.',
                ),
                value: settings.consentText,
                onChanged: _saving || !settings.available
                    ? null
                    : (v) => _save(settings, text: v),
              ),
              SwitchListTile(
                title: const Text('Wiadomości głosowe'),
                subtitle: const Text(
                  'ElevenLabs otrzymuje nagrania do transkrypcji i wybrane odpowiedzi mentora do syntezy mowy. Transkrypcję poprawisz przed wysłaniem.',
                ),
                value: settings.consentVoice,
                onChanged: _saving || !settings.available
                    ? null
                    : (v) => _save(settings, voice: v),
              ),
              const SizedBox(height: 8),
              const Text(
                'Domyślnie nie wysyłamy masy ciała, kroków, Apple Health, prywatnych dokumentów ani kluczy. Pamięć jest zapisywana wyłącznie na serwerze po Twoim zatwierdzeniu.',
              ),
              TextField(
                enabled: settings.available && !_saving,
                controller: _memory,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Co mentor pamięta',
                  helperText:
                      'Wyłącznie informacje, które świadomie chcesz podać.',
                ),
                onSubmitted: (_) => _save(settings, saveMemory: true),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving || !settings.available
                      ? null
                      : () => _save(settings, saveMemory: true),
                  child: const Text('Zapisz pamięć'),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Połączenia dostawców',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: Icon(
                  settings.openAiConfigured ? Icons.lock : Icons.key_outlined,
                ),
                title: const Text('OpenAI'),
                subtitle: Text(
                  settings.openAiConfigured ? 'Klucz zapisany' : 'Brak klucza',
                ),
                onTap: _saving || !settings.available
                    ? null
                    : () => _keyDialog('openai', settings.openAiConfigured),
              ),
              ListTile(
                leading: Icon(
                  settings.elevenLabsConfigured
                      ? Icons.lock
                      : Icons.key_outlined,
                ),
                title: const Text('ElevenLabs'),
                subtitle: Text(
                  settings.elevenLabsConfigured
                      ? 'Klucz zapisany'
                      : 'Brak klucza',
                ),
                onTap: _saving || !settings.available
                    ? null
                    : () => _keyDialog(
                        'elevenlabs',
                        settings.elevenLabsConfigured,
                      ),
              ),
              const Text(
                'Testy i odświeżanie głosów wywołują dostawcę i wliczają się do dziennych limitów.',
              ),
              TextButton(
                onPressed:
                    _saving ||
                        !settings.available ||
                        !settings.openAiConfigured ||
                        !settings.consentText
                    ? null
                    : () => _test('openai'),
                child: const Text('Test OpenAI'),
              ),
              TextButton(
                onPressed:
                    _saving ||
                        !settings.available ||
                        !settings.elevenLabsConfigured ||
                        !settings.consentVoice
                    ? null
                    : () => _test('elevenlabs'),
                child: const Text('Test ElevenLabs'),
              ),
              const Text('Dzienne zużycie / limit'),
              for (final entry in settings.limits.entries)
                Text(
                  '${_counterLabels[entry.key] ?? entry.key}: ${settings.usage[entry.key] ?? 0} / ${entry.value}',
                ),
              _ChoiceTile(
                label: 'Model rozmów',
                value: settings.model,
                choices: settings.models,
                onChanged: _saving || !settings.available
                    ? null
                    : (v) => _save(settings, model: v),
              ),
              _ChoiceTile(
                label: 'Model mowy',
                value: settings.ttsModel,
                choices: settings.ttsModels,
                onChanged: _saving || !settings.available
                    ? null
                    : (v) => _save(settings, tts: v),
              ),
              _ChoiceTile(
                label: 'Model transkrypcji',
                value: settings.sttModel,
                choices: settings.sttModels,
                onChanged: _saving || !settings.available
                    ? null
                    : (v) => _save(settings, stt: v),
              ),
              ListTile(
                title: const Text('Głos mentora'),
                subtitle: Text(
                  settings.voices
                          .where((v) => v.id == settings.voiceId)
                          .map((v) => v.name)
                          .firstOrNull ??
                      'Wybierz głos',
                ),
                trailing: const Icon(Icons.refresh),
                onTap:
                    _saving ||
                        !settings.available ||
                        !settings.elevenLabsConfigured ||
                        !settings.consentVoice
                    ? null
                    : () async {
                        if (_voicesRefreshed != null &&
                            DateTime.now().difference(_voicesRefreshed!) <
                                const Duration(seconds: 30)) {
                          _message(
                            'Odczekaj 30 sekund przed kolejnym odświeżeniem.',
                          );
                          return;
                        }
                        _voicesRefreshed = DateTime.now();
                        setState(() => _saving = true);
                        try {
                          await ref.read(mentorApiProvider).refreshVoices();
                          ref.invalidate(mentorSettingsProvider);
                          if (mounted) {
                            _message('Lista głosów została odświeżona.');
                          }
                        } catch (_) {
                          if (mounted) _message('Nie udało się pobrać głosów.');
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              ),
              if (settings.voices.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue:
                      settings.voices.any((v) => v.id == settings.voiceId)
                      ? settings.voiceId
                      : null,
                  decoration: const InputDecoration(labelText: 'Wybrany głos'),
                  items: settings.voices
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v.id, child: Text(v.name)),
                      )
                      .toList(),
                  onChanged: _saving || !settings.available
                      ? null
                      : (v) {
                          if (v != null) _save(settings, voiceId: v);
                        },
                ),
            ],
          );
        },
      ),
    );
  }
}

class MentorKeyDialog extends ConsumerStatefulWidget {
  const MentorKeyDialog({
    super.key,
    required this.provider,
    required this.configured,
    required this.api,
  });
  final String provider;
  final bool configured;
  final MentorApi api;
  @override
  ConsumerState<MentorKeyDialog> createState() => _MentorKeyDialogState();
}

class _MentorKeyDialogState extends ConsumerState<MentorKeyDialog>
    with WidgetsBindingObserver {
  final _key = TextEditingController();
  bool _busy = false;
  bool _closing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _key.clear();
    _key.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_closing) return;
    _closing = true;
    _key.clear();
    widget.api.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _dismiss();
  }

  Future<void> _submit({bool delete = false}) async {
    String secret = _key.text.trim();
    _key.clear();
    if (_busy || (!delete && secret.isEmpty)) {
      secret = '';
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = delete
          ? widget.api.deleteKey(widget.provider)
          : widget.api.saveKey(widget.provider, secret);
      secret = '';
      await request;
      if (mounted && !_closing) {
        _closing = true;
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted && !_closing) {
        setState(() => _error = 'Nie udało się zmienić klucza.');
      }
    } finally {
      secret = '';
      if (mounted && !_closing) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous != next) _dismiss();
    });
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _closing = true;
          _key.clear();
          if (_busy) widget.api.cancel();
        }
      },
      child: AlertDialog(
        title: Text(
          widget.provider == 'openai' ? 'Klucz OpenAI' : 'Klucz ElevenLabs',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Klucz przesyłamy jednorazowo przez HTTPS w uwierzytelnionej sesji. Zapisany klucz nie jest zwracany ani wyświetlany.',
            ),
            TextField(
              controller: _key,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              decoration: const InputDecoration(labelText: 'Nowy klucz'),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
        actions: [
          if (widget.configured)
            TextButton(
              onPressed: _busy ? null : () => _submit(delete: true),
              child: const Text('Usuń'),
            ),
          TextButton(onPressed: _dismiss, child: const Text('Anuluj')),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.value,
    required this.choices,
    this.onChanged,
  });
  final String label, value;
  final List<String> choices;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => choices.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            initialValue: choices.contains(value) ? value : null,
            decoration: InputDecoration(labelText: label),
            items: choices
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: onChanged == null
                ? null
                : (selected) {
                    if (selected != null) onChanged!(selected);
                  },
          ),
        );
}
