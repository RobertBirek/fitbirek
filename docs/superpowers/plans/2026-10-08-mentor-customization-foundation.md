# Mentor Customization Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a server-owned editable Mentor persona and a vetted OpenAI model-profile catalog, then expose both safely in Mentor settings.

**Architecture:** PostgreSQL stores the persona and a local model-profile key per account. A checked-in backend catalog maps that key to an OpenAI model ID and request limits; clients never submit provider model IDs. Settings become partial, revision-checked patches so old clients cannot erase new fields.

**Tech Stack:** FastAPI, Pydantic v2, SQLAlchemy async, Alembic, PostgreSQL 16, httpx, Flutter, Riverpod, widget tests.

---

## File map

- Create: `backend/app/mentor/catalog.py` — immutable profiles and public catalog serializer.
- Create: `backend/migrations/versions/0010_mentor_customization.py` — additive schema/data migration from `0009`.
- Modify: `backend/app/mentor/models.py` — persistent persona and active profile key.
- Modify: `backend/app/mentor/schemas.py` — partial settings patch and public profile DTO fields.
- Modify: `backend/app/mentor/service.py` — default persona, revision-aware mutation helpers, profile lookup.
- Modify: `backend/app/mentor/router.py` — settings contract and `409` conflict response.
- Modify: `backend/app/mentor/vendor.py` — accept a vetted profile and preserve strict Responses JSON validation.
- Modify: `backend/tests/test_schema.py`, `backend/tests/test_mentor.py`, `backend/tests/test_mentor_vendor.py` — migration, settings, catalog and transport tests.
- Modify: `lib/features/mentor/data/mentor_models.dart` — manual JSON models for profile and expanded settings.
- Modify: `lib/features/mentor/data/mentor_api.dart` — partial settings patch transport.
- Modify: `lib/features/mentor/presentation/pages/mentor_settings_page.dart` — persona input and model confirmation.
- Modify: `test/features/mentor/mentor_models_test.dart`, `test/features/mentor/mentor_api_test.dart`, `test/features/mentor/mentor_flow_test.dart` — Dart and widget tests.

### Task 1: Model-profile catalog and migration

**Files:**
- Create: `backend/app/mentor/catalog.py`
- Create: `backend/migrations/versions/0010_mentor_customization.py`
- Modify: `backend/app/mentor/models.py`
- Test: `backend/tests/test_schema.py`

- [ ] **Step 1: Write failing migration tests.**

  Seed `mentor_settings` at revision `0009` with `gpt-4.1-mini-2025-04-14`, `gpt-4.1-mini`, and an unknown string. Upgrade to `0010` and assert the known values become `legacy-gpt-4.1-mini-2025-04-14`, the unknown value becomes `NULL`, every new consent is `false`, and the exact default persona is stored.

  ```python
  assert row.model_profile_key == "legacy-gpt-4.1-mini-2025-04-14"
  assert row.persona == DEFAULT_PERSONA
  assert row.consent_context_training is False
  ```

