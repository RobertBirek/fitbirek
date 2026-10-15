# Exercise Illustrations Batch 22 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate the six approved cw103–cw108 illustrations.

**Architecture:** Extend the exact asset contract first and confirm red. Generate
each source individually with direct source/512px review before the next paid
call, then integrate the accepted set and verify the complete client suite.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker.

## Context and files

Approved design: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-22-design.md`.
Read `AGENTS.md` and `docs/modules/training.md`. Current main at `/opt/fit`,
preserve all unpublished batches 07–21. Direct reviews after subagent quota
exhaustion, not independent. Baseline 168/78/90/148/316; target 174/78/96/142/316.
No version, commit, push or deployment without separate request.

Create `assets/exercises/cw103.webp` through `cw108.webp`.
Modify `test/features/exercises/exercise_illustrations_test.dart`,
`lib/features/exercises/presentation/exercise_illustrations.dart`,
`docs/exercise-illustrations-status.md`. Record outcomes in this plan and spec.
Prompts, source PNGs, previews and ledgers stay under `/tmp/opencode`.

## Task 1: Red contract

- [x] Inspect scoped status and preserve existing changes.
- [x] Add after cw102 before cw251 in expectedIllustrationIds:

```dart
    'cw103',
    'cw104',
    'cw105',
    'cw106',
    'cw107',
    'cw108',
```

- [x] Change fallback assertion to:

```dart
expect(exerciseIllustrationAsset('cw109'), isNull);
```

- [x] Run (timeout at least 1200 seconds):

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-22-red .
```

Expected missing cw103 contract failure, other tests and analysis pass.

## Task 2: Prompt preparation

- [x] Verify parent `/tmp/opencode` and cw256 reference PNG.
- [x] Write six exact prompts to `/tmp/opencode/cw103-trial-01-prompt.txt`
  through `/tmp/opencode/cw108-trial-01-prompt.txt`, each composed of the
  approved spec's common block plus its complete respective scene block.
- [x] Review spec compliance then geometry: coherent band/soles/handles;
  drag elbows moving BACK; two palms under upper head cw105 versus right
  hand on handle cw106; vertical upper arms cw107; two touching weights cw108.

## Task 3: Sequential generation and review

Use each exact command separately, never run the next before reading the source
and its preview. Verify output parent before creation. Timeout >=240 seconds.

- [x] cw103:

```bash
test ! -e /tmp/opencode/cw103-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw103-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw103-trial-01 --exercise-id cw103 --single-sunburst-medium
convert /tmp/opencode/cw103-trial-01/cw103-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw103-trial-01/review-512.png
```

- [x] Read source and preview; verify two handles, supination, one band trapped
  under both soles, taut continuous branches, stable elbows and body.
- [x] cw104:

```bash
test ! -e /tmp/opencode/cw104-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw104-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw104-trial-01 --exercise-id cw104 --single-sunburst-medium
convert /tmp/opencode/cw104-trial-01/cw104-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw104-trial-01/review-512.png
```

- [x] Read source and preview; two supinated weights close to body, elbows
  behind torso, short top at waist/lower ribs, no classic forward curl.
- [x] cw105:

```bash
test ! -e /tmp/opencode/cw105-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw105-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw105-trial-01 --exercise-id cw105 --single-sunburst-medium
convert /tmp/opencode/cw105-trial-01/cw105-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw105-trial-01/review-512.png
```

- [x] Read source and preview; one vertical weight, both palms under same
  upper head, extension to flexion behind head, fixed upper arms, headroom.
- [x] cw106:

```bash
test ! -e /tmp/opencode/cw106-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw106-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw106-trial-01 --exercise-id cw106 --single-sunburst-medium
convert /tmp/opencode/cw106-trial-01/cw106-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw106-trial-01/review-512.png
```

- [x] Read source and preview; right hand holds only handle, left braces arm
  above elbow, same upper arm, weight behind head with visible connection.
- [x] cw107:

```bash
test ! -e /tmp/opencode/cw107-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw107-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw107-trial-01 --exercise-id cw107 --single-sunburst-medium
convert /tmp/opencode/cw107-trial-01/cw107-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw107-trial-01/review-512.png
```

