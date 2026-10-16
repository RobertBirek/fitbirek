import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/database/app_database.dart' show WorkoutSessionData;
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/pr_detector.dart';
import '../../../core/utils/set_comparison.dart';
import '../../../core/models/exercise.dart';
import '../data/workout_repository.dart';
import '../domain/interval_timer.dart';
import '../../auth/providers/auth_providers.dart';
import '../../progress/prs/providers/prs_providers.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorkoutRepository(db);
});

/// Pojedyncza wykonana seria w ramach BIEŻĄCEJ, aktywnej sesji (stan w pamięci,
/// zanim trafi do bazy - potrzebne do wyświetlenia listy w UI na żywo).
class ActiveSetEntry {
  const ActiveSetEntry({
    required this.exerciseId,
    required this.exerciseNamePl,
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.seconds,
    this.side,
    this.rpe,
    this.isNewPr = false,
    this.comparison,
  });

  final String exerciseId;
  final String exerciseNamePl;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final int? seconds;
  final String? side;
  final int? rpe;
  final bool isNewPr;
  final String? comparison;
}

/// Stan aktywnej sesji treningowej.
class ActiveWorkoutState {
  const ActiveWorkoutState({
    this.sessionId,
    this.startTime,
    this.selectedExercises = const [],
    this.loggedSets = const [],
    this.isActive = false,
  });

  final int? sessionId;
  final DateTime? startTime;
  final List<Exercise> selectedExercises;
  final List<ActiveSetEntry> loggedSets;
  final bool isActive;

