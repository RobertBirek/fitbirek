import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_operations.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';

class DebitedApi implements MentorApi {
  final ledger = <String, MentorOperation>{};
  int debits = 0, posts = 0;
  bool failStatus = false, loseResponse = true, pending = false;
  final answer = MentorMessage(
    id: 'answer',
    role: 'assistant',
    text: 'Odpowiedź',
    createdAt: DateTime(2026),
  );
  @override
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  }) async {
    if (failStatus) throw const MentorException();
    return ledger.values
        .toList()
        .reversed
        .where((o) => sessionId == null || o.sessionId == sessionId)
        .toList();
  }

  @override
  Future<MentorOperation?> operation(String id) async {
    if (failStatus) throw const MentorException();
    return ledger[id];
  }

  @override
  Future<List<MentorMessage>> messages(String sessionId) async =>
      ledger.values.any((o) => o.response != null) ? [answer] : [];
  @override
  Future<MentorMessage> send(
    String sessionId,
    String text, {
    required String requestId,
    int? settingsRevision,
    MentorContextSelection? context,
  }) async {
    posts++;
    if (!ledger.containsKey(requestId)) {
      debits++;
      ledger[requestId] = MentorOperation(
        requestId: requestId,
        kind: 'chat',
        state: pending ? 'reserved' : 'complete',
        sessionId: sessionId,
        userText: text,
        response: pending ? null : answer,
      );
    }
    if (loseResponse) throw const MentorException();
    return answer;
  }

  @override
  Future<Uint8List> speech(
    String messageId, {
    required String requestId,
  }) async {
    posts++;
    if (ledger.containsKey(requestId)) {
      throw const MentorException('result_unavailable');
    }
    debits++;
    ledger[requestId] = MentorOperation(
      requestId: requestId,
      kind: 'tts',
      state: 'complete',
      subjectId: messageId,
    );
    if (loseResponse) throw const MentorException();
    return Uint8List(1);
  }

  @override
  void cancel() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'a confirmed replacement does not make old failures block every later new message',
    () async {
      final api = DebitedApi()..pending = true;
      final controller = MentorConversation(
        api,
        MentorOperationRegistry('account-a'),
      );
      await controller.open('session');
      await controller.send('Pierwsza próba');
      final first = api.ledger.keys.single;
      api.ledger[first] = MentorOperation(
        requestId: first,
        kind: 'chat',
        state: 'failed',
        sessionId: 'session',
        userText: 'Pierwsza próba',
        createdAt: DateTime(2026, 9, 1),
      );
      api.pending = api.loseResponse = false;
      await controller.send('Świadomie zmieniona treść', regenerate: true);
      final second = api.ledger.keys.last;
      api.ledger[second] = MentorOperation(
        requestId: second,
        kind: 'chat',
        state: 'complete',
        sessionId: 'session',
        userText: 'Świadomie zmieniona treść',
        response: api.answer,
        createdAt: DateTime(2026, 9, 2),
      );
      await controller.send('Kolejna nowa wiadomość');
      expect(api.debits, 3);
      expect(controller.state.error, isNull);
      controller.dispose();
    },
  );

  test(
    'debit then lost chat response: repeated click, navigation and reload recover without paid POST',
    () async {
      final api = DebitedApi();
      var registry = MentorOperationRegistry('account-a');
      var controller = MentorConversation(api, registry);
      await controller.open('session');
      await controller.send('Prywatny tekst');
      expect(controller.state.error, isNotNull);
      await controller.send('Prywatny tekst');
      expect(controller.state.messages.single.id, 'answer');
      expect(api.debits, 1);
      expect(api.posts, 1);
      controller.dispose();
      controller = MentorConversation(api, registry);
      await controller.open('session');
      await controller.send('Prywatny tekst');
      controller.dispose();
      registry.dispose();
      registry = MentorOperationRegistry('account-a');
      controller = MentorConversation(api, registry);
      await controller.open('session');
      await controller.send('Prywatny tekst');
      expect(api.posts, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(registry.storageKey),
        isNot(contains('Prywatny tekst')),
      );
      // Browser storage cleared / logout-login: server remains authoritative.
      await prefs.clear();
      controller.dispose();
      controller = MentorConversation(
        api,
        MentorOperationRegistry('account-a'),
      );
      await controller.open('session');
      await controller.send('Prywatny tekst');
      expect(api.posts, 1);
      controller.dispose();
    },
  );

  test(
    'first GET failure never allocates an ID or makes a paid call, even confirmed regeneration',
    () async {
      final api = DebitedApi()..failStatus = true;
      final registry = MentorOperationRegistry('account-a');
      for (final kind in ['chat', 'tts', 'stt']) {
        for (final regenerate in [false, true]) {
          await expectLater(
            registry.resolve(api, kind, regenerate: regenerate),
            throwsA(isA<MentorException>()),
          );
        }
      }
      final controller = MentorConversation(api, registry);
      await controller.open('session');
      await controller.send('Treść');
      expect(api.posts, 0);
      expect(
        (await SharedPreferences.getInstance()).getString(registry.storageKey),
        isNull,
      );
      controller.dispose();
    },
  );

  test(
    'reserved chat after reload blocks same and edited text; confirmation alone permits new ID',
    () async {
      final api = DebitedApi()..pending = true;
      var controller = MentorConversation(api, MentorOperationRegistry('a'));
      await controller.open('session');
      await controller.send('Treść');
      controller.dispose();
      controller = MentorConversation(api, MentorOperationRegistry('a'));
      await controller.open('session');
      await controller.send('Treść');
      await controller.send('Zmieniona treść');
      expect(api.posts, 1);
      await controller.send('Treść', regenerate: true);
      expect(api.debits, 2);
      expect(api.ledger.keys.toSet().length, 2);
      controller.dispose();
    },
  );

  test(
    'TTS expired bytes and storage loss recover subject ID; only confirmed regeneration debits again',
    () async {
      final api = DebitedApi();
      final registry = MentorOperationRegistry('a');
      final first = await registry.resolve(api, 'tts', subjectId: 'answer');
      await expectLater(
        api.speech('answer', requestId: first.requestId),
        throwsA(isA<MentorException>()),
      );
      await (await SharedPreferences.getInstance()).clear();
      final reloaded = MentorOperationRegistry('a');
      final recovered = await reloaded.resolve(api, 'tts', subjectId: 'answer');
      expect(recovered.requestId, first.requestId);
      await expectLater(
        api.speech('answer', requestId: recovered.requestId),
        throwsA(
          isA<MentorException>().having(
            (e) => e.code,
            'code',
            'result_unavailable',
          ),
        ),
      );
      expect(api.debits, 1);
      final renewed = await reloaded.resolve(
        api,
        'tts',
        subjectId: 'answer',
        regenerate: true,
      );
      expect(renewed.requestId, isNot(first.requestId));
      api.loseResponse = false;
      await api.speech('answer', requestId: renewed.requestId);
      expect(api.debits, 2);
    },
  );

  test(
    'unresolved local operation keeps ID after metadata reload and account scopes never share IDs',
    () async {
      final api = DebitedApi();
      final a = MentorOperationRegistry('a');
      final first = await a.resolve(
        api,
        'chat',
        sessionId: 'session',
        text: 'Treść',
      );
      a.dispose();
      final retry = await MentorOperationRegistry(
        'a',
      ).resolve(api, 'chat', sessionId: 'session', text: 'Treść');
      expect(retry.requestId, first.requestId);
      final other = await MentorOperationRegistry(
        'b',
      ).resolve(api, 'chat', sessionId: 'session', text: 'Treść');
      expect(other.requestId, isNot(first.requestId));
      await expectLater(
        a.resolve(api, 'chat'),
        throwsA(isA<MentorException>()),
      );
    },
  );

  test(
    'STT ambiguity after reload requires explicit new recording consent and stores no audio',
    () async {
      final api = DebitedApi();
      final first = await MentorOperationRegistry('a').resolve(api, 'stt');
      final registry = MentorOperationRegistry('a');
      await expectLater(
        registry.resolve(api, 'stt'),
        throwsA(
          isA<MentorException>().having(
            (e) => e.code,
            'code',
            'result_unavailable',
          ),
        ),
      );
      final renewed = await registry.resolve(api, 'stt', regenerate: true);
      expect(renewed.requestId, isNot(first.requestId));
      final raw = (await SharedPreferences.getInstance()).getString(
        registry.storageKey,
      )!;
      expect(raw, isNot(contains('audio')));
      expect(raw, isNot(contains('text')));
    },
  );
}
