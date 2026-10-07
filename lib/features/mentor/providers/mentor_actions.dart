import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/models/exercise.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/exercises_providers.dart';
import '../../workout/providers/workout_providers.dart';
import '../data/mentor_models.dart';

enum MentorActionResult { applied, alreadyApplied, unavailable }

final mentorActionsProvider = Provider<MentorActions>(
  (ref) => MentorActions(ref),
);

/// The last local authority boundary for mentor proposals. It never accepts
/// navigation targets or arbitrary exercise data from the remote proposal.
class MentorActions {
  MentorActions(this._ref) {
    // Even a transition away and back to the same account invalidates work
    // already in flight; the persisted binding may still contain the old ID.
    _ref.listen(authStateProvider, (_, __) => _authGeneration++);
    _ref.onDispose(() => _disposed = true);
  }

  final Ref _ref;
  int _authGeneration = 0;
  bool _disposed = false;
  final Map<String, Future<MentorActionResult>> _pendingStarts = {};

  Future<MentorActionResult> confirm(
    MentorProposal proposal, {
    required String accountId,
    required int? expectedSessionId,
    double? weightKg,
    int? reps,
  }) {
    if (proposal.id.length != 36 ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(proposal.id)) {
      return Future.value(MentorActionResult.unavailable);
    }
    final generation = _authGeneration;
    bool guard() =>
        !_disposed && generation == _authGeneration && _ownsAccount(accountId);
    final key = _syncId(proposal, accountId);
    if (proposal.kind == MentorProposalKind.startWorkout) {
      final pending = _pendingStarts[key];
      if (pending != null) return pending;
      final future =
          _confirm(
            proposal,
            accountId: accountId,
            expectedSessionId: expectedSessionId,
            weightKg: weightKg,
            reps: reps,
            guard: guard,
          ).whenComplete(() {
            _pendingStarts.remove(key);
          });
      _pendingStarts[key] = future;
      return future;
    }
    return _confirm(
      proposal,
      accountId: accountId,
      expectedSessionId: expectedSessionId,
      weightKg: weightKg,
      reps: reps,
      guard: guard,
    );
  }

  Future<MentorActionResult> _confirm(
    MentorProposal proposal, {
    required String accountId,
    required int? expectedSessionId,
    double? weightKg,
    int? reps,
    required bool Function() guard,
  }) async {
    if (!guard() || !await _hasBoundAccount(accountId) || !guard()) {
      return MentorActionResult.unavailable;
    }
    if (proposal.kind == MentorProposalKind.navigateExercises) {
      return guard()
          ? MentorActionResult.applied
          : MentorActionResult.unavailable;
    }

    final syncId = _syncId(proposal, accountId);
    switch (proposal.kind) {
      case MentorProposalKind.startWorkout:
        Exercise? exercise;
        if (proposal.exerciseId != null) {
          exercise = await _ref
              .read(exercisesRepositoryProvider)
              .getById(proposal.exerciseId!);
          if (exercise == null) return MentorActionResult.unavailable;
        }
        if (!guard()) return MentorActionResult.unavailable;
        final write = await _ref
            .read(activeWorkoutProvider.notifier)
            .startMentorSession(
              syncId: syncId,
              accountId: accountId,
              guard: guard,
              exercise: exercise,
            );
        if (!guard() || !await _hasBoundAccount(accountId) || !guard()) {
          return MentorActionResult.unavailable;
        }
        if (write == null) return MentorActionResult.unavailable;
        return write.alreadyExists
            ? MentorActionResult.alreadyApplied
            : MentorActionResult.applied;
      case MentorProposalKind.logSet:
        final actualWeight = weightKg ?? proposal.weightKg;
        final actualReps = reps ?? proposal.reps;
        if (expectedSessionId == null ||
            proposal.exerciseId == null ||
            proposal.exerciseId!.isEmpty ||
            actualWeight == null ||
            !actualWeight.isFinite ||
            actualWeight < 0 ||
            actualWeight > 500 ||
            actualReps == null ||
            actualReps < 1 ||
            actualReps > 100) {
          return MentorActionResult.unavailable;
        }
        final existing = await _ref
            .read(workoutRepositoryProvider)
            .findSetBySyncId(syncId);
        if (!guard()) return MentorActionResult.unavailable;
        if (existing != null) return MentorActionResult.alreadyApplied;
        final exercise = await _ref
            .read(exercisesRepositoryProvider)
            .getById(proposal.exerciseId!);
        if (exercise == null ||
            !guard() ||
            !await _hasBoundAccount(accountId) ||
            !guard()) {
          return MentorActionResult.unavailable;
        }
        final write = await _ref
            .read(activeWorkoutProvider.notifier)
            .logMentorSet(
              exercise: exercise,
              weightKg: actualWeight,
              reps: actualReps,
              syncId: syncId,
              accountId: accountId,
              expectedSessionId: expectedSessionId,
              guard: guard,
            );
        if (!guard() || !await _hasBoundAccount(accountId) || !guard()) {
          return MentorActionResult.unavailable;
        }
        if (write == null) return MentorActionResult.unavailable;
        return write.alreadyExists
            ? MentorActionResult.alreadyApplied
            : MentorActionResult.applied;
      case MentorProposalKind.navigateExercises:
        return MentorActionResult.applied;
    }
  }

  String _syncId(MentorProposal proposal, String accountId) => Uuid().v5(
    Namespace.url.value,
    'fitbirek:mentor:$accountId:${proposal.id}:${proposal.kind.name}',
  );

  bool _ownsAccount(String accountId) {
    final auth = _ref.read(authStateProvider);
    return auth.isSignedIn && auth.accountId == accountId;
  }

  Future<bool> _hasBoundAccount(String accountId) async {
    final state = await _ref.read(appDatabaseProvider).syncDao.readState();
    return state != null && state.accountId == accountId && state.offlineAccess;
  }
}
