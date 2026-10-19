import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/api/api_client.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_operations.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'mentor_flow_test.dart' as fixtures;

class RejectionAdapter implements HttpClientAdapter {
  int status = 409;
  Object body = {'detail': 'Context selection unavailable'};
  final posts = <Map>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') posts.add(Map.from(options.data as Map));
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class ContextApi extends fixtures.ApiFake {
  ContextApi() {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    transport = HttpMentorApi(ApiClient(dio));
  }
  final adapter = RejectionAdapter();
  late final HttpMentorApi transport;
  int previews = 0;
  @override
  Future<MentorContextOptions> contextOptions() async {
    previews++;
    return MentorContextOptions.fromJson({
      'settings_revision': 4,
      'options': {
        'workout_notes': [
          {
            'selection_id': 'opaque-note-$previews',
            'summary': 'Notatka',
            'preview': 'Podgląd $previews',
          },
        ],
      },
    });
  }

  @override
  Future<MentorMessage> send(
    String id,
    String text, {
    required String requestId,
    int? settingsRevision,
    MentorContextSelection? context,
  }) => transport.send(
    id,
    text,
    requestId: requestId,
    settingsRevision: settingsRevision,
    context: context,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('real Dio classifies only exact pre-dispatch chat rejection', () async {
    final api = ContextApi();
    for (final entry in [
      (
        409,
        {'detail': 'Context selection unavailable'},
        'context_selection_unavailable',
      ),
      (400, {'detail': 'Context selection unavailable'}, null),
      (409, {'detail': 'Other conflict'}, null),
      (409, {'code': 'operation_pending'}, 'operation_pending'),
      (
        409,
        {
          'code': 'operation_conflict',
          'detail': 'Context selection unavailable',
        },
        'operation_conflict',
      ),
      (
        409,
        {
          'detail': ['Context selection unavailable'],
        },
        null,
      ),
      (409, 'invalid response', null),
    ]) {
      api.adapter.status = entry.$1;
      api.adapter.body = entry.$2;
      await expectLater(
        api.send('session', 'Tekst', requestId: 'id'),
        throwsA(isA<MentorException>().having((e) => e.code, 'code', entry.$3)),
      );
    }
    api.adapter.status = 409;
    api.adapter.body = {'detail': 'Context selection unavailable'};
    await expectLater(
      api.transport.contextOptions(),
      throwsA(isA<MentorException>().having((e) => e.code, 'non-send', isNull)),
    );
    await expectLater(
      api.transport.saveSettings({}),
      throwsA(
        isA<MentorException>().having(
          (e) => e.code,
          'settings',
          'settings_conflict',
        ),
      ),
    );
  });

  test(
    'other 409 conflicts retain pending ledger and block changed context',
    () async {
      final api = ContextApi();
      final registry = MentorOperationRegistry('a');
      final controller = MentorConversation(api, registry);
      await controller.open('session');
      api.adapter.body = {'code': 'operation_conflict'};
      await controller.send('Szkic');
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(registry.storageKey);
      expect(jsonDecode(before!), hasLength(1));
      expect(controller.state.error, isNot(contains('Odśwież podgląd')));
      await controller.send(
        'Szkic',
        context: const MentorContextSelection(training: true),
      );
      expect(api.adapter.posts, hasLength(1));
      expect(prefs.getString(registry.storageKey), before);
      controller.dispose();
    },
  );

  testWidgets(
    'stale send retains draft; fresh preview requires reselect and confirm',
    (tester) async {
      final api = ContextApi();
      await fixtures.mount(
        tester,
        api,
        fixtures.VoiceFake(),
        configuredSettings: fixtures.mentorSettings(
          consents: const MentorContextConsents(note: true),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Mój szkic');
      await tester.pump();
      Future<void> openPreview() async {
        await tester.tap(find.byTooltip('Dodaj kontekst do tej wiadomości'));
        await tester.pumpAndSettle();
      }

      Future<void> selectNote(int number) async {
        await tester.tap(
          find.byType(DropdownButtonFormField<MentorContextNoteOption>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Notatka: Podgląd $number').last);
        await tester.pumpAndSettle();
      }

      await openPreview();
      await selectNote(1);
      await tester.tap(find.text('Wyślij z tym kontekstem'));
      await tester.pumpAndSettle();
      expect(api.adapter.posts, hasLength(1));
      expect(find.textContaining('Odśwież podgląd'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Mój szkic',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString(MentorOperationRegistry('a').storageKey)!),
        isEmpty,
      );
      await openPreview();
      expect(api.previews, 2);
      expect(api.adapter.posts, hasLength(1));
      final field = tester.state<FormFieldState<MentorContextNoteOption>>(
        find.byType(DropdownButtonFormField<MentorContextNoteOption>),
      );
      expect(field.value, isNull);
      await selectNote(2);
      expect(api.adapter.posts, hasLength(1));
      api.adapter.status = 200;
      api.adapter.body = {
        'id': 'answer',
        'role': 'assistant',
        'text': 'OK',
        'created_at': '2026-10-18T00:00:00Z',
      };
      await tester.tap(find.text('Wyślij z tym kontekstem'));
      await tester.pumpAndSettle();
      expect(api.adapter.posts, hasLength(2));
      expect(
        api.adapter.posts.last['context']['note']['selection_id'],
        'opaque-note-2',
      );
      expect(
        api.adapter.posts.first['request_id'],
        isNot(api.adapter.posts.last['request_id']),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  test(
    'unknown paid attempt is not forgotten after a later context rejection',
    () async {
      final api = ContextApi();
      final registry = MentorOperationRegistry('a');
      final controller = MentorConversation(api, registry);
      await controller.open('session');
      api.adapter.status = 500;
      await controller.send('Szkic');
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(registry.storageKey);
      api.adapter.status = 409;
      await controller.send('Szkic');
      expect(prefs.getString(registry.storageKey), before);
      await controller.send('Zmieniony szkic');
      expect(api.adapter.posts, hasLength(2));
      expect(
        api.adapter.posts.first['request_id'],
        api.adapter.posts.last['request_id'],
      );
      controller.dispose();
    },
  );

  testWidgets('account change closes old context preview without sending', (
    tester,
  ) async {
    final api = ContextApi();
    final auth = fixtures.AuthFake();
    await fixtures.mount(
      tester,
      api,
      fixtures.VoiceFake(),
      auth: auth,
      configuredSettings: fixtures.mentorSettings(
        consents: const MentorContextConsents(note: true),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Prywatny szkic');
    await tester.pump();
    await tester.tap(find.byTooltip('Dodaj kontekst do tej wiadomości'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<MentorContextNoteOption>),
    );
    await tester.pumpAndSettle();
    auth.switchAccount();
    await tester.pumpAndSettle();
    expect(find.text('Kontekst tej wiadomości'), findsNothing);
    expect(find.text('Prywatny szkic'), findsNothing);
    expect(api.adapter.posts, isEmpty);
  });

  testWidgets(
    'late known rejection after auth change cannot restore draft or mutate ledger',
    (tester) async {
      final api = fixtures.ApiFake()..pending = Completer<MentorMessage>();
      final auth = fixtures.AuthFake();
      await fixtures.mount(tester, api, fixtures.VoiceFake(), auth: auth);
      await tester.enterText(find.byType(TextField), 'Stary szkic');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      final key = MentorOperationRegistry('a').storageKey;
      final before = prefs.getString(key);
      expect(before, isNotNull);
      auth.switchAccount();
      await tester.pumpAndSettle();
      api.pending!.completeError(const MentorContextSelectionUnavailable());
      await tester.pumpAndSettle();
      expect(prefs.getString(key), before);
      expect(find.textContaining('Odśwież podgląd'), findsNothing);
      expect(find.text('Stary szkic'), findsNothing);
      expect(api.sends, 1);
    },
  );
}
