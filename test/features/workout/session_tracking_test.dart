import 'dart:ui' show SemanticsAction;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/core/widgets/rest_timer_screen.dart';
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

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final previous = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previous);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  for (final dark in [false, true]) {
    testWidgets('active session and rest timer 320x640 text2 dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => ExerciseCatalogMetadata(
              exercises: {
                'custom': const ExerciseCatalogEntry(
                  tracking: 'reps',
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
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.addExercise(exercise.copyWith(sprzet: ['Hantle']));
      await tester.runAsync(notifier.startSession);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: dark ? FitBirekTheme.dark : FitBirekTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const ActiveSessionPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> reveal(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      final left = find.text('Lewa');
      await reveal(left);
      await tester.tap(left);
      await tester.pumpAndSettle();
      for (final field in [('Ciężar (kg)', '12'), ('Powtórzenia', '8')]) {
        final input = find.widgetWithText(TextField, field.$1);
        await reveal(input);
        await tester.enterText(input, field.$2);
      }
      final slider = find.byType(Slider);
      await reveal(slider);
      final sliderSemantics = tester.getSemantics(slider).getSemanticsData();
      expect(sliderSemantics.hasAction(SemanticsAction.increase), isTrue);
      expect(sliderSemantics.hasAction(SemanticsAction.decrease), isTrue);
      await tester.tap(slider);
      await tester.pumpAndSettle();
      final rpe = tester.widget<Slider>(slider).value.toInt();
      expect(find.text('$rpe/10'), findsOneWidget);
      final save = find.widgetWithText(ElevatedButton, 'Seria wykonana (0)');
      await reveal(save);
      final viewport = tester.getRect(find.byType(ListView));
      expect(tester.getRect(save).top, greaterThanOrEqualTo(viewport.top));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(viewport.bottom));
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      await tester.runAsync(() async {
        await tester.tap(save);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      final rows = await tester.runAsync(() => db.workoutDao.getAllSets());
      expect(rows, hasLength(1));
      expect(rows!.single.powtorzenia, 8);
      expect(rows.single.ciezarKg, 12);
      expect(rows.single.side, 'left');
      expect(rows.single.rpe, rpe);
      await tester.pumpAndSettle();
      expect(find.byType(RestTimerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Potwierdzenie PR współdzieli ScaffoldMessenger z trasą timera.
      if (find.byType(SnackBar).evaluate().isNotEmpty) {
        await tester.pump(
          tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        );
        await tester.pumpAndSettle();
      }
      int remaining() {
        final text = tester
            .widget<Text>(find.textContaining(RegExp(r'^\d+:\d{2}$')))
            .data!;
        final parts = text.split(':').map(int.parse).toList();
        return parts[0] * 60 + parts[1];
      }

      for (final selectedLabel in ['90s', '60s']) {
        final selection = find.widgetWithText(ChoiceChip, selectedLabel);
        await reveal(selection);
        await tester.tap(selection);
        await tester.pumpAndSettle();
        for (final label in ['60s', '90s', '120s', '180s', 'Własny']) {
          final chip = label == 'Własny'
              ? find.widgetWithText(ActionChip, label)
              : find.widgetWithText(ChoiceChip, label);
          await reveal(chip);
          final text = find.descendant(of: chip, matching: find.text(label));
          expect(text.hitTestable(), findsOneWidget);
          final foreground = DefaultTextStyle.of(
            tester.element(text),
          ).style.color!;
          final ink = tester.widget<Ink>(
            find.descendant(of: chip, matching: find.byType(Ink)),
          );
          final paintedColor =
              (ink.decoration! as ShapeDecoration).color ?? Colors.transparent;
          final scaffold = tester.widget<Scaffold>(
            find.descendant(
              of: find.byType(RestTimerScreen),
              matching: find.byType(Scaffold),
            ),
          );
          final background = Color.alphaBlend(
            paintedColor,
            scaffold.backgroundColor!,
          );
          expect(
            contrast(Color.alphaBlend(foreground, background), background),
            greaterThanOrEqualTo(4.5),
            reason: '$label dark=$dark',
          );
          if (label == selectedLabel) {
            final raw = tester.widget<RawChip>(
              find.descendant(of: chip, matching: find.byType(RawChip)),
            );
            expect(raw.selected, isTrue);
            final context = tester.element(text);
            final checkmark =
                raw.checkmarkColor ??
                ChipTheme.of(context).checkmarkColor ??
                Theme.of(context).colorScheme.onSecondaryContainer;
            expect(contrast(checkmark, background), greaterThanOrEqualTo(3));
          }
        }
      }

      final preset = find.widgetWithText(ChoiceChip, '90s');
      await reveal(preset);
      await tester.tap(preset);
      await tester.pump();
      expect(find.text('1:30'), findsOneWidget);
      final add = find.widgetWithText(OutlinedButton, '+15s');
      await reveal(add);
      expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(add).width.isFinite, isTrue);
      final beforeAdd = remaining();
      await tester.tap(add);
      await tester.pump();
      expect(remaining(), beforeAdd + 15);
      final subtract = find.widgetWithText(OutlinedButton, '-15s');
      await reveal(subtract);
      final beforeSubtract = remaining();
      await tester.tap(subtract);
      await tester.pump();
      expect(remaining(), beforeSubtract - 15);
      await tester.pump(const Duration(seconds: 2));
      expect(remaining(), beforeSubtract - 17);
      final skip = find.widgetWithText(ElevatedButton, 'Pomiń przerwę');
      expect(skip.hitTestable(), findsOneWidget);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(find.byType(RestTimerScreen), findsNothing);
      expect(find.byType(ActiveSessionPage), findsOneWidget);
      expect(
        await tester.runAsync(() => db.workoutDao.getAllSets()),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
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
        expect(find.textContaining('nie są obliczane'), findsNothing);
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
        final saveLabel = find.text(
          tracking == 'reps'
              ? 'Seria wykonana (0)'
              : tracking == 'rounds'
              ? 'Zapisz rundę (0)'
              : 'Zapisz czas (0)',
        );
        final save = find.ancestor(
          of: saveLabel,
          matching: find.byType(ElevatedButton),
        );
        Future<void> revealSave() async {
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          final viewport = tester.getRect(find.byType(ListView));
          final button = tester.getRect(save);
          expect(button.top, greaterThanOrEqualTo(viewport.top));
          expect(button.bottom, lessThanOrEqualTo(viewport.bottom));
          expect(button.height, greaterThanOrEqualTo(48));
          expect(save.hitTestable(), findsOneWidget);
        }

        await revealSave();
        await tester.tap(save);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          await tester.runAsync(() => db.workoutDao.getAllSets()),
          isEmpty,
        );
        // Błąd walidacji pokazuje SnackBar nad dolną częścią formularza.
        // pumpAndSettle nie czeka na jego timer; pozwól mu zniknąć naturalnie.
        final validationMessage = tester.widget<SnackBar>(
          find.byType(SnackBar),
        );
        await tester.pump(validationMessage.duration);
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        await tester.ensureVisible(input);
        await tester.pumpAndSettle();
        await tester.enterText(input, '25');
        await revealSave();
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
        expect(tester.takeException(), isNull);
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

  for (final timed in [false, true]) {
    testWidgets(
      'UI shows ${timed ? "seconds" : "kg and reps"} delta only for selected side',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  'custom': ExerciseCatalogEntry(
                    tracking: timed ? 'time' : 'reps',
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
        final notifier = container.read(activeWorkoutProvider.notifier);
        notifier.addExercise(exercise.copyWith(sprzet: ['Hantle']));
        await tester.runAsync(() async {
          await notifier.startSession();
          await notifier.logSet(
            exercise: exercise,
            weightKg: timed ? null : 20,
            reps: timed ? null : 10,
            seconds: timed ? 25 : null,
            side: 'both',
          );
          await notifier.logSet(
            exercise: exercise,
            weightKg: timed ? null : 22,
            reps: timed ? null : 8,
            seconds: timed ? 30 : null,
            side: 'both',
          );
          await notifier.logSet(
            exercise: exercise,
            seconds: 100,
            side: 'right',
          );
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Zmiana względem poprzedniej serii • Obie: ${timed ? '+5 s' : '+2 kg • −2 powt.'}',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Prawa'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Zmiana względem'), findsNothing);
      },
    );
  }

  test('sided PRs are independent; last set is side-specific', () async {
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
    expect(
      await notifier.logSet(exercise: exercise, weightKg: 100, reps: 10),
      isTrue,
    );
    for (final side in ['left', 'right', 'both']) {
      expect(
        await notifier.logSet(
          exercise: exercise,
          weightKg: 20,
          reps: 10,
          side: side,
        ),
        isTrue,
      );
      expect(
        await notifier.logSet(
          exercise: exercise,
          weightKg: 21,
          reps: 9,
          side: side,
        ),
        isTrue,
      );
      expect(
        container.read(activeWorkoutProvider).loggedSets.last.comparison,
        '+1 kg • −1 powt.',
      );
    }
    expect(await db.select(db.personalRecords).get(), hasLength(7));
    final repo = container.read(workoutRepositoryProvider);
    expect((await repo.getLastSet('custom', side: 'left'))!.side, 'left');
    expect((await repo.getLastSet('custom'))!.side, isNull);
    for (final side in [null, 'left', 'right', 'both']) {
      expect(
        await notifier.logSet(exercise: exercise, reps: 10, side: side),
        isFalse,
      );
      expect(
        await notifier.logSet(exercise: exercise, seconds: 20, side: side),
        isFalse,
      );
      expect(
        await notifier.logSet(exercise: exercise, seconds: 25, side: side),
        isFalse,
      );
      expect(
        container.read(activeWorkoutProvider).loggedSets.last.comparison,
        '+5 s',
      );
    }
    expect(await db.select(db.personalRecords).get(), hasLength(7));
  });
}
