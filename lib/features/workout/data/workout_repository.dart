import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/sync/sync_models.dart';
import '../domain/fixed_load_progression.dart';
import '../domain/workout_guidance.dart';
import '../domain/workout_repeat.dart';
import '../domain/workout_draft_write.dart';
import '../../exercises/data/exercise_variants_repository.dart';

class ActiveSessionExists extends StateError {
  ActiveSessionExists()
    : super('Aktywna sesja wymaga kontynuacji lub jawnego zakończenia.');
}

class WorkoutSessionUnavailable extends StateError {
  WorkoutSessionUnavailable(int id)
    : super('Workout session $id is missing or deleted.');
}

class WorkoutAccountUnavailable extends StateError {
  WorkoutAccountUnavailable() : super('Workout account is no longer active.');
}

class IdempotentSessionWrite {
  const IdempotentSessionWrite(this.session, {required this.alreadyExists});

  final WorkoutSessionData session;
  final bool alreadyExists;
}

class IdempotentSetWrite {
  const IdempotentSetWrite(this.set, {required this.alreadyExists});

  final SetLogData set;
  final bool alreadyExists;
}

/// Repozytorium sesji treningowych - zapis, historia, pobieranie ostatniej serii.
class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  Future<WorkoutRepeatPreview> previewRepeat(
    int source,
    RepeatMode mode,
  ) => _db.transaction(() async {
    final row = await _db.workoutDao.getSession(source);
    final sets = await getSetsForSession(source);
    sets.sort((a, b) => a.syncId.compareTo(b.syncId));
    final issues = <String>[];
    WorkoutRepeat? repeat;
    if (row == null || row.deletedAtUtc != null || row.dataKoniec == null) {
      issues.add('Źródło musi być zakończoną, nieusuniętą sesją.');
    } else {
      try {
        if (mode == RepeatMode.original) {
          final g = WorkoutGuidance.tryRead(row.guidanceJson);
          if (g == null) {
            issues.add(
              'Brak poprawnego oryginalnego snapshotu planu. Wybierz wykonanie.',
            );
          } else {
            repeat = WorkoutRepeat.original(g);
          }
        } else {
          repeat = WorkoutRepeat.execution(sets);
        }
      } on FormatException {
        issues.add(
          'Historia zawiera nieobsługiwane pomiary. Nie pominięto ich ani nie zmieniono.',
        );
      }
    }
    if (repeat != null) {
      if (repeat.targets.isEmpty) {
        issues.add('Brak potwierdzonych serii do powtórzenia.');
      }
      for (var i = 0; i < repeat.targets.length; i++) {
        final t = repeat.targets[i];
        final exercise = await (_db.select(
          _db.exercises,
        )..where((e) => e.id.equals(t.exerciseId))).getSingleOrNull();
        if (exercise == null) {
          issues.add(
            'Pozycja ${i + 1}: ćwiczenie ${t.exerciseId} niedostępne. Przywróć źródło przed powtórzeniem.',
          );
        }
        try {
          await ExerciseVariantsRepository.requireLive(
            _db,
            t.exerciseId,
            t.variantId,
          );
        } on StateError {
          issues.add(
            'Pozycja ${i + 1}: wariant ${t.variantLabel ?? t.variantId} niedostępny. Nie zastąpiono go bazowym.',
          );
        }
      }
    }
    return WorkoutRepeatPreview(
      sourceId: source,
      sourceSyncId: row?.syncId ?? '',
      fingerprint: jsonEncode([
        row?.toJson(),
        sets.map((s) => s.toJson()).toList(),
      ]),
      mode: mode,
      repeat: repeat,
      issues: issues,
    );
  });

  /// Revalidate source, exact targets and catalog inside the write transaction.
  /// A repeat creates only session + outbox + local target draft, never sets/PR.
  Future<WorkoutSessionData> startRepeat({
    required WorkoutRepeatPreview preview,
    required String accountId,
    required String syncId,
    required bool Function() guard,
  }) => _db.transaction(() async {
    await _requireAccount(accountId, guard);
    final fresh = await previewRepeat(preview.sourceId, preview.mode);
    _requireGuard(guard);
    if (!fresh.canStart ||
        fresh.sourceSyncId != preview.sourceSyncId ||
        fresh.fingerprint != preview.fingerprint) {
      throw WorkoutSessionUnavailable(preview.sourceId);
    }
    final existing = await _sessionBySyncId(syncId);
    if (existing != null) {
      if (existing.deletedAtUtc != null || existing.dataKoniec != null) {
        throw WorkoutSessionUnavailable(existing.id);
      }
      return existing;
    }
    final active = await (_db.select(
      _db.workoutSessions,
    )..where((s) => s.dataKoniec.isNull() & s.deletedAtUtc.isNull())).get();
    if (active.isNotEmpty) throw WorkoutSessionUnavailable(active.first.id);
    final repeat = fresh.repeat!;
    final guidance = repeat.plan == null
        ? null
        : WorkoutGuidance.start(repeat.plan!);
    final id = await _createSession(
      accountId: accountId,
      guard: guard,
      guidance: guidance,
      syncId: syncId,
    );
    await saveDraft(
      sessionId: id,
      sessionSyncId: syncId,
      accountId: accountId,
      guard: guard,
      payload: {
        'schemaVersion': 1,
        'currentSlot': 0,
        'selectedIds': repeat.targets.map((t) => t.exerciseId).toSet().toList(),
        'guidanceSignature': guidance == null
            ? null
            : jsonEncode(guidance.toJson()),
        'fields': {if (guidance == null) 'repeatTargets': repeat.toJson()},
      },
    );
    await _requireAccount(accountId, guard);
    return (await _db.workoutDao.getSession(id))!;
  });

  Future<int> startSession({
    bool Function()? guard,
    String? accountId,
    WorkoutGuidance? guidance,
    bool requireNoActiveSession = false,
  }) => _createSession(
    guard: guard,
    accountId: accountId,
    guidance: guidance,
    requireNoActiveSession: requireNoActiveSession,
  );

  Future<int> _createSession({
    bool Function()? guard,
    String? accountId,
    WorkoutGuidance? guidance,
    String? syncId,
    bool requireNoActiveSession = false,
  }) async {
    _requireGuard(guard);
    final now = DateTime.now().toUtc();
    syncId ??= Uuid().v4();
    final sessionSyncId = syncId;
    return _db.transaction(() async {
      _requireGuard(guard);
      if (accountId != null) await _requireAccount(accountId, guard);
      if (requireNoActiveSession) {
        final active =
            await (_db.select(_db.workoutSessions)
                  ..where(
                    (s) => s.dataKoniec.isNull() & s.deletedAtUtc.isNull(),
                  )
                  ..limit(1))
                .get();
        if (active.isNotEmpty) throw ActiveSessionExists();
      }
      final id = await _db.workoutDao.createSession(
        WorkoutSessionsCompanion.insert(
          dataStart: now,
          syncId: Value(sessionSyncId),
          updatedAtUtc: Value(now),
          guidanceJson: Value(
            guidance == null ? null : jsonEncode(guidance.toJson()),
          ),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSession,
        entityId: sessionSyncId,
        baseVersion: 0,
        payload: _sessionPayload(
          dataStart: now,
          dataKoniec: null,
          czasTrwaniaSekund: 0,
          notatka: null,
          guidance: guidance,
        ),
      );
      _requireGuard(guard);
      if (accountId != null) await _requireAccount(accountId, guard);
      return id;
    });
  }

  /// Creates a session exactly once for [syncId]. The account check and the
  /// duplicate lookup happen in the same database transaction as the outbox
  /// mutation, so a restarted caller cannot enqueue a second action.
  /// [guard] is synchronous live ownership (auth + notifier generation), checked
  /// after database awaits as well as before writes. Throwing rolls back both
  /// rows and outbox, including when this runs inside a notifier transaction.
  Future<IdempotentSessionWrite> startSessionIdempotent({
    required String syncId,
    required String accountId,
    bool Function()? guard,
  }) async {
    _requireGuard(guard);
    final now = DateTime.now().toUtc();
    return _db.transaction(() async {
      await _requireAccount(accountId, guard);
      final existing = await _sessionBySyncId(syncId);
      _requireGuard(guard);
      if (existing != null) {
        return IdempotentSessionWrite(existing, alreadyExists: true);
      }
      // A second proposal (or a fresh notifier) must not create another live
      // session while the first start is still awaiting its UI attachment.
      final active = await (_db.select(
        _db.workoutSessions,
      )..where((s) => s.dataKoniec.isNull() & s.deletedAtUtc.isNull())).get();
      _requireGuard(guard);
      if (active.isNotEmpty) throw WorkoutSessionUnavailable(active.first.id);
      final id = await _db.workoutDao.createSession(
        WorkoutSessionsCompanion.insert(
          dataStart: now,
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      _requireGuard(guard);
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSession,
        entityId: syncId,
        baseVersion: 0,
        payload: _sessionPayload(
          dataStart: now,
          dataKoniec: null,
          czasTrwaniaSekund: 0,
          notatka: null,
        ),
      );
      _requireGuard(guard);
      final session = (await _db.workoutDao.getSession(id))!;
      await _requireAccount(accountId, guard);
      _requireGuard(guard);
      return IdempotentSessionWrite(session, alreadyExists: false);
    });
  }

  Future<void> finishSession(
    int sessionId,
    DateTime start, {
    String? expectedSyncId,
    bool Function()? guard,
    String? note,
    String? accountId,
    bool preserveRecordedDuration = false,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      _requireGuard(guard);
      if (accountId != null) await _requireAccount(accountId, guard);
      final session = await _db.workoutDao.getSession(sessionId);
      _requireGuard(guard);
      if (session == null ||
          session.deletedAtUtc != null ||
          (expectedSyncId != null &&
              (session.dataKoniec != null ||
                  session.syncId != expectedSyncId))) {
        throw WorkoutSessionUnavailable(sessionId);
      }
      final duration = preserveRecordedDuration
          ? session.czasTrwaniaSekund
          : now.difference(start).inSeconds;
      await _db.workoutDao.updateSession(
        sessionId,
        WorkoutSessionsCompanion(
          dataKoniec: Value(now),
          czasTrwaniaSekund: Value(duration),
          updatedAtUtc: Value(now),
          notatka: Value(note ?? session.notatka),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSession,
        entityId: session.syncId,
        baseVersion: session.syncVersion,
        payload: _sessionPayload(
          dataStart: session.dataStart,
          dataKoniec: now,
          czasTrwaniaSekund: duration,
          notatka: note ?? session.notatka,
          guidance: WorkoutGuidance.tryRead(session.guidanceJson),
        ),
      );
      await (_db.delete(
        _db.workoutDrafts,
      )..where((d) => d.sessionSyncId.equals(session.syncId))).go();
      if (accountId != null) await _requireAccount(accountId, guard);
      _requireGuard(guard);
    });
  }

  Future<int> logSet({
    required int sessionId,
    required String exerciseId,
    required String exerciseNamePl,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? seconds,
    int? rpe,
    String? side,
    String? variantId,
    String? variantLabel,
    String? accountId,
    bool Function()? guard,
    int? guidanceSlot,
    String? expectedSyncId,
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    return _db.transaction(() async {
      _requireGuard(guard);
      if (accountId != null) await _requireAccount(accountId, guard);
      final label = await ExerciseVariantsRepository.requireLive(
        _db,
        exerciseId,
        variantId,
        accountId: accountId,
      );
      final session = await _db.workoutDao.getSession(sessionId);
      if (session == null ||
          session.deletedAtUtc != null ||
          session.dataKoniec != null ||
          (expectedSyncId != null && session.syncId != expectedSyncId)) {
        throw WorkoutSessionUnavailable(sessionId);
      }
      validateSet(reps: reps, seconds: seconds, weightKg: weightKg, side: side);
      final id = await _db.workoutDao.addSet(
        SetsLogCompanion.insert(
          sesjaId: sessionId,
          cwiczenieId: exerciseId,
          nazwaCwiczeniaPl: exerciseNamePl,
          numerSerii: setNumber,
          ciezarKg: Value(weightKg),
          powtorzenia: Value(reps),
          czasSekund: Value(seconds),
          side: Value(side),
          variantId: Value(variantId),
          variantLabel: Value(label),
          rpe: Value(rpe),
          timestamp: Value(now),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSet,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'sessionSyncId': session.syncId,
          'cwiczenieId': exerciseId,
          'nazwaCwiczeniaPl': exerciseNamePl,
          'numerSerii': setNumber,
          'ciezarKg': weightKg,
          'powtorzenia': reps,
          'czasSekund': seconds,
          if (side != null) 'side': side,
          if (variantId != null) 'variantId': variantId,
          if (variantId != null) 'variantLabel': label,
          'rpe': rpe,
          'timestamp': now.toIso8601String(),
        },
      );
      if (guidanceSlot != null) {
        final guidance = WorkoutGuidance.tryRead(session.guidanceJson);
        if (guidance == null ||
            guidance.exerciseAt(guidanceSlot) != exerciseId) {
          throw StateError(
            'Prowadzenie zmieniło się. Otwórz bieżący blok ponownie.',
          );
        }
        await _writeGuidance(session, guidance.link(guidanceSlot, syncId));
      }
      _requireGuard(guard);
      if (accountId != null) await _requireAccount(accountId, guard);
      return id;
    });
  }

  /// Inserts one set under a caller-owned stable sync ID. Lookup deliberately
  /// includes tombstones: a proposal may never resurrect a remotely deleted
  /// record just because it is retried after a reload.
  Future<IdempotentSetWrite> logSetIdempotent({
    required int sessionId,
    required String exerciseId,
    required String exerciseNamePl,
    required int setNumber,
    required double weightKg,
    required int reps,
    required String syncId,
    required String accountId,
    bool Function()? guard,
  }) async {
    _requireGuard(guard);
    final now = DateTime.now().toUtc();
    return _db.transaction(() async {
      await _requireAccount(accountId, guard);
      final existing = await _setBySyncId(syncId);
      _requireGuard(guard);
      if (existing != null) {
        return IdempotentSetWrite(existing, alreadyExists: true);
      }
      validateSet(reps: reps, weightKg: weightKg);
      final session = await _db.workoutDao.getSession(sessionId);
      _requireGuard(guard);
      if (session == null ||
          session.deletedAtUtc != null ||
          session.dataKoniec != null) {
        throw WorkoutSessionUnavailable(sessionId);
      }
      final id = await _db.workoutDao.addSet(
        SetsLogCompanion.insert(
          sesjaId: sessionId,
          cwiczenieId: exerciseId,
          nazwaCwiczeniaPl: exerciseNamePl,
          numerSerii: setNumber,
          ciezarKg: Value(weightKg),
          powtorzenia: Value(reps),
          timestamp: Value(now),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      _requireGuard(guard);
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSet,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'sessionSyncId': session.syncId,
          'cwiczenieId': exerciseId,
          'nazwaCwiczeniaPl': exerciseNamePl,
          'numerSerii': setNumber,
          'ciezarKg': weightKg,
          'powtorzenia': reps,
          'czasSekund': null,
          'rpe': null,
          'timestamp': now.toIso8601String(),
        },
      );
      _requireGuard(guard);
      final set = await (_db.select(
        _db.setsLog,
      )..where((s) => s.id.equals(id))).getSingle();
      await _requireAccount(accountId, guard);
      _requireGuard(guard);
      return IdempotentSetWrite(set, alreadyExists: false);
    });
  }

  static void _requireGuard(bool Function()? guard) {
    if (guard != null && !guard()) throw WorkoutAccountUnavailable();
  }

  Future<void> _requireAccount(
    String accountId, [
    bool Function()? guard,
  ]) async {
    _requireGuard(guard);
    final state = await _db.syncDao.readState();
    _requireGuard(guard);
    if (state == null || state.accountId != accountId || !state.offlineAccess) {
      throw WorkoutAccountUnavailable();
    }
  }

  Future<WorkoutSessionData?> _sessionBySyncId(String syncId) {
    return (_db.select(
      _db.workoutSessions,
    )..where((session) => session.syncId.equals(syncId))).getSingleOrNull();
  }

  Future<SetLogData?> _setBySyncId(String syncId) {
    return (_db.select(
      _db.setsLog,
    )..where((set) => set.syncId.equals(syncId))).getSingleOrNull();
  }

  static Map<String, Object?> _sessionPayload({
    required DateTime dataStart,
    required DateTime? dataKoniec,
    required int czasTrwaniaSekund,
    required String? notatka,
    WorkoutGuidance? guidance,
  }) => {
    'dataStart': dataStart.toUtc().toIso8601String(),
    'dataKoniec': dataKoniec?.toUtc().toIso8601String(),
    'czasTrwaniaSekund': czasTrwaniaSekund,
    'notatka': notatka,
    if (guidance != null) 'guidance': guidance.toJson(),
  };

  Future<void> _writeGuidance(
    WorkoutSessionData session,
    WorkoutGuidance guidance,
  ) async {
    final checked = WorkoutGuidance.validateJson(guidance.toJson());
    await _db.workoutDao.updateSession(
      session.id,
      WorkoutSessionsCompanion(
        guidanceJson: Value(jsonEncode(checked.toJson())),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
    await _db.syncDao.enqueueUpsert(
      entityType: SyncEntityType.workoutSession,
      entityId: session.syncId,
      baseVersion: session.syncVersion,
      payload: _sessionPayload(
        dataStart: session.dataStart,
        dataKoniec: session.dataKoniec,
        czasTrwaniaSekund: session.czasTrwaniaSekund,
        notatka: session.notatka,
        guidance: checked,
      ),
    );
  }

  Future<void> guidanceEvent({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required bool Function() guard,
    required int slot,
    String? replacement,
  }) => _db.transaction(() async {
    await _requireAccount(accountId, guard);
    final session = await _db.workoutDao.getSession(sessionId);
    _requireGuard(guard);
    if (session == null ||
        session.syncId != sessionSyncId ||
        session.dataKoniec != null ||
        session.deletedAtUtc != null) {
      throw WorkoutSessionUnavailable(sessionId);
    }
    final g = WorkoutGuidance.tryRead(session.guidanceJson);
    if (g == null) throw const FormatException('Prowadzenie niedostępne');
    await _writeGuidance(
      session,
      replacement == null ? g.skip(slot) : g.replace(slot, replacement),
    );
    await _requireAccount(accountId, guard);
  });

  Future<Map<String, Object?>> saveDraft({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required Map<String, Object?> payload,
    required bool Function() guard,
  }) => _db.transaction(() async {
    await _requireAccount(accountId, guard);
    final session = await _db.workoutDao.getSession(sessionId);
    _requireGuard(guard);
    if (session == null ||
        session.syncId != sessionSyncId ||
        session.deletedAtUtc != null ||
        session.dataKoniec != null) {
      throw WorkoutSessionUnavailable(sessionId);
    }
    final current = await readDraft(accountId, sessionSyncId);
    _requireGuard(guard);
    if (draftRevision(payload) != draftRevision(current)) {
      throw WorkoutDraftConflict(revisionOnly: true);
    }
    final guidance = WorkoutGuidance.tryRead(session.guidanceJson);
    final signature = guidance == null ? null : jsonEncode(guidance.toJson());
    if (payload['guidanceSignature'] != signature) {
      throw WorkoutSessionUnavailable(sessionId);
    }
    // Revision check and row mutation share SQLite's transaction. An old full
    // writer delayed outside this transaction cannot restore consumed work.
    final versions = checkpointVersions(current);
    final epochs = checkpointEpochs(current);
    final checked = validateWorkoutDraft(payload);
    for (final key in changedCheckpointKeys(sessionSyncId, current, checked)) {
      if ((checkpointEpochs(checked)[key] ?? 0) != (epochs[key] ?? 0) ||
          (checkpointVersions(checked)[key] ?? 0) != (versions[key] ?? 0)) {
        throw WorkoutDraftConflict();
      }
      versions[key] = (versions[key] ?? 0) + 1;
    }
    final next = validateWorkoutDraft({
      ...payload,
      'draftRevision': draftRevision(current) + 1,
      'checkpointEpochs': checkpointEpochs(current),
      'checkpointVersions': versions,
    });
    final raw = jsonEncode(next);
    await _db
        .into(_db.workoutDrafts)
        .insertOnConflictUpdate(
          WorkoutDraftsCompanion.insert(
            accountId: accountId,
            sessionSyncId: sessionSyncId,
            payloadJson: raw,
          ),
        );
    await _requireAccount(accountId, guard);
    return next;
  });

  Future<Map<String, Object?>?> readDraft(
    String accountId,
    String sessionSyncId,
  ) async {
    final row =
        await (_db.select(_db.workoutDrafts)..where(
              (d) =>
                  d.accountId.equals(accountId) &
                  d.sessionSyncId.equals(sessionSyncId),
            ))
            .getSingleOrNull();
    return row == null
        ? null
        : validateWorkoutDraft(jsonDecode(row.payloadJson));
  }

  /// Called inside the batch transaction. It clears just this checkpoint in the
  /// LATEST row and advances a durable, per-checkpoint consume-once epoch.
  Future<Map<String, Object?>> consumeDraftCheckpoint({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required String key,
    required int expectedEpoch,
    required int expectedVersion,
    required bool extra,
    required String exerciseId,
    required Map<String, Object?> fallbackPayload,
    required bool Function() guard,
  }) => _db.transaction(() async {
    await _requireAccount(accountId, guard);
    final session = await _db.workoutDao.getSession(sessionId);
    _requireGuard(guard);
    if (session == null ||
        session.syncId != sessionSyncId ||
        session.dataKoniec != null ||
        session.deletedAtUtc != null) {
      throw WorkoutSessionUnavailable(sessionId);
    }
    final current = await readDraft(accountId, sessionSyncId);
    _requireGuard(guard);
    final epochs = checkpointEpochs(current);
    if ((epochs[key] ?? 0) != expectedEpoch) throw WorkoutDraftConflict();
    final versions = checkpointVersions(current);
    if ((versions[key] ?? 0) != expectedVersion) throw WorkoutDraftConflict();
    final next = Map<String, Object?>.from(
      jsonDecode(jsonEncode(current ?? fallbackPayload)) as Map,
    );
    final fields = Map<String, Object?>.from(next['fields'] as Map);
    if (extra) {
      final forms = Map<String, Object?>.from(
        fields['extraForms'] as Map? ?? {},
      );
      final fallbackForms =
          (fallbackPayload['fields'] as Map)['extraForms'] as Map? ?? {};
      final form = Map<String, Object?>.from(
        (forms[key] ?? fallbackForms[key] ?? {}) as Map,
      );
      form.addAll({'timer': null, 'timerBinding': null});
      forms[key] = form;
      fields['extraForms'] = forms;
      next['selectedIds'] = {
        ...(next['selectedIds'] as List).cast<String>(),
        exerciseId,
      }.toList();
    } else {
      fields.addAll({'timer': null, 'timerBinding': null});
    }
    epochs[key] = expectedEpoch + 1;
    versions[key] = expectedVersion + 1;
    next.addAll({
      'fields': fields,
      'draftRevision': draftRevision(current) + 1,
      'checkpointEpochs': epochs,
      'checkpointVersions': versions,
      'guidanceSignature': session.guidanceJson == null
          ? null
          : jsonEncode(
              WorkoutGuidance.validateJson(
                jsonDecode(session.guidanceJson!),
              ).toJson(),
            ),
    });
    await _db
        .into(_db.workoutDrafts)
        .insertOnConflictUpdate(
          WorkoutDraftsCompanion.insert(
            accountId: accountId,
            sessionSyncId: sessionSyncId,
            payloadJson: jsonEncode(validateWorkoutDraft(next)),
          ),
        );
    await _requireAccount(accountId, guard);
    return next;
  });

  Future<List<WorkoutDraftData>> pendingDrafts(String accountId) async {
    final binding = await _db.syncDao.readState();
    if (binding?.accountId != accountId || binding?.offlineAccess != true) {
      return [];
    }
    final drafts = await (_db.select(
      _db.workoutDrafts,
    )..where((d) => d.accountId.equals(accountId))).get();
    final result = <WorkoutDraftData>[];
    for (final draft in drafts) {
      final session = await _sessionBySyncId(draft.sessionSyncId);
      if (session != null &&
          session.deletedAtUtc == null &&
          session.dataKoniec == null) {
        result.add(draft);
      }
    }
    return result;
  }

  /// Zwraca opis ostatniej wykonanej serii dla danego ćwiczenia
  /// w formacie do wyświetlenia jako "auto-progress": "Ostatnio: 15 kg × 8 (RPE 8)"
  Future<SetLogData?> getLastSet(
    String exerciseId, {
    String? side,
    String? variantId,
  }) {
    return _db.workoutDao.getLastSetForExercise(
      exerciseId,
      side: side,
      variantId: variantId,
    );
  }

  /// Read only. Keep every set in each ended session so the engine can use the
  /// weakest result/highest RPE rather than selecting two easy sets.
  Future<List<ProgressionPerformance>> getProgressionHistory(
    String exerciseId, {
    required String? side,
    String? variantId,
    required int excludingSessionId,
  }) async {
    final sets = _db.setsLog;
    final sessions = _db.workoutSessions;
    final query =
        _db.select(sets).join([
          innerJoin(sessions, sessions.id.equalsExp(sets.sesjaId)),
        ])..where(
          sets.cwiczenieId.equals(exerciseId) &
              (side == null ? sets.side.isNull() : sets.side.equals(side)) &
              (variantId == null
                  ? sets.variantId.isNull()
                  : sets.variantId.equals(variantId)) &
              sets.deletedAtUtc.isNull() &
              sessions.deletedAtUtc.isNull() &
              sessions.dataKoniec.isNotNull() &
              sessions.id.equals(excludingSessionId).not(),
        );
    return (await query.get()).map((row) {
      final set = row.readTable(sets);
      final session = row.readTable(sessions);
      return ProgressionPerformance(
        sessionId: session.id,
        endedAt: session.dataKoniec!,
        exerciseId: set.cwiczenieId,
        side: set.side,
        variantId: set.variantId,
        weightKg: set.ciezarKg,
        reps: set.powtorzenia,
        rpe: set.rpe,
      );
    }).toList();
  }

  Stream<List<WorkoutSessionData>> watchAllSessions() {
    return _db.workoutDao.watchAllSessions();
  }

  Stream<WorkoutSessionData?> watchSession(int id) =>
      _db.workoutDao.watchSession(id);

  Future<List<WorkoutSessionData>> getAllSessionsSorted() {
    return _db.workoutDao.getAllSessionsSorted();
  }

  Future<List<SetLogData>> getSetsForSession(int sessionId) {
    return _db.workoutDao.getSetsForSession(sessionId);
  }

  Future<List<SetLogData>> getAllSetsForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
  }) {
    return _db.workoutDao.getAllSetsForExercise(
      exerciseId,
      side: side,
      variantId: variantId,
    );
  }

  /// Includes soft-deleted rows so callers can safely recognize an old action.
  Future<WorkoutSessionData?> findSessionBySyncId(String syncId) =>
      _sessionBySyncId(syncId);

  /// Includes soft-deleted rows so retries cannot resurrect or duplicate a set.
  Future<SetLogData?> findSetBySyncId(String syncId) => _setBySyncId(syncId);

  Future<WorkoutSession> buildSessionModel(WorkoutSessionData session) async {
    final sets = await getSetsForSession(session.id);
    return WorkoutSession(
      id: session.id,
      dataStart: session.dataStart,
      dataKoniec: session.dataKoniec,
      czasTrwaniaSekund: session.czasTrwaniaSekund,
      notatka: session.notatka,
      serie: sets
          .map(
            (s) => SetLog(
              id: s.id,
              sesjaId: s.sesjaId,
              cwiczenieId: s.cwiczenieId,
              nazwaCwiczeniaPl: s.nazwaCwiczeniaPl,
              numerSerii: s.numerSerii,
              ciezarKg: s.ciezarKg,
              powtorzenia: s.powtorzenia,
              czasSekund: s.czasSekund,
              side: s.side,
              variantId: s.variantId,
              variantLabel: s.variantLabel,
              rpe: s.rpe,
              timestamp: s.timestamp,
            ),
          )
          .toList(),
    );
  }

  static void validateSet({
    int? reps,
    int? seconds,
    double? weightKg,
    String? side,
  }) {
    if ((reps == null && seconds == null) ||
        (reps != null && reps <= 0) ||
        (seconds != null && seconds <= 0) ||
        (weightKg != null && (!weightKg.isFinite || weightKg < 0)) ||
        (side != null && !const {'left', 'right', 'both'}.contains(side))) {
      throw ArgumentError(
        'Seria wymaga dodatnich powtórzeń lub czasu i poprawnej strony.',
      );
    }
  }
}
