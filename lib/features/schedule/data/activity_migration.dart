import '../../../core/push/push_client.dart';
import '../domain/activity_schedule.dart';
import 'activity_repository.dart';
import 'schedule_repository.dart';

/// A fresh account/profile lease is obtained before any HTTP. Never holds a
/// SQLite transaction while waiting for PushManager, network or preferences.
Future<ActivitySnapshot> migrateLegacyActivities(
  ActivityRepository repository,
  String account, {
  required bool Function() isCurrent,
  PushClient? push,
  bool? karate,
  bool? training,
}) async {
  final lease = await repository.snapshot(account, isCurrent: isCurrent);
  await assertScheduleWritable(repository.db, lease.profileSyncId);
  if (!isCurrent()) throw StateError('Konto zostało zmienione.');
  final ids = lease.schedule.entries.map((e) => e['id']).toSet();
  if (LegacyActivitySource.values.every(
    (s) => ids.contains(legacyActivityRuleId(lease.profileSyncId, s)),
  )) {
    return lease;
  }
  if (push != null) {
    final status = await push.status(account);
    if (!isCurrent()) throw StateError('Konto zostało zmienione.');
    final categories = status['categories'];
    final server = status['server'];
    if (status['supported'] != true ||
        status['enabled'] is! bool ||
        categories is! Map ||
        categories['karate'] is! bool ||
        categories['training'] is! bool ||
        server is! Map ||
        ['offline', 'registration_failed'].contains(server['reason'])) {
      throw StateError(
        'Migracja przypomnień oczekuje na znany status tej instalacji PWA. Połącz się i ponów; stare push pozostają bez zmian.',
      );
    }
    karate = status['enabled'] == true && categories['karate'] == true;
    training = status['enabled'] == true && categories['training'] == true;
  }
  if (karate == null || training == null) {
    throw StateError('Nieznane ustawienia przypomnień. Ponów migrację.');
  }
  await repository.seedLegacy(
    lease,
    karate: karate,
    training: training,
    isCurrent: isCurrent,
  );
  return repository.snapshot(account, isCurrent: isCurrent);
}
