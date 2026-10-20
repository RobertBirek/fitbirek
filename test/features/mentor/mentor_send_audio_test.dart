import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_page.dart';
import 'mentor_flow_test.dart' as f;
import 'mentor_usability_test.dart' show record;

class SendAudioApi extends f.ApiFake {
  MentorOperation? replay;
  bool returnOld = false;
  final spokenIds = <String>[];
  @override
  Future<MentorMessage> send(
    String id,
    String text, {
    required String requestId,
    int? settingsRevision,
    MentorContextSelection? context,
  }) async {
    final result = await super.send(
      id,
      text,
      requestId: requestId,
      settingsRevision: settingsRevision,
      context: context,
    );
    return returnOld ? (await messages(id)).single : result;
  }

  @override
  Future<List<MentorMessage>> messages(String id) async => [
    MentorMessage(
      id: 'old',
      role: 'assistant',
      text: 'Poprzednia odpowiedź',
      createdAt: DateTime(2026),
    ),
  ];
  @override
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  }) async => [if (kind == 'message' && replay != null) replay!];
  @override
  Future<Uint8List> speech(String id, {required String requestId}) async {
    spokenIds.add(id);
    speechCalls++;
    return Uint8List(1);
  }
}

Future<Map<String, Object?>> registry() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final text in ['', '  \n  ', 'oversize']) {
    testWidgets(
      'reviewed STT then invalid Send has no chat TTS or reservation: $text',
      (tester) async {
        final api = SendAudioApi();
        final voice = f.VoiceFake();
        await f.mount(tester, api, voice);
        await record(tester);
        final before = await registry();
        if (text == 'oversize') {
          tester.widget<TextField>(find.byType(TextField)).controller!.text =
              List.filled(2001, 'a').join();
        } else {
          await tester.enterText(find.byType(TextField), text);
        }
        await tester.pump();
        await tester.tap(find.byTooltip('Wyślij'));
        await tester.pumpAndSettle();
        expect(api.sends, 0);
        expect(api.speechCalls, 0);
        expect(voice.plays, 0);
        expect(await registry(), before);
        if (text != 'oversize') {
          expect(find.byTooltip('Anuluj transkrypcję'), findsNothing);
        }
      },
    );
  }
  for (final outcome in ['new', 'error', 'replay', 'unknown', 'old-id']) {
    testWidgets('voice Send plays only a confirmed new answer: $outcome', (
      tester,
    ) async {
      final api = SendAudioApi();
      final voice = f.VoiceFake();
      await f.mount(tester, api, voice);
      await record(tester);
      if (outcome == 'error') api.fail = true;
      if (outcome == 'old-id') api.returnOld = true;
      if (outcome == 'replay' || outcome == 'unknown') {
        api.replay = MentorOperation(
          requestId: 'previous-request',
          kind: 'chat',
          state: outcome == 'replay' ? 'complete' : 'unknown',
          sessionId: 'session',
          userText: 'Poprawiony szkic',
          response: outcome == 'replay'
              ? (await api.messages('session')).single
              : null,
        );
      }
      await tester.enterText(find.byType(TextField), 'Poprawiony szkic');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      expect(api.sends, outcome == 'replay' ? 0 : 1);
      expect(api.spokenIds, outcome == 'new' ? ['answer'] : isEmpty);
      expect(voice.plays, outcome == 'new' ? 1 : 0);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs
            .getKeys()
            .map((key) => prefs.get(key))
            .join()
            .contains('"kind":"tts"'),
        outcome == 'new',
      );
      if (outcome != 'replay') expect(api.sentTexts, ['Poprawiony szkic']);
    });
  }
  for (final action in ['edit', 'account', 'conversation', 'voice-consent']) {
    testWidgets(
      'pending voice Send respects current source and edited draft: $action',
      (tester) async {
        final api = SendAudioApi();
        final auth = f.AuthFake();
        final voice = f.VoiceFake();
        var settings = f.mentorSettings();
        await f.mount(
          tester,
          api,
          voice,
          auth: auth,
          loadSettings: () async => settings,
        );
        await record(tester);
        api.pending = Completer<MentorMessage>();
        await tester.tap(find.byTooltip('Wyślij'));
        await tester.pump();
        if (action == 'edit') {
          await tester.enterText(find.byType(TextField), 'Nowszy szkic');
        } else if (action == 'account') {
          auth.switchAccount();
        } else if (action == 'conversation') {
          await tester.tap(find.byTooltip('Usuń rozmowę'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Usuń'));
        } else if (action == 'voice-consent') {
          settings = MentorSettings.fromJson({
            'available': true,
            'openai_configured': true,
            'consent_text': true,
            'elevenlabs_configured': true,
            'consent_voice': false,
          });
          ProviderScope.containerOf(
            tester.element(find.byType(MentorPage)),
          ).invalidate(mentorSettingsProvider);
        }
        await tester.pumpAndSettle();
        api.pending!.complete(f.reply());
        await tester.pumpAndSettle();
        if (action == 'edit') {
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Nowszy szkic',
          );
        }
        if (action == 'account' ||
            action == 'conversation' ||
            action == 'voice-consent') {
          expect(api.spokenIds, isEmpty);
          expect(voice.plays, 0);
        }
      },
    );
  }
}
