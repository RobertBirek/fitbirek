# Release 1.15.0+28 — actual two-compiled-release rollout gate

## Verdict: **FAIL — rollout gate remains open**

Actual isolated Chromium acceptance on **2026-10-18 UTC** used the compiled
1.14.0+27 and 1.15.0+28 images, the real candidate API, fresh PostgreSQL and an
official CLI-created test account. **No production promotion, Git mutation,
commit, push, production login or source-app fix was performed.**

The critical unresolved result is **schema 12 remaining in use while the old
1.14 tab stays open**, despite the other tab executing the exact new 1.15 JS
and displaying version 1.15.0 build 28. Only after closing all old tabs and a
cold browser start did the persisted database migrate to 13. That later result
does **not** close the requested live two-tab migration gate.

| Gate | Result |
|---|---|
| Two actual compiled releases, UI 1.14.0+27 → 1.15.0+28 | **PASS** |
| Normal reload, natural new SW activation; HTML/bootstrap/main bytes match new image | **PASS** |
| Old second tab remains open and safely receives old main bytes | **PASS** |
| Local schema 12→13 while old second tab remains open | **FAIL** |
| Same session UUID, guidance, 7 reps / 5 kg / left and paused interval checkpoint | **PASS** preservation |
| Pending old operation preserved through reload and sent to real API | **PASS**, ACK was from the old second tab |
| Nonempty outbox survives an actual 12→13 migration with old tab open | **NOT ACHIEVED**, blocked by preceding FAIL |
| Candidate compiled UI consent/prepare/progress/ready, all 443 actual cache hashes | **PASS** |
| Candidate cold root/today/recovery offline after closing old tabs | **PASS**, a separate post-closure case |
| Offline image/font rendering, one explicit set, finish, real reconnect, no duplicates | **PASS** |
| Phone installation, sleep, storage retention, background execution | **UNTESTED / manual pending** |

## Time and evidence

- Stack/browser provision timestamp: **2026-10-18T07:51:41Z**.
- Static-origin release switch: **2026-10-18T08:02:42Z**.
- Evidence verification: **2026-10-18T08:30:33Z**; test ended on workout main
  at **08:30:45Z**, then own resources were removed.
- Artifact root: **`/tmp/opencode/release-rollout-20261018-b43f9d/`**.
- `verify.py` deliberately exits **1** and writes **`verification.json`** with
  the rollout FAIL. Its evidence-consistency assertions all passed. Exit 1 is
  not a discarded harness failure or a passing release gate.

## Exact releases and isolation

**Old web** `fit-web:candidate-1.14.0-27`:

```text
index sha256:a2121f18d6cc6ddb4f6d400bcc2ab8d4cb0b41a38d83fe4909a7717213fafa06
main.dart.js 256d36dc8efe26844611c03aed3ad9a96ec5a69f4297834ac3833b94f452a28c
index.html   b604cc37f1160c9ac87966c1fb1419b237f55da27a7fddd9933718df1e014718
```

**New web** `fit-web:candidate-1.15.0-28`:

```text
index  sha256:25165415aee932001665729aec7191c86700e144d85b08d6326bea67e4b494c9
config sha256:75ba628cc4b8fbcc231a734c485f4efa2858c8c44912d673e8065131597d51aa
main.dart.js 65e42d7ef3c8c3f90da4daa0e45b90aaf65d6054fe99191ec1c03339cd2b046b
index.html   3125af12d407ac5aee8134c3cfa9eac26808210b9afc755300ad248cbeec6966
bootstrap    3c7f19a18692b75df31589109c6dc8ada61e237db8a583b7eaecd99ce519bec7
packageId    4fc31fceee1444a54e6b28bf22ab1a34740b486c4f3ad224ae3ec2e0a6c9af78
443 files / 46,808,552 bytes
```

**Actual candidate API** `fit-api:candidate-1.15.0-28`:
`sha256:96f277bf9e06f665969660976dc778901406d52a524bcc86bc2f188004b73e49`.
All **40 Python app files** matched the current backend before provision;
hashes retained in `api-source-proof.json`. PostgreSQL 16 was new, Alembic
**0010**. The prior hash-locked migrator was used only for this fresh test DB.

The previously supplied **813 Flutter PASS / analyze 0 / compiled build OK**
(log `tool_14df46f49001t6AWl4g764gLa6`) and **378 backend PASS** were not rerun
or presented as the browser migration result.

