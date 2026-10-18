import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show CollectionServer, saveProfile;
import '../../core/profile_collection_quarantine_test.dart'
    show sessionRecord, setRecord, sessionId;
import 'weekly_schedule_test.dart' show planId;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final day = CalendarDay.parse('2026-10-19');

  test(
    'explicit restore onto another account remaps UUID references without leaking account binding or invalidating completion',
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
      await sa.bindAccount('source-account');
      await sb.bindAccount('target-account');
      await saveProfile(a);
      await saveProfile(b);
      final targetProfile = (await b.userProfileDao.watchProfileOnce())!.syncId;
      await PlannerRepository(
        a,
      ).savePlan(nazwa: 'Archived', cwiczeniaIds: ['cw001'], cel: 'mix');
      final oldPlan = (await a.select(a.workoutPlans).getSingle()).syncId;
      await SyncStore(a).apply(sessionRecord());
      await SyncStore(a).apply(setRecord());
      final ar = ScheduleRepository(a), br = ScheduleRepository(b);
      await ar.addRule(
        'source-account',
        planSyncId: oldPlan,
        name: 'Archived',
        weekday: 1,
        effectiveFrom: day,
      );
      final original = (await ar.load(
        'source-account',
      )).between(day, day).single;
      await ar.complete('source-account', original, sessionId);
      final bytes = await BackupService(a).exportToBytes();
      expect((await BackupService(b).importFromBytes(bytes)).success, isTrue);
      expect((await b.syncDao.readState())!.accountId, 'target-account');
      expect(
        (await b.userProfileDao.watchProfileOnce())!.syncId,
        targetProfile,
      );
      final restored = (await br.load(
        'target-account',
      )).between(day, day).single;
      final newPlan = (await b.select(b.workoutPlans).getSingle()).syncId;
      final newSession = (await b.select(b.workoutSessions).getSingle()).syncId;
      expect(newPlan, isNot(oldPlan));
      expect(newSession, isNot(sessionId));
      expect(restored.id, original.id);
      expect(restored.planSyncId, newPlan);
      expect(restored.sessionSyncId, newSession);
      expect(
        await br.completionStatus('target-account', restored),
        ScheduleCompletion.completed,
      );
      final raw =
          (await b.userProfileDao.watchProfileOnce())!.weeklyScheduleJson!;
      expect(raw.contains(oldPlan), isFalse);
      expect(raw.contains(sessionId), isFalse);
      expect((await a.select(a.workoutSessions).getSingle()).syncId, sessionId);
      expect(
        (await b.select(b.setsLog).getSingle()).sesjaId,
        (await b.select(b.workoutSessions).getSingle()).id,
      );
    },
  );

  test(
    'two real device CAS loops cannot count one session as two completions after concurrent explicit completion',
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
      final plan = {
        'entityType': 'workoutPlan',
        'entityId': planId,
        'version': 1,
        'updatedAt': '2026-10-17T12:00:00Z',
        'deletedAt': null,
        'payload': {
          'nazwa': 'Plan',
          'cwiczeniaIds': ['cw001'],
          'cel': 'mix',
          'dataUtworzenia': '2026-10-17T12:00:00Z',
        },
      };
      await SyncStore(a).apply(plan);
      await SyncStore(b).apply(plan);
      final ar = ScheduleRepository(a), br = ScheduleRepository(b);
      await ar.addRule(
        'account',
        planSyncId: planId,
        name: 'Plan',
        weekday: 1,
        effectiveFrom: day,
      );
      await sa.synchronize();
      server.log.addAll([sessionRecord(), setRecord()]);
      await sb.synchronize();
      await sa.synchronize();
      final first = (await ar.load('account')).between(day, day).single;
      final second = (await br.load(
        'account',
      )).between(day.plus(7), day.plus(7)).single;
      await ar.complete('account', first, sessionId);
      await br.complete('account', second, sessionId);
      await sa.synchronize();
      await sb.synchronize();
      await sa.synchronize();
      for (final pair in [(a, ar), (b, br)]) {
        final items = (await pair.$2.load('account')).between(day, day.plus(7));
        expect(items, hasLength(2));
        for (final o in items) {
          expect(
            await pair.$2.completionStatus('account', o),
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
