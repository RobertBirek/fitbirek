"""Stage 5: explicit execution tags, offline reproducibility and immutable data."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_catalog_metadata
import validate_catalog
import build_execution_conditions as execution

ROOT = Path(__file__).resolve().parents[2]
CONDITIONS = {
    'no_jumps': 'Bez skoków', 'quiet': 'Cichy trening',
    'no_kneeling': 'Bez klęku', 'no_hand_support': 'Bez podporu na dłoniach',
    'no_floor': 'Bez schodzenia na podłogę', 'small_space': 'Mało miejsca',
}
POSITIONS = {
    'standing': 'Stojąco', 'seated': 'Siedząco', 'floor': 'Na podłodze',
    'hanging': 'W zwisie', 'bench': 'Na ławce',
}


class ExecutionConditionsTests(unittest.TestCase):
    def setUp(self):
        self.meta = validate_catalog.load(validate_catalog.METADATA_PATH)
        self.data = validate_catalog.load(ROOT / 'assets/data/exercises.json')

    def test_exact_registries_and_all_363_entries(self):
        for key, expected in [('conditions', CONDITIONS), ('positions', POSITIONS)]:
            self.assertIn(key, self.meta)
            self.assertEqual({x['id']: x['label'] for x in self.meta[key]}, expected)
            for x in self.meta[key]:
                self.assertEqual(set(x), {'id', 'label', 'aliases'})
                self.assertIsInstance(x['aliases'], list)
        self.assertEqual(self.meta['schemaVersion'], 1)
        self.assertEqual(set(self.meta['exercises']), {f'cw{i:03d}' for i in range(1, 364)})
        for eid, entry in self.meta['exercises'].items():
            self.assertIn('conditions', entry, eid)
            self.assertIn('positions', entry, eid)
        validate_catalog.validate_metadata(self.data, self.meta)

    def test_reproducible_and_explicit_input(self):
        source = validate_catalog.load(ROOT / 'tools/source_data/exercise_execution_conditions.json')
        self.assertEqual(set(source['exercises']), set(self.meta['exercises']))
        for eid, row in source['exercises'].items():
            self.assertEqual(set(row), {'conditions', 'positions'})
            for key in row:
                self.assertEqual(row[key], self.meta['exercises'][eid][key], eid)
        self.assertEqual(build_catalog_metadata.build(), self.meta)

    def test_build_repeated_in_same_process_does_not_mutate_curated_styles(self):
        from catalog_additions import ADDITIONS
        before = copy.deepcopy(ADDITIONS)
        first = build_catalog_metadata.build()
        second = build_catalog_metadata.build()
        self.assertEqual(first, second)
        self.assertEqual(ADDITIONS, before)

    def test_all_preexisting_metadata_fields_unchanged(self):
        old = {k: copy.deepcopy(v) for k, v in self.meta.items()
               if k not in ('conditions', 'positions')}
        for entry in old['exercises'].values():
            entry.pop('conditions', None)
            entry.pop('positions', None)
        text = json.dumps(old, ensure_ascii=False, indent=2) + '\n'
        self.assertEqual(hashlib.sha256(text.encode()).hexdigest(),
                         'd3880aa56fcdb20cd9bc9abb2901923ea6f7a59b3d31e1efddcbbc2ba5abd252')

    def test_exercises_workbook_names_and_source_ids_unchanged(self):
        expected = {
            'assets/data/exercises.json': 'cf2a9c46ae5203365c819a8aec020c5e378a253be0a6efc7796ca9991330e071',
            'tools/source_data/baza_cwiczen_316.xlsx': '1605300b264bfffcf322a5aec4e1a525913628bd01c2301458a628a22ed2633c',
            'tools/source_data/catalog_sources.json': 'fa3067ae5c934f65a0361e31afc7296d12c69e530bd2160b94c72d312c68d990',
            'tools/source_data/exercise_names_pl.json': '162ca330232653344ed2879a7b110b33bf18df00a4ba0e7a95cf537538ebd6e0',
        }
        for path, digest in expected.items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)

    def test_hand_support_and_knee_contact_are_not_equipment_grip(self):
        entries = self.meta['exercises']
        for eid in ('cw001', 'cw004', 'cw005', 'cw011', 'cw080', 'cw333', 'cw335', 'cw357'):
            self.assertNotIn('no_hand_support', entries[eid]['conditions'], eid)
        self.assertIn('no_jumps', entries['cw333']['conditions'])
        self.assertNotIn('no_kneeling', entries['cw333']['conditions'])
        self.assertNotIn('no_floor', entries['cw001']['conditions'])
        for eid in ('cw012', 'cw047', 'cw093', 'cw169'):
            self.assertIn('no_hand_support', entries[eid]['conditions'], eid)

    def test_airborne_landings_and_locomotion_conservative(self):
        for eid in ('cw006', 'cw030', 'cw144', 'cw146', 'cw147', 'cw209', 'cw225', 'cw352', 'cw353', 'cw355'):
            self.assertNotIn('no_jumps', self.meta['exercises'][eid]['conditions'], eid)
        for eid in ('cw119', 'cw130', 'cw147', 'cw206', 'cw223', 'cw224', 'cw225', 'cw247', 'cw352', 'cw353', 'cw355'):
            self.assertNotIn('small_space', self.meta['exercises'][eid]['conditions'], eid)
        for eid in ('cw164', 'cw199', 'cw243', 'cw358', 'cw363'):
            self.assertIn('no_jumps', self.meta['exercises'][eid]['conditions'], eid)

    def test_quiet_is_low_impact_not_a_guarantee(self):
        for eid in ('cw006', 'cw209', 'cw212', 'cw225', 'cw234', 'cw235', 'cw241', 'cw352', 'cw353'):
            self.assertNotIn('quiet', self.meta['exercises'][eid]['conditions'], eid)
        for eid in ('cw282', 'cw283', 'cw289', 'cw360', 'cw361', 'cw362', 'cw363'):
            self.assertTrue({'quiet', 'no_floor', 'no_kneeling'} <= set(self.meta['exercises'][eid]['conditions']), eid)

    def test_positions_nonexclusive_and_floor_means_ground(self):
        expected = {
            'cw012': {'bench'}, 'cw065': {'seated', 'bench'},
            'cw169': {'floor'}, 'cw199': {'hanging'},
            'cw209': {'standing', 'floor'}, 'cw282': {'seated'},
            'cw333': {'floor'}, 'cw347': {'seated', 'floor'},
            'cw355': {'standing', 'floor'}, 'cw363': {'seated'},
        }
        for eid, positions in expected.items():
            self.assertEqual(set(self.meta['exercises'][eid]['positions']), positions, eid)
        self.assertIn('no_floor', self.meta['exercises']['cw012']['conditions'])
        self.assertNotIn('no_floor', self.meta['exercises']['cw347']['conditions'])
        for eid, e in self.meta['exercises'].items():
            if 'floor' in e['positions']:
                self.assertNotIn('no_floor', e['conditions'], eid)

    def test_strict_rejection_of_invalid_new_fields(self):
        for key, value in [('conditions', ['unknown']), ('positions', ['unknown']),
                           ('positions', []), ('conditions', True),
                           ('conditions', ['quiet', 'quiet']), ('positions', ['floor', 'floor'])]:
            with self.subTest(key=key, value=value):
                bad = copy.deepcopy(self.meta)
                bad['exercises']['cw001'][key] = value
                with self.assertRaises(ValueError):
                    validate_catalog.validate_metadata(self.data, bad)
        for key in ('conditions', 'positions'):
            bad = copy.deepcopy(self.meta)
            bad['exercises']['cw001'].pop(key, None)
            with self.assertRaises(ValueError):
                validate_catalog.validate_metadata(self.data, bad)
            bad = copy.deepcopy(self.meta)
            bad[key] = []
            with self.assertRaises(ValueError):
                validate_catalog.validate_metadata(self.data, bad)

    def test_generator_check_does_not_write(self):
        path = validate_catalog.METADATA_PATH
        before = path.read_bytes()
        subprocess.run([sys.executable, str(ROOT / 'tools/build_catalog_metadata.py'), '--check'],
                       check=True, capture_output=True)
        subprocess.run([sys.executable, str(ROOT / 'tools/build_execution_conditions.py'), '--check'],
                       check=True, capture_output=True)
        self.assertEqual(path.read_bytes(), before)

    def test_input_rejects_missing_extra_ids_and_duplicate_json_keys(self):
        source = validate_catalog.load(execution.INPUT_PATH)
        for kind in ('missing', 'extra', 'entry_keys'):
            bad = copy.deepcopy(source)
            if kind == 'missing':
                del bad['exercises']['cw363']
            elif kind == 'extra':
                bad['exercises']['cw364'] = bad['exercises']['cw363']
            else:
                bad['exercises']['cw001']['guessedFromName'] = True
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                execution.validate_classification(bad, self.meta['exercises'])
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'duplicate.json'
            path.write_text('{"schemaVersion": 1, "schemaVersion": 1}')
            with patch.object(execution, 'INPUT_PATH', path):
                with self.assertRaisesRegex(ValueError, 'Duplicate execution key'):
                    execution.load_classification(self.meta['exercises'])

    def test_input_rejects_registry_mutations_and_contradictions(self):
        source = validate_catalog.load(execution.INPUT_PATH)
        for mutate in (
            lambda s: s['conditions'].append(s['conditions'][0]),
            lambda s: s['positions'][0].update(label='Inna etykieta'),
            lambda s: s['conditions'][0].update(aliases=['x', 'x']),
            lambda s: s['exercises']['cw001'].update(conditions=['no_floor']),
        ):
            bad = copy.deepcopy(source)
            mutate(bad)
            with self.assertRaises(ValueError):
                execution.validate_classification(bad, self.meta['exercises'])

    def test_builder_copies_reviewed_decision_not_a_name_heuristic(self):
        source = validate_catalog.load(execution.INPUT_PATH)
        # A valid but intentionally reduced tag set must be copied literally.
        # The builder must not fill it back in from 'Push-up' or equipment/type.
        source['exercises']['cw001']['conditions'] = ['no_jumps']
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'reviewed.json'
            path.write_text(json.dumps(source), encoding='utf-8')
            with patch.object(execution, 'INPUT_PATH', path):
                built = build_catalog_metadata.build()
        self.assertEqual(built['exercises']['cw001']['conditions'], ['no_jumps'])


if __name__ == '__main__':
    unittest.main()
