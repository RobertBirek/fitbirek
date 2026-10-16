import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/features/exercises/data/filter_presets_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/filter_preset.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'unrelated': 'keep'}));
  const filters = ExerciseFilters(
    styles: {'tai'},
    muscles: {'back'},
    conditions: {'quiet', 'future_condition'},
    positions: {'standing', 'future_position'},
    sprzet: {'Krzesło'},
    typy: {'Siłowy'},
    partie: {'Plecy'},
    poziomy: {'Start'},
    tylkoUlubione: true,
    query: 'dłonie',
    sortBy: ExerciseSortBy.poziom,
  );
  FilterPresetsRepository repo() => FilterPresetsRepository();
  test(
    'restart round trips every criterion, scoped accounts and delete',
    () async {
      final saved = await repo().save('opaque-A', '  Dom  ', filters);
      final restored = (await repo().load('opaque-A')).single;
      expect(restored.id, saved.id);
      expect(restored.name, 'Dom');
      expect(FilterPreset.encodeFilters(restored.filters), {
        'styles': ['tai'],
        'muscles': ['back'],
        'conditions': ['quiet', 'future_condition'],
        'positions': ['standing', 'future_position'],
        'sprzet': ['Krzesło'],
        'typy': ['Siłowy'],
        'partie': ['Plecy'],
        'poziomy': ['Start'],
        'tylkoUlubione': true,
        'query': 'dłonie',
        'sortBy': 'poziom',
      });
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(
        FilterPresetsRepository.storageKey('opaque-A'),
      )!;
      expect((jsonDecode(raw) as Map)['version'], 1);
      expect(raw, isNot(contains('exerciseIds')));
      // Recreate the plugin cache from durable values, not only the repository.
      SharedPreferences.setMockInitialValues({
        FilterPresetsRepository.storageKey('opaque-A'): raw,
        'unrelated': 'keep',
      });
      expect((await repo().load('opaque-A')).single.filters.query, 'dłonie');
      expect(await repo().load('opaque-B'), isEmpty);
      await repo().delete('opaque-A', saved.id);
      expect(await repo().load('opaque-A'), isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString('unrelated'),
        'keep',
      );
    },
  );
  test(
    'invalid names and case insensitive duplicates need explicit overwrite',
    () async {
      for (final name in ['', '   ', 'x' * 81]) {
        await expectLater(repo().save('a', name, filters), throwsArgumentError);
      }
      final r = repo();
      final first = await r.save('a', 'Dom', filters);
      await expectLater(
        r.save('a', ' DOM ', filters),
        throwsA(isA<DuplicatePresetName>()),
      );
      final replacement = await r.save(
        'a',
        'dom',
        const ExerciseFilters(),
        overwriteId: first.id,
      );
      expect(replacement.id, first.id);
      expect(await r.load('a'), hasLength(1));
      expect((await r.load('a')).single.filters.query, '');
      await expectLater(r.save('', 'Valid', filters), throwsStateError);
    },
  );
  test(
    'corrupt envelopes, invalid entries, unknown keys and enum are tolerated',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final key = FilterPresetsRepository.storageKey('a');
      for (final raw in ['{', '[]', '{"version":999,"presets":[]}']) {
        await prefs.setString(key, raw);
        expect(await repo().load('a'), isEmpty);
      }
      await prefs.setString(
        key,
        jsonEncode({
          'version': 1,
          'future': true,
          'presets': [
            {'id': 'bad', 'name': ' '},
            {
              'id': 'ok',
              'name': 'Good',
              'filters': {
                'styles': ['future-style'],
                'sortBy': 'future',
                'future': 7,
              },
            },
            {
              'id': 'invalid',
              'name': 'Invalid',
              'filters': {'muscles': 42},
            },
          ],
        }),
      );
      final good = (await repo().load('a')).single;
      expect(good.filters.styles, {'future-style'});
      expect(good.filters.conditions, isEmpty);
      expect(good.filters.positions, isEmpty);
      expect(good.filters.sortBy, ExerciseSortBy.alfabetycznie);
    },
  );
  test(
    'pending acquisition after account switch cannot write or delete',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final delayed = Completer<SharedPreferences>();
      var active = true;
      final r = FilterPresetsRepository(preferences: () => delayed.future);
      final pending = r.save('a', 'Late', filters, isCurrent: () => active);
      active = false;
      delayed.complete(prefs);
      await expectLater(pending, throwsStateError);
      expect(await repo().load('a'), isEmpty);
      final item = await repo().save('a', 'Keep', filters);
      await expectLater(
        repo().delete('a', item.id, isCurrent: () => false),
        throwsStateError,
      );
      expect(await repo().load('a'), hasLength(1));
      expect(await repo().load('b'), isEmpty);
    },
  );
  test('concurrent operations on one repository do not lose updates', () async {
    final r = repo();
    await Future.wait([
      r.save('a', 'One', filters),
      r.save('a', 'Two', filters),
    ]);
    expect(await r.load('a'), hasLength(2));
  });
  test('a delete already waiting for storage is cancelled on logout', () async {
    final r = repo();
    final saved = await r.save('a', 'Keep', filters);
    final prefs = await SharedPreferences.getInstance();
    final gate = Completer<SharedPreferences>();
    var active = true;
    final delayed = FilterPresetsRepository(preferences: () => gate.future);
    final deleting = delayed.delete('a', saved.id, isCurrent: () => active);
    await Future<void>.delayed(Duration.zero);
    active = false;
    gate.complete(prefs);
    await expectLater(deleting, throwsStateError);
    expect(await r.load('a'), hasLength(1));
  });
}
