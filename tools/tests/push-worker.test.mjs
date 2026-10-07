import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../../web/push/push-worker.js', import.meta.url), 'utf8');

function worker(windows = [], consent = { enabled: true, installationId: 'installation', categories: { training: true, operations: true } }) {
  const listeners = new Map();
  const shown = [];
  const opened = [];
  const self = {
    location: { origin: 'https://fit.birek.online' },
    addEventListener: (name, handler) => listeners.set(name, handler),
    registration: { showNotification: async (title, options) => shown.push({ title, options }) },
    clients: {
      matchAll: async (options) => {
        assert.deepEqual(JSON.parse(JSON.stringify(options)), { type: 'window', includeUncontrolled: true });
        return windows;
      },
      openWindow: async (url) => opened.push(url),
    },
  };
  const indexedDB = { open() {
    const request = {};
    queueMicrotask(() => {
      request.result = { close() {}, transaction() {
        const tx = { objectStore: () => ({ get: () => ({ result: consent }) }) };
        queueMicrotask(() => tx.oncomplete());
        return tx;
      } };
      request.onsuccess();
    });
    return request;
  } };
  vm.runInNewContext(source, { self, URL, indexedDB });
  async function dispatch(name, event) {
    let pending;
    listeners.get(name)({ ...event, waitUntil: (promise) => { pending = promise; } });
    await pending;
  }
  return { listeners, shown, opened, dispatch };
}

test('worker does not intercept fetch or claim Flutter clients', () => {
  assert.deepEqual([...worker().listeners.keys()].sort(), ['notificationclick', 'push']);
});

test('push displays bounded notification with safe destination and dedup tag', async () => {
  const w = worker();
  await w.dispatch('push', { data: { json: () => ({ installationId: 'installation', expiresAt: Date.now() + 60000, category: 'training', eventId: 'training:2026-09-10', url: '/workout' }) } });
  assert.equal(w.shown[0].title, 'FitBirek');
  assert.equal(w.shown[0].options.data.url, 'https://fit.birek.online/workout');
  assert.equal(w.shown[0].options.tag, 'fit:training:2026-09-10');
  assert.equal(w.shown[0].options.renotify, false);
});

test('malformed or empty payload is ignored without a matching installation', async () => {
  for (const data of [undefined, { json: () => { throw Error('invalid'); } }, { json: () => null }]) {
    const w = worker();
    await w.dispatch('push', { data });
    assert.equal(w.shown.length, 0);
  }
});

test('offline logout suppresses already queued pushes', async () => {
  const w = worker([], { enabled: false, installationId: 'installation' });
  await w.dispatch('push', { data: { json: () => ({ installationId: 'installation', category: 'test' }) } });
  assert.equal(w.shown.length, 0);
});

test('operations recovery identifies the check without exposing raw server text', async () => {
  const w = worker();
  await w.dispatch('push', { data: { json: () => ({ installationId: 'installation', expiresAt: Date.now() + 60000, category: 'operations', incident: 'api', recovery: true, body: 'secret' }) } });
  assert.equal(w.shown[0].options.body, 'API: powrót do działania.');
});

test('expired provider delivery is suppressed at the device', async () => {
  const w = worker();
  await w.dispatch('push', { data: { json: () => ({ installationId: 'installation', expiresAt: Date.now() - 1, category: 'training' }) } });
  assert.equal(w.shown.length, 0);
});

test('notification click revalidates URLs against exact same-origin route allowlist', async () => {
  for (const url of ['https://evil.example/', '//evil.example/', '/api/auth/logout', '/today?next=https://evil.example', '/today#bad', 'javascript:alert(1)', '/workout/session', 'https://user@fit.birek.online/today', '/%74oday']) {
    const w = worker();
    let closed = false;
    await w.dispatch('notificationclick', { notification: { data: { url }, close: () => { closed = true; } } });
    assert.equal(closed, true);
    assert.deepEqual(w.opened, ['https://fit.birek.online/today']);
  }
});

test('click focuses existing exact target, including root Flutter worker clients', async () => {
  let focused = false;
  const w = worker([{ url: 'https://fit.birek.online/settings', focus: async () => { focused = true; } }]);
  await w.dispatch('notificationclick', { notification: { data: { url: '/settings' }, close() {} } });
  assert.equal(focused, true);
  assert.deepEqual(w.opened, []);
});

test('click does not navigate an unrelated active workout tab', async () => {
  const w = worker([{ url: 'https://fit.birek.online/workout/session', focus: () => assert.fail('wrong tab') }]);
  await w.dispatch('notificationclick', { notification: { data: { url: '/today' }, close() {} } });
  assert.deepEqual(w.opened, ['https://fit.birek.online/today']);
});
