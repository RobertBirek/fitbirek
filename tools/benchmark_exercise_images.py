"""By default, makes three paid image edits. --single-sunburst-medium makes
exactly one Sunburst medium request. Standard library only.

Never resume an output directory: an unfinished request may still be billable.
Prices are USD per million tokens, identical for the two configured models.
"""

import argparse
import base64
import binascii
from datetime import datetime, timezone
from decimal import Decimal
import hashlib
from http.client import HTTPException
import json
import os
from pathlib import Path
import re
import sys
import uuid
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener


CONFIGURATIONS = (
    ('gpt-image-2.5-sunburst', 'medium'),
    ('gpt-image-2.5-sunburst', 'high'),
    ('gpt-image-2.5-flare', 'medium'),
)
ENDPOINT = 'https://api.openai.com/v1/images/edits'


def is_count(value):
    return type(value) is int and value >= 0


def clean_usage(usage):
    """Copy numeric counters only; never persist arbitrary API response text."""
    if not isinstance(usage, dict):
        return None
    result = {key: usage[key] for key in ('input_tokens', 'output_tokens', 'total_tokens')
              if is_count(usage.get(key))}
    details = usage.get('input_tokens_details')
    if isinstance(details, dict):
        result['input_tokens_details'] = {
            key: details[key] for key in ('text_tokens', 'image_tokens', 'cached_tokens')
            if is_count(details.get(key))}
        cache = details.get('cached_tokens_details')
        if isinstance(cache, dict):
            result['input_tokens_details']['cached_tokens_details'] = {
                key: cache[key] for key in ('text_tokens', 'image_tokens')
                if is_count(cache.get(key))}
    return result


def estimate_cost(usage):
    usage = clean_usage(usage) or {}
    details = usage.get('input_tokens_details', {})
    text, image = details.get('text_tokens'), details.get('image_tokens')
    output, total = usage.get('output_tokens'), usage.get('input_tokens')
    unknown = {'kind': 'unknown', 'amount': None}
    if not all(is_count(x) for x in (text, image, output, total)):
        return unknown
    if text + image != total:
        return unknown
    amount = Decimal(text) * 5 + Decimal(image) * 8 + Decimal(output) * 30
    cached = details.get('cached_tokens')
    cache = details.get('cached_tokens_details', {})
    ct, ci = cache.get('text_tokens'), cache.get('image_tokens')
    kind = 'upper_bound_no_cache'
    if cached == 0 and not cache:
        kind = 'estimate'
    elif (is_count(ct) and is_count(ci) and ct <= text and ci <= image
          and cached == ct + ci):
        amount -= Decimal(ct) * Decimal('3.75') + Decimal(ci) * 6
        kind = 'estimate'
    return {'kind': kind, 'amount': format(amount / Decimal(1000000), 'f')}


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def send_request(request):
    """One attempt, no redirect/retry, bounded network timeout."""
    with build_opener(NoRedirect()).open(request, timeout=180) as response:
        return json.loads(response.read()), response.headers.get('x-request-id')


def make_request(configuration, prompt, reference, api_key):
    boundary = 'benchmark-' + uuid.uuid4().hex
    fields = {key: str(configuration[key]) for key in
              ('model', 'quality', 'size', 'n', 'output_format')}
    fields['prompt'] = prompt
    parts = []
    for name, value in fields.items():
        parts.append((f'--{boundary}\r\nContent-Disposition: form-data; '
                      f'name="{name}"\r\n\r\n{value}\r\n').encode('utf-8'))
    parts.append((f'--{boundary}\r\nContent-Disposition: form-data; name="image"; '
                  'filename="reference.png"\r\nContent-Type: image/png\r\n\r\n').encode())
    parts.extend((reference, f'\r\n--{boundary}--\r\n'.encode()))
    return Request(ENDPOINT, data=b''.join(parts), method='POST', headers={
        'Authorization': 'Bearer ' + api_key,
        'Content-Type': 'multipart/form-data; boundary=' + boundary,
    })