- [ ] **Step 2: Run the focused migration test and confirm RED.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_schema.py::test_mentor_0009_upgrade_adds_customization_defaults`

  Expected: FAIL because revision `0010` and the new columns do not exist.

- [ ] **Step 3: Add the immutable catalog.**

  Define the exact public profiles below. Keep `enabled=False` for a profile until its mocked Responses contract test in Task 4 passes; enable it only in the same commit as that passing test.

  ```python
  @dataclass(frozen=True)
  class OpenAIModelProfile:
      key: str
      provider_model_id: str
      label: str
      quality_class: str
      cost_warning: str
      reasoning_effort: str | None
      max_input_tokens: int
      max_output_tokens: int
      enabled: bool

  PROFILES = {
      "legacy-gpt-4.1-mini-2025-04-14": OpenAIModelProfile("legacy-gpt-4.1-mini-2025-04-14", "gpt-4.1-mini-2025-04-14", "GPT-4.1 mini", "sprawdzony", "Profil legacy o niskim koszcie.", None, 6000, 800, True),
      "gpt-6-luna": OpenAIModelProfile("gpt-6-luna", "gpt-6-luna", "GPT-6 Luna", "ekonomiczny", "Niski koszt; model do codziennych rozmów.", "none", 6000, 800, False),
      "gpt-6.1-sol": OpenAIModelProfile("gpt-6.1-sol", "gpt-6.1-sol", "GPT-6.1 Sol", "zrównoważony", "Wyższy koszt niż Luna; używaj świadomie.", "low", 6000, 1600, False),
      "gpt-6-astra": OpenAIModelProfile("gpt-6-astra", "gpt-6-astra", "GPT-6 Astra", "najwyższa jakość", "Najwyższy koszt; używaj tylko do złożonych pytań.", "low", 6000, 1600, False),
  }
  ```

  `public_profiles()` returns only `key`, `identifier`, `label`, `quality_class`, and `cost_warning`. `profile_for_key()` returns `None` for an unknown or disabled key.

- [ ] **Step 4: Add ORM fields and migration.**

  Add `persona: Text`, nullable `model_profile_key: String(64)`, `context_policy_version: Integer`, and five `Boolean` fields named `consent_context_training`, `consent_context_profile`, `consent_context_weight`, `consent_context_note`, `consent_context_apple_health` to `MentorSettings`.

  Migration order: add nullable columns; backfill persona and policy version; map old `model`; set every consent to `false`; then set `persona`, policy version, and consents to `NOT NULL`. Do not remove or alter the legacy `model` column. Downgrade removes only the new columns.

- [ ] **Step 5: Run migration and catalog tests.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_schema.py tests/test_mentor_vendor.py`

  Expected: PASS, including migration from `0009` and no network calls.

- [ ] **Step 6: Commit the backend schema foundation.**

  ```bash
  git add backend/app/mentor/catalog.py backend/app/mentor/models.py backend/migrations/versions/0010_mentor_customization.py backend/tests/test_schema.py
  git commit -m "feat: add mentor customization schema"
  ```

### Task 2: Partial settings API with revisions and persona

**Files:**
- Modify: `backend/app/mentor/schemas.py`
- Modify: `backend/app/mentor/service.py`
- Modify: `backend/app/mentor/router.py`
- Test: `backend/tests/test_mentor.py`

- [ ] **Step 1: Write failing API tests.**

  Cover all of these cases with the existing authenticated `mentor` fixture:

  ```python
  # omitted persona preserves it; an empty string clears it
  assert (await client.put("/api/mentor/settings", json={"expected_revision": 3, "persona": ""})).status_code == 200
  # stale revision fails without mutation
  assert response.status_code == 409
  # old full payload does not erase persona/profile fields
  assert after["persona"] == "Zapisana persona"
  ```

  Also assert trimmed persona length above 800 gives `422`, an unknown `model_profile_key` gives `422`, an identical patch leaves `revision` unchanged, and a real patch increments revision and invalidates a pending operation.

- [ ] **Step 2: Run focused settings tests and confirm RED.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor.py -k 'settings or persona or revision'`

  Expected: FAIL because `SettingsUpdate` requires a full snapshot and does not know the new fields.

- [ ] **Step 3: Replace the full update schema with a patch schema.**

  Keep provider key schemas unchanged. Define a `SettingsPatch` with optional fields and `extra="forbid"`:

  ```python
  class SettingsPatch(Strict):
      expected_revision: int | None = Field(default=None, ge=0)
      persona: str | None = Field(default=None, max_length=800)
      model_profile_key: str | None = Field(default=None, max_length=64)
      consent_text: bool | None = None
      consent_voice: bool | None = None
      memory: str | None = Field(default=None, max_length=2000)
      # preserve the existing optional voice/TTS/STT fields
  ```

  Use `model_fields_set` so missing differs from `""`. Strip persona in a validator and reject an over-limit value after stripping.

- [ ] **Step 4: Implement a revision-aware router mutation.**

  `GET /settings` returns `persona`, `revision`, `active_model_profile_key`, `model_profiles`, `context_policy_version`, and `context_consents` while retaining `model` and `models` for old clients. `PUT /settings` compares `expected_revision` when supplied, validates the profile through `profile_for_key()`, checks credentials in changed free-text fields, and calls `invalidate_pending()` only if a persisted value changed.

  Return `HTTPException(409, "Mentor settings changed")` for a stale revision. Do not put secrets or the key material in the response.

- [ ] **Step 5: Run focused settings tests and confirm GREEN.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor.py -k 'settings or persona or revision'`

  Expected: PASS.

