const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { webcrypto, createHash } = require('node:crypto');
const { MessageChannel } = require('node:worker_threads');

function fixture(base = 'https://fit.test/app/', options = {}) {
  const bodies = options.bodies || { 'index.html': '<html>shell</html>', 'main.dart.js': 'app', 'assets/font.woff2': 'font' };
  const files = Object.entries(bodies).map(([path, body]) => ({path, bytes: Buffer.byteLength(body), sha256: createHash('sha256').update(body).digest('hex')}));
  const manifest = {packageId: options.packageId || 'test', shellId: options.shellId || 'current-shell', files, totalBytes: files.reduce((n, f) => n + f.bytes, 0), core: ['index.html', 'main.dart.js']};
  const handlers = {}, stored = options.stored || new Map();
  let quota = false;
  const cacheFor = (entries, enforceQuota) => ({async match(key) {const response = entries.get(typeof key === 'string' ? key : key.url)?.clone(); if (response && enforceQuota) options.onMatch?.(response); return response;}, async put(key, response) {if (quota && enforceQuota) throw Object.assign(new Error('quota'), {name: 'QuotaExceededError'}); entries.set(String(key), response.clone());}, async delete(key) {return entries.delete(String(key));}, async keys() {return [...entries.keys()].map(url => ({url}));}});
  const metadataEntries = options.metadata || new Map();
  const cache = cacheFor(stored, true), metadata = cacheFor(metadataEntries, false);
  const clientFor = id => ({id, type: options.clientTypes?.[id] || 'window', url: base, postMessage(data, ports) {
    if (options.clientTypes?.[id] && options.clientTypes[id] !== 'window') throw new Error('Do not send DOM protocol to a worker');
    const shellId = Object.hasOwn(options.clientShells || {}, id) ? options.clientShells[id] :
      ('identifiedShell' in options ? options.identifiedShell : manifest.shellId);
    ports[0].postMessage({shellId});
    ports[0].close();
  }});
  const client = clientFor('test-client');
  let fetches = [], override;
  const context = {URL, Response, Request, Headers, AbortController, MessageChannel, setTimeout, clearTimeout, crypto: webcrypto, console,
    caches: {keys: async () => [], open: async (name) => {if (options.names) options.names.add(name); return name.endsWith(':routing') ? metadata : cache;}},
    fetch: async (url, init) => {const path = String(url).replace(base, ''); fetches.push(path); if (override) return override(path, init); return new Response(bodies[path], {headers: {'content-type': path.endsWith('html') ? 'text/html' : 'application/octet-stream'}});},
    self: {registration: {scope: base}, location: new URL(base + 'flutter_service_worker.js'), clients: {get: async id => clientFor(id), matchAll: async () => options.installClients || [], claim: async () => {throw new Error('must not claim');}}, skipWaiting: async () => {options.onSkip?.(stored);}, addEventListener: (name, fn) => handlers[name] = fn}};
  vm.runInNewContext(fs.readFileSync('web/offline_worker.js.template', 'utf8').replace('__FIT_OFFLINE_MANIFEST__', JSON.stringify(manifest)), context);
  async function event(name, extra = {}) {let work; handlers[name]({...extra, waitUntil(p) {work = p;}}); await work;}
  async function message(action, protocolVersion = 1, packageId = manifest.packageId, sourceId = client.id) {let work; const result = new Promise(resolve => handlers.message({source: clientFor(sourceId), data: {protocolVersion, action, packageId}, ports: [{postMessage: resolve}], waitUntil(p) {work = p;}})); const snapshot = await result; return {snapshot, done: work};}
  function request(path, mode = 'navigate', resultingClientId = '', sourceId = client.id, destination = '') {let response; handlers.fetch({clientId: sourceId, resultingClientId, request: {url: new URL(path, base).href, method: 'GET', mode, destination, headers: new Headers()}, respondWith(p) {response = p;}}); return response;}
  return {event, message, request, stored, metadataEntries, manifest, fetches, base, override(fn) {override = fn;}, quota(value) {quota = value;}};
}