Own prefix `fit-rollout-20261018-b43f9d`; internal Docker network, zero host
ports, localhost HTTPS SAN/SPKI, real API/PG, generated test account through
official CLI stdin. Secrets 0600, evidence root 0700. No production requests,
DB injection, synthetic ACK/auth, HTTP response mocks, main-code patches,
storage clearing, SW unregister, forced claim or skipWaiting calls.

Used `tests/tools/offline_browser_driver.py`: temporary copy of the existing
driver excludes **only SW auto-attachment**. Chromium 140.0.7339.16 had real
SW enabled. Confirmed real SW targets unattached after compiled UI status.
No installed Playwright/dependency/security changes. The initial idle-target
diagnostic found no running SW target; a subsequent normal UI status woke the
worker, then the required unattached-target assertion passed. Both diagnostics
are retained (`46-idle-helper-note.json`, `47-no-SW-attachment.json`).

## Actual same-origin release switch

Both static trees were extracted unchanged from their immutable images.
The candidate Nginx configuration was copied, retaining its missing-static
404 rule. Test-only changes added HTTPS, an `/api/` proxy and a root at
`/srv/releases/current`. An **atomic symlink swap old→new** switched only own
static origin, preserving the running proxy, TLS, browser namespace, profile,
SQLite and both tabs. No HTTP fulfillment or altered HTML/JS was used.
`image-release-proof.json` and `48-runtime-manifest.json` identify exact images;
all recorded extracted release file hashes remained unchanged.

Two tabs first loaded actual old main JS and UI. Ordinary primary reload
obtained new HTML, bootstrap and main JS. The observed responses match the new
image hashes above; there was no old main paired with new HTML. The worker
activated naturally, without repeated RPC to the old worker during install.
The loader logged its existing 4000 ms preparation timeout before activation;
this was retained rather than treated as activation failure or silenced.

The unchanged second tab still displayed 1.14 and had no `fitOffline` bridge.
After new SW activation, its read-only fetch of main returned **old**
`256d36dc…a28c` bytes, not candidate main. It therefore could not report false
ready for the new package. It remained open through candidate full prepare.
Evidence: `03/04-old-version-ui`, `21-first-reload-native.json`,
`22-loaded-pair-diagnostics.json`, **`25-candidate-real-version-bottom.png`**,
`29-old-second-safe-code.json`, `32b-old-second-still1.14-ui`,
`33-before-cold-oldtab-open.json`, `46-loaded-code-final.json`.

## Blocking live-migration result

Using only old compiled UI, prepared one guided session with **7 reps, 5 kg,
left** at slot 0 and an extra rounds exercise (`cw352`). That extra exercise
had a real interval checkpoint: round 1, work phase, paused, elapsed
**13,165,101 µs**, no results. Its 30 s work target restored as **17 s remaining**.
No sets or PRs existed. The earlier simple stopwatch was not a durable interval
checkpoint and was not used as migration evidence; the actual interval was.

Test API was intentionally stopped after authenticated onboarding to leave a
real **pending start operation** in outbox. The old second tab remained open.
The first candidate boot during this deliberate API outage got HTTP502 and
showed login. Local identity, offlineAccess, guidance, draft and the pending
operation remained. Restoring own API and a normal reload reused the real
cookie session, with no reset or auth stub.

However, while that second old tab remained open:

- Candidate **UI displayed 1.15.0 build 28**, candidate main hash matched.
- Repeated SQLite copies reported **`PRAGMA user_version = 12`**.
- **`weekly_schedule_json` was absent** from `PRAGMA table_info(user_profiles)`.
- `PRAGMA integrity_check = ok`; not a corrupt/empty snapshot.
- The same result persisted after candidate recovery/resume and actual compiled
  package preparation. It was not just a snapshot taken while startup loaded.
- UUID, fields and checkpoint remained intact. No automatic series/PR appeared.

Evidence: **`29-migration-gate-failure.json`** and snapshots
`22-candidate-schema13-db.json` (historical filename, **observed 12**),
`23-candidate-migration-db.json`, `27-candidate-recovery-db.json`,
`28-candidate-resumed-durable-db.json`, `33-pre-cut-durable-db.json`.
At the FAIL, returned to main and stopped the affected live-migration case:
`29-return-main-stop-migration-case.png`.

After closing **all** old tabs/processes for the independent cold/offline case,
schema became **13** and the new column was present. This suggests interaction
with the lifetime of the old shared DB connection, but **root cause was not
proven or fixed**. No unsupported repair or criterion relaxation was performed.
Closing old tabs is an observed boundary/workaround, not a successful result
for the requested old-tab-open rollout.

