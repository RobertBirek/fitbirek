# Exercise Illustrations Batch 26 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate the six approved cw127–cw132 illustrations.

**Architecture:** Extend the exact asset contract first and confirm red.
Generate six sources individually, reviewing each source and 512px preview
before another paid request. Integrate accepted WebP assets and restore green.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and files

Approved design: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-26-design.md`.
Read AGENTS.md and docs/modules/training.md. Work in current /opt/fit main;
preserve unpublished batches 07–25. Direct reviews after earlier subagent
limit, not independent. Baseline 192/78/114/124/316; target 198/78/120/118/316.
Create assets/exercises/cw127.webp through cw132.webp. Modify registry,
test/features/exercises/exercise_illustrations_test.dart, status and batch docs.
No catalog/model/dependency/WebSQLite/version/commit/push/deployment changes.

## Task 1: Red contract

- [x] Inspect scoped status and preserve prior work.
- [x] Add after cw126 before cw251 in expectedIllustrationIds:

```dart
    'cw127',
    'cw128',
    'cw129',
    'cw130',
    'cw131',
    'cw132',
```

- [x] Set fallback `expect(exerciseIllustrationAsset('cw133'), isNull);`.
- [x] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-26-red .
```

Expected only missing cw127 exact registry failure, 365 other tests pass,
analysis 0 issues.

## Task 2: Prompts and sequential generation

- [x] Verify /tmp/opencode and cw256-reference.png. Write six prompt files
  /tmp/opencode/cw127-trial-01-prompt.txt through cw132-trial-01-prompt.txt;
  each includes full approved common block plus respective scene from spec.
- [x] Direct spec then geometry review: shoulder rack, rear foot dorsum,
  static contacts, alternating forward travel, anchored right foot reverse,
  anchored left foot lateral; two weights and complete grips throughout.

Run each request separately with timeout >=240 seconds and fresh exclusive
output. Verify parent. Read original PNG and 512px preview before next request.
Never print secrets or raw provider payloads.

- [x] Generate cw127:

```bash
test ! -e /tmp/opencode/cw127-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw127-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw127-trial-01 --exercise-id cw127 --single-sunburst-medium
convert /tmp/opencode/cw127-trial-01/cw127-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw127-trial-01/review-512.png
```

- [x] Review cw127: 2 side-by-side frames, 2 shoulder rack contacts, elbows
  forward/high, stand→deep squat, same full soles, not goblet/overhead.
- [x] Generate cw128:

```bash
test ! -e /tmp/opencode/cw128-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw128-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw128-trial-01 --exercise-id cw128 --single-sunburst-medium
convert /tmp/opencode/cw128-trial-01/cw128-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw128-trial-01/review-512.png
```

- [x] Review cw128: 2 horizontal bands, right full sole forward, left dorsum
  atop seat, fixed contacts/bench height, controlled descent, no jump.
- [x] Generate cw129:

```bash
test ! -e /tmp/opencode/cw129-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw129-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw129-trial-01 --exercise-id cw129 --single-sunburst-medium
convert /tmp/opencode/cw129-trial-01/cw129-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw129-trial-01/review-512.png
```

- [x] Review cw129: 2 horizontal bands, fixed right sole/left forefoot on
  floor, low rear knee not grounded, no bench/step/side change.
- [x] Generate cw130:

```bash
test ! -e /tmp/opencode/cw130-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw130-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw130-trial-01 --exercise-id cw130 --single-sunburst-medium
convert /tmp/opencode/cw130-trial-01/cw130-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw130-trial-01/review-512.png
```

- [x] Review cw130: 3 horizontal bands, right low lunge→rise/left passing→
  left low lunge, body advances relative floor, same camera, no mirrored body.
- [x] Generate cw131:

```bash
test ! -e /tmp/opencode/cw131-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw131-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw131-trial-01 --exercise-id cw131 --single-sunburst-medium
convert /tmp/opencode/cw131-trial-01/cw131-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw131-trial-01/review-512.png
```

- [x] Review cw131: 3 bands stand→left step BACK low→return, right foot stays
  at seam, no forward step or static split squat masquerading as reverse.
- [x] Generate cw132:

```bash
test ! -e /tmp/opencode/cw132-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw132-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw132-trial-01 --exercise-id cw132 --single-sunburst-medium
convert /tmp/opencode/cw132-trial-01/cw132-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw132-trial-01/review-512.png
```

- [x] Review cw132: 3 bands stand→right lateral wide step high→right leg
  flexed/left straight, left foot anchored, heels grounded, not sumo/goblet.

