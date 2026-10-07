"""Isolated Chromium/real IndexedDB tests; no production network or push vendor."""
import json
import os
from pathlib import Path
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
import time

from playwright.sync_api import sync_playwright

KEY = 'BGsX0fLhLEJH-Lzm5WOkQPJ3A32BLeszoPShOUXYmMKWT-NC4v4af5uO5-tKfA-eFivOM1drMV7Oy7ZAaDe_UfU'
CLIENT = Path(__file__).parents[2] / 'web/push/push-client.js'


class BrowserTests(unittest.TestCase):
    def setUp(self):
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(headless=True, args=['--no-sandbox'])
        self.context = self.browser.new_context()
        self.page = self.context.new_page()
        self.writes = []
        self.offline = False
        self.page.route('https://fit.test/**', self.route)
        self.page.goto('https://fit.test/')
        self.page.evaluate('''() => {
          window.calls = [];
          window.fakeSub = null;
          window.PushManager = function() {};
          window.Notification = {permission: 'default', requestPermission() {
            calls.push(['permission', navigator.userActivation.isActive]);
            this.permission = 'granted'; return Promise.resolve('granted');
          }};
          const reg = {scope: 'https://fit.test/push/', active: {}, getNotifications: async () => [],
            pushManager: {getSubscription: async () => fakeSub, subscribe: async (options) => {
              calls.push(['subscribe']);
              fakeSub = {options, toJSON: () => ({endpoint: 'https://fcm.googleapis.com/test', keys: {p256dh: 'public', auth: 'auth'}}),
                unsubscribe: async () => { calls.push(['unsubscribe']); fakeSub = null; return true; }};
              return fakeSub;
            }}};
          window.reg = reg;
          Object.defineProperty(navigator, 'serviceWorker', {value: {
            register: async (path, options) => {calls.push(['register', path, options.scope]); return reg;},
            getRegistration: async () => reg,
            get ready() { throw Error('must not use Flutter registration'); }
          }});
        }''')
        self.page.add_script_tag(path=str(CLIENT))

    def tearDown(self):
        self.browser.close()
        self.playwright.stop()

    def route(self, route):
        if '/api/push' in route.request.url:
            if self.offline:
                route.abort()
                return
            if route.request.method == 'GET':
                route.fulfill(json={'deliveryAvailable': True, 'reason': 'ready', 'publicKey': KEY})
            else:
                self.writes.append((route.request.method, route.request.url, route.request.post_data))
                route.fulfill(status=202 if route.request.url.endswith('/test') else 204,
                              body='{"queued":true}' if route.request.url.endswith('/test') else '')
        else:
            route.fulfill(content_type='text/html', body='<button id="enable">Enable</button>')

    def enable(self):
        self.page.evaluate('fitPush.status("account-a")')
        self.page.evaluate('(key) => { document.querySelector("button").onclick = () => { window.result = fitPush.enable(key, JSON.stringify({karate:true,training:false,mood:false,operations:false}), "account-a"); }; }', KEY)
        self.page.click('button')
        return json.loads(self.page.evaluate('window.result'))

    def test_optin_requires_button_and_uses_separate_registration(self):
        status = json.loads(self.page.evaluate('fitPush.status("account-a")'))
        self.assertFalse(status['enabled'])
        self.assertNotIn('permission', [call[0] for call in self.page.evaluate('calls')])
        self.assertTrue(self.enable()['enabled'])
        self.assertIn(['permission', True], self.page.evaluate('calls'))
        self.assertIn(['register', '/push/push-worker.js', '/push/'], self.page.evaluate('calls'))
        body = json.loads(self.writes[0][2])
        self.assertTrue(body['categories']['karate'])
        self.assertEqual(body['vapidPublicKey'], KEY)

    def test_offline_logout_persists_off_and_account_switch_does_not_optin(self):
        self.enable()
        self.offline = True
        self.page.evaluate('fitPush.logout()')
        status = json.loads(self.page.evaluate('fitPush.status("account-a")'))
        self.assertFalse(status['enabled'])
        self.assertIn(['unsubscribe'], self.page.evaluate('calls'))
        self.offline = False
        status = json.loads(self.page.evaluate('fitPush.status("account-b")'))
        self.assertFalse(status['enabled'])
        self.assertFalse(any(status['categories'].values()))

    def test_denied_permission_never_subscribes(self):
        self.page.evaluate('Notification.requestPermission = () => Promise.resolve(Notification.permission = "denied")')
        result = self.enable()
        self.assertFalse(result['enabled'])
        self.assertNotIn('subscribe', [call[0] for call in self.page.evaluate('calls')])

    def other_tab(self):
        page = self.page.context.new_page()
        page.route('https://fit.test/**', self.route)
        page.goto('https://fit.test/')
        page.add_script_tag(path=str(CLIENT))
        return page

    def stored_state(self, page):
        return page.evaluate('''() => new Promise((resolve, reject) => {
            const request = indexedDB.open('fit-push-state', 1);
            request.onerror = reject;
            request.onsuccess = () => {
                const db = request.result;
                const tx = db.transaction('settings', 'readonly');
                const result = tx.objectStore('settings').get('active');
                tx.oncomplete = () => { db.close(); resolve(result.result); };
                tx.onerror = reject;
            };
        })''')

    def revoke_without_waiting(self, page):
        page.evaluate('''() => {
            window.logoutDone = false;
            window.logoutResult = fitPush.logout().then(() => { window.logoutDone = true; });
        }''')
        # A prior PushManager operation/Web Lock must not hold up durable revoke.
        page.evaluate('() => Promise.race([window.logoutResult, new Promise(resolve => setTimeout(resolve, 1000))])')
        state = self.stored_state(page)
        self.assertFalse(state['enabled'])
        self.assertTrue(page.evaluate('window.logoutDone'))
        return state

    def test_logout_bypasses_stalled_refresh_lock_and_survives_closed_pwa_offline(self):
        self.enable()
        previous = self.stored_state(self.page)
        self.page.evaluate('''() => {
            reg.pushManager.getSubscription = async () => {
                window.refreshPaused = true;
                return new Promise(() => {});
            };
            window.refreshResult = fitPush.status('account-a').catch(() => null);
        }''')
        self.page.wait_for_function('window.refreshPaused === true')
        other = self.other_tab()
        state = self.revoke_without_waiting(other)
        self.assertNotEqual(state['generation'], previous['generation'])
        # Closing the blocked page destroys its pending work. Reopen without API.
        context = self.page.context
        self.page.close()
        other.close()
        self.offline = True
        restarted = context.new_page()
        restarted.route('https://fit.test/**', self.route)
        restarted.goto('https://fit.test/')
        restarted.add_script_tag(path=str(CLIENT))
        self.assertFalse(self.stored_state(restarted)['enabled'])
        restarted.evaluate('fitPush.logout()')
        self.assertFalse(self.stored_state(restarted)['enabled'])

    def test_late_subscribe_cannot_restore_consent_after_revoke(self):
        self.page.evaluate('fitPush.status("account-a")')
        self.page.evaluate('''key => {
            const subscribe = reg.pushManager.subscribe;
            reg.pushManager.subscribe = async options => {
                window.subscribePaused = true;
                await new Promise(resolve => { window.releaseSubscribe = resolve; });
                return subscribe(options);
            };
            window.enabling = fitPush.enable(key, JSON.stringify({karate:true}), 'account-a').catch(() => 'revoked');
        }''', KEY)
        self.page.wait_for_function('window.subscribePaused === true')
        other = self.other_tab()
        revoked = self.revoke_without_waiting(other)
        self.page.evaluate('window.releaseSubscribe()')
        self.assertEqual(self.page.evaluate('window.enabling'), 'revoked')
        self.assertEqual(self.stored_state(other)['generation'], revoked['generation'])
        self.assertFalse(self.stored_state(other)['enabled'])
        self.assertFalse(any(method == 'PUT' for method, _, _ in self.writes))

    def test_same_tab_logout_bypasses_its_pending_queue(self):
        self.enable()
        self.page.evaluate('''() => {
            reg.pushManager.getSubscription = async () => {
                window.refreshPaused = true;
                return new Promise(() => {});
            };
            window.refreshResult = fitPush.status('account-a');
        }''')
        self.page.wait_for_function('window.refreshPaused === true')
        self.revoke_without_waiting(self.page)

    def test_disable_commits_before_stalled_cleanup(self):
        self.enable()
        self.page.evaluate('''() => {
            reg.pushManager.getSubscription = () => new Promise(() => {});
            window.disabled = false;
            window.disableResult = fitPush.disable().then(() => { window.disabled = true; });
        }''')
        self.page.evaluate('() => Promise.race([window.disableResult, new Promise(resolve => setTimeout(resolve, 1000))])')
        self.assertFalse(self.stored_state(self.page)['enabled'])
        self.assertTrue(self.page.evaluate('window.disabled'))

    def test_enable_waiting_for_web_lock_is_invalidated_by_logout(self):
        self.page.evaluate('fitPush.status("account-a")')
        other = self.other_tab()
        other.evaluate('''() => {
            window.lock = navigator.locks.request('fit-push', async () => {
                window.lockHeld = true;
                await new Promise(resolve => { window.releaseLock = resolve; });
            });
        }''')
        other.wait_for_function('window.lockHeld === true')
        # Delay IndexedDB open callbacks in the enabling tab. Capturing intent
        # with an asynchronous read can otherwise see the post-logout epoch,
        # even though the user's enable gesture happened before logout.
        self.page.evaluate('''() => {
            const open = indexedDB.open.bind(indexedDB);
            window.delayReads = true;
            window.delayedReads = [];
            indexedDB.open = (...args) => {
                const request = open(...args);
                return new Proxy(request, {
                    get: (target, property) => Reflect.get(target, property, target),
                    set: (target, property, callback) => {
                        if (property === 'onsuccess') {
                            target.onsuccess = event => {
                                const invoke = () => callback.call(target, event);
                                if (window.delayReads) window.delayedReads.push(invoke);
                                else invoke();
                            };
                            return true;
                        }
                        return Reflect.set(target, property, callback, target);
                    },
                });
            };
        }''')
        self.page.evaluate('''key => {
            window.enabling = fitPush.enable(key, JSON.stringify({karate:true}), 'account-a').catch(() => 'revoked');
        }''', KEY)
        self.revoke_without_waiting(other)
        self.page.evaluate('''() => {
            window.delayReads = false;
            for (const invoke of window.delayedReads) invoke();
        }''')
        other.evaluate('window.releaseLock()')
        self.assertEqual(self.page.evaluate('window.enabling'), 'revoked')
        self.assertFalse(self.stored_state(other)['enabled'])
        self.assertNotIn('subscribe', [call[0] for call in self.page.evaluate('calls')])

    def test_late_put_response_cannot_restore_consent(self):
        self.enable()
        self.page.evaluate('''() => {
            const original = window.fetch;
            window.fetch = async (url, options) => {
                if (options.method === 'PUT') {
                    window.putPaused = true;
                    await new Promise(resolve => { window.releasePut = resolve; });
                    return new Response(null, {status:204});
                }
                return original(url, options);
            };
            window.saving = fitPush.save(JSON.stringify({karate:false,mood:true})).catch(() => 'revoked');
        }''')
        self.page.wait_for_function('window.putPaused === true')
        other = self.other_tab()
        revoked = self.revoke_without_waiting(other)
        self.page.evaluate('window.releasePut()')
        self.assertEqual(self.page.evaluate('window.saving'), 'revoked')
        self.assertEqual(self.stored_state(other)['generation'], revoked['generation'])
        self.assertFalse(self.stored_state(other)['enabled'])


