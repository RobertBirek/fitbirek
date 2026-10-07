import 'package:drift/drift.dart';
import 'sync_metadata.dart';

/// Server-owned imports. Client mutations are tombstones only.
@DataClassName('HealthSampleData')
class HealthSamples extends Table with SyncMetadata {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get day => text()();
  DateTimeColumn get measuredAt => dateTime().nullable()();
  RealColumn get value => real()();
  TextColumn get source => text()();
  TextColumn get method => text()();
  DateTimeColumn get importedAt => dateTime()();
}