  ActiveWorkoutState copyWith({
    int? sessionId,
    DateTime? startTime,
    List<Exercise>? selectedExercises,
    List<ActiveSetEntry>? loggedSets,
    bool? isActive,
  }) {
    return ActiveWorkoutState(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      selectedExercises: selectedExercises ?? this.selectedExercises,
      loggedSets: loggedSets ?? this.loggedSets,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Opaque single-use capture. Never retarget a returned timer to a newer session.
class IntervalWriteOrigin {
  IntervalWriteOrigin._(
    this._owner,
    this.sessionId,
    this._generation,
    this._authority,
    this._epoch,
    this.exercise,
    this.side,
    this.rpe,
  );
  final ActiveWorkoutNotifier _owner;
  final int sessionId, _generation, _epoch;
  final CachedAuthWriteAuthority _authority;
  final Exercise exercise;
  final String? side;
  final int? rpe;
  bool _claimed = false;
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  ActiveWorkoutNotifier(this._ref) : super(const ActiveWorkoutState());

  final Ref _ref;
  StreamSubscription<WorkoutSessionData?>? _sessionSubscription;
  int _generation = 0;
  bool _intervalClosing = false;
  Future<IdempotentSessionWrite?>? _pendingMentorStart;
  String? _pendingMentorStartKey;

  bool _isCurrent(int id, int generation) =>
      mounted && generation == _generation && state.sessionId == id;

  void _resetIfCurrent(int id, int generation) {
    if (_isCurrent(id, generation)) discardSession();
  }

  Future<void> startSession() async {
    final generation = ++_generation;
    final authority = _ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    bool current() =>
        mounted &&
        generation == _generation &&
        authority.epoch == epoch &&
        (authority.state == null || authority.state!.isSignedIn);
    _intervalClosing = false;
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    final repo = _ref.read(workoutRepositoryProvider);
    if (!current()) return;
    final id = await repo.startSession(
      guard: current,
      accountId: authority.state?.accountId,
    );
    if (!current()) return;
    state = ActiveWorkoutState(
      sessionId: id,
      startTime: DateTime.now(),
      isActive: true,
      selectedExercises: state.selectedExercises,
    );
    _sessionSubscription = repo.watchSession(id).listen((row) {
      if (row == null || row.deletedAtUtc != null || row.dataKoniec != null) {
        _resetIfCurrent(id, generation);
      }
    });
  }

  void addExercise(Exercise exercise) {
    if (state.selectedExercises.any((e) => e.id == exercise.id)) return;
    state = state.copyWith(
      selectedExercises: [...state.selectedExercises, exercise],
    );
  }

  void removeExercise(String exerciseId) {
    state = state.copyWith(
      selectedExercises: state.selectedExercises
          .where((e) => e.id != exerciseId)
          .toList(),
    );
  }

  IntervalWriteOrigin? captureInterval({
    required Exercise exercise,
    String? side,
    int? rpe,
  }) {
    if (!mounted || !state.isActive || state.sessionId == null) return null;
    final authority = _ref.read(cachedAuthWriteAuthorityProvider);
    final origin = IntervalWriteOrigin._(
      this,
      state.sessionId!,
      _generation,
      authority,
      authority.epoch,
      exercise,
      side,
      rpe,
    );
    return isIntervalCurrent(origin) ? origin : null;
  }

  bool isIntervalCurrent(IntervalWriteOrigin origin) =>
      identical(origin._owner, this) &&
      _isCurrent(origin.sessionId, origin._generation) &&
      state.isActive &&
      !_intervalClosing &&
      origin._authority.epoch == origin._epoch &&
      (origin._authority.state == null || origin._authority.state!.isSignedIn);

  /// True means the entire batch was written, not a PR flag. One explicit
  /// attempt per capture, with a synchronous reservation before the first await.
  Future<bool> saveIntervalRounds(
    IntervalWriteOrigin origin,
    List<IntervalRound> rounds, {
    bool Function()? guard,
  }) async {
    if (origin._claimed || !isIntervalCurrent(origin)) return false;
    origin._claimed = true;
    final results = List<IntervalRound>.of(rounds);
    if (results.isEmpty ||
        results.length > 100 ||
        results.any((r) => r.seconds < 1 || r.seconds > 3600) ||
        results.any((r) => r.round < 1 || r.round > 100) ||
        results.map((r) => r.round).toSet().length != results.length) {
      return false;
    }
    void requireOwnership() {
      if (!isIntervalCurrent(origin) || !(guard?.call() ?? true)) {
        throw WorkoutAccountUnavailable();
      }
    }

    final db = _ref.read(appDatabaseProvider);
    final repo = _ref.read(workoutRepositoryProvider);
    final entries = <ActiveSetEntry>[];
    try {
      await db.transaction(() async {
        requireOwnership();
        final binding = await db.syncDao.readState();
        requireOwnership();
        if ((binding != null && !binding.offlineAccess) ||
            (origin._authority.state != null &&
                binding?.accountId != origin._authority.state!.accountId)) {
          throw WorkoutAccountUnavailable();
        }
        final session = await db.workoutDao.getSession(origin.sessionId);
        requireOwnership();
        if (session == null ||
            session.deletedAtUtc != null ||
            session.dataKoniec != null) {
          throw WorkoutSessionUnavailable(origin.sessionId);
        }
        // Read numbering inside the serialized transaction, not from stale UI.
        final existing = await repo.getSetsForSession(origin.sessionId);
        requireOwnership();
        var number = existing
            .where((s) => s.cwiczenieId == origin.exercise.id)
            .fold<int>(0, (n, s) => s.numerSerii > n ? s.numerSerii : n);
        for (final result in results) {
          await repo.logSet(
            sessionId: origin.sessionId,
            exerciseId: origin.exercise.id,
            exerciseNamePl: origin.exercise.nazwaPl,
            setNumber: ++number,
            seconds: result.seconds,
            side: origin.side,
            rpe: origin.rpe,
          );
          requireOwnership();
          entries.add(
            ActiveSetEntry(
              exerciseId: origin.exercise.id,
              exerciseNamePl: origin.exercise.nazwaPl,
              setNumber: number,
              seconds: result.seconds,
              side: origin.side,
              rpe: origin.rpe,
            ),
          );
        }
        final currentBinding = await db.syncDao.readState();
        requireOwnership();
        if (currentBinding?.accountId != binding?.accountId ||
            (currentBinding != null && !currentBinding.offlineAccess)) {
          throw WorkoutAccountUnavailable();
        }
      });
    } on WorkoutAccountUnavailable {
      return false;
    } on WorkoutSessionUnavailable {
      return false;
    }
    if (!isIntervalCurrent(origin)) return false;
    state = state.copyWith(loggedSets: [...state.loggedSets, ...entries]);
    return true;
  }

  /// Zapisuje serię do bazy + wykrywa PR + zwraca info czy to nowy rekord.
  Future<bool> logSet({
    required Exercise exercise,
    double? weightKg,
    int? reps,
    int? seconds,
    int? rpe,
    String? side,
  }) async {
    if (state.sessionId == null) return false;
    final sessionId = state.sessionId!;
    final generation = _generation;
    final repo = _ref.read(workoutRepositoryProvider);

    // SQLite reads inside this transaction cannot observe a logout lock queued
    // behind it. The passive auth epoch changes synchronously at logout start.
    final authority = _ref.read(cachedAuthWriteAuthorityProvider);
    final authEpoch = authority.epoch;

    final setNumber =
        state.loggedSets.where((s) => s.exerciseId == exercise.id).length + 1;

    bool isNewPr = false;
    String? comparison;
    void requireOwnership() {
      if (!_isCurrent(sessionId, generation) ||
          authority.epoch != authEpoch ||
          (authority.state != null && !authority.state!.isSignedIn)) {
        throw WorkoutAccountUnavailable();
      }
    }

    try {
      await _ref.read(appDatabaseProvider).transaction(() async {
        requireOwnership();
        final binding = await _ref
            .read(appDatabaseProvider)
            .syncDao
            .readState();
        requireOwnership();
        if ((binding != null && !binding.offlineAccess) ||
            (authority.state != null &&
                binding?.accountId != authority.state!.accountId)) {
          throw WorkoutAccountUnavailable();
        }
        final previous = await repo.getLastSet(exercise.id, side: side);
        requireOwnership();
        comparison = setComparison(
          weightKg: weightKg,
          reps: reps,
          seconds: seconds,
          previousWeightKg: previous?.ciezarKg,
          previousReps: previous?.powtorzenia,
          previousSeconds: previous?.czasSekund,
        );
        await repo.logSet(
          sessionId: sessionId,
          exerciseId: exercise.id,
          exerciseNamePl: exercise.nazwaPl,
          setNumber: setNumber,
          weightKg: weightKg,
          reps: reps,
          seconds: seconds,
          side: side,
          rpe: rpe,
        );
        requireOwnership();

        if (weightKg != null && reps != null && weightKg > 0 && reps > 0) {
          final prsRepo = _ref.read(prsRepositoryProvider);
          final best = await prsRepo.getBestForExercise(
            exercise.id,
            side: side,
          );
          requireOwnership();
          isNewPr = PrDetector.isNewRecord(
            nowyCiezar: weightKg,
            nowePowtorzenia: reps,
            dotychczasowyBest1Rm: best?.szacowane1Rm,
          );
          if (isNewPr) {
            await prsRepo.savePr(
              exerciseId: exercise.id,
              exerciseNamePl: exercise.nazwaPl,
              weightKg: weightKg,
              reps: reps,
              side: side,
            );
            requireOwnership();
          }
        }
        final currentBinding = await _ref
            .read(appDatabaseProvider)
            .syncDao
            .readState();
        requireOwnership();
        if (currentBinding?.accountId != binding?.accountId ||
            (currentBinding != null && !currentBinding.offlineAccess)) {
          throw WorkoutAccountUnavailable();
        }
      });
    } on WorkoutSessionUnavailable {
      _resetIfCurrent(sessionId, generation);
      return false;
    } on WorkoutAccountUnavailable {
      _resetIfCurrent(sessionId, generation);
      return false;
    }
    if (!_isCurrent(sessionId, generation)) return false;

    state = state.copyWith(
      loggedSets: [
        ...state.loggedSets,
        ActiveSetEntry(
          exerciseId: exercise.id,
          exerciseNamePl: exercise.nazwaPl,
          setNumber: setNumber,
          weightKg: weightKg,
          reps: reps,
          seconds: seconds,
          side: side,
          rpe: rpe,
          isNewPr: isNewPr,
          comparison: comparison,
        ),
      ],
    );

    return isNewPr;
  }

  /// Performs an externally deduplicated set write and mirrors it into the
  /// active-workout state only when this notifier still owns that live session.
  Future<IdempotentSetWrite?> logMentorSet({
    required Exercise exercise,
    required double weightKg,
    required int reps,
    required String syncId,
    required String accountId,
    required int expectedSessionId,
    bool Function()? guard,
  }) async {
    if (!state.isActive || state.sessionId != expectedSessionId) return null;
    final generation = _generation;
    bool ownsSession() =>
        _isCurrent(expectedSessionId, generation) &&
        state.isActive &&
        (guard?.call() ?? true);
    void requireOwnership() {
      if (!ownsSession()) throw WorkoutAccountUnavailable();
    }

    final setNumber =
        state.loggedSets.where((set) => set.exerciseId == exercise.id).length +
        1;
    final repo = _ref.read(workoutRepositoryProvider);
    IdempotentSetWrite? write;
    bool isNewPr = false;
    try {
      await _ref.read(appDatabaseProvider).transaction(() async {
        requireOwnership();
        write = await repo.logSetIdempotent(
          sessionId: expectedSessionId,
          exerciseId: exercise.id,
          exerciseNamePl: exercise.nazwaPl,
          setNumber: setNumber,
          weightKg: weightKg,
          reps: reps,
          syncId: syncId,
          accountId: accountId,
          guard: ownsSession,
        );
        requireOwnership();
        if (!write!.alreadyExists && weightKg > 0 && reps > 0) {
          final prsRepo = _ref.read(prsRepositoryProvider);
          final best = await prsRepo.getBestForExercise(exercise.id);
          requireOwnership();
          isNewPr = PrDetector.isNewRecord(
            nowyCiezar: weightKg,
            nowePowtorzenia: reps,
            dotychczasowyBest1Rm: best?.szacowane1Rm,
          );
          if (isNewPr) {
            await prsRepo.savePr(
              exerciseId: exercise.id,
              exerciseNamePl: exercise.nazwaPl,
              weightKg: weightKg,
              reps: reps,
            );
            requireOwnership();
          }
        }
        final binding = await _ref
            .read(appDatabaseProvider)
            .syncDao
            .readState();
        requireOwnership();
        if (binding?.accountId != accountId || binding?.offlineAccess != true) {
          throw WorkoutAccountUnavailable();
        }
      });
    } on WorkoutSessionUnavailable {
      _resetIfCurrent(expectedSessionId, generation);
      return null;
    } on WorkoutAccountUnavailable {
      return null;
    }
    final completedWrite = write;
    if (completedWrite == null || !ownsSession()) {
      return null;
    }
    if (!completedWrite.alreadyExists) {
      state = state.copyWith(
        loggedSets: [
          ...state.loggedSets,
          ActiveSetEntry(
            exerciseId: exercise.id,
            exerciseNamePl: exercise.nazwaPl,
            setNumber: setNumber,
            weightKg: weightKg,
            reps: reps,
            isNewPr: isNewPr,
          ),
        ],
      );
    }
    return completedWrite;
  }

  Future<IdempotentSessionWrite?> startMentorSession({
    required String syncId,
    required String accountId,
    bool Function()? guard,
    Exercise? exercise,
  }) {
    final key = '$accountId:$syncId';
    // Reserve synchronously: duplicate taps share the same result, while a
    // different proposal cannot invalidate the first start's UI attachment.
    final pending = _pendingMentorStart;
    if (pending != null) {
      return key == _pendingMentorStartKey ? pending : Future.value(null);
    }
    if (guard != null && !guard()) return Future.value(null);
    _pendingMentorStartKey = key;
    final future =
        _startMentorSession(
          syncId: syncId,
          accountId: accountId,
          guard: guard,
          exercise: exercise,
        ).whenComplete(() {
          _pendingMentorStart = null;
          _pendingMentorStartKey = null;
        });
    _pendingMentorStart = future;
    return future;
  }

  Future<IdempotentSessionWrite?> _startMentorSession({
    required String syncId,
    required String accountId,
    bool Function()? guard,
    Exercise? exercise,
  }) async {
    final generation = _generation;
    final initialSessionId = state.sessionId;
    bool ownsStart() =>
        mounted &&
        generation == _generation &&
        state.sessionId == initialSessionId &&
        (guard?.call() ?? true);
    void requireOwnership() {
      if (!ownsStart()) throw WorkoutAccountUnavailable();
    }

    final repo = _ref.read(workoutRepositoryProvider);
    late IdempotentSessionWrite write;
    var loggedSets = <ActiveSetEntry>[];
    try {
      await _ref.read(appDatabaseProvider).transaction(() async {
        requireOwnership();
        write = await repo.startSessionIdempotent(
          syncId: syncId,
          accountId: accountId,
          guard: ownsStart,
        );
        requireOwnership();
        if (write.alreadyExists &&
            !state.isActive &&
            write.session.deletedAtUtc == null &&
            write.session.dataKoniec == null) {
          final sets = await repo.getSetsForSession(write.session.id);
          requireOwnership();
          loggedSets = sets
              .map(
                (s) => ActiveSetEntry(
                  exerciseId: s.cwiczenieId,
                  exerciseNamePl: s.nazwaCwiczeniaPl,
                  setNumber: s.numerSerii,
                  weightKg: s.ciezarKg,
                  reps: s.powtorzenia,
                  seconds: s.czasSekund,
                  side: s.side,
                  rpe: s.rpe,
                ),
              )
              .toList();
        }
        final binding = await _ref
            .read(appDatabaseProvider)
            .syncDao
            .readState();
        requireOwnership();
        if (binding?.accountId != accountId || binding?.offlineAccess != true) {
          throw WorkoutAccountUnavailable();
        }
      });
    } on WorkoutAccountUnavailable {
      return null;
    } on WorkoutSessionUnavailable {
      return null;
    }
    if (!ownsStart()) return null;
    if (state.isActive) return write;
    final session = write.session;
    if (session.deletedAtUtc != null || session.dataKoniec != null) {
      return write;
    }
    _intervalClosing = false;
    state = ActiveWorkoutState(
      sessionId: session.id,
      startTime: session.dataStart.toLocal(),
      isActive: true,
      loggedSets: loggedSets,
      selectedExercises: [
        ...state.selectedExercises,
        if (exercise != null &&
            !state.selectedExercises.any((e) => e.id == exercise.id))
          exercise,
      ],
    );
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = _ref
        .read(workoutRepositoryProvider)
        .watchSession(session.id)
        .listen((row) {
          if (row == null ||
              row.deletedAtUtc != null ||
              row.dataKoniec != null) {
            _resetIfCurrent(session.id, generation);
          }
        });
    return write;
  }

  Future<void> finishSession() async {
    if (state.sessionId == null || state.startTime == null) return;
    // Invalidate timer captures synchronously: SQLite finish may be queued
    // behind an in-flight interval transaction, which must then roll back.
    _intervalClosing = true;
    final sessionId = state.sessionId!;
    final startTime = state.startTime!;
    final generation = _generation;
    final repo = _ref.read(workoutRepositoryProvider);
    try {
      await repo.finishSession(sessionId, startTime);
    } on WorkoutSessionUnavailable {
      // A restore/pull may win the race before the watch notification arrives.
      _resetIfCurrent(sessionId, generation);
      return;
    }
    _resetIfCurrent(sessionId, generation);
  }

  void discardSession() {
    _generation++;
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = null;
    state = const ActiveWorkoutState();
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_sessionSubscription?.cancel());
    super.dispose();
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
      return ActiveWorkoutNotifier(ref);
    });

final allSessionsProvider = StreamProvider<List<WorkoutSessionData>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchAllSessions();
});
