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
import '../../../schedule/presentation/widgets/today_schedule.dart';

final mentorVoiceProvider = Provider.autoDispose<MentorVoice>((ref) {
  final voice = MentorVoice();
  ref.onDispose(voice.dispose);
  return voice;
});

class MentorPage extends ConsumerStatefulWidget {
  const MentorPage({super.key, this.templatePrompt = false});
  final bool templatePrompt;
  @override
  ConsumerState<MentorPage> createState() => _MentorPageState();
}

class _MentorPageState extends ConsumerState<MentorPage>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _messages = ScrollController();
  int _scrollGeneration = 0;
  bool _newReply = false;
  int _scrollIntent = 0;
  bool _startingScroll = false;
  bool _autoScrolling = false;

  bool get _nearEnd =>
      !_messages.hasClients || _messages.position.extentAfter < 80;

  void _resetScroll() {
    _scrollGeneration++;
    _newReply = false;
    // Stop an animation belonging to the previous conversation immediately.
    if (_messages.hasClients) _messages.jumpTo(_messages.offset);
  }

  void _latest({bool animate = true, bool conditional = false}) {
    final ticket = ++_scrollGeneration;
    final generation = _generation;
    final session = ref.read(mentorConversationProvider).sessionId;
    final intent = _scrollIntent;
    final previousEnd = _messages.hasClients
        ? _messages.position.maxScrollExtent
        : 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          ticket != _scrollGeneration ||
          generation != _generation ||
          !_foreground ||
          _router?.routeInformationProvider.value.uri.path != '/today' ||
          session != ref.read(mentorConversationProvider).sessionId ||
          !_messages.hasClients) {
        return;
      }
      // Compare against the old end: layout growth from the answer itself
      // must not look like the user moving away from the conversation end.
      if (conditional &&
          (intent != _scrollIntent || previousEnd - _messages.offset >= 80)) {
        setState(() => _newReply = true);
        return;
      }
      if (_newReply) setState(() => _newReply = false);
      final media = MediaQuery.of(context);
      final end = _messages.position.maxScrollExtent;
      _startingScroll = _autoScrolling = true;
      try {
        if (!animate || media.disableAnimations || media.accessibleNavigation) {
          _messages.jumpTo(end);
          _autoScrolling = false;
        } else {
          _messages
              .animateTo(
                end,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
              )
              .whenComplete(() {
                if (mounted && ticket == _scrollGeneration) {
                  _autoScrolling = false;
                }
              });
        }
      } finally {
        _startingScroll = false;
      }
    });
  }

  void _conversationChanged(
    MentorConversationState? previous,
    MentorConversationState next,
  ) {
    if (!_foreground ||
        _router?.routeInformationProvider.value.uri.path != '/today') {
      _resetScroll();
      return;
    }
    if (previous?.sessionId != next.sessionId) {
      _resetScroll();
      if (next.sessionId != null) _latest(animate: false);
      return;
    }
    if (next.messages.isEmpty ||
        // Removing a rejected local draft is not a new assistant answer.
        previous?.messages.any((m) => m.id == next.messages.last.id) == true) {
      return;
    }
    final last = next.messages.last;
    if (!last.isAssistant || _nearEnd) {
      _latest(conditional: last.isAssistant);
    } else {
      setState(() => _newReply = true);
    }
  }

  late final MentorVoice _voice;
  bool _voiceBusy = false;
  bool _foreground = true;
  int _generation = 0, _seconds = 0;
  int _voiceGeneration = 0;
  Timer? _timer, _ttl;
  GoRouter? _router;
  bool _recording = false;
  bool _voiceDraft = false;
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
    if (widget.templatePrompt) _prefillTemplate();
  }

  void _prefillTemplate() {
    _input.text = 'Ułóż szablon: Poranne rozciąganie ogólne 15 min';
  }

  @override
  void didUpdateWidget(covariant MentorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.templatePrompt && !oldWidget.templatePrompt) _prefillTemplate();
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
      setState(() {
        if (widget.templatePrompt && _input.text.isEmpty) _prefillTemplate();
      });
    }
  }

  void _cleanup() {
    _generation++;
    _resetScroll();
    _stopVoice();
    _timer?.cancel();
    _ttl?.cancel();
    _voice.cancelRecording();
    _voice.stopPlayback();
    _voice.dispose();
    _input.clear();
    _voiceDraft = false;
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
    _scrollGeneration++;
    _messages.dispose();
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
    bool? autoPlayReply,
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
    final text = _input.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) return;
    final generation = _generation;
    final account = ref.read(authStateProvider).accountId;
    final voiceGeneration = _voiceGeneration;
    final conversation = ref.read(mentorConversationProvider.notifier);
    final playReply = autoPlayReply ?? _voiceDraft;
    if (regenerate && !await _confirmRegeneration()) return;
    if (!mounted || generation != _generation || _input.text != text) return;
    final result = await conversation.send(
      text,
      regenerate: regenerate,
      context: context,
      settingsRevision: settingsRevision,
    );
    if (!mounted ||
        generation != _generation ||
        account != ref.read(authStateProvider).accountId ||
        !identical(
          conversation,
          ref.read(mentorConversationProvider.notifier),
        ) ||
        result == null ||
        result.sessionId != ref.read(mentorConversationProvider).sessionId) {
      return;
    }
    if (_input.text == text) {
      _input.clear();
      setState(() => _voiceDraft = false);
    }
    final currentSettings = ref.read(mentorSettingsProvider).valueOrNull;
    if (!playReply ||
        !result.newReply ||
        voiceGeneration != _voiceGeneration ||
        !_foreground ||
        currentSettings?.available != true ||
        currentSettings?.consentText != true ||
        currentSettings?.consentVoice != true ||
        currentSettings?.elevenLabsConfigured != true ||
        !_voice.supported) {
      return;
    }
    await _play(result.reply, autoStart: true);
  }

  Future<void> _composeContext() async {
    final generation = _generation;
    final settings = ref.read(mentorSettingsProvider).valueOrNull;
    if (settings == null || _input.text.trim().isEmpty) return;
    // Fetch only on explicit opening, never auto-refresh/approve after rejection.
    ref.invalidate(mentorContextOptionsProvider);
    final selection = await showDialog<MentorContextSelection>(
      context: context,
      builder: (_) => MentorContextComposer(consents: settings.contextConsents),
    );
    if (!mounted || generation != _generation || selection == null) return;
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
          setState(() {
            _voiceBusy = false;
            _voiceDraft = true;
          });
          _latest();
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

  Future<void> _confirm(
    MentorProposal proposal, {
    required String? sourceAccount,
    required int sourceGeneration,
  }) async {
    if (sourceAccount == null ||
        sourceAccount != ref.read(authStateProvider).accountId ||
        sourceGeneration != _generation) {
      return;
    }
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
    if (proposal.kind == MentorProposalKind.createTemplate) {
      if (accountId == null) return;
      final seed = await ref
          .read(mentorActionsProvider)
          .prepareTemplate(
            proposal,
            accountId: accountId,
            expectedSessionId: sessionId,
          );
      if (!mounted ||
          generation != _generation ||
          ref.read(activeWorkoutProvider).sessionId != sessionId) {
        return;
      }
      if (seed == null) {
        _notice(
          'Szablon niedostępny. Sprawdź konto i aktualny katalog lub ułóż go samodzielnie.',
        );
        return;
      }
      context.push('/workout/templates/new', extra: seed);
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
    MentorProposalKind.createTemplate => 'Otworzyć szablon do edycji?',
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
    final proposalAccount = ref.watch(authStateProvider).accountId;
    final proposalGeneration = _generation;
    final state = ref.watch(mentorConversationProvider);
    ref.listen(mentorConversationProvider, _conversationChanged);
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
                      _voiceDraft = false;
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
                    _voiceDraft = false;
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: !enabled
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _availability(settings),
                      if (widget.templatePrompt) ...[
                        _templateHelp(),
                        TextField(
                          controller: _input,
                          maxLength: 2000,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Szkic szablonu',
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const TodaySchedule(),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) => Column(
                      children: [
                        Expanded(
                          child: state.loading && state.messages.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    // Real offset activity, not ScrollMetricsNotification:
                                    // covers drag, wheel, keyboard and external jumpTo.
                                    if (notification
                                            is ScrollStartNotification &&
                                        !_startingScroll) {
                                      _autoScrolling = false;
                                      _scrollIntent++;
                                    } else if (notification
                                            is ScrollUpdateNotification &&
                                        !_autoScrolling &&
                                        notification.scrollDelta != 0) {
                                      _scrollIntent++;
                                    }
                                    if (notification is ScrollEndNotification &&
                                        _newReply &&
                                        _nearEnd) {
                                      setState(() => _newReply = false);
                                    }
                                    return false;
                                  },
                                  child: SingleChildScrollView(
                                    key: const ValueKey('mentor-messages'),
                                    controller: _messages,
                                    padding: const EdgeInsets.all(16),
                                    // History is capped at 40 messages by the API. Eager
                                    // layout gives an exact end even for unequal bubbles.
                                    child: Column(
                                      children: [
                                        _overview(),
                                        if (widget.templatePrompt)
                                          _templateHelp(),
                                        ...List.generate(
                                          state.messages.length +
                                              (state.loading ? 1 : 0),
                                          (index) {
                                            if (index ==
                                                state.messages.length) {
                                              return const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'Mentor odpowiada…',
                                                  ),
                                                ),
                                              );
                                            }
                                            final message =
                                                state.messages[index];
                                            return _MessageBubble(
                                              message: message,
                                              playing: _playing == message.id,
                                              onPlay:
                                                  message.isAssistant &&
                                                      !_voiceBusy &&
                                                      !_recording &&
                                                      settings
                                                              .valueOrNull
                                                              ?.consentVoice ==
                                                          true &&
                                                      settings
                                                              .valueOrNull
                                                              ?.elevenLabsConfigured ==
                                                          true &&
                                                      _voice.supported
                                                  ? () => _play(message)
                                                  : null,
                                              onProposal:
                                                  message.proposal == null
                                                  ? null
                                                  : () => _confirm(
                                                      message.proposal!,
                                                      sourceAccount:
                                                          proposalAccount,
                                                      sourceGeneration:
                                                          proposalGeneration,
                                                    ),
                                            );
                                          },
                                        ),
                                        if (_recording)
                                          Text('Nagrywanie: $_seconds / 30 s'),
                                        if (_voiceBusy)
                                          const Text('Przetwarzanie głosu…'),
                                        if (_playing != null)
                                          TextButton(
                                            onPressed: () => _voice
                                                .play()
                                                .catchError((Object _) {
                                                  if (mounted) {
                                                    _notice(
                                                      'Głos wygasł. Przygotuj go ponownie.',
                                                    );
                                                  }
                                                }),
                                            child: const Text('Odtwórz'),
                                          ),
                                        if (_voiceDraft)
                                          const Text(
                                            'Sprawdź transkrypcję i wybierz Wyślij',
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        if (enabled && _newReply)
                          Semantics(
                            liveRegion: true,
                            child: TextButton.icon(
                              onPressed: () => _latest(),
                              icon: const Icon(Icons.arrow_downward),
                              label: const Text('Nowa odpowiedź'),
                            ),
                          ),
                        if (state.error != null)
                          Flexible(
                            flex: 2,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    state.error!,
                                    style: const TextStyle(
                                      color: FitBirekColors.danger,
                                    ),
                                  ),
                                  if (enabled)
                                    TextButton(
                                      onPressed: state.loading
                                          ? null
                                          : () => _send(regenerate: true),
                                      child: const Text(_regenerateLabel),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _input,
                                maxLength: 2000,
                                minLines: 1,
                                maxLines:
                                    constraints.maxHeight < 500 ||
                                        MediaQuery.viewInsetsOf(
                                              context,
                                            ).bottom >
                                            0
                                    ? 1
                                    : 3,
                                textInputAction: TextInputAction.send,
                                onChanged: (value) {
                                  if (_voiceDraft && value.trim().isEmpty) {
                                    setState(() => _voiceDraft = false);
                                  }
                                },
                                onSubmitted: (_) => _send(),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: 'Napisz do mentora…',
                                  hintMaxLines: 1,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_recording ||
                                      _voiceBusy ||
                                      _playing != null)
                                    IconButton(
                                      tooltip: 'Stop',
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      onPressed: _stopVoice,
                                      icon: const Icon(Icons.cancel_outlined),
                                    ),
                                  if (_voice.supported)
                                    IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      tooltip: _recording
                                          ? 'Zakończ nagranie'
                                          : 'Nagraj wiadomość',
                                      icon: Icon(
                                        _recording
                                            ? Icons.stop_circle
                                            : Icons.mic,
                                      ),
                                      color: _recording
                                          ? FitBirekColors.danger
                                          : null,
                                      onPressed:
                                          state.loading ||
                                              !enabled ||
                                              _voiceBusy ||
                                              settings
                                                      .valueOrNull
                                                      ?.consentVoice !=
                                                  true ||
                                              settings
                                                      .valueOrNull
                                                      ?.elevenLabsConfigured !=
                                                  true
                                          ? null
                                          : _record,
                                    ),
                                  if (_voiceDraft)
                                    IconButton(
                                      tooltip: 'Anuluj transkrypcję',
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      onPressed: () => setState(() {
                                        _input.clear();
                                        _voiceDraft = false;
                                      }),
                                      icon: const Icon(Icons.close),
                                    ),
                                  const Spacer(),
                                  const SizedBox(width: 8),
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _input,
                                    builder: (context, value, child) =>
                                        IconButton.outlined(
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          tooltip:
                                              'Dodaj kontekst do tej wiadomości',
                                          onPressed:
                                              state.loading ||
                                                  !enabled ||
                                                  value.text.trim().isEmpty
                                              ? null
                                              : _composeContext,
                                          icon: child!,
                                        ),
                                    child: const Icon(Icons.tune),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    tooltip: 'Wyślij',
                                    onPressed: state.loading || !enabled
                                        ? null
                                        : () => _send(),
                                    icon: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _availability(AsyncValue<MentorSettings> settings) {
    final value = settings.valueOrNull;
    final reason = settings.isLoading
        ? 'Sprawdzanie konfiguracji Mentora…'
        : settings.hasError
        ? 'Nie można odczytać konfiguracji. Sprawdź połączenie i spróbuj ponownie.'
        : value?.available != true
        ? 'Brak konfiguracji usługi.'
        : value?.openAiConfigured != true
        ? 'Dodaj klucz OpenAI w ustawieniach Mentora.'
        : 'Włącz zgodę na tekst w ustawieniach Mentora.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reason, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => context.push('/settings/mentor'),
          child: const Text('Otwórz ustawienia mentora'),
        ),
        if (settings.hasError)
          TextButton(
            onPressed: () => ref.invalidate(mentorSettingsProvider),
            child: const Text('Spróbuj ponownie'),
          ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => context.go('/today/classic'),
          child: const Text('Klasyczny trening (offline)'),
        ),
      ],
    );
  }

  Widget _templateHelp() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Opisz nazwę i cel szablonu. Wysłanie używa limitu i może kosztować. Propozycja otworzy edytor; niczego nie zapisze ani nie rozpocznie. Bez konfiguracji Mentora ułóż szablon samodzielnie.',
      ),
      TextButton(
        onPressed: () => context.push('/workout/templates/new'),
        child: const Text('Ułóż szablon samodzielnie'),
      ),
    ],
  );

  Widget _overview() => ExpansionTile(
    title: const Text('Plan dnia i podpowiedzi'),
    children: [
      const TodaySchedule(),
      TextButton(
        onPressed: () => context.go('/today/classic'),
        child: const Text('Klasyczny trening (offline)'),
      ),
      if (ref.watch(activeWorkoutProvider).isActive)
        TextButton(
          onPressed: () => context.go('/workout/session'),
          child: const Text('Wznów aktywny trening'),
        ),
      const Text(
        'Spokojnie, konkretnie i bez oceniania. Zanim zapiszę trening lub serię, zawsze poproszę o potwierdzenie.',
      ),
      if (!_voice.supported)
        const Text('Użyj klawiatury lub dyktowania systemowego.'),
      Wrap(
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
    ],
  );

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
      _voiceDraft = false;
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
            style: TextStyle(
              color: message.isAssistant ? null : FitBirekColors.onAccent,
            ),
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