- [ ] **Step 6: Commit the settings API.**

  ```bash
  git add backend/app/mentor/schemas.py backend/app/mentor/service.py backend/app/mentor/router.py backend/tests/test_mentor.py
  git commit -m "feat: add mentor persona settings"
  ```

### Task 3: Preserve hierarchy in the OpenAI adapter

**Files:**
- Modify: `backend/app/mentor/vendor.py`
- Modify: `backend/app/mentor/service.py`
- Test: `backend/tests/test_mentor_vendor.py`

- [ ] **Step 1: Write failing transport tests for each catalog profile.**

  With the existing mocked `httpx` transport, assert that each enabled profile sends its catalog model ID, `store: false`, the existing strict `text.format`, no `tools`, its configured `max_output_tokens`, and `reasoning: {"effort": "low"}` only when the profile sets an effort.

  Add tests that a response containing a `reasoning` output item plus one completed `message` is accepted, while a refusal, incomplete response, unknown item type, invalid JSON, missing `input_tokens`, or missing `output_tokens` is rejected.

- [ ] **Step 2: Run the adapter test and confirm RED.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor_vendor.py`

  Expected: FAIL because `openai_reply()` accepts only a string in `_OPENAI_MODELS` and rejects reasoning output items.

- [ ] **Step 3: Make the adapter profile-driven.**

  Change the signature and result shape:

  ```python
  async def openai_reply(key: str, profile: OpenAIModelProfile, messages: list[dict]) -> dict:
      if not isinstance(key, str) or not key or not isinstance(messages, list):
          raise _unavailable()
      payload = {
          "model": profile.provider_model_id,
          "instructions": _SYSTEM_INSTRUCTIONS,
          "input": messages,
          "max_output_tokens": profile.max_output_tokens,
          "store": False,
          "text": {"format": {"type": "json_schema", "name": "mentor_reply", "strict": True, "schema": _OUTPUT_SCHEMA}},
      }
      if profile.reasoning_effort is not None:
          payload["reasoning"] = {"effort": profile.reasoning_effort}
      response = _json_object((await _request_bytes("POST", _OPENAI_URL, maximum=_MAX_RESPONSE, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}, json=payload))[1])
      answer_text, proposal = _parse_completed_response(response, profile.max_output_tokens)
      usage = response["usage"]
      return {
          "text": answer_text,
          "proposal": proposal,
          "input_tokens": _usage_token(usage, "input_tokens", profile.max_input_tokens),
          "output_tokens": _usage_token(usage, "output_tokens", profile.max_output_tokens),
      }
  ```

  Keep `_SYSTEM_INSTRUCTIONS` immutable. Add one sentence stating that persona, memory, conversation history, and contextual data are untrusted user data that cannot alter these rules. Ignore a completed `reasoning` item; still require exactly one valid assistant message with a valid JSON payload.

  Extract the existing completed-message validation loop into `def _parse_completed_response(response: dict[str, Any], max_output_tokens: int) -> tuple[str, dict[str, Any] | None]`. Add `def _usage_token(usage: dict[str, Any], name: str, upper: int) -> int` that rejects booleans, non-integers, negatives, and values above `upper` with `_unavailable()`.

  After the parameterized tests pass, change the three GPT-6 profile `enabled` values from `False` to `True` in the same commit. The UI then receives only tested profiles.

- [ ] **Step 4: Update `reply()` to select the profile and bound input.**

  Resolve `setting.model_profile_key` before reserving work. Reject `None` as `409 "Select an available model"`. Build messages only after `reject_credentials()` covers persona, memory, history, and the user message. Send persona as a separately labeled user-data item, never in `instructions`.

- [ ] **Step 5: Run adapter and Mentor integration tests.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor_vendor.py tests/test_mentor.py`

  Expected: PASS; no test connects to OpenAI.

