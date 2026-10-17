import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import '../../../core/database/app_database.dart' show WorkoutSessionData;
import '../../../core/database/app_database.dart' show WorkoutDraftData;
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/pr_detector.dart';
import '../../../core/utils/set_comparison.dart';
import '../../../core/models/exercise.dart';
import '../data/workout_repository.dart';
import '../domain/interval_timer.dart';
import '../domain/workout_guidance.dart';
import '../domain/workout_draft_write.dart';
import '../../exercises/providers/exercises_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../progress/prs/providers/prs_providers.dart';
import '../../exercises/data/exercise_variants_repository.dart';

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
    this.variantId,
    this.variantLabel,
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
  final String? variantId, variantLabel;
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
    this.sessionSyncId,
    this.guidance,
    this.currentSlot = 0,
    this.draft = const {},
  });

  final int? sessionId;
  final DateTime? startTime;
  final List<Exercise> selectedExercises;
  final List<ActiveSetEntry> loggedSets;
  final bool isActive;
  final String? sessionSyncId;
  final WorkoutGuidance? guidance;
  final int currentSlot;
  final Map<String, Object?> draft;

  Set<String> get plannedExerciseIds => {
    ...?guidance?.plan.exerciseIds,
    if (guidance != null)
      ...List.generate(guidance!.plan.blocks.length, guidance!.exerciseAt),
    if (guidance != null)
      ...guidance!.events
          .where((e) => e['type'] == 'replaced')
          .map((e) => e['exerciseId'] as String),
  };

  bool isExtraExercise(String id) =>
      guidance != null &&
      !plannedExerciseIds.contains(id) &&
      selectedExercises.any((e) => e.id == id);

  String extraDraftKey(String id, String? side, String? variantId) =>
      jsonEncode(['extra', sessionSyncId, id, side, variantId]);

  Map<String, Object?> extraSelection(String id) {
    final values = draft['extraSelections'];
    final value = values is Map ? values[id] : null;
    return value is Map ? Map<String, Object?>.from(value) : {};
  }

  Map<String, Object?> exerciseDraft(
    String id, {
    bool extra = false,
    String? side,
    String? variantId,
  }) {
    if (!extra) return draft;
    final forms = draft['extraForms'];
    final value = forms is Map
        ? forms[extraDraftKey(id, side, variantId)]
        : null;
    return value is Map ? Map<String, Object?>.from(value) : {};
  }

  ActiveWorkoutState copyWith({
    int? sessionId,
    DateTime? startTime,
    List<Exercise>? selectedExercises,
    List<ActiveSetEntry>? loggedSets,
    bool? isActive,
    String? sessionSyncId,
    WorkoutGuidance? guidance,
    int? currentSlot,
    Map<String, Object?>? draft,
  }) {
    return ActiveWorkoutState(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      selectedExercises: selectedExercises ?? this.selectedExercises,
      loggedSets: loggedSets ?? this.loggedSets,
      isActive: isActive ?? this.isActive,
      sessionSyncId: sessionSyncId ?? this.sessionSyncId,
      guidance: guidance ?? this.guidance,
      currentSlot: currentSlot ?? this.currentSlot,
      draft: draft ?? this.draft,
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
    this.sessionSyncId,
    this.guidanceSlot,
    this.variantId,
    this.variantLabel,
    this.extra,
    this.checkpointKey,
    this.checkpointEpoch,
  );
  final ActiveWorkoutNotifier _owner;
  final int sessionId, _generation, _epoch;
  final CachedAuthWriteAuthority _authority;
  final Exercise exercise;
  final String? side;
  final int? rpe;
  final String? sessionSyncId;
  final int? guidanceSlot;
  final String? variantId, variantLabel;
  final bool extra;
  final String checkpointKey;
  final int checkpointEpoch;
  bool _claimed = false;
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  ActiveWorkoutNotifier(this._ref) : super(const ActiveWorkoutState());

  final Ref _ref;

  /// Drift 2.28.2 binds an executor via a zone value. Leave only that short-
  /// lived database scope, retaining the caller's UI/error/test zone. A blanket
  /// Zone.root detachment would also strip legitimate scheduling contexts.
  Zone _persistentDatabaseZone() {
    final db = _ref.read(appDatabaseProvider);
    var zone = Zone.current;
    while (zone.parent != null) {
      final transactionBound = zone.run(() {
        // Version-pinned compatibility point; covered with native + RPC tests.
        // ignore: invalid_use_of_internal_member
        return !identical(db.resolvedEngine, db);
      });
      if (!transactionBound) return zone;
      zone = zone.parent!;
    }
    return zone;
  }

  StreamSubscription<WorkoutSessionData?>? _sessionSubscription;
  int _generation = 0;
  bool _intervalClosing = false;
  Future<IdempotentSessionWrite?>? _pendingMentorStart;
  String? _pendingMentorStartKey;
  Future<void> _draftWrites = Future.value();
  Map<String, Object?>? _lastDraftSnapshot;
  Map<String, int> _checkpointEpochs = {};
  Map<String, int> _checkpointVersions = {};
  final Map<String, String> _ownGuidanceRebases = {};
  bool _draftConsumptionInFlight = false;
  String? _consumingCheckpointKey;
  bool _guidedBusy = false;
  CachedAuthWriteAuthority? _sessionAuthority;
  int? _sessionEpoch;
  String? _sessionAccount;
  bool get _ownsAuthority =>
      _sessionAuthority == null ||
      (_sessionAuthority!.epoch == _sessionEpoch &&
          (_sessionAuthority!.state == null ||
              _sessionAuthority!.state!.isSignedIn));

  bool _isCurrent(int id, int generation) =>
      mounted &&
      generation == _generation &&
      state.sessionId == id &&
      _ownsAuthority;

  void _resetIfCurrent(int id, int generation) {
    if (_isCurrent(id, generation)) discardSession();
  }

  void _observeGuidance(WorkoutSessionData row, int generation) {
    if (!_isCurrent(row.id, generation) || state.guidance == null) return;
    final g = WorkoutGuidance.tryRead(row.guidanceJson);
    if (g == null) {
      discardSession();
      return;
    }
    if (jsonEncode(g.toJson()) != jsonEncode(state.guidance!.toJson())) {
      final slot = state.currentSlot.clamp(0, g.plan.blocks.length - 1);
      final changed =
          slot != state.currentSlot ||
          g.exerciseAt(slot) != state.guidance!.exerciseAt(state.currentSlot) ||
          jsonEncode(g.plan.toJson()) !=
              jsonEncode(state.guidance!.plan.toJson());
      state = state.copyWith(
        guidance: g,
        currentSlot: slot,
        draft: changed ? _clearedGuidedFields() : state.draft,
      );
      updateDraft({});
    }
  }

  Future<void> startSession({WorkoutGuidance? guidance}) async {
    final generation = ++_generation;
    _lastDraftSnapshot = null;
    _checkpointEpochs = {};
    _checkpointVersions = {};
    _draftError = null;
    _ownGuidanceRebases.clear();
    final authority = _ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    _sessionAuthority = authority;
    _sessionEpoch = epoch;
    bool current() =>
        mounted &&
        generation == _generation &&
        authority.epoch == epoch &&
        (authority.state == null || authority.state!.isSignedIn);
    _intervalClosing = false;
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    final repo = _ref.read(workoutRepositoryProvider);
    final binding = await _ref.read(appDatabaseProvider).syncDao.readState();
    _sessionAccount = authority.state?.accountId ?? binding?.accountId;
    if (!current()) return;
    final id = await repo.startSession(
      guard: current,
      accountId: authority.state?.accountId,
      guidance: guidance,
    );
    if (!current()) return;
    final row = await _ref.read(appDatabaseProvider).workoutDao.getSession(id);
    if (!current() || row == null) return;
    state = ActiveWorkoutState(
      sessionId: id,
      startTime: DateTime.now(),
      isActive: true,
      selectedExercises: state.selectedExercises,
      sessionSyncId: row.syncId,
      guidance: guidance,
    );
    // The planner may call startSession inside its short-lived transaction.
    // Persistent subscriptions must not retain that transaction's Drift zone.
    _sessionSubscription = _persistentDatabaseZone().run(
      () => repo.watchSession(id).listen((row) {
        if (row == null ||
            row.syncId != state.sessionSyncId ||
            row.deletedAtUtc != null ||
            row.dataKoniec != null) {
          _resetIfCurrent(id, generation);
        } else {
          _observeGuidance(row, generation);
        }
      }),
    );
    updateDraft({});
  }

  void updateDraft(Map<String, Object?> changes) {
    if (!state.isActive || state.sessionId == null || !_ownsAuthority) return;
    final fields = {...state.draft};
    // Bind older checkpoints BEFORE merging a side/variant-only form edit.
    if (fields['timer'] != null && fields['timerBinding'] == null) {
      fields['timerBinding'] = _timerBinding(fields);
    }
    fields.addAll(changes);
    if (changes.containsKey('timer')) {
      if (changes['timer'] == null) {
        fields.remove('timerBinding');
      } else {
        fields['timerBinding'] = _timerBinding(fields);
      }
    }
    if (_consumingCheckpointKey != null && state.sessionSyncId != null) {
      final signature = state.guidance == null
          ? null
          : jsonEncode(state.guidance!.toJson());
      final before = <String, Object?>{
        'fields': state.draft,
        'currentSlot': state.currentSlot,
        'guidanceSignature': signature,
      };
      final after = <String, Object?>{...before, 'fields': fields};
      if (changedCheckpointKeys(
        state.sessionSyncId!,
        before,
        after,
      ).contains(_consumingCheckpointKey)) {
        // Reject a new/late timer for the consuming key before accepting it in
        // RAM. Other fields and every unrelated checkpoint still enter the queue.
        throw WorkoutDraftConflict();
      }
    }
    state = state.copyWith(draft: Map.unmodifiable(fields));
    final snapshot = state;
    final generation = _generation;
    final authority = _ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    final account = _sessionAccount;
    if (account == null) return;
    final repo = _ref.read(workoutRepositoryProvider);
    final signature = snapshot.guidance == null
        ? null
        : jsonEncode(snapshot.guidance!.toJson());
    bool guard() =>
        _isCurrent(snapshot.sessionId!, generation) &&
        authority.epoch == epoch &&
        !_intervalClosing &&
        (signature ==
                (state.guidance == null
                    ? null
                    : jsonEncode(state.guidance!.toJson())) ||
            (signature != null &&
                state.guidance != null &&
                _ownGuidanceRebases[signature] ==
                    jsonEncode(state.guidance!.toJson())));
    final payload =
        jsonDecode(
              jsonEncode({
                'schemaVersion': 1,
                'currentSlot': snapshot.currentSlot,
                'guidanceSignature': signature,
                'fields': snapshot.draft,
                'selectedIds': snapshot.selectedExercises
                    .map((e) => e.id)
                    .toList(),
              }),
            )
            as Map<String, dynamic>;
    final before = _lastDraftSnapshot ?? <String, Object?>{};
    final patch = WorkoutDraftPatch.between(
      before,
      payload,
      _timerPatchEpochs(before, payload),
    );
    _lastDraftSnapshot = payload;
    // Queue snapshots in capture order; no delayed write can overtake a newer one.
    // A draft outlives the caller's transaction. Register callbacks outside its
    // Drift zone; otherwise planner start can leave every later write chained
    // behind a retired remote executor (or a closed native transaction).
    _draftWrites = _persistentDatabaseZone().run<Future<void>>(
      () => _draftWrites
          .then((_) async {
            if (!guard()) return;
            if (!guard() || snapshot.sessionSyncId == null) return;
            for (var attempt = 0; attempt < 4; attempt++) {
              final current = await repo.readDraft(
                account,
                snapshot.sessionSyncId!,
              );
              if (!guard()) return;
              final currentEpochs = checkpointEpochs(current);
              final retiredByOwner = patch.expectedEpochs.entries
                  .where(
                    (e) =>
                        (currentEpochs[e.key] ?? 0) > e.value &&
                        _checkpointEpochs[e.key] == currentEpochs[e.key],
                  )
                  .map((e) => e.key)
                  .toSet();
              final ownSignature =
                  signature != null &&
                      state.guidance != null &&
                      _ownGuidanceRebases[signature] ==
                          jsonEncode(state.guidance!.toJson())
                  ? jsonEncode(state.guidance!.toJson())
                  : null;
              final rebased = current == null
                  ? WorkoutDraftPatch.between(
                      {},
                      payload,
                      patch.expectedEpochs,
                    ).apply({})
                  : patch.apply(
                      current,
                      retiredByOwner: retiredByOwner,
                      ownGuidanceSignature: ownSignature,
                    );
              if (signature != null &&
                  state.guidance != null &&
                  _ownGuidanceRebases[signature] ==
                      jsonEncode(state.guidance!.toJson())) {
                rebased['guidanceSignature'] = jsonEncode(
                  state.guidance!.toJson(),
                );
              }
              rebased.addAll({
                'draftRevision': draftRevision(current),
                'checkpointEpochs': checkpointEpochs(current),
              });
              try {
                final changedKeys = changedCheckpointKeys(
                  snapshot.sessionSyncId!,
                  current,
                  rebased,
                );
                final persistedVersions = checkpointVersions(current);
                for (final key in changedKeys) {
                  if ((persistedVersions[key] ?? 0) !=
                      (_checkpointVersions[key] ?? 0)) {
                    throw WorkoutDraftConflict();
                  }
                }
                final committed = await repo.saveDraft(
                  sessionId: snapshot.sessionId!,
                  sessionSyncId: snapshot.sessionSyncId!,
                  accountId: account,
                  payload: rebased,
                  guard: guard,
                );
                if (guard()) {
                  final versions = checkpointVersions(committed);
                  for (final key in changedKeys) {
                    _checkpointVersions[key] = versions[key] ?? 0;
                  }
                }
                return;
              } on WorkoutDraftConflict catch (error) {
                if (!error.revisionOnly || attempt == 3) rethrow;
              }
            }
          })
          .catchError((Object error) async {
            bool owned() => guard();
            if (!owned()) return;
            if (error is WorkoutAccountUnavailable ||
                error is WorkoutSessionUnavailable) {
              // Only genuinely stale work is a cancellation. A refused write for
              // the SAME live account/session is a failed checkpoint, not success.
              try {
                final db = _ref.read(appDatabaseProvider);
                final binding = await db.syncDao.readState();
                final row = await db.workoutDao.getSession(snapshot.sessionId!);
                if (!owned() ||
                    binding?.accountId != account ||
                    binding?.offlineAccess != true ||
                    row?.syncId != snapshot.sessionSyncId ||
                    row?.dataKoniec != null ||
                    row?.deletedAtUtc != null) {
                  return;
                }
              } catch (_) {
                // Keep the original write error visible if verification also fails.
              }
            }
            if (!owned()) return;
            _draftError = error;
            state = state.copyWith();
          }),
    );
  }

  String? get draftSaveError =>
      _draftError == null ? null : 'Nie zapisano szkicu: $_draftError';

  Map<String, int> _timerPatchEpochs(
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    final result = <String, int>{};
    Map fields(Map p) => p['fields'] as Map? ?? {};
    void addMain(Map form) {
      final b = form['timerBinding'] is Map
          ? form['timerBinding'] as Map
          : _timerBinding(Map<String, Object?>.from(form));
      if (b['exerciseId'] is! String) return;
      final key = checkpointKey(
        state.sessionSyncId,
        b['exerciseId'] as String,
        b['side'] as String?,
        b['variantId'] as String?,
        extra: false,
        slot: b['slotIndex'] as int?,
      );
      result[key] = _checkpointEpochs[key] ?? 0;
    }

    bool timerChanged(Map a, Map b) =>
        !draftValueEquals(a['timer'], b['timer']) ||
        !draftValueEquals(a['timerBinding'], b['timerBinding']);
    final a = fields(before), b = fields(after);
    if (timerChanged(a, b)) {
      if (a['timer'] != null) addMain(a);
      if (b['timer'] != null) addMain(b);
    }
    final oldForms = a['extraForms'] as Map? ?? {},
        newForms = b['extraForms'] as Map? ?? {};
    for (final key in {
      ...oldForms.keys.cast<String>(),
      ...newForms.keys.cast<String>(),
    }) {
      if (timerChanged(
        oldForms[key] as Map? ?? {},
        newForms[key] as Map? ?? {},
      )) {
        result[key] = _checkpointEpochs[key] ?? 0;
      }
    }
    return result;
  }

  Map<String, Object?> _timerBinding(
    Map<String, Object?> fields, {
    String? exerciseId,
    bool extra = false,
  }) => {
    'sessionSyncId': state.sessionSyncId,
    'exerciseId': exerciseId ?? state.guidance?.exerciseAt(state.currentSlot),
    'slotIndex': state.guidance == null || extra ? null : state.currentSlot,
    'extra': extra,
    'side': fields['side'],
    'variantId': fields['variantId'],
  };

  bool _checkpointMatches(IntervalWriteOrigin origin) {
    final fields = state.exerciseDraft(
      origin.exercise.id,
      extra: origin.extra,
      side: origin.side,
      variantId: origin.variantId,
    );
    if (state.guidance == null || fields['timer'] == null) return true;
    final binding =
        fields['timerBinding'] ??
        _timerBinding(
          fields,
          exerciseId: origin.exercise.id,
          extra: origin.extra,
        );
    if (binding is! Map) return false;
    return binding['sessionSyncId'] == origin.sessionSyncId &&
        binding['exerciseId'] == origin.exercise.id &&
        binding['slotIndex'] == origin.guidanceSlot &&
        (binding['extra'] == true) == origin.extra &&
        binding['side'] == origin.side &&
        binding['variantId'] == origin.variantId &&
        fields['side'] == origin.side &&
        fields['variantId'] == origin.variantId;
  }

  Map<String, Object?> _clearedGuidedFields() => {
    if (state.draft.containsKey('extraForms'))
      'extraForms': state.draft['extraForms'],
    if (state.draft.containsKey('extraSelections'))
      'extraSelections': state.draft['extraSelections'],
  };

  Map<String, Object?> _withExtraForm(
    Map<String, Object?> root,
    String exerciseId,
    Map<String, Object?> fields,
    String? side,
    String? variantId,
  ) => {
    ...root,
    'extraForms': {
      if (root['extraForms'] is Map)
        ...Map<String, Object?>.from(root['extraForms'] as Map),
      state.extraDraftKey(exerciseId, side, variantId): fields,
    },
    'extraSelections': {
      if (root['extraSelections'] is Map)
        ...Map<String, Object?>.from(root['extraSelections'] as Map),
      exerciseId: {
        'side': side,
        'variantId': variantId,
        'variantLabel': fields['variantLabel'],
      },
    },
  };

  void updateExerciseDraft(
    String exerciseId,
    Map<String, Object?> changes, {
    bool extra = false,
    String? side,
    String? variantId,
  }) {
    if (!extra) {
      updateDraft(changes);
      return;
    }
    if (!state.isActive ||
        !_ownsAuthority ||
        !state.isExtraExercise(exerciseId)) {
      return;
    }
    final fields = {
      ...state.exerciseDraft(
        exerciseId,
        extra: true,
        side: side,
        variantId: variantId,
      ),
      ...changes,
      'side': side,
      'variantId': variantId,
    };
    if (changes.containsKey('timer')) {
      fields['timerBinding'] = changes['timer'] == null
          ? null
          : _timerBinding(fields, exerciseId: exerciseId, extra: true);
    }
    final root = _withExtraForm(
      state.draft,
      exerciseId,
      fields,
      side,
      variantId,
    );
    updateDraft({
      'extraForms': root['extraForms'],
      'extraSelections': root['extraSelections'],
    });
  }

  Object? _draftError;
  Future<void> flushDraft() async {
    await _draftWrites;
    if (_draftError != null) {
      throw StateError('Szkic nie został zapisany: $_draftError');
    }
  }

  bool moveGuided(int slot) {
    final g = state.guidance;
    if (!_ownsAuthority ||
        _guidedBusy ||
        g == null ||
        slot < 0 ||
        slot >= g.plan.blocks.length) {
      return false;
    }
    state = state.copyWith(currentSlot: slot, draft: _clearedGuidedFields());
    updateDraft({});
    return true;
  }

  Future<bool> guidedEvent({String? replacement}) async {
    if (_guidedBusy || state.guidance == null || state.sessionSyncId == null) {
      return false;
    }
    _guidedBusy = true;
    final snapshot = state, generation = _generation;
    final authority = _ref.read(cachedAuthWriteAuthorityProvider),
        epoch = _ref.read(cachedAuthWriteAuthorityProvider).epoch;
    bool guard() =>
        _isCurrent(snapshot.sessionId!, generation) &&
        authority.epoch == epoch &&
        !_intervalClosing;
    try {
      final binding = await _ref.read(appDatabaseProvider).syncDao.readState();
      if (!guard() || binding == null || binding.accountId != _sessionAccount) {
        return false;
      }
      await _ref
          .read(workoutRepositoryProvider)
          .guidanceEvent(
            sessionId: snapshot.sessionId!,
            sessionSyncId: snapshot.sessionSyncId!,
            accountId: binding.accountId,
            guard: guard,
            slot: snapshot.currentSlot,
            replacement: replacement,
          );
      final row = await _ref
          .read(appDatabaseProvider)
          .workoutDao
          .getSession(snapshot.sessionId!);
      if (!guard() || row?.syncId != snapshot.sessionSyncId) return false;
      state = state.copyWith(
        guidance: WorkoutGuidance.tryRead(row!.guidanceJson),
        draft: _clearedGuidedFields(),
      );
      updateDraft({});
      return true;
    } on WorkoutAccountUnavailable {
      return false;
    } on WorkoutSessionUnavailable {
      return false;
    } finally {
      _guidedBusy = false;
    }
  }

  Future<bool> resumeSession(
    String sessionSyncId, {
    bool restartSegment = false,
  }) async {
    if (state.isActive) return false;
    final generation = ++_generation;
    final authority = _ref.read(cachedAuthWriteAuthorityProvider),
        epoch = _ref.read(cachedAuthWriteAuthorityProvider).epoch;
    final db = _ref.read(appDatabaseProvider),
        repo = _ref.read(workoutRepositoryProvider);
    bool guard() =>
        mounted &&
        generation == _generation &&
        authority.epoch == epoch &&
        (authority.state == null || authority.state!.isSignedIn);
    ActiveWorkoutState? restored;
    await db.transaction(() async {
      final binding = await db.syncDao.readState();
      if (!guard() ||
          binding?.offlineAccess != true ||
          (authority.state != null &&
              authority.state!.accountId != binding!.accountId)) {
        return;
      }
      final row = await repo.findSessionBySyncId(sessionSyncId);
      if (!guard() ||
          row == null ||
          row.dataKoniec != null ||
          row.deletedAtUtc != null) {
        return;
      }
      final drafts = await repo.pendingDrafts(binding!.accountId);
      final draft = drafts
          .where((d) => d.sessionSyncId == sessionSyncId)
          .firstOrNull;
      if (draft == null) return;
      try {
        final j = validateWorkoutDraft(jsonDecode(draft.payloadJson));
        if (j['schemaVersion'] != 1) return;
        final guidance = WorkoutGuidance.tryRead(row.guidanceJson);
        if (row.guidanceJson != null && guidance == null) {
          return; // not a silent legacy downgrade
        }
        if (j['guidanceSignature'] !=
            (guidance == null ? null : jsonEncode(guidance.toJson()))) {
          return;
        }
        final slot = j['currentSlot'] as int;
        if (slot < 0 ||
            (guidance != null && slot >= guidance.plan.blocks.length)) {
          return;
        }
        final fields = Map<String, Object?>.from(j['fields'] as Map);
        if (restartSegment && fields['timer'] is Map) {
          fields['timer'] = IntervalTimer.restore(
            Map<String, dynamic>.from(fields['timer'] as Map),
            restartSegment: true,
          ).checkpoint();
        }
        final ids = {
          ...(j['selectedIds'] as List).cast<String>(),
          if (guidance != null)
            ...List.generate(guidance.plan.blocks.length, guidance.exerciseAt),
        };
        final catalog = await _ref
            .read(exercisesRepositoryProvider)
            .watchAll()
            .first;
        final sets = await repo.getSetsForSession(row.id);
        final after = await db.syncDao.readState();
        if (!guard() ||
            after?.accountId != binding.accountId ||
            after?.offlineAccess != true) {
          return;
        }
        _sessionAccount = binding.accountId;
        _lastDraftSnapshot = draftDomain(j);
        _checkpointEpochs = checkpointEpochs(j);
        _checkpointVersions = checkpointVersions(j);
        _draftError = null;
        restored = ActiveWorkoutState(
          sessionId: row.id,
          sessionSyncId: row.syncId,
          startTime: row.dataStart.toLocal(),
          isActive: true,
          guidance: guidance,
          currentSlot: slot,
          draft: fields,
          selectedExercises: catalog.where((e) => ids.contains(e.id)).toList(),
          loggedSets: sets
              .map(
                (s) => ActiveSetEntry(
                  exerciseId: s.cwiczenieId,
                  exerciseNamePl: s.nazwaCwiczeniaPl,
                  setNumber: s.numerSerii,
                  weightKg: s.ciezarKg,
                  reps: s.powtorzenia,
                  seconds: s.czasSekund,
                  side: s.side,
                  variantId: s.variantId,
                  variantLabel: s.variantLabel,
                  rpe: s.rpe,
                ),
              )
              .toList(),
        );
      } on FormatException {
        return;
      } on TypeError {
        return;
      }
    });
    if (!guard() || restored == null) return false;
    _sessionAuthority = authority;
    _sessionEpoch = epoch;
    _intervalClosing = false;
    state = restored!;
    await _sessionSubscription?.cancel();
    _sessionSubscription = _persistentDatabaseZone().run(
      () => repo.watchSession(state.sessionId!).listen((row) {
        if (row == null ||
            row.syncId != sessionSyncId ||
            row.deletedAtUtc != null ||
            row.dataKoniec != null) {
          if (mounted && generation == _generation) discardSession();
        } else {
          _observeGuidance(row, generation);
        }
      }),
    );
    return true;
  }

  /// Closing a damaged draft must not need to decode its guidance or timer.
  Future<int?> finishPendingSession(String sessionSyncId) async {
    if (state.isActive) return null;
    final generation = _generation;
    final authority = _ref.read(cachedAuthWriteAuthorityProvider),
        epoch = _ref.read(cachedAuthWriteAuthorityProvider).epoch;
    bool guard() =>
        mounted &&
        generation == _generation &&
        !state.isActive &&
        authority.epoch == epoch &&
        (authority.state == null || authority.state!.isSignedIn);
    final db = _ref.read(appDatabaseProvider),
        repo = _ref.read(workoutRepositoryProvider);
    try {
      return await db.transaction(() async {
        final binding = await db.syncDao.readState();
        if (!guard() ||
            binding?.offlineAccess != true ||
            (authority.state != null &&
                authority.state!.accountId != binding!.accountId)) {
          return null;
        }
        final drafts = await repo.pendingDrafts(binding!.accountId);
        if (!guard() || !drafts.any((d) => d.sessionSyncId == sessionSyncId)) {
          return null;
        }
        final row = await repo.findSessionBySyncId(sessionSyncId);
        if (!guard() ||
            row == null ||
            row.dataKoniec != null ||
            row.deletedAtUtc != null) {
          return null;
        }
        await repo.finishSession(
          row.id,
          row.dataStart,
          expectedSyncId: sessionSyncId,
          accountId: binding.accountId,
          guard: guard,
        );
        return row.id;
      });
    } on WorkoutAccountUnavailable {
      return null;
    } on WorkoutSessionUnavailable {
      return null;
    }
  }

  void addExercise(Exercise exercise) {
    if (state.selectedExercises.any((e) => e.id == exercise.id)) return;
    state = state.copyWith(
      selectedExercises: [...state.selectedExercises, exercise],
    );
    updateDraft({});
  }

  void removeExercise(String exerciseId) {
    state = state.copyWith(
      selectedExercises: state.selectedExercises
          .where((e) => e.id != exerciseId)
          .toList(),
    );
    updateDraft({});
  }

  IntervalWriteOrigin? captureInterval({
    required Exercise exercise,
    String? side,
    String? variantId,
    String? variantLabel,
    int? rpe,
    bool extra = false,
  }) {
    if (!mounted || !state.isActive || state.sessionId == null) return null;
    if (extra && !state.isExtraExercise(exercise.id)) return null;
    if (!extra &&
        state.guidance != null &&
        state.guidance!.exerciseAt(state.currentSlot) != exercise.id) {
      return null;
    }
    final authority = _ref.read(cachedAuthWriteAuthorityProvider);
    final key = checkpointKey(
      state.sessionSyncId,
      exercise.id,
      side,
      variantId,
      extra: extra,
      slot: state.guidance == null || extra ? null : state.currentSlot,
    );
    if (_consumingCheckpointKey == key) return null;
    final origin = IntervalWriteOrigin._(
      this,
      state.sessionId!,
      _generation,
      authority,
      authority.epoch,
      exercise,
      side,
      rpe,
      state.sessionSyncId,
      state.guidance == null || extra ? null : state.currentSlot,
      variantId,
      variantLabel,
      extra,
      key,
      _checkpointEpochs[key] ?? 0,
    );
    return isIntervalCurrent(origin) ? origin : null;
  }

  bool isIntervalCheckpointCurrent(IntervalWriteOrigin origin) =>
      !origin._claimed &&
      _consumingCheckpointKey != origin.checkpointKey &&
      isIntervalCurrent(origin);

  /// The opaque origin is the callback nonce. A late ticker of a claimed timer
  /// cannot create fresh work while its batch is being consumed (or afterward).
  bool updateIntervalCheckpoint(
    IntervalWriteOrigin origin,
    Map<String, Object?>? checkpoint,
  ) {
    if (!isIntervalCheckpointCurrent(origin)) return false;
    updateExerciseDraft(
      origin.exercise.id,
      {'timer': checkpoint},
      extra: origin.extra,
      side: origin.side,
      variantId: origin.variantId,
    );
    return true;
  }

  bool isIntervalCurrent(IntervalWriteOrigin origin) =>
      identical(origin._owner, this) &&
      _isCurrent(origin.sessionId, origin._generation) &&
      state.isActive &&
      state.sessionSyncId == origin.sessionSyncId &&
      (origin.extra
          ? state.isExtraExercise(origin.exercise.id)
          : (state.guidance == null ||
                state.guidance!.exerciseAt(state.currentSlot) ==
                    origin.exercise.id)) &&
      (origin.guidanceSlot == null ||
          state.currentSlot == origin.guidanceSlot) &&
      !_intervalClosing &&
      origin._authority.epoch == origin._epoch &&
      (_checkpointEpochs[origin.checkpointKey] ?? 0) ==
          origin.checkpointEpoch &&
      _checkpointMatches(origin) &&
      (origin._authority.state == null || origin._authority.state!.isSignedIn);

  /// True means the entire batch was written, not a PR flag. One explicit
  /// attempt per capture, with a synchronous reservation before the first await.
  Future<bool> saveIntervalRounds(
    IntervalWriteOrigin origin,
    List<IntervalRound> rounds, {
    bool Function()? guard,
  }) async {
    if (_draftConsumptionInFlight ||
        origin._claimed ||
        !isIntervalCurrent(origin)) {
      return false;
    }
    origin._claimed = true;
    final results = List<IntervalRound>.of(rounds);
    final saveStep = state.currentSlot;
    final expectedVersion = _checkpointVersions[origin.checkpointKey] ?? 0;
    if (results.isEmpty ||
        results.length > 100 ||
        results.any((r) => r.seconds < 1 || r.seconds > 3600) ||
        results.any((r) => r.round < 1 || r.round > 100) ||
        results.map((r) => r.round).toSet().length != results.length) {
      return false;
    }
    void requireOwnership() {
      if (!isIntervalCurrent(origin) ||
          (origin.extra && state.currentSlot != saveStep) ||
          !(guard?.call() ?? true)) {
        throw WorkoutAccountUnavailable();
      }
    }

    final db = _ref.read(appDatabaseProvider);
    final repo = _ref.read(workoutRepositoryProvider);
    final entries = <ActiveSetEntry>[];
    final previousDraft = state.draft;
    final consumesDraft = state.guidance != null;
    final previousGuidanceSignature = state.guidance == null
        ? null
        : jsonEncode(state.guidance!.toJson());
    Map<String, Object?>? consumedPayload;
    final expectedForm = Map<String, Object?>.from(
      jsonDecode(
            jsonEncode(
              state.exerciseDraft(
                origin.exercise.id,
                extra: origin.extra,
                side: origin.side,
                variantId: origin.variantId,
              ),
            ),
          )
          as Map,
    );
    if (consumesDraft) {
      _draftConsumptionInFlight = true;
      _consumingCheckpointKey = origin.checkpointKey;
    }

    try {
      try {
        await db.transaction(() async {
          requireOwnership();
          final binding = await db.syncDao.readState();
          requireOwnership();
          if ((binding != null && !binding.offlineAccess) ||
              (_sessionAccount != null &&
                  binding?.accountId != _sessionAccount) ||
              (origin._authority.state != null &&
                  binding?.accountId != origin._authority.state!.accountId)) {
            throw WorkoutAccountUnavailable();
          }
          final session = await db.workoutDao.getSession(origin.sessionId);
          requireOwnership();
          if (session == null ||
              (origin.sessionSyncId != null &&
                  session.syncId != origin.sessionSyncId) ||
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
              variantId: origin.variantId,
              variantLabel: origin.variantLabel,
              accountId: binding?.accountId,
              guard: () => isIntervalCurrent(origin) && (guard?.call() ?? true),
              rpe: origin.rpe,
              guidanceSlot: origin.guidanceSlot,
              expectedSyncId: origin.sessionSyncId,
            );
            requireOwnership();
            entries.add(
              ActiveSetEntry(
                exerciseId: origin.exercise.id,
                exerciseNamePl: origin.exercise.nazwaPl,
                setNumber: number,
                seconds: result.seconds,
                side: origin.side,
                variantId: origin.variantId,
                variantLabel: origin.variantLabel,
                rpe: origin.rpe,
              ),
            );
          }
          if (consumesDraft && binding != null) {
            final row = await db.workoutDao.getSession(origin.sessionId);
            requireOwnership();
            final guidance = WorkoutGuidance.tryRead(row?.guidanceJson);
            if (row?.syncId != origin.sessionSyncId || guidance == null) {
              throw WorkoutSessionUnavailable(origin.sessionId);
            }
            // Consuming a checkpoint is part of the same commit as its actual
            // rounds. A crash after commit must not offer those results again.
            consumedPayload = await repo.consumeDraftCheckpoint(
              sessionId: origin.sessionId,
              sessionSyncId: origin.sessionSyncId!,
              accountId: binding.accountId,
              key: origin.checkpointKey,
              expectedEpoch: origin.checkpointEpoch,
              expectedVersion: expectedVersion,
              extra: origin.extra,
              exerciseId: origin.exercise.id,
              fallbackPayload: {
                'schemaVersion': 1,
                'currentSlot': saveStep,
                'selectedIds': state.selectedExercises
                    .map((e) => e.id)
                    .toList(),
                'guidanceSignature': jsonEncode(guidance.toJson()),
                'fields': previousDraft,
              },
              guard: () => isIntervalCurrent(origin) && (guard?.call() ?? true),
            );
            final nextSignature =
                consumedPayload!['guidanceSignature'] as String?;
            if (previousGuidanceSignature != null &&
                nextSignature != null &&
                previousGuidanceSignature != nextSignature) {
              for (final key in _ownGuidanceRebases.keys.toList()) {
                if (_ownGuidanceRebases[key] == previousGuidanceSignature) {
                  _ownGuidanceRebases[key] = nextSignature;
                }
              }
              _ownGuidanceRebases[previousGuidanceSignature] = nextSignature;
            }
            requireOwnership();
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
      } on WorkoutDraftConflict catch (error) {
        _draftError = error;
        if (mounted) state = state.copyWith();
        return false;
      }
      if (!isIntervalCurrent(origin)) return false;
      state = state.copyWith(loggedSets: [...state.loggedSets, ...entries]);
      if (origin.guidanceSlot != null) {
        final row = await db.workoutDao.getSession(origin.sessionId);
        if (isIntervalCurrent(origin)) {
          state = state.copyWith(
            guidance: WorkoutGuidance.tryRead(row?.guidanceJson),
          );
        }
      }
      if (consumedPayload != null) {
        final epoch = checkpointEpochs(consumedPayload)[origin.checkpointKey]!;
        final version = checkpointVersions(
          consumedPayload,
        )[origin.checkpointKey]!;
        if (epoch > (_checkpointEpochs[origin.checkpointKey] ?? 0)) {
          _checkpointEpochs[origin.checkpointKey] = epoch;
        }
        if (version > (_checkpointVersions[origin.checkpointKey] ?? 0)) {
          _checkpointVersions[origin.checkpointKey] = version;
        }
      }
      if (consumesDraft) {
        state = state.copyWith(
          draft: mergeConsumedCheckpointFields(
            state.draft,
            key: origin.checkpointKey,
            extra: origin.extra,
            expectedForm: expectedForm,
          ),
        );
      }
      _consumingCheckpointKey = null;
      _draftConsumptionInFlight = false;
      if (consumesDraft) {
        // Persist only the final targeted delta from current RAM.
        updateDraft({});
      } else {
        updateDraft({'timer': null}); // unchanged legacy/manual path
      }
      return true;
    } finally {
      if (_consumingCheckpointKey == origin.checkpointKey) {
        _consumingCheckpointKey = null;
      }
      _draftConsumptionInFlight = false;
    }
  }

  /// Zapisuje serię do bazy + wykrywa PR + zwraca info czy to nowy rekord.
  Future<bool> logSet({
    required Exercise exercise,
    double? weightKg,
    int? reps,
    int? seconds,
    int? rpe,
    String? side,
    String? variantId,
    String? variantLabel,
    bool extra = false,
  }) async {
    if (state.sessionId == null ||
        !_ownsAuthority ||
        _guidedBusy ||
        _intervalClosing) {
      return false;
    }
    if (extra && !state.isExtraExercise(exercise.id)) return false;
    final guidedSlot = state.guidance == null || extra
        ? null
        : state.currentSlot;
    if (guidedSlot != null &&
        state.guidance!.exerciseAt(guidedSlot) != exercise.id) {
      return false;
    }
    final guardedGuidedWrite = state.guidance != null;
    if (guardedGuidedWrite) _guidedBusy = true;
    try {
      final sessionId = state.sessionId!;
      final generation = _generation;
      final repo = _ref.read(workoutRepositoryProvider);

      // SQLite reads inside this transaction cannot observe a logout lock queued
      // behind it. The passive auth epoch changes synchronously at logout start.
      final authority = _ref.read(cachedAuthWriteAuthorityProvider);
      final authEpoch = authority.epoch;

      var setNumber =
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
              (_sessionAccount != null &&
                  binding?.accountId != _sessionAccount) ||
              (authority.state != null &&
                  binding?.accountId != authority.state!.accountId)) {
            throw WorkoutAccountUnavailable();
          }
          variantLabel = await ExerciseVariantsRepository.requireLive(
            _ref.read(appDatabaseProvider),
            exercise.id,
            variantId,
            accountId: binding?.accountId,
          );
          requireOwnership();
          final previous = await repo.getLastSet(
            exercise.id,
            side: side,
            variantId: variantId,
          );
          requireOwnership();
          comparison = setComparison(
            weightKg: weightKg,
            reps: reps,
            seconds: seconds,
            previousWeightKg: previous?.ciezarKg,
            previousReps: previous?.powtorzenia,
            previousSeconds: previous?.czasSekund,
          );
          final existingSets = await repo.getSetsForSession(sessionId);
          requireOwnership();
          setNumber =
              existingSets
                  .where((s) => s.cwiczenieId == exercise.id)
                  .fold<int>(0, (n, s) => s.numerSerii > n ? s.numerSerii : n) +
              1;
          await repo.logSet(
            sessionId: sessionId,
            exerciseId: exercise.id,
            exerciseNamePl: exercise.nazwaPl,
            setNumber: setNumber,
            weightKg: weightKg,
            reps: reps,
            seconds: seconds,
            side: side,
            variantId: variantId,
            variantLabel: variantLabel,
            accountId: binding?.accountId,
            guard: () =>
                _isCurrent(sessionId, generation) &&
                authority.epoch == authEpoch,
            rpe: rpe,
            guidanceSlot: guidedSlot,
            expectedSyncId: state.sessionSyncId,
          );
          requireOwnership();

          if (seconds == null &&
              weightKg != null &&
              reps != null &&
              weightKg > 0 &&
              reps > 0) {
            final prsRepo = _ref.read(prsRepositoryProvider);
            final best = await prsRepo.getBestForExercise(
              exercise.id,
              side: side,
              variantId: variantId,
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
                variantId: variantId,
                variantLabel: variantLabel,
                accountId: binding?.accountId,
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
        _guidedBusy = false;
        _resetIfCurrent(sessionId, generation);
        return false;
      } on WorkoutAccountUnavailable {
        _guidedBusy = false;
        _resetIfCurrent(sessionId, generation);
        return false;
      }
      if (!_isCurrent(sessionId, generation)) return false;
      final row = await _ref
          .read(appDatabaseProvider)
          .workoutDao
          .getSession(sessionId);
      if (!_isCurrent(sessionId, generation)) return false;
      if (guidedSlot != null) {
        state = state.copyWith(
          guidance: WorkoutGuidance.tryRead(row?.guidanceJson),
        );
      }

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
            variantId: variantId,
            variantLabel: variantLabel,
            rpe: rpe,
            isNewPr: isNewPr,
            comparison: comparison,
          ),
        ],
      );

      if (guidedSlot != null) updateDraft({'timer': null});
      return isNewPr;
    } finally {
      if (guardedGuidedWrite) _guidedBusy = false;
    }
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
                  variantId: s.variantId,
                  variantLabel: s.variantLabel,
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
    _sessionSubscription = _persistentDatabaseZone().run(
      () => _ref
          .read(workoutRepositoryProvider)
          .watchSession(session.id)
          .listen((row) {
            if (row == null ||
                row.deletedAtUtc != null ||
                row.dataKoniec != null) {
              _resetIfCurrent(session.id, generation);
            }
          }),
    );
    return write;
  }

  Future<void> finishSession({String? note}) async {
    if (state.sessionId == null || state.startTime == null) return;
    // Invalidate timer captures synchronously: SQLite finish may be queued
    // behind an in-flight interval transaction, which must then roll back.
    _intervalClosing = true;
    final sessionId = state.sessionId!;
    final startTime = state.startTime!;
    final generation = _generation;
    final repo = _ref.read(workoutRepositoryProvider);
    final authority = _ref.read(cachedAuthWriteAuthorityProvider),
        epoch = _ref.read(cachedAuthWriteAuthorityProvider).epoch;
    final account = _sessionAccount;
    bool guard() =>
        _isCurrent(sessionId, generation) && authority.epoch == epoch;
    try {
      await repo.finishSession(
        sessionId,
        startTime,
        expectedSyncId: state.sessionSyncId,
        guard: guard,
        note: note,
        accountId: account,
      );
    } on WorkoutAccountUnavailable {
      if (mounted && generation == _generation) discardSession();
      return;
    } on WorkoutSessionUnavailable {
      // A restore/pull may win the race before the watch notification arrives.
      _resetIfCurrent(sessionId, generation);
      return;
    }
    _resetIfCurrent(sessionId, generation);
  }

  void discardSession() {
    _generation++;
    _lastDraftSnapshot = null;
    _checkpointEpochs = {};
    _checkpointVersions = {};
    _draftError = null;
    _ownGuidanceRebases.clear();
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

final pendingWorkoutDraftsProvider = StreamProvider<List<WorkoutDraftData>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        'SELECT d.* FROM workout_drafts d '
        'JOIN workout_sessions s ON s.sync_id = d.session_sync_id '
        'JOIN sync_state a ON a.account_id = d.account_id '
        'WHERE a.offline_access = 1 AND s.data_koniec IS NULL AND s.deleted_at_utc IS NULL',
        readsFrom: {db.workoutDrafts, db.workoutSessions, db.syncState},
      )
      .watch()
      .map(
        (rows) => rows
            .map(
              (r) => WorkoutDraftData(
                accountId: r.read<String>('account_id'),
                sessionSyncId: r.read<String>('session_sync_id'),
                payloadJson: r.read<String>('payload_json'),
              ),
            )
            .toList(),
      );
});
