import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Fields shared by records that are replicated through the sync API.
mixin SyncMetadata on Table {
  TextColumn get syncId => text().clientDefault(() => Uuid().v4())();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAtUtc =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get deletedAtUtc => dateTime().nullable()();
}
