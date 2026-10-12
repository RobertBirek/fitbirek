# Exercise Illustrations Batch 03 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add anatomically clear offline illustrations for the final three catalog exercises, `cw314-cw316`, and release them as one web-only version `1.7.0+20`.

**Architecture:** Each approved `1024x1024` source PNG becomes one `512x512` WebP in `assets/exercises`. The explicit Flutter registry and its test remain the source of truth. Prompts, ledgers and rejected PNGs stay in `/tmp/opencode`; only approved WebP files, registry, tests, status and release metadata enter the repository.

**Tech Stack:** OpenAI image edits via `tools/benchmark_exercise_images.py`, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker, Docker Compose, Nginx web runtime.

---

## File Structure

- Create: `assets/exercises/cw314.webp`, `assets/exercises/cw315.webp`, `assets/exercises/cw316.webp` - final offline assets.
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart` - register the three approved IDs.
- Modify: `test/features/exercises/exercise_illustrations_test.dart` - establish the expected set before production registration.
- Modify: `docs/exercise-illustrations-status.md` - record final frame counts and the third batch.
- Modify: `pubspec.yaml`, `lib/app/app_version.g.dart`, `CHANGELOG.md` - record release `1.7.0+20`.
- Create temporarily: prompts, ledgers and PNGs under `/tmp/opencode/cw314-*`, `/tmp/opencode/cw315-*`, and `/tmp/opencode/cw316-*`.

## Task 1: Establish The Registry Contract First

**Files:**
- Modify: `test/features/exercises/exercise_illustrations_test.dart`
- Modify later: `lib/features/exercises/presentation/exercise_illustrations.dart`

- [ ] **Step 1: Add the three expected IDs after `cw313`.**

  In `expectedIllustrationIds`, add:

  ```dart
  'cw314',
  'cw315',
  'cw316',
  ```

- [ ] **Step 2: Run the full verification target and observe the expected red contract.**

  Run:

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-03-red .
  ```

  Expected: `registry contains exactly the illustration assets in the catalog` fails because `illustratedExerciseIds` does not yet contain `cw314`.

- [ ] **Step 3: Keep the production registry unchanged until every source image is accepted.**

  Do not add any `cw314-cw316` entry to `illustratedExerciseIds` in this task.

## Task 2: Generate And Review The Controlled Dumbbell Squat Press

**Files:**
- Create temporarily: `/tmp/opencode/cw314-trial-01-prompt.txt`, `/tmp/opencode/cw314-trial-01/`
- Create later: `assets/exercises/cw314.webp`

- [ ] **Step 1: Write the first prompt.**

  Create `/tmp/opencode/cw314-trial-01-prompt.txt` with:

  ```text
  Use supplied image only as style reference. Clean 2D fitness art, cream
  background, dark outlines, faceless adult in dark neutral clothes, no text,
  numbers, arrows, labels or watermark. Square 1024x1024.

  Three clearly separated left-to-right panels showing a controlled dumbbell
  squat press. Panel 1: stand tall holding one dumbbell at each shoulder in a
  secure rack. Panel 2: a deep controlled squat with both dumbbells still at
  shoulders, knees tracking over toes and neutral spine. Panel 3: stand tall
  with both arms straight and vertically locked out, dumbbells directly above
  shoulders, ribs stacked over pelvis with no lumbar hyperextension. Use
  dumbbells only, never a barbell.
  ```

