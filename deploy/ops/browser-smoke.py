"""Production browser smoke; requires Python Playwright/Chromium and root.

No traces, cookie files, password logging or screenshots of credentials.
Creates an offline mood entry and, on a fresh account, a temporary profile.
Test records are tombstoned after verification.
"""
from pathlib import Path
from uuid import uuid4

from playwright.sync_api import sync_playwright, expect

ORIGIN = "https://fit.birek.online"
stage = "startup"


def login(context):
    global stage
    page = context.new_page()
    page.goto(ORIGIN + "/#/today")
    page.wait_for_load_state("networkidle")
    page.locator("flt-semantics-placeholder").evaluate("e => e.click()")
    email = page.get_by_role("textbox", name="E-mail", exact=True)
    expect(email).to_be_visible(timeout=60000)
    stage = "login route assertion"
    assert "/login" in page.url
    email.click()
    page.keyboard.insert_text("robert@birek.online")
    page.wait_for_timeout(300)
    stage = "credential entry"
    password = Path("/docker/fit/secrets/initial-account.txt").read_text().strip()
    page.get_by_role("textbox", name="Hasło", exact=True).click()
    page.keyboard.insert_text(password)
    page.keyboard.press("Tab")
    page.wait_for_timeout(500)
    stage = "login response"
    with page.expect_response(ORIGIN + "/api/auth/login") as response:
        page.get_by_role("button", name="Zaloguj się", exact=True).click()
    submitted = response.value.request.post_data_json
    print("Credential input matches:", submitted.get("email") == "robert@birek.online", submitted.get("password") == password)
    print("Login HTTP status:", response.value.status)
    assert response.value.status == 204
    stage = "post-login navigation"
    page.wait_for_url(lambda url: "/login" not in url, timeout=30000)
    return page


def changes(context):
    response = context.request.get(ORIGIN + "/api/sync/pull?cursor=0")
    assert response.status == 200
    latest = {}
    for change in response.json()["changes"]:
        latest[(change["entityType"], change["entityId"])] = change
    return latest


def tombstone(context, record):
    csrf = next(cookie["value"] for cookie in context.cookies() if cookie["name"] == "fit_csrf")
    response = context.request.post(ORIGIN + "/api/sync/push", headers={"Origin": ORIGIN, "X-CSRF-Token": csrf}, data={
        "operations": [{"operationId": str(uuid4()), "entityType": record["entityType"],
                        "entityId": record["entityId"], "baseVersion": record["version"],
                        "payload": record["payload"], "deleted": True}]})
    assert response.status == 200 and len(response.json()["accepted"]) == 1


try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=["--no-sandbox"])
        first = browser.new_context(viewport={"width": 1280, "height": 1100})
        stage = "first browser login"
        page = login(first)
        print("PASS: protected route redirects to login; browser login uses same-origin API")
        initial = {key: record for key, record in changes(first).items() if record["deletedAt"] is None}
        stage = "onboarding"
        if "/onboarding" in page.url:
            page.get_by_role("button", name="Zaczynajmy", exact=True).click()
            page.get_by_role("button", name="Dalej", exact=True).click()
            page.get_by_role("button", name="Zakończ konfigurację", exact=True).click()
        page.wait_for_url("**/#/today", timeout=30000)
        save = page.get_by_role("button", name="Zapisz", exact=True)
        expect(save).to_be_visible(timeout=30000)
        stage = "offline mood creation"
        # Allow profile sync to settle before taking the device offline.
        page.wait_for_timeout(2000)
        before_offline = changes(first)
        first.set_offline(True)
        save.click()
        expect(page.get_by_text("Dziennik samopoczucia wypełniony na dziś ✓", exact=True)).to_be_visible()
        print("PASS: mood saved locally while browser is offline")
        stage = "reconnect synchronization"
        first.set_offline(False)
        new_moods = []
        for _ in range(45):
            current = changes(first)
            new_moods = [record for key, record in current.items() if key not in before_offline and "mood" in key[0].lower() and record["deletedAt"] is None]
            if new_moods:
                break
            page.wait_for_timeout(1000)
        assert len(new_moods) == 1
        print("PASS: reconnect synchronized exactly one new mood record")
        stage = "second independent profile"
        second = browser.new_context(viewport={"width": 1280, "height": 1100})
        other = login(second)
        stage = "second profile mood display"
        expect(other.get_by_text("Dziennik samopoczucia wypełniony na dziś ✓", exact=True)).to_be_visible(timeout=30000)
        stage = "second profile API identity"
        assert new_moods[0]["entityId"] in [r["entityId"] for r in changes(second).values()]
        stage = "second profile reload"
        other.reload(wait_until="domcontentloaded", timeout=60000)
        placeholder = other.locator("flt-semantics-placeholder")
        placeholder.wait_for(state="attached", timeout=30000)
        placeholder.evaluate("e => e.click()")
        stage = "reloaded mood visibility"
        expect(other.get_by_text("Dziennik samopoczucia wypełniony na dziś ✓", exact=True)).to_be_visible(timeout=30000)
        print("PASS: second independent browser receives mood and retains it after reload")
        stage = "logout"
        other.goto(ORIGIN + "/#/settings", wait_until="domcontentloaded")
        placeholder = other.locator("flt-semantics-placeholder")
        if placeholder.count():
            placeholder.evaluate("e => e.click()")
        other.get_by_role("button", name="Wyloguj", exact=False).click()
        other.wait_for_url(lambda url: "/login" in url, timeout=30000)
        other.goto(ORIGIN + "/#/today")
        other.wait_for_url(lambda url: "/login" in url, timeout=30000)
        print("PASS: logout and protected-route access return to login")
        stage = "cleanup"
        current = changes(first)
        test_mood_ids = {record["entityId"] for record in new_moods}
        for key, record in current.items():
            is_test_record = record["entityId"] in test_mood_ids or (key[0] == "profile" and key not in initial)
            if is_test_record and record["deletedAt"] is None:
                tombstone(first, record)
        print("PASS: smoke-test profile/mood records tombstoned")
        # Revoke the first browser's test session too.
        csrf = next(c["value"] for c in first.cookies() if c["name"] == "fit_csrf")
        assert first.request.post(ORIGIN + "/api/auth/logout", headers={"Origin": ORIGIN, "X-CSRF-Token": csrf}).status == 204
        browser.close()
except Exception as error:
    if stage in ("second profile reload", "reloaded mood visibility", "logout"):
        print("Browser check diagnostic:", str(error).replace(Path("/docker/fit/secrets/initial-account.txt").read_text().strip(), "[REDACTED]"))
    # Playwright failure messages can include fill() values. Never print them.
    raise SystemExit(f"Browser smoke failed at {stage}; exception details suppressed to protect credentials") from None
