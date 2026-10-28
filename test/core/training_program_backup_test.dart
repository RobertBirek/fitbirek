import 'dart:convert';
import 'package:drift/drift.dart' show Value, Uint8List, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'profile_collections_sync_test.dart' show saveProfile;
import 'training_sets_programs_domain_test.dart'
    show collection, programEntry, programId, planA, planB, planJson;

Future<void> seedProgramBackup(
  AppDatabase db, {
  bool workingEvidence = false,
}) async {
  await saveProfile(db);
  final repo = WorkoutRepository(db);
  final session = await repo.startSession(
    guidance: WorkoutGuidance.start(StructuredPlan.fromJson(planJson())),
  );
  await repo.logSet(
    sessionId: session,
    exerciseId: 'cw001',
    exerciseNamePl: 'X',
    setNumber: 1,
    reps: 8,
    setRole: 'warmup',
  );
  final s = await db.workoutDao.getSession(session);
  final set = (await repo.getSetsForSession(session)).single;
  if (workingEvidence) {
    await repo.logSet(
      sessionId: session,
      exerciseId: 'cw001',
      exerciseNamePl: 'X',
      setNumber: 2,
      reps: 6,
      weightKg: 18,
      setRole: 'working',
    );
  }
  var guidance = WorkoutGuidance.tryRead(
    s!.guidanceJson,
  )!.link(0, set.syncId, targetId: 'a');
  if (workingEvidence) {
    final working = (await repo.getSetsForSession(
      session,
    )).singleWhere((s) => s.setRole == 'working');
    guidance = guidance.link(0, working.syncId, targetId: 'b');
  }
  await db.workoutDao.updateSession(
    session,
    WorkoutSessionsCompanion(
      dataKoniec: Value(DateTime.utc(2026, 10, 28)),
      guidanceJson: Value(jsonEncode(guidance.toJson())),
    ),
  );
  for (final id in [planA, planB]) {
    await db
        .into(db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(
            nazwa: id,
            cwiczeniaIds: '["cw001"]',
            cel: 'mix',
            syncId: Value(id),
            structureJson: Value(jsonEncode(planJson())),
          ),
        );
  }
  final program = {
    ...programEntry(),
    'endBeforeDate': '2026-11-01',
    'deletedAtUtc': '2026-10-28T00:00:00.000Z',
  };
  final override =
      {
        ...programEntry(),
        'id': TrainingPrograms.occurrenceId(
          programId,
          CalendarDay.parse('2026-10-28'),
        ),
        'kind': 'programOverride',
        'programId': programId,
        'originalDate': '2026-10-28',
        'movedDate': '2026-10-30',
        'state': 'completed',
        'sessionSyncId': s.syncId,
        'programSnapshot': TrainingPrograms.snapshot(program),
      }..removeWhere(
        (k, v) => ['planSyncIds', 'weekdays', 'effectiveFromDate'].contains(k),
      );
  await db
      .update(db.userProfiles)
      .write(
        UserProfilesCompanion(
          trainingProgramsJson: Value(
            jsonEncode(collection([program, override])),
          ),
        ),
      );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());
  for (final missing in ['plan', 'linkedSet']) {
    test(
      'genuinely missing local $missing refuses before retaining a dangling original',
      () async {
        await seedProgramBackup(db);
        final validArchive = await BackupService(db).exportToBytes();
        if (missing == 'plan') {
          await (db.delete(
            db.workoutPlans,
          )..where((p) => p.syncId.equals(planA))).go();
        } else {
          await db.delete(db.setsLog).go();
        }
        final profile = (await db.userProfileDao.watchProfileOnce())!.toJson();
        final outbox = (await db.select(db.syncOutbox).get())
            .map((r) => r.toJson())
            .toList();
        final result = await BackupService(db).importFromBytes(validArchive);
        expect(result.success, isFalse);
        expect((await db.userProfileDao.watchProfileOnce())!.toJson(), profile);
        expect(
          (await db.select(db.syncOutbox).get())
              .map((r) => r.toJson())
              .toList(),
          outbox,
        );
      },
    );
  }
  for (final completed in [false, true]) {
    test(
      'own backup stays restorable through same-db restore then fresh-db restore, completed=$completed',
      () async {
        await seedProgramBackup(db, workingEvidence: true);
        if (!completed) {
          final json =
              jsonDecode(
                    (await db.userProfileDao.watchProfileOnce())!
                        .trainingProgramsJson!,
                  )
                  as Map;
          (json['entries'] as List).removeWhere(
            (e) => e['kind'] == 'programOverride',
          );
          await db
              .update(db.userProfiles)
              .write(
                UserProfilesCompanion(
                  trainingProgramsJson: Value(jsonEncode(json)),
                ),
              );
        }
        final originalEntries =
            (jsonDecode(
                      (await db.userProfileDao.watchProfileOnce())!
                          .trainingProgramsJson!,
                    )['entries']
                    as List)
                .cast<Map>();
        final sourceSessions = await db.select(db.workoutSessions).get();
        final sourceSets = await db.select(db.setsLog).get();
        await db.customStatement('UPDATE sync_outbox SET attempted = 1');
        final attempted = (await db.select(db.syncOutbox).get())
            .map((r) => r.toJson())
            .toList();
        final firstBytes = await BackupService(db).exportToBytes();
        final first = await BackupService(db).importFromBytes(firstBytes);
        expect(first.success, isTrue, reason: first.message);
        final entriesAfterFirst =
            (jsonDecode(
                      (await db.userProfileDao.watchProfileOnce())!
                          .trainingProgramsJson!,
                    )['entries']
                    as List)
                .cast<Map>();
        for (final original in originalEntries) {
          expect(
            entriesAfterFirst.singleWhere((e) => e['id'] == original['id']),
            original,
          );
        }
        expect(
          (await db.select(db.syncOutbox).get())
              .where((r) => r.attempted)
              .map((r) => r.toJson())
              .toList(),
          attempted,
        );

        // The file is generated by the successful restore itself, not patched to
        // add missing records/maps or to drop immutable originals and overrides.
        final secondBytes = await BackupService(db).exportToBytes();
        final fresh = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(fresh.close);
        final second = await BackupService(fresh).importFromBytes(secondBytes);
        expect(second.success, isTrue, reason: second.message);
        final entries =
            (jsonDecode(
                      (await fresh.userProfileDao.watchProfileOnce())!
                          .trainingProgramsJson!,
                    )['entries']
                    as List)
                .cast<Map>();
        expect(entries, hasLength(completed ? 4 : 2));
        final programs = entries.where((e) => e['kind'] == 'program').toList();
        final plans = await fresh.select(fresh.workoutPlans).get();
        final sessions = await fresh.select(fresh.workoutSessions).get();
        final sets = await fresh.select(fresh.setsLog).get();
        expect(plans, hasLength(4));
        expect(plans.where((p) => p.deletedAtUtc != null), hasLength(2));
        expect(
          sessions.where((s) => s.deletedAtUtc != null),
          hasLength(completed ? 1 : 0),
        );
        for (final p in programs) {
          expect(p['endBeforeDate'], '2026-11-01');
          expect(p['deletedAtUtc'], originalEntries.first['deletedAtUtc']);
          expect(
            p['effectiveFromDate'],
            originalEntries.first['effectiveFromDate'],
          );
          expect(p['weekdays'], originalEntries.first['weekdays']);
          expect(entriesAfterFirst.any((old) => old['id'] == p['id']), isFalse);
          final ids = p['planSyncIds'] as List;
          expect(ids, hasLength(2));
          expect(ids.toSet(), hasLength(2));
          for (final id in ids) {
            final plan = plans.singleWhere((row) => row.syncId == id);
            expect(jsonDecode(plan.structureJson!), planJson());
          }
          if (completed) {
            final override = entries.singleWhere(
              (e) =>
                  e['kind'] == 'programOverride' && e['programId'] == p['id'],
            );
            expect(
              override['id'],
              TrainingPrograms.occurrenceId(
                p['id'] as String,
                CalendarDay.parse('2026-10-28'),
              ),
            );
            expect(override['state'], 'completed');
            expect(override['movedDate'], '2026-10-30');
            expect((override['programSnapshot'] as Map)['planSyncIds'], ids);
            expect(
              (override['programSnapshot'] as Map)['endBeforeDate'],
              p['endBeforeDate'],
            );
            final proof = sessions.singleWhere(
              (s) => s.syncId == override['sessionSyncId'],
            );
            expect(proof.dataKoniec, sourceSessions.single.dataKoniec);
            expect(
              proof.deletedAtUtc != null,
              plans
                      .singleWhere((row) => row.syncId == ids.first)
                      .deletedAtUtc !=
                  null,
            );
          }
        }
        for (final session in sessions) {
          final guidance = WorkoutGuidance.tryRead(session.guidanceJson)!;
          expect(guidance.events.map((e) => e['targetId']), ['a', 'b']);
          for (final event in guidance.events) {
            final linked = sets.singleWhere(
              (s) => s.syncId == event['setSyncId'],
            );
            expect(linked.sesjaId, session.id);
            expect(linked.deletedAtUtc != null, session.deletedAtUtc != null);
            final original = sourceSets.singleWhere(
              (s) => s.setRole == linked.setRole,
            );
            expect(
              [
                linked.setRole,
                linked.ciezarKg,
                linked.powtorzenia,
                linked.czasSekund,
              ],
              [
                original.setRole,
                original.ciezarKg,
                original.powtorzenia,
                original.czasSekund,
              ],
            );
          }
        }
        // Archived/deleted proof remains invalid; only the copied live working
        // evidence participates in preparation, without hiding normal history.
        expect(
          await WorkoutRepository(
            fresh,
          ).getPreparationHistory('cw001', side: null),
          hasLength(1),
        );
        final third = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(third.close);
        final again = await BackupService(
          third,
        ).importFromBytes(await BackupService(fresh).exportToBytes());
        expect(again.success, isTrue, reason: again.message);
      },
    );
  }
  test(
    'missing entire sets section still refuses dangling performed guidance refs',
    () async {
      await seedProgramBackup(db);
      final archive =
          jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
              as Map;
      (archive['data'] as Map).remove('setsLog');
      final before = (await db.select(db.syncOutbox).get())
          .map((r) => r.toJson())
          .toList();
      final result = await BackupService(
        db,
      ).importFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(archive))));
      expect(result.success, isFalse);
      expect(
        (await db.select(db.syncOutbox).get()).map((r) => r.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'valid UUID reference casing does not break shared restore maps',
    () async {
      await seedProgramBackup(db);
      final archive =
          jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
              as Map;
      final data = archive['data'] as Map;
      final plans = data['workoutPlans'] as List;
      // Real UUIDs are case-insensitive. Use hex letters so the casing differs.
      const lower = 'aabbccdd-0000-4000-8000-000000000001';
      final programs =
          jsonDecode(
                data['userProfiles'].single['trainingProgramsJson'] as String,
              )
              as Map;
      for (final e in programs['entries'] as List) {
        final def = e['kind'] == 'program' ? e : e['programSnapshot'];
        (def['planSyncIds'] as List)[0] = lower;
      }
      plans.first['archivePlanSyncId'] = lower.toUpperCase();
      data['userProfiles'].single['trainingProgramsJson'] = jsonEncode(
        programs,
      );
      final result = await BackupService(
        db,
      ).importFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(archive))));
      expect(result.success, isTrue, reason: result.message);
    },
  );
  test(
    'foreign-session guidance link refuses restore, not remapped as evidence',
    () async {
      await seedProgramBackup(db);
      final repo = WorkoutRepository(db);
      final second = await repo.startSession();
      await repo.logSet(
        sessionId: second,
        exerciseId: 'cw001',
        exerciseNamePl: 'Foreign',
        setNumber: 1,
        reps: 8,
      );
      final foreign = (await repo.getSetsForSession(second)).single;
      final first = (await db.select(db.workoutSessions).get()).first;
      final g = WorkoutGuidance.tryRead(first.guidanceJson)!;
      await db.workoutDao.updateSession(
        first.id,
        WorkoutSessionsCompanion(
          guidanceJson: Value(
            jsonEncode({
              ...g.toJson(),
              'events': [
                {...g.events.single, 'setSyncId': foreign.syncId},
              ],
            }),
          ),
        ),
      );
      final bytes = await BackupService(db).exportToBytes();
      final before = (await db.select(db.syncOutbox).get())
          .map((r) => r.toJson())
          .toList();
      final result = await BackupService(db).importFromBytes(bytes);
      expect(result.success, isFalse);
      expect(
        (await db.select(db.syncOutbox).get()).map((r) => r.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'legacy restore without any profile cannot erase existing program history',
    () async {
      await seedProgramBackup(db);
      final before =
          (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson;
      final result = await BackupService(db).importFromBytes(
        Uint8List.fromList(utf8.encode('{"schemaVersion":1,"data":{}}')),
      );
      expect(result.success, isTrue, reason: result.message);
      expect(
        (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson,
        before,
      );
    },
  );
  test(
    'backup4 includes quarantined raw and pending bytes as inert recovery evidence',
    () async {
      const raw =
          '{"entityType":"workoutPlan","payload":{"structure":{"schemaVersion":3}}}';
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: '_syncPullQuarantine',
              entityId: 'raw',
              version: 1,
              recordJson: raw,
            ),
          );
      await WorkoutRepository(db).startSession();
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final pending = (await db.select(db.syncOutbox).get())
          .map((r) => r.toJson())
          .toList();
      final bytes = await BackupService(db).exportToBytes();
      final recovery =
          jsonDecode(utf8.decode(bytes))['data']['syncRecovery'] as Map;
      expect(recovery['deferredRecords'].single['recordJson'], raw);
      expect(recovery['outbox'], pending);
      final result = await BackupService(db).importFromBytes(bytes);
      expect(result.success, isTrue, reason: result.message);
      final rows = await db.select(db.syncDeferredRecords).get();
      expect(rows.singleWhere((r) => r.entityId == 'raw').recordJson, raw);
      final archive = jsonDecode(
        rows
            .singleWhere((r) => r.entityType == '_backupRecoveryArchive')
            .recordJson,
      );
      expect(archive['recovery'], recovery);
      expect(
        (await db.select(db.syncOutbox).get())
            .where((r) => r.attempted)
            .map((r) => r.toJson())
            .toList(),
        pending,
      );
    },
  );
  test(
    'backup4 forks program and occurrence, remaps all plan/session/set refs and retains originals',
    () async {
      await seedProgramBackup(db);
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final attempted = (await db.select(db.syncOutbox).get())
          .map((r) => r.toJson())
          .toList();
      final before =
          jsonDecode(
                (await db.userProfileDao.watchProfileOnce())!
                    .trainingProgramsJson!,
              )
              as Map;
      final bytes = await BackupService(db).exportToBytes();
      expect(jsonDecode(utf8.decode(bytes))['schemaVersion'], 4);
      final result = await BackupService(db).importFromBytes(bytes);
      expect(result.success, isTrue, reason: result.message);
      final entries =
          (jsonDecode(
                    (await db.userProfileDao.watchProfileOnce())!
                        .trainingProgramsJson!,
                  )['entries']
                  as List)
              .cast<Map>();
      expect(entries, hasLength(4));
      expect(
        entries.where((e) => e['id'] == programId).single,
        (before['entries'] as List).first,
      );
      final fork = entries.singleWhere(
        (e) => e['kind'] == 'program' && e['id'] != programId,
      );
      expect(fork['deletedAtUtc'], isNotNull);
      expect(fork['endBeforeDate'], '2026-11-01');
      final override = entries.singleWhere(
        (e) => e['kind'] == 'programOverride' && e['programId'] == fork['id'],
      );
      expect(
        override['id'],
        TrainingPrograms.occurrenceId(
          fork['id'] as String,
          CalendarDay.parse('2026-10-28'),
        ),
      );
      final plans = (await db.select(db.workoutPlans).get()).where(
        (p) => p.deletedAtUtc == null,
      );
      expect(fork['planSyncIds'], unorderedEquals(plans.map((p) => p.syncId)));
      expect(
        (override['programSnapshot'] as Map)['planSyncIds'],
        fork['planSyncIds'],
      );
      final sessions = (await db.select(db.workoutSessions).get())
          .where((s) => s.deletedAtUtc == null)
          .toList();
      expect(override['sessionSyncId'], sessions.single.syncId);
      final set = (await db.select(db.setsLog).get()).singleWhere(
        (s) => s.deletedAtUtc == null,
      );
      expect(set.setRole, 'warmup');
      final g = WorkoutGuidance.tryRead(sessions.single.guidanceJson)!;
      expect(g.events.single['targetId'], 'a');
      expect(g.events.single['setSyncId'], set.syncId);
      expect(
        (await db.select(db.syncOutbox).get())
            .where((o) => o.attempted)
            .map((r) => r.toJson())
            .toList(),
        attempted,
      );
    },
  );
  test(
    'missing program reference map refuses the whole import without changing attempted/raw',
    () async {
      await seedProgramBackup(db);
      final archive =
          jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
              as Map<String, dynamic>;
      ((archive['data'] as Map)['workoutPlans'] as List).removeLast();
      final before = (await db.select(db.userProfiles).getSingle()).toJson();
      final pending = (await db.select(db.syncOutbox).get())
          .map((o) => o.toJson())
          .toList();
      final result = await BackupService(
        db,
      ).importFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(archive))));
      expect(result.success, isFalse);
      expect((await db.select(db.userProfiles).getSingle()).toJson(), before);
      expect(
        (await db.select(db.syncOutbox).get()).map((o) => o.toJson()).toList(),
        pending,
      );
    },
  );
  test(
    'future local guidance is exported raw and restore refuses destructive replacement',
    () async {
      final session = await WorkoutRepository(db).startSession();
      const raw = '{"schemaVersion":3,"future":[1,2,3]}';
      await db.workoutDao.updateSession(
        session,
        const WorkoutSessionsCompanion(guidanceJson: Value(raw)),
      );
      final bytes = await BackupService(db).exportToBytes();
      expect(
        jsonDecode(
          utf8.decode(bytes),
        )['data']['workoutSessions'].single['guidanceJson'],
        raw,
      );
      final result = await BackupService(db).importFromBytes(
        Uint8List.fromList(utf8.encode('{"schemaVersion":1,"data":{}}')),
      );
      expect(result.success, isFalse);
      expect((await db.workoutDao.getSession(session))!.guidanceJson, raw);
    },
  );
  test(
    'fork exceeding combined500 incl tombstones rolls the entire restore back',
    () async {
      await seedProgramBackup(db);
      final bytes = await BackupService(db).exportToBytes();
      final original =
          jsonDecode(
                (await db.userProfileDao.watchProfileOnce())!
                    .trainingProgramsJson!,
              )
              as Map;
      final entries = (original['entries'] as List)
          .cast<Map<String, dynamic>>();
      for (var i = 0; i < 498; i++) {
        entries.add({
          ...programEntry(),
          'id': '30000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
        });
      }
      await db
          .update(db.userProfiles)
          .write(
            UserProfilesCompanion(
              trainingProgramsJson: Value(jsonEncode(collection(entries))),
            ),
          );
      final before = (await db.select(db.userProfiles).getSingle()).toJson();
      final pending = (await db.select(db.syncOutbox).get())
          .map((o) => o.toJson())
          .toList();
      final result = await BackupService(db).importFromBytes(bytes);
      expect(result.success, isFalse);
      expect((await db.select(db.userProfiles).getSingle()).toJson(), before);
      expect(
        (await db.select(db.syncOutbox).get()).map((o) => o.toJson()).toList(),
        pending,
      );
    },
  );
  for (final version in [1, 2, 3]) {
    test(
      'legacy backup$version without extension keeps existing program definitions',
      () async {
        await seedProgramBackup(db);
        final before =
            (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson;
        final archive =
            jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
                as Map;
        archive['schemaVersion'] = version;
        for (final p in archive['data']['userProfiles'] as List) {
          (p as Map).remove('trainingProgramsJson');
        }
        final result = await BackupService(
          db,
        ).importFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(archive))));
        expect(result.success, isTrue, reason: result.message);
        expect(
          (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson,
          before,
        );
      },
    );
  }
}
