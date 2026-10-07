/* Register explicitly with scope /push/ when Web Push UI is implemented.
 * No fetch handler, clients.claim(), or Flutter cache interaction.
 */
'use strict';

const routes = new Set(['/today', '/workout', '/settings']);
const messages = Object.freeze({
  karate: 'Przypomnienie o karate o 19:30.',
  training: 'Czas na trening.',
  mood: 'Jak się dziś czujesz? Zapisz samopoczucie.',
  operations: 'Nowy komunikat techniczny FitBirek.',
  test: 'Test Web Push działa na tym urządzeniu.',
});

function consent() {
  return new Promise((resolve) => {
    const request = indexedDB.open('fit-push-state', 1);
    request.onupgradeneeded = () => request.result.createObjectStore('settings');
    request.onerror = () => resolve(null);
    request.onsuccess = () => {
      const db = request.result;
      const tx = db.transaction('settings', 'readonly');
      const read = tx.objectStore('settings').get('active');
      tx.oncomplete = () => { db.close(); resolve(read.result); };
      tx.onerror = tx.onabort = () => { db.close(); resolve(null); };
    };
  });
}

function safeDestination(value) {
  const fallback = `${self.location.origin}/today`;
  if (typeof value !== 'string') return fallback;
  try {
    const url = new URL(value, self.location.origin);
    // Accept only canonical paths or exact absolute URLs, without credentials,
    // query strings, fragments, encoded aliases, or URL normalization tricks.
    if (url.origin !== self.location.origin || !routes.has(url.pathname) ||
        (value !== url.pathname && value !== `${self.location.origin}${url.pathname}`)) {
      return fallback;
    }
    return `${self.location.origin}${url.pathname}`;
  } catch (_) {
    return fallback;
  }
}

self.addEventListener('push', (event) => {
  let payload;
  try {
    payload = event.data?.json();
  } catch (_) {
    payload = null;
  }
  const category = payload?.category;
  let body = Object.prototype.hasOwnProperty.call(messages, category)
    ? messages[category] : 'Masz nowe powiadomienie FitBirek.';
  const incidents = { backup: 'Kopia zapasowa', restore: 'Test odtwarzania', stale_backup: 'Aktualność kopii', api: 'API' };
  if (category === 'operations' && Object.prototype.hasOwnProperty.call(incidents, payload?.incident)) {
    body = `${incidents[payload.incident]}: ${payload.recovery === true ? 'powrót do działania' : 'wykryto problem'}.`;
  }
  const eventId = payload?.eventId;
  const tag = typeof eventId === 'string' && /^[A-Za-z0-9:_-]{1,128}$/.test(eventId)
    ? `fit:${eventId}` : 'fit:notification';
  event.waitUntil((async () => {
    const state = await consent();
    if (!state?.enabled || state.installationId !== payload?.installationId) return;
    if (!Number.isFinite(payload.expiresAt) || payload.expiresAt <= Date.now()) return;
    if (category !== 'test' && !state.categories?.[category]) return;
    await self.registration.showNotification('FitBirek', {
      body,
      tag,
      renotify: false,
      data: { url: safeDestination(payload?.url) },
    });
    const current = await consent();
    if (!current?.enabled || current.installationId !== state.installationId) {
      for (const notification of await self.registration.getNotifications({ tag })) notification.close();
    }
  })());
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = safeDestination(event.notification.data?.url);
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const existing = windows.find((client) => client.url === target);
    if (existing) {
      try {
        await existing.focus();
        return;
      } catch (_) {
        // A tab can disappear between enumeration and focus.
      }
    }
    await self.clients.openWindow(target);
  })());
});
