import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'sync_metadata.dart';

/// Account binding and pull cursor for the single synchronized account.
@DataClassName('SyncStateData')
class SyncState extends Table {
  IntColumn get id =>
      integer().customConstraint('NOT NULL DEFAULT 1 CHECK (id = 1)')();
  TextColumn get accountId => text()();
  TextColumn get deviceId => text()();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  BoolColumn get offlineAccess => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mutations waiting to be sent to the sync API.
@DataClassName('SyncOutboxData')
class SyncOutbox extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get baseVersion => integer()();
  TextColumn get payloadJson => text()();
  BoolColumn get attempted => boolean().withDefault(const Constant(false))();
  BoolColumn get preserveLocal =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAtUtc =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// Latest server state observed while a local mutation is still unresolved.
/// Stored atomically with the pull cursor and retained across process restarts.
@DataClassName('SyncDeferredRecordData')
class SyncDeferredRecords extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get version => integer()();
  TextColumn get recordJson => text()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

/// Favorite flags are user data, separate from immutable seeded exercises.
@DataClassName('ExerciseFavoriteData')
class ExerciseFavorites extends Table with SyncMetadata {
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}