test('install provides cold root/index/deep link without fetching the full package', async () => {
  const f = fixture(); await f.event('install');
  assert.deepEqual(f.fetches.sort(), ['index.html', 'main.dart.js']);
  for (const path of ['', 'index.html', 'today', 'workout/session']) assert.equal(await (await f.request(path)).text(), '<html>shell</html>');
});
test('activation is requested only after verified core; integrity failure cannot replace the old worker', async () => {
  let skips = 0;
  const valid = fixture('https://fit.test/app/', {onSkip(stored) {
    skips++;
    assert.ok(stored.has('https://fit.test/app/index.html'));
    assert.ok(stored.has('https://fit.test/app/main.dart.js'));
    assert.ok(stored.has('https://fit.test/app/'));
  }});
  await valid.event('install'); await valid.event('activate');
  assert.equal(skips, 1);
  const broken = fixture('https://fit.test/app/', {onSkip() {skips++;}});
  broken.override(() => new Response('wrong'));
  await assert.rejects(broken.event('install'), /integrity/);
  assert.equal(skips, 1);
});
test('status consumes cache response bodies instead of leaving unread tee streams in the old worker', async () => {
  const responses = [];
  const f = fixture('https://fit.test/app/', {onMatch(response) {responses.push(response);}});
  await f.event('install'); responses.length = 0;
  await f.message('status');
  assert.equal(responses.length, 2);
  assert.ok(responses.every(response => response.bodyUsed));
});
test('API, foreign origin and unknown navigation are not intercepted; missing asset is 404 without HTML', async () => {
  const f = fixture();
  for (const path of ['api/me', '/api/me', 'unknown', 'settings/api/me', 'https://other.test/today']) assert.equal(f.request(path), undefined, path);
  const missing = await f.request('assets/missing.png', 'cors');
  assert.equal(missing.status, 404); assert.equal(await missing.text(), '');
  assert.equal(f.fetches.length, 0);
});
test('prepare is explicit, coalesces and status detects eviction and corrupted bytes', async () => {
  const f = fixture(); await f.event('install');
  const before = await f.message('status'); assert.equal(before.snapshot.state, 'notReady');
  const job = await f.message('prepare'); assert.equal(job.snapshot.state, 'checking'); await job.done;
  assert.equal((await f.message('status')).snapshot.state, 'ready');
  f.stored.set(f.base + 'assets/font.woff2', new Response('evil'));
  assert.equal((await f.message('status')).snapshot.state, 'notReady');
  await (await f.message('prepare')).done;
  f.stored.delete(f.base + 'main.dart.js');
  assert.equal((await f.message('status')).snapshot.state, 'notReady');
});
test('HTML masquerading as a font cannot become ready; retry preserves partial files', async () => {
  const f = fixture(); await f.event('install');
  f.override(() => new Response('<html>wrong</html>', {headers: {'content-type': 'text/html'}}));
  await (await f.message('prepare')).done;
  const {snapshot} = await f.message('status'); assert.equal(snapshot.state, 'error'); assert.equal(snapshot.errorCode, 'integrity');
  assert.equal(f.stored.has(f.base + 'main.dart.js'), true);
});

test('two prepare messages share a job; cancellation and network retry retain verified core', async () => {
  const f = fixture(); await f.event('install');
  let started;
  const fetching = new Promise(resolve => started = resolve);
  f.override((_, init) => new Promise((resolve, reject) => {
    started(); init.signal.addEventListener('abort', () => reject(new Error('aborted')));
  }));
  const first = await f.message('prepare'); await fetching;
  const second = await f.message('prepare');
  assert.equal(f.fetches.filter(path => path === 'assets/font.woff2').length, 1);
  assert.equal(second.snapshot.state, 'downloading');
  const rejected = await f.message('prepare', 1, 'old-package');
  assert.equal(rejected.snapshot.errorCode, 'packageChanged');
  assert.equal((await f.message('status')).snapshot.state, 'downloading');
  assert.equal((await f.message('cancel')).snapshot.state, 'cancelled');
  await first.done;
  assert.equal((await f.message('status')).snapshot.state, 'cancelled');
  f.override(() => {throw new TypeError('offline');});
  await (await f.message('prepare')).done;
  assert.equal((await f.message('status')).snapshot.errorCode, 'network');
  f.override(null);
  await (await f.message('prepare')).done;
  assert.equal((await f.message('status')).snapshot.state, 'ready');
  assert.equal(f.fetches.filter(path => path === 'index.html').length, 1);
});

test('missing or stale consent cannot start downloads in the current package', async () => {
  const f = fixture('https://fit.test/app/', {packageId: 'B'});
  for (const packageId of [null, '', 'A']) {
    const result = await f.message('prepare', 1, packageId);
    await result.done;
    assert.equal(result.snapshot.errorCode, 'packageChanged');
    assert.equal(result.snapshot.packageId, 'B');
    assert.equal(f.fetches.length, 0);
    assert.equal((await f.message('status')).snapshot.state, 'notReady');
  }
});

