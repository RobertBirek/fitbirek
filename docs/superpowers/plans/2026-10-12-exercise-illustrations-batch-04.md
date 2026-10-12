# Exercise Illustrations Batch 04 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add offline illustrations for the six missing mobility exercises `cw268-cw272` and `cw275`, then release one web-only version `1.8.0+21`.

**Architecture:** Approved source PNGs are converted to one `512x512` WebP per ID. The Flutter registry and its test remain the source of truth. Prompts, ledgers and rejected PNGs stay in `/tmp/opencode`; only approved WebP files, registry, tests and release metadata enter the repository.

**Tech Stack:** OpenAI image edits through `tools/benchmark_exercise_images.py`, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker, Docker Compose, Nginx runtime.

---

## File Structure

- Create: `assets/exercises/cw268.webp` through `cw272.webp`, and `cw275.webp`.
- Modify: `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`.
- Modify: `docs/exercise-illustrations-status.md`, `pubspec.yaml`, `lib/app/app_version.g.dart`, `CHANGELOG.md`.
- Temporary only: `/tmp/opencode/cw268-*` through `cw272-*`, `/tmp/opencode/cw275-*`.

## Task 1: Create The Red Registry Contract

**Files:**
- Modify: `test/features/exercises/exercise_illustrations_test.dart`
- Modify later: `lib/features/exercises/presentation/exercise_illustrations.dart`

- [ ] **Step 1: Add the expected missing IDs in ascending order.**

  Insert after `cw267`:

  ```dart
  'cw268',
  'cw269',
  'cw270',
  'cw271',
  'cw272',
  ```

  Insert after `cw274`:

  ```dart
  'cw275',
  ```

- [ ] **Step 2: Verify the intended red state.**

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-04-red .
  ```

  Expected: the registry equality test fails because `illustratedExerciseIds` lacks `cw268`.

- [ ] **Step 3: Leave production registry unchanged.**

  Do not add production IDs or assets before all six scenes are accepted.

## Task 2: Generate The Seated Spine And Neck Assets

**Files:**
- Temporary: prompts and output directories for `cw268-cw270`.

- [ ] **Step 1: Create the three prompts with the common constraint block.**

  Every prompt starts with:

  ```text
  Use supplied image only as style reference. Clean 2D fitness art, cream background, dark outlines, faceless adult in dark neutral clothes, no text, numbers, arrows, labels or watermark. Square 1024x1024.
  ```

  Append these exact scenes:

  ```text
  cw268: Two separated panels, upright seated cat-cow. First panel opens the chest forward with a gentle thoracic extension; second panel rounds the full spine. Keep feet grounded and shoulders relaxed.

  cw269: Two separated panels, controlled seated neck mobility. First panel neutral upright head; second panel a small chin-forward-to-side arc only. Do not tilt the head backward, force end range, or draw arrows.

  cw270: Two separated side-profile panels, upright seated chin tuck. First panel neutral head; second panel slides the head horizontally backward as if making a double chin. Keep gaze level and do not nod, flex, extend, or lift the chin.
  ```

- [ ] **Step 2: Generate and inspect one asset at a time.**

  Use this command form after inspecting the preceding output:

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw268-trial-01-prompt.txt \
      --reference /tmp/opencode/cw256-reference.png \
      --output-dir /tmp/opencode/cw268-trial-01 \
      --exercise-id cw268 --single-sunburst-medium
  ```

  Repeat by replacing only the ID and prompt path for `cw269` then `cw270`.

- [ ] **Step 3: Apply safety rejection criteria.**

  Reject `cw268` if motion is only lumbar; reject `cw269` for any substantial neck extension; reject `cw270` if it becomes a nod. For a named defect only, use the rejected PNG as the sole reference, a new output directory, and a correction prompt preserving accepted phases and style.

## Task 3: Generate The Shoulder, Wrist And Ankle Assets

**Files:**
- Temporary: prompts and output directories for `cw271`, `cw272`, `cw275`.

- [ ] **Step 1: Create prompts with the common constraint block and these scenes.**

  ```text
  cw271: Two separated panels, upright seated shoulder rolls. First panel shows shoulders moved forward; second shows shoulders lifted and drawn backward. Keep neck long and torso upright.

  cw272: Two separated panels, hands extended in front of torso with two visibly distinct wrist-circle positions. Keep elbows soft, movement isolated to wrists, and use no arrows.

  cw275: Two separated panels, stable seated ankle mobility with one foot raised. Show two visibly distinct opposite ankle-circle positions; keep the lower leg still and isolate movement to the ankle.
  ```

