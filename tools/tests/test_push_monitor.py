import importlib.util
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('monitor', Path(__file__).parents[2] / 'deploy/ops/push-monitor.py')
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)


class MonitorTests(unittest.TestCase):
    def test_missing_partial_old_and_future_backups(self):
        now = datetime.now(timezone.utc)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertTrue(monitor.backup_is_stale(root, now))
            for age, stale in [(31, True), (-2, True), (1, False)]:
                bundle = root / '20260910'
                bundle.mkdir(exist_ok=True)
                (bundle / 'database.dump').write_bytes(b'dump')
                (bundle / 'manifest.json').write_text(json.dumps({'created_at': (now - timedelta(hours=age)).strftime('%Y%m%dT%H%M%S%fZ')}))
                self.assertEqual(monitor.backup_is_stale(root, now), stale)

    def test_in_progress_retry_is_not_reported_as_recovery(self):
        with patch.object(monitor.subprocess, 'run') as run:
            run.return_value.stdout = 'Result=success\nActiveState=activating\n'
            self.assertIsNone(monitor.unit_failure('fit-backup.service'))
            run.return_value.stdout = 'Result=exit-code\nActiveState=failed\n'
            self.assertTrue(monitor.unit_failure('fit-backup.service'))
            run.return_value.stdout = 'Result=success\nActiveState=inactive\n'
            self.assertIsNone(monitor.unit_failure('fit-backup.service'))
            run.return_value.stdout = 'Result=success\nActiveState=inactive\nExecMainExitTimestampMonotonic=123\n'
            self.assertFalse(monitor.unit_failure('fit-backup.service'))


class PushSystemdInstallationTests(unittest.TestCase):
    def test_monitor_units_require_the_mentor_overlay(self):
        systemd_directory = Path(__file__).parents[2] / 'deploy/ops/systemd'
        for name in ('fit-push-monitor.service', 'fit-push-failure@.service'):
            unit = (systemd_directory / name).read_text()
            self.assertIn('ConditionPathExists=/docker/fit/compose.mentor.yaml', unit)
            self.assertIn('ExecStart=/usr/bin/python3 /opt/fit/deploy/ops/push-monitor.py', unit)

    def test_installation_includes_all_changed_units_without_a_wildcard(self):
        document = (Path(__file__).parents[2] / 'docs/web-push.md').read_text()
        deployment = document.split('## Procedura wdrożenia', 1)[1]
        installation = deployment.split('6. ', 1)[1]
        installation = installation.split('```', 2)[1]
        for name in (
            'fit-push-monitor.service',
            'fit-push-monitor.timer',
            'fit-push-failure@.service',
            'fit-backup.service',
            'fit-restore-verify.service',
        ):
            self.assertIn(f'/opt/fit/deploy/ops/systemd/{name}', installation)
        self.assertIn('systemctl daemon-reload', installation)
        self.assertNotIn('*', installation)


if __name__ == '__main__':
    unittest.main()
