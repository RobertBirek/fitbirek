import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;

void main() {
  for (final kind in ['external', 'fitbirek', 'legacy']) {
    for (final change in [
      'move',
      'move-back',
      'rule-revision',
      'rule-name',
      'rule-target',
      'override-revision',
      'override-name',
      'override-target',
      'disabled',
      'deleted',
    ]) {
      test(
        '$kind $change rejects stale move and completion without outbox; fresh snapshot works',
        () async {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          final sync = SyncService(db, CollectionServer());
          addTearDown(() async {
            sync.dispose();
            await db.close();
          });
          await sync.bindAccount('account');
          await saveProfile(db);
          final day = CalendarDay.parse('2026-10-19');
          final repo = ScheduleRepository(db);
          final activities = ActivityRepository(db);
          String rule;
          if (kind == 'legacy') {
            await PlannerRepository(
              db,
            ).savePlan(nazwa: 'Plan', cwiczeniaIds: ['cw001'], cel: 'mix');
            final plan = (await db.select(db.workoutPlans).getSingle()).syncId;
            rule = await repo.addRule(
              'account',
              planSyncId: plan,
              name: 'Plan',
              weekday: 1,
              effectiveFrom: day,
            );
          } else {
            rule = await activities.create(
              await activities.snapshot('account'),
              ActivityDraft(
                name: 'Termin',
                activityType: kind == 'external'
                    ? ActivityType.external
                    : ActivityType.fitbirek,
                weekdays: {1},
                time: '12:30',
                effectiveFrom: day,
              ),
            );
          }
          Future<ScheduleOccurrence> current() async =>
              (await repo.load('account')).between(day, day.plus(6)).single;
          if (change.startsWith('override-')) {
            await repo.move('account', await current(), day);
          }
          final shown = await current();
          if (change == 'move' || change == 'move-back') {
            await repo.move('account', shown, day.plus(1));
            if (change == 'move-back') {
              await repo.move('account', await current(), day);
            }
          } else {
            await UserCollectionsRepository(
              db,
            ).update('account', 'weeklySchedule', (entries) {
              final index = entries.indexWhere(
                (e) =>
                    e['id'] ==
                    (change.startsWith('override-') ? shown.id : rule),
              );
              final entry = entries[index];
              final stamp = UserCollectionsRepository.nextTimestamp(entry);
              entries[index] = {
                ...entry,
                'updatedAtUtc': stamp,
                if (change == 'override-revision')
                  'remoteRevision': {'target': 'changed'},
                if (change.endsWith('-name')) 'name': 'Zmieniona nazwa',
                if (change == 'rule-target' && kind != 'external')
                  'planSyncId': '11111111-1111-4111-8111-111111111111',
                if (change == 'rule-target' && kind == 'external')
                  'time': '18:00',
                if (change == 'override-target')
                  'ruleSnapshot': {
                    ...entry['ruleSnapshot'] as Map,
                    if (kind == 'external')
                      'time': '18:00'
                    else
                      'planSyncId': '11111111-1111-4111-8111-111111111111',
                  },
                if (change == 'disabled' && kind != 'legacy') 'enabled': false,
                if (change == 'deleted' ||
                    (change == 'disabled' && kind == 'legacy'))
                  'deletedAtUtc': stamp,
              };
            });
          }
          final sessionId = await db
              .into(db.workoutSessions)
              .insert(
                WorkoutSessionsCompanion.insert(
                  dataStart: DateTime.now(),
                  dataKoniec: Value(DateTime.now()),
                ),
              );
          await db
              .into(db.setsLog)
              .insert(
                SetsLogCompanion.insert(
                  sesjaId: sessionId,
                  cwiczenieId: 'cw001',
                  nazwaCwiczeniaPl: 'Ćwiczenie',
                  numerSerii: 1,
                ),
              );
          final session =
              (await db.select(db.workoutSessions).getSingle()).syncId;
          final scheduleBefore = (await repo.load('account')).toJson();
          final outboxBefore = (await db.select(db.syncOutbox).get())
              .map((e) => e.toJson())
              .toList();
          await expectLater(
            repo.move('account', shown, day.plus(2)),
            throwsStateError,
          );
          await expectLater(
            kind == 'external'
                ? repo.completeExternal('account', shown)
                : repo.complete('account', shown, session),
            throwsStateError,
          );
          expect((await repo.load('account')).toJson(), scheduleBefore);
          expect(
            (await db.select(db.syncOutbox).get())
                .map((e) => e.toJson())
                .toList(),
            outboxBefore,
          );
          if (change != 'deleted' && change != 'disabled') {
            final fresh = await current();
            await repo.move('account', fresh, day.plus(2));
            final moved = await current();
            if (kind == 'external') {
              await repo.completeExternal('account', moved);
            } else {
              await repo.complete('account', moved, session);
            }
            expect((await current()).isCompleted, true);
          } else {
            expect(
              (await repo.load('account')).between(day, day.plus(6)),
              isEmpty,
            );
          }
          expect(await db.select(db.workoutSessions).get(), hasLength(1));
          expect(await db.select(db.setsLog).get(), hasLength(1));
        },
      );
    }
  }
}