- [ ] **Step 2: Generate exactly one source PNG.**

  Run:

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw314-trial-01-prompt.txt \
      --reference /tmp/opencode/cw256-reference.png \
      --output-dir /tmp/opencode/cw314-trial-01 \
      --exercise-id cw314 --single-sunburst-medium
  ```

- [ ] **Step 3: Inspect the PNG before another paid request.**

  Read `/tmp/opencode/cw314-trial-01/cw314-gpt-image-2.5-sunburst-medium.png`.
  Reject it for a substituted barbell, knees collapsing inward, unclear rack or
  squat phase, unsupported overhead arms, or a lumbar overextension. If one
  named defect exists, write a new correction prompt that preserves the style
  and all valid phases, use the rejected PNG as the sole `--reference`, and use
  a new unclaimed output directory such as `/tmp/opencode/cw314-correction-01`.

## Task 3: Generate And Review The Burpee Pull-Up Combination

**Files:**
- Create temporarily: `/tmp/opencode/cw315-trial-01-prompt.txt`, `/tmp/opencode/cw315-trial-01/`
- Create later: `assets/exercises/cw315.webp`

- [ ] **Step 1: Write the first prompt.**

  Create `/tmp/opencode/cw315-trial-01-prompt.txt` with:

  ```text
  Use supplied image only as style reference. Clean 2D fitness art, cream
  background, dark outlines, faceless adult in dark neutral clothes, no text,
  numbers, arrows, labels or watermark. Square 1024x1024.

  Four clearly separated left-to-right panels showing a burpee and pull-up
  combination beneath a fixed horizontal pull-up bar. Panel 1: upright ready
  stance directly below the bar. Panel 2: low burpee plank with hands on floor,
  straight body and no sagging hips. Panel 3: controlled dead hang from the
  clearly visible bar with straight arms and no swinging. Panel 4: strict
  pull-up with chin visibly above the bar, neutral body and no kipping. Use
  bodyweight only; do not add weights, text, arrows or labels.
  ```

- [ ] **Step 2: Generate exactly one source PNG.**

  Run:

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw315-trial-01-prompt.txt \
      --reference /tmp/opencode/cw256-reference.png \
      --output-dir /tmp/opencode/cw315-trial-01 \
      --exercise-id cw315 --single-sunburst-medium
  ```

- [ ] **Step 3: Inspect the PNG before another paid request.**

  Read `/tmp/opencode/cw315-trial-01/cw315-gpt-image-2.5-sunburst-medium.png`.
  Reject it if the bar is absent, the burpee is shortened, plank hips sag,
  panel 3 is not a dead hang, panel 4 lacks chin-over-bar height, or the figure
  uses kipping. For a named defect only, use the rejected draft as the sole
  reference for a correction prompt and a new output directory.

## Task 4: Generate And Review The Alternating Carry

**Files:**
- Create temporarily: `/tmp/opencode/cw316-trial-01-prompt.txt`, `/tmp/opencode/cw316-trial-01/`
- Create later: `assets/exercises/cw316.webp`

- [ ] **Step 1: Write the first prompt.**

  Create `/tmp/opencode/cw316-trial-01-prompt.txt` with:

  ```text
  Use supplied image only as style reference. Clean 2D fitness art, cream
  background, dark outlines, faceless adult in dark neutral clothes, no text,
  numbers, arrows, labels or watermark. Square 1024x1024.

  Three clearly separated left-to-right panels showing an alternating dumbbell
  carry with a visible walking step in each panel. Panel 1: farmer carry with
  one dumbbell hanging at each side. Panel 2: suitcase carry with one dumbbell
  only in the figure's left hand. Panel 3: suitcase carry with one dumbbell
  only in the figure's right hand. In every panel the torso is tall and level,
  shoulders are even, the spine is neutral and the body does not lean toward
  the weight. Use dumbbells only, never a barbell.
  ```

- [ ] **Step 2: Generate exactly one source PNG.**

  Run:

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw316-trial-01-prompt.txt \
      --reference /tmp/opencode/cw256-reference.png \
      --output-dir /tmp/opencode/cw316-trial-01 \
      --exercise-id cw316 --single-sunburst-medium
  ```

- [ ] **Step 3: Inspect the PNG before another paid request.**

  Read `/tmp/opencode/cw316-trial-01/cw316-gpt-image-2.5-sunburst-medium.png`.
  Reject it if panel 1 lacks two dumbbells, either suitcase panel uses the
  wrong hand or two dumbbells, the subject leans toward the weight, or the
  carry lacks a readable walking step. Correct only named defects using the
  rejected draft as sole reference and a new output directory.

## Task 5: Convert Assets And Restore The Green Registry Contract

**Files:**
- Create: `assets/exercises/cw314.webp`, `assets/exercises/cw315.webp`, `assets/exercises/cw316.webp`
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart`
- Verify: `test/features/exercises/exercise_illustrations_test.dart`

