import 'dart:convert';
import 'package:drift/drift.dart' show Value, Uint8List;
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

Future<void> seedProgramBackup(AppDatabase db) async {
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
  await db.workoutDao.updateSession(
    session,
    WorkoutSessionsCompanion(
      dataKoniec: Value(DateTime.utc(2026, 10, 28)),
      guidanceJson: Value(
        jsonEncode(
          WorkoutGuidance.tryRead(
            s!.guidanceJson,
          )!.link(0, set.syncId, targetId: 'a').toJson(),
        ),
      ),
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
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());
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
      final plans = await db.select(db.workoutPlans).get();
      expect(fork['planSyncIds'], unorderedEquals(plans.map((p) => p.syncId)));
      expect(
        (override['programSnapshot'] as Map)['planSyncIds'],
        fork['planSyncIds'],
      );
      final sessions = (await db.select(db.workoutSessions).get())
          .where((s) => s.deletedAtUtc == null)
          .toList();
      expect(override['sessionSyncId'], sessions.single.syncId);
      final set = (await db.select(db.setsLog).get()).single;
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
