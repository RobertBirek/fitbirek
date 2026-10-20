import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/activity_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/providers/schedule_providers.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import 'schedule_repository_test.dart' show TestAuthority;

void main() {
  test(
    'shared week provider observes external manual completion and disabled history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(TestAuthority()),
          filterPresetsAccountProvider.overrideWith(
            (ref) => Stream.value('account'),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await saveProfile(db);
      final day = CalendarDay.parse('2026-10-19');
      final activities = container.read(activityRepositoryProvider);
      final id = await activities.create(
        await activities.snapshot('account'),
        ActivityDraft(
          name: 'Basen',
          activityType: ActivityType.external,
          weekdays: {1},
          time: '12:30',
          effectiveFrom: day,
        ),
      );
      await container.read(filterPresetsAccountProvider.future);
      final completed = Completer<ScheduleWeek>();
      final sub = container.listen(scheduleWeekProvider(day), (_, next) {
        final value = next.valueOrNull;
        if (value != null &&
            value.occurrences.length == 1 &&
            value.status.values.single == ScheduleCompletion.completed &&
            value.schedule.entries.any((e) => e['enabled'] == false) &&
            !completed.isCompleted) {
          completed.complete(value);
        }
      });
      addTearDown(sub.close);
      final first = (await container.read(scheduleWeekProvider(day).future))!;
      expect(first.occurrences.single.time, '12:30');
      expect(first.status.values.single, ScheduleCompletion.planned);
      await container
          .read(scheduleRepositoryProvider)
          .completeExternal('account', first.occurrences.single);
      await activities.setEnabled(
        await activities.snapshot('account'),
        id,
        false,
      );
      final history = await completed.future.timeout(
        const Duration(seconds: 10),
      );
      expect(history.occurrences.single.id, first.occurrences.single.id);
      expect(history.occurrences.single.externalCompleted, isTrue);
      expect(history.sessions, isEmpty);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
    },
  );
}
