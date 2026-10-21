import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/user_collections.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import '../../core/profile_collections_sync_test.dart' as support;

Map<String, dynamic> fixture() =>
    jsonDecode(
          File('tests/fixtures/fitness_protocol_v1.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

class FitnessAuthority extends CachedAuthWriteAuthority {
  int generation = 0;
  @override
  int get epoch => generation;
  @override
  AuthState get state => const AuthState.signedIn('a');
}

class InterruptFitnessInsert extends QueryInterceptor {
  void Function()? interrupt;
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await executor.runInsert(statement, args);
    if (statement.contains('fitness_test_results')) interrupt?.call();
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'fixture exact wire roundtrips; revision semantics exclude only top-level metadata',
    () {
      final json = fixture()['protocol'] as Map<String, dynamic>;
      final p = FitnessProtocol.fromJson(json);
      expect(p.toJson(), json);
      expect(p.metric, FitnessMetric.reps);
      expect(p.metric.unitLabel, 'powt.');
      expect(
        p.hasSameRevisionRules(
          FitnessProtocol.fromJson({
            ...json,
            'updatedAtUtc': '2026-10-22T10:00:00.000Z',
            'deletedAtUtc': '2026-10-22T10:00:00.000Z',
          }),
        ),
        isTrue,
      );
      expect(
        p.hasSameRevisionRules(
          FitnessProtocol.fromJson({...json, 'name': 'Inna nazwa'}),
        ),
        isFalse,
      );
      expect(
        () => FitnessProtocol.fromJson({...json, 'future': true}),
        throwsFormatException,
      );
      expect(
        () => FitnessProtocol.fromJson({...json, 'metric': 'seconds'}),
        throwsFormatException,
      );
      expect(
        () => FitnessProtocol.fromJson({...json, 'loadKg': 0}),
        throwsFormatException,
      );
      expect(
        FitnessProtocol.fromJson({
          ...json,
          'loadKg': 0,
          'loadBasis': 'total',
        }).loadKg,
        0,
      );
    },
  );
  test(
    'same UUID rule collision fails merge rather than choosing arbitrary LWW',
    () {
      final json = fixture()['protocol'] as Map<String, dynamic>;
      final a = {
        'version': 1,
        'entries': [json],
      };
      final b = {
        'version': 1,
        'entries': [
          {
            ...json,
            'instructions': 'Inne zasady',
            'updatedAtUtc': '2026-10-22T10:00:00.000Z',
          },
        ],
      };
      expect(
        () => UserCollections.merge('fitnessProtocols', a, b),
        throwsFormatException,
      );
    },
  );
  test(
    'protocol v1 numeric enum string snapshot and UTF8 limits fail closed',
    () {
      final json = fixture()['protocol'] as Map<String, dynamic>;
      for (final changes in <Map<String, dynamic>>[
        {'loadKg': double.nan, 'loadBasis': 'total'},
        {'loadKg': double.infinity, 'loadBasis': 'total'},
        {'loadKg': -1, 'loadBasis': 'total'},
        {'loadKg': 1001, 'loadBasis': 'total'},
        {'loadBasis': 'total'},
        {'side': 'all'},
        {'direction': 'up'},
        {'timeLimitSeconds': 0},
        {'timeLimitSeconds': 86401},
        {'timeLimitSeconds': 1.0},
        {'name': 'a' * 81},
        {'instructions': 'a' * 4001},
        {'exerciseId': 'a' * 65},
        {'exerciseName': 'a' * 201},
        {'supersedesId': json['id']},
        {'updatedAtUtc': '2025-01-01T00:00:00Z'},
        {'deletedAtUtc': '2027-01-01T00:00:00Z'},
        {
          'variantSnapshot': {
            'id': '33333333-3333-4333-8333-333333333333',
            'name': 'V',
            'exerciseId': 'other',
            'createdAtUtc': json['createdAtUtc'],
            'updatedAtUtc': json['updatedAtUtc'],
          },
        },
      ]) {
        expect(
          () => FitnessProtocol.fromJson({...json, ...changes}),
          throwsFormatException,
          reason: changes.toString(),
        );
      }
      final unicode = FitnessProtocol.fromJson({...json, 'name': '😀' * 80});
      expect(unicode.name.runes.length, 80);
      final p = FitnessProtocol.fromJson(json);
      final copy = p.toJson();
      copy['name'] = 'mutated';
      expect(p.name, json['name']);
      Map<String, dynamic> entry(int i, {String instructions = ''}) {
        final id = '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';
        return {
          ...json,
          'id': id,
          'familyId': id,
          'instructions': instructions,
        };
      }

      expect(
        () => UserCollections.validate('fitnessProtocols', {
          'version': 1,
          'entries': [for (var i = 0; i < 501; i++) entry(i)],
        }),
        throwsFormatException,
      );
      expect(
        () => UserCollections.validate('fitnessProtocols', {
          'version': 1,
          'entries': [
            for (var i = 0; i < 100; i++) entry(i, instructions: 'a' * 4000),
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => UserCollections.validate('fitnessProtocols', {
          'version': 1.0,
          'entries': [],
        }),
        throwsFormatException,
      );
    },
  );
  group('account-bound repository', () {
    late AppDatabase db;
    late TestsRepository repo;
    late CachedAuthWriteAuthority authority;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
          );
      await support.saveProfile(db);
      await db.delete(db.syncOutbox).go();
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'cw001',
              nazwaPl: 'Pompki klasyczne',
              nazwaEn: 'Pushup',
              partiaGlowna: 'Klatka',
              partieWspierajace: '[]',
              sprzet: '[]',
              typ: 'Siłowe',
              poziom: 'Początkujący',
              wzorzecRuchu: '',
              seriexPowtorzenia: '',
              tempo: '',
              kluczoweWskazowki: '',
              czesteBledy: '',
              progresja: '',
              regresja: '',
              zrodlo: '',
            ),
          );
      authority = FitnessAuthority();
      repo = TestsRepository(db, authority: authority);
    });
    tearDown(() => db.close());
    test(
      'create revise archive and historical result produce no workouts or PR',
      () async {
        final p = await repo.createProtocol(
          await repo.captureLease(),
          FitnessProtocolDraft.fromProtocol(
            FitnessProtocol.fromJson(
              fixture()['protocol'] as Map<String, dynamic>,
            ),
          ),
        );
        final date = DateTime.utc(2026, 1, 1, 12, 15);
        final lease = await repo.captureLease(protocolId: p.id);
        await repo.addCustomResult(lease, value: 18, performedAt: date);
        final rows = await db.testsDao.watchAll().first;
        expect(rows.single.data.toUtc(), date);
        expect(rows.single.updatedAtUtc.isAfter(date), isTrue);
        expect(CustomFitnessResult.fromRow(rows.single).protocol!.id, p.id);
        final revised = await repo.reviseProtocol(
          lease,
          FitnessProtocolDraft.fromProtocol(p),
        );
        expect(revised.id, isNot(p.id));
        expect(revised.familyId, p.familyId);
        expect(revised.supersedesId, p.id);
        expect((await repo.watchProtocols().first).active, hasLength(2));
        await repo.archiveProtocol(lease);
        await expectLater(
          repo.addCustomResult(lease, value: 2, performedAt: date),
          throwsStateError,
        );
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        expect(await db.select(db.personalRecords).get(), isEmpty);
      },
    );
    test(
      'future and nonfinite values fail without inserting row/outbox',
      () async {
        final p = await repo.createProtocol(
          await repo.captureLease(),
          FitnessProtocolDraft.fromProtocol(
            FitnessProtocol.fromJson(
              fixture()['protocol'] as Map<String, dynamic>,
            ),
          ),
        );
        await db.delete(db.syncOutbox).go();
        final lease = await repo.captureLease(protocolId: p.id);
        await expectLater(
          repo.addCustomResult(
            lease,
            value: double.nan,
            performedAt: DateTime.utc(2020),
          ),
          throwsArgumentError,
        );
        await expectLater(
          repo.addCustomResult(
            lease,
            value: 1.5,
            performedAt: DateTime.utc(2020),
          ),
          throwsArgumentError,
        );
        await expectLater(
          repo.addCustomResult(
            lease,
            value: 1,
            performedAt: DateTime.now().add(const Duration(days: 1)),
          ),
          throwsArgumentError,
        );
        expect(await db.testsDao.watchAll().first, isEmpty);
        expect(await db.syncDao.pendingOperations(), isEmpty);
      },
    );
    test(
      'backup3 keeps protocol UUID and embedded snapshot; unknown marker fails atomically',
      () async {
        final p = await repo.createProtocol(
          await repo.captureLease(),
          FitnessProtocolDraft.fromProtocol(
            FitnessProtocol.fromJson(
              fixture()['protocol'] as Map<String, dynamic>,
            ),
          ),
        );
        await repo.addCustomResult(
          await repo.captureLease(protocolId: p.id),
          value: 3,
          performedAt: DateTime.utc(2020),
        );
        final bytes = await BackupService(db).exportToBytes();
        final archive = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        expect(archive['schemaVersion'], 3);
        expect(
          (await BackupService(db).importFromBytes(bytes)).success,
          isTrue,
        );
        expect((await repo.watchProtocols().first).protocols.single.id, p.id);
        expect(
          CustomFitnessResult.fromRow(
            (await db.testsDao.watchAll().first).single,
          ).protocol!.id,
          p.id,
        );
        final rowsBefore = (await db.testsDao.watchAll().first)
            .map((r) => r.toJson())
            .toList();
        archive['data']['fitnessTestResults'][0]['customProtocolJson'] = null;
        expect(
          (await BackupService(db).importFromBytes(
            Uint8List.fromList(utf8.encode(jsonEncode(archive))),
          )).success,
          isFalse,
        );
        expect(
          (await db.testsDao.watchAll().first).map((r) => r.toJson()).toList(),
          rowsBefore,
        );
        final other = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(other.close);
        await other
            .into(other.syncState)
            .insert(
              SyncStateCompanion.insert(
                accountId: 'b',
                deviceId: 'other-device',
              ),
            );
        await support.saveProfile(other);
        expect(
          (await BackupService(other).importFromBytes(bytes)).success,
          isTrue,
        );
        final otherRepo = TestsRepository(other);
        final restored =
            (await otherRepo.watchProtocols().first).protocols.single;
        expect(restored.id, p.id);
        expect(restored.familyId, p.familyId);
        expect(
          (await otherRepo.watchCustomResults().first)!.single.protocol!
              .toJson(),
          p.toJson(),
        );
        final extra = await otherRepo.createProtocol(
          await otherRepo.captureLease(),
          FitnessProtocolDraft.fromProtocol(p),
        );
        await otherRepo.archiveProtocol(
          await otherRepo.captureLease(protocolId: extra.id),
        );
        expect(
          (await BackupService(other).importFromBytes(bytes)).success,
          isTrue,
        );
        expect(
          (await otherRepo.watchProtocols().first).archived.single.id,
          extra.id,
        );
      },
    );
    test(
      'epoch A-B-A and offline binding rotation revoke old forms including legacy',
      () async {
        final lease = await repo.captureLease();
        (authority as FitnessAuthority).generation += 2;
        await expectLater(
          repo.addLegacyResult(
            lease,
            typ: TypTestu.sklon,
            value: -5,
            performedAt: DateTime.utc(2020),
          ),
          throwsStateError,
        );
        final fresh = await repo.captureLease();
        await db.syncDao.lockOfflineAccess();
        await db
            .update(db.syncState)
            .write(const SyncStateCompanion(offlineAccess: Value(true)));
        await expectLater(
          repo.addLegacyResult(
            fresh,
            typ: TypTestu.maxPompki,
            value: 5,
            performedAt: DateTime.utc(2020),
          ),
          throwsStateError,
        );
        expect(await db.testsDao.watchAll().first, isEmpty);
        expect(await db.syncDao.pendingOperations(), isEmpty);
        final valid = await repo.captureLease();
        await repo.addLegacyResult(
          valid,
          typ: TypTestu.sklon,
          value: -5,
          performedAt: DateTime.utc(2020),
        );
        expect((await db.testsDao.watchAll().first).single.wynik, -5);
      },
    );
    test(
      'new variants must be exact live entries; unchanged historical snapshot survives variant archive',
      () async {
        final variant = {
          'id': '33333333-3333-4333-8333-333333333333',
          'name': 'Wolno',
          'exerciseId': 'cw001',
          'tempo': '3030',
          'createdAtUtc': '2026-01-01T00:00:00Z',
          'updatedAtUtc': '2026-01-01T00:00:00Z',
        };
        final collections = UserCollectionsRepository(db);
        await collections.update(
          'a',
          'exerciseVariants',
          (entries) => entries.add(variant),
        );
        final draft = FitnessProtocolDraft.fromProtocol(
          FitnessProtocol.fromJson({
            ...fixture()['protocol'] as Map<String, dynamic>,
            'variantSnapshot': variant,
          }),
        );
        final p = await repo.createProtocol(await repo.captureLease(), draft);
        await expectLater(
          collections.update('a', 'fitnessProtocols', (entries) {
            (entries.single['variantSnapshot'] as Map)['cue'] =
                'Zmiana zasad pod tym samym UUID';
          }),
          throwsFormatException,
        );
        await collections.update(
          'a',
          'exerciseVariants',
          (entries) => entries.single.addAll({
            'updatedAtUtc': '2026-02-01T00:00:00Z',
            'deletedAtUtc': '2026-02-01T00:00:00Z',
          }),
        );
        final revised = await repo.reviseProtocol(
          await repo.captureLease(protocolId: p.id),
          FitnessProtocolDraft.fromProtocol(p),
        );
        expect(revised.variantSnapshot, variant);
        await expectLater(
          repo.createProtocol(await repo.captureLease(), draft),
          throwsStateError,
        );
        final list = await repo.watchProtocols().first;
        expect(list.protocols, hasLength(2));
      },
    );
    test(
      'lifecycle revocation during transaction rolls row and outbox back',
      () async {
        final interceptor = InterruptFitnessInsert();
        final database = AppDatabase.forTesting(
          NativeDatabase.memory().interceptWith(interceptor),
        );
        addTearDown(database.close);
        await database
            .into(database.syncState)
            .insert(
              SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
            );
        await support.saveProfile(database);
        await database.delete(database.syncOutbox).go();
        final repository = TestsRepository(database);
        var alive = true;
        final lease = await repository.captureLease(isCurrent: () => alive);
        // Revoke after the actual INSERT await, before the final transaction
        // ownership check. A missing final guard would commit both records.
        interceptor.interrupt = () => alive = false;
        await expectLater(
          repository.addLegacyResult(
            lease,
            typ: TypTestu.maxPompki,
            value: 3,
            performedAt: DateTime.utc(2020),
          ),
          throwsStateError,
        );
        expect(alive, isFalse);
        expect(await database.testsDao.watchAll().first, isEmpty);
        expect(await database.syncDao.pendingOperations(), isEmpty);
      },
    );
  });
  test(
    'comparison isolates exact revision snapshot and sorts actual dates not write dates',
    () {
      final p = FitnessProtocol.fromJson(
        fixture()['protocol'] as Map<String, dynamic>,
      );
      CustomFitnessResult result(
        int id,
        int value,
        DateTime date, {
        String? instructions,
      }) => CustomFitnessResult.fromRow(
        FitnessTestResultData(
          id: id,
          typ: 'customFitnessTestV1',
          data: date,
          wynik: value.toDouble(),
          score: 0,
          syncId: 'result-$id',
          syncVersion: 0,
          updatedAtUtc: DateTime.utc(2026, 10, 21),
          customProtocolJson: jsonEncode({
            ...fixture()['result']['customProtocol'] as Map,
            'snapshot': {
              ...p.toJson(),
              if (instructions != null) 'instructions': instructions,
            },
          }),
        ),
      );
      final old = result(1, 10, DateTime.utc(2020));
      final current = result(2, 12, DateTime.utc(2021));
      final conflict = result(
        3,
        100,
        DateTime.utc(2022),
        instructions: 'Inna zasada',
      );
      final comparison = compareFitnessResults(p, [conflict, old, current]);
      expect(comparison.latest, current);
      expect(comparison.previous, old);
      expect(comparison.delta, 2);
      expect(comparison.improved, isTrue);
    },
  );
}