The old pending operation `bfacaac7-b128-440a-b469-46adf0b42cb1` was preserved
exactly, including JSON payload, base version and UUID, across the first reload.
When API returned, **the old second tab** sent it and received real HTTP200 ACK,
version 1, duplicate=false, at **2026-10-18T08:04:42Z**. Request and ACK are in
`33-pre-cut-ACKs.json`. Thus there is a PASS for preservation and actual delivery,
but **no proof of migration12→13 with that operation still pending**: the live
migration failed, and the queue had already been acknowledged before cold13.

## Independent candidate package/offline/recovery controls

With the old tab still open, candidate **Settings → Tryb offline** showed
notReady and correct size. Explicit consent showed **46,808,552 bytes / 443 files**.
Prepare/progress reached ready; a direct read-only CacheStorage audit verified
every actual response length and SHA256, total bytes and independently recomputed
manifest fingerprint. No API URL was cached. No manual full cache warming.
Evidence: `30-candidate-package-notReady`, `31-candidate-size-consent`,
`31b-candidate-prepare-progress`, **`32-candidate-ready443.png`**,
`32-candidate-all443-cache-audit.json`.

Then stopped **whole own web**, closed browser context and launched the same
persistent profile for a cold test. This also closed the old second tab and
allowed the separately observed schema13. Root and `/today` served the actual
app offline. Direct active route showed recovery; explicit resume preserved
the original session, 7/5/left and extra checkpoint. Timer UI remained paused
at **17 s** across a further 3.2 s observation, not counting absence as work.
Images cw369/cw364, not previously opened in UI, painted offline.

Only explicit **Seria wykonana (0)** created a set: **7 × 5 kg, left**. Finish
saved emoji-only note `💪 ⚠️ 👩‍💻 💪🏽`; no interval round was falsely logged.
SC font was naturally served by SW as WOFF2, **5256 bytes**, SHA256
`e4b7e47d39dc977a198121b39c448c698a5ccb33f14a48d945e25d122f6904e8`.
This is a bounded rollout smoke, not a replacement for the prior full font test
or a claim of zero generic FE0F warnings.

After own-origin restart/rejoin, real sync emptied outbox/deferred. Repeated
full API pull and second independent real-login/pull were identical. Read-only
PostgreSQL latest payload/version/UUID matched API. End state:
**1 profile, 1 session, 1 set, 1 PR**, no saved-plan fixture or duplicate log.

Session UUID **`c984115c-479c-4e3d-8470-d10efd3e2da0`**;
set UUID **`fcf1a127-c2c6-411d-8437-b0297c8c60d8`**.
Drift after old-tab closure **13**, server Alembic **0010**.
Missing `.webp`/`.woff2` returned 404, not SPA HTML. All browser requests were
same-origin; no external request was allowed or observed.

Evidence: `34-candidate-offline-cold-root`, `35-candidate-offline-deep-today`,
`36-candidate-offline-recovery`, `37-offline-preserved-fields`,
**`38-checkpoint-restored-paused.png`**, `38-checkpoint-not-running-proof.json`,
`39/39b-offline-unvisited-image-*`, `41-explicit-one-offline-set-db.json`,
`42-natural-font-responses.json`, `43-offline-finished-db.json`,
`44-real-api-pull.json`, `44b-repeat-api-pull.json`,
`45-second-actual-pull-db.json`, `46-second-actual-summary`,
`48-final-postgres.json`, `48-origin-events.json`, `48-nginx-access.log`.

## Cleanup and release decision boundary

Stopped on main, preserved all evidence and image candidates. `cleanup.py`
completed successfully; **zero own containers/networks/volumes remain** in
`cleanup-result.json`. Secrets remain protected with 0600 inside the protected
artifact root. The temporary extracted static trees are public build contents;
only those subdirectories were made traversable by test Nginx.

Setup permission diagnostics, UI focus/timeouts, idle-worker-target diagnostic
and intermediate snapshots are retained. No source behavior or runner assertion
was weakened to turn the critical migration into a pass. The evidence verifier
records the observed FAIL and exits 1 deliberately.

**Required before production gate closure:** a supported and verified handling
of old-tab/shared-connection lifetime, then a new actual compiled two-release
retest that satisfies schema13 with the required old-tab boundary and proves
the pending-outbox migration rather than only its old-client ACK. This report
does not prescribe or implement the fix.

**Review limitations/manual pending:** physical iPhone/Android installation,
sleep/storage eviction/background behavior, full additional worker/backend
matrix, all CAS/account-switch cases, quota and complete update permutations
remain untested here. No iPhone verification or independent source review is
claimed. Existing fixture/native results do not replace this failed gate.

---

## LATEST — 2026-10-18 10:22–10:31 UTC: schema-gate policy retest

