import 'dart:convert';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/user_collections.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/schedule/data/activity_repository.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import '../../core/profile_cloud_review_test.dart' show ReviewServer;
import '../../core/profile_collection_quarantine_test.dart'
    show sessionRecord, setRecord, sessionId;
import 'schedule_cloud_test.dart' show failPushTransport;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final day = CalendarDay.parse('2026-10-19');
  ActivityDraft draft(
    String name, {
    ActivityType type = ActivityType.external,
    String? plan,
  }) => ActivityDraft(
    name: name,
    activityType: type,
    weekdays: {1},
    time: '12:30',
    effectiveFrom: day,
    planSyncId: plan,
  );

  test(
    'actual cross-account restore remaps nullable activity plan/session refs and preserves history identity',
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
      await PlannerRepository(
        a,
      ).savePlan(nazwa: 'Plan', cwiczeniaIds: ['cw001'], cel: 'mix');
      final oldPlan = (await a.select(a.workoutPlans).getSingle()).syncId;
      await SyncStore(a).apply(sessionRecord());
      await SyncStore(a).apply(setRecord());
      final ar = ActivityRepository(a), sr = ScheduleRepository(a);
      final fitId = await ar.create(
        await ar.snapshot('source'),
        draft('Fit', type: ActivityType.fitbirek, plan: oldPlan),
      );
      await ar.create(
        await ar.snapshot('source'),
        draft('Free', type: ActivityType.fitbirek),
      );
      final extId = await ar.create(
        await ar.snapshot('source'),
        draft('External'),
      );
      var occurrences = (await sr.load('source')).between(day, day);
      final fitOccurrence = occurrences.singleWhere((o) => o.ruleId == fitId);
      await sr.complete('source', fitOccurrence, sessionId);
      await sr.completeExternal(
        'source',
        occurrences.singleWhere((o) => o.ruleId == extId),
      );
      // Keep a moved, explicitly NULL plan/session override, not only virtual rules.
      await sr.move(
        'source',
        occurrences.singleWhere((o) => o.name == 'Free'),
        day.plus(1),
      );
      final bytes = await BackupService(a).exportToBytes();
      expect((await BackupService(b).importFromBytes(bytes)).success, isTrue);
      expect((await b.syncDao.readState())!.accountId, 'target');
      final br = ScheduleRepository(b);
      occurrences = (await br.load('target')).between(day, day.plus(1));
      final fit = occurrences.singleWhere((o) => o.ruleId == fitId);
      expect(fit.id, fitOccurrence.id);
      expect(
        fit.planSyncId,
        (await b.select(b.workoutPlans).getSingle()).syncId,
      );
      expect(fit.planSyncId, isNot(oldPlan));
      expect(
        fit.sessionSyncId,
        (await b.select(b.workoutSessions).getSingle()).syncId,
      );
      expect(fit.sessionSyncId, isNot(sessionId));
      expect(
        await br.completionStatus('target', fit),
        ScheduleCompletion.completed,
      );
      final external = occurrences.singleWhere((o) => o.ruleId == extId);
      expect(external.planSyncId, isNull);
      expect(external.sessionSyncId, isNull);
      expect(external.externalCompleted, isTrue);
      expect(
        occurrences.singleWhere((o) => o.name == 'Free').planSyncId,
        isNull,
      );
      final raw =
          (await b.userProfileDao.watchProfileOnce())!.weeklyScheduleJson!;
      expect(raw.contains(oldPlan), isFalse);
      expect(raw.contains(sessionId), isFalse);
      expect(await b.select(b.workoutSessions).get(), hasLength(1));
      expect(await b.select(b.setsLog).get(), hasLength(1));
      expect(await b.select(b.personalRecords).get(), isEmpty);
    },
  );

  test(
    'two real DB sync CAS preserves attempted bytes, tombstones and external history through reopen',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var a = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final b = AppDatabase.forTesting(NativeDatabase.memory());
      final server = ReviewServer();
      var sa = SyncService(a, server);
      final sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        raw.dispose();
        await b.close();
      });
      await sa.bindAccount('account');
      await sb.bindAccount('account');
      await saveProfile(a);
      var ar = ActivityRepository(a);
      final id = await ar.create(await ar.snapshot('account'), draft('Basen'));
      final sr = ScheduleRepository(a);
      await sr.completeExternal(
        'account',
        (await sr.load('account')).between(day, day).single,
      );
      await sa.synchronize();
      await sb.synchronize();
      final br = ActivityRepository(b);
      await br.create(await br.snapshot('account'), draft('B'));
      await failPushTransport(sb, server);
      final attempted = (await b.syncDao.pendingOperations()).single.toJson();
      // Another local edit must not change the attempted operation UUID/hash/base.
      await br.create(await br.snapshot('account'), draft('B2'));
      expect((await b.syncDao.pendingOperations()).first.toJson(), attempted);
      await ar.delete(await ar.snapshot('account'), id);
      await sa.synchronize();
      for (var i = 0; i < 4; i++) {
        await sb.synchronize();
        await sa.synchronize();
      }
      expect(sa.status, SyncStatus.idle);
      expect(sb.status, SyncStatus.idle);
      final expected = (await br.snapshot('account')).schedule.toJson();
      expect(
        UserCollections.canonical(
          (await ar.snapshot('account')).schedule.toJson(),
        ),
        UserCollections.canonical(expected),
      );
      sa.dispose();
      await a.close();
      a = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      sa = SyncService(a, server);
      ar = ActivityRepository(a);
      final reopened = await ar.snapshot('account');
      expect(
        UserCollections.canonical(reopened.schedule.toJson()),
        UserCollections.canonical(expected),
      );
      expect(
        reopened.schedule.entries.singleWhere(
          (e) => e['id'] == id,
        )['deletedAtUtc'],
        isNotNull,
      );
      final externalHistory = reopened.schedule
          .between(day, day)
          .singleWhere((o) => o.ruleId == id);
      expect(externalHistory.externalCompleted, isTrue);
      expect(await a.select(a.workoutSessions).get(), isEmpty);
      expect(await a.select(a.setsLog).get(), isEmpty);
      // Still the normal schemaVersion=2 archive, not a second collection store.
      expect(
        jsonDecode(
          utf8.decode(await BackupService(a).exportToBytes()),
        )['schemaVersion'],
        2,
      );
    },
  );
}
