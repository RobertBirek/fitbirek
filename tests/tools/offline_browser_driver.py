"""Lifecycle acceptance without automatically debugging service-worker targets.

Playwright normally attaches a Runtime session to each SW, which changes its
idle/termination behavior. Copy the installed driver to a TEMP directory and
exclude only service_worker auto-attachment. Pages/CDP control remain enabled;
no browser security/network policy is changed and no dependency is installed.
FIT_OFFLINE_ATTACH_SW=1 preserves the original instrumented mode for diagnosis.
"""
from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import tempfile

from playwright._impl import _transport


@contextmanager
def native_service_worker_lifecycle():
    if os.environ.get('FIT_OFFLINE_ATTACH_SW') == '1':
        yield
        return
    original = getattr(_transport, 'compute_driver_executable')
    node, cli = original()
    with tempfile.TemporaryDirectory(prefix='fit-native-sw-driver-') as directory:
        package = Path(directory) / 'package'
        shutil.copytree(Path(cli).parent, package)
        bundle = package / 'lib/coreBundle.js'
        if not bundle.exists():
            raise RuntimeError('Unsupported installed Playwright driver layout; do not silently attach SW')
        source = bundle.read_text()
        before = 'session2.send("Target.setAutoAttach", { autoAttach: true, waitForDebuggerOnStart: true, flatten: true })'
        # CDP's default filter excludes browser/tab and includes the remaining
        # types. Retain that behavior, adding only the SW exclusion.
        after = 'session2.send("Target.setAutoAttach", { autoAttach: true, waitForDebuggerOnStart: true, flatten: true, filter: [{type:"service_worker", exclude:true}, {type:"browser", exclude:true}, {type:"tab", exclude:true}, {}] })'
        if source.count(before) != 2:
            raise RuntimeError('Unsupported Playwright auto-attachment implementation; inspect before adapting')
        bundle.write_text(source.replace(before, after))
        setattr(_transport, 'compute_driver_executable', lambda: (node, str(package / 'cli.js')))
        try:
            yield
        finally:
            setattr(_transport, 'compute_driver_executable', original)


def assert_no_worker_debugger(test, browser, context):
    if os.environ.get('FIT_OFFLINE_ATTACH_SW') == '1':
        return
    test.assertEqual(context.service_workers, [], 'Driver must not attach a Runtime to SW')
    session = browser.new_browser_cdp_session()
    try:
        workers = [target for target in session.send('Target.getTargets')['targetInfos']
                   if target['type'] == 'service_worker']
        test.assertTrue(workers, 'Real SW targets must exist; workers are not disabled')
        test.assertTrue(all(not target['attached'] for target in workers), 'SW debugger unexpectedly attached')
    finally:
        session.detach()
