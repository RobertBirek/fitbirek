import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_settings_page.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mentor_flow_test.dart' as fixtures;

class _RevocableApi extends fixtures.ApiFake {
  @override
  Future<MentorSettings> settings() async {
    if (cancelled != 0) throw const MentorException();
    return fixtures.settings();
  }
}

void main() {
  testWidgets(
    'cancelled key form recreates transport so settings stay usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final instances = <_RevocableApi>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => fixtures.AuthFake()),
            mentorApiProvider.overrideWith((ref) {
              final api = _RevocableApi();
              instances.add(api);
              ref.onDispose(api.cancel);
              return api;
            }),
          ],
          child: const MaterialApp(home: MentorSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('OpenAI'));
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nowy klucz'),
        'fake-private-key',
      );
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ustawienia mentora są teraz niedostępne.'),
        findsNothing,
      );
      expect(instances.length, greaterThan(1));
      expect(find.text('fake-private-key'), findsNothing);
    },
  );
}