- [x] Read source and preview; two horizontal bands, supported head/body/feet,
  two neutral weights above chest to beside forehead, vertical upper arms.
- [x] cw108:

```bash
test ! -e /tmp/opencode/cw108-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw108-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw108-trial-01 --exercise-id cw108 --single-sunburst-medium
convert /tmp/opencode/cw108-trial-01/cw108-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw108-trial-01/review-512.png
```

- [x] Read source and preview; two horizontal bands, two distinct touching
  neutral weights, tucked elbows, low chest to vertical press, same supports.

Correction: name defect, fresh prompt/output directory, ONLY last rejected PNG
reference; preserve accepted details. Read source/preview before another call.
After two failed corrections of same defect stop and obtain approval for new
composition. On HTTP/uncertain failure retain ledger and stop; no auto retry,
unknown cost not treated as zero. Never print secrets or raw provider payload.

## Task 4: Integrate six accepted sources

- [x] Confirm accepted paths. Commands below apply only if trial-01 accepted;
  use actual accepted correction path when a trial is rejected.

```bash
convert /tmp/opencode/cw103-trial-01/cw103-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw103.webp
convert /tmp/opencode/cw104-trial-01/cw104-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw104.webp
convert /tmp/opencode/cw105-trial-01/cw105-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw105.webp
convert /tmp/opencode/cw106-trial-01/cw106-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw106.webp
convert /tmp/opencode/cw107-trial-01/cw107-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw107.webp
convert /tmp/opencode/cw108-trial-01/cw108-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw108.webp
```

- [x] Read all six final WebP, verify 512×512 and two frames each.
- [x] Add after cw102 before cw251 in illustratedExerciseIds:

```dart
  'cw103',
  'cw104',
  'cw105',
  'cw106',
  'cw107',
  'cw108',
```

- [x] Run full verification (timeout >=1200 seconds):

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-22-verified .
docker run --rm fit-web:batch-22-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected full suite green, analysis 0 issues, version check pass, 174 exact
registry/test/files, all decode 512×512, fallback cw109, format 0 changes.

## Task 5: Record and close

- [x] Update status counts to 174 local / 78 published / 96 unpublished
  batches 07–22 / 142 missing / 316 catalog. Add rows cw103–cw108 with exact
  names from design, two frames, locally integrated/unpublished status.
- [x] Add “Dwudziesta druga partia” section before rules: layouts, selected
  variants, actual accepted paths, direct reviews, corrections and green evidence.
- [x] Read all ledgers, count only success with unique request_id; report
  summed estimated_cost_usd and its kind, unknown failures separately.
- [x] Record execution in spec and plan, preserving previous history.
- [x] Final source/asset/integration review and scoped status; run:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expected clean diff, production 1.9.0 build 22, API status ok.

## Plan self-review

All six spec scenes covered with individual prompts/calls/reviews, red-green
contract and exact 174-ID check. Counts/fallback/layouts consistent. Production
and catalog preserved. Direct review explicitly not independent. Paid-call error
handling and request_id cost deduplication included.

## Execution checkpoint — 2026-10-15

Tasks 1–2 done. Red build: analysis 0 issues, 365 tests passed, only exact
registry contract fails on missing cw103. Log:
`/root/.local/share/opencode/tool-output/tool_13e11ac970010GDQVEtWsZV5fu`.

Five sources accepted after direct spec→quality review of source and 512px:
trial-01 for cw103, cw104, cw106, cw107; correction-02 for cw105.
Cw105 correction-01 increased overhead margin but did not expose the far hand;
correction-02 exposed the second supporting hand/forearm under the upper head.

Cw108 trial-01 hid the far grip/weight; correction-01 exposed the second hand
but weights read as end-to-end/shared-head equipment. Correction-02 added
head outlines but did not make parallel neutral-grip placement unambiguous.
All three rejected. STOP after two unsuccessful corrections; obtain user
approval for NEW composition from foot-end three-quarter camera before another
paid call. Keep two horizontal bands, neutral touching weights, tucked elbows,
full body and supports. No further requests made at this checkpoint.

No final WebP or registry integration yet; Task 3 blocked on cw108, Tasks 4–5
pending. Extended test deliberately remains red, fallback cw109. Current assets
and status remain 168/78/90/148/316. Previous packages preserved.

