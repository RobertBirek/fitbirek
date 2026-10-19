"""Public catalog grounding and strict, non-writing template proposal boundary."""
import json
import math
import re
import unicodedata
from pathlib import Path

from fastapi import HTTPException

CATALOG = {e['id']: e for e in json.loads(
    Path(__file__).with_name('exercise_catalog.json').read_text())['exercises']}


def fold(text):
    return ''.join(c for c in unicodedata.normalize('NFKD', text.lower().replace('ł', 'l'))
                    if not unicodedata.combining(c))


def template_requested(text):
    intent = fold(text)
    return ('szablon' in intent or
            (re.search(r'(?<!\d)\d{1,2}\s*min', intent) is not None and
             any(word in intent for word in ('rozciag', 'stretch', 'trening', 'plan', 'joga', 'mobil', 'porann'))))


def candidate_pool(text):
    # The text selects public candidates only, never health/profile/credential data.
    words = {w for w in re.findall(r'[a-z]{4,}', fold(text))
             if w not in {'szablon', 'uloz', 'ogolne', 'poranne', 'trening'}}
    stretching = any(w.startswith(('rozciag', 'stretch')) for w in words)
    pool = [e for e in CATALOG.values() if e['tracking'] in {'reps', 'time'}
            and (not stretching or 'rozciag' in fold(e['type']))]
    selected, muscles = [], set()
    def rank(e):
        public = fold(' '.join([e['name'], e['type'], e['muscle'], *e['equipment']]))
        return (-sum(w in public for w in words), e['muscle'] in muscles, e['id'])
    while pool and len(selected) < 10:
        entry = min(pool, key=rank)
        selected.append(entry)
        muscles.add(entry['muscle'])
        pool.remove(entry)
    return selected


def catalog_message(text):
    # Compact trusted projection; no arbitrary context or user health values.
    return 'CATALOG (jedyna dozwolona pula ID, publiczne dane): ' + json.dumps(
        [{key: e[key] for key in ('id', 'name', 'tracking', 'unilateral')}
         for e in candidate_pool(text)], ensure_ascii=False, separators=(',', ':'))


def _integer(v, low, high):
    return type(v) is int and low <= v <= high


def validate_template(raw, text=None):
    def invalid():
        raise HTTPException(502, 'Invalid template proposal')
    if (not isinstance(raw, dict) or set(raw) != {'kind', 'name', 'minutes', 'exercises'}
            or raw['kind'] != 'create_template'
            or not isinstance(raw['name'], str) or not 1 <= len(raw['name']) <= 120 or not raw['name'].strip()
            or any(ord(c) < 32 for c in raw['name'])
            or not _integer(raw['minutes'], 5, 90)
            or not isinstance(raw['exercises'], list) or not 1 <= len(raw['exercises']) <= 10):
        invalid()
    allowed = CATALOG if text is None else {e['id']: e for e in candidate_pool(text)}
    seen, total = set(), 0
    for e in raw['exercises']:
        if (not isinstance(e, dict) or set(e) != {'exercise_id', 'sets', 'reps', 'seconds', 'rest_seconds', 'weight_kg'}
                or not isinstance(e['exercise_id'], str) or e['exercise_id'] not in allowed
                or e['exercise_id'] in seen or not _integer(e['sets'], 1, 5400)
                or not _integer(e['rest_seconds'], 0, 5400)):
            invalid()
        meta = allowed[e['exercise_id']]
        if meta['tracking'] == 'reps':
            if not _integer(e['reps'], 1, 1800) or e['seconds'] is not None:
                invalid()
            work = e['reps'] * 3 * (2 if meta['unilateral'] else 1)
        elif meta['tracking'] == 'time':
            if e['reps'] is not None or not _integer(e['seconds'], 1, 5400):
                invalid()
            work = e['seconds']  # Total work, including both sides.
        else:
            invalid()
        kg = e['weight_kg']
        if kg is not None and (type(kg) not in {float, int} or not 0 <= kg <= 1000 or not math.isfinite(kg)):
            invalid()
        if work > 5400:
            invalid()
        total += e['sets'] * work + (e['sets'] - 1) * e['rest_seconds'] + 15
        seen.add(e['exercise_id'])
    if total > raw['minutes'] * 60:
        invalid()
    return raw


TEMPLATE_SCHEMA = {
    'type': 'object', 'additionalProperties': False,
    'required': ['kind', 'name', 'minutes', 'exercises'],
    'properties': {
        'kind': {'type': 'string', 'enum': ['create_template']},
        'name': {'type': 'string'}, 'minutes': {'type': 'integer'},
        'exercises': {'type': 'array', 'items': {
            'type': 'object', 'additionalProperties': False,
            'required': ['exercise_id', 'sets', 'reps', 'seconds', 'rest_seconds', 'weight_kg'],
            'properties': {
                'exercise_id': {'type': 'string'}, 'sets': {'type': 'integer'},
                'reps': {'type': ['integer', 'null']}, 'seconds': {'type': ['integer', 'null']},
                'rest_seconds': {'type': 'integer'}, 'weight_kg': {'type': ['number', 'null']},
            }}}}}