- [ ] **Step 2: Generate each asset separately with `cw256` as reference.**

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw271-trial-01-prompt.txt \
      --reference /tmp/opencode/cw256-reference.png \
      --output-dir /tmp/opencode/cw271-trial-01 \
      --exercise-id cw271 --single-sunburst-medium
  ```

  Repeat one reviewed request at a time for `cw272` and `cw275`.

- [ ] **Step 3: Inspect safety and phase clarity.**

  Reject shoulder shrug-only `cw271`, elbow-led `cw272`, or an unsupported/unclear raised foot in `cw275`. Correct named pose defects only, with the rejected draft as sole reference and a fresh output directory.

## Task 4: Integrate Approved Assets And Restore Green

**Files:**
- Create: `assets/exercises/cw268.webp` through `cw272.webp`, `assets/exercises/cw275.webp`
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart`

- [ ] **Step 1: Convert each accepted PNG to WebP.**

  ```bash
  convert /tmp/opencode/cw268-trial-01/cw268-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw268.webp
  ```

  Apply the same command to every accepted source for `cw269-cw272` and `cw275`, using the final correction path where necessary.

- [ ] **Step 2: Verify dimensions.**

  ```bash
  identify -format '%f %wx%h %b\n' assets/exercises/cw{268..272}.webp assets/exercises/cw275.webp
  ```

  Expected: six nonempty `512x512` WebP files.

- [ ] **Step 3: Register the six IDs in ascending catalog order.**

  Add `cw268-cw272` after `cw267` and `cw275` after `cw274` in `illustratedExerciseIds`.

- [ ] **Step 4: Verify green contract.**

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-04-verified .
  ```

  Expected: no Flutter analysis findings and all tests pass, including registry, orphan-file and decoding tests.

## Task 5: Release One Web Image

**Files:**
- Modify: `pubspec.yaml`, `lib/app/app_version.g.dart`, `CHANGELOG.md`, `docs/exercise-illustrations-status.md`

- [ ] **Step 1: Set version `1.8.0+21` and generate the Dart version file.**

  ```bash
  docker run --rm --entrypoint /bin/sh -v /opt/fit:/app -w /app ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022 -c 'dart tools/generate_app_version.dart && dart tools/generate_app_version.dart --check'
  ```

- [ ] **Step 2: Record the six illustrations.**

  Add `cw268-cw272` and `cw275` to the status table with two frames each, add a `Czwarta partia` section, and add a changelog entry for the six IDs.

- [ ] **Step 3: Build and inspect the web candidate.**

  ```bash
  docker build --target runtime -f deploy/docker/web.Dockerfile -t fit-web:batch-04-candidate .
  docker run --rm --entrypoint /bin/sh fit-web:batch-04-candidate -c 'test -s /usr/share/nginx/html/assets/assets/exercises/cw268.webp && test -s /usr/share/nginx/html/assets/assets/exercises/cw275.webp && test -s /usr/share/nginx/html/sqlite3.wasm && test -s /usr/share/nginx/html/drift_worker.dart.js'
  ```

- [ ] **Step 4: Preserve rollback and deploy web only.**

  ```bash
  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  docker tag fit-web:production "fit-web:rollback-1.7.0-20-$timestamp"
  docker tag fit-web:batch-04-candidate fit-web:production
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web
  ```

- [ ] **Step 5: Verify public production.**

  ```bash
  curl -fsS https://fit.birek.online/api/health
  curl -fsS https://fit.birek.online/version.json
  curl -fsSI https://fit.birek.online/assets/assets/exercises/cw268.webp
  curl -fsSI https://fit.birek.online/assets/assets/exercises/cw275.webp
  curl -fsSI https://fit.birek.online/sqlite3.wasm
  curl -fsSI https://fit.birek.online/drift_worker.dart.js
  ```

  Expected: health `{"status":"ok"}`, version `1.8.0+21`, both WebP assets `200 image/webp`, Wasm `200 application/wasm`, and worker `200` with `Cache-Control: no-cache`.

## Plan Self-Review

- Spec coverage: Tasks 2 and 3 cover every approved scene and safety requirement; Task 4 restores tested offline registry consistency; Task 5 releases only web.
- Placeholder scan: every ID, prompt scene, command, file path and expected result is explicit.
- Consistency: IDs are ordered in catalog order and the release version is consistently `1.8.0+21`.
- Commit policy: do not commit or push unless the user explicitly requests it.