### Verdict: **FAIL — explicit BLOCK works, but close-old → Retry does not recover**

The acceptance criterion in this retest is the **new explicit fail-closed policy**
from `release-1.15.0-28-schema-gate-fix-2026-10-18.md`, **not** concurrent automatic
migration with an old writer. The historical RED above is unchanged.

The newest candidate correctly refuses the old shared schema before normal app
startup. It also refuses repeated retries and deep links while the old tab is
open. However, **after closing the only remaining old tab**, the new tab's
**Spróbuj ponownie** still reports **12; required 13**. First post-closure Retry
did not migrate within **60 seconds**. A second Retry after that wait remained
blocked at 12. Only the blocked new page was left open. The requested natural
close-old→Retry→actual13 transition is therefore **not achieved**.

No browser/profile restart, forced worker shutdown, unregister, storage clearing,
manual PRAGMA/DDL or application source patch was used to obtain a different
result. This case was stopped on the blocking screen; proper main UI is
intentionally unavailable there. The successful cold-start workaround from the
previous image was **not** substituted for the new Retry criterion.

| New-policy gate, newest compiled image | Result |
|---|---|
| Actual old1.14 and newest1.15, correct new HTML/main | **PASS** |
| Full-app explicit `Schemat bazy: 12; wymagany: 13.` with close-other-tabs instruction | **PASS** |
| Repeated Retry while old tab open; deep link cannot bypass | **PASS**, three UI retries, unchanged DB snapshots |
| New app auth/router/sync not started before verified schema | **PASS externally observed boundary**: gate only, no app API requests after new main; no proper app UI |
| Old tab remains operational and receives old static bytes after new-client rejection | **PASS** |
| Close only old tab → Retry in existing blocked new tab → actual13 | **FAIL**, first attempt remained12 for60s, second also12 |
| Nonempty pending outbox preserved throughout blocked retries, before any ACK | **PASS**, complete raw rows and hashes equal |
| Nonempty outbox preserved across a **successful** migration13 | **NOT ACHIEVED**, no migration occurred |
| Post-migration recovery, normal UI/version, package prepare/cache443, offline set/finish, real reconnect and second pull | **UNTESTED on this image**, blocked by failed recovery gate |
| Physical phone/iPhone | **UNTESTED / manual pending** |

### Exact newest candidate and isolated environment

New artifact root: **`/tmp/opencode/schema-gate-rollout-20261018-f6a82c/`**.
Own resource prefix: `fit-schema-rollout-20261018-f6a82c`.
Start timestamp **2026-10-18T10:22:39Z**, same-origin static switch
**10:25:05Z**, final stopped-case screenshot **10:31:38Z**.

```text
old compiled index:
sha256:a2121f18d6cc6ddb4f6d400bcc2ab8d4cb0b41a38d83fe4909a7717213fafa06
new compiled index:
sha256:d1bf2fd0aac87c3e97df9350cc30a1177c73cbb2c8cc59304a10466435681a9a
new config (verified in image save):
sha256:8da45290e25c3c2aa44cd4e5ee7d84f2b7f3387a183c4166f3a6f1849a633db1
new main.dart.js:
73818f007fd4f89fd447567ceaa4f6de0fe4539924117f535989418fae2f168b
new index.html:
5749cd76dc2ff5bccc7759727a209927ec4a8e32372ea545267b771c32be1caa
new package metadata:
9e13f19e751bbaf1d0aea302619edbac85cac0ab894b14775dc6d947c2984dfd
443 files / 46,814,384 bytes
```

The package size/count/ID above was checked in the **extracted image manifest**.
It is **not** a claim that this blocked app prepared or verified that package in
CacheStorage. Earlier 443-cache results belong to earlier images.

Actual API candidate is unchanged:
`sha256:96f277bf9e06f665969660976dc778901406d52a524bcc86bc2f188004b73e49`;
**40/40 Python files matched current backend** before provision. Fresh PostgreSQL
16, Alembic0010, official CLI-generated account, new TLS/SPKI and persistent
profile. Same-origin HTTPS static trees switched atomically, using the copied
candidate Nginx plus test-only HTTPS/API/root changes. No main/HTML response
patching. Internal network, no host ports, no production resources or logins.

Used the supplied temporary `offline_browser_driver.py` and existing Chromium,
without installed-driver/security/dependency changes. Native registrations
reported the real new SW active; controller was the real worker. The driver had
no SW Runtime. At the final idle capture no running SW target was present;
that idle termination was not treated as a missing registration or replaced by
forced activation. Default dedicated-worker attachment was left unchanged.

