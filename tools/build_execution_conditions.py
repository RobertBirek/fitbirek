#!/usr/bin/env python3
"""Load reviewed, explicit per-ID execution data. No movement/name inference.

Integrated by build_catalog_metadata.py. Standalone --check verifies the input
and its exact projection in the generated sidecar, without writing either file.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = ROOT / 'tools/source_data/exercise_execution_conditions.json'
CONDITION_LABELS = {
    'no_jumps': 'Bez skoków', 'quiet': 'Cichy trening',
    'no_kneeling': 'Bez klęku', 'no_hand_support': 'Bez podporu na dłoniach',
    'no_floor': 'Bez schodzenia na podłogę', 'small_space': 'Mało miejsca',
}
POSITION_LABELS = {
    'standing': 'Stojąco', 'seated': 'Siedząco', 'floor': 'Na podłodze',
    'hanging': 'W zwisie', 'bench': 'Na ławce',
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f'Duplicate execution key: {key}')
        result[key] = value
    return result


def string_list(value, label):
    require(isinstance(value, list), f'{label}: expected list')
    require(all(isinstance(x, str) and x and x.strip() == x for x in value),
            f'{label}: invalid string')
    require(len(value) == len(set(value)), f'{label}: duplicates')


def validate_classification(source, expected_ids):
    require(isinstance(source, dict) and
            set(source) == {'schemaVersion', 'conditions', 'positions', 'exercises'},
            'Execution source keys')
    require(type(source['schemaVersion']) is int and source['schemaVersion'] == 1,
            'Execution schemaVersion')
    for key, labels in [('conditions', CONDITION_LABELS), ('positions', POSITION_LABELS)]:
        require(isinstance(source[key], list), f'{key}: expected registry list')
        ids = []
        for record in source[key]:
            require(isinstance(record, dict) and set(record) == {'id', 'label', 'aliases'},
                    f'{key}: registry keys')
            require(isinstance(record['id'], str) and record['id'] in labels,
                    f'{key}: unknown registry ID')
            require(record['label'] == labels[record['id']], f'{key}: wrong label')
            string_list(record['aliases'], f'{key}: aliases')
            ids.append(record['id'])
        require(len(ids) == len(set(ids)) and set(ids) == set(labels),
                f'{key}: exact registry coverage required')
    require(isinstance(source['exercises'], dict) and
            set(source['exercises']) == set(expected_ids), 'Execution ID coverage')
    for eid, entry in source['exercises'].items():
        require(isinstance(entry, dict) and set(entry) == {'conditions', 'positions'},
                f'{eid}: execution entry keys')
        for key, registry in [('conditions', CONDITION_LABELS), ('positions', POSITION_LABELS)]:
            string_list(entry[key], f'{eid}: {key}')
            require(set(entry[key]) <= set(registry), f'{eid}: unknown {key}')
        require(bool(entry['positions']), f'{eid}: positions must not be empty')
        require(not ('floor' in entry['positions'] and 'no_floor' in entry['conditions']),
                f'{eid}: floor conflicts with no_floor')


def load_classification(expected_ids):
    source = json.loads(INPUT_PATH.read_text(encoding='utf-8'), object_pairs_hook=unique_pairs)
    validate_classification(source, expected_ids)
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', required=True)
    parser.parse_args()
    catalog = json.loads((ROOT / 'assets/data/exercises.json').read_text(encoding='utf-8'))
    source = load_classification({e['id'] for e in catalog})
    meta = json.loads((ROOT / 'assets/data/exercise_catalog_metadata.json').read_text(encoding='utf-8'))
    require(meta['schemaVersion'] == source['schemaVersion'], 'Execution schema differs')
    require(set(meta['exercises']) == set(source['exercises']), 'Execution output ID coverage')
    for key in ('conditions', 'positions'):
        require(meta.get(key) == source[key], f'Execution registry differs: {key}')
        for eid, entry in source['exercises'].items():
            require(meta['exercises'][eid].get(key) == entry[key], f'{eid}: execution output differs')
    print(f'Execution CHECK OK: {len(source["exercises"])} explicit entries, 6 conditions, 5 positions')


if __name__ == '__main__':
    main()
