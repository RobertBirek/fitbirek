import 'dart:convert';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/schedule/data/training_programs_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show CollectionServer, saveProfile;
import '../../core/profile_collection_quarantine_test.dart'
    show sessionRecord, setRecord, sessionId;
import '../../core/training_sets_programs_domain_test.dart'
    show planA, planB, planJson;
import '../exercises/catalog_filter_test.dart' show exercise;
import 'training_programs_repository_test.dart' show programMetadata;

Future<void> seedProgramPlans(AppDatabase db) async {
  for (final id in [planA, planB]) {
    await db
        .into(db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(
            nazwa: 'Szablon',
            cwiczeniaIds: '["cw001"]',
            cel: 'Własny szablon',
            syncId: Value(id),
            structureJson: Value(jsonEncode(planJson())),
          ),
        );
  }
}

final programDay = CalendarDay.parse('2026-10-19');
Future<String> createProgram(
  TrainingProgramsRepository repo,
  String account,
) async => repo.create(
  await repo.open(account),
  name: 'Program',
  planSyncIds: [planA, planB],
  weekdays: {1, 3, 5},
  effectiveFrom: programDay,
  catalog: [exercise('cw001')],
  metadata: programMetadata,
);
Future<ProgramOccurrence> programOccurrence(
  TrainingProgramsRepository repo,
  String account, {
  int offset = 0,
}) async => TrainingProgramSchedule(
  await repo.load(account),
).between(programDay.plus(offset), programDay.plus(offset)).single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final crossCollection in [false, true]) {
    test(
      'two device CAS preserves both explicit proof conflicts, crossCollection=$crossCollection',
      () async {
        final a = AppDatabase.forTesting(NativeDatabase.memory()),
            b = AppDatabase.forTesting(NativeDatabase.memory());
        final server = CollectionServer();
        final sa = SyncService(a, server), sb = SyncService(b, server);
        addTearDown(() async {
          sa.dispose();
          sb.dispose();
          await a.close();
          await b.close();
        });
        await sa.bindAccount('account');
        await sb.bindAccount('account');
        await saveProfile(a);
        await seedProgramPlans(a);
        await seedProgramPlans(b);
        final ar = TrainingProgramsRepository(a),
            br = TrainingProgramsRepository(b);
        await createProgram(ar, 'account');
        if (crossCollection) {
          await ScheduleRepository(a).addRule(
            'account',
            planSyncId: planA,
            name: 'Rytm tygodnia',
            weekday: 1,
            effectiveFrom: programDay,
          );
        }
        await sa.synchronize();
        server.log.addAll([sessionRecord(), setRecord()]);
        await sb.synchronize();
        await sa.synchronize();
        await ar.complete(
          'account',
          await programOccurrence(ar, 'account'),
          sessionId,
        );
        if (crossCollection) {
          final w = ScheduleRepository(b);
          await w.complete(
            'account',
            (await w.load('account')).between(programDay, programDay).single,
            sessionId,
          );
        } else {
          await br.complete(
            'account',
            await programOccurrence(br, 'account', offset: 2),
            sessionId,
          );
        }
        await sa.synchronize();
        await sb.synchronize();
        await sa.synchronize();
        for (final pair in [(a, ar), (b, br)]) {
          final o = await programOccurrence(pair.$2, 'account');
          expect(
            await pair.$2.completionStatus('account', o),
            ScheduleCompletion.conflict,
          );
          if (crossCollection) {
            final w = ScheduleRepository(pair.$1);
            expect(
              await w.completionStatus(
                'account',
                (await w.load(
                  'account',
                )).between(programDay, programDay).single,
              ),
              ScheduleCompletion.conflict,
            );
          } else {
            expect(
              await pair.$2.completionStatus(
                'account',
                await programOccurrence(pair.$2, 'account', offset: 2),
              ),
              ScheduleCompletion.conflict,
            );
          }
          expect(
            await pair.$1.select(pair.$1.workoutSessions).get(),
            hasLength(1),
          );
          expect(await pair.$1.select(pair.$1.setsLog).get(), hasLength(1));
          expect(await pair.$1.select(pair.$1.personalRecords).get(), isEmpty);
          expect(await pair.$1.syncDao.pendingOperations(), isEmpty);
        }
      },
    );
  }
  test(
    'competing exclusive end dates from two devices hold conflict instead of rewriting overdue history',
    () async {
      final a = AppDatabase.forTesting(NativeDatabase.memory()),
          b = AppDatabase.forTesting(NativeDatabase.memory());
      final server = CollectionServer();
      final sa = SyncService(a, server), sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
      });
      await sa.bindAccount('account');
      await sb.bindAccount('account');
      await saveProfile(a);
      await seedProgramPlans(a);
      await seedProgramPlans(b);
      final ar = TrainingProgramsRepository(a, today: () => programDay),
          br = TrainingProgramsRepository(b, today: () => programDay);
      final id = await createProgram(ar, 'account');
      await sa.synchronize();
      await sb.synchronize();
      await ar.end(await ar.open('account', programId: id), programDay.plus(7));
      await br.end(await br.open('account', programId: id), programDay.plus(9));
      await sa.synchronize();
      await sb.synchronize();
      expect(sb.status, SyncStatus.conflict);
      expect(
        (await ar.load('account')).entries.single['endBeforeDate'],
        '2026-10-26',
      );
      expect(
        (await br.load('account')).entries.single['endBeforeDate'],
        '2026-10-28',
      );
      final pending = (await b.select(b.syncOutbox).getSingle()).toJson();
      await expectLater(br.open('account', programId: id), throwsStateError);
      await sb.synchronize();
      expect((await b.select(b.syncOutbox).getSingle()).toJson(), pending);
      expect(
        TrainingProgramSchedule(
          await ar.load('account'),
        ).between(programDay, programDay.plus(13)),
        hasLength(3),
      );
      expect(
        TrainingProgramSchedule(
          await br.load('account'),
        ).between(programDay, programDay.plus(13)),
        hasLength(4),
      );
    },
  );
  test(
    'future remote CAS holds exact attempted bytes and repo refuses all edits, raw survives retries',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final server = CollectionServer();
      final service = SyncService(db, server);
      addTearDown(() async {
        service.dispose();
        await db.close();
      });
      await service.bindAccount('account');
      await saveProfile(db);
      await seedProgramPlans(db);
      final repo = TrainingProgramsRepository(db);
      final id = await createProgram(repo, 'account');
      await service.synchronize();
      await repo.rename(
        await repo.open('account', programId: id),
        'Lokalna edycja',
      );
      final outgoing = (await db.select(db.syncOutbox).getSingle());
      final raw = {'version': 9, 'entries': [], 'opaque': 'nie usuwaj'};
      server.record = {
        ...server.record!,
        'version': (server.record!['version'] as int) + 1,
        'payload': <String, dynamic>{
          ...server.record!['payload'] as Map<String, dynamic>,
          'trainingPrograms': raw,
        },
      };
      server.log.add(server.record!);
      await service.synchronize();
      expect(service.status, SyncStatus.conflict);
      expect(
        (await db.select(db.syncOutbox).get()).length,
        1,
        reason: 'outbox after raw CAS',
      );
      final attempted = await db.select(db.syncOutbox).getSingle();
      expect(attempted.attempted, isTrue);
      expect(attempted.payloadJson, outgoing.payloadJson);
      expect(attempted.operationId, outgoing.operationId);
      expect(attempted.baseVersion, outgoing.baseVersion);
      final records = await db.select(db.syncDeferredRecords).get();
      final deferred = records.singleWhere((r) => r.entityType == 'profile');
      expect(
        jsonDecode(deferred.recordJson)[SyncStore
            .profileCollectionHold]['quarantinedRecord']['payload']['trainingPrograms'],
        raw,
      );
      await expectLater(repo.open('account'), throwsStateError);
      await expectLater(
        repo.move(
          'account',
          await programOccurrence(repo, 'account'),
          programDay.plus(1),
        ),
        throwsStateError,
      );
      await service.synchronize();
      expect(
        (await db.select(db.syncOutbox).getSingle()).toJson(),
        attempted.toJson(),
      );
      expect(
        (await db.select(db.syncDeferredRecords).get())
            .map((r) => r.toJson())
            .toList(),
        records.map((r) => r.toJson()).toList(),
      );
      expect(
        (await repo.load('account')).entries.single['name'],
        'Lokalna edycja',
      );
    },
  );
  test(
    'repository-created backup copies keep cutoff/move/working proof; originals invalid and fresh-account restore remaps references',
    () async {
      final a = AppDatabase.forTesting(NativeDatabase.memory()),
          b = AppDatabase.forTesting(NativeDatabase.memory());
      final sa = SyncService(a, CollectionServer()),
          sb = SyncService(b, CollectionServer());
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
      });
      await sa.bindAccount('source');
      await sb.bindAccount('target');
      await saveProfile(a);
      await saveProfile(b);
      await seedProgramPlans(a);
      final repo = TrainingProgramsRepository(a, today: () => programDay);
      final id = await createProgram(repo, 'source');
      await SyncStore(a).apply(sessionRecord());
      final working = setRecord();
      (working['payload'] as Map)['setRole'] = 'working';
      await SyncStore(a).apply(working);
      await repo.move(
        'source',
        await programOccurrence(repo, 'source'),
        programDay.plus(1),
      );
      final moved = TrainingProgramSchedule(
        await repo.load('source'),
      ).between(programDay.plus(1), programDay.plus(1)).single;
      await repo.complete('source', moved, sessionId);
      await repo.end(
        await repo.open('source', programId: id),
        programDay.plus(7),
      );
      final bytes = await BackupService(a).exportToBytes();
      final ownRestore = await BackupService(a).importFromBytes(bytes);
      expect(ownRestore.success, isTrue, reason: ownRestore.message);
      final own = TrainingProgramSchedule(
        await repo.load('source'),
      ).between(programDay.plus(1), programDay.plus(1));
      expect(own, hasLength(2));
      final original = own.singleWhere((o) => o.programId == id),
          copy = own.singleWhere((o) => o.programId != id);
      expect(
        await repo.completionStatus('source', original),
        ScheduleCompletion.invalidated,
      );
      expect(
        await repo.completionStatus('source', copy),
        ScheduleCompletion.completed,
      );
      expect(copy.planSyncId, isNot(planA));
      expect(copy.sessionSyncId, isNot(sessionId));
      final exported = await BackupService(a).exportToBytes();
      final restored = await BackupService(b).importFromBytes(exported);
      expect(restored.success, isTrue, reason: restored.message);
      expect((await b.syncDao.readState())!.accountId, 'target');
      final target = TrainingProgramsRepository(b);
      final items = TrainingProgramSchedule(
        await target.load('target'),
      ).between(programDay.plus(1), programDay.plus(1));
      expect(items, hasLength(2));
      expect(items.where((o) => own.any((old) => old.id == o.id)), isEmpty);
      final statuses = await Future.wait(
        items.map((o) => target.completionStatus('target', o)),
      );
      expect(
        statuses,
        containsAll([
          ScheduleCompletion.completed,
          ScheduleCompletion.invalidated,
        ]),
      );
      for (final p in (await target.load(
        'target',
      )).entries.where((e) => e['kind'] == 'program')) {
        expect(p['endBeforeDate'], '2026-10-26');
        for (final plan in p['planSyncIds'] as List) {
          expect(
            (await b.select(b.workoutPlans).get()).any(
              (row) => row.syncId == plan,
            ),
            isTrue,
          );
        }
      }
      expect(
        (await b.select(b.setsLog).get()).every((s) => s.setRole == 'working'),
        isTrue,
      );
    },
  );
}