test('quota fails safely, restart scans partial bytes, protocol is validated', async () => {
  const f = fixture(); await f.event('install'); f.quota(true);
  await (await f.message('prepare')).done;
  assert.equal((await f.message('status')).snapshot.errorCode, 'quota');
  const restarted = fixture(f.base, {stored: f.stored});
  const {snapshot} = await restarted.message('status');
  assert.equal(snapshot.state, 'notReady'); assert.equal(snapshot.cachedFiles, 2);
  assert.equal((await restarted.message('prepare', 2)).snapshot.errorCode, 'protocol');
  assert.equal(restarted.fetches.length, 0);
});

test('package caches are isolated by scope and content id; no unrelated cache cleanup', async () => {
  const names = new Set();
  for (const packageId of ['old', 'new']) {
    const f = fixture('https://fit.test/app/', {names, packageId}); await f.message('status');
  }
  const sub = fixture('https://fit.test/other/', {names}); await sub.message('status');
  assert.equal([...names].filter(name => !name.endsWith(':routing')).length, 3);
  assert.equal([...names].filter(name => name.endsWith(':routing')).length, 2);
  assert.ok([...names].every(name => name.startsWith('fit-offline-v1:')));
});

test('unknown document after routing loss cannot fetch current code or prepare current package', async () => {
  const f = fixture('https://fit.test/app/', {identifiedShell: null});
  await assert.rejects(f.request('main.dart.js', 'cors'), /reloadRequired/);
  for (const action of ['status', 'prepare', 'cancel']) {
    const result = await f.message(action);
    await result.done;
    assert.equal(result.snapshot.state, 'error');
    assert.equal(result.snapshot.errorCode, 'reloadRequired');
  }
  assert.equal(f.fetches.length, 0);
});

test('old document cannot report active package ready or prepare it', async () => {
  const current = fixture();
  await (await current.message('prepare')).done;
  const metadata = new Map();
  const old = {...current.manifest, packageId: 'old', shellId: 'old-shell'};
  metadata.set(current.base + '.fit-offline/client/test-client', new Response(JSON.stringify(old)));
  const f = fixture(current.base, {metadata, stored: current.stored, identifiedShell: 'old-shell'});
  for (const action of ['status', 'prepare', 'cancel']) {
    const result = await f.message(action);
    await result.done;
    assert.equal(result.snapshot.state, 'error');
    assert.equal(result.snapshot.errorCode, 'reloadRequired');
    assert.equal(result.snapshot.cachedFiles, 0);
  }
  assert.equal(f.fetches.length, 0);
});

test('cached old-only asset is selected from document manifest, not current FILES', async () => {
  const a = fixture('https://fit.test/app/', {packageId: 'A', shellId: 'shell-A', bodies: {
    'index.html': '<html>A</html>', 'main.dart.js': 'A', 'old-only.js': 'old bytes',
  }});
  await (await a.message('prepare')).done;
  const metadata = new Map();
  metadata.set(a.base + '.fit-offline/client/test-client', new Response(JSON.stringify(a.manifest)));
  const b = fixture(a.base, {packageId: 'B', stored: a.stored, metadata, identifiedShell: 'shell-A'});
  const response = await b.request('old-only.js', 'cors');
  assert.ok(response, 'old-only request must be handled');
  assert.equal(await response.text(), 'old bytes');
  assert.equal(b.fetches.length, 0);
});

test('old and unknown document messages cannot cancel or change the active download', async () => {
  const f = fixture('https://fit.test/app/', {clientShells: {'old-client': 'old-shell', 'unknown-client': null}});
  await f.event('install');
  f.metadataEntries.set(f.base + '.fit-offline/client/old-client', new Response(JSON.stringify({...f.manifest, packageId: 'old', shellId: 'old-shell'})));
  let started;
  const downloading = new Promise(resolve => started = resolve);
  f.override((_, init) => new Promise((resolve, reject) => {
    started(); init.signal.addEventListener('abort', () => reject(new Error('cancelled')));
  }));
  const job = await f.message('prepare'); await downloading;
  for (const id of ['old-client', 'unknown-client']) {
    for (const action of ['status', 'prepare', 'cancel']) {
      assert.equal((await f.message(action, 1, f.manifest.packageId, id)).snapshot.errorCode, 'reloadRequired');
    }
  }
  assert.equal((await f.message('status')).snapshot.state, 'downloading');
  assert.equal(f.fetches.filter(path => path === 'assets/font.woff2').length, 1);
  await f.message('cancel'); await job.done;
});

