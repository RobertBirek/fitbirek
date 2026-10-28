import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../planner/preview_edit_widgets_test.dart' show shortPlan;
import '../planner/plan_explanation_widgets_test.dart'
    show compatibleExercise, compatibleMetadata;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;

class DialogAuthority extends CachedAuthWriteAuthority {
  int value = 0;
  @override
  int get epoch => value;
}

void main() {
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  for (final action in [
    'cancel',
    'accept',
    'catalog',
    'profile',
    'engine',
    'account',
    'form',
    'guidance',
    'slot',
    'weight',
    'equipment',
  ]) {
    final accept = action != 'cancel';
    testWidgets('active ID-only replacement $action', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = DialogAuthority();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([
              compatibleExercise('a'),
              compatibleExercise('b').copyWith(seriexPowtorzenia: '99 x 100 s'),
            ]),
          ),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => compatibleMetadata,
          ),
          userProfileStreamProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(
                imie: 'T',
                wiek: 30,
                wzrostCm: 180,
                wagaKg: 80,
                cel: CelTreningowy.mix,
                dostepnySprzet: action == 'equipment' ? [] : ['Mata'],
                dataUtworzenia: DateTime(2026),
              ),
            ),
          ),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      late ActiveWorkoutNotifier n;
      final base = shortPlan();
      final plan = action == 'slot'
          ? StructuredPlan(
              criteria: base.criteria,
              budgetSeconds: 600,
              equipment: base.equipment,
              warnings: [],
              blocks: [
                ...base.blocks,
                PlanBlock(
                  exerciseId: 'third',
                  section: PlanSection.main,
                  prescription: base.blocks.single.prescription,
                ),
              ],
            )
          : action != 'weight'
          ? base
          : StructuredPlan(
              criteria: base.criteria,
              budgetSeconds: base.budgetSeconds,
              equipment: base.equipment,
              warnings: [],
              blocks: [
                PlanBlock(
                  exerciseId: 'a',
                  section: PlanSection.main,
                  prescription: const PlanPrescription(
                    tracking: 'time',
                    sets: 3,
                    workSeconds: 40,
                    restSeconds: 30,
                    transitionSeconds: 15,
                    weightKg: 12,
                  ),
                ),
              ],
            );
      await tester.runAsync(() async {
        n = c.read(activeWorkoutProvider.notifier);
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        await n.startSession(guidance: WorkoutGuidance.start(plan));
        n.updateDraft({
          'seconds': '9',
          'side': 'left',
          'timer': completedLeftTimer(),
        });
        await n.flushDraft();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
      });
      await tester.pumpAndSettle();
      await drain(tester);
      final before = c.read(activeWorkoutProvider);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'Zamień'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Zamień'));
      await tester.pumpAndSettle();
      if (action == 'weight' || action == 'equipment') {
        expect(find.text('Zamienić ćwiczenie?'), findsNothing);
        expect(
          find.textContaining(
            action == 'weight'
                ? 'indywidualnym ciężarem'
                : 'Brak zgodnego zamiennika',
          ),
          findsOneWidget,
        );
        expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'a');
        await tester.pumpWidget(const SizedBox());
        return;
      }
      expect(find.text('Zamienić ćwiczenie?'), findsOneWidget);
      expect(find.textContaining('niezapisane wyniki timera'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Zamień').last)
            .onPressed,
        isNull,
      );
      if (accept) {
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
      }
      if (action == 'catalog') c.invalidate(allExercisesProvider);
      if (action == 'profile') c.invalidate(userProfileStreamProvider);
      if (action == 'engine') c.invalidate(exerciseFilterEngineProvider);
      if (action == 'account') authority.value++;
      if (action == 'form') n.updateDraft({'seconds': '25'});
      if (action == 'slot') n.moveGuided(1);
      if (action == 'guidance') {
        await tester.runAsync(() async {
          await c
              .read(workoutRepositoryProvider)
              .guidanceEvent(
                sessionId: before.sessionId!,
                sessionSyncId: before.sessionSyncId!,
                accountId: 'a',
                guard: () => true,
                slot: 0,
              );
        });
      }
      await tester.pumpAndSettle();
      await drain(tester);
      await tester.runAsync(() async {
        await tester.tap(
          find.widgetWithText(TextButton, accept ? 'Zamień' : 'Anuluj').last,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await drain(tester);
      final after = c.read(activeWorkoutProvider);
      expect(
        after.guidance!.exerciseAt(0),
        action == 'accept' ? 'b' : 'a',
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join('\n'),
      );
      expect(after.guidance!.plan.toJson(), plan.toJson());
      expect(
        after.draft['timer'],
        action == 'accept' || action == 'slot' ? isNull : before.draft['timer'],
      );
      expect(
        after.draft['side'],
        action == 'accept' || action == 'slot' ? isNull : before.draft['side'],
      );
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
