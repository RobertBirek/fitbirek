import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'plan_explanation_fixtures.dart';
import 'preview_edit_widgets_test.dart' show openPreview;

void main() {
  for (final refresh in ['pending', 'error']) {
    for (final action in ['rest', 'replace', 'save', 'start']) {
      for (final before in [
        false,
        if (action == 'rest' || action == 'replace') true,
      ]) {
        testWidgets(
          '$action refuses $refresh profile with previous ${before ? 'before proposal' : 'after dialog'}',
          (tester) async {
            final db = AppDatabase.forTesting(NativeDatabase.memory());
            addTearDown(db.close);
            final stream = StreamController<UserProfile?>.broadcast();
            addTearDown(stream.close);
            final profile = UserProfile(
              imie: 'T',
              wiek: 30,
              wzrostCm: 180,
              wagaKg: 80,
              cel: CelTreningowy.mix,
              dostepnySprzet: ['Mata'],
              dataUtworzenia: DateTime(2026),
            );
            var refreshing = false;
            final c = await openPreview(
              tester,
              explanationPlan(),
              db: db,
              profileLoader: () =>
                  refreshing ? stream.stream : Stream.value(profile),
            );
            final opener = switch (action) {
              'rest' => find.byTooltip('Edytuj przerwę'),
              'replace' => find.byTooltip('Wymień ćwiczenie'),
              'save' => find.text('Zapisz plan'),
              _ => find.text('Rozpocznij trening'),
            };
            await tester.ensureVisible(opener);
            final staleCallback = before
                ? tester
                      .widgetList<IconButton>(find.byType(IconButton))
                      .singleWhere(
                        (w) =>
                            w.tooltip ==
                            (action == 'rest'
                                ? 'Edytuj przerwę'
                                : 'Wymień ćwiczenie'),
                      )
                      .onPressed
                : null;
            if (!before) {
              await tester.tap(opener);
              await tester.pumpAndSettle();
              expect(find.byType(AlertDialog), findsOneWidget);
              if (action == 'rest') {
                await tester.enterText(find.byType(TextField).last, '0');
                await tester.pump();
              }
            }
            refreshing = true;
            c.invalidate(userProfileStreamProvider);
            expect(c.read(userProfileStreamProvider).isLoading, isTrue);
            await tester.pump();
            if (refresh == 'error') {
              stream.addError(StateError('Profile refresh failed'));
              await tester.pumpAndSettle();
            }
            final source = c.read(userProfileStreamProvider);
            expect(identical(source.valueOrNull, profile), isTrue);
            expect(
              refresh == 'pending' ? source.isLoading : source.hasError,
              isTrue,
            );
            if (before) {
              // An already captured widget callback must not authorize stale data,
              // even if the error branch has since hidden the original button.
              staleCallback!();
              await tester.pumpAndSettle();
              expect(find.byType(AlertDialog), findsNothing);
            } else {
              final label = action == 'rest'
                  ? 'Zastosuj'
                  : action == 'replace'
                  ? 'Zamień'
                  : 'Potwierdź';
              await tester.runAsync(() async {
                await tester.tap(find.text(label));
                await Future<void>.delayed(const Duration(milliseconds: 50));
              });
              for (var i = 0; i < 10; i++) {
                await tester.pump();
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 10)),
                );
              }
            }
            // Return the very same instance to expose the preview after an error.
            stream.add(profile);
            await tester.pumpAndSettle();
            expect(find.text('Ruch a'), findsOneWidget);
            expect(find.text('Ruch b'), findsNothing);
            expect(find.textContaining('przerwa 30 s'), findsOneWidget);
            expect(c.exists(plannerWorkflowProvider), isFalse);
            expect(
              await tester.runAsync(() => db.select(db.workoutPlans).get()),
              isEmpty,
            );
            expect(
              await tester.runAsync(() => db.select(db.workoutSessions).get()),
              isEmpty,
            );
            expect(
              await tester.runAsync(() => db.select(db.syncOutbox).get()),
              isEmpty,
            );
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
