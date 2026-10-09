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
MentorSettings mentorSettings({
  bool enabled = true,
  String persona = 'Wspieraj spokojnie.',
  int revision = 4,
  MentorContextConsents consents = const MentorContextConsents(),
  bool contextConsentsActive = true,
}) => MentorSettings.fromJson({
  'available': enabled,
  'openai_configured': enabled,
  'elevenlabs_configured': enabled,
  'consent_text': enabled,
  'consent_voice': enabled,
  'persona': persona,
  'revision': revision,
  'context_policy_version': 1,
  'context_consents_active': contextConsentsActive,
  'active_model_profile_key': 'gpt-6-luna',
  'model_profiles': [
    {
      'key': 'gpt-6-luna',
      'identifier': 'gpt-6-luna',
      'label': 'GPT-6 Luna',
      'quality_class': 'ekonomiczny',
      'cost_warning': 'Niski koszt do codziennych rozmów.',
    },
  ],
  'context_consents': {
    'training': consents.training,
    'profile': consents.profile,
    'weight': consents.weight,
    'note': consents.note,
    'apple_health': consents.appleHealth,
  },
});

MentorSettings settings({bool enabled = true}) =>
    mentorSettings(enabled: enabled);

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
  int sends = 0,
      queries = 0,
      cancelled = 0,
      deleted = 0,
      speechCalls = 0,
      transcriptions = 0;
  final requestIds = <String>[];
  Completer<MentorMessage>? pending;
  Completer<void>? keyPending;
  bool fail = false;
  bool settingsConflict = false;
  String? savedKey;
  int settingsCalls = 0;
  final savedSettings = <Map<String, Object?>>[];
  @override
  void cancel() {
    cancelled++;
  }

  @override
  Future<MentorSettings> settings() async {
    settingsCalls++;
    return mentorSettings();
  }

  @override
  Future<MentorSettings> saveSettings(Map<String, Object?> patch) async {
    savedSettings.add(Map<String, Object?>.from(patch));
    if (settingsConflict) throw const MentorException('settings_conflict');
    return mentorSettings();
  }

  @override
  Future<MentorContextOptions> contextOptions() async =>
      MentorContextOptions.fromJson({
        'settings_revision': 4,
        'options': {
          'training': {'available': true, 'summary': 'Ostatnie 12 tygodni'},
          'profile': {'available': true},
          'weight': [
            {
              'selection_id': 'opaque-weight-selector-that-is-long-enough',
              'source': 'measurement',
              'summary': '72 kg · 2026-10-08',
            },
          ],
          'workout_notes': [
            {
              'selection_id': 'opaque-note-selector-that-is-long-enough',
              'summary': '2026-10-07',
              'preview': 'Dobra energia',
            },
          ],
          'apple_health': {'available': true},
        },
      });

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
    int? settingsRevision,
    MentorContextSelection? context,
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
  }) async {
    transcriptions++;
    return 'Tekst do poprawienia';
  }

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
  bool rejectNextPlay = false;
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
    if (rejectNextPlay) {
      rejectNextPlay = false;
      throw StateError('autoplay denied');
    }
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
  MentorSettings? configuredSettings,
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
          (ref) async => configuredSettings ?? mentorSettings(enabled: enabled),
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
  testWidgets(
    'context composer previews only consented categories and requires final confirmation',
    (tester) async {
      await mount(
        tester,
        ApiFake(),
        VoiceFake(),
        configuredSettings: mentorSettings(
          consents: const MentorContextConsents(
            training: true,
            profile: true,
            weight: true,
            note: true,
            appleHealth: true,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Sprawdź mój plan');
      await tester.pump();
      await tester.tap(find.byTooltip('Dodaj kontekst do tej wiadomości'));
      await tester.pumpAndSettle();

      expect(find.text('Kontekst tej wiadomości'), findsOneWidget);
      expect(find.text('Kontekst treningowy'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Kontekst treningowy'),
            )
            .value,
        isTrue,
      );
      expect(find.text('Wyślij z tym kontekstem'), findsOneWidget);
      expect(
        find.textContaining('Persona i wybrane kategorie trafiają do OpenAI'),
        findsOneWidget,
      );
      expect(
        find.textContaining('store:false nie gwarantuje zerowej retencji'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Usunięcie rozmowy nie cofa danych'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'context composer requires a non-whitespace message before it opens',
    (tester) async {
      await mount(tester, ApiFake(), VoiceFake());

      final contextButton = find.ancestor(
        of: find.byTooltip('Dodaj kontekst do tej wiadomości'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(contextButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '   \n  ');
      await tester.pump();
      expect(tester.widget<IconButton>(contextButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Sprawdź mój plan');
      await tester.pump();
      expect(tester.widget<IconButton>(contextButton).onPressed, isNotNull);

      await tester.tap(find.byTooltip('Dodaj kontekst do tej wiadomości'));
      await tester.pumpAndSettle();
      expect(find.text('Kontekst tej wiadomości'), findsOneWidget);
    },
  );
  testWidgets('settings send independent persona and context-consent patches', (
    tester,
  ) async {
    final api = ApiFake();
    await mount(tester, api, VoiceFake());
    await tester.tap(find.byTooltip('Ustawienia mentora'));
    await tester.pumpAndSettle();

    final persona = find.widgetWithText(TextField, 'Persona mentora');
    expect(
      tester.widget<TextField>(persona).controller!.text,
      'Wspieraj spokojnie.',
    );
    await tester.enterText(persona, '');
    await tester.tap(find.text('Zapisz personę'));
    await tester.pumpAndSettle();
    expect(api.savedSettings, [
      {'expected_revision': 4, 'persona': ''},
    ]);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Kontekst treningowy'),
    );
    await tester.pumpAndSettle();
    expect(api.savedSettings.last, {
      'expected_revision': 4,
      'context_consents': {'training': true},
    });
  });
  testWidgets(
    'settings require explicit full context consent acknowledgement after restore',
    (tester) async {
      final api = ApiFake();
      await mount(
        tester,
        api,
        VoiceFake(),
        configuredSettings: mentorSettings(contextConsentsActive: false),
      );
      await tester.tap(find.byTooltip('Ustawienia mentora'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('przywróceniu danych lub zmianie polityki'),
        findsOneWidget,
      );
      await tester.tap(find.text('Przejrzyj i zatwierdź zgody kontekstu'));
      await tester.pumpAndSettle();
      expect(find.text('Potwierdź zgody kontekstu'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Kontekst treningowy'),
      );
      await tester.tap(find.text('Potwierdź komplet zgód'));
      await tester.pumpAndSettle();

      expect(api.savedSettings, [
        {
          'expected_revision': 4,
          'context_policy_version': 1,
          'context_consents': {
            'training': true,
            'profile': false,
            'weight': false,
            'note': false,
            'apple_health': false,
          },
        },
      ]);
    },
  );
  testWidgets(
    'model selection explains quality and cost before sending a patch',
    (tester) async {
      final api = ApiFake();
      await mount(tester, api, VoiceFake());
      await tester.tap(find.byTooltip('Ustawienia mentora'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Model mentora'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Model mentora'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SimpleDialogOption));
      await tester.pumpAndSettle();
      expect(find.text('GPT-6 Luna'), findsWidgets);
      expect(find.textContaining('ekonomiczny'), findsOneWidget);
      expect(find.textContaining('Niski koszt'), findsOneWidget);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(api.savedSettings, isEmpty);

      await tester.tap(find.text('Model mentora'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SimpleDialogOption));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wybierz model'));
      await tester.pumpAndSettle();
      expect(api.savedSettings, [
        {'expected_revision': 4, 'model_profile_key': 'gpt-6-luna'},
      ]);
    },
  );
  testWidgets(
    'too long persona is blocked locally and a conflict refreshes settings',
    (tester) async {
      final api = ApiFake();
      await mount(tester, api, VoiceFake());
      await tester.tap(find.byTooltip('Ustawienia mentora'));
      await tester.pumpAndSettle();

      final persona = find.widgetWithText(TextField, 'Persona mentora');
      await tester.enterText(persona, 'x' * 801);
      await tester.tap(find.text('Zapisz personę'));
      await tester.pumpAndSettle();
      expect(api.savedSettings, isEmpty);
      expect(
        find.text('Persona mentora może mieć maksymalnie 800 znaków.'),
        findsOneWidget,
      );

      await tester.enterText(persona, 'Nowa persona');
      api.settingsConflict = true;
      await tester.tap(find.text('Zapisz personę'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.savedSettings.single, {
        'expected_revision': 4,
        'persona': 'Nowa persona',
      });
      expect(api.settingsCalls, 1);
      expect(
        find.textContaining('zmienione na innym urządzeniu'),
        findsOneWidget,
      );
    },
  );
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
    'voice turn transcribes, sends, prepares and plays the assistant reply',
    (tester) async {
      final api = ApiFake();
      final voice = VoiceFake();
      await mount(tester, api, voice);

      await tester.tap(find.byTooltip('Nagraj wiadomość'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zakończ nagranie'));
      await tester.pumpAndSettle();

      expect(api.transcriptions, 1);
      expect(api.sends, 1);
      expect(api.speechCalls, 1);
      expect(voice.prepares, 1);
      expect(voice.plays, 1);
      expect(find.text('Tekst do poprawienia'), findsOneWidget);
      expect(find.text('Odpowiedź mentora'), findsWidgets);
    },
  );
  testWidgets('typed text sends without preparing or playing speech', (
    tester,
  ) async {
    final api = ApiFake();
    final voice = VoiceFake();
    await mount(tester, api, voice);

    await tester.enterText(find.byType(TextField), 'Wiadomość pisana');
    await tester.tap(find.byTooltip('Wyślij'));
    await tester.pumpAndSettle();

    expect(api.sends, 1);
    expect(voice.prepares, 0);
    expect(voice.plays, 0);
  });
  testWidgets(
    'voice turn keeps prepared speech for manual playback after autoplay denial',
    (tester) async {
      final api = ApiFake();
      final voice = VoiceFake()..rejectNextPlay = true;
      await mount(tester, api, voice);

      await tester.tap(find.byTooltip('Nagraj wiadomość'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zakończ nagranie'));
      await tester.pumpAndSettle();

      expect(api.speechCalls, 1);
      expect(voice.prepares, 1);
      expect(voice.plays, 1);
      expect(find.text('Odtwórz'), findsOneWidget);

      await tester.tap(find.text('Odtwórz'));
      await tester.pump();

      expect(api.speechCalls, 1);
      expect(voice.plays, 2);
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
