import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_page.dart';
import 'package:fitbirek_training/features/schedule/presentation/widgets/today_schedule.dart';
import 'mentor_flow_test.dart' as f;

class TranscriptionApi extends f.ApiFake {
  Completer<String>? transcription;
  bool loseResult = false;
  final sttIds = <String>[];
  @override
  Future<String> transcribe(
    Uint8List bytes,
    String type,
    double duration, {
    required String requestId,
  }) async {
    transcriptions++;
    sttIds.add(requestId);
    if (loseResult) throw const MentorException();
    return transcription == null
        ? 'Prywatna transkrypcja'
        : transcription!.future;
  }
}

class RecordingVoice extends f.VoiceFake {
  int starts = 0;
  @override
  Future<void> startRecording() async {
    starts++;
  }
}

Future<void> record(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Nagraj wiadomość'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Zakończ nagranie'));
  await tester.pumpAndSettle();
}

void visible(WidgetTester tester, Finder finder, double height) {
  expect(finder, findsOneWidget);
  final bounds = tester.getRect(finder);
  expect(bounds.top, greaterThanOrEqualTo(0));
  expect(bounds.bottom, lessThanOrEqualTo(height));
  expect(finder.hitTestable(), findsOneWidget);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'desktop measure and collapsible schedule share conversation scroll',
    (tester) async {
      final api = f.ApiFake();
      await f.mount(tester, api, f.VoiceFake(), size: const Size(1280, 900));
      expect(tester.getSize(find.byType(TextField)).width, 928);
      expect(find.byType(TodaySchedule), findsNothing);
      await tester.tap(find.text('Plan dnia i podpowiedzi'));
      await tester.pumpAndSettle();
      expect(find.byType(TodaySchedule), findsOneWidget);
      final messageScroll = find.byKey(const ValueKey('mentor-messages'));
      expect(
        find.descendant(
          of: messageScroll,
          matching: find.byType(TodaySchedule),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Dziś mam dużo energii.'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Dziś mam dużo energii.',
      );
      expect(api.sends, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('cancel review discards draft without chat or speech calls', (
    tester,
  ) async {
    final api = TranscriptionApi();
    await f.mount(tester, api, f.VoiceFake());
    await record(tester);
    expect(api.sends, 0);
    await tester.tap(find.byTooltip('Anuluj transkrypcję'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(api.sends, 0);
    expect(api.speechCalls, 0);
    expect(find.text('Sprawdź transkrypcję i wybierz Wyślij'), findsNothing);
  });
  for (final change in ['account', 'stop', 'offstage']) {
    testWidgets('pending STT cannot leak into draft after $change', (
      tester,
    ) async {
      final api = TranscriptionApi()..transcription = Completer<String>();
      final auth = f.AuthFake();
      await f.mount(tester, api, f.VoiceFake(), auth: auth);
      await record(tester);
      if (change == 'account') {
        auth.switchAccount();
      } else if (change == 'stop') {
        await tester.tap(find.byTooltip('Stop'));
      } else {
        await tester.tap(find.text('Inna zakładka'));
      }
      await tester.pumpAndSettle();
      api.transcription!.complete('NIE UJAWNIAJ');
      await tester.pumpAndSettle();
      if (change == 'offstage') {
        await tester.tap(find.text('Dziś'));
        await tester.pumpAndSettle();
      }
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('NIE UJAWNIAJ'), findsNothing);
      expect(api.sends, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().map((key) => prefs.get(key)).join(),
        isNot(contains('NIE UJAWNIAJ')),
      );
    });
  }
  testWidgets('unknown STT never silently allocates a paid retry', (
    tester,
  ) async {
    final api = TranscriptionApi()..loseResult = true;
    final voice = RecordingVoice();
    await f.mount(tester, api, voice);
    await tester.enterText(find.byType(TextField), 'Zachowaj mój szkic');
    await record(tester);
    expect(api.transcriptions, 1);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(api.sends, 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Zachowaj mój szkic',
    );
    await tester.tap(find.byTooltip('Nagraj wiadomość'));
    await tester.pumpAndSettle();
    expect(find.text('Nowa płatna operacja'), findsOneWidget);
    expect(voice.starts, 1);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(api.sttIds, hasLength(1));
    await tester.tap(find.byTooltip('Nagraj wiadomość'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Wygeneruj ponownie — ponowne użycie limitu i koszt'),
    );
    await tester.pumpAndSettle();
    expect(voice.starts, 2);
    await tester.tap(find.byTooltip('Zakończ nagranie'));
    await tester.pumpAndSettle();
    expect(api.sttIds.toSet(), hasLength(2));
    expect(api.sends, 0);
  });
  testWidgets('configuration loading does not erase a private reviewed draft', (
    tester,
  ) async {
    final refresh = Completer<MentorSettings>();
    var reads = 0;
    final api = TranscriptionApi();
    await f.mount(
      tester,
      api,
      f.VoiceFake(),
      loadSettings: () async {
        if (reads++ == 0) return f.mentorSettings();
        return refresh.future;
      },
    );
    await record(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MentorPage)),
    );
    container.invalidate(mentorSettingsProvider);
    await tester.pump();
    refresh.complete(f.mentorSettings());
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Prywatna transkrypcja',
    );
    expect(api.sends, 0);
  });
  for (final width in [320.0, 375.0]) {
    testWidgets('review voice draft fits keyboard at text2 $width', (
      tester,
    ) async {
      final api = TranscriptionApi();
      await f.mount(
        tester,
        api,
        f.VoiceFake(),
        size: Size(width, 550),
        textScale: 2,
        keyboardInset: 180,
      );
      await record(tester);
      expect(api.sends, 0);
      visible(tester, find.text('Sprawdź transkrypcję i wybierz Wyślij'), 370);
      expect(find.byTooltip('Wyślij').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'unconfigured reason and single offline CTA visible first $width',
      (tester) async {
        final api = f.ApiFake();
        await f.mount(
          tester,
          api,
          f.VoiceFake(),
          enabled: false,
          size: Size(width, 700),
          textScale: 2,
        );
        visible(tester, find.text('Brak konfiguracji usługi.'), 700);
        visible(tester, find.text('Otwórz ustawienia mentora'), 700);
        visible(tester, find.text('Klasyczny trening (offline)'), 700);
        expect(find.byTooltip('Stop'), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(api.sends, 0);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'composer has full width and 48px controls with keyboard $width',
      (tester) async {
        await f.mount(
          tester,
          f.ApiFake(),
          f.VoiceFake(),
          size: Size(width, 650),
          textScale: 2,
          keyboardInset: 180,
        );
        final field = find.byType(TextField);
        expect(tester.getSize(field).width, greaterThanOrEqualTo(width - 40));
        await tester.tap(field);
        await tester.enterText(field, 'Szkic');
        await tester.pump();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        for (final tooltip in [
          'Wyślij',
          'Nagraj wiadomość',
          'Dodaj kontekst do tej wiadomości',
        ]) {
          final button = find.byTooltip(tooltip);
          visible(tester, button, 470);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        }
        expect(find.byTooltip('Stop'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
