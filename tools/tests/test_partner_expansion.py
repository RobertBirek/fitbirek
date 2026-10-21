import hashlib
import json
from pathlib import Path
import unittest
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


class PartnerExpansionTests(unittest.TestCase):
    def test_all_369_existing_records_and_metadata_unchanged(self):
        for file in ['exercises.json', 'exercise_catalog_metadata.json']:
            before = json.loads(subprocess.check_output(['git', 'show', f'ed0621a:assets/data/{file}'], cwd=ROOT))
            after = json.loads((ROOT / 'assets/data' / file).read_text())
            if isinstance(before, list):
                self.assertEqual(after[:369], before)
            else:
                for eid, row in before['exercises'].items():
                    self.assertEqual(after['exercises'][eid], row)
                for key in ['styles', 'muscles']:
                    ids = {r['id'] for r in before[key]}
                    self.assertEqual([r for r in after[key] if r['id'] in ids], before[key])

    def test_regeneration_is_byte_idempotent(self):
        paths = [ROOT / p for p in ['tools/source_data/baza_cwiczen_316.xlsx',
                 'tools/source_data/exercise_names_pl.json', 'tools/source_data/exercise_execution_conditions.json',
                 'tools/source_data/catalog_sources.json', 'assets/data/exercises.json',
                 'assets/data/exercise_catalog_metadata.json']]
        before = [hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]
        for tool in ['expand_partner_catalog.py', 'xlsx_to_json.py', 'build_catalog_metadata.py']:
            subprocess.run([sys.executable, str(ROOT / 'tools' / tool)], check=True, capture_output=True)
        self.assertEqual([hashlib.sha256(p.read_bytes()).hexdigest() for p in paths], before)

    def test_append_and_partner_requirements(self):
        data = json.loads((ROOT / 'assets/data/exercises.json').read_text())
        self.assertGreaterEqual(len(data), 408)
        meta = json.loads((ROOT / 'assets/data/exercise_catalog_metadata.json').read_text())
        partners = data[392:408]
        self.assertEqual(len(partners), 16)
        for row in partners:
            self.assertIn('Partner', row['sprzet'])
            self.assertIn('w parach', row['nazwaPl'].lower())
            self.assertIn('partner', meta['exercises'][row['id']]['styles'])
            self.assertTrue(any('A:' in cue for cue in row['kluczoweWskazowki']))
            self.assertTrue(any('B:' in cue for cue in row['kluczoweWskazowki']))
        for row in data[:392]:
            self.assertNotIn('Partner', row['sprzet'])

    def test_new_records_complete(self):
        data = json.loads((ROOT / 'assets/data/exercises.json').read_text())
        self.assertEqual([r['id'] for r in data[369:408]], [f'cw{n}' for n in range(370, 409)])
        for row in data[369:408]:
            self.assertGreaterEqual(len(row['kluczoweWskazowki']), 4)
            self.assertTrue(row['czesteBledy'])
            self.assertTrue(row['regresja'])
            self.assertTrue(row['progresja'])
            self.assertTrue(row['zrodlo'].startswith('https://'))


if __name__ == '__main__':
    unittest.main()
