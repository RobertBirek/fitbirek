import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';

// Pause after a real SELECT has materialized, including inside transactions.
// The independent connection must commit before the next export read proceeds.
class _WriteBetweenReads extends QueryInterceptor {
  final String table;
  Future<void> Function()? write;

  _WriteBetweenReads(this.table);

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await executor.runSelect(statement, args);
    if (statement == 'SELECT * FROM "$table";' && write != null) {
      final action = write!;
      write = null;
      await action();
    }
    return rows;
  }
}

Future<Map<String, dynamic>> _exportData(AppDatabase db) async {
  final payload =
      jsonDecode(utf8.decode(await BackupService(db).exportToBytes()))
          as Map<String, dynamic>;
  return payload['data'] as Map<String, dynamic>;
}

void main() {
  setUp(() {
    final previous = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    // Deliberately independent executors for the WAL reader and writer.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previous;
    });
  });

  for (final boundary in ['workout_sessions', 'exercise_favorites']) {
    test('export keeps one WAL snapshot across $boundary read', () async {
      final directory = await Directory.systemTemp.createTemp(
        'backup-snapshot',
      );
      final file = File('${directory.path}/database.sqlite');
      final interceptor = _WriteBetweenReads(boundary);
      final reader = AppDatabase.forTesting(
        NativeDatabase(
          file,
          setup: (db) {
            db.execute('PRAGMA journal_mode = WAL');
          },
        ).interceptWith(interceptor),
      );
      final writer = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await writer.close();
        await reader.close();
        await directory.delete(recursive: true);
      });
      final sessionId = await reader
          .into(reader.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              dataStart: DateTime.utc(2026, 10, 18),
              syncId: const Value('session-archive-id'),
              guidanceJson: const Value('{"revision":"before"}'),
            ),
          );
      await reader
          .into(reader.setsLog)
          .insert(
            SetsLogCompanion.insert(
              sesjaId: sessionId,
              cwiczenieId: 'cw001',
              nazwaCwiczeniaPl: 'Test',
              numerSerii: 1,
              powtorzenia: const Value(5),
              syncId: const Value('set-archive-id'),
            ),
          );
      await reader
          .into(reader.healthSamples)
          .insert(
            HealthSamplesCompanion.insert(
              kind: 'steps',
              day: '2026-10-18',
              value: 100,
              source: 'test',
              method: 'import',
              importedAt: DateTime.utc(2026, 10, 18),
            ),
          );
      // Open both connections before arming the deterministic interleaving.
      expect(
        (await writer.customSelect('PRAGMA journal_mode').getSingle())
            .read<String>('journal_mode'),
        'wal',
      );
      final before = await _exportData(reader);
      var committed = false;
      interceptor.write = () async {
        await writer.transaction(() async {
          await writer
              .update(writer.workoutSessions)
              .write(
                const WorkoutSessionsCompanion(
                  guidanceJson: Value('{"revision":"after"}'),
                  czasTrwaniaSekund: Value(60),
                ),
              );
          await writer
              .update(writer.setsLog)
              .write(const SetsLogCompanion(powtorzenia: Value(10)));
          await writer
              .update(writer.healthSamples)
              .write(const HealthSamplesCompanion(value: Value(200)));
        });
        committed = true;
      };

      final during = await _exportData(reader);
      expect(
        committed,
        isTrue,
        reason: 'write must commit between source reads',
      );
      final after = await _exportData(writer);
      expect(after, isNot(before));
      expect(
        after['workoutSessions'].single['guidanceJson'],
        '{"revision":"after"}',
      );
      expect(after['setsLog'].single['powtorzenia'], 10);
      expect(after['healthSamples'].single['value'], 200);
      // The earlier SELECT has already pinned the pre-write snapshot.
      expect(during, before, reason: 'no mixed session/set/health revisions');
      expect(
        during['workoutSessions'].single['archiveSessionSyncId'],
        'session-archive-id',
      );
      expect(during['setsLog'].single['archiveSetSyncId'], 'set-archive-id');
    });
  }
}
