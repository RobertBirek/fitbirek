"""EZ append-only contract: equipment, prefix guard and deterministic replay."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import openpyxl

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import xlsx_to_json as converter
import validate_catalog
from tools.tests.catalog_test_utils import before_owner_equipment
PREFIX_SHA = '98fea910a93c5f85796533c217d11ce437492307c9c9aea315b4f14804438ed9'
PATHS = ['tools/source_data/baza_cwiczen_316.xlsx',
         'tools/source_data/exercise_names_pl.json',
         'tools/source_data/exercise_execution_conditions.json',
         'tools/source_data/catalog_sources.json', 'assets/data/exercises.json',
         'assets/data/exercise_catalog_metadata.json']


class EzExpansionTests(unittest.TestCase):
    def test_exact_ids_equipment_tracking_and_preserved_prefix(self):
        data = json.loads((ROOT / PATHS[4]).read_text())
        self.assertEqual(len(data[:412]), 412)  # Historical EZ publication scope.
        self.assertEqual(hashlib.sha256(json.dumps(data[:408], ensure_ascii=False,
                                                  sort_keys=True).encode()).hexdigest(), PREFIX_SHA)
        meta = before_owner_equipment(self, json.loads((ROOT / PATHS[5]).read_text()))
        old = json.loads(subprocess.check_output(['git', 'show', '1b67bd5:' + PATHS[5]], cwd=ROOT))
        for eid, row in old['exercises'].items():
            self.assertEqual(meta['exercises'][eid], row)
        for key in ['styles', 'muscles', 'conditions', 'positions']:
            self.assertEqual(meta[key], old[key])
        self.assertEqual([r['id'] for r in data[408:412]], ['cw409', 'cw410', 'cw411', 'cw412'])
        bike = data[411]
        self.assertEqual(bike['sprzet'], ['Rower stacjonarny'])
        self.assertEqual(meta['exercises']['cw412']['tracking'], 'time')
        self.assertFalse(meta['exercises']['cw412']['unilateral'])
        self.assertEqual(meta['exercises']['cw412']['positions'], ['seated'])
        self.assertIn('swobodnie rozmawiać', ' '.join(bike['kluczoweWskazowki']))
        for row in data[408:411]:
            self.assertEqual(row['sprzet'], ['Gryf łamany EZ', 'Ławeczka'] if row['id'] == 'cw411' else ['Gryf łamany EZ'])
            m = meta['exercises'][row['id']]
            self.assertEqual(m['tracking'], 'reps')
            self.assertFalse(m['unilateral'])
            self.assertEqual(m['styles'], ['strength'])
            text = ' '.join(row['kluczoweWskazowki']).lower()
            self.assertIn('łączną masę gryfu i talerzy', text)
            self.assertIn('łokci', text)
            self.assertNotIn('40 kg', text)

    def test_replay_from_408_and_byte_idempotence(self):
        with tempfile.TemporaryDirectory(dir='/tmp/opencode') as tmp:
            root = Path(tmp)
            shutil.copytree(ROOT / 'tools', root / 'tools', ignore=shutil.ignore_patterns('__pycache__'))
            (root / 'assets/data').mkdir(parents=True)
            for path in PATHS:
                (root / path).write_bytes(subprocess.check_output(['git', 'show', '1b67bd5:' + path], cwd=ROOT))
            def run(tool, *args):
                subprocess.run([sys.executable, str(root / 'tools' / tool), *args], check=True, capture_output=True)
            for tool in ['expand_ez_catalog.py', 'expand_owner_equipment_catalog.py', 'expand_bodyweight_catalog.py', 'xlsx_to_json.py', 'build_catalog_metadata.py']:
                run(tool)
            for path in PATHS[1:]:
                self.assertEqual((root / path).read_bytes(), (ROOT / path).read_bytes(), path)
            hashes = [hashlib.sha256((root / p).read_bytes()).hexdigest() for p in PATHS]
            for tool in ['expand_ez_catalog.py', 'expand_owner_equipment_catalog.py', 'expand_bodyweight_catalog.py', 'expand_partner_catalog.py', 'xlsx_to_json.py', 'build_catalog_metadata.py']:
                run(tool)
            self.assertEqual(hashes, [hashlib.sha256((root / p).read_bytes()).hexdigest() for p in PATHS])
            run('expand_ez_catalog.py', '--check')
            run('expand_partner_catalog.py', '--check')

    def test_converter_rejects_edit_inside_408_prefix(self):
        with tempfile.TemporaryDirectory(dir='/tmp/opencode') as tmp:
            path = Path(tmp) / 'edited.xlsx'
            wb = openpyxl.load_workbook(converter.XLSX_PATH)
            wb[converter.SHEET_NAME].cell(409, 3).value = 'Changed historical English name'
            wb.save(path)
            wb.close()
            with patch.object(converter, 'XLSX_PATH', path):
                with self.assertRaisesRegex(ValueError, 'cw001–cw408'):
                    converter.convert()

    def test_current_validator_rejects_historical_408(self):
        data = json.loads((ROOT / PATHS[4]).read_text())
        with patch.object(converter, 'convert', return_value=data[:408]):
            original = validate_catalog.load
            with patch.object(validate_catalog, 'load', side_effect=lambda p: data[:408] if p == converter.OUTPUT_PATH else original(p)):
                with self.assertRaisesRegex(ValueError, 'Unexpected reviewed catalog count'):
                    validate_catalog.validate()


if __name__ == '__main__':
    unittest.main()