Supplied **840 Flutter PASS / analyze0 / full compiled build** (log
`tool_14e806565001BhNfie65MLPIlP`) and prior review CLEAR are upstream evidence,
not this E2E result. They were not rerun or used to override the failed Retry.

### Reproduction and no-ACK preservation proof

1. Old1.14 UI login/onboarding created the profile. Opened the second old tab in
   the same context; both executed the actual old compiled main.
2. **Physically stopped only own API container** before starting the guided
   workout, so neither old nor new tab could receive a session ACK.
3. Through old UI created one session, fields **7 reps / 5 kg / left**, slot0,
   and an extra cw352 interval checkpoint (paused work, round1, 30/10/3 config,
   **11,527,099 µs elapsed**, no results). **0 sets / 0 PR**.
4. Reloaded the primary tab after switching the static origin. New HTML and
   main hashes matched the newest image. New SW activated naturally.
5. Observed full-screen block; two Retry clicks with old tab still open stayed
   blocked. A direct schedule URL plus a third Retry also stayed blocked.
   Whole SQLite snapshots remained byte-value identical row-for-row.
6. Closed **only `oldtab`** by ordinary page close. The blocked new page and
   browser context were retained: `remainingPages=1`, oldClosed=true.
7. Clicked Retry, waited up to60s, captured schema12/block. Clicked Retry again
   after that wait and captured the same block and unchanged schema12.

**Critical pending operation, before any ACK:**

```text
operation_id: b54722d4-81c5-4c14-9f9c-fe0f107bc99d
entity_type: workoutSession
entity_id: 7c4a6dda-525b-4c7e-aea9-81016fd9d3f4
base_version: 0
attempted: 0
preserve_local: 0
deleted: 0
created_at_utc: 1792319061
canonical full-row SHA256:
893a1d9542373d51e3238ce8465a8e1cf567ce5c26102646c7ee82293c129c84
raw payload_json SHA256:
45e2c4e0b2f5773c3fe4bdfec3b5041dd044149bf7e8710167b733f32e355111
```

The complete raw row, original `payload_json`, draft row and session row were
compared **before switch**, during every blocked stage, and **after old close /
both failed Retry clicks**. They are exactly equal. The entire inspected table
snapshot also matches the baseline, including binding/offlineAccess, zero
sets/PR and unchanged checkpoint. Hashes above are identical before and after.

Evidence: **`05-pending-row-fingerprint.json`**,
**`15-final-pending-row-comparison.json`**, `05-before-upgrade-schema12-pending.json`,
`06/07/08/09/10-*-db.json`,
`12-after-Retry-schema13-BEFORE-ACK-db-timeout.json` (**filename is intended target,
actual observed version12**), `13-post-close-retry-db.json`,
`14-second-postclose-retry-db.json`, `15-final-blocked-BEFORE-ACK-db.json`.

API stayed physically stopped through completion (`15-api-remained-stopped-proof.json`).
Read-only PG audit ran in a separate one-off candidate container, not an API
server, and found **only the onboarded profile**, one profile operation/change:
**0 workout sessions / 0 sets / 0 PR in PG**. Local DB has **1 pending session,
1 draft, 1 unsent outbox row, 0 sets, 0 PR**. Thus no ACK race can explain the
preservation result. Attempted+unsent combinations were not both exercised:
the actual pending row is **unsent (`attempted=0`)**.

### Request and lifecycle boundaries

After new main loaded there were **zero primary app API requests** while blocked.
The two `/api/auth/session` requests labelled at the first reload phase occurred
**before the response containing new HTML**, from the preceding old document;
`09-initial-request-order-diagnostics.json` preserves the exact event order.
Old second-tab auth failures during the deliberate outage are separately
labelled. Diagnostic `/api/health` probes are harness network checks, not app
bootstrap. Deep-link/retry phases generated no new app auth/push/pull.

Snapshots alone do not trace every possible transient SQL instruction. The
compiled E2E proves unchanged persisted data and absence of new-app network/UI
startup; the separate native/RPC raw executor test suite remains its own scope.

`13-worker-targets-afterclose.json` shows a shared Drift worker and multiple
dedicated Drift worker targets despite only one page remaining. This is retained
as diagnostic evidence, **not a proven leak/root cause**. No worker was forcibly
terminated, no source fix attempted, and no existing acceptance assertion was
weakened. Whether channel closure/worker lifetime causes the persistent schema12
needs focused investigation outside this acceptance task.

### Failure screenshots, cleanup and release boundary

- **`06-new-first-schema-block.png`** — correct explicit new policy.
- **`07-retry1-old-open-block.png`**, **`08-retry2-old-open-block.png`**,
  **`09-deep-link-still-blocked.png`**, **`10-deep-retry-blocked.png`**.