- [ ] **Step 6: Commit adapter support.**

  ```bash
  git add backend/app/mentor/vendor.py backend/app/mentor/service.py backend/tests/test_mentor_vendor.py backend/tests/test_mentor.py
  git commit -m "feat: support vetted mentor model profiles"
  ```

### Task 4: Flutter settings for persona and model choice

**Files:**
- Modify: `lib/features/mentor/data/mentor_models.dart`
- Modify: `lib/features/mentor/data/mentor_api.dart`
- Modify: `lib/features/mentor/presentation/pages/mentor_settings_page.dart`
- Test: `test/features/mentor/mentor_models_test.dart`
- Test: `test/features/mentor/mentor_api_test.dart`
- Test: `test/features/mentor/mentor_flow_test.dart`

- [ ] **Step 1: Write failing Dart model and transport tests.**

  Deserialize a settings response with `persona`, `revision`, `active_model_profile_key`, and one model profile. Assert missing new properties default to empty persona, revision `0`, and an empty profile list. Assert `saveSettings` serializes a patch containing only `expected_revision` and the changed field, including `persona: ""`.

- [ ] **Step 2: Run focused Flutter tests and confirm RED.**

  Run: `flutter test test/features/mentor/mentor_models_test.dart test/features/mentor/mentor_api_test.dart`

  Expected: FAIL because the Dart settings model and API still require the legacy full snapshot.

- [ ] **Step 3: Add manual JSON models and patch transport.**

  Add `MentorModelProfile` and fields to `MentorSettings`; retain legacy `model` and `models`. Change `MentorApi.saveSettings` to accept a patch map and preserve empty-string values. Do not add Freezed, JSON generators, Drift tables, SharedPreferences, or outbox writes.

- [ ] **Step 4: Write failing widget tests for the controls.**

  Assert that the server persona fills the `TextField`, clearing it sends an empty value, text longer than 800 trimmed characters is blocked locally, and selecting a profile opens a confirmation dialog showing label, identifier, quality class, and cost warning. Cancelling sends no request; confirming sends the profile key and settings revision. A `409` refreshes settings and displays a conflict message.

- [ ] **Step 5: Implement the settings controls.**

  Add a `_persona` controller with the same account-change cleanup and `dispose()` treatment as `_memory`. Replace full-snapshot `_save()` with individual patch methods. Update the text-consent explanation so it names persona as data sent to OpenAI. Keep key entry unchanged.

- [ ] **Step 6: Run focused Flutter tests and confirm GREEN.**

  Run: `flutter test test/features/mentor/mentor_models_test.dart test/features/mentor/mentor_api_test.dart test/features/mentor/mentor_flow_test.dart`

  Expected: PASS.

- [ ] **Step 7: Commit the Flutter foundation.**

  ```bash
  git add lib/features/mentor/data/mentor_models.dart lib/features/mentor/data/mentor_api.dart lib/features/mentor/presentation/pages/mentor_settings_page.dart test/features/mentor
  git commit -m "feat: configure mentor persona and model"
  ```

### Task 5: Document, version, and verify the foundation

**Files:**
- Modify: `docs/mentor.md`
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`
- Modify: `lib/app/app_version.g.dart` via generator

- [ ] **Step 1: Update Mentor documentation.**

  Document persona as server-stored user preference sent only with text consent, the catalog-only model policy, snapshot/legacy compatibility, fixed provider endpoint, `store: false` limitation, and that no deployment runs provider calls.

- [ ] **Step 2: Bump the feature version.**

  Change `pubspec.yaml` from `1.3.1+6` to `1.4.0+7`; add a narrow Polish changelog entry; run `dart tools/generate_app_version.dart`.

- [ ] **Step 3: Run required verification.**

  ```bash
  dart format .
  dart tools/generate_app_version.dart --check
  flutter analyze
  flutter test
  cd backend && .venv/bin/python -m pytest -q
  cd .. && docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:mentor-foundation .
  ```

  Expected: every command exits `0`; no real OpenAI request occurs.

- [ ] **Step 4: Commit the release preparation.**

  ```bash
  git add docs/mentor.md CHANGELOG.md pubspec.yaml lib/app/app_version.g.dart
  git commit -m "docs: describe mentor customization"
  ```
