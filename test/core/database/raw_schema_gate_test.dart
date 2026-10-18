import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/database/schema_gate.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'shared_schema_fixture.dart';

final _rawOperations = <String, FutureOr<Object?> Function(QueryExecutor)>{
  'select': (e) => e.runSelect('SELECT 1', []),
  'custom': (e) => e.runCustom('PRAGMA user_version = 13'),
  'insert': (e) => e.runInsert(
    "INSERT INTO sync_state (account_id, device_id) VALUES ('wrong', 'device')",
    [],
  ),
  'update': (e) =>
      e.runUpdate("UPDATE sync_state SET account_id = 'wrong'", []),
  'delete': (e) => e.runDelete('DELETE FROM sync_outbox', []),
  'batch': (e) => e.runBatched(
    BatchedStatements(
      ['PRAGMA user_version = 13'],
      [ArgumentsForBatchedStatement(0, [])],
    ),
  ),
  'transaction': (e) async {
    final transaction = e.beginTransaction();
    try {
      await transaction.ensureOpen(const _NestedUser());
      await transaction.runCustom('PRAGMA user_version = 13');
    } finally {
      await transaction.rollback();
    }
    return null;
  },
  'exclusive': (e) async {
    final exclusive = e.beginExclusive();
    try {
      await exclusive.ensureOpen(const _NestedUser());
      await exclusive.runCustom('PRAGMA user_version = 13');
    } finally {
      await exclusive.close();
    }
    return null;
  },
};

class _Version14Client extends AppDatabase {
  _Version14Client(super.e) : super.forTesting();
  @override
  int get schemaVersion => 14;
}

class _NestedUser implements QueryExecutorUser {
  const _NestedUser();
  @override
  int get schemaVersion => 13;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    throw StateError('Nested executor must not invoke database migrations');
  }
}

void main() {
  for (final version in [12, 14]) {
    for (final operation in _rawOperations.entries) {
      test(
        'RPC$version rejected but not closed: raw ${operation.key} must refuse',
        () async {
          final raw = sqlite.sqlite3.openInMemory();
          final server = DriftServer(
            NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
          );
          final ownerConnection = await connectSchemaClient(server);
          final owner = version == 12
              ? OldSchemaClient(ownerConnection)
              : _Version14Client(ownerConnection);
          await owner.customSelect('SELECT 1').get();
          final db = AppDatabase.forTesting(await connectSchemaClient(server));
          addTearDown(() async {
            await db.close();
            await owner.close();
            await server.shutdown();
            raw.dispose();
          });
          await expectLater(
            db.customSelect('SELECT 1').get(),
            throwsA(isA<DatabaseSchemaMismatch>()),
          );
          // Deliberately keep db open: rejection must be authoritative even before
          // the async bootstrap's close, not just a consequence of disconnecting.
          await expectLater(
            Future.sync(() => operation.value(db.executor)),
            throwsA(isA<DatabaseSchemaMismatch>()),
          );
          expect(raw.userVersion, version);
          expect(raw.select('SELECT * FROM sync_state'), isEmpty);
          expect(raw.select('SELECT * FROM sync_outbox'), isEmpty);
        },
      );
    }
  }

  for (final remote in [false, true]) {
    test(
      'unopened future14 refuses all raw APIs without downgrade, remote=$remote',
      () async {
        final raw = sqlite.sqlite3.openInMemory()..userVersion = 14;
        final native = NativeDatabase.opened(
          raw,
          closeUnderlyingOnClose: false,
        );
        final server = remote ? DriftServer(native) : null;
        final db = AppDatabase.forTesting(
          server == null ? native : await connectSchemaClient(server),
        );
        addTearDown(() async {
          await db.close();
          await server?.shutdown();
          raw.dispose();
        });
        Object? mismatch;
        try {
          await db.customSelect('SELECT 1').get();
        } catch (error) {
          mismatch = error;
        }
        expect(mismatch, isA<DatabaseSchemaMismatch>());
        for (final operation in _rawOperations.entries) {
          await expectLater(
            Future.sync(() => operation.value(db.executor)),
            throwsA(same(mismatch)),
            reason: operation.key,
          );
        }
        expect(raw.userVersion, 14);
        expect(
          raw.select("SELECT name FROM sqlite_master WHERE type = 'table'"),
          isEmpty,
        );
      },
    );
  }

  test(
    'raw APIs cannot race the migration callback through a caller-wide pass',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final raw = sqlite.sqlite3.openInMemory();
      final db = _PausedMigration(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
        entered,
        release,
      );
      addTearDown(() async {
        if (!release.isCompleted) release.complete();
        await db.close();
        raw.dispose();
      });
      final opening = db.customSelect('SELECT 1').get();
      await entered.future;
      for (final operation in _rawOperations.entries) {
        await expectLater(
          Future.sync(() => operation.value(db.executor)),
          throwsStateError,
          reason: operation.key,
        );
      }
      release.complete();
      await opening;
      expect(raw.userVersion, 13);
      expect(raw.select('SELECT * FROM scoped_migration_probe'), isEmpty);
      // Legitimate raw access and transactions still work after successful open.
      final transaction = db.executor.beginTransaction();
      await transaction.ensureOpen(db);
      await transaction.runCustom(
        "INSERT INTO sync_state (account_id, device_id) VALUES ('A', 'device')",
      );
      await transaction.send();
      expect(
        raw.select('SELECT account_id FROM sync_state').single['account_id'],
        'A',
      );
    },
  );
}

class _PausedMigration extends AppDatabase {
  _PausedMigration(super.executor, this.entered, this.release)
    : super.forTesting();
  final Completer<void> entered;
  final Completer<void> release;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      entered.complete();
      await release.future;
      await m.createAll();
      await transaction(
        () =>
            customStatement('CREATE TABLE scoped_migration_probe (value TEXT)'),
      );
    },
  );
}
