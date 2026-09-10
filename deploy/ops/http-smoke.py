"""Read-only production HTTPS, MIME, cache and SPA contract checks."""
import hashlib
from urllib.error import HTTPError
from urllib.request import urlopen

origin = "https://fit.birek.online"
root = None
for path, mime in [
    ("/", "text/html"), ("/today", "text/html"),
    ("/sqlite3.wasm", "application/wasm"),
    ("/drift_worker.dart.js", "application/javascript"),
    ("/flutter_service_worker.js", "application/javascript"),
    ("/flutter_bootstrap.js", "application/javascript"),
    ("/main.dart.js", "application/javascript"),
]:
    with urlopen(origin + path, timeout=30) as response:
        data = response.read()
        assert response.status == 200 and response.headers.get_content_type() == mime
        assert "no-cache" in response.headers["Cache-Control"]
        if path == "/":
            root = hashlib.sha256(data).digest()
        if path == "/today":
            assert hashlib.sha256(data).digest() == root
        print(f"PASS: {path} HTTPS 200, {mime}, no-cache")
with urlopen(origin + "/api/health", timeout=30) as response:
    assert response.read() == b'{"status":"ok"}'
print("PASS: same-origin /api/health includes working database query")
for path, status in [("/api/auth/session", 401), ("/api/not-a-route", 404), ("/missing.wasm", 404)]:
    try:
        urlopen(origin + path, timeout=30)
    except HTTPError as error:
        assert error.code == status
    else:
        raise AssertionError(f"Unexpected successful response: {path}")
    print(f"PASS: {path} returns {status}")
