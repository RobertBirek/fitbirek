import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../database/app_database.dart';
import 'sync_models.dart';
import 'sync_store.dart';
import 'user_collections.dart';
import 'dart:convert';

abstract class SyncApi {
  Future<Map<String, dynamic>> push(List<SyncOperation> operations);
  Future<Map<String, dynamic>> pull(int cursor);
}

class HttpSyncApi implements SyncApi {
  HttpSyncApi(this.client);
  final ApiClient client;
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> operations) async =>
      Map<String, dynamic>.from(
        (await client.post(
              '/api/sync/push',
              data: {'operations': operations.map((o) => o.toJson()).toList()},
            )).data
            as Map,
      );
  @override
  Future<Map<String, dynamic>> pull(int cursor) async =>
      Map<String, dynamic>.from(
        (await client.get(
              '/api/sync/pull?cursor=$cursor&include_health=true',
            )).data
            as Map,
      );
}

enum SyncStatus { idle, syncing, offline, error, conflict, signedOut }

class SyncService extends ChangeNotifier {
  SyncService(
    this.db,
    this.api, {
    this.onUnauthorized,
    this.currentAccountId,
    this.retryInterval = const Duration(seconds: 15),
  }) : store = SyncStore(db);
  final AppDatabase db;
  final SyncApi api;
  final SyncStore store;
  final Future<void> Function()? onUnauthorized;
  final Future<String?> Function()? currentAccountId;
  final Duration retryInterval;
  SyncStatus status = SyncStatus.idle;
  Future<void>? _running;
  StreamSubscription<dynamic>? _mutations;
  Timer? _retry;
  bool _enabled = false;
  bool _disposed = false;
  int _generation = 0;

