"""Real Chromium/SW fixture, no Flutter build or production connection.

Run with the existing Python Playwright installation and Chromium:
python3 tests/tools/offline_browser_test.py (loopback fixture only).
"""
import functools
import hashlib
import http.server
import json
from pathlib import Path
import tempfile
import threading
import time
import unittest

from playwright.sync_api import sync_playwright


class OfflineBrowserTest(unittest.TestCase):
    def test_first_visit_prepare_origin_stopped_and_cache_loss(self):
        self.exercise(prepare=True)

    def test_first_visit_core_cold_root_without_prepare(self):
        self.exercise(prepare=False)

    def exercise(self, prepare):
        with tempfile.TemporaryDirectory(prefix="fit-offline-browser-") as temporary:
            root = Path(temporary)
            app = root / "app"
            app.mkdir()
            shell = b'''<!doctype html><base href="/app/"><title>Offline fixture</title>
                <meta name="fit-offline-shell" content="fixture-shell">
                <script src="offline_client.js"></script>
                <script>navigator.serviceWorker.register('flutter_service_worker.js?v=fixture');</script>
                <body>Fixture shell</body>'''
            bodies = {"index.html": shell,
                      "offline_client.js": Path("web/offline_client.js").read_bytes(),
                      "assets/unvisited.woff2": b"fixture font bytes"}
            manifest = {"packageId": "browser-fixture", "shellId": "fixture-shell", "totalBytes": sum(map(len, bodies.values())),
                        "core": ["index.html", "offline_client.js"], "files": [
                            {"path": path, "bytes": len(body), "sha256": hashlib.sha256(body).hexdigest()}
                            for path, body in bodies.items()]}
            for path, body in bodies.items():
                file = app / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_bytes(body)
            (app / "flutter_service_worker.js").write_text(
                Path("web/offline_worker.js.template").read_text().replace(
                    "__FIT_OFFLINE_MANIFEST__", json.dumps(manifest)))
            handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=root)
            server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            stopped = False
            try:
                with sync_playwright() as playwright:
                    browser = playwright.chromium.launch()
                    context = browser.new_context(service_workers="allow")
                    page = context.new_page()
                    base = f"http://127.0.0.1:{server.server_port}/app/"
                    page.goto(base)
                    page.evaluate("navigator.serviceWorker.ready")
                    before = page.evaluate("fitOffline.status()")
                    self.assertEqual(before["state"], "notReady")
                    self.assertEqual(before["cachedFiles"], 2)
                    self.assertTrue(page.evaluate("navigator.serviceWorker.controller === null"))
                    if prepare:
                        self.assertNotIn(page.evaluate("fitOffline.prepare({packageId: 'browser-fixture'})")["state"], ["ready", "error"])
                        deadline = time.monotonic() + 5
                        while page.evaluate("fitOffline.status()")["state"] != "ready":
                            if time.monotonic() > deadline:
                                self.fail("Fixture did not become ready")
                            time.sleep(0.05)
                        self.assertEqual(page.evaluate("fitOffline.status()")["cachedBytes"], manifest["totalBytes"])
                    server.shutdown()
                    server.server_close()
                    stopped = True
                    for route in ["", "today", "workout/session"]:
                        page.goto(base + route)
                        self.assertEqual(page.title(), "Offline fixture")
                    if prepare:
                        self.assertEqual(page.evaluate("fetch('assets/unvisited.woff2').then(r => r.text())"), "fixture font bytes")
                    self.assertTrue(page.evaluate("fetch('api/me').then(() => false, () => true)"))
                    self.assertEqual(page.evaluate("fetch('assets/missing.png').then(r => r.status)"), 404)
                    page.evaluate("""async () => {
                        const cache = await caches.open('fit-offline-v1:/app/:browser-fixture');
                        await cache.delete(new URL('assets/unvisited.woff2', document.baseURI).href);
                    }""")
                    self.assertEqual(page.evaluate("fitOffline.status()")["state"], "notReady")
                    browser.close()
            finally:
                if not stopped:
                    server.shutdown()
                    server.server_close()
                thread.join(timeout=5)


if __name__ == "__main__":
    unittest.main()
