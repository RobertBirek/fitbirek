"""The promotion gate must exercise the image as the sender, not only API USER."""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'deploy/ops/check-backend-images.py'
API = 'sha256:' + '1' * 64
MIG = 'sha256:' + '2' * 64


def load_checker():
    spec = importlib.util.spec_from_file_location('backend_image_gate', SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BackendImagesTests(unittest.TestCase):
    def test_cli_requires_both_images_without_production_fallback(self):
        p = subprocess.run(['python3', str(SCRIPT)], capture_output=True)
        self.assertNotEqual(p.returncode, 0)
        self.assertNotIn(b'production', p.stdout)

    def test_resolves_once_and_probes_all_four_immutable_identities(self):
        module = load_checker()
        calls = []

        def run(args, **kwargs):
            calls.append((args, kwargs))
            if args[:3] == ['docker', 'image', 'inspect']:
                return subprocess.CompletedProcess(args, 0, json.dumps({
                    'id': API if args[-1] == 'runtime-candidate' else MIG,
                    'user': 'app',
                }), '')
            if 'run' in args:
                uid, gid = (100, 101) if args[args.index('--user') + 1] == 'app' else (65532, 65532)
                return subprocess.CompletedProcess(args, 0, json.dumps({
                    'ok': True, 'uid': uid, 'gid': gid,
                    'files': 44, 'modules': 43,
                }), '')
            return subprocess.CompletedProcess(args, 0, '', '')

        with patch.object(module.subprocess, 'run', side_effect=run):
            result = module.check_images('runtime-candidate', 'migration-candidate')
        self.assertTrue(result['ok'])
        self.assertEqual(len(result['checks']), 4)
        inspections = [a for a, _ in calls if a[:3] == ['docker', 'image', 'inspect']]
        self.assertEqual(len(inspections), 2)
        runs = [(a, kw) for a, kw in calls if a[:2] == ['docker', 'run']]
        self.assertEqual(len(runs), 4)
        for args, kwargs in runs:
            self.assertIn(API if 'runtime' in kwargs['input'] else MIG, args)
            self.assertEqual(args[args.index('--network') + 1], 'none')
            self.assertIn('--read-only', args)
            self.assertIn('--pull=never', args)
            self.assertNotIn('--env-file', args)
            self.assertNotIn('-v', args)
            self.assertNotIn('-p', args)
            self.assertEqual(args[args.index('--cap-drop') + 1], 'ALL')
            self.assertIn('no-new-privileges:true', args)
            self.assertIn('DATABASE_URL=postgresql+asyncpg://probe:probe@127.0.0.1:1/probe', args)
            self.assertIn('PUSH_ENABLED=false', args)
            self.assertNotIn('-m', args)

    def test_failure_timeout_and_invalid_proof_never_pass_and_cleanup_only_owned_names(self):
        module = load_checker()
        for fault in ['exit', 'timeout', 'empty', 'wrong-uid']:
            with self.subTest(fault=fault):
                cleaned = []

                def run(args, **kwargs):
                    if args[:3] == ['docker', 'image', 'inspect']:
                        return subprocess.CompletedProcess(args, 0, json.dumps({'id': API, 'user': 'app'}), '')
                    if args[:2] == ['docker', 'rm']:
                        cleaned.append(args[-1])
                        return subprocess.CompletedProcess(args, 0, '', '')
                    if fault == 'timeout':
                        raise subprocess.TimeoutExpired(args, 1)
                    body = '' if fault == 'empty' else json.dumps({'ok': True, 'uid': 0, 'gid': 0, 'files': 44, 'modules': 43})
                    return subprocess.CompletedProcess(args, 1 if fault == 'exit' else 0, body, 'SENSITIVE ERROR')

                with patch.object(module.subprocess, 'run', side_effect=run):
                    result = module.check_images('candidate', 'migration')
                self.assertFalse(result['ok'])
                self.assertTrue(cleaned)
                self.assertTrue(all(n.startswith('fit-image-gate-') for n in cleaned))
                self.assertNotIn('SENSITIVE', json.dumps(result))

    def test_missing_image_and_wrong_default_user_fail_closed(self):
        module = load_checker()
        for proof in ['', json.dumps({'id': API, 'user': 'root'})]:
            with patch.object(module.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, proof, '')):
                self.assertFalse(module.check_images('candidate', 'migration')['ok'])


