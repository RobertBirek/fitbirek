import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercise_variants_providers.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/protocol_editor_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/protocol_detail_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/fitness_test_widgets.dart';
import 'fitness_ui_support.dart';

final _protocolJson =
    (jsonDecode(
              File(
                'tests/fixtures/fitness_protocol_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>)['protocol']
        as Map<String, dynamic>;
final _exercise = Exercise.fromJson(
  (jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as List)
          .first
      as Map<String, dynamic>,
);
final _savedVariant = <String, dynamic>{
  'id': '22222222-2222-4222-8222-222222222222',
  'exerciseId': 'cw001',
  'name': 'Wolno',
  'tempo': '4010',
  'createdAtUtc': '2026-01-01T10:00:00.000Z',
  'updatedAtUtc': '2026-01-01T10:00:00.000Z',
};

void main() {
  for (final metric in [
    ('reps', 'Powtórzenia · powt.'),
    ('time', 'Czas · s'),
    ('distance', 'Dystans · m'),
  ]) {
    for (final unavailable in [false, true]) {
      for (final detail in [false, true]) {
        testWidgets(
          'metric ${metric.$1} visible on ${detail ? 'detail' : 'card'} with ${unavailable ? 'unavailable' : 'empty'} history',
          (tester) async {
            final p = FitnessProtocol.fromJson({
              ..._protocolJson,
              'name': 'Próba',
              'metric': metric.$1,
              'instructions': '',
            });
            final List<CustomFitnessResult>? results = unavailable ? null : [];
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  fitnessProtocolsProvider.overrideWith(
                    (ref) => Stream.value(
                      FitnessProtocolsView(isAvailable: true, protocols: [p]),
                    ),
                  ),
                  customFitnessResultsProvider.overrideWith(
                    (ref) => Stream.value(results),
                  ),
                ],
                child: MaterialApp(
                  home: detail
                      ? ProtocolDetailPage(protocolId: p.id)
                      : Scaffold(
                          body: SingleChildScrollView(
                            child: CustomTestCard(
                              protocol: p,
                              results: results,
                            ),
                          ),
                        ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text(metric.$2), findsOneWidget);
            expect(find.textContaining('Więcej = lepiej'), findsOneWidget);
            expect(
              find.text(
                unavailable ? 'Historia niedostępna' : 'Jeszcze bez wyniku',
              ),
              findsWidgets,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final sameName in [false, true]) {
    for (final chooseCurrent in [false, true]) {
      testWidgets(
        'revision variant sameId sameName=$sameName chooseCurrent=$chooseCurrent shows and saves exact snapshot',
        (tester) async {
          final fixture = await fitnessUiFixture();
          addTearDown(fixture.db.close);
          Future<void> seedVariant(Map<String, dynamic> v) => fixture.db
              .update(fixture.db.userProfiles)
              .write(
                UserProfilesCompanion(
                  exerciseVariantsJson: Value(
                    jsonEncode({
                      'version': 1,
                      'entries': [v],
                    }),
                  ),
                ),
              );
          await seedVariant(_savedVariant);
          final initial = FitnessProtocol.fromJson({
            ..._protocolJson,
            'variantSnapshot': _savedVariant,
          });
          final p = await fixture.repo.createProtocol(
            await fixture.repo.captureLease(),
            FitnessProtocolDraft.fromProtocol(initial),
          );
          final current = {
            ..._savedVariant,
            'name': sameName ? 'Wolno' : 'Szybko',
            'tempo': '1010',
            'updatedAtUtc': '2026-02-01T10:00:00.000Z',
          };
          await seedVariant(current);
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => ProtocolEditorPage(protocolId: p.id),
              ),
              GoRoute(
                path: '/progress/tests/:id',
                builder: (_, __) =>
                    const Scaffold(body: Text('Zapisano rewizję')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                testsRepositoryProvider.overrideWithValue(fixture.repo),
                allExercisesProvider.overrideWith(
                  (ref) => Stream.value([_exercise]),
                ),
                exerciseVariantsProvider.overrideWith(
                  (ref, id) => Stream.value([current]),
                ),
              ],
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Wariant ćwiczenia'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          final variantField = find.ancestor(
            of: find.text('Wariant ćwiczenia'),
            matching: find.byType(DropdownButtonFormField<String>),
          );
          final dropdown = tester.widget<DropdownButton<String>>(
            find.descendant(
              of: variantField,
              matching: find.byType(DropdownButton<String>),
            ),
          );
          final selected = dropdown.items!.singleWhere(
            (item) => item.value == dropdown.value,
          );
          expect(
            (selected.child as Text).data,
            contains('Wolno (zapisany snapshot)'),
          );
          expect(
            dropdown.items,
            hasLength(3),
          ); // None, saved rules, live rules with the SAME ID.
          expect(dropdown.items!.map((e) => e.value).toSet(), hasLength(3));
          if (chooseCurrent) {
            await tester.tap(variantField);
            await tester.pumpAndSettle();
            await tester.tap(
              find.text('${current['name']} (bieżący wariant)').last,
            );
            await tester.pumpAndSettle();
          }
          await tester.scrollUntilVisible(
            find.text('Zapisz nową wersję'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.text('Zapisz nową wersję'));
          await tester.pumpAndSettle();
          expect(find.text('Zapisano rewizję'), findsOneWidget);
          final profile = await fixture.db
              .select(fixture.db.userProfiles)
              .getSingle();
          final revisions =
              ((jsonDecode(profile.fitnessProtocolsJson!)
                          as Map<String, dynamic>)['entries']
                      as List)
                  .map(
                    (entry) =>
                        FitnessProtocol.fromJson(entry as Map<String, dynamic>),
                  )
                  .toList();
          final revised = revisions.singleWhere((r) => r.id != p.id);
          expect(
            revised.variantSnapshot,
            chooseCurrent ? current : _savedVariant,
          );
          expect(
            revisions.singleWhere((r) => r.id == p.id).variantSnapshot,
            _savedVariant,
          );
          expect(revisions.every((r) => !r.isArchived), isTrue);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
