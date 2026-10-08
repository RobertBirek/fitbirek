# Mentor Context Consent Recovery Implementation Plan

> **For agentic workers:** Execute task-by-task with tests before production code. Do not stage, commit, or deploy this change.

**Goal:** Let a user explicitly submit all five context consents and the current policy version after a restore invalidates the acknowledgement, while retaining independent consent patches after the acknowledgement is valid.

**Architecture:** `GET /api/mentor/settings` exposes whether the server considers the stored acknowledgement current. The Flutter settings model preserves this marker. When it is false, settings renders a clear recovery card and a modal with all five consent choices; its single confirmation sends a complete `context_consents` object and `context_policy_version`. When it is true, existing switches keep sending one-field patches.

**Tech Stack:** FastAPI/Pydantic, Flutter, Riverpod, flutter_test.

---

### Task 1: Prove the recovery request and normal partial request

**Files:**
- Modify: `test/features/mentor/mentor_flow_test.dart`

- [ ] Add a widget test whose settings response has `context_consents_active: false`, opens the recovery action, confirms it, and expects this exact payload:

```dart
{
  'expected_revision': 4,
  'context_policy_version': 1,
  'context_consents': {
    'training': true,
    'profile': false,
    'weight': false,
    'note': false,
    'apple_health': false,
  },
}
```

- [ ] In the same test, assert the restore warning and confirmation text are visible. Retain and run the existing test asserting a valid marker sends `{'context_consents': {'training': true}}` only.
- [ ] Run `flutter test test/features/mentor/mentor_flow_test.dart`; the new test must fail before implementation.

### Task 2: Surface the server acknowledgement marker

**Files:**
- Modify: `backend/app/mentor/router.py`
- Modify: `lib/features/mentor/data/mentor_models.dart`

- [ ] Add `context_consents_active: service.context_consents_active(row)` to the settings response.
- [ ] Add immutable `contextPolicyVersion` and `contextConsentsActive` fields to `MentorSettings`, parsing `context_policy_version` and `context_consents_active` with safe defaults.

### Task 3: Implement the explicit recovery dialog

**Files:**
- Modify: `lib/features/mentor/presentation/pages/mentor_settings_page.dart`

- [ ] Add a recovery card shown only when `settings.contextConsentsActive` is false. Its text explains that a restore or policy update invalidated the prior acknowledgement and that individual switches cannot reactivate context.
- [ ] Open an `AlertDialog` with all five independently selectable consent controls, concise recipient disclosures, cancel, and an explicit confirmation button.
- [ ] On confirmation call `_savePatch` once with all five booleans and `context_policy_version: settings.contextPolicyVersion`; do not issue individual switch saves while inactive.
- [ ] Keep the existing individual switch handlers unchanged when the marker is valid.

### Task 4: Verify

**Files:**
- Verify: `test/features/mentor/mentor_flow_test.dart`

- [ ] Run `dart format backend/app/mentor/router.py lib/features/mentor/data/mentor_models.dart lib/features/mentor/presentation/pages/mentor_settings_page.dart test/features/mentor/mentor_flow_test.dart`.
- [ ] Run `flutter test test/features/mentor/mentor_flow_test.dart` and `flutter analyze`.
- [ ] Run `dart tools/generate_app_version.dart --check`.
- [ ] Run `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:verified .`.
- [ ] Inspect `git diff` and `git status --short`; do not stage, commit, deploy, or alter Web SQLite artifacts because lockfile dependencies remain unchanged.
