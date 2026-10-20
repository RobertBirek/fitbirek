import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_providers.dart'
    show apiClientProvider, authStateProvider;
import '../data/mentor_api.dart';
import '../data/mentor_models.dart';
import '../data/mentor_operations.dart';

final mentorOperationRegistryProvider = Provider<MentorOperationRegistry>((
  ref,
) {
  final account = ref.watch(authStateProvider.select((s) => s.accountId));
  final registry = MentorOperationRegistry(account ?? '');
  ref.onDispose(registry.dispose);
  return registry;
});

final mentorApiProvider = Provider.autoDispose<MentorApi>((ref) {
  // Recreate and cancel all in-flight work when the authenticated account changes.
  ref.watch(authStateProvider);
  final api = HttpMentorApi(ref.watch(apiClientProvider));
  ref.onDispose(api.cancel);
  return api;
});
final mentorSettingsProvider = FutureProvider.autoDispose<MentorSettings>(
  (ref) => ref.watch(mentorApiProvider).settings(),
);

final mentorVoiceApiProvider = Provider.autoDispose<MentorApi>((ref) {
  ref.watch(authStateProvider);
  final api = HttpMentorApi(ref.watch(apiClientProvider));
  ref.onDispose(api.cancel);
  return api;
});

class MentorConversationState {
  const MentorConversationState({
    this.sessionId,
    this.messages = const [],
    this.loading = false,
    this.error,
  });
  final String? sessionId;
  final List<MentorMessage> messages;
  final bool loading;
  final String? error;
  MentorConversationState copyWith({
    String? sessionId,
    List<MentorMessage>? messages,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => MentorConversationState(
    sessionId: sessionId ?? this.sessionId,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

/// A confirmed result of this send, not merely the last item in the history.
/// Only a newly allocated chat operation with a previously unseen answer may
/// carry the optional voice intent. Reconciliation/replay never authorizes TTS.
class MentorSendResult {
  const MentorSendResult({
    required this.sessionId,
    required this.reply,
    required this.newReply,
  });
  final String sessionId;
  final MentorMessage reply;
  final bool newReply;
}

class MentorConversation extends StateNotifier<MentorConversationState> {
  MentorConversation(this._api, this._registry)
    : super(const MentorConversationState());
  final MentorApi _api;
  final MentorOperationRegistry _registry;
  static const _uuid = Uuid();
  int _generation = 0;
  bool _valid(int generation) => mounted && generation == _generation;
  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  void cancel() {
    _generation++;
    _api.cancel();
    if (mounted) state = const MentorConversationState();
  }

  Future<void> openLatest() async {
    final generation = ++_generation;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final sessions = await _api.sessions();
      if (generation != _generation || !mounted) return;
      final id = sessions.isEmpty
          ? await _api.createSession(_uuid.v4())
          : sessions.first.id;
      if (!_valid(generation)) return;
      final messages = await _api.messages(id);
      if (generation != _generation || !mounted) return;
      state = MentorConversationState(sessionId: id, messages: messages);
    } catch (_) {
      if (!_valid(generation)) return;
      state = state.copyWith(
        loading: false,
        error: 'Nie udało się otworzyć rozmowy.',
      );
    }
  }

  Future<MentorSendResult?> send(
    String text, {
    bool regenerate = false,
    MentorContextSelection? context,
    int? settingsRevision,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 2000 || state.loading) return null;
    if (state.sessionId == null) {
      await openLatest();
      if (!mounted) return null;
    }
    final id = state.sessionId;
    if (id == null) return null;
    final generation = ++_generation;
    final local = MentorMessage(
      id: 'local-${_uuid.v4()}',
      role: 'user',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, local],
      loading: true,
      clearError: true,
    );
    try {
      final operation = await _registry.resolve(
        _api,
        'chat',
        sessionId: id,
        text: trimmed,
        selection: context?.toJson() ?? const {},
        regenerate: regenerate,
      );
      if (!_valid(generation)) return null;
      if (operation.response != null) {
        final messages = await _api.messages(id);
        if (!_valid(generation)) return null;
        state = state.copyWith(messages: messages, loading: false);
        return MentorSendResult(
          sessionId: id,
          reply: operation.response!,
          newReply: false,
        );
      }
      if (operation.state != 'new' && operation.state != 'unknown') {
        throw const MentorException('result_unavailable');
      }
      late final MentorMessage reply;
      try {
        reply = await _api.send(
          id,
          trimmed,
          requestId: operation.requestId,
          settingsRevision: settingsRevision,
          context: context,
        );
      } on MentorContextSelectionUnavailable {
        if (!_valid(generation)) return null;
        // Never forget an earlier ambiguous paid attempt, even if its retry
        // now encounters a stale selector before reserve.
        var cleaned = false;
        try {
          await _registry.discardRejectedNew(operation);
          cleaned = operation.state == 'new';
        } catch (_) {
          // Storage failure is fail-closed: retain the ledger protection.
        }
        if (!_valid(generation)) return null;
        state = state.copyWith(
          messages: state.messages.where((m) => m.id != local.id).toList(),
          loading: false,
          error:
              'Wybrany kontekst jest już niedostępny. Ta próba została odrzucona przed wysłaniem do dostawcy. Odśwież podgląd przyciskiem dodawania kontekstu, wybierz dane ponownie i potwierdź wysłanie.'
              '${cleaned
                  ? ''
                  : operation.state == 'new'
                  ? ' Nie udało się wyczyścić lokalnego wpisu operacji; jego ochrona pozostaje aktywna.'
                  : ' Wynik wcześniejszej próby pozostaje nieznany; jej rejestr został zachowany. Nowa operacja wymaga osobnego potwierdzenia limitu i kosztu.'}',
        );
        return null;
      }
      if (generation != _generation || !mounted) return null;
      final newReply =
          operation.state == 'new' &&
          reply.isAssistant &&
          !state.messages.any((message) => message.id == reply.id);
      state = state.copyWith(
        messages: [...state.messages, reply],
        loading: false,
      );
      return MentorSendResult(sessionId: id, reply: reply, newReply: newReply);
    } catch (_) {
      if (generation != _generation || !mounted) return null;
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != local.id).toList(),
        loading: false,
        error:
            'Najpierw sprawdzamy wynik na serwerze. Ponów tę samą treść bez nowego kosztu. Nowe generowanie wymaga potwierdzenia limitu i kosztu.',
      );
      return null;
    }
  }

  Future<void> newConversation() async {
    final generation = ++_generation;
    state = const MentorConversationState(loading: true);
    try {
      final id = await _api.createSession(_uuid.v4());
      if (!_valid(generation)) return;
      state = MentorConversationState(sessionId: id);
    } catch (_) {
      if (!_valid(generation)) return;
      state = const MentorConversationState(
        error: 'Nie udało się utworzyć rozmowy.',
      );
    }
  }

  Future<void> open(String id) async {
    final generation = ++_generation;
    state = const MentorConversationState(loading: true);
    try {
      final messages = await _api.messages(id);
      if (!_valid(generation)) return;
      state = MentorConversationState(sessionId: id, messages: messages);
    } catch (_) {
      if (_valid(generation)) {
        state = const MentorConversationState(
          error: 'Nie udało się otworzyć rozmowy.',
        );
      }
    }
  }

  Future<void> deleteCurrent() async {
    final id = state.sessionId;
    if (id == null) return;
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    try {
      await _api.deleteSession(id);
      if (!_valid(generation)) return;
      state = const MentorConversationState();
    } catch (_) {
      if (_valid(generation)) {
        state = state.copyWith(
          loading: false,
          error: 'Nie udało się usunąć rozmowy.',
        );
      }
    }
  }
}

final mentorConversationProvider =
    StateNotifierProvider.autoDispose<
      MentorConversation,
      MentorConversationState
    >((ref) {
      final conversation = MentorConversation(
        ref.watch(mentorApiProvider),
        ref.watch(mentorOperationRegistryProvider),
      );
      return conversation;
    });
