"""Explicit non-mutating corrections for generators, never the raw XLSX export."""
from copy import deepcopy
import json
from pathlib import Path
from catalog_equipment import VALID_SPRZET

CORRECTIONS_PATH = Path(__file__).resolve().parents[1] / 'assets/data/exercise_catalog_corrections.json'
CORRECTION_IDS = {'cw009', 'cw123', 'cw135', 'cw136', 'cw165', 'cw267'}
FIELDS = {'nazwaPl', 'sprzet', 'kluczoweWskazowki', 'czesteBledy', 'progresja', 'regresja'}


def validate_corrections(manifest):
    def require(ok, message):
        if not ok:
            raise ValueError('Corrections: ' + message)
    require(isinstance(manifest, dict) and set(manifest) == {'schemaVersion', 'corrections'}, 'root keys')
    require(type(manifest['schemaVersion']) is int and manifest['schemaVersion'] == 1, 'schemaVersion')
    rows = manifest['corrections']
    require(isinstance(rows, list) and len(rows) == len(CORRECTION_IDS), 'exact six corrections')
    seen = set()
    for row in rows:
        require(isinstance(row, dict) and set(row) == {'exerciseId', 'revision', 'fields'}, 'entry keys')
        eid = row['exerciseId']
        require(isinstance(eid, str) and eid in CORRECTION_IDS and eid not in seen, 'unknown/duplicate exerciseId')
        seen.add(eid)
        require(type(row['revision']) is int and row['revision'] == 1, 'revision')
        fields = row['fields']
        require(isinstance(fields, dict) and bool(fields) and set(fields) <= FIELDS, 'field whitelist')
        for key, value in fields.items():
            if key in ('sprzet', 'kluczoweWskazowki', 'czesteBledy'):
                require(isinstance(value, list) and bool(value), key + ': nonempty list')
                require(all(isinstance(v, str) and bool(v) and v.strip() == v for v in value), key + ': strings')
                require(len(value) == len(set(value)), key + ': duplicates')
                if key == 'sprzet':
                    require(set(value) <= VALID_SPRZET, 'unknown equipment')
            else:
                require(isinstance(value, str) and bool(value) and value.strip() == value, key + ': string')
    require(seen == CORRECTION_IDS, 'ID coverage')


def effective_catalog(raw, manifest=None):
    if manifest is None:
        manifest = json.loads(CORRECTIONS_PATH.read_text())
    validate_corrections(manifest)
    result = deepcopy(raw)
    by_id = {row['id']: row for row in result}
    if len(by_id) != len(result) or not CORRECTION_IDS <= set(by_id):
        raise ValueError('Corrections: raw ID coverage/duplicates')
    for correction in manifest['corrections']:
        by_id[correction['exerciseId']].update(deepcopy(correction['fields']))
    return result
