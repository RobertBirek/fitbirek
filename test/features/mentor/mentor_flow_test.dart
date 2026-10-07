import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_operations.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_page.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_settings_page.dart';
import 'package:fitbirek_training/features/mentor/voice/mentor_voice.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_actions.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/core/models/exercise.dart';

const exercise = Exercise(
  id: 'cw001',
  nazwaPl: 'Przysiad',
  nazwaEn: '',
  partiaGlowna: '',
  partieWspierajace: [],
  sprzet: [],
  typ: '',
  poziom: '',
  wzorzecRuchu: '',
  seriexPowtorzenia: '',
  tempo: '',
  kluczoweWskazowki: [],
  czesteBledy: [],
  progresja: '',
  regresja: '',
  zrodlo: '',
);

class ActionsFake implements MentorActions {
  int calls = 0;
  double? weight;
  int? repetitions;
  @override
  Future<MentorActionResult> confirm(
    MentorProposal proposal, {
    required String accountId,
    required int? expectedSessionId,
    double? weightKg,
    int? reps,
  }) async {
    calls++;
    weight = weightKg;
    repetitions = reps;
    expect(accountId, 'a');
    return MentorActionResult.applied;
  }
}

class AuthApiFake implements AuthApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuthFake extends AuthController {
  AuthFake() : super(AuthApiFake()) {
    state = const AuthState.signedIn('a');
  }
  void switchAccount() => state = const AuthState.signedIn('b');
}

MentorMessage reply() => MentorMessage(
  id: 'answer',
  role: 'assistant',
  text: 'Odpowiedź mentora',
  createdAt: DateTime(2026),
);
MentorSettings settings({bool enabled = true}) => MentorSettings.fromJson({
  'available': enabled,
  'openai_configured': enabled,
  'elevenlabs_configured': enabled,
  'consent_text': enabled,
  'consent_voice': enabled,
});

