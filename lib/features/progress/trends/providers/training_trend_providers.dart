import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/training_trend_repository.dart';
import '../domain/training_trend.dart';

final trainingTrendRepositoryProvider = Provider<TrainingTrendRepository>((ref) =>
  TrainingTrendRepository(ref.watch(appDatabaseProvider)));

final _binding = StreamProvider.autoDispose((ref) {
  final db=ref.watch(appDatabaseProvider);
  return db.select(db.syncState).watchSingleOrNull();
});
final _revision = Provider.autoDispose((ref) {
  final authority=ref.watch(cachedAuthWriteAuthorityProvider);
  void changed()=>ref.invalidateSelf();
  authority.revision.addListener(changed);
  ref.onDispose(()=>authority.revision.removeListener(changed));
  return authority.epoch;
});

class _ReadLease {
  _ReadLease(this.epoch, this.binding);
  final int epoch;
  final SyncStateData? binding;
  bool revoked=false;
  bool matches(SyncStateData? other) => binding != null && other != null &&
    other.offlineAccess && binding!.offlineAccess &&
    other.accountId==binding!.accountId && other.deviceId==binding!.deviceId;
}

// Held across history refreshes and selection changes. A->B->A cannot retarget
// the mounted screen, even if the database rows have not yet been cleared.
final _lease = FutureProvider.autoDispose((ref) async {
  final db=ref.watch(appDatabaseProvider);
  final epoch=ref.read(cachedAuthWriteAuthorityProvider).epoch;
  final lease=_ReadLease(epoch,await db.syncDao.readState());
  final subscription=db.select(db.syncState).watchSingleOrNull().listen((state) {
    if(!lease.matches(state)) lease.revoked=true;
  });
  ref.onDispose(subscription.cancel);
  return lease;
});

final _history = StreamProvider.autoDispose<List<TrendRow>>((ref) =>
  ref.watch(trainingTrendRepositoryProvider).watchHistory());

final trainingTrendHistoryProvider = FutureProvider.autoDispose<List<TrendRow>?>((ref) async {
  ref.watch(_revision);
  ref.watch(_binding);
  final leaseFuture=ref.watch(_lease.future);
  final authority=ref.read(cachedAuthWriteAuthorityProvider);
  final db=ref.read(appDatabaseProvider);
  final historyFuture=ref.watch(_history.future);
  ref.watch(_history);
  var disposed=false;
  ref.onDispose(()=>disposed=true);
  final lease=await leaseFuture;
  Future<bool> current() async {
    bool owns()=>!disposed && !lease.revoked && authority.epoch==lease.epoch &&
      (authority.state==null || (authority.state!.isSignedIn &&
        authority.state!.accountId==lease.binding?.accountId));
    if(!owns()) return false;
    final state=await db.syncDao.readState();
    if(!lease.matches(state)) lease.revoked=true;
    return owns() && lease.matches(state);
  }
  if(!await current()) return null;
  final rows=await historyFuture;
  if(!await current()) return null;
  return List.unmodifiable(rows);
});