Ten successful calls, each distinct request_id, no HTTP errors. Ledger success
costs (USD): trials cw103 0.023067, cw104 0.023047, cw105 0.023177,
cw106 0.023112, cw107 0.023107, cw108 0.023202; cw105 corrections
0.022567/0.022527; cw108 corrections 0.022557/0.022557.
Total 0.228920 USD upper_bound_no_cache estimate, not provider billing.
All prompts, original/edited PNGs, previews and ledgers retained under
`/tmp/opencode/cw103-*` through `/tmp/opencode/cw108-*`.
Reviews direct, not independent after the earlier subagent quota limit.

### New composition checkpoint — 2026-10-15

User approved ONE new request from foot-end three-quarter camera. Exact prompt
`/tmp/opencode/cw108-new-01-prompt.txt`, style-only cw256 reference, output
`/tmp/opencode/cw108-new-01`. Request succeeded; source and 512px preview read.
New view improves separation of four heads, but far grip still disappears in
low phase and neutral palm orientation is not unambiguous. REJECTED, no final
asset integrated. No additional requests under the single-request approval.

Next proposed action requiring approval: one targeted correction of new-01,
showing both separate hands on parallel handles with palms facing each other,
preserving contact of heads, foot-end view, supports and two bands.

New success request_id `req_1e3dae2112e849e0ab6ab79b7a363fd9`, cost 0.023407
USD upper_bound_no_cache. Total so far 11 successes, 0.252327 USD estimate,
no HTTP errors; not provider billing. Five accepted sources unchanged, full
integration/green remain pending, current asset/status counts unchanged.

### Authorized new-view correction — 2026-10-15

User approved one targeted correction. Exact prompt
`/tmp/opencode/cw108-new-correction-01-prompt.txt`; sole reference is rejected
new-01 PNG; fresh output `/tmp/opencode/cw108-new-correction-01`.
Source and 512px preview read directly. Both hands are now visible, but
equipment in extended phase reads as a common transverse handle/shared-head
assembly rather than two separate parallel neutral-grip dumbbells. REJECTED.
No integration and no further paid request under this single-correction approval.
This is the first failed correction in the new composition.

Success request_id `req_832245e97ce943c7911159a8dd6658ed`, 0.022822 USD
upper_bound_no_cache. Running total 12 successful requests, 0.275149 USD
estimate, no HTTP errors. Original ledgers/images retained; cost is not provider
billing. Five accepted sources unchanged; cw108/integration/green still pending.

## Completion record — 2026-10-15

User approved second correction and continuing until correct. Accepted
`/tmp/opencode/cw108-new-correction-02/cw108-gpt-image-2.5-sunburst-medium.png`:
two parallel neutral grips, separate heads touching at sides, no common
transverse handle. Source and 512px read before integration; natural occlusion
judged by connected hand/weight geometry. No further paid call required.

Final accepted paths: trial-01 for cw103/cw104/cw106/cw107, correction-02 for
cw105, new-correction-02 for cw108. Converted six final WebP with resize512,
strip, quality90; all read after conversion. Frames2 each, side-by-side103–106,
horizontal bands107–108. Added IDs to registry, test fallbackcw109.

Full Docker verification passed: 366 tests, analysis0issues, app-version check
pass, 2 Dart files formatted0changes. Log:
`/root/.local/share/opencode/tool-output/tool_13e3c08d9001Xf7fAflomR2lO1`.
Status/spec updated preserving earlier history:174local/78published/96unpublished/
142missing/316. Package local and unpublished, production1.9.0+22.

Read all13success ledgers, request_id unique, no HTTP errors, response_received
not double-counted. Last call request_id `req_a5e29ebc12f84bcea9a1c471a37b6a1f`,
0.023082USD. Total0.298231USD upper_bound_no_cache estimate, not provider billing.
13calls=6initial+1newcomposition+6corrections. All source/prompt/preview/ledger
files retained. Reviews direct, not independent after earlier quota exhaustion.

Final checks: git diff --check clean; registry/test/assets/status table all
contain the same174IDs, fallbackcw109. Scoped status confirms six new assets
and batch docs. Public version.json1.9.0build22, APIhealth statusok.
