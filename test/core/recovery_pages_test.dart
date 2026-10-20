import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/templates_page.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_settings_page.dart';

void main() {
  for (final mentor in [false, true]) {
    testWidgets(
      '${mentor ? 'mentor' : 'templates'} errors offer retry without exposing exception',
      (tester) async {
        var reads = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              savedPlansProvider.overrideWith((ref) {
                reads++;
                return Stream.error(StateError('private'));
              }),
              mentorSettingsProvider.overrideWith((ref) async {
                reads++;
                throw StateError('private');
              }),
            ],
            child: MaterialApp(
              home: mentor ? const MentorSettingsPage() : const TemplatesPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.textContaining('private'), findsNothing);
        expect(find.text('Spróbuj ponownie'), findsOneWidget);
        final before = reads;
        await tester.tap(find.text('Spróbuj ponownie'));
        await tester.pumpAndSettle();
        expect(reads, greaterThan(before));
      },
    );
  }
}
