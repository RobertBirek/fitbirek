import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/workout/providers/session_recovery_provider.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'session_tracking_test.dart' show exercise;
import '../planner/structured_plan_persistence_test.dart' show structure;

class LateDeleteRepository extends WorkoutRepository {
  LateDeleteRepository(this.db) : super(db);
  final AppDatabase db;
  @override
  Future<List<SetLogData>> getSetsForSession(int id) async {
    final sets = await super.getSetsForSession(id);
    await (db.update(db.workoutSessions)..where((s) => s.id.equals(id))).write(
      WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.now().toUtc())),
    );
    return sets;
  }
}

void main() {
  test(
    'delete while restore awaits must not publish a stale active session',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      var c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      await c
          .read(activeWorkoutProvider.notifier)
          .startSession(guidance: WorkoutGuidance.start(structure));
      await c.read(activeWorkoutProvider.notifier).flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      c.dispose();
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(LateDeleteRepository(db)),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      expect(
        await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
        isFalse,
      );
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
    },
  );
  for (final repeat in [false, true]) {
    testWidgets(
      'fresh real route offers explicit recovery, restores UUID and paused checkpoint without writes repeat=$repeat',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
              'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
              (_) async =>
                  const StandardMessageCodec().encodeMessage(<Object?>[null]),
            );
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        var c = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        late String uuid;
        late int operations;
        late int records;
        await tester.runAsync(() async {
          await db
              .into(db.syncState)
              .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
          final n = c.read(activeWorkoutProvider.notifier);
          await n.startSession(
            guidance: repeat ? null : WorkoutGuidance.start(structure),
          );
          uuid = c.read(activeWorkoutProvider).sessionSyncId!;
          if (repeat) {
            await db
                .into(db.exercises)
                .insert(
                  ExercisesCompanion.insert(
                    id: exercise.id,
                    nazwaPl: exercise.nazwaPl,
                    nazwaEn: '',
                    partiaGlowna: '',
                    partieWspierajace: '[]',
                    typ: '',
                    sprzet: '[]',
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
            n.addExercise(exercise);
            n.updateDraft({
              'repeatTargets': {
                'version': 1,
                'targets': [
                  RepeatSetTarget(
                    exerciseId: exercise.id,
                    name: exercise.nazwaPl,
                    reps: 9,
                    seconds: 10,
                    side: 'left',
                  ).toJson(),
                  RepeatSetTarget(
                    exerciseId: exercise.id,
                    name: exercise.nazwaPl,
                    reps: 7,
                    seconds: 20,
                    weightKg: 5,
                    side: 'right',
                    variantId: 'variant-snapshot',
                    variantLabel: 'Wariant historyczny',
                  ).toJson(),
                ],
              },
            });
            await n.flushDraft();
            // The only real write is explicit: recovery must retain this cursor,
            // not infer it from all session logs or create the next target as a set.
            await n.logSet(
              exercise: exercise,
              reps: 9,
              seconds: 10,
              side: 'left',
            );
          }
          final timer = IntervalTimer(
            IntervalConfig(preparation: 0, work: 30, rest: 0, rounds: 2),
          )..start();
          n.updateDraft({
            'seconds': '17',
            'side': 'left',
            'rpe': 7,
            if (!repeat) 'timer': timer.checkpoint(),
          });
          await n.flushDraft();
          operations = (await db.syncDao.pendingOperations()).length;
          records = (await db.select(db.personalRecords).get()).length;
          c.dispose();
          c = ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              authStateProvider.overrideWith(
                (ref) =>
                    throw StateError('Recovery must not initialize auth/HTTP'),
              ),
            ],
          );
        });
        final router = createRouter(
          readAuthState: () => const AuthState.signedIn('a'),
          readOnboardingComplete: () => true,
          initialLocation: '/workout/session',
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
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Wybierz ćwiczenia, aby zacząć logować serie'),
          findsNothing,
        );
        expect(find.text('Wznów trening'), findsOneWidget);
        expect(c.read(activeWorkoutProvider).isActive, isFalse);
        await tester.runAsync(() async {
          expect((await db.syncDao.pendingOperations()).length, operations);
          await tester.tap(find.text('Wznów trening'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        final active = c.read(activeWorkoutProvider);
        expect(active.sessionSyncId, uuid);
        expect(active.draft['side'], 'left');
        expect(active.draft['seconds'], '17');
        if (!repeat) {
          expect(
            IntervalTimer.restore(
              Map<String, dynamic>.from(active.draft['timer'] as Map),
            ).paused,
            isTrue,
          );
        }
        if (repeat) {
          expect(active.repeatCompletedCount, 1);
          expect(active.repeatTarget!.reps, 7);
          expect(active.repeatTarget!.seconds, 20);
          expect(active.repeatTarget!.side, 'right');
          expect(active.repeatTarget!.variantId, 'variant-snapshot');
          expect(find.text('Powtórzenie wykonania • seria 2'), findsOneWidget);
          expect(find.textContaining('Wariant historyczny'), findsOneWidget);
        } else {
          expect(find.textContaining('Cel planu:'), findsOneWidget);
        }
        await tester.runAsync(() async {
          expect(await db.select(db.setsLog).get(), hasLength(repeat ? 1 : 0));
          expect(await db.select(db.personalRecords).get(), hasLength(records));
          expect((await db.syncDao.pendingOperations()).length, operations);
          expect(
            (await db.select(db.workoutSessions).get()).single.syncId,
            uuid,
          );
          expect(
            jsonDecode(
              (await db.select(db.workoutDrafts).getSingle()).payloadJson,
            )['fields']['seconds'],
            '17',
          );
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  }

  testWidgets(
    'loading, read failure retry and multiple explicit choices, no automatic selection',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      var attempts = 0;
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sessionRecoveryProvider.overrideWith((ref) {
            attempts++;
            return attempts == 1
                ? Stream<SessionRecovery>.error(StateError('disk'))
                : Stream.value(
                    SessionRecovery('a', 0, [
                      RecoverableSession(1, 'one', DateTime(2026), null),
                      RecoverableSession(
                        2,
                        'two',
                        DateTime(2026),
                        'Brak lokalnego szkicu tej sesji.',
                      ),
                      RecoverableSession(3, 'three', DateTime(2026), null),
                    ]),
                  );
          }),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ActiveSessionPage()),
        ),
      );
      expect(find.text('Sprawdzanie zapisanej sesji…'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        find.text('Nie udało się odczytać zapisanej sesji.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Spróbuj ponownie'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.textContaining('kilka aktywnych sesji'), findsOneWidget);
      expect(find.text('Wznów trening'), findsNWidgets(2));
      expect(find.textContaining('Brak lokalnego szkicu'), findsOneWidget);
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect(find.text('Zakończ'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
