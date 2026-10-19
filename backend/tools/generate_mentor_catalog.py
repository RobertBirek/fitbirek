"""Reproducible public-only runtime bundle; run from any directory, no network."""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sources = [ROOT / 'assets/data' / name for name in
           ('exercises.json', 'exercise_catalog_metadata.json')]
exercises, metadata = [json.loads(p.read_text()) for p in sources]
entries = [{
    'id': e['id'], 'name': e['nazwaPl'], 'type': e['typ'],
    'muscle': e['partiaGlowna'], 'equipment': e['sprzet'],
    'tracking': metadata['exercises'][e['id']]['tracking'],
    'unilateral': metadata['exercises'][e['id']]['unilateral'],
} for e in sorted(exercises, key=lambda e: e['id'])]
bundle = {'sources_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
          'exercises': entries}
target = ROOT / 'backend/app/mentor/exercise_catalog.json'
rendered = json.dumps(bundle, ensure_ascii=False, indent=2) + '\n'
if '--check' in sys.argv:
    if target.read_text() != rendered:
        raise SystemExit('Mentor catalog is stale; regenerate it from assets.')
else:
    target.write_text(rendered)