  Future<void> bindAccount(String accountId) async {
    await db.transaction(() async {
      final state = await db.syncDao.readState();
      if (state != null && state.accountId != accountId) {
        throw StateError('Local data belongs to another account');
      }
      if (state == null) {
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(
                id: const Value(1),
                accountId: accountId,
                deviceId: Uuid().v4(),
              ),
            );
      }
    });
    _enabled = true;
  }

  /// Watch committed local mutations and probe connectivity periodically. The
  /// timer also catches reconnects where the platform emits no network event.
  void start() {
    _mutations ??= db.select(db.syncOutbox).watch().listen((_) {
      if (_running == null) unawaited(synchronize());
    });
    _retry ??= Timer.periodic(retryInterval, (_) => unawaited(synchronize()));
    unawaited(synchronize());
  }

  Future<void> stop() async {
    _enabled = false;
    _generation++;
    _retry?.cancel();
    _retry = null;
    await _mutations?.cancel();
    _mutations = null;
    await _running;
    _setStatus(SyncStatus.signedOut);
  }

  Future<void> synchronize() {
    if (!_enabled || _disposed) return Future.value();
    return _running ??= _run(_generation).whenComplete(() {
      _running = null;
    });
  }

  /// Administrative/user-confirmed recovery after preserving the local backup
  /// and quarantined raw snapshot. A compatible/corrected remote record must
  /// have been pulled first; ordinary synchronize never releases this hold.
  Future<void> retryProfileCollectionConflict(
    String accountId,
    String profileId,
  ) async {
    if (!_enabled || _disposed || _running != null) {
      throw StateError('Synchronizacja konta jest niedostępna lub trwa.');
    }
    final generation = _generation;
    await db.transaction(() async {
      Future<void> guard() async {
        final state = await db.syncDao.readState();
        if (!_enabled ||
            _disposed ||
            generation != _generation ||
            state?.accountId != accountId ||
            state?.offlineAccess != true) {
          throw StateError('Konto zmieniło się lub jest niedostępne.');
        }
      }

      await guard();
      await store.retryHeldProfile(profileId);
      await guard();
    });
    // Still pending, not "fully synchronized" until the new request is ACKed.
    _setStatus(SyncStatus.conflict);
  }

  void _setStatus(SyncStatus value) {
    status = value;
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(int generation) async {
    _setStatus(SyncStatus.syncing);
    try {
      if (currentAccountId != null) {
        final remoteAccount = await currentAccountId!();
        final bound = await db.syncDao.readState();
        if (generation != _generation) return;
        if (remoteAccount == null || remoteAccount != bound?.accountId) {
          _enabled = false;
          _setStatus(SyncStatus.signedOut);
          await onUnauthorized?.call();
          return;
        }
      }
      var blocked = false;
      // A bounded pass prevents an active writer starving pull indefinitely.
      for (var batch = 0; batch < 100 && _enabled; batch++) {
        final operations = await db.transaction(() async {
          final heldProfiles = await store.heldProfileIds();
          if (heldProfiles.isNotEmpty) blocked = true;
          final pending = await db.syncDao.pendingOperations();
          final keys = <String>{};
          final next = pending
              .where(
                (o) =>
                    !(o.entityType == SyncEntityType.profile &&
                        heldProfiles.contains(o.entityId)) &&
                    keys.add('${o.entityType.name}:${o.entityId}'),
              )
              .toList();
          // Coalescing a finished session can place it after its sets in the
          // outbox. Publish parents first, including across batch boundaries.
          final ops = [
            for (final type in SyncEntityType.values)
              for (final op in next)
                if (op.entityType == type) op,
          ].take(100).toList();
          for (final op in ops) {
            await (db.update(db.syncOutbox)
                  ..where((o) => o.operationId.equals(op.operationId)))
                .write(const SyncOutboxCompanion(attempted: Value(true)));
          }
          return ops;
        });
        if (operations.isEmpty) break;
        final response = await api.push(operations);
        if (generation != _generation) return;
        var unresolvedResponse = false;
        await db.transaction(() async {
          for (final dynamic ack in response['accepted'] as List) {
            final op = operations.firstWhere(
              (o) => o.operationId == ack['operationId'],
            );
            await (db.delete(
              db.syncOutbox,
            )..where((o) => o.operationId.equals(op.operationId))).go();
            await store.version(
              op.entityType,
              op.entityId,
              ack['version'] as int,
            );
            await store.reconcile(
              op.entityType,
              op.entityId,
              acceptedVersion: ack['version'] as int,
              acceptedOperation: op,
            );
          }
          for (final dynamic conflict in response['conflicts'] as List) {
            if (conflict['kind'] != null) {
              blocked = true;
              unresolvedResponse = true;
              continue;
            }
            final op = operations.firstWhere(
              (o) => o.operationId == conflict['operationId'],
            );
            final record = Map<String, dynamic>.from(conflict['record'] as Map);
            if (op.entityType == SyncEntityType.profile &&
                !op.deleted &&
                record['deletedAt'] == null) {
              final remote = Map<String, dynamic>.from(
                record['payload'] as Map,
              );
              try {
                // Validate even when a local NULL/omission or later edit would
                // bypass merge. Never overwrite an unknown remote extension.
                for (final key in UserCollections.keys) {
                  if (remote[key] != null) {
                    UserCollections.validate(key, remote[key]);
                  }
                }
              } on FormatException {
                await store.holdProfileConflict(record, op.operationId);
                blocked = true;
                continue;
              }
            }
            final later = (await db.syncDao.pendingOperations()).any(
              (o) =>
                  o.operationId != op.operationId &&
                  o.entityType == op.entityType &&
                  o.entityId == op.entityId,
            );
            final deletedSession =
                op.entityType == SyncEntityType.workoutSession &&
                record['deletedAt'] != null &&
                !op.deleted;
            if (op.entityType == SyncEntityType.profile &&
                !later &&
                !op.deleted &&
                record['deletedAt'] == null) {
              final local = await store.row(op.entityType, op.entityId);
              final remote = Map<String, dynamic>.from(
                record['payload'] as Map,
              );
              final merged = Map<String, dynamic>.from(remote);
              var changed = false;
              try {
                for (final key in UserCollections.keys) {
                  final raw = local?['${key}Json'] as String?;
                  if (raw == null &&
                      op.payload.containsKey(key) &&
                      op.payload[key] == null) {
                    merged[key] = null;
                    if (remote[key] != null) changed = true;
                    continue;
                  }
                  if (raw == null) continue;
                  final value = UserCollections.merge(
                    key,
                    jsonDecode(raw),
                    remote[key],
                  );
                  merged[key] = value;
                  if (UserCollections.canonical(value) !=
                      UserCollections.canonical(remote[key])) {
                    changed = true;
                  }
                }
              } on FormatException {
                // A quarantined local extension or an over-limit merge must
                // not roll back the whole push response and global pull either.
                await store.holdProfileConflict(record, op.operationId);
                blocked = true;
                continue;
              }
              if (changed || op.preserveLocal) {
                final payload = changed
                    ? merged
                    : <String, dynamic>{
                        ...op.payload,
                        // Explicit backup scalar restore keeps its existing policy,
                        // but must NEVER replay stale collections over merged data.
                        for (final key in UserCollections.keys)
                          if (merged.containsKey(key)) key: merged[key],
                      };
                // The attempted operation was definitively rejected. Apply the
                // server's scalar fields AND merged collections before creating
                // a fresh immutable operation at the authoritative CAS version.
                await (db.delete(
                  db.syncOutbox,
                )..where((o) => o.operationId.equals(op.operationId))).go();
                await store.apply({...record, 'payload': payload});
                await db.syncDao.enqueueUpsert(
                  entityType: op.entityType,
                  entityId: op.entityId,
                  baseVersion: record['version'] as int,
                  payload: payload,
                  // Once server scalars were chosen, this is a normal merged
                  // write, not a renewed request to restore older scalars.
                  preserveLocal: op.preserveLocal && !changed,
                );
                await store.reconcile(op.entityType, op.entityId);
                continue;
              }
            }
            await (db.delete(
              db.syncOutbox,
            )..where((o) => o.operationId.equals(op.operationId))).go();
            final deletedProfile =
                op.entityType == SyncEntityType.profile &&
                record['deletedAt'] != null;
            if (op.preserveLocal &&
                !later &&
                !deletedSession &&
                !deletedProfile) {
              // This request was definitively rejected, so a fresh operation
              // may carry the explicit restore intent at the observed version.
              if (op.deleted) {
                await db.syncDao.enqueueDelete(
                  entityType: op.entityType,
                  entityId: op.entityId,
                  baseVersion: record['version'] as int,
                  payload: op.payload,
                  preserveLocal: true,
                );
              } else {
                await db.syncDao.enqueueUpsert(
                  entityType: op.entityType,
                  entityId: op.entityId,
                  baseVersion: record['version'] as int,
                  payload: op.payload,
                  preserveLocal: true,
                );
              }
            }
            await store.apply(record);
            await store.reconcile(op.entityType, op.entityId);
          }
        });
        if (unresolvedResponse) break;
        if ((response['accepted'] as List).isEmpty &&
            (response['conflicts'] as List).isEmpty) {
          throw const FormatException('Missing push outcomes');
        }
      }
      while (_enabled) {
        final state = await db.syncDao.readState();
        if (state == null) throw StateError('Missing account binding');
        final page = await api.pull(state.fullCursor);
        if (generation != _generation) return;
        final cursor = page['cursor'] as int;
        final changes = page['changes'] as List;
        if (cursor < state.fullCursor ||
            (changes.isNotEmpty && cursor <= state.fullCursor)) {
          throw const FormatException('Invalid cursor');
        }
        await db.transaction(() async {
          // Parents precede children, retaining version order within each type.
          for (final type in SyncEntityType.values) {
            for (final dynamic change in changes.where(
              (dynamic c) => c['entityType'] == type.wireName,
            )) {
              await store.apply(Map<String, dynamic>.from(change as Map));
            }
          }
          for (final dynamic change in changes) {
            syncEntityTypeFromWireName(change['entityType'] as String);
          }
          await db
              .update(db.syncState)
              .write(SyncStateCompanion(fullCursor: Value(cursor)));
        });
        if (changes.length < 500) break;
      }
      _setStatus(blocked ? SyncStatus.conflict : SyncStatus.idle);
    } on DioException catch (e) {
      if (generation != _generation) return;
      if (e.response?.statusCode == 401) {
        _enabled = false;
        _setStatus(SyncStatus.signedOut);
        await onUnauthorized?.call();
      } else {
        _setStatus(e.response == null ? SyncStatus.offline : SyncStatus.error);
      }
    } catch (_) {
      if (generation != _generation) return;
      _setStatus(SyncStatus.error);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _enabled = false;
    _generation++;
    _retry?.cancel();
    unawaited(_mutations?.cancel());
    super.dispose();
  }
}