@unittest.skipUnless(os.environ.get('DISPLAY'), 'Run with xvfb-run for real notification permission')
class RealWorkerTests(unittest.TestCase):
    def test_real_worker_uses_indexeddb_consent_and_logout_closes_notifications(self):
        root = Path(__file__).parents[2] / 'web'
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                scripts = {'/push/push-worker.js': root / 'push/push-worker.js',
                           '/push/push-client.js': root / 'push/push-client.js'}
                body = scripts[self.path].read_bytes() if self.path in scripts else b'<html>Isolated worker test</html>'
                self.send_response(200)
                self.send_header('Content-Type', 'application/javascript' if self.path in scripts else 'text/html')
                self.send_header('Content-Length', str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            def log_message(self, *args): pass
        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        origin = f'http://127.0.0.1:{server.server_port}'
        try:
            with sync_playwright() as playwright:
                browser = playwright.chromium.launch(headless=False, args=['--no-sandbox'])
                context = browser.new_context()
                context.grant_permissions(['notifications'], origin=origin)
                page = context.new_page()
                cdp = context.new_cdp_session(page)
                registrations = []
                worker_errors = []
                cdp.on('ServiceWorker.workerErrorReported', lambda event: worker_errors.append(event))
                cdp.on('ServiceWorker.workerRegistrationUpdated', lambda event: registrations.extend(event['registrations']))
                cdp.send('ServiceWorker.enable')
                page.goto(origin)
                page.add_script_tag(url=origin + '/push/push-client.js')
                page.evaluate('''async () => {
                  await new Promise((resolve, reject) => {
                    const request = indexedDB.open('fit-push-state', 1);
                    request.onupgradeneeded = () => request.result.createObjectStore('settings');
                    request.onsuccess = () => {
                      const db = request.result;
                      const tx = db.transaction('settings', 'readwrite');
                      tx.objectStore('settings').put({enabled:true, installationId:'real', categories:{training:true}}, 'active');
                      tx.oncomplete = () => {db.close(); resolve();};
                      tx.onerror = reject;
                    };
                  });
                  window.pushReg = await navigator.serviceWorker.register('/push/push-worker.js', {scope:'/push/'});
                }''')
                page.wait_for_function('window.pushReg.active?.state === "activated"')
                worker = context.service_workers[0]
                worker.evaluate('self.addEventListener("push", event => { self.testLastPush = event.data?.text(); })')
                permission_before = page.evaluate('Notification.permission')
                self.assertEqual(permission_before, 'granted')
                registration = next(item for item in registrations if item['scopeURL'] == origin + '/push/')
                message = json.dumps({'installationId': 'real', 'category': 'training', 'eventId': 'real:test',
                                      'expiresAt': int(time.time() * 1000) + 60000, 'url': '/workout'})
                cdp.send('ServiceWorker.deliverPushMessage', {'origin': origin, 'registrationId': registration['registrationId'], 'data': message})
                # This Playwright version treats an async wait_for_function
                # predicate's Promise as truthy before inspecting its result.
                # Poll the actual browser condition inside an awaited evaluate.
                body = page.evaluate('''async () => {
                    const deadline = performance.now() + 10000;
                    while (performance.now() < deadline) {
                        const notifications = await window.pushReg.getNotifications();
                        if (notifications.length === 1) return notifications[0].body;
                        await new Promise(resolve => setTimeout(resolve, 50));
                    }
                    return null;
                }''')
                self.assertEqual(body, 'Czas na trening.', {
                    'workerErrors': worker_errors,
                    'permissionBefore': permission_before,
                    'permissionAfter': page.evaluate('Notification.permission'),
                    'workerState': worker.evaluate('async () => ({lastPush: self.testLastPush, consent: await consent()})'),
                })
                self.assertIsNone(page.evaluate('navigator.serviceWorker.controller'))
                page.evaluate('fitPush.logout()')
                self.assertFalse(worker.evaluate('consent()')['enabled'])
                cdp.send('ServiceWorker.deliverPushMessage', {'origin': origin, 'registrationId': registration['registrationId'], 'data': message})
                # Logout waits for consent, not best-effort notification cleanup.
                closed = page.evaluate('''async () => {
                    const deadline = performance.now() + 10000;
                    while (performance.now() < deadline) {
                        if ((await window.pushReg.getNotifications()).length === 0) return true;
                        await new Promise(resolve => setTimeout(resolve, 50));
                    }
                    return false;
                }''')
                self.assertTrue(closed)
                browser.close()
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == '__main__':
    unittest.main()
