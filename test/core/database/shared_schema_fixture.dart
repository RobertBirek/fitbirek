import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:fitbirek_training/core/database/app_database.dart';

class OldSchemaClient extends AppDatabase {
  OldSchemaClient(super.e) : super.forTesting();

  int opens = 0;
  @override
  int get schemaVersion => 12;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Fixture only: previous compiled release's actual schema.
      await customStatement(
        'ALTER TABLE user_profiles DROP COLUMN weekly_schedule_json',
      );
    },
    beforeOpen: (_) async {
      opens++;
    },
  );
}

class CountingSchemaClient extends AppDatabase {
  CountingSchemaClient(super.e) : super.forTesting();
  int upgrades = 0;
  @override
  MigrationStrategy get migration {
    final strategy = super.migration;
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        upgrades++;
        await strategy.onUpgrade(m, from, to);
      },
    );
  }
}

Future<DatabaseConnection> connectSchemaClient(DriftServer server) {
  final channel = StreamChannelController<Object?>();
  server.serve(channel.foreign);
  return connectToRemoteAndInitialize(channel.local);
}
