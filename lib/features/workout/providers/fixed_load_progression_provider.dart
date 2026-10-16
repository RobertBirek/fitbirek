import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart'
    show SyncStateData, SetLogData;
import '../../auth/providers/auth_providers.dart';
import '../domain/fixed_load_progression.dart';
import 'workout_providers.dart';

typedef FixedLoadRequest = ({
  String exerciseId,
  String? side,
  String prescription,
  String tracking,
  bool usesWeight,
  double? weightKg,
});

final _progressionBinding = StreamProvider.autoDispose<SyncStateData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.syncState).watchSingleOrNull();
});

// One baseline for the live session, shared across load/side request changes.
// A binding/auth transition must not retarget the same form to a new account.
final _sessionProgressionBinding = FutureProvider.autoDispose((ref) async {
  ref.watch(activeWorkoutProvider.select((s) => (s.sessionId, s.startTime)));
  final epoch = ref.read(cachedAuthWriteAuthorityProvider).epoch;
  final binding = await ref.read(appDatabaseProvider).syncDao.readState();
  return (epoch: epoch, binding: binding);
});

final _authorityRevision = Provider.autoDispose<int>((ref) {
  final authority = ref.watch(cachedAuthWriteAuthorityProvider);
  void changed() => ref.invalidateSelf();
  authority.revision.addListener(changed);
  ref.onDispose(() => authority.revision.removeListener(changed));
  return authority.epoch;
});

class FixedLoadOffer {
  FixedLoadOffer(this.suggestion, this.isCurrent, {this.lastSet});
  final FixedLoadSuggestion suggestion;

  /// Existing last-set comparison; never used as progression evidence.
  final SetLogData? lastSet;

  /// Rechecks passive auth, session ownership and durable account binding.
  final Future<bool> Function() isCurrent;
}

final fixedLoadProgressionProvider = FutureProvider.autoDispose
    .family<FixedLoadOffer?, FixedLoadRequest>((ref, request) async {
      ref.watch(_authorityRevision);
      final origin = ref.watch(
        activeWorkoutProvider.select(
          (s) => (s.sessionId, s.startTime, s.isActive),
        ),
      );
      if (!origin.$3 || origin.$1 == null) return null;
      final authority = ref.read(cachedAuthWriteAuthorityProvider);
      final epoch = authority.epoch;
      final account = authority.state?.accountId;
      final db = ref.read(appDatabaseProvider);
      final repo = ref.read(workoutRepositoryProvider);
      var disposed = false;
      ref.onDispose(() => disposed = true);
      bool owns() {
        if (disposed ||
            authority.epoch != epoch ||
            (authority.state != null && !authority.state!.isSignedIn)) {
          return false;
        }
        final live = ref.read(activeWorkoutProvider);
        return live.isActive &&
            live.sessionId == origin.$1 &&
            live.startTime == origin.$2;
      }

      if (!owns()) return null;
      final bindingState = ref.watch(_progressionBinding);
      final binding = bindingState.isLoading
          ? await ref.watch(_progressionBinding.future)
          : bindingState.valueOrNull;
      if (!owns()) return null;
      final baseline = await ref.watch(_sessionProgressionBinding.future);
      if (!owns() ||
          binding == null ||
          !binding.offlineAccess ||
          baseline.epoch != epoch ||
          baseline.binding?.accountId != binding.accountId ||
          baseline.binding?.deviceId != binding.deviceId ||
          (account != null && binding.accountId != account)) {
        return null;
      }
      final originalSession = await db.workoutDao.getSession(origin.$1!);
      if (!owns() ||
          originalSession == null ||
          originalSession.dataKoniec != null ||
          originalSession.deletedAtUtc != null) {
        return null;
      }
      // Even without initialized auth, the durable offline binding is mandatory.
      Future<bool> current() async {
        if (!owns()) return false;
        final now = await db.syncDao.readState();
        if (!owns() ||
            now == null ||
            !now.offlineAccess ||
            now.accountId != binding.accountId ||
            now.deviceId != binding.deviceId) {
          return false;
        }
        final session = await db.workoutDao.getSession(origin.$1!);
        if (!owns() ||
            session == null ||
            session.syncId != originalSession.syncId ||
            session.dataStart != originalSession.dataStart ||
            session.dataKoniec != null ||
            session.deletedAtUtc != null) {
          return false;
        }
        final finalBinding = await db.syncDao.readState();
        return owns() &&
            finalBinding?.accountId == binding.accountId &&
            finalBinding?.deviceId == binding.deviceId &&
            finalBinding?.offlineAccess == true;
      }

      final history = await repo.getProgressionHistory(
        request.exerciseId,
        side: request.side,
        excludingSessionId: origin.$1!,
      );
      if (!owns()) return null;
      final lastSet = await repo.getLastSet(
        request.exerciseId,
        side: request.side,
      );
      if (!await current()) return null;
      final suggestion = proposeFixedLoad(
        exerciseId: request.exerciseId,
        side: request.side,
        prescription: request.prescription,
        tracking: request.tracking,
        usesWeight: request.usesWeight,
        currentWeightKg: request.weightKg,
        history: history,
      );
      return FixedLoadOffer(suggestion, current, lastSet: lastSet);
    });
