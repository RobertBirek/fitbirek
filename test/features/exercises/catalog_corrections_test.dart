import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final raw =
      (jsonDecode(File('assets/data/exercises.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>()
          .take(412)
          .toList();
  const ids = ['cw009', 'cw123', 'cw135', 'cw136', 'cw165', 'cw267'];
  Map<String, Object?> correction(String id) => {
    'exerciseId': id,
    'revision': 1,
    'fields': {
      'nazwaPl': 'Poprawione $id',
      'sprzet': ['Wrist roller'],
      'kluczoweWskazowki': ['Pełny cykl'],
      'czesteBledy': ['Zły chwyt'],
      'progresja': 'Powtórzenia',
      'regresja': 'Mniej powtórzeń',
    },
  };
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());
  ExercisesRepository repo(List<dynamic> catalog, List<Object?> corrections) =>
      ExercisesRepository(
        db,
        loadAsset: (path) async => jsonEncode(
          path.endsWith('exercise_catalog_corrections.json')
              ? {'schemaVersion': 1, 'corrections': corrections}
              : catalog,
        ),
      );

  test(
    'upgrade 412 keeps local data, favorites, history and pending; patches six rows atomically',
    () async {
      await repo(raw, []).syncFromAssets();
      await (db.update(db.exercises)..where((t) => t.id.equals('cw123'))).write(
        const ExercisesCompanion(
          tempo: Value('local tempo'),
          nazwaEn: Value('local English'),
        ),
      );
      await repo(raw, []).toggleFavorite('cw123', true);
      final session = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              dataStart: DateTime.utc(2026),
              dataKoniec: Value(DateTime.utc(2026, 1, 2)),
            ),
          );
      await db
          .into(db.setsLog)
          .insert(
            SetsLogCompanion.insert(
              sesjaId: session,
              cwiczenieId: 'cw123',
              nazwaCwiczeniaPl: 'Historyczny roller',
              numerSerii: 1,
            ),
          );
      final favorites = await db.select(db.exerciseFavorites).get();
      final pending = await db.select(db.syncOutbox).get();
      final history = await db.select(db.setsLog).get();
      final before = {for (final e in await db.exercisesDao.getAll()) e.id: e};
      final expanded = [
        ...raw,
        for (var n = 413; n <= 424; n++) {...raw.first, 'id': 'cw$n'},
      ];
      final importer = repo(expanded, ids.map(correction).toList());
      await importer.syncFromAssets();
      expect(await db.exercisesDao.getAll(), hasLength(424));
      for (final id in ids) {
        final row = (await db.exercisesDao.getByIdWithFavorite(id))!.$1;
        expect(
          row,
          before[id]!.copyWith(
            nazwaPl: 'Poprawione $id',
            sprzet: '["Wrist roller"]',
            kluczoweWskazowki: '["Pełny cykl"]',
            czesteBledy: '["Zły chwyt"]',
            progresja: 'Powtórzenia',
            regresja: 'Mniej powtórzeń',
          ),
        );
      }
      for (final row in await db.exercisesDao.getAll()) {
        if (!ids.contains(row.id) && before.containsKey(row.id)) {
          expect(row, before[row.id]);
        }
      }
      final once = await db.exercisesDao.getAll();
      final changesBefore =
          (await db.customSelect('SELECT total_changes() AS count').getSingle())
              .read<int>('count');
      await importer.syncFromAssets();
      final changesAfter =
          (await db.customSelect('SELECT total_changes() AS count').getSingle())
              .read<int>('count');
      expect(
        changesAfter,
        changesBefore,
        reason:
            'Repeated effective catalog import must not write unchanged rows, including corrected names and equipment.',
      );
      expect(await db.exercisesDao.getAll(), once);
      expect(await db.select(db.exerciseFavorites).get(), favorites);
      expect(await db.select(db.syncOutbox).get(), pending);
      expect(await db.select(db.setsLog).get(), history);
    },
  );

  for (final bad in <Object?>[
    {...correction('cw123'), 'revision': 0},
    {...correction('cw123'), 'revision': 2},
    {...correction('cw123'), 'revision': 1.0},
    {...correction('cw123'), 'unknown': true},
    {
      ...correction('cw123'),
      'fields': {
        'sprzet': [1],
      },
    },
    {
      ...correction('cw123'),
      'fields': {
        'sprzet': [' '],
      },
    },
    {
      ...correction('cw123'),
      'fields': {'tempo': 'bad'},
    },
    {
      ...correction('cw123'),
      'fields': {'sprzet': 'not a list'},
    },
    {
      ...correction('cw123'),
      'fields': {'sprzet': []},
    },
    {
      ...correction('cw123'),
      'fields': {'nazwaPl': ''},
    },
    correction('cw001'),
    null,
  ]) {
    test(
      'rejects malformed correction $bad before any inserts or updates',
      () async {
        await repo(raw, []).syncFromAssets();
        final before = await db.exercisesDao.getAll();
        await expectLater(
          repo(
            [
              ...raw,
              {...raw.first, 'id': 'cw413'},
            ],
            [correction('cw009'), bad],
          ).syncFromAssets(),
          throwsFormatException,
        );
        expect(await db.exercisesDao.getAll(), before);
      },
    );
  }
  test('duplicate correction rejected without partial writes', () async {
    await expectLater(
      repo(raw, [correction('cw123'), correction('cw123')]).syncFromAssets(),
      throwsFormatException,
    );
    expect(await db.exercisesDao.getAll(), isEmpty);
  });
  for (final manifest in <Object?>[
    null,
    [],
    {'schemaVersion': 2, 'corrections': []},
    {'schemaVersion': 1.0, 'corrections': []},
    {'schemaVersion': 1, 'corrections': {}},
    {'schemaVersion': 1, 'corrections': [], 'unknown': true},
  ]) {
    test('invalid manifest root $manifest leaves no partial catalog', () async {
      final importer = ExercisesRepository(
        db,
        loadAsset: (path) async => jsonEncode(
          path.endsWith('exercise_catalog_corrections.json') ? manifest : raw,
        ),
      );
      await expectLater(importer.syncFromAssets(), throwsFormatException);
      expect(await db.exercisesDao.getAll(), isEmpty);
    });
  }
}