class ApiFake implements MentorApi {
  bool lostPaidResponse = false, expiredSpeech = false;
  final ledger = <String, MentorOperation>{};
  final voiceRequestIds = <String>[];
  @override
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  }) async => ledger.values.toList();
  @override
  Future<MentorOperation?> operation(String requestId) async =>
      ledger[requestId];
  MentorProposal? proposal;
  int sends = 0, queries = 0, cancelled = 0, deleted = 0, speechCalls = 0;
  final requestIds = <String>[];
  Completer<MentorMessage>? pending;
  Completer<void>? keyPending;
  bool fail = false;
  String? savedKey;
  @override
  void cancel() {
    cancelled++;
  }

  @override
  Future<MentorSettings> settings() async => MentorSettings.fromJson({});
  @override
  Future<List<MentorSession>> sessions() async {
    queries++;
    return [MentorSession(id: 'session', createdAt: DateTime(2026))];
  }

  @override
  Future<String> createSession(String id) async => id;
  @override
  Future<List<MentorMessage>> messages(String id) async => [
    MentorMessage(
      id: 'answer',
      role: 'assistant',
      text: 'Odpowiedź mentora',
      createdAt: DateTime(2026),
      proposal: proposal,
    ),
  ];
  @override
  Future<MentorMessage> send(
    String id,
    String text, {
    required String requestId,
  }) async {
    sends++;
    requestIds.add(requestId);
    if (lostPaidResponse) {
      ledger[requestId] = MentorOperation(
        requestId: requestId,
        kind: 'chat',
        state: 'complete',
        sessionId: id,
        userText: text,
        response: reply(),
      );
      throw const MentorException();
    }
    if (fail) throw const MentorException();
    return pending == null ? reply() : pending!.future;
  }

  @override
  Future<void> deleteSession(String id) async {
    deleted++;
  }

  @override
  Future<String> transcribe(
    Uint8List bytes,
    String type,
    double duration, {
    required String requestId,
  }) async => 'Tekst do poprawienia';
  @override
  Future<Uint8List> speech(String id, {required String requestId}) async {
    speechCalls++;
    voiceRequestIds.add(requestId);
    if (expiredSpeech && speechCalls == 1) {
      throw const MentorException('result_unavailable');
    }
    expect(id, 'answer');
    return Uint8List(1);
  }

  @override
  Future<void> saveKey(String provider, String key) async {
    savedKey = key;
    await keyPending?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VoiceFake implements MentorVoice {
  int prepares = 0, plays = 0, stops = 0, disposals = 0;
  @override
  bool get supported => true;
  @override
  Future<void> startRecording() async {}
  @override
  Future<MentorRecording> stopRecording() async => MentorRecording(
    bytes: Uint8List(1),
    contentType: 'audio/webm',
    durationSeconds: 1,
  );
  @override
  void cancelRecording() {}
  @override
  Future<void> preparePlayback(Uint8List bytes) async {
    prepares++;
  }

  @override
  Future<void> play() async {
    plays++;
  }

  @override
  void stopPlayback() {
    stops++;
  }

  @override
  void dispose() {
    disposals++;
  }
}

Future<void> mount(
  WidgetTester tester,
  ApiFake api,
  VoiceFake voice, {
  bool enabled = true,
  AuthFake? auth,
  ActionsFake? actions,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(
          body: shell,
          bottomNavigationBar: Row(
            children: [
              TextButton(
                onPressed: () => shell.goBranch(0),
                child: const Text('Dziś'),
              ),
              TextButton(
                onPressed: () => shell.goBranch(1),
                child: const Text('Inna zakładka'),
              ),
            ],
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/today', builder: (_, _) => const MentorPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/other',
                builder: (_, _) => const Scaffold(body: Text('Inny panel')),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/today/classic',
        builder: (_, _) => const Scaffold(body: Text('Klasyczny panel')),
      ),
      GoRoute(
        path: '/settings/mentor',
        builder: (_, _) => const MentorSettingsPage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => auth ?? AuthFake()),
        mentorApiProvider.overrideWith((ref) {
          ref.watch(authStateProvider);
          ref.onDispose(api.cancel);
          return api;
        }),
        mentorSettingsProvider.overrideWith(
          (ref) async => settings(enabled: enabled),
        ),
        mentorVoiceProvider.overrideWithValue(voice),
        mentorVoiceApiProvider.overrideWithValue(api),
        if (actions != null) mentorActionsProvider.overrideWithValue(actions),
        allExercisesProvider.overrideWith((ref) => Stream.value([exercise])),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'lost paid chat response survives tab navigation and repeated Send without another POST',
    (tester) async {
      final api = ApiFake()..lostPaidResponse = true;
      await mount(tester, api, VoiceFake());
      await tester.enterText(find.byType(TextField), 'Ta sama treść');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      expect(api.sends, 1);
      await tester.tap(find.text('Inna zakładka'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dziś'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ta sama treść');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      expect(api.sends, 1);
      expect(find.text('Odpowiedź mentora'), findsOneWidget);
    },
  );
  testWidgets(
    'expired TTS requires explicit cost confirmation before a new UUID',
    (tester) async {
      final api = ApiFake()..expiredSpeech = true;
      await mount(tester, api, VoiceFake());
      await tester.tap(find.byTooltip('Przygotuj głos'));
      await tester.pumpAndSettle();
      expect(api.speechCalls, 1);
      expect(find.text('Nowa płatna operacja'), findsOneWidget);
      await tester.tap(
        find.text('Wygeneruj ponownie — ponowne użycie limitu i koszt'),
      );
      await tester.pumpAndSettle();
      expect(api.speechCalls, 2);
      expect(api.voiceRequestIds.toSet().length, 2);
      expect(find.text('Odtwórz'), findsOneWidget);
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('narrow viewport leaves conversation composer accessible', (
    tester,
  ) async {
    await mount(tester, ApiFake(), VoiceFake());
    await tester.binding.setSurfaceSize(const Size(375, 550));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Krótki szkic');
    expect(find.byTooltip('Wyślij'), findsOneWidget);
  });
  testWidgets('offstage tab cancels pending response and resets private draft', (
    tester,
  ) async {
    final api = ApiFake();
    final voice = VoiceFake();
    await mount(tester, api, voice);
    api.pending = Completer();
    await tester.enterText(find.byType(TextField), 'Szkic przed zmianą');
    await tester.tap(find.byTooltip('Wyślij'));
    await tester.pump();
    await tester.tap(find.text('Inna zakładka'));
    await tester.pumpAndSettle();
    expect(api.cancelled, greaterThan(0));
    expect(
      voice.disposals,
      greaterThan(0),
      reason:
          'Leaving an offstage page must revoke audio URLs, not only pause playback',
    );
    api.pending!.complete(
      MentorMessage(
        id: 'late',
        role: 'assistant',
        text: 'Spóźniona odpowiedź',
        createdAt: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dziś'));
    await tester.pumpAndSettle();
    expect(find.text('Szkic przed zmianą'), findsNothing);
    expect(find.text('Spóźniona odpowiedź'), findsNothing);
  });
  testWidgets(
    'proposal cancel makes no write and confirmation passes edited values',
    (tester) async {
      final api = ApiFake()
        ..proposal = const MentorProposal(
          id: 'proposal',
          kind: MentorProposalKind.logSet,
          exerciseId: 'cw001',
          weightKg: 20,
          reps: 8,
        );
      final actions = ActionsFake();
      await mount(tester, api, VoiceFake(), actions: actions);
      await tester.tap(find.text('Sprawdź i potwierdź'));
      await tester.pumpAndSettle();
      expect(find.text('Przysiad'), findsOneWidget);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(actions.calls, 0);
      await tester.tap(find.text('Sprawdź i potwierdź'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Ciężar (kg)'),
        '32,5',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Powtórzenia'),
        '12',
      );
      await tester.tap(find.text('Wykonaj'));
      await tester.pumpAndSettle();
      expect(actions.calls, 1);
      expect(actions.weight, 32.5);
      expect(actions.repetitions, 12);
    },
  );
  testWidgets('history picker and explicit delete operate on actual session', (
    tester,
  ) async {
    final api = ApiFake();
    await mount(tester, api, VoiceFake());
    await tester.tap(find.byTooltip('Historia rozmów'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SimpleDialogOption));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Usuń rozmowę'));
    await tester.pumpAndSettle();
    expect(api.deleted, 0);
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(api.deleted, 1);
    expect(find.text('Odpowiedź mentora'), findsNothing);
  });
  testWidgets('settings names recipients without automatic provider calls', (
    tester,
  ) async {
    final api = ApiFake();
    await mount(tester, api, VoiceFake(), enabled: false);
    await tester.tap(find.byTooltip('Ustawienia mentora'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OpenAI otrzymuje'), findsOneWidget);
    expect(find.textContaining('ElevenLabs otrzymuje'), findsOneWidget);
    expect(api.queries, 0);
    expect(api.sends, 0);
    expect(api.speechCalls, 0);
  });
  test(
    'ambiguous retry preserves request ID and cancellation rejects late reply',
    () async {
      final api = ApiFake();
      final controller = MentorConversation(api, MentorOperationRegistry('a'));
      await controller.openLatest();
      api.fail = true;
      await controller.send('Test');
      await controller.send('Test');
      expect(api.requestIds.toSet(), hasLength(1));
      api.fail = false;
      api.pending = Completer();
      final sending = controller.send('Test');
      controller.cancel();
      api.pending!.complete(reply());
      await sending;
      expect(controller.state.messages, isEmpty);
      expect(api.cancelled, 1);
      controller.dispose();
    },
  );
  test('history deletion clears session and messages', () async {
    final api = ApiFake();
    final controller = MentorConversation(api, MentorOperationRegistry('a'));
    await controller.open('session');
    api.pending = Completer();
    final sending = controller.send('Wiadomość w toku');
    await controller.deleteCurrent();
    api.pending!.complete(reply());
    await sending;
    expect(api.deleted, 1);
    expect(controller.state.sessionId, isNull);
    expect(controller.state.messages, isEmpty);
    controller.dispose();
  });
  testWidgets(
    'disabled Today never opens history and classic stays reachable',
    (tester) async {
      final api = ApiFake();
      await mount(tester, api, VoiceFake(), enabled: false);
      expect(api.queries, 0);
      await tester.tap(find.text('Klasyczny trening (offline)').first);
      await tester.pumpAndSettle();
      expect(find.text('Klasyczny panel'), findsOneWidget);
    },
  );
  testWidgets(
    'transcript is editable and speech requires separate play gesture',
    (tester) async {
      final api = ApiFake();
      final voice = VoiceFake();
      await mount(tester, api, voice);
      await tester.tap(find.byTooltip('Nagraj wiadomość'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zakończ nagranie'));
      await tester.pumpAndSettle();
      expect(find.text('Tekst do poprawienia'), findsOneWidget);
      expect(api.sends, 0);
      await tester.enterText(find.byType(TextField), 'Poprawiony tekst');
      await tester.tap(find.byTooltip('Przygotuj głos'));
      await tester.pumpAndSettle();
      expect(voice.prepares, 1);
      expect(voice.plays, 0);
      await tester.tap(find.text('Odtwórz'));
      await tester.pump();
      expect(voice.plays, 1);
      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(voice.stops, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('account transition removes draft and discards late answer', (
    tester,
  ) async {
    final api = ApiFake();
    final auth = AuthFake();
    await mount(tester, api, VoiceFake(), auth: auth);
    api.pending = Completer();
    await tester.enterText(find.byType(TextField), 'Prywatny szkic');
    await tester.tap(find.byTooltip('Wyślij'));
    await tester.pump();
    auth.switchAccount();
    await tester.pumpAndSettle();
    api.pending!.complete(
      MentorMessage(
        id: 'late',
        role: 'assistant',
        text: 'TAJNA SPÓŹNIONA',
        createdAt: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prywatny szkic'), findsNothing);
    expect(find.text('TAJNA SPÓŹNIONA'), findsNothing);
    expect(api.cancelled, greaterThan(0));
  });
  testWidgets('key clears before pending save and dismissal', (tester) async {
    final api = ApiFake()..keyPending = Completer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith((ref) => AuthFake())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => MentorKeyDialog(
                  provider: 'openai',
                  configured: false,
                  api: api,
                ),
              ),
              child: const Text('Otwórz'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otwórz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'test-secret');
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    await tester.tap(find.text('Zapisz'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(api.savedKey, 'test-secret');
    api.keyPending!.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), 'cancel-secret');
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(find.text('cancel-secret'), findsNothing);
    await tester.tap(find.text('Otwórz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hidden-secret');
    final hiddenController = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(hiddenController.text, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Otwórz'), findsOneWidget);
    expect(find.text('hidden-secret'), findsNothing);
  });
}