def run(args):
    key = os.environ.get('OPENAI_API_KEY')
    if not key or not re.fullmatch(r'cw[0-9]{3,}', args.exercise_id):
        raise ValueError('invalid inputs')
    prompt_bytes = args.prompt.read_bytes()
    prompt = prompt_bytes.decode('utf-8')
    reference = args.reference.read_bytes()
    if not prompt.strip() or not reference.startswith(b'\x89PNG\r\n\x1a\n'):
        raise ValueError('expected prompt and PNG reference')
    # Atomic exclusive claim. Never delete or reuse this directory, even on failure.
    args.output_dir.mkdir(mode=0o700, exist_ok=False)
    common = {
        'prompt_sha256': hashlib.sha256(prompt_bytes).hexdigest(),
        'reference_sha256': hashlib.sha256(reference).hexdigest(),
    }
    configurations = (CONFIGURATIONS[:1] if args.single_sunburst_medium
                      else CONFIGURATIONS)
    with (args.output_dir / 'ledger.jsonl').open('x', encoding='utf-8') as ledger:
        for model, quality in configurations:
            configuration = {'exercise_id': args.exercise_id, 'model': model,
                             'quality': quality, 'size': '1024x1024',
                             'n': 1, 'output_format': 'png'}
            event = {**common, 'configuration': configuration, 'usage': None,
                     'request_id': None, 'estimated_cost_usd': estimate_cost(None)}

            def record(status):
                event.update(status=status, time=datetime.now(timezone.utc).isoformat())
                ledger.write(json.dumps(event, ensure_ascii=True) + '\n')
                ledger.flush()
                os.fsync(ledger.fileno())

            request = make_request(configuration, prompt, reference, key)
            record('started')
            try:
                payload, request_id = send_request(request)
            except HTTPError as error:
                error.close()
                record('http_error')
                return 1
            except (TimeoutError, URLError, OSError, HTTPException):
                record('uncertain')
                return 1
            except (ValueError, UnicodeError):
                record('response_error')
                return 1
            if not isinstance(payload, dict):
                record('response_error')
                return 1
            # Restrict the sole logged header; never log headers or raw responses.
            if (isinstance(request_id, str)
                    and re.fullmatch(r'[A-Za-z0-9_-]{1,200}', request_id)
                    and key not in request_id):
                event['request_id'] = request_id
            event['usage'] = clean_usage(payload.get('usage'))
            event['estimated_cost_usd'] = estimate_cost(event['usage'])
            record('response_received')
            try:
                data = payload['data']
                if not isinstance(data, list) or len(data) != 1:
                    raise ValueError('expected one image')
                image = base64.b64decode(data[0]['b64_json'], validate=True)
                if not image.startswith(b'\x89PNG\r\n\x1a\n'):
                    raise ValueError('expected PNG')
                filename = f'{args.exercise_id}-{model}-{quality}.png'
                with (args.output_dir / filename).open('xb') as output:
                    output.write(image)
                    output.flush()
                    os.fsync(output.fileno())
            except (KeyError, IndexError, TypeError, ValueError, binascii.Error, OSError):
                record('image_error')
                return 1
            record('success')
            cost = event['estimated_cost_usd']
            label = 'unknown' if cost['amount'] is None else f"{cost['amount']} USD ({cost['kind']})"
            print(f'{model}/{quality} 1024x1024 n=1: {label}')
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prompt', type=Path, required=True)
    parser.add_argument('--reference', type=Path, required=True, help='PNG reference image')
    parser.add_argument('--output-dir', type=Path, required=True, help='must not exist')
    parser.add_argument('--exercise-id', required=True)
    parser.add_argument(
        '--single-sunburst-medium', action='store_true',
        help='make exactly one paid gpt-image-2.5-sunburst medium request')
    args = parser.parse_args(argv)
    try:
        code = run(args)
    except (OSError, ValueError):
        code = 1
    if code:
        print('Benchmark stopped; inspect ledger if created. No automatic retry.', file=sys.stderr)
    return code


if __name__ == '__main__':
    sys.exit(main())
