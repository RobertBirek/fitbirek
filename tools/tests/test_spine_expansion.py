"""Second expansion: immutable 363 prefix, additive styles, explicit new data."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import xlsx_to_json as converter
import validate_catalog

ROOT = Path(__file__).resolve().parents[2]
BASE = '6f3eb79b692f6201d8bbf45b6952cd461aeccaaa'


def baseline(path):
    return json.loads(subprocess.check_output(['git', 'show', f'{BASE}:{path}'], cwd=ROOT))


class SpineExpansionTests(unittest.TestCase):
    def test_six_new_records_and_unchanged_prefix(self):
        data = validate_catalog.load(converter.OUTPUT_PATH)
        self.assertEqual(len(data), 369)
        self.assertEqual(data[:363], baseline('assets/data/exercises.json'))
        self.assertEqual([e['id'] for e in data[363:]], [f'cw{i}' for i in range(364, 370)])

    def test_old_metadata_preserved_except_additive_spine(self):
        old = baseline('assets/data/exercise_catalog_metadata.json')
        new = validate_catalog.load(validate_catalog.METADATA_PATH)
        self.assertEqual(new['styles'][:6], old['styles'])
        self.assertEqual(new['styles'][6:], [dict(id='spine', label='Kręgosłup — ruch i stabilizacja',
                                                aliases=['kręgosłup', 'kregoslup', 'spine'])])
        for key in ('muscles', 'conditions', 'positions'):
            self.assertEqual(new[key], old[key])
        for eid, row in old['exercises'].items():
            actual = copy.deepcopy(new['exercises'][eid])
            self.assertTrue(set(row['styles']) <= set(actual['styles']), eid)
            actual['styles'] = [x for x in actual['styles'] if x != 'spine']
            self.assertEqual(actual, row, eid)
        for eid in ('cw179', 'cw181', 'cw250'):
            self.assertIn('spine', new['exercises'][eid]['styles'])
        self.assertNotIn('spine', new['exercises']['cw269']['styles'])
        self.assertNotIn('spine', new['exercises']['cw194']['styles'])

    def test_new_expansion_input_and_checks(self):
        path = ROOT / 'tools/expand_spine_catalog.py'
        self.assertTrue(path.exists(), 'Missing idempotent second expansion tool')
        for name in ('expand_spine_catalog.py', 'expand_catalog.py',
                     'build_catalog_metadata.py', 'build_execution_conditions.py'):
            subprocess.run([sys.executable, str(ROOT / 'tools' / name), '--check'],
                           check=True, capture_output=True)

    def test_prefix363_mutation_rejected_by_converter(self):
        import openpyxl
        wb = openpyxl.load_workbook(converter.XLSX_PATH)
        wb[converter.SHEET_NAME]['L364'] = 'Zmieniona instrukcja cw363'
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'bad.xlsx'
            wb.save(path)
            with patch.object(converter, 'XLSX_PATH', path):
                with self.assertRaisesRegex(ValueError, 'cw001–cw363'):
                    converter.convert()
        wb.close()

    def test_explicit_conditions_and_tracking(self):
        meta = validate_catalog.load(validate_catalog.METADATA_PATH)['exercises']
        for n in range(364, 370):
            eid = f'cw{n}'
            self.assertIn(eid, meta)
            m = meta[eid]
            expected = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support']
            if n == 369:
                expected.append('no_floor')
            expected.append('small_space')
            self.assertEqual(m['conditions'], expected, eid)
            self.assertEqual(m['positions'], ['standing'] if n == 369 else ['floor'])
            self.assertEqual(m['tracking'], 'time' if n == 365 else 'reps')
            self.assertEqual(m['unilateral'], n in (366, 367, 368))

    def test_baseline_guard_rejects_style_loss_and_nonstyle_mutation(self):
        import spine_additions
        meta = validate_catalog.load(validate_catalog.METADATA_PATH)
        spine_additions.validate_preservation(converter.convert(), meta)
        for key, value in [('styles', ['spine']), ('tracking', 'rounds'),
                           ('primaryMuscles', ['neck']), ('conditions', [])]:
            bad = copy.deepcopy(meta)
            bad['exercises']['cw179'][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                spine_additions.validate_preservation(converter.convert(), bad)

    def test_rebuild_from_baseline_and_byte_idempotence(self):
        import expand_spine_catalog as expansion
        from contextlib import ExitStack
        with tempfile.TemporaryDirectory() as tmp, ExitStack() as stack:
            paths = {}
            for name in ('baza_cwiczen_316.xlsx', 'exercise_names_pl.json',
                         'exercise_execution_conditions.json', 'catalog_sources.json'):
                path = Path(tmp) / name
                path.write_bytes(subprocess.check_output(
                    ['git', 'show', f'{BASE}:tools/source_data/{name}'], cwd=ROOT))
                paths[name] = path
            stack.enter_context(patch.object(converter, 'XLSX_PATH', paths['baza_cwiczen_316.xlsx']))
            for attribute, name in [('MAPPING_PATH', 'exercise_names_pl.json'),
                                    ('INPUT_PATH', 'exercise_execution_conditions.json'),
                                    ('SOURCE_PATH', 'catalog_sources.json')]:
                stack.enter_context(patch.object(expansion, attribute, paths[name]))
            with patch.object(sys, 'argv', ['expand_spine_catalog.py']):
                expansion.main()
                first = {name: path.read_bytes() for name, path in paths.items()}
                expansion.main()
                self.assertEqual(first, {name: path.read_bytes() for name, path in paths.items()})
            with patch.object(sys, 'argv', ['expand_spine_catalog.py', '--check']):
                expansion.main()
            self.assertEqual(converter.convert(), validate_catalog.load(converter.OUTPUT_PATH))
            for name, path in paths.items():
                if not name.endswith('.xlsx'):
                    self.assertEqual(json.loads(path.read_text()),
                                     validate_catalog.load(ROOT / 'tools/source_data' / name))

    def test_guard_enforces_reviewed_spine_membership_and_definition(self):
        import spine_additions
        meta = validate_catalog.load(validate_catalog.METADATA_PATH)
        for mutation in ('extra_member', 'missing_member', 'definition', 'new_tracking'):
            bad = copy.deepcopy(meta)
            if mutation == 'extra_member':
                bad['exercises']['cw194']['styles'].append('spine')
            elif mutation == 'missing_member':
                bad['exercises']['cw179']['styles'].remove('spine')
            elif mutation == 'definition':
                bad['styles'][-1]['label'] = 'Inna etykieta'
            else:
                bad['exercises']['cw365']['tracking'] = 'reps'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                spine_additions.validate_preservation(converter.convert(), bad)


if __name__ == '__main__':
    unittest.main()
