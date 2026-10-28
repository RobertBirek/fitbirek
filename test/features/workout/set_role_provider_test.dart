import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'session_tracking_test.dart' show exercise;

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late WorkoutRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    repo = c.read(workoutRepositoryProvider);
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: exercise.id,
            nazwaPl: exercise.nazwaPl,
            nazwaEn: '',
            partiaGlowna: '',
            partieWspierajace: '[]',
            sprzet: '[]',
            typ: '',
            poziom: '',
            wzorzecRuchu: '',
            seriexPowtorzenia: '',
            tempo: '',
            kluczoweWskazowki: '[]',
            czesteBledy: '[]',
            progresja: '',
            regresja: '',
            zrodlo: '',
          ),
        );
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  test('new manual writes choose working explicitly', () async {
    final n = c.read(activeWorkoutProvider.notifier);
    await n.startSession();
    await n.logSet(exercise: exercise, reps: 8);
    expect((await db.select(db.setsLog).getSingle()).setRole, 'working');
  });

  for (final role in ['warmup', null]) {
    test('repeat preserves $role; warmup cannot create PR', () async {
      final source = await repo.startSession(accountId: 'a');
      await repo.logSet(
        sessionId: source,
        exerciseId: exercise.id,
        exerciseNamePl: exercise.nazwaPl,
        setNumber: 1,
        weightKg: 100,
        reps: 10,
        setRole: role,
        accountId: 'a',
      );
      await repo.finishSession(source, DateTime.now(), accountId: 'a');
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      expect(await n.confirmRepeat(request), isTrue);
      final isPr = await n.logSet(exercise: exercise, weightKg: 200, reps: 10);
      final sets = await repo.getSetsForSession(
        c.read(activeWorkoutProvider).sessionId!,
      );
      expect(sets.single.setRole, role);
      expect(isPr, role == null);
      expect(
        await db.select(db.personalRecords).get(),
        role == null ? hasLength(1) : isEmpty,
      );
    });
  }

  test(
    'PR baseline uses working history without rewriting legacy PR',
    () async {
      final source = await repo.startSession(accountId: 'a');
      await repo.logSet(
        sessionId: source,
        exerciseId: exercise.id,
        exerciseNamePl: exercise.nazwaPl,
        setNumber: 1,
        weightKg: 100,
        reps: 10,
        setRole: 'warmup',
        accountId: 'a',
      );
      await repo.logSet(
        sessionId: source,
        exerciseId: exercise.id,
        exerciseNamePl: exercise.nazwaPl,
        setNumber: 2,
        weightKg: 30,
        reps: 10,
        setRole: 'working',
        accountId: 'a',
      );
      await repo.finishSession(source, DateTime.now(), accountId: 'a');
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession();
      expect(
        await n.logSet(exercise: exercise, weightKg: 20, reps: 10),
        isFalse,
      );
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(
        await n.logSet(exercise: exercise, weightKg: 40, reps: 10),
        isTrue,
      );
      expect(await db.select(db.personalRecords).get(), hasLength(1));
    },
  );
}
