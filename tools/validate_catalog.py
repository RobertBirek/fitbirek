#!/usr/bin/env python3
"""Offline validation of immutable legacy prefix, metadata and source coverage."""
import hashlib
import json
from pathlib import Path
import re

import xlsx_to_json as converter

ROOT = Path(__file__).resolve().parents[1]
METADATA_PATH = ROOT / 'assets/data/exercise_catalog_metadata.json'
SOURCES_PATH = ROOT / 'tools/source_data/catalog_sources.json'
LEGACY_SHA256 = converter.LEGACY_SHA256


def require(condition, message):
    if not condition:
        raise ValueError(message)


def unique_pairs(pairs):
    result = {}
    for k, v in pairs:
        require(k not in result, f'Duplicate JSON key: {k}')
        result[k] = v
    return result


def load(path):
    return json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=unique_pairs)


def string_list(value, label, nonempty=False):
    require(isinstance(value, list), f'{label}: expected list')
    require(all(isinstance(x, str) and x.strip() == x and x for x in value), f'{label}: invalid string')
    require(len(value) == len(set(value)), f'{label}: duplicates')
    require(not nonempty or bool(value), f'{label}: empty')


def validate_metadata(data, meta):
    require(set(meta) == {'schemaVersion', 'styles', 'muscles', 'exercises'}, 'Metadata keys')
    require(type(meta['schemaVersion']) is int and meta['schemaVersion'] == 1, 'schemaVersion')
    registries = {}
    for key in ('styles', 'muscles'):
        require(isinstance(meta[key], list), f'{key}: expected list')
        ids = []
        labels = []
        for record in meta[key]:
            require(set(record) == {'id', 'label', 'aliases'}, f'{key}: registry keys')
            require(isinstance(record['id'], str) and re.fullmatch('[a-z][a-z_]*', record['id']), f'{key}: unstable id')
            require(isinstance(record['label'], str) and record['label'].strip(), f'{key}: label')
            string_list(record['aliases'], f'{key}: aliases')
            ids.append(record['id'])
            labels.append(record['label'])
        require(len(ids) == len(set(ids)) and len(labels) == len(set(labels)), f'{key}: duplicate id/label')
        registries[key] = set(ids)
    require(not {'cardio', 'mobility', 'coordination', 'full_body'} & registries['muscles'], 'Non-anatomical muscle')
    require(set(meta['exercises']) == {e['id'] for e in data}, 'Metadata ID coverage')
    for eid, m in meta['exercises'].items():
        require(set(m) == {'styles', 'primaryMuscles', 'secondaryMuscles', 'aliases', 'tracking', 'unilateral'}, f'{eid}: keys')
        for key in ('styles', 'primaryMuscles', 'secondaryMuscles', 'aliases'):
            string_list(m[key], f'{eid}: {key}', nonempty=key in ('styles', 'primaryMuscles'))
        require(set(m['styles']) <= registries['styles'], f'{eid}: unknown style')
        require(set(m['primaryMuscles'] + m['secondaryMuscles']) <= registries['muscles'], f'{eid}: unknown muscle')
        require(not set(m['primaryMuscles']) & set(m['secondaryMuscles']), f'{eid}: overlapping muscle roles')
        require(m['tracking'] in ('reps', 'time', 'rounds'), f'{eid}: tracking')
        require(type(m['unilateral']) is bool, f'{eid}: unilateral must be boolean')


def validate_sources(data, sources):
    additions = [e for e in data if int(e['id'][2:]) > converter.LEGACY_COUNT]
    require(set(sources['exercises']) == {e['id'] for e in additions}, 'Source ID coverage')
    for record in sources['sources'].values():
        require(record['url'].startswith('https://') and record['verifiedSections'].strip(), 'Source review missing')
    seen_names = {e['nazwaEn'].casefold() for e in data[:316]}
    for e in additions:
        record = sources['exercises'][e['id']]
        require(record['source'] in sources['sources'], f'{e["id"]}: unknown source')
        require(e['zrodlo'] == sources['sources'][record['source']]['url'], f'{e["id"]}: source differs')
        require(e['nazwaEn'] == record['movement'], f'{e["id"]}: sourced movement differs')
        require(e['nazwaEn'].casefold() not in seen_names, f'{e["id"]}: duplicate movement name')
        seen_names.add(e['nazwaEn'].casefold())
        for key in ('kluczoweWskazowki', 'czesteBledy', 'progresja', 'regresja'):
            require(bool(e[key]), f'{e["id"]}: missing {key}')


def validate():
    data = load(converter.OUTPUT_PATH)
    require(converter.convert() == data, 'XLSX export differs')
    legacy = json.dumps(data[:316], ensure_ascii=False, sort_keys=True).encode()
    require(hashlib.sha256(legacy).hexdigest() == LEGACY_SHA256, 'Legacy cw001–cw316 changed')
    validate_metadata(data, load(METADATA_PATH))
    validate_sources(data, load(SOURCES_PATH))
    names = load(ROOT / 'tools/source_data/exercise_names_pl.json')
    require(names == {e['id']: e['nazwaPl'] for e in data}, 'Names mapping differs')
    print(f'Catalog OK: {len(data)} exercises, {len(data) - 316} new; 316 legacy records unchanged; metadata and sources complete')


if __name__ == '__main__':
    validate()
