"""Real dedicated/shared/nested workers and locked Drift SQLite, no Flutter build."""
import functools
import hashlib
import http.server
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import time
import unittest
import uuid

from playwright.sync_api import sync_playwright

from offline_browser_driver import native_service_worker_lifecycle, assert_no_worker_debugger


WORKER = '''
const VERSION = __VERSION__;
async function handle(event, port) {
  if (!event.data?.kind) return;
  const {id, kind, url} = event.data;
  try {
    if (kind === 'nested') {
      if (typeof Worker === 'undefined') {port.postMessage({id,nestedUnsupported:true});return;}
      const child = new Worker(new URL('probe-worker.js', self.location.href));
      child.onmessage = e => {port.postMessage({...e.data, id}); child.terminate();};
      child.onerror = () => port.postMessage({id, error:'nested worker error'});
      child.postMessage({id,kind:'fetch',url}); return;
    }
    const response = await fetch(url);
    const bytes = await response.arrayBuffer();
    const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)), b=>b.toString(16).padStart(2,'0')).join('');
    port.postMessage({id, version:VERSION, status:response.status, bytes:bytes.byteLength,
      text: url.endsWith('version.txt') ? new TextDecoder().decode(bytes) : null, hash,
      validWasm:kind==='wasm' ? WebAssembly.validate(bytes) : null});
  } catch(error) {port.postMessage({id, error:String(error)});}
}
if (typeof SharedWorkerGlobalScope !== 'undefined' && self instanceof SharedWorkerGlobalScope) {
  self.onconnect = e => {const port=e.ports[0];port.onmessage=e=>handle(e,port);port.start();};
} else self.onmessage = e=>handle(e,self);
'''


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def log_message(self, format, *args):
        pass


class OfflineWorkersBrowserTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.compilation = tempfile.TemporaryDirectory(prefix='fit-drift-probe-')
        cls.compiled = Path(cls.compilation.name)
        subprocess.run(['docker', 'run', '--rm', '--network', 'none',
                        '-v', f'{Path.cwd()}:/workspace:ro', '-v', f'{cls.compiled}:/fixture',
                        '-w', '/workspace', 'fit-web:guided-verified', 'dart', 'compile', 'js',
                        '--no-source-maps', '-O1', 'tests/tools/offline_drift_probe.dart',
                        '-o', '/fixture/drift-probe.js'], check=True)
        # Existing Flutter 3.35.4 release artifact, no image build or runtime start.
        container = 'fit-canvaskit-fixture-' + uuid.uuid4().hex[:12]
        subprocess.run(['docker', 'create', '--name', container, '--network', 'none',
                        'fit-web:candidate-1.14.0-27'], check=True, capture_output=True)
        try:
            subprocess.run(['docker', 'cp', f'{container}:/usr/share/nginx/html/canvaskit/canvaskit.wasm',
                            str(cls.compiled / 'canvaskit.wasm')], check=True)
        finally:
            subprocess.run(['docker', 'rm', container], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.compilation.cleanup()

    def test_file_workers_and_fresh_drift_fetch_offline_after_sw_restart(self):
        self.exercise(update=False)

    def test_a_workers_keep_a_bytes_while_b_workers_use_b_after_update_and_restart(self):
        self.exercise(update=True)

    def test_worker_pins_lost_to_eviction_fail_closed_after_restart_without_window_guess(self):
        self.exercise(update=True, evict=True)

    def exercise(self, update, evict=False):
        with tempfile.TemporaryDirectory(prefix='fit-worker-cache-') as directory:
            root = Path(directory)
            for name in ['sqlite3.wasm', 'drift_worker.dart.js', 'offline_client.js']:
                shutil.copyfile(Path('web') / name, root / name)
            shutil.copyfile(self.compiled / 'drift-probe.js', root / 'drift-probe.js')
            (root / 'canvaskit').mkdir()
            shutil.copyfile(self.compiled / 'canvaskit.wasm', root / 'canvaskit/canvaskit.wasm')
            canvas_hash = hashlib.sha256((root / 'canvaskit/canvaskit.wasm').read_bytes()).hexdigest()
            original_worker = hashlib.sha256((root / 'drift_worker.dart.js').read_bytes()).hexdigest()
            self.assertEqual(original_worker, '6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610')
            sqlite_hash = hashlib.sha256((root / 'sqlite3.wasm').read_bytes()).hexdigest()

            def build(version):
                (root / 'index.html').write_text(f'''<!doctype html><html data-build="{version}"><head><base href="/"></head>
                    <body><script src="offline_client.js"></script><script src="drift-probe.js"></script>
                    <script>navigator.serviceWorker.register('flutter_service_worker.js?v=fixed');</script></body></html>''')
                (root / 'main.dart.js').write_text(f'// executable {version}')
                (root / 'flutter_bootstrap.js').write_text('// fixture bootstrap')
                (root / 'probe-worker.js').write_text(WORKER.replace('__VERSION__', json.dumps(version)))
                (root / 'version.txt').write_text(version)
                subprocess.run(['docker', 'run', '--rm', '--network', 'none',
                                '-v', f'{Path.cwd()}:/workspace:ro', '-v', f'{root}:/fixture',
                                '-w', '/workspace', 'fit-web:guided-verified', 'dart',
                                'tools/generate_offline_package.dart', '/fixture'], check=True, capture_output=True)
                # Test-only audit: prove SQLite was actually requested by a
                # fresh upstream Drift worker, not by a fallback on the window.
                sw = root / 'flutter_service_worker.js'
                sw.write_text('''self.addEventListener('fetch', event => {
                    if (new URL(event.request.url).pathname !== '/sqlite3.wasm') return;
                    event.waitUntil((async()=>{
                        const client = event.clientId ? await self.clients.get(event.clientId) : null;
                        const cache = await caches.open('fixture-worker-audit');
                        await cache.put(new URL('.fixture-audit/'+crypto.randomUUID(), self.registration.scope).href,
                          new Response(JSON.stringify({clientId:event.clientId,type:client?.type,url:client?.url})));
                    })());
                });\n''' + sw.read_text())
                if os.environ.get('FIT_WORKER_TRACE') == '1':
                    sw = root / 'flutter_service_worker.js'
                    sw.write_text("self.addEventListener('fetch',e=>console.log('WORKER_FETCH '+JSON.stringify({url:e.request.url,client:e.clientId,resulting:e.resultingClientId,destination:e.request.destination})));\n" + sw.read_text())
                return json.loads((root / 'offline_package.json').read_text())

            a_manifest = build('A')
            server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(Handler, directory=root))
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                with sync_playwright() as playwright:
                    browser = playwright.chromium.launch()
                    context = browser.new_context(service_workers='allow')
                    if os.environ.get('FIT_WORKER_TRACE') == '1':
                        context.on('console', lambda message: print(message.text, flush=True))
                    a = context.new_page()
                    base = f'http://127.0.0.1:{server.server_port}/'
                    a.goto(base)
                    a.evaluate('navigator.serviceWorker.ready')
                    a.reload()

                    def ready(page, manifest):
                        self.assertNotEqual(page.evaluate('(id)=>fitOffline.prepare({packageId:id})', manifest['packageId'])['state'], 'error')
                        deadline = time.monotonic() + 30
                        while page.evaluate('fitOffline.status()')['state'] != 'ready':
                            if time.monotonic() > deadline:
                                self.fail('Worker fixture package preparation timed out')
                            time.sleep(.05)

                    def start_workers(page, label):
                        page.evaluate('''label => {
                            window.fixtureWorkers = {
                              dedicated:new Worker('probe-worker.js'),
                              shared:new SharedWorker('probe-worker.js', {name:'fixture-'+label})
                            };
                            window.workerFetch = (which, url, kind='fetch') => new Promise((resolve,reject)=>{
                              const worker=fixtureWorkers[which], port=worker.port||worker, id=crypto.randomUUID();
                              const timer=setTimeout(()=>{port.removeEventListener('message',listen);reject(Error('worker request timeout'));},5000);
                              const listen=e=>{if(e.data.id!==id)return;clearTimeout(timer);port.removeEventListener('message',listen);resolve(e.data);};
                              port.addEventListener('message',listen);port.start?.();port.postMessage({id,kind,url:new URL(url,document.baseURI).href});
                            });
                        }''', label)

                    def worker_fetch(page, which, url='version.txt', kind='fetch'):
                        return page.evaluate('([which,url,kind])=>workerFetch(which,url,kind)', [which, url, kind])

                    def stop_sw():
                        session = context.new_cdp_session(a)
                        session.send('ServiceWorker.enable')
                        session.send('ServiceWorker.stopAllWorkers')
                        session.detach()

                    ready(a, a_manifest)
                    start_workers(a, 'A')
                    for which in ['dedicated', 'shared']:
                        self.assertEqual(worker_fetch(a, which)['text'], 'A')
                    # Force the remote Drift executor to run SQL from the worker.
                    # It must not silently fall back to inMemory on the document.
                    sql = json.loads(a.evaluate('fitDriftProbe("online")'))
                    self.assertEqual(sql['answer'], 42)
                    self.assertNotEqual(sql['implementation'], 'inMemory')
                    self.assertNotIn('workerError', sql['missingFeatures'])
                    b = None
                    if update:
                        a.evaluate('navigator.serviceWorker.getRegistration().then(r=>window.previousWorker=r.active)')
                        b_manifest = build('B')
                        b = context.new_page()
                        b.goto(base)
                        deadline = time.monotonic() + 60
                        while not a.evaluate("navigator.serviceWorker.getRegistration().then(r=>r.active!==window.previousWorker && r.active?.state==='activated' && !r.waiting && !r.installing)"):
                            if time.monotonic() > deadline:
                                self.fail('Successor activation timed out')
                            time.sleep(.05)
                        b.reload()
                        self.assertEqual(b.evaluate('document.documentElement.dataset.build'), 'B')
                        ready(b, b_manifest)
                        start_workers(b, 'B')
                        for which in ['dedicated', 'shared']:
                            self.assertEqual(worker_fetch(b, which)['text'], 'B')
                    assert_no_worker_debugger(self, browser, context)
                    stop_sw()
                    server.shutdown()
                    server.server_close()
                    for page, version in [(a, 'A')] + ([(b, 'B')] if b else []):
                        for which in ['dedicated', 'shared']:
                            result = worker_fetch(page, which)
                            self.assertEqual(result.get('version'), version, result)
                            self.assertEqual(result.get('text'), version, result)
                            wasm = worker_fetch(page, which, 'sqlite3.wasm')
                            self.assertEqual(wasm.get('hash'), sqlite_hash, wasm)
                            canvas = worker_fetch(page, which, 'canvaskit/canvaskit.wasm', kind='wasm')
                            self.assertEqual(canvas.get('hash'), canvas_hash, canvas)
                            self.assertTrue(canvas.get('validWasm'), canvas)
                            # Chromium can omit clientId entirely for fetches
                            # from nested workers. There is no safe document
                            # association in that case: denial is intentional.
                            nested = worker_fetch(page, which, kind='nested')
                            if nested.get('nestedUnsupported'):
                                self.assertEqual(which, 'shared', nested)
                            elif 'error' in nested:
                                self.assertIn('Failed to fetch', nested['error'], nested)
                            else:
                                self.assertEqual(nested.get('text'), version, nested)
                    current = b or a
                    # A new actual Drift connection starts only after origin stop
                    # and SW restart, including its compatibility helper workers.
                    sql_offline = json.loads(current.evaluate('fitDriftProbe("offline")'))
                    self.assertEqual(sql_offline['answer'], 42)
                    self.assertNotEqual(sql_offline['implementation'], 'inMemory')
                    self.assertNotIn('workerError', sql_offline['missingFeatures'])
                    audit = current.evaluate('''async () => {
                        const cache=await caches.open('fixture-worker-audit');
                        return await Promise.all((await cache.keys()).map(async key=>(await cache.match(key)).json()));
                    }''')
                    self.assertTrue(any(item.get('clientId') and item.get('type') in ['worker','sharedworker'] and
                                        'drift_worker.dart.js?fixture=offline' in item.get('url','')
                                        for item in audit), audit)
                    dedicated_sql = json.loads(current.evaluate('fitDriftProbe("dedicated-offline")'))
                    self.assertEqual(dedicated_sql['answer'], 42)
                    self.assertEqual(dedicated_sql['implementation'], 'unsafeIndexedDb')
                    self.assertNotIn('workerError', dedicated_sql['missingFeatures'])
                    dedicated_audit = current.evaluate('''async () => {
                        const cache=await caches.open('fixture-worker-audit');
                        return await Promise.all((await cache.keys()).map(async key=>(await cache.match(key)).json()));
                    }''')
                    self.assertTrue(any(item.get('clientId') and item.get('type') == 'worker' and
                                        'drift_worker.dart.js?fixture=dedicated-offline' in item.get('url','')
                                        for item in dedicated_audit), dedicated_audit)
                    blob = current.evaluate('''code => new Promise(resolve=>{
                        const worker=new Worker(URL.createObjectURL(new Blob([code.replace('__VERSION__','"untrusted"')],{type:'application/javascript'})));
                        const timer=setTimeout(()=>resolve({error:'fixture timeout'}),3000);
                        worker.onmessage=e=>{clearTimeout(timer);resolve(e.data);worker.terminate();};
                        worker.postMessage({id:'blob',kind:'fetch',url:new URL('sqlite3.wasm',document.baseURI).href});
                    })''', WORKER)
                    self.assertIn('Failed to fetch', blob.get('error', ''), blob)
                    if evict:
                        current.evaluate("caches.delete('fit-offline-v1:/:routing')")
                        stop_sw()
                        for page in [a, b]:
                            for which in ['dedicated', 'shared']:
                                denied = worker_fetch(page, which)
                                self.assertIn('Failed to fetch', denied.get('error',''), denied)
                        # A current window can identify itself after eviction;
                        # that must not also rebind unrelated worker clients.
                        self.assertEqual(current.evaluate("fetch('version.txt').then(r=>r.text())"), 'B')
                        denied_again = worker_fetch(a, 'dedicated')
                        self.assertIn('Failed to fetch', denied_again.get('error',''), denied_again)
                    self.assertEqual(hashlib.sha256((root / 'drift_worker.dart.js').read_bytes()).hexdigest(), original_worker)
                    browser.close()
            finally:
                server.shutdown()
                server.server_close()
                thread.join(timeout=5)


if __name__ == '__main__':
    with native_service_worker_lifecycle():
        unittest.main()
