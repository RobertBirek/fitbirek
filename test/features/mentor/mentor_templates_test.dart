import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_actions.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/mentor/presentation/pages/mentor_page.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/template_editor_page.dart';
import 'mentor_flow_test.dart'
    show ApiFake, VoiceFake, AuthFake, mentorSettings;
import '../exercises/catalog_filter_test.dart' show exercise;

final templateMetadata = ExerciseCatalogMetadata.fromJson({
  'schemaVersion': 1,
  'styles': [],
  'muscles': [],
  'exercises': {
    'cw001': {
      'styles': [],
      'primaryMuscles': [],
      'secondaryMuscles': [],
      'aliases': [],
      'tracking': 'reps',
      'unilateral': false,
    },
  },
});

Map<String, Object?> wire({String id = 'cw001'}) => {
  'id': 'd34d884a-fbde-48a3-925d-08edf2ce25c0',
  'kind': 'create_template',
  'name': 'Poranny szablon',
  'minutes': 15,
  'exercises': [
    {
      'exercise_id': id,
      'sets': 2,
      'reps': 8,
      'seconds': null,
      'rest_seconds': 30,
      'weight_kg': 4.5,
    },
  ],
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'typed proposal rejects malformed, excessive and duplicate prescriptions',
    () {
      expect(MentorProposal.fromJson(wire()).isSafeToConfirm, isTrue);
      for (final field in ['sets', 'reps', 'rest_seconds']) {
        for (final value in [true, -1, 2.5, 1e100, 4611686018427387904]) {
          final p = wire();
          ((p['exercises'] as List).single as Map)[field] = value;
          expect(() => MentorProposal.fromJson(p), throwsFormatException);
        }
      }
      final duplicate = wire();
      (duplicate['exercises'] as List).add(
        (duplicate['exercises'] as List).first,
      );
      expect(() => MentorProposal.fromJson(duplicate), throwsFormatException);
      final kg = wire();
      ((kg['exercises'] as List).single as Map)['weight_kg'] = double.infinity;
      expect(() => MentorProposal.fromJson(kg), throwsFormatException);
    },
  );

  test(
    'account transition while catalog loads prevents opening the private seed',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
          );
      final auth = AuthFake();
      final entered = Completer<void>();
      final catalog = Completer<ExerciseCatalogMetadata>();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authStateProvider.overrideWith((ref) => auth),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('cw001')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) {
            entered.complete();
            return catalog.future;
          }),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final opening = c
          .read(mentorActionsProvider)
          .prepareTemplate(
            MentorProposal.fromJson(wire()),
            accountId: 'a',
            expectedSessionId: null,
          );
      await entered.future;
      auth.switchAccount();
      catalog.complete(templateMetadata);
      expect(await opening, isNull);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  for (final action in ['save', 'cancel', 'account', 'unknown']) {
    testWidgets(
      'real Mentor proposal -> detached editor -> $action has no session writes',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1500));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
            );
        final api = ApiFake()
          ..proposal = MentorProposal.fromJson(
            wire(id: action == 'unknown' ? 'cw999' : 'cw001'),
          );
        final auth = AuthFake();
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => templateMetadata,
            ),
            authStateProvider.overrideWith((ref) => auth),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([exercise('cw001', name: 'Pompki')]),
            ),
            mentorApiProvider.overrideWithValue(api),
            mentorVoiceApiProvider.overrideWithValue(api),
            mentorVoiceProvider.overrideWithValue(VoiceFake()),
            mentorSettingsProvider.overrideWith(
              (ref) async => mentorSettings(),
            ),
          ],
        );
        final router = createRouter(
          readAuthState: () => const AuthState.signedIn('a'),
          readOnboardingComplete: () => true,
          initialLocation: '/today',
        );
        addTearDown(() async {
          router.dispose();
          c.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sprawdź i potwierdź'));
        await tester.pumpAndSettle();
        if (action == 'unknown') {
          expect(find.byType(TemplateEditorPage), findsNothing);
          expect(await db.select(db.workoutPlans).get(), isEmpty);
          expect(await db.select(db.syncOutbox).get(), isEmpty);
          expect(await db.select(db.workoutSessions).get(), isEmpty);
          await tester.pumpWidget(const SizedBox());
          return;
        }
        expect(find.byType(TemplateEditorPage), findsOneWidget);
        expect(find.text('Poranny szablon'), findsOneWidget);
        expect(await db.select(db.workoutPlans).get(), isEmpty);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
        expect(
          api.sends,
          0,
        ); // Confirming never calls the paid provider a second time.
        if (action == 'save') {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Nazwa szablonu'),
            'Edytowany szablon',
          );
          await tester.tap(find.text('Zapisz szablon'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Potwierdź'));
          await tester.pumpAndSettle();
          expect(
            (await db.select(db.workoutPlans).get()).single.nazwa,
            'Edytowany szablon',
          );
          expect(await db.select(db.syncOutbox).get(), hasLength(1));
        } else if (action == 'cancel') {
          router.pop();
          await tester.pumpAndSettle();
          expect(await db.select(db.workoutPlans).get(), isEmpty);
        } else {
          auth.switchAccount();
          await tester.pumpAndSettle();
          expect(find.text('Poranny szablon'), findsNothing);
          expect(find.text('Zapisz szablon'), findsNothing);
          expect(await db.select(db.workoutPlans).get(), isEmpty);
        }
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'templates entry prefills without sending and offers manual fallback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = ApiFake();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => templateMetadata,
          ),
          authStateProvider.overrideWith((ref) => AuthFake()),
          mentorApiProvider.overrideWithValue(api),
          mentorVoiceApiProvider.overrideWithValue(api),
          mentorVoiceProvider.overrideWithValue(VoiceFake()),
          mentorSettingsProvider.overrideWith(
            (ref) async => mentorSettings(enabled: false),
          ),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('cw001')]),
          ),
        ],
      );
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('a'),
        readOnboardingComplete: () => true,
        initialLocation: '/workout/templates',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utwórz szablon z Mentorem'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ułóż szablon: Poranne rozciąganie ogólne 15 min',
      );
      expect(api.sends, 0);
      expect(find.text('Ułóż szablon samodzielnie'), findsOneWidget);
      await tester.tap(find.text('Ułóż szablon samodzielnie'));
      await tester.pumpAndSettle();
      expect(find.byType(TemplateEditorPage), findsOneWidget);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
