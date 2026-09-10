import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/database/app_database.dart' show WorkoutSessionData;
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/pr_detector.dart';
import '../../../core/models/exercise.dart';
import '../data/workout_repository.dart';
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
    this.rpe,
    this.isNewPr = false,
  });

  final String exerciseId;
  final String exerciseNamePl;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final int? seconds;
  final int? rpe;
  final bool isNewPr;
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

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  ActiveWorkoutNotifier(this._ref) : super(const ActiveWorkoutState());

  final Ref _ref;
  StreamSubscription<WorkoutSessionData?>? _sessionSubscription;
  int _generation = 0;

  bool _isCurrent(int id, int generation) =>
      mounted && generation == _generation && state.sessionId == id;

  void _resetIfCurrent(int id, int generation) {
    if (_isCurrent(id, generation)) discardSession();
  }

  Future<void> startSession() async {
    final generation = ++_generation;
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    final repo = _ref.read(workoutRepositoryProvider);
    final id = await repo.startSession();
    if (!mounted || generation != _generation) return;
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

  /// Zapisuje serię do bazy + wykrywa PR + zwraca info czy to nowy rekord.
  Future<bool> logSet({
    required Exercise exercise,
    double? weightKg,
    int? reps,
    int? seconds,
    int? rpe,
  }) async {
    if (state.sessionId == null) return false;
    final sessionId = state.sessionId!;
    final generation = _generation;
    final repo = _ref.read(workoutRepositoryProvider);

    final setNumber =
        state.loggedSets.where((s) => s.exerciseId == exercise.id).length + 1;

    bool isNewPr = false;
    try {
      await _ref.read(appDatabaseProvider).transaction(() async {
        await repo.logSet(
          sessionId: sessionId,
          exerciseId: exercise.id,
          exerciseNamePl: exercise.nazwaPl,
          setNumber: setNumber,
          weightKg: weightKg,
          reps: reps,
          seconds: seconds,
          rpe: rpe,
        );

        if (weightKg != null && reps != null && weightKg > 0 && reps > 0) {
          final prsRepo = _ref.read(prsRepositoryProvider);
          final best = await prsRepo.getBestForExercise(exercise.id);
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
          }
        }
      });
    } on WorkoutSessionUnavailable {
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
          rpe: rpe,
          isNewPr: isNewPr,
        ),
      ],
    );

    return isNewPr;
  }

  Future<void> finishSession() async {
    if (state.sessionId == null || state.startTime == null) return;
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
