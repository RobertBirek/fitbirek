import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/workout_guidance.dart';

class RecoverableSession {
  const RecoverableSession(this.id, this.syncId, this.started, this.problem);
  final int id;
  final String syncId;
  final DateTime started;
  final String? problem;
}

class SessionRecovery {
  const SessionRecovery(this.accountId, this.epoch, this.sessions);
  final String? accountId;
  final int epoch;
  final List<RecoverableSession> sessions;
}

final _authorityRevision = Provider.autoDispose<int>((ref) {
  final authority = ref.watch(cachedAuthWriteAuthorityProvider);
  void changed() => ref.invalidateSelf();
  authority.revision.addListener(changed);
  ref.onDispose(() => authority.revision.removeListener(changed));
  return authority.epoch;
});

/// A single reactive, read-only snapshot: no auth bootstrap, HTTP, draft repair
/// or session selection. Works through native SQLite and Drift's web transport.
final sessionRecoveryProvider = StreamProvider.autoDispose<SessionRecovery>((
  ref,
) {
  final epoch = ref.watch(_authorityRevision);
  final authority = ref.watch(cachedAuthWriteAuthorityProvider);
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        'SELECT s.*, a.account_id, d.payload_json FROM workout_sessions s '
        'JOIN sync_state a ON a.offline_access = 1 '
        'LEFT JOIN workout_drafts d ON d.session_sync_id = s.sync_id AND d.account_id = a.account_id '
        'WHERE s.data_koniec IS NULL AND s.deleted_at_utc IS NULL '
        'AND NOT EXISTS (SELECT 1 FROM workout_drafts foreign_d '
        'WHERE foreign_d.session_sync_id = s.sync_id AND foreign_d.account_id <> a.account_id) '
        'ORDER BY s.data_start DESC, s.sync_id',
        readsFrom: {db.workoutSessions, db.workoutDrafts, db.syncState},
      )
      .watch()
      .map((rows) {
        if (authority.epoch != epoch ||
            (authority.state != null && !authority.state!.isSignedIn)) {
          return SessionRecovery(null, epoch, const []);
        }
        final account = rows.isEmpty
            ? null
            : rows.first.read<String>('account_id');
        if (authority.state != null && authority.state!.accountId != account) {
          return SessionRecovery(null, epoch, const []);
        }
        return SessionRecovery(
          account,
          epoch,
          List.unmodifiable(
            rows.map((r) {
              final raw = r.readNullable<String>('guidance_json');
              final payload = r.readNullable<String>('payload_json');
              String? problem;
              if (payload == null) {
                problem =
                    'Brak lokalnego szkicu tej sesji. Nie odtworzono formularza ani timera.';
              } else {
                try {
                  final draft = validateWorkoutDraft(jsonDecode(payload));
                  final guidance = WorkoutGuidance.tryRead(raw);
                  if ((raw != null && guidance == null) ||
                      draft['guidanceSignature'] !=
                          (guidance == null
                              ? null
                              : jsonEncode(guidance.toJson())) ||
                      (guidance != null &&
                          (draft['currentSlot'] as int) >=
                              guidance.plan.blocks.length)) {
                    problem =
                        'Szkic nie odpowiada zapisanej sesji. Nie zmieniono danych.';
                  }
                } on FormatException {
                  problem = 'Nie można odczytać szkicu. Nie zmieniono danych.';
                } on TypeError {
                  problem = 'Nie można odczytać szkicu. Nie zmieniono danych.';
                }
              }
              return RecoverableSession(
                r.read<int>('id'),
                r.read<String>('sync_id'),
                r.read<DateTime>('data_start'),
                problem,
              );
            }),
          ),
        );
      });
});