Corrections: named defect, only last rejected PNG reference, fresh prompt/output,
read source/preview before next call. After two failed corrections of same
defect stop that composition and assess new one, continuing toward correct
result per user without blind repeats. On provider error/uncertainty preserve
ledger/path, no automatic retry, unknown cost separate. Never log secrets.

## Task 3: Integration

- [x] Confirm six accepted paths and fresh destinations. Commands below use
  trial-01 ONLY if accepted; substitute actual accepted correction paths:

```bash
convert /tmp/opencode/cw127-trial-01/cw127-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw127.webp
convert /tmp/opencode/cw128-trial-01/cw128-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw128.webp
convert /tmp/opencode/cw129-trial-01/cw129-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw129.webp
convert /tmp/opencode/cw130-trial-01/cw130-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw130.webp
convert /tmp/opencode/cw131-trial-01/cw131-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw131.webp
convert /tmp/opencode/cw132-trial-01/cw132-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw132.webp
```

- [x] Read final six WebP, verify512×512 and frames2/2/2/3/3/3.
- [x] Add after cw126 before cw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw127',
  'cw128',
  'cw129',
  'cw130',
  'cw131',
  'cw132',
```

## Task 4: Green verification

- [x] Run timeout >=1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-26-verified .
docker run --rm fit-web:batch-26-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass, analysis0issues, version check pass,198 matching IDs/assets,
all512decode, fallbackcw133, format0changes.

## Task 5: Documentation and close

- [x] Update status198local/78published/120unpublished07–26/118missing/316;
  six rows with exact names/framecounts; “Dwudziesta szósta partia” before rules.
- [x] Record accepted sources, real direct reviews/corrections, cw128 no-jump
  interpretation, walking progression and anchored steps; retain history.
- [x] Read all ledgers, success only with unique request_id, summed estimated
  costs and kind, no double-count response_received; unknown errors separate.
- [x] Final asset/integration review,198matching registry/test/files/status,
  scoped status; run:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expected clean diff, production1.9.0build22, APIstatusok; package unpublished.

## Self-review

All six approved scenes covered;2/2/2/3/3/3frames, explicit foot/bench contacts,
step directions and side assignments. Red-green198contract/fallback133, real
grips, geometry/error/cost rules and preservation of prior work included.

## Execution record — 2026-10-15

- Accepted: cw127-correction-02, cw128-new-01, cw129-new-02, cw130-new-01,
  cw131-new-01 under /tmp/opencode; cw132 uses cw132-approved-aligned.png,
  derived locally from cw132-correction-02. Frames2/2/2/3/3/3.
- Cw127: removed unintended bench and raised elbows; clarified no bench
  before later non-bench calls. Cw128: two failed far-grip corrections,
  new front3/4 composition exposed both grips and rear dorsum support.
- Cw129: two unsuccessful stance corrections, rejected new-01 with drift/
  hidden grip, accepted frontal new-02. Cw130 changed global composition
  immediately after first wrong leg/scale/travel result to frontal new-01.
- Cw131: two unsuccessful front-anchor corrections, accepted frontal new-01.
  Cw132: two support corrections, then LOCAL rigid translation +22px of
  top region (rows0–357) aligned anchor; lower rows/dividers pixel-identical.
  RGB comparison confirmed exact translation and unchanged lower scenes;
  no mirror/scale/deformation or extra paid call. Exact command in spec.
- Each source and512px preview read before next request; aligned PNG/preview
  read, all final six WebP read after resize512/strip/quality90. Direct
  spec→quality reviews, not independent after earlier subagent quota limit.
- Red: missing cw127 only,365other tests pass,analysis0issues. Log:
  `/root/.local/share/opencode/tool-output/tool_13f1772ab001kBCscDXganp2AF`.
- Green:366pass,analysis0issues,version check pass,2Dartfiles format0changes.
  Log `/root/.local/share/opencode/tool-output/tool_13f6c5c46001hwtZK26fVNBZVf`.
  Registry/test/files198IDs,512decode,fallbackcw133; status198/78/120/118/316.
- Read21success ledgers with unique request_id, no double-count
  response_received, no HTTP errors.11sources/newcompositions+10corrections,
  total0.480842USD upper_bound_no_cache estimate,not providerbilling.
  Detailed cost table in spec. Package local/unpublished,production1.9.0+22.
- Final checks: git diff --check clean; scoped status reviewed;198matching IDs
  in registry/test/assets/status table, fallbackcw133. Publicversion1.9.0build22,
  APIhealth statusok. No outstanding batch tasks.
