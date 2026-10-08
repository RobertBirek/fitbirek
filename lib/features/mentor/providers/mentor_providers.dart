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

  Future<void> send(
    String text, {
    bool regenerate = false,
    MentorContextSelection? context,
    int? settingsRevision,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 2000 || state.loading) return;
    if (state.sessionId == null) {
      await openLatest();
      if (!mounted) return;
    }
    final id = state.sessionId;
    if (id == null) return;
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
      if (!_valid(generation)) return;
      if (operation.response != null) {
        final messages = await _api.messages(id);
        if (!_valid(generation)) return;
        state = state.copyWith(messages: messages, loading: false);
        return;
      }
      if (operation.state != 'new' && operation.state != 'unknown') {
        throw const MentorException('result_unavailable');
      }
      final reply = await _api.send(
        id,
        trimmed,
          requestId: operation.requestId,
          settingsRevision: settingsRevision,
          context: context,
      );
      if (generation != _generation || !mounted) return;
      state = state.copyWith(
        messages: [...state.messages, reply],
        loading: false,
      );
    } catch (_) {
      if (generation != _generation || !mounted) return;
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != local.id).toList(),
        loading: false,
        error:
            'Najpierw sprawdzamy wynik na serwerze. Ponów tę samą treść bez nowego kosztu. Nowe generowanie wymaga potwierdzenia limitu i kosztu.',
      );
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
