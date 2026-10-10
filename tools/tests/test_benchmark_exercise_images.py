"""Offline contracts: transport is always mocked; no API key is needed."""

import base64
import contextlib
import importlib
import io
from http.client import IncompleteRead
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError


PNG = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')
USAGE = {'input_tokens': 300, 'input_tokens_details': {
    'text_tokens': 100, 'image_tokens': 200, 'cached_tokens': 0},
    'output_tokens': 50}


class BenchmarkTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(Path('tools/benchmark_exercise_images.py').is_file(),
                        'benchmark runner has not been implemented')
        self.mod = importlib.import_module('tools.benchmark_exercise_images')
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.prompt = self.root / 'prompt.txt'
        self.prompt.write_text('PRIVATE PROMPT', encoding='utf-8')
        self.reference = self.root / 'reference.png'
        self.reference.write_bytes(PNG)
        self.out = self.root / 'result'

    def ledger(self):
        return [json.loads(line) for line in (self.out / 'ledger.jsonl').read_text().splitlines()]

    def run_benchmark(self, transport, single=False):
        arguments = ['--prompt', str(self.prompt), '--reference',
                     str(self.reference), '--output-dir', str(self.out),
                     '--exercise-id', 'cw265']
        if single:
            arguments.append('--single-sunburst-medium')
        with patch.object(self.mod, 'send_request', side_effect=transport), \
                patch.dict('os.environ', {'OPENAI_API_KEY': 'SECRET-KEY'}), \
                contextlib.redirect_stdout(io.StringIO()) as stdout, \
                contextlib.redirect_stderr(io.StringIO()) as stderr:
            code = self.mod.main(arguments)
        return code, stdout.getvalue(), stderr.getvalue()

    def response(self, usage=USAGE, image=None):
        return {'usage': usage, 'data': [{'b64_json': image or base64.b64encode(PNG).decode()}]}, 'req_123'

    def test_single_sunburst_medium_help_explains_one_paid_request(self):
        with contextlib.redirect_stdout(io.StringIO()) as stdout, \
                self.assertRaises(SystemExit) as exit_code:
            self.mod.main(['--help'])
        self.assertEqual(exit_code.exception.code, 0)
        help_text = ' '.join(stdout.getvalue().split())
        self.assertIn('By default, makes three paid image edits.', help_text)
        self.assertIn(
            '--single-sunburst-medium makes exactly one Sunburst medium request.',
            help_text)
        self.assertIn('--single-sunburst-medium', help_text)
        self.assertIn(
            'make exactly one paid gpt-image-2.5-sunburst medium request',
            help_text)

    def test_regular_cost(self):
        self.assertEqual(self.mod.estimate_cost(USAGE),
                         {'kind': 'estimate', 'amount': '0.0036'})

    def test_known_cache_discount(self):
        usage = json.loads(json.dumps(USAGE))
        usage['input_tokens_details'].update(cached_tokens=90,
            cached_tokens_details={'text_tokens': 30, 'image_tokens': 60})
        self.assertEqual(self.mod.estimate_cost(usage),
                         {'kind': 'estimate', 'amount': '0.0031275'})

    def test_unknown_cache_is_upper_bound(self):
        for cached in (90, None):
            usage = json.loads(json.dumps(USAGE))
            usage['input_tokens_details']['cached_tokens'] = cached
            self.assertEqual(self.mod.estimate_cost(usage),
                             {'kind': 'upper_bound_no_cache', 'amount': '0.0036'})

    def test_missing_or_invalid_usage_is_unknown(self):
        for usage in (None, {}, {'input_tokens': 300, 'output_tokens': 50},
                      {**USAGE, 'output_tokens': -1}, {**USAGE, 'input_tokens': 301}):
            self.assertEqual(self.mod.estimate_cost(usage),
                             {'kind': 'unknown', 'amount': None})

    def test_three_sequential_requests_and_started_ledger(self):
        calls = []
        def transport(request):
            events = self.ledger()
            self.assertEqual(events[-1]['status'], 'started')
            self.assertEqual(request.full_url, 'https://api.openai.com/v1/images/edits')
            self.assertEqual(request.method, 'POST')
            self.assertEqual(request.get_header('Authorization'), 'Bearer SECRET-KEY')
            calls.append(request.data)
            return self.response()
        code, stdout, stderr = self.run_benchmark(transport)
        self.assertEqual((code, stderr), (0, ''))
        self.assertEqual(len(calls), 3)
        for body, model, quality in zip(calls,
                ['sunburst', 'sunburst', 'flare'], ['medium', 'high', 'medium']):
            for value in (f'gpt-image-2.5-{model}', quality, '1024x1024',
                          'name="n"\r\n\r\n1', 'PRIVATE PROMPT', 'name="image"'):
                self.assertIn(value.encode(), body)
        self.assertEqual(len(list(self.out.glob('*.png'))), 3)
        self.assertEqual(len(stdout.splitlines()), 3)
        self.assertTrue(all('0.0036' in line for line in stdout.splitlines()))
        self.assertEqual([x['status'] for x in self.ledger()],
                         ['started', 'response_received', 'success'] * 3)

    def test_single_sunburst_medium_makes_one_request(self):
        calls = []

        def transport(request):
            calls.append(request.data)
            return self.response()

        code, stdout, stderr = self.run_benchmark(transport, single=True)
        self.assertEqual((code, stderr), (0, ''))
        self.assertEqual(len(calls), 1)
        for value in ('gpt-image-2.5-sunburst', 'medium', '1024x1024',
                      'name="n"\r\n\r\n1', 'PRIVATE PROMPT', 'name="image"'):
            self.assertIn(value.encode(), calls[0])
        self.assertEqual(len(list(self.out.glob('*.png'))), 1)
        self.assertEqual(stdout.count('gpt-image-2.5-sunburst/medium'), 1)
        self.assertEqual([x['status'] for x in self.ledger()],
                         ['started', 'response_received', 'success'])
        self.assertTrue(all(event['configuration'] == {
            'exercise_id': 'cw265', 'model': 'gpt-image-2.5-sunburst',
            'quality': 'medium', 'size': '1024x1024', 'n': 1,
            'output_format': 'png',
        } for event in self.ledger()))

    def test_no_usage_still_saves_image_and_reports_unknown(self):
        code, stdout, _ = self.run_benchmark(lambda request: self.response(None))
        self.assertEqual(code, 0)
        self.assertEqual(stdout.count('unknown'), 3)
        self.assertIsNone(self.ledger()[-1]['estimated_cost_usd']['amount'])

    def test_usage_saved_before_decode_failure(self):
        code, stdout, _ = self.run_benchmark(lambda request: self.response(image='not base64!'))
        self.assertEqual(code, 1)
        self.assertEqual(stdout, '')
        self.assertEqual([x['status'] for x in self.ledger()],
                         ['started', 'response_received', 'image_error'])
        self.assertEqual(self.ledger()[-2]['usage'], USAGE)
        self.assertEqual(self.ledger()[-1]['estimated_cost_usd']['amount'], '0.0036')

    def test_existing_directory_prevents_any_request(self):
        self.out.mkdir()
        marker = self.out / 'user-file'
        marker.write_text('preserve')
        def forbidden(request):
            self.fail('duplicate request')
        self.assertEqual(self.run_benchmark(forbidden)[0], 1)
        self.assertEqual(marker.read_text(), 'preserve')

    def test_existing_directory_prevents_any_single_request(self):
        self.out.mkdir()

        def forbidden(request):
            self.fail('duplicate request')

        self.assertEqual(self.run_benchmark(forbidden, single=True)[0], 1)

    def test_timeout_network_http_stop_without_retry(self):
        for error, status in [(TimeoutError('SECRET-KEY'), 'uncertain'),
                (IncompleteRead(b'SECRET-KEY'), 'uncertain'),
                (URLError(TimeoutError('SECRET-KEY')), 'uncertain'),
                (HTTPError('url', 429, 'SECRET-KEY', {}, None), 'http_error')]:
            with self.subTest(status=status):
                self.out = self.root / str(id(error))
                calls = []
                def transport(request):
                    calls.append(request)
                    self.assertEqual(self.ledger()[-1]['status'], 'started')
                    raise error
                code, stdout, stderr = self.run_benchmark(transport)
                self.assertEqual(code, 1)
                self.assertEqual(len(calls), 1)
                self.assertEqual(self.ledger()[-1]['status'], status)
                self.assertIsNone(self.ledger()[-1]['estimated_cost_usd']['amount'])
                self.assertNotIn('SECRET-KEY', stdout + stderr + (self.out / 'ledger.jsonl').read_text())

    def test_real_transport_uses_one_open_and_disables_redirects(self):
        request = self.mod.Request(self.mod.ENDPOINT, data=b'fake', method='POST')
        with patch.object(self.mod, 'build_opener') as factory:
            factory.return_value.open.side_effect = TimeoutError('secret')
            with self.assertRaises(TimeoutError):
                self.mod.send_request(request)
            factory.return_value.open.assert_called_once_with(request, timeout=180)
            handler = factory.call_args.args[0]
            self.assertIsNone(handler.redirect_request(request, None, 307, '', {}, 'https://other'))

    def test_usage_is_on_disk_when_decoder_is_entered(self):
        def decode(*args, **kwargs):
            self.assertEqual(self.ledger()[-1]['status'], 'response_received')
            self.assertEqual(self.ledger()[-1]['usage'], USAGE)
            raise ValueError('SECRET-KEY')
        with patch.object(self.mod.base64, 'b64decode', side_effect=decode):
            self.assertEqual(self.run_benchmark(lambda request: self.response())[0], 1)

    def test_invalid_cache_split_does_not_receive_discount(self):
        usage = json.loads(json.dumps(USAGE))
        usage['input_tokens_details'].update(cached_tokens=90,
            cached_tokens_details={'text_tokens': 200, 'image_tokens': 0})
        self.assertEqual(self.mod.estimate_cost(usage),
                         {'kind': 'upper_bound_no_cache', 'amount': '0.0036'})

    def test_logs_only_allowlisted_fields(self):
        usage = json.loads(json.dumps(USAGE))
        usage['secret'] = 'SECRET-KEY'
        usage['input_tokens_details']['injected'] = 'PRIVATE PROMPT'
        self.assertEqual(self.run_benchmark(lambda request: self.response(usage))[0], 0)
        raw = (self.out / 'ledger.jsonl').read_text()
        for forbidden in ('SECRET-KEY', 'PRIVATE PROMPT', 'b64_json', base64.b64encode(PNG).decode()):
            self.assertNotIn(forbidden, raw)
        allowed = {'configuration', 'prompt_sha256', 'reference_sha256', 'time',
                   'usage', 'request_id', 'status', 'estimated_cost_usd'}
        for event in self.ledger():
            self.assertEqual(set(event), allowed)
            self.assertEqual(len(event['prompt_sha256']), 64)

    def test_non_png_is_rejected(self):
        code, _, _ = self.run_benchmark(lambda request: self.response(image=base64.b64encode(b'not png').decode()))
        self.assertEqual(code, 1)
        self.assertEqual(list(self.out.glob('*.png')), [])


if __name__ == '__main__':
    unittest.main()
