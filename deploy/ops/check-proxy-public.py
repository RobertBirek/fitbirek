"""Production HTTPS auth/proxy smoke; secrets stay in memory, no domain writes.

Creates a unique nonexistent-email limiter bucket, left to normal expiry/cleanup.
Run as root on the deployment host after check-proxy-trust.py.
"""
import http.cookiejar
import json
from pathlib import Path
import subprocess
from urllib.error import HTTPError
from urllib.request import HTTPCookieProcessor, Request, build_opener
from uuid import uuid4


BASE = "https://fit.birek.online"
jar = http.cookiejar.CookieJar()
opener = build_opener(HTTPCookieProcessor(jar))


def request(path, payload=None, headers=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = Request(BASE + path, data=data,
                  headers={"Content-Type": "application/json", **(headers or {})})
    try:
        response = opener.open(req, timeout=20)
    except HTTPError as error:
        response = error
    with response:
        return response.status, response.headers, response.read()


def main():
    assert request("/api/health")[0] == 200
    assert request("/api/auth/session")[0] == 401
    assert request("/api/sync/pull")[0] == 401
    password = Path("/docker/fit/secrets/initial-account.txt").read_text().strip()
    status, headers, _ = request("/api/auth/login", {
        "email": "robert@birek.online", "password": password,
    }, {"Origin": BASE})
    del password
    assert status == 204
    try:
        cookies = headers.get_all("Set-Cookie")
        assert len(cookies) == 2
        assert all("Secure" in cookie and "SameSite=strict" in cookie for cookie in cookies)
        assert any(cookie.startswith("fit_session=") and "HttpOnly" in cookie for cookie in cookies)
        assert request("/api/auth/session")[0] == 200
        assert request("/api/sync/pull")[0] == 200
        csrf = next(cookie.value for cookie in jar if cookie.name == "fit_csrf")
        assert request("/api/auth/logout", {}, {
            "Origin": "https://untrusted.example", "X-CSRF-Token": csrf,
        })[0] == 403
        assert request("/api/auth/logout", {}, {"Origin": BASE})[0] == 403
    finally:
        csrf = next(cookie.value for cookie in jar if cookie.name == "fit_csrf")
        assert request("/api/auth/logout", {}, {
            "Origin": BASE, "X-CSRF-Token": csrf,
        })[0] == 204
    assert request("/api/auth/session")[0] == 401
    assert request("/api/sync/pull")[0] == 401
    print("HTTPS health/authenticated sync/session/cookie/Origin/CSRF/logout checks passed")

    email = f"proxy-smoke-{uuid4().hex}@example.com"
    for number in range(6):
        status, headers, _ = request("/api/auth/login", {
            "email": email, "password": "nonexistent-account-test",
        }, {"Origin": BASE, "X-Forwarded-For": f"198.51.100.{10 + number}"})
        assert status == (401 if number < 5 else 429)
        assert not headers.get_all("Set-Cookie")

    # Only emit a boolean, never credentials, tokens or the real client address.
    sql = f"""SELECT count(*) = 1 AND bool_and(
        client_ip <> '172.26.0.4' AND client_ip NOT LIKE '198.51.100.%'
        AND cardinality(failed_at) = 5)
        FROM login_attempts WHERE email = '{email}';"""
    result = subprocess.run(
        ["docker", "exec", "-i", "fit-postgres-1", "psql", "-U", "fit", "-d", "fit", "-At"],
        input=sql, text=True, capture_output=True, check=True,
    )
    assert result.stdout.strip() == "t", "Expected one real-client bucket with five failures"
    print("Public spoofed XFF ignored: five 401, then 429; one real-client DB bucket, no cookies")


if __name__ == "__main__":
    main()
