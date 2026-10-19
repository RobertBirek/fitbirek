import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_page.dart';
import 'mentor_flow_test.dart' as f;

class LongApi extends f.ApiFake {
  @override
  Future<List<MentorSession>> sessions() async => [
    MentorSession(id: 'first', createdAt: DateTime(2026)),
    MentorSession(id: 'chosen', createdAt: DateTime(2025)),
  ];
  @override
  Future<List<MentorMessage>> messages(String id) async => [
    for (var i = 0; i < 30; i++)
      MentorMessage(
        id: '$id-$i',
        role: 'assistant',
        text:
            'Wiadomość $i. ${List.filled(i % 4 + 1, 'Spokojny trening i odpoczynek. ').join()}',
        createdAt: DateTime(2026),
      ),
  ];
}

Finder get chat => find.byKey(const ValueKey('mentor-messages'));
ScrollPosition position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: chat, matching: find.byType(Scrollable)).first,
    )
    .position;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final input in ['drag', 'wheel', 'jump', 'none', 'account', 'session']) {
    testWidgets('reply callback race preserves user intent: $input', (
      tester,
    ) async {
      final api = LongApi()..pending = Completer<MentorMessage>();
      final auth = f.AuthFake();
      await f.mount(
        tester,
        api,
        f.VoiceFake(),
        auth: auth,
        size: const Size(375, 550),
      );
      await tester.enterText(find.byType(TextField), 'Pytanie');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MentorPage)),
      );
      // Flush only microtasks: the provider has scheduled its post-frame scroll,
      // but no layout/post-frame callback has run yet.
      api.pending!.complete(
        MentorMessage(
          id: 'race-answer',
          role: 'assistant',
          text: List.filled(40, 'Długa odpowiedź.').join(' '),
          createdAt: DateTime(2026),
        ),
      );
      await tester.idle();
      expect(
        container.read(mentorConversationProvider).messages.last.id,
        'race-answer',
      );
      TestGesture? gesture;
      if (input == 'drag') {
        gesture = await tester.startGesture(tester.getCenter(chat));
        await gesture.moveBy(const Offset(0, 110));
      } else if (input == 'wheel') {
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(chat),
            scrollDelta: const Offset(0, -120),
          ),
        );
      } else if (input == 'jump') {
        position(tester).jumpTo(position(tester).pixels - 120);
      } else if (input == 'account') {
        auth.switchAccount();
      } else if (input == 'session') {
        await container
            .read(mentorConversationProvider.notifier)
            .newConversation();
      }
      final offset = position(tester).pixels;
      await tester.pumpAndSettle();
      if (input == 'account' || input == 'session') {
        expect(find.text('Nowa odpowiedź'), findsNothing);
        expect(find.textContaining('Długa odpowiedź.'), findsNothing);
      } else if (input == 'none') {
        expect(position(tester).extentAfter, lessThan(2));
        expect(find.text('Nowa odpowiedź'), findsNothing);
      } else {
        expect(position(tester).pixels, offset);
        expect(find.text('Nowa odpowiedź'), findsOneWidget);
      }
      await gesture?.up();
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
    'queued badge scroll is cancelled when chosen conversation changes',
    (tester) async {
      final api = LongApi()..pending = Completer<MentorMessage>();
      await f.mount(tester, api, f.VoiceFake(), size: const Size(375, 550));
      await tester.enterText(find.byType(TextField), 'Pytanie');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      position(tester).jumpTo(0);
      api.pending!.complete(f.reply());
      await tester.pumpAndSettle();
      expect(find.text('Nowa odpowiedź'), findsOneWidget);
      final live = tester.widgetList<Semantics>(
        find.ancestor(
          of: find.text('Nowa odpowiedź'),
          matching: find.byType(Semantics),
        ),
      );
      expect(live.any((s) => s.properties.liveRegion == true), isTrue);
      await tester.tap(find.text('Nowa odpowiedź'));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MentorPage)),
      );
      await container
          .read(mentorConversationProvider.notifier)
          .newConversation();
      await tester.pumpAndSettle();
      expect(find.text('Nowa odpowiedź'), findsNothing);
      expect(position(tester).pixels, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed send keeps draft readable with keyboard at 320 text2', (
    tester,
  ) async {
    final api = LongApi()..fail = true;
    await f.mount(
      tester,
      api,
      f.VoiceFake(),
      size: const Size(320, 550),
      textScale: 2,
      keyboardInset: 180,
    );
    final draft = List.filled(12, 'Dłuższy szkic wiadomości.').join(' ');
    await tester.enterText(find.byType(TextField), draft);
    await tester.tap(find.byTooltip('Wyślij'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      draft,
    );
    expect(find.text('Nowa odpowiedź'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'chosen history opens at latest with large text keyboard and reduced motion',
    (tester) async {
      final api = LongApi();
      await f.mount(
        tester,
        api,
        f.VoiceFake(),
        size: const Size(320, 550),
        textScale: 2,
        reducedMotion: true,
        keyboardInset: 180,
      );
      expect(position(tester).extentAfter, lessThan(2));
      position(tester).jumpTo(0);
      await tester.tap(find.byTooltip('Historia rozmów'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(SimpleDialogOption).last);
      await tester.tap(find.byType(SimpleDialogOption).last);
      await tester.pumpAndSettle();
      expect(position(tester).extentAfter, lessThan(2));
      expect(api.sends, 0);
      expect(tester.takeException(), isNull);
    },
  );
  for (final change in ['account', 'session', 'offstage']) {
    testWidgets('late reply cannot notify or scroll after $change change', (
      tester,
    ) async {
      final api = LongApi()..pending = Completer<MentorMessage>();
      final auth = f.AuthFake();
      await f.mount(
        tester,
        api,
        f.VoiceFake(),
        auth: auth,
        size: const Size(375, 550),
      );
      await tester.enterText(find.byType(TextField), 'Prywatny szkic');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      position(tester).jumpTo(0);
      if (change == 'account') {
        auth.switchAccount();
      } else if (change == 'offstage') {
        await tester.tap(find.text('Inna zakładka'));
      } else {
        // Deletion remains available during an in-flight response.
        await tester.tap(find.byTooltip('Usuń rozmowę'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Usuń'));
      }
      await tester.pumpAndSettle();
      api.pending!.complete(f.reply());
      await tester.pumpAndSettle();
      expect(find.text('Nowa odpowiedź'), findsNothing);
      expect(find.text('Odpowiedź mentora'), findsNothing);
      expect(find.text('Prywatny szkic'), findsNothing);
      expect(api.sends, 1);
      expect(tester.takeException(), isNull);
    });
  }
  for (final reading in [false, true]) {
    testWidgets('long chat own send and delayed answer reading=$reading', (
      tester,
    ) async {
      final api = LongApi()..pending = Completer<MentorMessage>();
      await f.mount(
        tester,
        api,
        f.VoiceFake(),
        size: Size(reading ? 320 : 375, 550),
        textScale: reading ? 2 : 1,
        keyboardInset: reading ? 180 : 0,
      );
      expect(position(tester).extentAfter, lessThan(2));
      position(tester).jumpTo(0);
      await tester.enterText(find.byType(TextField), 'Moja wiadomość');
      await tester.tap(find.byTooltip('Wyślij'));
      await tester.pumpAndSettle();
      expect(position(tester).extentAfter, lessThan(2));
      if (reading) {
        position(tester).jumpTo(0);
        await tester.pumpAndSettle();
      }
      final before = position(tester).pixels;
      api.pending!.complete(f.reply());
      await tester.pumpAndSettle();
      if (reading) {
        expect(position(tester).pixels, before);
        expect(find.text('Nowa odpowiedź'), findsOneWidget);
        await tester.tap(find.text('Nowa odpowiedź'));
        await tester.pumpAndSettle();
      }
      expect(position(tester).extentAfter, lessThan(2));
      expect(find.text('Nowa odpowiedź'), findsNothing);
      expect(api.sends, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