- **`13-post-close-retry-timeout.png`** — old closed, first retry failed60s.
- **`14-second-postclose-retry.png`**, **`15-final-schema12-still-blocked.png`**,
  **`16-final-blocked-page-before-cleanup.png`** — still blocked after second.
- `11-only-old-tab-closed.json`, `15-post-close-state.json`,
  `16-final-blocked-stop.json` — only one new blocked page remained.

`verify.py` deliberately exits **1**, with all evidence-consistency checks true,
and writes the failed close-old→Retry gate to `verification.json`.
`cleanup.py` completed successfully: **zero own containers/networks/volumes**.
Artifacts, profiles, candidate images and secrets0600 in the protected root
remain. No production/Git actions, source-app changes or cache/DB repair.

**Release gate is still not closed under the changed safe policy.**
Downstream normalUI/version/recovery, package prepare443, full-origin offline,
explicit set/finish and real reconnect/second pull were **not rerun on this
newest image** because permitted recovery never reached schema13. Historical
passes from earlier images are not attributed to this one. Physical phone and
full additional worker/CAS/future-schema cases remain **UNTESTED/manual pending**.

---

## LATEST — 2026-10-18 13:24–13:37 UTC: explicit full-exit policy — PASS

**PASS for the changed contract: SAFE BLOCK → normal full browser exit of all
Fit windows, including the blocked one → reopen the same persistent disk profile
→ actual migration13 with the original nonempty outbox preserved BEFORE ACK.**

This is **not** a pass for automatic migration while old tabs stay open or for
the previous close-old-only→Retry promise. Both historical FAIL sections remain
unchanged. **The process action actually tested was a complete ordinary Chromium
process exit**, not only closing an old tab or assuming background workers stop
when a window disappears. The UI correctly asks for complete closure, including
the blocked window/PWA, and describes Retry only as an optional version check.

### Exact artifact, clock and isolation

New evidence root: **`/tmp/opencode/fullclose-rollout-20261018-a71c95/`**.
Own prefix: `fit-fullclose-rollout-20261018-a71c95`.
Started **2026-10-18T13:24:12Z**, ended on workout main at **13:37:55Z**.
All previously used stacks were cleaned; this stack had fresh PG, account,
certificates, profile and cache. API/DB were real and test-only, official account
CLI via stdin, HTTPS localhost/SPKI, internal network, **zero host ports**.
Candidate API current-source check again verified **40/40 Python app files**.

```text
old1.14 compiled image index:
a2121f18d6cc6ddb4f6d400bcc2ab8d4cb0b41a38d83fe4909a7717213fafa06
new1.15 compiled image index:
e0d42678c1923a742bbbdee29132b63c2c7164f29c79ef8517fcbacb8112a38f
new config (independently verified in image save):
b266c8e6356648050bb6f7bc769ea5ba776d8022d0c8c736fcd3586c8be5cf09
new package:
a88407eba4e8fe464d4400a3310892085fdc84f60211807184e2fbaab2abd1b1
443 files / 46,814,736 bytes
real API candidate:
96f277bf9e06f665969660976dc778901406d52a524bcc86bc2f188004b73e49
```

Both immutable compiled static roots were extracted and hash-checked. Same
running HTTPS Nginx switched its own root by atomic symlink, preserving origin,
TLS, profile and API proxy. Actual new HTML/main hashes matched the new image,
not a patched response or fixture main. Worker activation remained natural.
The supplied temporary driver excluded only SW debugger auto-attachment;
real SW was enabled and the unattached-target assertion passed after compiled
UI status. No installed-driver/security/dependency changes.

Supplied full **840 Flutter PASS / analyze0 / build** evidence
`tool_14f267309001cCkzSMMFa6xpr4` was not rerun or conflated with this browser E2E.

### Critical migration sequence and matrix

