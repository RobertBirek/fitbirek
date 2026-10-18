import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'session_tracking_test.dart' show exercise;
import 'package:fitbirek_training/features/workout/presentation/widgets/repeat_workout_dialog.dart';
import 'package:fitbirek_training/features/workout/presentation/widgets/repeat_set_panel.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/data/exercise_variants_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import '../../core/profile_collections_sync_test.dart' show saveProfile;

class RepeatAuthority extends CachedAuthWriteAuthority {
  int serial = 0;
  String account = 'a';
  @override
  int get epoch => serial;
  @override
  AuthState get state => AuthState.signedIn(account);
  void switchTo(String next) {
    account = next;
    serial++;
  }
}

class PausedRepeatRepository extends WorkoutRepository {
  PausedRepeatRepository(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<Map<String, Object?>> saveDraft({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required Map<String, Object?> payload,
    required bool Function() guard,
  }) async {
    final saved = await super.saveDraft(
      sessionId: sessionId,
      sessionSyncId: sessionSyncId,
      accountId: accountId,
      payload: payload,
      guard: guard,
    );
    entered.complete();
    await release.future;
    return saved;
  }
}

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;
  late ProviderContainer c;
  late int source;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
    c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            accountId: 'a',
            deviceId: 'd',
            offlineAccess: const Value(true),
          ),
        );
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: exercise.id,
            nazwaPl: exercise.nazwaPl,
            nazwaEn: '',
            partiaGlowna: '',
            partieWspierajace: '[]',
            typ: exercise.typ,
            sprzet: jsonEncode(exercise.sprzet),
            poziom: exercise.poziom,
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
    source = await repo.startSession(accountId: 'a');
    for (final reps in [8, 5]) {
      final id = await repo.logSet(
        sessionId: source,
        exerciseId: exercise.id,
        exerciseNamePl: exercise.nazwaPl,
        setNumber: reps,
        reps: reps,
        weightKg: 10,
        rpe: 9,
        accountId: 'a',
      );
      await (db.update(db.setsLog)..where((s) => s.id.equals(id))).write(
        SetsLogCompanion(timestamp: Value(DateTime.utc(2026, 1, 9 - reps))),
      );
    }
    await repo.finishSession(source, DateTime.now(), accountId: 'a');
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<void> measuredHistory({int? reps, double? weightKg}) async {
    source = await repo.startSession(accountId: 'a');
    await repo.logSet(
      sessionId: source,
      exerciseId: exercise.id,
      exerciseNamePl: exercise.nazwaPl,
      setNumber: 1,
      reps: reps,
      seconds: 30,
      weightKg: weightKg,
      accountId: 'a',
    );
    await repo.finishSession(source, DateTime.now(), accountId: 'a');
  }

  test(
    'actual reps plus seconds survive preview, durable reopen and explicit log',
    () async {
      await measuredHistory(reps: 3, weightKg: 10);
      final old = await repo.getSetsForSession(source);
      var n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      expect(request.preview.issues, isEmpty);
      final target = request.preview.repeat!.targets.single;
      expect([target.reps, target.seconds, target.weightKg], [3, 30, 10]);
      expect(await n.confirmRepeat(request), isTrue);
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      await n.flushDraft();
      c.dispose();
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      n = c.read(activeWorkoutProvider.notifier);
      expect(await n.resumeSession(uuid), isTrue);
      final active = c.read(activeWorkoutProvider);
      expect(
        [
          active.repeatTarget!.reps,
          active.repeatTarget!.seconds,
          active.repeatTarget!.weightKg,
        ],
        [3, 30, 10],
      );
      expect(active.draft['timer'], isNull);
      expect(await repo.getSetsForSession(active.sessionId!), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      await n.logSet(exercise: exercise, reps: 3, seconds: 30, weightKg: 10);
      final logged = (await repo.getSetsForSession(active.sessionId!)).single;
      expect(
        [logged.powtorzenia, logged.czasSekund, logged.ciezarKg],
        [3, 30, 10],
      );
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(await repo.getSetsForSession(source), old);
    },
  );

  for (final mixed in [false, true]) {
    testWidgets('preview shows all measurements and load mixed=$mixed', (
      tester,
    ) async {
      await tester.runAsync(
        () => measuredHistory(reps: mixed ? 3 : null, weightKg: 10),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: RepeatWorkoutDialog(sessionId: source)),
        ),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Potwierdzone wykonanie (wszystkie serie)'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('30 s'), findsOneWidget);
      expect(find.textContaining('10.0 kg'), findsOneWidget);
      if (mixed) expect(find.textContaining('3 powt.'), findsOneWidget);
    });
  }

  for (final scenario in ['mixed', 'timed', 'edit', 'clear', 'null']) {
    testWidgets(
      'explicit time-based log preserves editable nullable load: $scenario',
      (tester) async {
        final mixed = scenario == 'mixed';
        await tester.runAsync(() async {
          await measuredHistory(
            reps: mixed ? 3 : null,
            weightKg: scenario == 'null' ? null : 10,
          );
          final n = c.read(activeWorkoutProvider.notifier);
          expect(
            await n.confirmRepeat(
              await n.previewRepeat(source, RepeatMode.execution),
            ),
            isTrue,
          );
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: Scaffold(body: RepeatSetPanel())),
          ),
        );
        await tester.pumpAndSettle();
        Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        final load = field('Ciężar (kg, opcjonalnie)');
        expect(load, findsOneWidget);
        expect(
          tester.widget<TextField>(load).controller!.text,
          scenario == 'null' ? '' : '10.0',
        );
        expect(
          tester.widget<TextField>(field('Sekundy')).controller!.text,
          '30',
        );
        if (mixed) {
          expect(
            tester.widget<TextField>(field('Powtórzenia')).controller!.text,
            '3',
          );
        }
        expect(
          await tester.runAsync(
            () => repo.getSetsForSession(
              c.read(activeWorkoutProvider).sessionId!,
            ),
          ),
          isEmpty,
        );
        expect(
          await tester.runAsync(() => db.select(db.personalRecords).get()),
          isEmpty,
        );
        if (scenario == 'clear') await tester.enterText(load, '');
        if (scenario == 'edit') await tester.enterText(load, '12,5');
        await tester.ensureVisible(find.text('Zapisz tę serię'));
        await tester.runAsync(() async {
          await tester.tap(find.text('Zapisz tę serię'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        final logs = await tester.runAsync(
          () =>
              repo.getSetsForSession(c.read(activeWorkoutProvider).sessionId!),
        );
        expect(logs, hasLength(1));
        expect(logs!.single.ciezarKg, switch (scenario) {
          'null' || 'clear' => null,
          'edit' => 12.5,
          _ => 10,
        });
        expect(logs.single.czasSekund, 30);
        expect(logs.single.powtorzenia, mixed ? 3 : null);
        expect(
          await tester.runAsync(() => db.select(db.personalRecords).get()),
          isEmpty,
        );
      },
    );
  }

  test(
    'confirm creates new UUID with no sets/PR; duplicate confirm and reload',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      final old = (await db.workoutDao.getSession(source))!;
      final starts = await Future.wait([
        n.confirmRepeat(request),
        n.confirmRepeat(request),
      ]);
      expect(starts, [true, true]);
      final active = c.read(activeWorkoutProvider);
      expect(active.sessionSyncId, isNot(old.syncId));
      expect(await repo.getSetsForSession(active.sessionId!), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(active.repeatTarget!.reps, 8);
      expect(active.repeatTarget!.previousRpe, 9);
      expect(active.draft['rpe'], isNull);
      final uuid = active.sessionSyncId!;
      await n.flushDraft();
      c.dispose();
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      expect(
        await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).repeatTarget!.reps, 8);
      await c
          .read(activeWorkoutProvider.notifier)
          .logSet(exercise: exercise, reps: 8, weightKg: 10);
      expect(c.read(activeWorkoutProvider).repeatTarget!.reps, 5);
      expect(await db.workoutDao.getSession(source), old);
      expect((await db.select(db.workoutSessions).get()).length, 2);
    },
  );
  test(
    'source tombstone after preview blocks start without partial writes',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      await (db.update(db.workoutSessions)..where((s) => s.id.equals(source)))
          .write(WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.now())));
      expect(await n.confirmRepeat(request), isFalse);
      expect((await db.select(db.workoutSessions).get()).length, 1);
    },
  );
  test(
    'active session is not abandoned, missing exercise is explained',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      await n.startSession();
      final active = c.read(activeWorkoutProvider).sessionSyncId;
      expect(await n.confirmRepeat(request), isFalse);
      expect(c.read(activeWorkoutProvider).sessionSyncId, active);
      await db.delete(db.exercises).go();
      final blocked = await n.previewRepeat(source, RepeatMode.execution);
      expect(blocked.preview.issues, isNotEmpty);
    },
  );
  test(
    'legacy source has no original snapshot and account switch refuses request',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      final original = await n.previewRepeat(source, RepeatMode.original);
      expect(original.preview.issues, isNotEmpty);
      final execution = await n.previewRepeat(source, RepeatMode.execution);
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(accountId: Value('b')));
      expect(await n.confirmRepeat(execution), isFalse);
    },
  );
  test(
    'original uses exact snapshot with fresh guidance and empty fields',
    () async {
      final plan =
          jsonDecode(jsonEncode(structure.toJson())) as Map<String, dynamic>;
      plan['blocks'][0]['exerciseId'] = exercise.id;
      final original = WorkoutGuidance.validateJson({
        'schemaVersion': 1,
        'plan': plan,
        'events': [],
      }).replace(0, 'missing-replacement').skip(0);
      await (db.update(
        db.workoutSessions,
      )..where((s) => s.id.equals(source))).write(
        WorkoutSessionsCompanion(
          guidanceJson: Value(jsonEncode(original.toJson())),
        ),
      );
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.original);
      expect(request.preview.canStart, isTrue);
      expect(await n.confirmRepeat(request), isTrue);
      final active = c.read(activeWorkoutProvider);
      expect(active.guidance!.plan.toJson(), plan);
      expect(active.guidance!.events, isEmpty);
      expect(active.draft, isEmpty);
      expect(await repo.getSetsForSession(active.sessionId!), isEmpty);
    },
  );
  test(
    'missing variant blocks preview without silently dropping its values',
    () async {
      const uuid = '11111111-1111-4111-8111-111111111111';
      await (db.update(
        db.setsLog,
      )..where((s) => s.sesjaId.equals(source))).write(
        const SetsLogCompanion(
          variantId: Value(uuid),
          variantLabel: Value('Usunięty'),
        ),
      );
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      expect(request.preview.canStart, isFalse);
      expect(
        request.preview.issues.join(),
        contains('Nie zastąpiono go bazowym'),
      );
      expect(request.preview.repeat!.targets.first.variantId, uuid);
      expect(request.preview.repeat!.targets.first.reps, 8);
      expect(await n.confirmRepeat(request), isFalse);
    },
  );
  test(
    'changed source values and database-only active session refuse confirm',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      await (db.update(db.setsLog)..where((s) => s.sesjaId.equals(source)))
          .write(const SetsLogCompanion(powtorzenia: Value(12)));
      final before = (await db.syncDao.pendingOperations()).length;
      expect(await n.confirmRepeat(request), isFalse);
      expect((await db.syncDao.pendingOperations()).length, before);
      final next = await n.previewRepeat(source, RepeatMode.execution);
      await repo.startSession(accountId: 'a');
      expect(await n.confirmRepeat(next), isFalse);
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect((await db.select(db.workoutSessions).get()).length, 2);
    },
  );
  test('external additional set does not consume a target on reload', () async {
    final n = c.read(activeWorkoutProvider.notifier);
    expect(
      await n.confirmRepeat(
        await n.previewRepeat(source, RepeatMode.execution),
      ),
      isTrue,
    );
    final state = c.read(activeWorkoutProvider);
    await repo.logSet(
      sessionId: state.sessionId!,
      exerciseId: exercise.id,
      exerciseNamePl: exercise.nazwaPl,
      setNumber: 10,
      reps: 99,
      accountId: 'a',
    );
    await n.flushDraft();
    c.dispose();
    c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    final restored = c.read(activeWorkoutProvider.notifier);
    expect(await restored.resumeSession(state.sessionSyncId!), isTrue);
    expect(c.read(activeWorkoutProvider).repeatTarget!.reps, 8);
    await restored.logSet(exercise: exercise, reps: 8, weightKg: 10);
    expect(c.read(activeWorkoutProvider).repeatTarget!.reps, 5);
    // Completion is committed with the actual set, not a later UI draft flush.
    c.dispose();
    c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    expect(
      await c
          .read(activeWorkoutProvider.notifier)
          .resumeSession(state.sessionSyncId!),
      isTrue,
    );
    expect(c.read(activeWorkoutProvider).repeatTarget!.reps, 5);
  });
  test(
    'A–B–A invalidates preview even when database binding is A again',
    () async {
      c.dispose();
      final authority = RepeatAuthority();
      addTearDown(authority.revision.dispose);
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        ],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      authority.switchTo('b');
      authority.switchTo('a');
      expect(await n.confirmRepeat(request), isFalse);
      expect((await db.select(db.workoutSessions).get()).length, 1);
    },
  );
  test(
    'authority loss during start rolls back session, outbox and draft together',
    () async {
      c.dispose();
      final authority = RepeatAuthority(), paused = PausedRepeatRepository(db);
      addTearDown(authority.revision.dispose);
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          workoutRepositoryProvider.overrideWithValue(paused),
        ],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      final before = (await db.syncDao.pendingOperations())
          .map((s) => s.toJson())
          .toList();
      final write = n.confirmRepeat(request);
      await paused.entered.future;
      authority.switchTo('b');
      authority.switchTo('a');
      paused.release.complete();
      expect(await write, isFalse);
      expect((await db.select(db.workoutSessions).get()).length, 1);
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect(
        (await db.syncDao.pendingOperations()).map((s) => s.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'mixed live variant reps and nullable-side timed extra keep exact targets',
    () async {
      await saveProfile(db);
      final variants = ExerciseVariantsRepository(
        UserCollectionsRepository(db),
      );
      final variant = await variants.create(
        'a',
        exercise.id,
        'Pauza',
        pauseSeconds: 2,
      );
      final rows = await repo.getSetsForSession(source);
      rows.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await (db.update(
        db.setsLog,
      )..where((s) => s.id.equals(rows.first.id))).write(
        SetsLogCompanion(
          side: const Value('left'),
          variantId: Value(variant),
          variantLabel: const Value('Pauza'),
        ),
      );
      await (db.update(
        db.setsLog,
      )..where((s) => s.id.equals(rows.last.id))).write(
        const SetsLogCompanion(
          side: Value(null),
          powtorzenia: Value(null),
          ciezarKg: Value(null),
          czasSekund: Value(17),
        ),
      );
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      expect(request.preview.canStart, isTrue);
      expect(await n.confirmRepeat(request), isTrue);
      expect(c.read(activeWorkoutProvider).repeatTarget!.variantId, variant);
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      await n.logSet(
        exercise: exercise,
        side: 'left',
        variantId: variant,
        reps: 8,
        weightKg: 10,
      );
      final target = c.read(activeWorkoutProvider).repeatTarget!;
      expect(target.side, isNull);
      expect(target.variantId, isNull);
      expect(target.seconds, 17);
      expect(target.reps, isNull);
      await n.logSet(exercise: exercise, seconds: 17);
      expect(c.read(activeWorkoutProvider).repeatTarget, isNull);
      final newSets = await repo.getSetsForSession(
        c.read(activeWorkoutProvider).sessionId!,
      );
      expect(newSets.map((s) => s.variantId), [variant, null]);
      expect(newSets.map((s) => s.side), ['left', null]);
      expect(newSets.map((s) => s.czasSekund), [null, 17]);
      expect(newSets.every((s) => s.rpe == null), isTrue);
    },
  );
  test(
    'variant deleted after preview is revalidated before any start write',
    () async {
      await saveProfile(db);
      final variants = ExerciseVariantsRepository(
        UserCollectionsRepository(db),
      );
      final variant = await variants.create(
        'a',
        exercise.id,
        'Pauza',
        pauseSeconds: 2,
      );
      await (db.update(
        db.setsLog,
      )..where((s) => s.sesjaId.equals(source))).write(
        SetsLogCompanion(
          variantId: Value(variant),
          variantLabel: const Value('Pauza'),
        ),
      );
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.execution);
      expect(request.preview.canStart, isTrue);
      await variants.delete('a', variant);
      final before = (await db.syncDao.pendingOperations()).length;
      expect(await n.confirmRepeat(request), isFalse);
      expect((await db.syncDao.pendingOperations()).length, before);
      expect((await db.select(db.workoutSessions).get()).length, 1);
    },
  );
  testWidgets('preview has two explicit choices and confirm alone starts', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: RepeatWorkoutDialog(sessionId: source)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oryginalny plan (snapshot)'), findsOneWidget);
    expect(
      find.text('Potwierdzone wykonanie (wszystkie serie)'),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Potwierdzone wykonanie (wszystkie serie)'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('RPE poprzednio: 9'), findsNWidgets(2));
    expect(c.read(activeWorkoutProvider).isActive, isFalse);
    expect(
      await tester
          .runAsync(() => db.select(db.workoutSessions).get())
          .then((s) => s!.length),
      1,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Rozpocznij nową sesję'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(c.read(activeWorkoutProvider).isActive, isTrue);
    expect(
      await tester.runAsync(
        () => repo.getSetsForSession(c.read(activeWorkoutProvider).sessionId!),
      ),
      isEmpty,
    );
  });
  testWidgets(
    'per-set prefill advances only after explicit log, RPE stays empty',
    (tester) async {
      final n = c.read(activeWorkoutProvider.notifier);
      expect(
        await tester.runAsync(
          () async => n.confirmRepeat(
            await n.previewRepeat(source, RepeatMode.execution),
          ),
        ),
        isTrue,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: Scaffold(body: RepeatSetPanel())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '8'), findsOneWidget);
      expect(find.widgetWithText(TextField, '9'), findsNothing);
      expect(
        await tester.runAsync(
          () =>
              repo.getSetsForSession(c.read(activeWorkoutProvider).sessionId!),
        ),
        isEmpty,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Zapisz tę serię'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '5'), findsOneWidget);
      final sets = await tester.runAsync(
        () => repo.getSetsForSession(c.read(activeWorkoutProvider).sessionId!),
      );
      expect(sets!.length, 1);
      expect(sets.single.rpe, isNull);
    },
  );
}
