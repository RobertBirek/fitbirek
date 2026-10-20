import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../../web/push/push-worker.js', import.meta.url), 'utf8');
test('dynamic activity plain bounded message, never an arbitrary navigation target', async () => {
  const listeners = {};
  let shown;
  const self = { location: { origin: 'https://fit.test' }, addEventListener: (k, v) => { listeners[k] = v; },
    registration: { showNotification: async (title, options) => { shown = {title, ...options}; } } };
  const state = {enabled: true, installationId: 'i', categories: {karate: true}};
  const indexedDB = { open() {
    const r = {};
    queueMicrotask(() => { r.result = {close() {}, transaction() {
      const tx = { objectStore: () => ({get: () => ({result: state})}) };
      queueMicrotask(() => tx.oncomplete()); return tx;
    }}; r.onsuccess(); }); return r;
  }};
  vm.runInNewContext(source, {self, indexedDB, URL});
  async function dispatch(title, body) {
    let promise;
    listeners.push({data: {json: () => ({category: 'karate', installationId: 'i', eventId: 'activity:abc',
      expiresAt: Date.now()+60000, title, body, url: '//evil.test'})}, waitUntil: p => { promise = p; }});
    await promise;
  }
  await dispatch('Basen 🏊', '12:30 · Europe/Warsaw');
  assert.equal(shown.title, 'Basen 🏊');
  assert.equal(shown.body, '12:30 · Europe/Warsaw');
  assert.equal(shown.data.url, 'https://fit.test/today');
  await dispatch('x'.repeat(81), 'bad\nbody');
  assert.equal(shown.title, 'FitBirek');
  assert.equal(shown.body, 'Przypomnienie o karate o 19:30.');
});
