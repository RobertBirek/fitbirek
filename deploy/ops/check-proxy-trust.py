"""Run inside the API image with its real environment; no DB or HTTP writes.

docker exec -i fit-api-1 python - < deploy/ops/check-proxy-trust.py
"""
import unittest

from starlette.requests import Request
from uvicorn import Config
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware


class ProxyTrustTests(unittest.IsolatedAsyncioTestCase):
    async def client_seen(self, peer, forwarded):
        observed = {}

        async def app(scope, receive, send):
            request = Request(scope)
            observed.update(client=request.client.host, scheme=request.url.scheme)

        config = Config(app)
        self.assertTrue(config.proxy_headers)
        middleware = ProxyHeadersMiddleware(app, trusted_hosts=config.forwarded_allow_ips)
        await middleware(
            {"type": "http", "method": "GET", "path": "/", "query_string": b"",
             "server": ("fit-api", 8000), "client": (peer, 12345), "scheme": "http",
             "headers": [(b"x-forwarded-for", forwarded.encode()),
                         (b"x-forwarded-proto", b"https")]},
            None, None,
        )
        return observed

    def test_exact_trust(self):
        self.assertEqual(Config("app.main:app").forwarded_allow_ips, "172.26.0.4")

    async def test_caddy_preserves_distinct_clients(self):
        for client in ("198.51.100.10", "198.51.100.11", "2001:db8::10"):
            self.assertEqual(await self.client_seen("172.26.0.4", client),
                             {"client": client, "scheme": "https"})

    async def test_untrusted_peers_cannot_spoof(self):
        for peer in ("172.26.0.2", "172.26.0.1", "127.0.0.1", "198.51.100.20"):
            self.assertEqual(await self.client_seen(peer, "198.51.100.99"),
                             {"client": peer, "scheme": "http"})

    async def test_untrusted_leftmost_chain_is_not_client(self):
        self.assertEqual(
            await self.client_seen("172.26.0.4", "198.51.100.99, 198.51.100.10"),
            {"client": "198.51.100.10", "scheme": "https"},
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