| Case actually rerun on this newest image | Result |
|---|---|
| Old1.14 compiled guided session, two old tabs, API gated before pending start | **PASS**, real UI, schema12, 1 session/1 draft/1 pending operation, 0 sets/PR |
| New compiled client loads while old second tab remains open | **PASS**, coherent new HTML/main and full-screen block |
| Correct full-close instruction, including this window/PWA; optional Retry wording | **PASS**, `06-new-fullclose-instruction-block.png` |
| Retry with old tab held open stays blocked, no data changes/auth/sync startup | **PASS**, whole SQLite snapshot equals baseline |
| Normal exit of **all** old and new blocked browser windows/process | **PASS**, `08-all-windows-closed.json`, PIDs and path recorded |
| Reopen **same** persistent `/evidence/profile-upgrade`, API still physically stopped | **PASS**, original persisted data; no new context with empty storage substituted |
| Actual `user_version=13`, `weekly_schedule_json` present, before any session ACK | **PASS**, `09-MIGRATED13-PENDING-BEFORE-ACK.json` |
| Original pending full row/raw payload, account/device/offlineAccess, session and draft/checkpoint across successful migration13 | **PASS**, exact row-by-row comparison and hashes before ACK |
| Only then restore real API; original operation gets nonduplicate ACK | **PASS**, original operation UUID/payload and version1 ACK captured |
| Normal AppVersion1.15+28, direct recovery, same UUID/7/5kg/left, 0 autologs | **PASS** |
| Paused interval checkpoint restored without adding absence as work | **PASS**, actual UI text stable across further2.5s |
| Explicit UI full-package size/prepare/progress/ready, real443 SHA/length audit | **PASS**, two actual complete-cache audits |
| Whole origin STOP, same-profile cold root/today/deep, recovery and unvisited illustration | **PASS** |
| Exactly one explicit offline set+finish, reconnect ACK0queue, repeated sync and second real context pull | **PASS**, no duplicate UUID/log |
| Physical iPhone/Android and PWA close/background behavior | **UNTESTED/manual pending** |

### Before-ACK row-by-row proof — the previously missing critical gate

Old compiled UI created guided slot0 **7 reps / 5 kg / left** and an extra
cw352 paused interval checkpoint with real partial elapsed work and no results.
There was no series or PR. Own API container was then kept **stopped throughout
the update, full exit/reopen and migration audit**, preventing an ACK race.

Baseline `05-old-before-upgrade-pending.json` has schema12. After safe block,
`07-retry-old-open-db.json` is an **entire-table-snapshot exact match**.
After reopening the same profile, `09-MIGRATED13-PENDING-BEFORE-ACK.json` has:

- **schema13** and actual nullable `user_profiles.weekly_schedule_json` column;
- all prior profile field values unchanged, with only that additive column;
- exact `sync_state` rows: **same account, device, offlineAccess and cursor**;
- exact `workout_sessions` row, including UUID and raw guidance JSON;
- exact `workout_drafts` row, including raw payload, fields, selections,
  checkpoint config/elapsed/paused state and revision metadata;
- exact **nonempty `sync_outbox`** row, including operation UUID, base version,
  attempted/preserve/delete flags, timestamp and raw payload string;
- unchanged empty sets/PR/deferred tables.

The critical operation:

```text
operation_id: 39f71f8f-d995-4cdc-8fac-0a8b6aabdd37
entity_type: workoutSession
entity_id: 986b51c1-f1a7-4533-8e99-d98864aaf379
base_version: 0
attempted: 0 (actual unsent UI operation)
canonical full-row SHA256, identical before/after:
1fe886f07c7f605fe16ca774a36a62c2d47ffcf486abdc6e69d0d0ab491ca94c
raw payload_json SHA256, identical before/after:
2d54c905df38f0268596b84ac918847d3627256807feb2192fb31845658130aa
```

The full rows, not just selected fields, are retained in
**`05-baseline-outbox-hashes.json`** and
**`09-critical-migration-comparison.json`**. `verify.py` independently compares
all rows and hashes. `10-API-physically-stopped-preACK.json` records stopped
API/restartCount0. An isolated one-off candidate container performed only the
read-only PG audit: **profile only, 0 server sessions/logs/PR**, one profile
operation/change. Thus the original pending session was definitely **not
acknowledged until after the successful migration comparison**.

This tests **one unsent attempted0 row**. It does not claim a new compiled-browser
test of a combined attempted+unsent queue; native/RPC immutable-attempted tests
remain separate evidence.

### Precisely what “full closure” meant here

The test closed the **persistent browser context normally** (`context.close()`),
which closes both the old tab and the blocked new tab and exits that isolated
Chromium process. It then called `launch_persistent_context` with exactly the
**same on-disk directory `/evidence/profile-upgrade`**. Browser PIDs before and
after differ, and both old page objects were closed. No SIGKILL, worker-CDP
termination, `terminateAll`, unregister, cache/storage removal, DB injection,
manual DDL/PRAGMA write or temporary empty profile was used.

This is stronger than merely closing only an old tab and pressing Retry. It is
an explicitly allowed normal full-browser/process exit, **not proof that every
desktop/mobile browser exits its background process when the last Fit window
closes**. Closing a PWA while its browser/other origin tabs keep workers alive
was not independently established. Operational instructions must retain the
full-exit boundary; no promise of automatic live migration or Retry restart is
restored by this PASS.

