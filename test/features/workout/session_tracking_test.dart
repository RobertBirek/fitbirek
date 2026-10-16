import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';

const exercise = Exercise(
  id: 'custom',
  nazwaPl: 'Test',
  nazwaEn: '',
  partiaGlowna: '',
  partieWspierajace: [],
  sprzet: ['Masa własna', 'Drążek'],
  typ: '',
  poziom: '',
  wzorzecRuchu: '',
  seriexPowtorzenia: '',
  tempo: '',
  kluczoweWskazowki: [],
  czesteBledy: [],
  progresja: '',
  regresja: '',
  zrodlo: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  for (final tracking in ['reps', 'time', 'rounds']) {
    testWidgets(
      '$tracking uses correct fields and explicit Polish side selector',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  'custom': ExerciseCatalogEntry(
                    tracking: tracking,
                    unilateral: true,
                  ),
                },
              ),
            ),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });
        container.read(activeWorkoutProvider.notifier).addExercise(exercise);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Ciężar (kg)'), findsNothing);
        expect(find.text('Lewa'), findsOneWidget);
        expect(find.text('Prawa'), findsOneWidget);
        expect(find.text('Obie'), findsOneWidget);
        expect(
          find.text('Powtórzenia'),
          tracking == 'reps' ? findsOneWidget : findsNothing,
        );
        if (tracking == 'rounds') {
          expect(find.text('Czas pracy rundy (s)'), findsOneWidget);
        }
        if (tracking == 'time') {
          expect(find.text('Czas (s)'), findsOneWidget);
        }
        await tester.runAsync(
          () => container.read(activeWorkoutProvider.notifier).startSession(),
        );
        await tester.tap(find.text('Lewa'));
        await tester.pumpAndSettle();
        final input = find.byType(TextField).first;
        await tester.enterText(input, '0');
        final save = find.text(
          tracking == 'reps'
              ? 'Seria wykonana (0)'
              : tracking == 'rounds'
              ? 'Zapisz rundę (0)'
              : 'Zapisz czas (0)',
        );
        await tester.tap(save);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          await tester.runAsync(() => db.workoutDao.getAllSets()),
          isEmpty,
        );
        await tester.enterText(input, '25');
        await tester.runAsync(() async {
          await tester.tap(save);
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pump();
        final rows = await tester.runAsync(() => db.workoutDao.getAllSets());
        expect(rows, hasLength(1));
        expect(rows!.single.side, 'left');
        expect(rows.single.ciezarKg, isNull);
        expect(rows.single.powtorzenia, tracking == 'reps' ? 25 : isNull);
        expect(rows.single.czasSekund, tracking == 'reps' ? isNull : 25);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  for (final typ in ['Izometria', 'time', 'custom']) {
    testWidgets('metadata error keeps legacy $typ functional', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => throw const FormatException('metadata'),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container
          .read(activeWorkoutProvider.notifier)
          .addExercise(exercise.copyWith(typ: typ, sprzet: ['Hantle']));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ActiveSessionPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lewa'), findsNothing);
      if (typ == 'custom') {
        expect(find.text('Ciężar (kg)'), findsOneWidget);
        expect(find.text('Powtórzenia'), findsOneWidget);
      } else {
        expect(find.text('Czas (s)'), findsOneWidget);
        expect(find.text('Ciężar (kg)'), findsNothing);
      }
    });
  }

  test(
    'sided sets never create unsided personal records; last set is side-specific',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      for (final side in ['left', 'right', 'both']) {
        expect(
          await notifier.logSet(
            exercise: exercise,
            weightKg: 20,
            reps: 10,
            side: side,
          ),
          isFalse,
        );
      }
      expect(await db.select(db.personalRecords).get(), isEmpty);
      final repo = container.read(workoutRepositoryProvider);
      expect((await repo.getLastSet('custom', side: 'left'))!.side, 'left');
      expect(await repo.getLastSet('custom'), isNull);
    },
  );
}
