(function () {
  'use strict';
  const empty = (state, errorCode = null, message = null) => ({protocolVersion: 1,
    state, packageId: null, totalFiles: 0, cachedFiles: 0, totalBytes: 0,
    cachedBytes: 0, errorCode, message});
  // Reply only with public build identity, never account/storage data. This lets
  // the newly active worker preserve the old document's HTML/JS pair.
  navigator.serviceWorker?.addEventListener('message', event => {
    if (event.data?.type === 'fitOffline.identifyShell' && event.ports?.[0]) {
      event.ports[0].postMessage({shellId: document.querySelector('meta[name="fit-offline-shell"]')?.content || null});
      event.ports[0].close();
    }
  });
  async function call(action, options) {
    if (!window.isSecureContext || !('serviceWorker' in navigator) || !('caches' in window) || !window.MessageChannel) return empty('unsupported');
    let timer, channel, finished = false;
    const timeout = action === 'status' ? 60000 : 5000;
    try {
      return await Promise.race([
        new Promise(resolve => {timer = setTimeout(() => resolve(empty('error', 'timeout', 'Przekroczono czas komunikacji z workerem.')), timeout);}),
        (async () => {
          const base = new URL(document.baseURI);
          const registration = await navigator.serviceWorker.getRegistration(base.href);
          if (finished) return empty('notReady');
          // Never message a push worker or an unrelated app registration.
          if (!registration || registration.scope !== base.href) return empty('notReady');
          const controller = navigator.serviceWorker.controller;
          const worker = controller || registration.active;
          if (!worker || new URL(worker.scriptURL).origin !== base.origin ||
              new URL(worker.scriptURL).pathname !== new URL('flutter_service_worker.js', base).pathname) return empty('notReady');
          // Chromium can restart a retiring incumbent when it receives RPC,
          // resetting its expedited idle termination. Observe the native slots
          // without waking A while a successor is installing/waiting. Do not
          // poll either worker, force activation or report the old package ready.
          if ([registration.installing, registration.waiting].some(candidate =>
              candidate && candidate !== worker && candidate.state !== 'redundant')) {
            return empty('error', 'reloadRequired', 'Trwa aktualizacja aplikacji. Poczekaj na jej zakończenie i przeładuj kartę przed przygotowaniem offline.');
          }
          return new Promise(resolve => {
            channel = new MessageChannel();
            channel.port1.onmessage = event => {
              const value = event.data;
              resolve(value?.protocolVersion === 1 ? value : empty('error', 'protocol', 'Nieobsługiwany protokół workera.'));
            };
            worker.postMessage({protocolVersion: 1, action,
              ...(action === 'prepare' ? {packageId: options?.packageId} : {})}, [channel.port2]);
          });
        })(),
      ]);
    } catch (_) {return empty('error', 'network', 'Komunikacja z workerem nie powiodła się.');}
    finally {finished = true; clearTimeout(timer); channel?.port1.close(); channel?.port2.close();}
  }
  window.fitOffline = Object.freeze({status: () => call('status'), prepare: options => call('prepare', options), cancel: () => call('cancel')});
})();