- [ ] **Step 1: Convert each accepted source PNG to a stripped `512x512` WebP.**

  Replace each source path with the accepted trial or correction path, then run:

  ```bash
  convert /tmp/opencode/cw314-trial-01/cw314-gpt-image-2.5-sunburst-medium.png \
    -resize 512x512 -strip -quality 90 assets/exercises/cw314.webp
  convert /tmp/opencode/cw315-trial-01/cw315-gpt-image-2.5-sunburst-medium.png \
    -resize 512x512 -strip -quality 90 assets/exercises/cw315.webp
  convert /tmp/opencode/cw316-trial-01/cw316-gpt-image-2.5-sunburst-medium.png \
    -resize 512x512 -strip -quality 90 assets/exercises/cw316.webp
  ```

- [ ] **Step 2: Verify all three image dimensions and file sizes.**

  Run:

  ```bash
  identify -format '%f %wx%h %b\n' assets/exercises/cw{314..316}.webp
  ```

  Expected: three nonempty `512x512` WebP files.

- [ ] **Step 3: Add the accepted IDs to the production registry.**

  Insert after `cw313` in `illustratedExerciseIds`:

  ```dart
  'cw314',
  'cw315',
  'cw316',
  ```

- [ ] **Step 4: Run the full verification target and confirm green.**

  Run:

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-03-verified .
  ```

  Expected: Flutter analysis has no issues and all tests, including the
  illustration registry and `512x512` decoding test, pass.

## Task 6: Version And Deploy One Web Image

**Files:**
- Modify: `pubspec.yaml`, `lib/app/app_version.g.dart`, `CHANGELOG.md`, `docs/exercise-illustrations-status.md`

- [ ] **Step 1: Set version `1.7.0+20` and regenerate the Dart representation.**

  Change `version:` in `pubspec.yaml` to `1.7.0+20`, then run:

  ```bash
  docker run --rm --entrypoint /bin/sh -v /opt/fit:/app -w /app \
    ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022 \
    -c 'dart tools/generate_app_version.dart && dart tools/generate_app_version.dart --check'
  ```

- [ ] **Step 2: Update the release documentation.**

  Add a `1.7.0+20` changelog entry for illustrations `cw314-cw316`. In
  `docs/exercise-illustrations-status.md`, add rows with frame counts `3`, `4`,
  and `3`, then add a `Trzecia partia` section identifying `cw314-cw316`.

- [ ] **Step 3: Build and inspect the runtime candidate.**

  Run:

  ```bash
  docker build --target runtime -f deploy/docker/web.Dockerfile -t fit-web:batch-03-candidate .
  docker run --rm --entrypoint /bin/sh fit-web:batch-03-candidate -c \
    'test -s /usr/share/nginx/html/assets/assets/exercises/cw314.webp && \
     test -s /usr/share/nginx/html/assets/assets/exercises/cw316.webp && \
     test -s /usr/share/nginx/html/sqlite3.wasm && \
     test -s /usr/share/nginx/html/drift_worker.dart.js'
  ```

- [ ] **Step 4: Preserve rollback and deploy only `web`.**

  Tag the current `fit-web:production` with its actual current version before
  promotion, validate the installed Compose configuration without printing it,
  then recreate only web:

  ```bash
  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  docker tag fit-web:production "fit-web:rollback-1.6.0-19-$timestamp"
  docker tag fit-web:batch-03-candidate fit-web:production
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web
  ```

- [ ] **Step 5: Verify public production.**

  Run:

  ```bash
  curl -fsS https://fit.birek.online/api/health
  curl -fsS https://fit.birek.online/version.json
  curl -fsSI https://fit.birek.online/assets/assets/exercises/cw314.webp
  curl -fsSI https://fit.birek.online/assets/assets/exercises/cw316.webp
  curl -fsSI https://fit.birek.online/sqlite3.wasm
  curl -fsSI https://fit.birek.online/drift_worker.dart.js
  ```

  Expected: health is `{"status":"ok"}`, public version is `1.7.0+20`, both
  assets return `200 image/webp`, the Wasm asset returns `200 application/wasm`,
  and the worker returns `200` with `Cache-Control: no-cache`.

## Plan Self-Review

- Spec coverage: Tasks 2-4 cover every approved scene and its safety gates;
  Task 5 makes the tested offline registry complete; Task 6 releases only web.
- Placeholder scan: every scene, prompt, command, target path and expected
  result is explicit; no task depends on an unnamed implementation step.
- Consistency: all registry IDs, source paths, WebP paths, test IDs and release
  version use `cw314-cw316` and `1.7.0+20` consistently.
- Commit policy: do not create a Git commit or push unless the user explicitly
  requests it.