While own API was still off, successful schema migration permitted normal auth
bootstrap, which displayed login because the endpoint was unavailable. This
does not invalidate the pre-ACK comparison: no new account or reset occurred.
After the audit, own API was started and an ordinary reload reused the original
real-cookie session. The original operation was sent unchanged and ACKed
version1, `duplicate=false`, outbox empty. Only then was normal UI/version and
session resume exercised. Evidence: `11-real-start-ACK-events.json`,
`11-real-start-ACK-db.json`, **`12-new-normal-version1.15.png`**,
**`13-migrated-session-direct-recovery.png`**,
**`14-migrated-preserved7left5.png`**, `15-checkpoint-no-autotime.json`.

### New-image package, offline and actual final sync

New compiled **Settings → Tryb offline** displayed notReady and the real total
**46,814,736 bytes / 443 files**. Explicit consent and prepare reached ready.
`18-actual-all443-cache-audit.json` and `31-final-all443-cache-audit.json` hash
**every actual CacheStorage response**: correct 443 lengths/SHA and total bytes,
no API entries. Manifest content fingerprint was recomputed independently.
Screenshots: `16-package-notReady-newimage`, **`17-package-size-consent.png`**,
`17b-prepare-progress`, **`18-package443ready.png`**.

Stopped own whole web origin, normally closed/reopened the persistent browser
profile, then cold root, `/today` and deep-path shell all ran the actual app.
Health/API probes failed; direct hash active route showed recovery and restored
the same original UUID/7/5/left. cw369 illustration, not previously opened in UI,
painted offline. The first hash navigation during boot settled on today;
the subsequent stable direct active navigation and panel were recorded
separately, not represented by the intermediate screenshot. A reconnect helper
also initially expected settings while startup was on today; using the actual
Settings tab completed that intended UI action. Intermediate diagnostics remain.

Only **Seria wykonana (0)** created the one new log. Offline finish saved note
`💪 ⚠️ 👩‍💻 💪🏽`, left 7×5kg, one normal PR, and three pending operations.
Natural SC font response was **HTTP200 from SW, WOFF2/5256 bytes**, SHA256
`e4b7e47d39dc977a198121b39c448c698a5ccb33f14a48d945e25d122f6904e8`.
The known generic nominal-coverage/FE0F warning is not an asset-availability
failure and no zero-warning guarantee is claimed. This was a bounded font
smoke, not a repeat of every prior font/update matrix.

After normal own-origin restart and rejoin of its network namespace with the
same profile, real sync yielded **0 outbox / 0 deferred**. A repeat full API pull
and an independent second-context login/pull were identical. UI in that second
context showed one series, original session and emoji note. Final read-only PG
payloads/versions/UUIDs match the API: **1 profile / 1 session / 1 set / 1 PR**.
Server Alembic remains0010, both clients Drift13.

Original session **`986b51c1-f1a7-4533-8e99-d98864aaf379`**;
new explicitly logged set **`c7e14274-1285-4e3a-9fbf-363003c232a1`**.
Evidence: `19/20/20b-offline-*`, `21b-offline-recovery-real-activeURL`,
`22-offline-before-explicit-set.json`, `23-offline-unvisited-image.png`,
`24-one-explicit-offline-set.json`, `25-natural-font-responses.json`,
`26-offline-finished-pending-db.json`, `27/27b/28-*-API-pull.json`,
**`29-second-real-summary.png`**, `48-final-postgres.json`.

### Completion and scope of release evidence

`verify.py`: **exit0**, including the now-successful **actual13 + exact nonempty
outbox BEFORE ACK** assertion. `verification.json` records the full-process
boundary explicitly. `cleanup.py`: **exit0**, zero own containers/network/volume;
artifacts, persistent profiles, candidate images and protected secrets0600
remain. No source-app/dependency/version changes, commit/push/deploy or production
connection in this task. Only this report was appended in the repository.

The tested release gate is now **PASS under the full-exit/reopen policy**; the
historical live-auto-migration and close-old-only→Retry FAILs are **not repaired
or relabelled**. Acceptance does not itself promote production.

**Manual/review limitations:** physical iPhone/Android installation, full PWA
process closure and mobile background behavior, storage retention/eviction,
all future-schema/CAS/account-switch cases, attempted+unsent combined queue,
quota and full additional worker/update matrices remain **UNTESTED here**.
Existing 840 tests/review evidence were not rerun as an independent source review.
No iPhone verification, universal PWA closure behavior or live shared-schema
migration is claimed.
