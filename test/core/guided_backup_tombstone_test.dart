import 'dart:convert';

import 'package:drift/drift.dart' show Value, Uint8List, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';

import 'training_sets_programs_domain_test.dart' show planJson;

final _deletedAt = DateTime.utc(2026, 10, 28, 12);

Future<void> _seedDeletedPerformed(AppDatabase db, int version) async {
  final plan = planJson(version: version);
  if (version == 1) {
    (plan['blocks'] as List).single['prescription'] = {
      'tracking': 'reps',
      'sets': 2,
      'reps': 8,
      'workSeconds': 24,
      'restSeconds': 20,
      'transitionSeconds': 15,
    };
  }
  final repo = WorkoutRepository(db);
  final session = await repo.startSession(
    guidance: WorkoutGuidance.start(StructuredPlan.fromJson(plan)),
  );
  final deleted = await repo.logSet(
    sessionId: session,
    exerciseId: 'cw001',
    exerciseNamePl: 'X',
    setNumber: 1,
    reps: 8,
    setRole: version == 2 ? 'warmup' : null,
    guidanceSlot: 0,
    guidanceTargetId: version == 2 ? 'a' : null,
  );
  await repo.logSet(
    sessionId: session,
    exerciseId: 'cw001',
    exerciseNamePl: 'X',
    setNumber: 2,
    reps: 6,
    setRole: 'working',
    guidanceSlot: 0,
    guidanceTargetId: version == 2 ? 'b' : null,
  );
  // Deletion after sync must not erase append-only guidance or revive its proof.
  await (db.update(db.setsLog)..where((s) => s.id.equals(deleted))).write(
    SetsLogCompanion(deletedAtUtc: Value(_deletedAt)),
  );
  final row = (await db.workoutDao.getSession(session))!;
  final guidance = WorkoutGuidance.tryRead(row.guidanceJson)!;
  await db.workoutDao.updateSession(
    session,
    WorkoutSessionsCompanion(
      guidanceJson: Value(
        jsonEncode({
          ...guidance.toJson(),
          'events': [
            {
              ...guidance.events.first,
              'setSyncId': (guidance.events.first['setSyncId'] as String)
                  .toUpperCase(),
            },
            guidance.events.last,
          ],
        }),
      ),
    ),
  );
  // Unreferenced tombstones must not broaden the ordinary-session closure.
  final extra = await repo.logSet(
    sessionId: session,
    exerciseId: 'cw001',
    exerciseNamePl: 'Unlinked',
    setNumber: 3,
    reps: 1,
    setRole: 'warmup',
  );
  await (db.update(db.setsLog)..where((s) => s.id.equals(extra))).write(
    SetsLogCompanion(deletedAtUtc: Value(_deletedAt)),
  );
  await repo.finishSession(session, DateTime.now());
  final unrelated = await repo.startSession();
  await repo.logSet(
    sessionId: unrelated,
    exerciseId: 'cw001',
    exerciseNamePl: 'Deleted session',
    setNumber: 1,
    reps: 1,
  );
  await db.workoutDao.updateSession(
    unrelated,
    WorkoutSessionsCompanion(deletedAtUtc: Value(_deletedAt)),
  );
  await db.customStatement('UPDATE sync_outbox SET attempted = 1');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  for (final version in [1, 2]) {
    test(
      'ordinary guided v$version restores deleted performed proof through two fresh restores',
      () async {
        await _seedDeletedPerformed(db, version);
        final sourceOutbox = (await db.select(db.syncOutbox).get())
            .map((r) => r.toJson())
            .toList();
        final sourceIds = (await db.select(db.setsLog).get())
            .map((r) => r.syncId)
            .toSet();
        final sourceSessionIds = (await db.select(db.workoutSessions).get())
            .map((r) => r.syncId)
            .toSet();
        final sourceGuidance = WorkoutGuidance.tryRead(
          (await db.select(db.workoutSessions).get())
              .singleWhere((s) => s.guidanceJson != null)
              .guidanceJson,
        )!;
        var bytes = await BackupService(db).exportToBytes();
        var previousSetIds = sourceIds;
        var previousSessionIds = sourceSessionIds;
        for (var round = 0; round < 2; round++) {
          final fresh = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(fresh.close);
          final result = await BackupService(fresh).importFromBytes(bytes);
          expect(result.success, isTrue, reason: result.message);
          final archive = jsonDecode(utf8.decode(bytes))['data'] as Map;
          expect(archive['workoutSessions'], hasLength(1));
          expect(archive['setsLog'], hasLength(2));
          expect(
            (archive['setsLog'] as List)
                .where((s) => s['archiveDeletedAtUtc'] != null)
                .single['archiveDeletedAtUtc'],
            _deletedAt.toIso8601String(),
          );
          final session = await fresh.select(fresh.workoutSessions).getSingle();
          expect(session.deletedAtUtc, isNull);
          expect(session.dataKoniec, isNotNull);
          expect(previousSessionIds, isNot(contains(session.syncId)));
          final guidance = WorkoutGuidance.tryRead(session.guidanceJson)!;
          expect(guidance.schemaVersion, version);
          expect(guidance.plan.toJson(), sourceGuidance.plan.toJson());
          expect(guidance.events, hasLength(2));
          expect(guidance.events.map((e) => e['type']), [
            'performed',
            'performed',
          ]);
          expect(
            guidance.events.map((e) => e['targetId']),
            version == 2 ? ['a', 'b'] : [null, null],
          );
          final sets = await fresh.select(fresh.setsLog).get();
          expect(sets, hasLength(2));
          for (var i = 0; i < 2; i++) {
            final linked = sets.singleWhere(
              (s) => s.syncId == guidance.events[i]['setSyncId'],
            );
            expect(linked.sesjaId, session.id);
            expect(previousSetIds, isNot(contains(linked.syncId)));
            expect(
              linked.setRole,
              i == 1
                  ? 'working'
                  : version == 2
                  ? 'warmup'
                  : null,
            );
            expect(linked.powtorzenia, i == 0 ? 8 : 6);
            expect(linked.deletedAtUtc?.toUtc(), i == 0 ? _deletedAt : null);
          }
          // The history link survives, but the deleted target still has no live
          // evidence; it is not counted as actual execution or an extra set.
          final live = await WorkoutRepository(
            fresh,
          ).getSetsForSession(session.id);
          expect(live, hasLength(1));
          expect(live.single.syncId, guidance.events.last['setSyncId']);
          expect(
            live.any((s) => s.syncId == guidance.events.first['setSyncId']),
            isFalse,
          );
          expect(guidance.additionalSetIds(live.map((s) => s.syncId)), isEmpty);
          if (version == 2) {
            expect(
              () => guidance.link(0, 'another-set', targetId: 'a'),
              throwsFormatException,
            );
          }
          final outbox = await fresh.select(fresh.syncOutbox).get();
          expect(outbox.where((r) => r.attempted), isEmpty);
          expect(
            outbox.any(
              (r) => sourceOutbox.any(
                (old) => old['operationId'] == r.operationId,
              ),
            ),
            isFalse,
          );
          expect(outbox.any((r) => sourceIds.contains(r.entityId)), isFalse);
          final tombstone = sets.singleWhere((s) => s.deletedAtUtc != null);
          expect(
            outbox.where((r) => r.entityId == tombstone.syncId).single.deleted,
            isTrue,
          );
          final recovery =
              await (fresh.select(fresh.syncDeferredRecords)..where(
                    (r) => r.entityType.equals('_backupRecoveryArchive'),
                  ))
                  .getSingle();
          expect(
            jsonDecode(recovery.recordJson)['recovery'],
            archive['syncRecovery'],
          );
          previousSetIds = sets.map((s) => s.syncId).toSet();
          previousSessionIds = {session.syncId};
          bytes = await BackupService(fresh).exportToBytes();
        }
        expect(
          (await db.select(db.syncOutbox).get())
              .map((r) => r.toJson())
              .toList(),
          sourceOutbox,
        );
      },
    );

    for (final corruption in ['missing', 'foreign-session']) {
      test(
        'guided v$version still refuses $corruption performed set UUID atomically',
        () async {
          await _seedDeletedPerformed(db, version);
          final archive =
              jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
                  as Map;
          final data = archive['data'] as Map;
          final sets = data['setsLog'] as List;
          if (corruption == 'missing') {
            sets.removeWhere((s) => s['numerSerii'] == 1);
          } else {
            final sessions = data['workoutSessions'] as List;
            final session = Map<String, dynamic>.from(sessions.single as Map);
            session['id'] = 999;
            session['archiveSessionSyncId'] =
                'aaaaaaaa-0000-4000-8000-000000000001';
            session['guidanceJson'] = null;
            sessions.add(session);
            sets.singleWhere((s) => s['numerSerii'] == 1)['sesjaId'] = 999;
          }
          final fresh = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(fresh.close);
          final result = await BackupService(fresh).importFromBytes(
            Uint8List.fromList(utf8.encode(jsonEncode(archive))),
          );
          expect(result.success, isFalse);
          expect(
            result.message,
            contains('Missing archived guidance set UUID'),
          );
          expect(await fresh.select(fresh.workoutSessions).get(), isEmpty);
          expect(await fresh.select(fresh.setsLog).get(), isEmpty);
          expect(await fresh.select(fresh.syncOutbox).get(), isEmpty);
          expect(await fresh.select(fresh.syncDeferredRecords).get(), isEmpty);
        },
      );
    }
  }
}
