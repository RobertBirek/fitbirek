import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../workout/providers/workout_providers.dart';
import '../../data/mentor_models.dart';
import '../../data/mentor_api.dart';
import '../../providers/mentor_providers.dart';
import '../../providers/mentor_actions.dart';
import '../widgets/mentor_context_composer.dart';
import '../../voice/mentor_voice.dart';
import '../../../auth/providers/auth_providers.dart';

final mentorVoiceProvider = Provider.autoDispose<MentorVoice>((ref) {
  final voice = MentorVoice();
  ref.onDispose(voice.dispose);
  return voice;
});

class MentorPage extends ConsumerStatefulWidget {
  const MentorPage({super.key});
  @override
  ConsumerState<MentorPage> createState() => _MentorPageState();
}

class _MentorPageState extends ConsumerState<MentorPage>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  late final MentorVoice _voice;
  bool _voiceBusy = false;
  bool _foreground = true;
  int _generation = 0, _seconds = 0;
  int _voiceGeneration = 0;
  Timer? _timer, _ttl;
  GoRouter? _router;
  bool _recording = false;
  bool _opened = false;
  String? _playing;
  String? _recordingRequestId;
  static const _regenerateLabel =
      'Wygeneruj ponownie — ponowne użycie limitu i koszt';

  Future<bool> _confirmRegeneration() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nowa płatna operacja'),
          content: const Text(
            'Poprzednia próba mogła już zużyć limit. Nowa odpowiedź, głos lub nagranie ponownie użyje limitu i może naliczyć koszt. Zmiana treści nie anuluje poprzedniej operacji.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(_regenerateLabel),
            ),
          ],
        ),
      ) ==
      true;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(mentorVoiceProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_router != router) {
      _router?.routerDelegate.removeListener(_routeChanged);
      _router = router;
      router.routerDelegate.addListener(_routeChanged);
    }
  }

  void _routeChanged() {
    if (_router?.routeInformationProvider.value.uri.path != '/today') {
      _cleanup();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _cleanup() {
    _generation++;
    _stopVoice();
    _timer?.cancel();
    _ttl?.cancel();
    _voice.cancelRecording();
    _voice.stopPlayback();
    _voice.dispose();
    _input.clear();
    ref.read(mentorApiProvider).cancel();
    ref.invalidate(mentorApiProvider);
    if (mounted) {
      setState(() {
        _opened = false;
        _recording = _voiceBusy = false;
        _playing = null;
      });
    }
  }

  void _stopVoice() {
    _voiceGeneration++;
    _recordingRequestId = null;
    _timer?.cancel();
    _ttl?.cancel();
    _voice.cancelRecording();
    _voice.stopPlayback();
    ref.read(mentorVoiceApiProvider).cancel();
    ref.invalidate(mentorVoiceApiProvider);
    if (mounted) {
      setState(() {
        _recording = _voiceBusy = false;
        _playing = null;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cleanup();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _input.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _router?.routerDelegate.removeListener(_routeChanged);
    _timer?.cancel();
    _ttl?.cancel();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _send({
    bool regenerate = false,
    bool autoPlayReply = false,
    MentorContextSelection? context,
    int? settingsRevision,
  }) async {
    if (ref.read(mentorConversationProvider).loading ||
        _voiceBusy ||
        _recording) {
      return;
    }
    final settings = ref.read(mentorSettingsProvider).valueOrNull;
    if (!_foreground ||
        settings?.openAiConfigured != true ||
        settings?.consentText != true) {
      return;
    }
    final generation = _generation;
    final text = _input.text;
    if (regenerate && !await _confirmRegeneration()) return;
    if (!mounted || generation != _generation) return;
    await ref
        .read(mentorConversationProvider.notifier)
        .send(
          text,
          regenerate: regenerate,
          context: context,
          settingsRevision: settingsRevision,
        );
    if (mounted &&
        generation == _generation &&
        _input.text == text &&
        ref.read(mentorConversationProvider).error == null) {
      _input.clear();
    }
    if (!autoPlayReply || !mounted || generation != _generation) return;
    final state = ref.read(mentorConversationProvider);
    if (state.error != null) return;
    final replies = state.messages.where((message) => message.isAssistant);
    if (replies.isNotEmpty) {
      await _play(replies.last, autoStart: true);
    }
  }

  Future<void> _composeContext() async {
    final settings = ref.read(mentorSettingsProvider).valueOrNull;
    if (settings == null || _input.text.trim().isEmpty) return;
    final selection = await showDialog<MentorContextSelection>(
      context: context,
      builder: (_) => MentorContextComposer(
        consents: settings.contextConsents,
      ),
    );
    if (!mounted || selection == null) return;
    await _send(context: selection, settingsRevision: settings.revision);
  }

  Future<void> _record() async {
    if (_voiceBusy) return;
    final generation = _voiceGeneration;
    setState(() => _voiceBusy = true);
    try {
      if (_recording) {
        final audio = await _voice.stopRecording();
        if (!mounted || generation != _voiceGeneration) return;
        _timer?.cancel();
        setState(() => _recording = false);
        final text = await ref
            .read(mentorVoiceApiProvider)
            .transcribe(
              audio.bytes,
              audio.contentType,
              audio.durationSeconds,
              requestId: _recordingRequestId!,
            );
        if (mounted && generation == _voiceGeneration) {
          _input.text = text;
          setState(() => _voiceBusy = false);
          await _send(autoPlayReply: true);
        }
      } else {
        final api = ref.read(mentorVoiceApiProvider);
        final registry = ref.read(mentorOperationRegistryProvider);
        try {
          _recordingRequestId = (await registry.resolve(api, 'stt')).requestId;
        } on MentorException catch (e) {
          if (e.code != 'result_unavailable') rethrow;
          if (!mounted ||
              generation != _voiceGeneration ||
              !await _confirmRegeneration()) {
            return;
          }
          if (!mounted || generation != _voiceGeneration) return;
          _recordingRequestId = (await registry.resolve(
            api,
            'stt',
            regenerate: true,
          )).requestId;
        }
        if (!mounted || generation != _voiceGeneration) return;
        await _voice.startRecording();
        if (mounted && generation == _voiceGeneration) {
          setState(() {
            _recording = true;
            _seconds = 0;
          });
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() => _seconds++);
            if (_seconds >= 30) {
              _timer?.cancel();
              _record();
            }
          });
        }
      }
    } catch (_) {
      _voice.cancelRecording();
      if (mounted && generation == _voiceGeneration) {
        setState(() => _recording = false);
        _notice('Nie udało się nagrać wiadomości.');
      }
    } finally {
      if (mounted && generation == _voiceGeneration) {
        setState(() => _voiceBusy = false);
      }
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _play(
    MentorMessage message, {
    bool regenerate = false,
    bool autoStart = false,
  }) async {
    if (_voiceBusy) return;
    final generation = _voiceGeneration;
    setState(() => _voiceBusy = true);
    try {
      final api = ref.read(mentorVoiceApiProvider);
      final operation = await ref
          .read(mentorOperationRegistryProvider)
          .resolve(api, 'tts', subjectId: message.id, regenerate: regenerate);
      if (!mounted || generation != _voiceGeneration) return;
      final data = await api.speech(message.id, requestId: operation.requestId);
      if (!mounted || generation != _voiceGeneration) return;
      await _voice.preparePlayback(data);
      if (!mounted || generation != _voiceGeneration) return;
      setState(() => _playing = message.id);
      _ttl?.cancel();
      _ttl = Timer(const Duration(seconds: 60), () {
        if (mounted) setState(() => _playing = null);
      });
      if (autoStart) {
        try {
          await _voice.play();
        } catch (_) {
          if (mounted && generation == _voiceGeneration) {
            _notice(
              'Głos jest gotowy. Użyj Odtwórz, aby rozpocząć odtwarzanie.',
            );
          }
        }
      }
    } on MentorException catch (e) {
      if (mounted && generation == _voiceGeneration) {
        _notice(
          'Wynik głosu jest niedostępny. Ponowienie nie tworzy nowej płatnej operacji.',
        );
        if (const {
              'result_unavailable',
              'operation_failed',
              'operation_cancelled',
              'operation_conflict',
            }.contains(e.code) &&
            await _confirmRegeneration() &&
            mounted &&
            generation == _voiceGeneration) {
          setState(() => _voiceBusy = false);
          await _play(message, regenerate: true);
        }
      }
    } catch (_) {
      if (mounted && generation == _voiceGeneration) {
        _notice('Odtwarzanie odpowiedzi nie jest teraz dostępne.');
      }
    } finally {
      if (mounted && generation == _voiceGeneration) {
        setState(() => _voiceBusy = false);
      }
    }
  }

  Future<void> _confirm(MentorProposal proposal) async {
    if (!proposal.isSafeToConfirm) {
      _notice('Ta propozycja wymaga doprecyzowania.');
      return;
    }
    final accountId = ref.read(authStateProvider).accountId;
    final sessionId = ref.read(activeWorkoutProvider).sessionId;
    final generation = _generation;
    final exercise = ref
        .read(allExercisesProvider)
        .valueOrNull
        ?.where((e) => e.id == proposal.exerciseId)
        .firstOrNull;
    if (proposal.kind == MentorProposalKind.logSet && exercise == null) {
      _notice('Ćwiczenie nie jest dostępne w katalogu.');
      return;
    }
    var weight = '${proposal.weightKg ?? 0}';
    var reps = '${proposal.reps ?? 1}';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdź działanie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_proposalLabel(proposal)),
            if (exercise != null) Text(exercise.nazwaPl),
            if (proposal.kind == MentorProposalKind.logSet) ...[
              TextFormField(
                initialValue: weight,
                onChanged: (value) => weight = value,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ciężar (kg)'),
              ),
              TextFormField(
                initialValue: reps,
                onChanged: (value) => reps = value,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Powtórzenia'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wykonaj'),
          ),
        ],
      ),
    );
    final kg = double.tryParse(weight.replaceAll(',', '.'));
    final count = int.tryParse(reps);
    if (accepted != true ||
        !mounted ||
        generation != _generation ||
        accountId == null) {
      return;
    }
    if (proposal.kind == MentorProposalKind.logSet &&
        (kg == null || count == null)) {
      _notice('Wpisz poprawny ciężar i liczbę powtórzeń.');
      return;
    }
    final result = await ref
        .read(mentorActionsProvider)
        .confirm(
          proposal,
          accountId: accountId,
          expectedSessionId: sessionId,
          weightKg: kg,
          reps: count,
        );
    if (!mounted || generation != _generation) return;
    if (result == MentorActionResult.unavailable) {
      _notice('Działanie niedostępne. Sprawdź konto, trening i wartości.');
      return;
    }
    if (result == MentorActionResult.alreadyApplied) {
      _notice('To działanie zostało już wykonane.');
      return;
    }
    if (proposal.kind == MentorProposalKind.startWorkout) {
      context.go('/workout/session');
    }
    if (proposal.kind == MentorProposalKind.navigateExercises) {
      context.go('/exercises');
    }
    if (proposal.kind == MentorProposalKind.logSet) {
      _notice('Seria została zapisana.');
    }
  }

  String _proposalLabel(MentorProposal p) => switch (p.kind) {
    MentorProposalKind.startWorkout => 'Rozpocząć nowy trening?',
    MentorProposalKind.navigateExercises => 'Otworzyć bazę ćwiczeń?',
    MentorProposalKind.logSet => 'Zapisać serię: ${p.weightKg} kg × ${p.reps}?',
  };

  @override
  Widget build(BuildContext context) {
    ref.watch(allExercisesProvider);
    ref.watch(mentorVoiceProvider);
    ref.watch(mentorVoiceApiProvider);
    ref.listen(authStateProvider, (previous, next) {
      if (previous != next) _cleanup();
    });
    final settings = ref.watch(mentorSettingsProvider);
    final state = ref.watch(mentorConversationProvider);
    final enabled =
        _foreground &&
        _router?.routeInformationProvider.value.uri.path == '/today' &&
        settings.valueOrNull?.openAiConfigured == true &&
        settings.valueOrNull?.available == true &&
        settings.valueOrNull?.consentText == true;
    if (enabled && !_opened) {
      _opened = true;
      Future.microtask(() {
        if (mounted && _opened) {
          ref.read(mentorConversationProvider.notifier).openLatest();
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor treningowy'),
        actions: [
          IconButton(
            tooltip: 'Historia rozmów',
            icon: const Icon(Icons.history),
            onPressed: !enabled || state.loading ? null : _history,
          ),
          IconButton(
            tooltip: 'Usuń rozmowę',
            icon: const Icon(Icons.delete_outline),
            onPressed: !enabled || state.sessionId == null
                ? null
                : () async {
                    final generation = _generation;
                    final sessionId = state.sessionId;
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Usunąć rozmowę?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Anuluj'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Usuń'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true &&
                        mounted &&
                        generation == _generation &&
                        ref.read(mentorConversationProvider).sessionId ==
                            sessionId) {
                      _stopVoice();
                      _input.clear();
                      await ref
                          .read(mentorConversationProvider.notifier)
                          .deleteCurrent();
                    }
                  },
          ),
          IconButton(
            tooltip: 'Nowa rozmowa',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: !enabled || state.loading
                ? null
                : () {
                    _input.clear();
                    _stopVoice();
                    ref
                        .read(mentorConversationProvider.notifier)
                        .newConversation();
                  },
          ),
          IconButton(
            tooltip: 'Ustawienia mentora',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings/mentor'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () => context.go('/today/classic'),
                      child: const Text('Klasyczny trening (offline)'),
                    ),
                    if (ref.watch(activeWorkoutProvider).isActive)
                      TextButton(
                        onPressed: () => context.go('/workout/session'),
                        child: const Text('Wznów aktywny trening'),
                      ),
                    if (!_voice.supported)
                      const Text('Użyj klawiatury lub dyktowania systemowego.'),
                    if (_recording) Text('Nagrywanie: $_seconds / 30 s'),
                    if (_playing != null)
                      TextButton(
                        onPressed: () {
                          _voice.play().catchError((Object _) {
                            if (mounted) {
                              _notice('Głos wygasł. Przygotuj go ponownie.');
                            }
                          });
                        },
                        child: const Text('Odtwórz'),
                      ),
                    TextButton(
                      onPressed: _stopVoice,
                      child: const Text('Stop'),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FitBirekColors.accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Spokojnie, konkretnie i bez oceniania. Zanim zapiszę trening lub serię, zawsze poproszę o potwierdzenie.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final prompt in const [
                            'Mam mało czasu — ułóż krótki trening.',
                            'Dziś mam dużo energii.',
                            'Pomóż mi zaplanować trening na dziś.',
                          ])
                            ActionChip(
                              label: Text(prompt),
                              onPressed: () => _input.text = prompt,
                            ),
                        ],
                      ),
                    ),
                    if (!enabled)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Mentor wymaga połączenia, zapisanego klucza OpenAI i zgody na tekst. Trening klasyczny działa offline.',
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/settings/mentor'),
                                  child: const Text(
                                    'Otwórz ustawienia mentora',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: !enabled
                  ? Center(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/today/classic'),
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Klasyczny trening (offline)'),
                      ),
                    )
                  : state.loading && state.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.messages.length + (state.loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Mentor odpowiada…'),
                            ),
                          );
                        }
                        final message = state.messages[index];
                        return _MessageBubble(
                          message: message,
                          playing: _playing == message.id,
                          onPlay:
                              message.isAssistant &&
                                  !_voiceBusy &&
                                  !_recording &&
                                  settings.valueOrNull?.consentVoice == true &&
                                  settings.valueOrNull?.elevenLabsConfigured ==
                                      true &&
                                  _voice.supported
                              ? () => _play(message)
                              : null,
                          onProposal: message.proposal == null
                              ? null
                              : () => _confirm(message.proposal!),
                        );
                      },
                    ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: FitBirekColors.danger),
                ),
              ),
            if (state.error != null && enabled)
              TextButton(
                onPressed: state.loading ? null : () => _send(regenerate: true),
                child: const Text(_regenerateLabel),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  if (_voice.supported)
                    IconButton(
                      tooltip: _recording
                          ? 'Zakończ nagranie'
                          : 'Nagraj wiadomość',
                      icon: Icon(_recording ? Icons.stop_circle : Icons.mic),
                      color: _recording ? FitBirekColors.danger : null,
                      onPressed:
                          state.loading ||
                              !enabled ||
                              _voiceBusy ||
                              settings.valueOrNull?.consentVoice != true ||
                              settings.valueOrNull?.elevenLabsConfigured != true
                          ? null
                          : _record,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'Napisz do mentora…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _input,
                    builder: (context, value, child) => IconButton.outlined(
                      tooltip: 'Dodaj kontekst do tej wiadomości',
                      onPressed:
                          state.loading || !enabled || value.text.trim().isEmpty
                          ? null
                          : _composeContext,
                      icon: child!,
                    ),
                    child: const Icon(Icons.tune),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Wyślij',
                    onPressed: state.loading || !enabled ? null : () => _send(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _history() async {
    final generation = _generation;
    try {
      final sessions = await ref.read(mentorApiProvider).sessions();
      if (!mounted || generation != _generation) return;
      final id = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Historia rozmów'),
          children: [
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Brak rozmów'),
              ),
            for (final session in sessions.take(20))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, session.id),
                child: Text('${session.createdAt.toLocal()}'),
              ),
          ],
        ),
      );
      if (!mounted || generation != _generation || id == null) return;
      _stopVoice();
      _input.clear();
      await ref.read(mentorConversationProvider.notifier).open(id);
    } catch (_) {
      if (mounted) _notice('Historia jest teraz niedostępna.');
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.playing,
    this.onPlay,
    this.onProposal,
  });
  final MentorMessage message;
  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback? onProposal;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isAssistant
        ? Alignment.centerLeft
        : Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 440),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: message.isAssistant
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : FitBirekColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(color: message.isAssistant ? null : Colors.white),
          ),
          if (message.isAssistant && onPlay != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Przygotuj głos',
                icon: Icon(
                  playing ? Icons.volume_up : Icons.volume_up_outlined,
                ),
                onPressed: onPlay,
              ),
            ),
          if (onProposal != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.tonal(
                onPressed: onProposal,
                child: const Text('Sprawdź i potwierdź'),
              ),
            ),
        ],
      ),
    ),
  );
}
