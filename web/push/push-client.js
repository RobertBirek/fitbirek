'use strict';

// Only this worker registration owns PushManager. Never use serviceWorker.ready.
globalThis.fitPush = (() => {
  const empty = () => ({ karate: false, training: false, mood: false, operations: false });
  let registration;
  let currentAccount;
  let lastServer = { deliveryAvailable: false, reason: 'offline' };
  let lastState;
  let pending = Promise.resolve();
  const supported = () => globalThis.isSecureContext && 'serviceWorker' in navigator &&
    'PushManager' in globalThis && 'Notification' in globalThis;
  const installed = () => globalThis.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  const ios = () => /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  function stateDB(mode, operation) {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('fit-push-state', 1);
      request.onupgradeneeded = () => request.result.createObjectStore('settings');
      request.onerror = () => reject(Error('storage'));
      request.onsuccess = () => {
        const db = request.result;
        const tx = db.transaction('settings', mode);
        const result = operation(tx.objectStore('settings'));
        tx.oncomplete = () => { db.close(); resolve(result.result); };
        tx.onerror = tx.onabort = () => { db.close(); reject(Error('storage')); };
      };
    });
  }
  const read = async () => (await stateDB('readonly', (store) => store.get('active'))) || { enabled: false, categories: empty() };

  function updateState(change) {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('fit-push-state', 1);
      request.onupgradeneeded = () => request.result.createObjectStore('settings');
      request.onerror = () => reject(Error('storage'));
      request.onsuccess = () => {
        const db = request.result;
        const tx = db.transaction('settings', 'readwrite', { durability: 'strict' });
        const store = tx.objectStore('settings');
        const previous = store.get('active');
        let next;
        previous.onsuccess = () => {
          try { next = change(previous.result || {}); store.put(next, 'active'); }
          catch (_) { tx.abort(); }
        };
        tx.oncomplete = () => { db.close(); resolve(next); };
        tx.onerror = tx.onabort = () => { db.close(); reject(Error('state_changed')); };
      };
    });
  }

  async function api(path, method = 'GET', body) {
    const csrf = document.cookie.split(';').map((v) => v.trim()).find((v) => v.startsWith('fit_csrf='))?.slice(9);
    const response = await fetch(`/api/push${path}`, {
      method, credentials: 'same-origin', cache: 'no-store', redirect: 'error',
      headers: { 'Content-Type': 'application/json', ...(csrf ? { 'X-CSRF-Token': decodeURIComponent(csrf) } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) {
      const error = Error(`push_api_${response.status}`);
      error.status = response.status;
      throw error;
    }
    return response.status === 204 ? null : response.json();
  }

  async function getRegistration() {
    if (!registration) {
      registration = await navigator.serviceWorker.register('/push/push-worker.js', { scope: '/push/', updateViaCache: 'none' });
    }
    if (!registration.active) {
      await new Promise((resolve, reject) => {
        const worker = registration.installing || registration.waiting;
        if (!worker) return reject(Error('worker'));
        const timer = setTimeout(() => reject(Error('worker_timeout')), 10000);
        const check = () => {
          if (worker.state === 'activated') { clearTimeout(timer); resolve(); }
          if (worker.state === 'redundant') { clearTimeout(timer); reject(Error('worker')); }
        };
        worker.addEventListener('statechange', check);
        check();
      });
    }
    return registration;
  }

  async function revokeConsent() {
    // This transaction must start OUTSIDE pending / Web Locks. No PushManager,
    // network request, or previously queued action may delay local refusal.
    // If storage itself stalls, report failure rather than hanging logout. A
    // late transaction is still allowed to finish: it only revokes consent.
    let timer;
    try {
      const state = await Promise.race([
        updateState((current) => ({ ...current, enabled: false, generation: crypto.randomUUID() })),
        new Promise((_, reject) => { timer = setTimeout(() => reject(Error('storage_timeout')), 2000); }),
      ]);
      lastState = state;
      return state;
    } finally { clearTimeout(timer); }
  }

  async function isRevoked(state) {
    const current = await read();
    return current.generation === state.generation && !current.enabled;
  }

  async function cleanupLocal(state) {
    // Called under the normal work lock, never awaited by logout. This avoids
    // unsubscribing a newer opt-in when an old cleanup eventually acquires it.
    if (!await isRevoked(state)) return;
    if (supported()) {
      try {
        const reg = await navigator.serviceWorker.getRegistration('/push/');
        if (reg && new URL(reg.scope).pathname === '/push/') {
          for (const notification of await reg.getNotifications()) notification.close();
          const subscription = await reg.pushManager.getSubscription();
          if (subscription && await isRevoked(state)) await subscription.unsubscribe();
        }
      } catch (_) { /* Local consent is already durably off, including offline. */ }
    }
  }

  function cleanupLater(state, removeServer = false) {
    void serialized(async () => {
      await cleanupLocal(state);
      if (removeServer && state.installationId && await isRevoked(state)) {
        await api(`/subscriptions/${state.installationId}`, 'DELETE');
      }
    }).catch(() => {});
  }

  async function bindAccount(accountId) {
    currentAccount = accountId;
    let state = await read();
    if (state.accountId !== accountId) {
      const previous = await revokeConsent();
      await cleanupLocal(previous);
      state = await updateState((current) => {
        if (current.generation !== previous.generation) throw Error('state_changed');
        return { accountId, installationId: crypto.randomUUID(), generation: crypto.randomUUID(), enabled: false, categories: empty() };
      });
    }
    return state;
  }

  function keyBytes(value) {
    const raw = atob(value.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - value.length % 4) % 4));
    return Uint8Array.from(raw, (c) => c.charCodeAt(0));
  }
  function matchesKey(subscription, publicKey) {
    const existing = new Uint8Array(subscription.options.applicationServerKey || []);
    const expected = keyBytes(publicKey);
    return existing.length === expected.length && existing.every((v, i) => v === expected[i]);
  }
  async function persistSubscription(state, subscription, publicKey, categories) {
    await requireCurrent(state);
    const json = subscription.toJSON();
    await api(`/subscriptions/${state.installationId}`, 'PUT', {
      endpoint: json.endpoint, keys: json.keys, categories, vapidPublicKey: publicKey,
    });
    await updateState((current) => {
      if (current.generation !== state.generation || current.accountId !== state.accountId) throw Error('state_changed');
      return { ...current, enabled: true, categories, publicKey };
    });
  }

  async function status(accountId) {
    if (!supported()) return { supported: false, installed: installed(), needsInstall: ios() && !installed(), categories: empty() };
    let state = await bindAccount(accountId);
    const base = { supported: true, installed: installed(), needsInstall: ios() && !installed(), permission: Notification.permission };
    let server;
    try { server = await api('/status'); } catch (_) { server = { deliveryAvailable: false, reason: 'offline' }; }
    lastServer = server;
    if (base.needsInstall) return { ...base, server, enabled: false, categories: state.categories };
    const reg = await getRegistration();
    const subscription = await reg.pushManager.getSubscription();
    let needsResubscribe = false;
    if (state.enabled && subscription && server.publicKey) {
      needsResubscribe = !matchesKey(subscription, server.publicKey);
      if (!needsResubscribe && server.deliveryAvailable && Notification.permission === 'granted') {
        // Refresh the session binding after login, and reconcile a restored DB.
        try { await persistSubscription(state, subscription, server.publicKey, state.categories); }
        catch (_) { server = { ...server, deliveryAvailable: false, reason: 'registration_failed' }; }
      }
    }
    if (state.enabled && (!subscription || Notification.permission !== 'granted')) {
      state = await updateState((current) => current.generation === state.generation ? { ...current, enabled: false } : current);
    }
    const latest = await read();
    lastState = latest;
    return { ...base, server, enabled: latest.generation === state.generation && latest.enabled && !!subscription,
      categories: latest.accountId === accountId ? latest.categories : empty(), needsResubscribe };
  }

  function enable(publicKey, categories, accountId) {
    if (!supported() || (ios() && !installed())) return Promise.reject(Error('unsupported'));
    // Critical: invoked synchronously in the button handler, before any await.
    const permission = Notification.permission === 'granted'
      ? Promise.resolve('granted') : Notification.requestPermission();
    return withIntent(async (state) => {
      if (await permission !== 'granted') return status(accountId);
      if (state.accountId !== accountId) throw Error('state_changed');
      await requireCurrent(state);
      const reg = await getRegistration();
      let subscription = await reg.pushManager.getSubscription();
      if (subscription && (!state.publicKey || !matchesKey(subscription, publicKey))) {
        await updateState((current) => {
          if (current.generation !== state.generation) throw Error('state_changed');
          return { ...current, enabled: false };
        });
        await subscription.unsubscribe();
        subscription = await reg.pushManager.getSubscription();
        if (subscription) throw Error('unsubscribe_failed');
      }
      subscription ||= await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: keyBytes(publicKey) });
      await persistSubscription(state, subscription, publicKey, categories);
      return status(accountId);
    });
  }

  async function disable() {
    const state = await revokeConsent();
    cleanupLater(state, true);
    return { supported: supported(), installed: installed(), needsInstall: ios() && !installed(),
      permission: supported() ? Notification.permission : 'default', server: lastServer,
      enabled: false, categories: state.categories || empty() };
  }

  async function requireCurrent(state) {
    const current = await read();
    if (current.generation !== state.generation || current.accountId !== state.accountId) throw Error('state_changed');
  }

  function withIntent(action) {
    // Capture the epoch displayed by the last status SYNCHRONOUSLY. Even an
    // IndexedDB open callback can be delayed until after another tab revokes.
    // Refresh is required before an action on a new/unknown installation.
    const state = lastState;
    if (!state) return Promise.reject(Error('refresh_required'));
    return serialized(async () => {
      await requireCurrent(state);
      return action(state);
    });
  }

  function serialized(action) {
    const result = pending.then(() => navigator.locks ? navigator.locks.request('fit-push', action) : action());
    pending = result.catch(() => {});
    return result;
  }
  const json = (promise) => promise.then((result) => JSON.stringify(result));
  return {
    status: (account) => json(serialized(() => status(account))),
    enable: (key, categories, account) => json(enable(key, JSON.parse(categories), account)),
    save: (categories) => json(withIntent(async (state) => {
      const sub = await (await getRegistration()).pushManager.getSubscription();
      if (!state.enabled || !sub) throw Error('not_subscribed');
      await persistSubscription(state, sub, state.publicKey, JSON.parse(categories));
      return status(currentAccount);
    })),
    disable: () => json(disable()),
    test: () => json(withIntent(async (state) => {
      if (!state.enabled) throw Error('not_subscribed');
      return api(`/subscriptions/${state.installationId}/test`, 'POST');
    })),
    logout: () => json(revokeConsent().then((state) => { cleanupLater(state); return {}; })),
  };
})();