@unittest.skipUnless(sys.platform == 'linux' and os.geteuid() == 0,
                     'Real UID fixture requires Linux root; actual Docker gate never skips')
class ProbePermissionsTests(unittest.TestCase):
    def setUp(self):
        self.module = load_checker()
        self.root = Path(tempfile.mkdtemp(prefix='image-gate-test-', dir='/tmp/opencode'))
        self.addCleanup(shutil.rmtree, self.root)
        self.root.chmod(0o755)
        for path, contents in {
            'app/main.py': 'value = 1\n',
            'app/push/worker.py': 'def run():\n raise RuntimeError("MUST NOT RUN")\nif __name__ == "__main__":\n run()\n',
            'app/push/transport.py': 'value = 2\n',
            'app/mentor/exercise_catalog.json': '{}',
            'app/extra/__init__.py': 'value = 3\n',
            'app/extra/other.py': 'value = 4\n',
        }.items():
            full = self.root / path
            full.parent.mkdir(parents=True, exist_ok=True)
            full.write_text(contents)
            full.chmod(0o644)
            os.chown(full, 100, 101)
        for path in (self.root / 'app').rglob('*'):
            if path.is_dir():
                path.chmod(0o755)
                os.chown(path, 100, 101)
        (self.root / 'app').chmod(0o755)
        os.chown(self.root / 'app', 100, 101)

    def probe(self, uid, gid):
        def identity():
            os.setgroups([])
            os.setgid(gid)
            os.setuid(uid)
        code = 'ARGUMENTS = ' + repr(('runtime', uid, gid)) + '\n' + self.module.PROBE
        code = code.replace("root = pathlib.Path('/app')", f'root = pathlib.Path({str(self.root)!r})')
        result = subprocess.run([sys.executable, '-B', '-c', code], cwd=self.root,
                                preexec_fn=identity, capture_output=True, text=True, timeout=20)
        proof = json.loads(result.stdout)
        self.assertEqual(result.returncode == 0, proof['ok'])
        return proof

    def test_kernel_permissions_reproduce_0700_and_corrected_0755_for_both_users(self):
        (self.root / 'app/push').chmod(0o700)
        self.assertTrue(self.probe(100, 101)['ok'])
        self.assertFalse(self.probe(65532, 65532)['ok'])
        (self.root / 'app/push').chmod(0o755)
        self.assertTrue(self.probe(100, 101)['ok'])
        self.assertTrue(self.probe(65532, 65532)['ok'])

    def test_unreadable_file_missing_sentinel_and_unimported_module_fail(self):
        catalog = self.root / 'app/mentor/exercise_catalog.json'
        catalog.chmod(0o600)
        self.assertFalse(self.probe(65532, 65532)['ok'])
        catalog.chmod(0o644)
        catalog.unlink()
        self.assertFalse(self.probe(100, 101)['ok'])
        catalog.write_text('{}')
        (self.root / 'app/extra/other.py').write_text('import definitely_missing_image_gate_dependency\n')
        self.assertFalse(self.probe(100, 101)['ok'])

    def test_import_time_io_is_rejected_without_running_worker(self):
        other = self.root / 'app/extra/other.py'
        other.write_text('import socket\nsocket.create_connection(("127.0.0.1", 1))\n')
        self.assertFalse(self.probe(100, 101)['ok'])
        other.write_text('value = 4\n')
        self.assertTrue(self.probe(65532, 65532)['ok'])

    def test_caught_import_time_io_still_fails_closed(self):
        other = self.root / 'app/extra/other.py'
        other.write_text('import socket\ntry:\n socket.create_connection(("127.0.0.1", 1))\nexcept RuntimeError:\n pass\n')
        self.assertFalse(self.probe(100, 101)['ok'])

    def test_symlink_and_directory_without_search_permission_fail(self):
        (self.root / 'app/extra/link.py').symlink_to(self.root / 'app/main.py')
        self.assertFalse(self.probe(65532, 65532)['ok'])
        (self.root / 'app/extra/link.py').unlink()
        (self.root / 'app/extra').chmod(0o644)
        self.assertFalse(self.probe(100, 101)['ok'])


if __name__ == '__main__':
    unittest.main()