test('early identity denial is not cached forever; a recognized cold shell can retry', async () => {
  const options = {identifiedShell: null};
  const f = fixture('https://fit.test/app/', options);
  await assert.rejects(f.request('main.dart.js', 'cors'), /reloadRequired/);
  assert.equal(f.fetches.length, 0);
  options.identifiedShell = 'current-shell';
  assert.equal(await (await f.request('main.dart.js', 'cors')).text(), 'app');
  assert.equal((await f.message('status')).snapshot.state, 'notReady');
});

test('successor install cannot infer an unpinned document version from the global active descriptor', async () => {
  const b = fixture('https://fit.test/app/', {packageId: 'B'});
  const metadata = new Map();
  metadata.set(b.base + '.fit-offline/active', new Response(JSON.stringify(b.manifest)));
  const c = fixture(b.base, {packageId: 'C', metadata, identifiedShell: null,
    installClients: [{id: 'test-client', url: b.base}],
  });
  await c.event('install');
  await assert.rejects(c.request('main.dart.js', 'cors'), /reloadRequired/);
});

test('a versioned resource hint does not become trusted identity for an unknown document', async () => {
  const f = fixture('https://fit.test/app/', {identifiedShell: null});
  await assert.rejects(f.request('main.dart.js?fit-shell=current-shell', 'cors'), /reloadRequired/);
  assert.equal((await f.message('status')).snapshot.errorCode, 'reloadRequired');
  await assert.rejects(f.request('main.dart.js', 'cors'), /reloadRequired/);
  assert.equal(f.fetches.length, 0);
});

test('trusted navigation allows cold bootstrap before the document identity listener is ready', async () => {
  const f = fixture('https://fit.test/app/', {identifiedShell: null});
  await f.event('install');
  assert.equal(await (await f.request('', 'navigate', 'test-client')).text(), '<html>shell</html>');
  assert.equal(await (await f.request('main.dart.js?fit-shell=current-shell', 'cors')).text(), 'app');
  await (await f.message('prepare')).done;
  assert.equal((await f.message('status')).snapshot.state, 'ready');
});

test('verified network/cache bodies are consumed without teeing response streams', async () => {
  let strict = false;
  const f = fixture('https://fit.test/app/', {onMatch(response) {
    if (strict) response.clone = () => {throw new Error('must not tee cached body');};
  }});
  f.override(path => {
    const response = new Response(path === 'index.html' ? '<html>shell</html>' : 'app',
      {headers: {'content-encoding': 'gzip', 'content-length': '1'}});
    response.clone = () => {throw new Error('must not tee network body');};
    return response;
  });
  await f.event('install'); strict = true;
  const response = await f.request('main.dart.js', 'cors');
  assert.equal(await response.text(), 'app');
  assert.equal(response.headers.get('content-encoding'), null);
  assert.equal(response.headers.get('content-length'), '3');
});

test('verified worker script inherits initiator pin and worker fetch survives service-worker restart without DOM messages', async () => {
  for (const kind of ['worker', 'sharedworker']) {
    const options = {clientTypes: {'worker-id': kind}};
    const f = fixture('https://fit.test/app/', options);
    await f.event('install');
    await f.request('main.dart.js', 'same-origin', 'worker-id', 'test-client', kind);
    const restarted = fixture(f.base, {...options, stored: f.stored, metadata: f.metadataEntries});
    const response = await restarted.request('assets/font.woff2', 'cors', '', 'worker-id');
    assert.equal(await response.text(), 'font');
  }
});

test('failed worker script verification and ordinary subresource requests must not create worker pins', async () => {
  const f = fixture();
  f.override(() => new Response('wrong bytes'));
  await assert.rejects(f.request('main.dart.js', 'same-origin', 'bad-worker', 'test-client', 'worker'), /integrity/);
  assert.equal(f.metadataEntries.has(f.base + '.fit-offline/client/bad-worker'), false);
  f.override(null);
  await f.request('main.dart.js', 'cors', 'not-a-worker', 'test-client', 'script');
  assert.equal(f.metadataEntries.has(f.base + '.fit-offline/client/not-a-worker'), false);
});

test('unbound worker/blob cannot identify itself using a forged document handshake or version query', async () => {
  const f = fixture('https://fit.test/app/', {clientTypes: {'blob-id': 'worker'}});
  await assert.rejects(f.request('assets/font.woff2?fit-shell=current-shell', 'cors', '', 'blob-id'), /reloadRequired/);
  assert.equal(f.fetches.length, 0);
});
