"""Real Flutter 3.35.4 loader + legacy template, two tabs, same ?v token.

Provide FIT_FLUTTER_JS and FIT_LEGACY_SW_TEMPLATE from the pinned SDK/artifact.
No Flutter build. Docker is used only for the dependency-free Dart generator.
"""
import functools
import hashlib
import http.server
import json
import os
import re
from pathlib import Path
import subprocess
import tempfile
import threading
import time
import unittest
from typing import cast

from playwright.sync_api import sync_playwright

from offline_browser_driver import assert_no_worker_debugger, native_service_worker_lifecycle


class FixtureServer(http.server.ThreadingHTTPServer):
    fixture_requests: list[str]
    core_download_started: threading.Event
    release_core_download: threading.Event
    hold_core_download: bool


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        server = cast(FixtureServer, self.server)
        server.fixture_requests.append(self.path)
        if server.hold_core_download and self.path == '/main.dart.js':
            server.core_download_started.set()
            if not server.release_core_download.wait(timeout=10):
                self.send_error(504, 'Fixture core gate timed out')
                return
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, format, *args):
        pass


class OfflineUpdateBrowserTest(unittest.TestCase):
    def test_legacy_to_custom_two_tabs(self):
        self.exercise(legacy=True)

    def test_custom_a_to_b_two_tabs_same_loader_token(self):
        self.exercise(legacy=False)

    def test_lost_routing_and_worker_restart_legacy_old_document_fails_closed(self):
        self.exercise(legacy=True, scenario='lostAfter')

    def test_lost_routing_before_successor_install_does_not_pin_unknown_to_b(self):
        self.exercise(legacy=False, scenario='lostBefore')

    def test_old_document_status_requires_reload_even_when_b_is_ready(self):
        self.exercise(legacy=False, scenario='oldStatus')

    def test_old_only_cached_asset_removed_from_b_still_works_offline(self):
        self.exercise(legacy=False, scenario='oldOnly')

    def test_asset_only_release_does_not_reidentify_old_document_after_metadata_loss(self):
        self.exercise(legacy=False, scenario='assetOnlyLostAfter')

    def exercise(self, legacy, scenario=None):
        loader = Path(os.environ.get("FIT_FLUTTER_JS", "/tmp/opencode/fit-offline-flutter-3.35.4.js")).read_text()
        legacy_template = Path(os.environ.get("FIT_LEGACY_SW_TEMPLATE", "/tmp/opencode/fit-offline-legacy-worker-3.35.4.js")).read_text()
        # Use the actual release worker's runtime unchanged. Only substitute the
        # build-specific RESOURCES/CORE with our small static fixture's hashes.
        legacy_template = re.sub(r'const RESOURCES = .*?;', 'const RESOURCES = $$RESOURCES_MAP;', legacy_template, flags=re.S)
        legacy_template = re.sub(r'const CORE = .*?;', 'const CORE = $$CORE_LIST;', legacy_template, flags=re.S)
        # Assert we are testing the real loader, not a fixture that secretly activates SW.
        self.assertIn("_getNewServiceWorker", loader)
        self.assertNotIn("postMessage(\"skipWaiting\")", loader)
        with tempfile.TemporaryDirectory(prefix="fit-update-", dir="/tmp/opencode") as temporary:
            root = Path(temporary)

            def build(version, custom):
                bridge = '<script src="offline_client.js"></script>' if custom else ''
                (root / "index.html").write_text(f'''<!doctype html><html data-build="{version}"><head>
                    <base href="/"><title>{version}</title></head><body>{bridge}
                    <script src="flutter_bootstrap.js" async></script></body></html>''')
                main = f"(window.pairs ||= []).push([document.documentElement.dataset.build, '{version}']);"
                if scenario == 'assetOnlyLostAfter':
                    main = '(window.pairs ||= []).push([document.documentElement.dataset.build, document.documentElement.dataset.build]);'
                (root / "main.dart.js").write_text(main)
                (root / "offline_client.js").write_text(Path("web/offline_client.js").read_text())
                (root / "full-package-only.bin").write_bytes(version.encode() * 1024)
                if version == 'A':
                    (root / 'old-only.js').write_text('// cached A-only bytes')
                else:
                    (root / 'old-only.js').unlink(missing_ok=True)
                config = "_flutter.buildConfig = {builds:[{compileTarget:'dart2js', renderer:'fixture', mainJsPath:'main.dart.js'}]};"
                bootstrap = Path("web/flutter_bootstrap.js").read_text().replace("{{flutter_js}}", loader).replace(
                    "{{flutter_build_config}}", config).replace("{{flutter_service_worker_version}}", "'fixed-token'")
                (root / "flutter_bootstrap.js").write_text(bootstrap)
                if custom:
                    subprocess.run(["docker", "run", "--rm", "--network", "none",
                                    "-v", f"{Path.cwd()}:/workspace:ro", "-v", f"{root}:/fixture",
                                    "-w", "/workspace", "fit-web:guided-verified", "dart",
                                    "tools/generate_offline_package.dart", "/fixture"], check=True, capture_output=True)
                    return json.loads((root / "offline_package.json").read_text())
                resources = {path.name: hashlib.md5(path.read_bytes()).hexdigest()
                             for path in root.iterdir() if path.is_file()}
                resources['/'] = resources['index.html']
                worker = legacy_template.replace('$$RESOURCES_MAP', json.dumps(resources)).replace(
                    '$$CORE_LIST', json.dumps(['index.html', 'flutter_bootstrap.js', 'main.dart.js']))
                (root / "flutter_service_worker.js").write_text(worker)

            a_manifest = build('A', custom=not legacy)
            a_main = (root / 'main.dart.js').read_bytes()
            server = FixtureServer(('127.0.0.1', 0), functools.partial(Handler, directory=root))
            server.fixture_requests = []
            server.core_download_started = threading.Event()
            server.release_core_download = threading.Event()
            server.hold_core_download = False
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                with sync_playwright() as playwright:
                    browser = playwright.chromium.launch()
                    context = browser.new_context(service_workers='allow')
                    first, old = context.new_page(), context.new_page()
                    diagnostics = []
                    first.on('console', lambda message: diagnostics.append(message.text))
                    first.on('pageerror', lambda error: diagnostics.append(str(error)))
                    base = f'http://127.0.0.1:{server.server_port}/'
                    first.goto(base)
                    first.wait_for_function('window.pairs?.length === 1')
                    old.goto(base)
                    old.wait_for_function('window.pairs?.length === 1')
                    self.assertEqual(old.evaluate('pairs'), [['A', 'A']])
                    approved_a = None
                    if not legacy:
                        approved_a = old.evaluate('fitOffline.status()')['packageId']
                    if scenario == 'oldOnly':
                        self.assertEqual(old.evaluate("fetch('old-only.js').then(r => r.text())"), '// cached A-only bytes')
                    old.evaluate("localStorage.setItem('fixture-user-data', 'preserve')")
                    old.evaluate('''async () => {
                        await (await caches.open('fixture-unrelated-push-cache')).put('/push-marker', new Response('preserve'));
                        const db = await new Promise((resolve, reject) => {
                            const request = indexedDB.open('fixture-drift', 1);
                            request.onupgradeneeded = () => request.result.createObjectStore('outbox');
                            request.onsuccess = () => resolve(request.result); request.onerror = reject;
                        });
                        await new Promise((resolve, reject) => {
                            const tx = db.transaction('outbox', 'readwrite');
                            tx.objectStore('outbox').put('pending-user-data', 'sentinel');
                            tx.oncomplete = resolve; tx.onerror = reject;
                        });
                        db.close();
                    }''')
                    def lose_routing_and_restart():
                        first.evaluate("caches.delete('fit-offline-v1:/:routing')")
                        session = context.new_cdp_session(first)
                        session.send('ServiceWorker.enable')
                        session.send('ServiceWorker.stopAllWorkers')
                        session.detach()

                    def execute_main(page):
                        return page.evaluate('''() => new Promise(resolve => {
                            const script = document.createElement('script');
                            script.src = new URL('main.dart.js', document.baseURI).href;
                            script.onload = () => resolve('executed'); script.onerror = () => resolve('blocked');
                            document.body.append(script);
                        })''')

                    def worker_call(page, action, package_id):
                        return page.evaluate('''async ([action, packageId]) => {
                            const registration = await navigator.serviceWorker.getRegistration();
                            return await new Promise(resolve => {
                                const channel = new MessageChannel();
                                const finish = result => {clearTimeout(timer); channel.port1.close(); channel.port2.close(); resolve(result);};
                                const timer = setTimeout(() => finish({errorCode:'fixtureTimeout'}), 5000);
                                channel.port1.onmessage = event => finish(event.data);
                                registration.active.postMessage({protocolVersion:1, action, packageId}, [channel.port2]);
                            });
                        }''', [action, package_id])

                    if scenario == 'lostBefore':
                        old.evaluate("document.querySelector('meta[name=\"fit-offline-shell\"]').remove()")
                        lose_routing_and_restart()
                    old.evaluate('navigator.serviceWorker.getRegistration().then(r => window.fixturePreviousActive = r.active)')
                    server.hold_core_download = scenario == 'oldStatus'
                    b_manifest = build('B', custom=True)
                    assert b_manifest is not None
                    if scenario == 'assetOnlyLostAfter':
                        assert a_manifest is not None
                        self.assertEqual((root / 'main.dart.js').read_bytes(), a_main)
                        self.assertNotEqual(a_manifest['shellId'], b_manifest['shellId'])
                    # Ordinary reload, no manual update()/postMessage('skipWaiting').
                    first.reload()
                    first.wait_for_function('window.pairs?.length === 1')
                    if scenario == 'oldStatus':
                        self.assertTrue(server.core_download_started.wait(timeout=5), 'Successor must actually be installing')
                        for action in ['status', 'prepare', 'cancel'] * 3:
                            result = old.evaluate('([action, packageId]) => fitOffline[action]({packageId})', [action, b_manifest['packageId']])
                            self.assertEqual(result['state'], 'error')
                            self.assertEqual(result['errorCode'], 'reloadRequired')
                            self.assertEqual(result['cachedFiles'], 0)
                        self.assertEqual(server.fixture_requests.count('/full-package-only.bin'), 0)
                        server.release_core_download.set()
                    active_probe = '''async id => {
                        const registration = await navigator.serviceWorker.getRegistration();
                        if (registration.active?.state !== 'activated' || registration.installing || registration.waiting) return false;
                        return await new Promise(resolve => {
                            const channel = new MessageChannel();
                            const finish = value => {clearTimeout(timer); channel.port1.close(); channel.port2.close(); resolve(value);};
                            const timer = setTimeout(() => finish(false), 300);
                            channel.port1.onmessage = e => finish(e.data.packageId === id);
                            registration.active.postMessage({protocolVersion:1, action:'status'}, [channel.port2]);
                        });
                    }'''
                    activation_started = time.monotonic()
                    deadline = activation_started + 60
                    # Do not message the incumbent while waiting for its exit.
                    # A fast status-RPC loop can restart A just as Chromium is
                    # terminating it, leaving B waiting even after skipWaiting.
                    # Observe native registration identity/state only; verify
                    # the newly activated worker's content identity afterwards.
                    native_activation = '''async () => {
                        const r = await navigator.serviceWorker.getRegistration();
                        return r.active !== window.fixturePreviousActive && r.active?.state === 'activated' && !r.installing && !r.waiting;
                    }'''
                    while not old.evaluate(native_activation):
                        if time.monotonic() > deadline:
                            registration = first.evaluate('''async () => {
                                const r = await navigator.serviceWorker.getRegistration();
                                const identify = worker => !worker ? null : new Promise(resolve => {
                                    const channel = new MessageChannel();
                                    const finish = result => {clearTimeout(timer); channel.port1.close(); channel.port2.close(); resolve(result);};
                                    const timer = setTimeout(() => finish('noReply'), 1000);
                                    channel.port1.onmessage = e => finish({packageId:e.data.packageId, state:e.data.state, errorCode:e.data.errorCode});
                                    worker.postMessage({protocolVersion:1, action:'status'}, [channel.port2]);
                                });
                                return {active:r.active?.state, activePackage:await identify(r.active), installing:r.installing?.state,
                                    waiting:r.waiting?.state, waitingPackage:await identify(r.waiting), caches:await caches.keys()};
                            }''')
                            workers = [worker.evaluate("typeof PACKAGE === 'undefined' ? 'legacy' : ({id:PACKAGE.packageId, core:PACKAGE.core})") for worker in context.service_workers]
                            self.fail(f'B did not activate: {registration}; workers={workers}; {diagnostics}')
                        time.sleep(0.05)
                    self.assertTrue(first.evaluate(active_probe, b_manifest['packageId']), 'Activated worker must be B, not merely any active worker')
                    assert_no_worker_debugger(self, browser, context)
                    activation_seconds = time.monotonic() - activation_started
                    if activation_seconds > 10:
                        print(f'Chromium activation waited {activation_seconds:.1f}s for predecessor work', flush=True)
                    if scenario == 'lostBefore':
                        self.assertEqual(execute_main(old), 'blocked')
                        self.assertEqual(old.evaluate('pairs'), [['A', 'A']])
                        self.assertEqual(worker_call(old, 'status', b_manifest['packageId'])['errorCode'], 'reloadRequired')
                        first.reload()
                        first.wait_for_function('window.pairs?.length === 1')
                        self.assertEqual(first.evaluate('pairs'), [['B', 'B']])
                        self.assertEqual(first.evaluate('fitOffline.status()')['state'], 'notReady')
                        browser.close()
                        return
                    if scenario == 'oldOnly':
                        # Stop the real origin as well: page-only network
                        # emulation does not reach an unattached SW target.
                        server.shutdown()
                        server.server_close()
                        context.set_offline(True)
                        result = old.evaluate("fetch('old-only.js').then(async r => ({status:r.status, text:await r.text()}), () => ({status:'networkError'}))")
                        self.assertEqual(result, {'status': 200, 'text': '// cached A-only bytes'})
                        browser.close()
                        return
                    # The unreloaded A document must still execute A bytes after B activation.
                    old.evaluate('''() => new Promise((resolve, reject) => {
                        const script = document.createElement('script');
                        script.src = new URL('main.dart.js', document.baseURI).href;
                        script.onload = resolve; script.onerror = reject; document.body.append(script);
                    })''')
                    pairs = old.evaluate('pairs')
                    if pairs != [['A', 'A'], ['A', 'A']]:
                        routing = old.evaluate('''async () => {
                            const cache = await caches.open('fit-offline-v1:/:routing');
                            return await Promise.all((await cache.keys()).map(async r => [r.url, await (await cache.match(r)).json()]));
                        }''')
                        self.fail(f'Old document mixed versions: {pairs}; routing={routing}; diagnostics={diagnostics}')
                    self.assertEqual(first.evaluate('pairs[0][0]'), first.evaluate('pairs[0][1]'))
                    # A second ordinary reload enters the verified B shell/code pair.
                    first.reload()
                    first.wait_for_function('window.pairs?.length === 1')
                    self.assertEqual(first.evaluate('pairs'), [['B', 'B']])
                    if not legacy or scenario == 'lostAfter':
                        self.assertEqual(server.fixture_requests.count('/full-package-only.bin'), 0)
                        if not legacy:
                            rejected = first.evaluate('(id) => fitOffline.prepare({packageId:id})', approved_a)
                            self.assertEqual(rejected['errorCode'], 'packageChanged')
                        self.assertEqual(first.evaluate('fitOffline.status()')['state'], 'notReady')
                        self.assertFalse(first.evaluate('''async () => {
                            const cache = await caches.open('fit-offline-v1:/:' + (await fitOffline.status()).packageId);
                            return !!await cache.match(new URL('full-package-only.bin', document.baseURI).href);
                        }'''))
                        self.assertEqual(server.fixture_requests.count('/full-package-only.bin'), 0)
                        first.evaluate('(id) => fitOffline.prepare({packageId:id})', b_manifest['packageId'])
                        deadline = time.monotonic() + 5
                        while first.evaluate('fitOffline.status()')['state'] != 'ready':
                            if time.monotonic() > deadline:
                                self.fail('Approved B did not become ready')
                            time.sleep(0.05)
                        self.assertEqual(server.fixture_requests.count('/full-package-only.bin'), 1)
                    if scenario == 'oldStatus':
                        self.assertEqual(old.evaluate('fitOffline.status()')['errorCode'], 'reloadRequired')
                        for action in ['status', 'prepare', 'cancel']:
                            result = worker_call(old, action, b_manifest['packageId'])
                            self.assertEqual(result['state'], 'error')
                            self.assertEqual(result['errorCode'], 'reloadRequired')
                            self.assertEqual(result['cachedFiles'], 0)
                        self.assertEqual(first.evaluate('fitOffline.status()')['state'], 'ready')
                        self.assertEqual(server.fixture_requests.count('/full-package-only.bin'), 1)
                    if scenario in ['lostAfter', 'assetOnlyLostAfter']:
                        lose_routing_and_restart()
                        before = old.evaluate('pairs')
                        self.assertEqual(execute_main(old), 'blocked')
                        self.assertEqual(old.evaluate('pairs'), before)
                        for action in ['status', 'prepare', 'cancel']:
                            self.assertEqual(worker_call(old, action, b_manifest['packageId'])['errorCode'], 'reloadRequired')
                        # New B document can identify itself after metadata loss;
                        # fail-closed must not block a legitimate fresh shell.
                        self.assertEqual(first.evaluate('fitOffline.status()')['state'], 'ready')
                    names = first.evaluate('caches.keys()')
                    self.assertIn('fixture-unrelated-push-cache', names)
                    if legacy:
                        self.assertIn('flutter-app-cache', names)
                    else:
                        assert a_manifest is not None
                        self.assertIn('fit-offline-v1:/:' + a_manifest['packageId'], names)
                    self.assertEqual(old.evaluate("localStorage.getItem('fixture-user-data')"), 'preserve')
                    self.assertEqual(first.evaluate('''async () => {
                        const db = await new Promise(resolve => {
                            const r = indexedDB.open('fixture-drift', 1); r.onsuccess = () => resolve(r.result);
                        });
                        const value = await new Promise(resolve => {
                            const r = db.transaction('outbox').objectStore('outbox').get('sentinel');
                            r.onsuccess = () => resolve(r.result);
                        });
                        db.close(); return value;
                    }'''), 'pending-user-data')
                    browser.close()
            finally:
                server.release_core_download.set()
                server.shutdown()
                server.server_close()
                thread.join(timeout=5)


if __name__ == '__main__':
    with native_service_worker_lifecycle():
        unittest.main()
