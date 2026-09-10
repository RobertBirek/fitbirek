import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../database/app_database.dart';
import 'sync_models.dart';
import 'sync_store.dart';

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
        (await client.get('/api/sync/pull?cursor=$cursor')).data as Map,
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
          final pending = await db.syncDao.pendingOperations();
          final keys = <String>{};
          final next = pending
              .where((o) => keys.add('${o.entityType.name}:${o.entityId}'))
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
              continue;
            }
            final op = operations.firstWhere(
              (o) => o.operationId == conflict['operationId'],
            );
            await (db.delete(
              db.syncOutbox,
            )..where((o) => o.operationId.equals(op.operationId))).go();
            final record = Map<String, dynamic>.from(conflict['record'] as Map);
            final later = (await db.syncDao.pendingOperations()).any(
              (o) => o.entityType == op.entityType && o.entityId == op.entityId,
            );
            final deletedSession =
                op.entityType == SyncEntityType.workoutSession &&
                record['deletedAt'] != null &&
                !op.deleted;
            if (op.preserveLocal && !later && !deletedSession) {
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
        if (blocked) break;
        if ((response['accepted'] as List).isEmpty &&
            (response['conflicts'] as List).isEmpty) {
          throw const FormatException('Missing push outcomes');
        }
      }
      while (_enabled) {
        final state = await db.syncDao.readState();
        if (state == null) throw StateError('Missing account binding');
        final page = await api.pull(state.cursor);
        if (generation != _generation) return;
        final cursor = page['cursor'] as int;
        final changes = page['changes'] as List;
        if (cursor < state.cursor ||
            (changes.isNotEmpty && cursor <= state.cursor)) {
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
              .write(SyncStateCompanion(cursor: Value(cursor)));
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
