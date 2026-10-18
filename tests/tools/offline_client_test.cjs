const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');

function bridge({controller, active, scope = 'https://fit.test/app/', supported = true, timeout = false, registrationDelay = 0, workerResponse, update = {}} = {}) {
  const messages = [], closed = [], payloads = [];
  class Channel {
    constructor() {
      this.port1 = {close: () => closed.push(1)};
      this.port2 = {close: () => closed.push(2), reply: data => this.port1.onmessage({data})};
    }
  }
  function worker(name) {return {scriptURL: `https://fit.test/app/${name}.js`, postMessage(data, ports) {
    messages.push(name); payloads.push(data); if (!timeout) ports[0].reply(workerResponse || {protocolVersion: 1, state: 'notReady', ...data});
  }};}
  const window = {isSecureContext: supported, caches: {}, MessageChannel: Channel};
  const context = {window, document: {baseURI: 'https://fit.test/app/'}, URL, MessageChannel: Channel,
    navigator: {serviceWorker: {addEventListener() {}, controller: controller && worker(controller), getRegistration: async () => {
      if (registrationDelay) await new Promise(resolve => setTimeout(resolve, registrationDelay));
      return {scope, active: active && worker(active), ...update};
    }}},
    setTimeout: (fn) => setTimeout(fn, timeout ? 10 : 1000), clearTimeout};
  vm.runInNewContext(fs.readFileSync('web/offline_client.js', 'utf8'), context);
  return {api: window.fitOffline, messages, closed, payloads};
}
test('unsupported never communicates with a worker', async () => {
  const f = bridge({supported: false}); assert.equal((await f.api.prepare()).state, 'unsupported'); assert.equal(f.messages.length, 0);
});
test('prefers current controller and closes both message ports', async () => {
  const f = bridge({controller: 'flutter_service_worker', active: 'flutter_service_worker'});
  assert.equal((await f.api.status()).state, 'notReady'); assert.deepEqual(f.messages, ['flutter_service_worker']); assert.deepEqual(f.closed, [1, 2]);
});
test('first visit uses exact-scope active worker; unrelated registration is rejected', async () => {
  const f = bridge({active: 'flutter_service_worker'}); await f.api.prepare(); assert.equal(f.messages.length, 1);
  const wrong = bridge({active: 'flutter_service_worker', scope: 'https://fit.test/app/push/'});
  assert.equal((await wrong.api.status()).state, 'notReady'); assert.equal(wrong.messages.length, 0);
});
test('missing worker and wrong controller do not claim readiness', async () => {
  assert.equal((await bridge().api.status()).state, 'notReady');
  const f = bridge({controller: 'push/push-worker', active: 'flutter_service_worker'});
  assert.equal((await f.api.prepare()).state, 'notReady'); assert.equal(f.messages.length, 0);
  const wrongActive = bridge({active: 'push/push-worker'});
  assert.equal((await wrongActive.api.prepare()).state, 'notReady'); assert.equal(wrongActive.messages.length, 0);
});
test('unresponsive worker returns bounded timeout and closes channel', async () => {
  const f = bridge({active: 'flutter_service_worker', timeout: true});
  assert.equal((await f.api.status()).errorCode, 'timeout'); assert.deepEqual(f.closed, [1, 2]);
});
test('late registration after timeout cannot start a forgotten prepare job', async () => {
  const f = bridge({active: 'flutter_service_worker', timeout: true, registrationDelay: 30});
  assert.equal((await f.api.prepare()).errorCode, 'timeout');
  await new Promise(resolve => setTimeout(resolve, 50));
  assert.equal(f.messages.length, 0);
});
test('prepare forwards the exact package consent, not a fresh implicit status', async () => {
  const f = bridge({active: 'flutter_service_worker'});
  await f.api.prepare({packageId: 'approved-A'});
  assert.equal(f.payloads[0].packageId, 'approved-A');
  assert.equal(f.payloads[0].action, 'prepare');
  assert.equal(f.payloads.length, 1);
});
test('reloadRequired is passed to UI without reporting ready or starting another operation', async () => {
  const f = bridge({active: 'flutter_service_worker', workerResponse: {protocolVersion: 1,
    state: 'error', errorCode: 'reloadRequired', message: 'Przeładuj kartę.', cachedFiles: 0, cachedBytes: 0}});
  const status = await f.api.status();
  assert.equal(status.state, 'error'); assert.equal(status.errorCode, 'reloadRequired');
  assert.equal(status.message, 'Przeładuj kartę.'); assert.equal(status.cachedFiles, 0);
  assert.equal(f.payloads.length, 1); assert.equal(f.payloads[0].action, 'status');
});
test('installing or waiting successor never wakes the incumbent, downloads or claims readiness', async () => {
  for (const slot of ['installing', 'waiting']) {
    const update = {[slot]: {state: slot === 'installing' ? 'installing' : 'installed'}};
    const f = bridge({controller: 'flutter_service_worker', active: 'flutter_service_worker', update});
    for (const action of ['status', 'prepare', 'cancel']) {
      const result = await f.api[action]({packageId: 'approved-A'});
      assert.equal(result.state, 'error'); assert.equal(result.errorCode, 'reloadRequired');
      assert.equal(result.cachedFiles, 0); assert.equal(result.cachedBytes, 0);
    }
    assert.equal(f.messages.length, 0);
    assert.equal(f.closed.length, 0, 'No MessageChannel is opened during handover');
  }
});
test('native update guard is temporary; same bridge resumes after successor activates', async () => {
  const update = {waiting: {state: 'installed'}};
  const f = bridge({controller: 'flutter_service_worker', active: 'flutter_service_worker', update});
  for (let i = 0; i < 10; i++) assert.equal((await f.api.status()).errorCode, 'reloadRequired');
  assert.equal(f.messages.length, 0);
  update.waiting = null;
  assert.equal((await f.api.status()).state, 'notReady'); assert.equal(f.messages.length, 1);
});
