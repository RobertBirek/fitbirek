import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/push/push_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/activity_migration.dart';
import '../domain/activity_reminders.dart';
import 'schedule_providers.dart';

final activityReminderSyncProvider = StreamProvider<String>((ref) {
  final binding = ref.watch(filterPresetsAccountProvider);
  final account = binding.valueOrNull;
  final service = ref.watch(notificationServiceProvider);
  final authority = ref.watch(cachedAuthWriteAuthorityProvider);
  final epoch = authority.epoch;
  var alive = true;
  bool guard() => alive && authority.epoch == epoch;
  void invalidate() {
    ref.invalidateSelf();
  }

  authority.revision.addListener(invalidate);
  ref.onDispose(() {
    alive = false;
    authority.revision.removeListener(invalidate);
    if (!kIsWeb) {
      unawaited(
        service
            .replaceActivities([], isCurrent: () => true, migrated: false)
            .catchError((Object _) {}),
      );
    }
  });
  if (account == null) {
    return Stream.value('Przypomnienia wymagają aktywnego konta.');
  }
  final db = ref.watch(appDatabaseProvider);
  final repository = ref.watch(activityRepositoryProvider);
  // Native category consent stays in its old preference keys. PWA consent is
  // exclusively read through the existing installation status client.
  final settings = ref.watch(settingsProvider);
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.userProfiles, db.syncState, db.syncDeferredRecords},
      )
      .watch()
      .asyncMap((_) async {
        try {
          final prefs = kIsWeb ? null : await SharedPreferences.getInstance();
          if (!guard()) throw StateError('Konto zostało zmienione.');
          final snapshot = await migrateLegacyActivities(
            repository,
            account,
            isCurrent: guard,
            push: kIsWeb ? ref.read(pushClientProvider) : null,
            karate: prefs?.getBool('notif_karate') ?? (kIsWeb ? null : false),
            training:
                prefs?.getBool('notif_workout') ?? (kIsWeb ? null : false),
          );
          if (!guard()) throw StateError('Konto zostało zmienione.');
          if (!kIsWeb) {
            await service.init();
            final reminders = activityReminders(
              snapshot.schedule,
              DateTime.now(),
              external: settings.notifKarate,
              training: settings.notifWorkout,
            );
            await service.replaceActivities(reminders, isCurrent: guard);
          }
          return kIsWeb
              ? 'Migracja gotowa. Dostarczanie wymaga aktywnej subskrypcji, kategorii i synchronizacji.'
              : 'Przypomnienia na najbliższe 7 dni. Otwórz aplikację co najmniej raz w tygodniu, aby odnowić; system może opóźnić dostarczenie.';
        } catch (error) {
          if (!kIsWeb && guard()) {
            try {
              await service.replaceActivities(
                [],
                isCurrent: guard,
                migrated: false,
              );
            } catch (cancelError) {
              return 'Przypomnienia: $error Nie udało się anulować: $cancelError. Sprawdź ustawienia systemu i ponów.';
            }
          }
          return 'Przypomnienia: $error Ponów po odświeżeniu.';
        }
      });
});

class ActivityReminderBootstrap extends ConsumerStatefulWidget {
  const ActivityReminderBootstrap({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<ActivityReminderBootstrap> createState() =>
      _ActivityReminderBootstrapState();
}

class _ActivityReminderBootstrapState
    extends ConsumerState<ActivityReminderBootstrap>
    with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => ref.invalidate(activityReminderSyncProvider),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(activityReminderSyncProvider);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activityReminderSyncProvider);
    return widget.child;
  }
}
