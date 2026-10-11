# Exercise Illustrations Batch 02 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add locally available, anatomically clear illustrations for exercises `cw282-cw313` and deploy them in one web-only release.

**Architecture:** Each accepted source image is converted to a single `512x512` WebP in `assets/exercises`. The explicit Flutter registry and its test remain the source of truth for the asset set. Prompt files and rejected images stay in `/tmp/opencode`; only approved WebP files, the registry, tests, release metadata and status document enter the repository.

**Tech Stack:** OpenAI image edits through `tools/benchmark_exercise_images.py`, ImageMagick `convert`, Flutter/Dart in the pinned Docker image, Docker Compose, Nginx web runtime.

---

## File Structure

- Create: `assets/exercises/cw282.webp` through `assets/exercises/cw313.webp` - final local WebP assets.
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart` - add the 32 approved IDs.
- Modify: `test/features/exercises/exercise_illustrations_test.dart` - make the expected registry include every new ID before registering it.
- Modify: `docs/exercise-illustrations-status.md` - record the batch and final frame counts.
- Modify: `pubspec.yaml` - perform the next minor release version bump.
- Modify: `lib/app/app_version.g.dart` - generated from `pubspec.yaml`.
- Modify: `CHANGELOG.md` - narrowly describe the new illustrations.
- Create temporary only: `/tmp/opencode/cw282-...` through `/tmp/opencode/cw313-...` prompt files, ledgers and source PNGs.

## Task 1: Establish The Registry Contract First

**Files:**
- Modify: `test/features/exercises/exercise_illustrations_test.dart`
- Modify later: `lib/features/exercises/presentation/exercise_illustrations.dart`

- [ ] **Step 1: Extend the expected set in the illustration test, without changing the production registry.**

  Add these exact IDs after `cw281` in `expectedIllustrationIds`:

  ```dart
  'cw282', 'cw283', 'cw284', 'cw285', 'cw286', 'cw287', 'cw288', 'cw289',
  'cw290', 'cw291', 'cw292', 'cw293', 'cw294', 'cw295', 'cw296', 'cw297',
  'cw298', 'cw299', 'cw300', 'cw301', 'cw302', 'cw303', 'cw304', 'cw305',
  'cw306', 'cw307', 'cw308', 'cw309', 'cw310', 'cw311', 'cw312', 'cw313',
  ```

- [ ] **Step 2: Run the full Docker verification target and confirm the intended red state.**

  Run:

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-02-red .
  ```

  Expected: the test `registry contains exactly the illustration assets in the catalog` fails because `illustratedExerciseIds` lacks `cw282`.

- [ ] **Step 3: Do not change production code yet.**

  Keep the failing contract while generating and reviewing the asset set. It proves that a registered asset cannot be accidentally omitted from the batch.

## Task 2: Generate And Review Chair-Based Tai Chi And Recovery Assets

**Files:**
- Create temporarily: one prompt and output directory for each `cw282-cw301` under `/tmp/opencode`.
- Create later: `assets/exercises/cw282.webp` through `assets/exercises/cw301.webp`.

- [ ] **Step 1: Use the common visual constraints in every prompt.**

  Start every prompt with this exact constraint block and attach `/tmp/opencode/cw256-reference.png`:

  ```text
  Use supplied image only as style reference. Clean 2D fitness art, cream
  background, dark outlines, faceless adult in dark neutral clothes, no text,
  numbers, arrows, labels or watermark. Square 1024x1024.
  ```

- [ ] **Step 2: Generate and inspect each Tai Chi asset one at a time.**

  Use these scene instructions after the common block:

  | ID | Required prompt scene |
  |---|---|
  | cw282 | Two panels: upright seated chest opening, arms open on inhale then return to centre; relaxed shoulders. |
  | cw283 | Three panels: alternating cloud hands in front of torso, gentle rotation, gaze follows the active hand. |
  | cw284 | Four panels: seated ward off, roll back, press, then push; each hand position visibly distinct. |
  | cw285 | Three panels: alternating cloud-like hand waves with an arm path distinct from cw283; gentle torso rotation. |
  | cw286 | Three panels: seated parting wild horse's mane; one hand rises diagonally outward while the other lowers; show both sides. |
  | cw287 | Two panels: seated golden rooster; one knee lifted, opposite arm raised and other arm lowered, upright torso. |
  | cw288 | Three panels: one hand sweeps toward its knee while the opposite hand presses forward at chest height; show both sides. |
  | cw289 | Two panels: single whip; one hand extended laterally and the other forms a clear hook-hand silhouette; calm rotation. |
  | cw290 | Two panels: tall seated start then thoracic rotation while lightly holding the chair back; no forced end range. |
  | cw291 | Two panels: seated cat-cow with a visible chest-opening phase and a full-spine rounding phase. |
  | cw292 | Two panels: feet flat on floor, hip-hinge forward fold with a relaxed neck; no forced reach. |
  | cw293 | Two panels: figure-four ankle on opposite knee, then a long-back forward hinge; do not press the raised knee. |
  | cw294 | Two panels: one hand on hip and the other arm overhead in a pure side bend without rotation. |
  | cw295 | Two panels: ear moves gently toward shoulder; low shoulder and only light hand assistance at temple. |
  | cw296 | Two panels: seated shoulder circles forward then backward, shoulders clearly elevated only as part of the circle. |
  | cw297 | Two panels: seated eagle arms, crossed arms, palms or backs of hands together, elbows at shoulder height. |
  | cw298 | Two panels: one foot raised and ankle circles shown in both directions; stable seated posture. |
  | cw299 | Two panels: stable sit on chair edge, pelvic circle in opposite directions, torso upright; one small curved arrow beside the pelvis in each panel is permitted only to show direction. |
  | cw300 | One panel: calm upright seated box-breathing posture, hands on thighs; do not draw timing diagrams or breath holds. |
  | cw301 | One panel: upright seated diaphragmatic breathing with one hand on chest and one on abdomen. |

- [ ] **Step 3: Make each paid request separately with an unclaimed output directory.**

  For `cw282`, run this form; repeat with the corresponding ID and prompt path only after visually reviewing the previous image:

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw282-trial-01-prompt.txt \
      --reference /tmp/opencode/cw256-reference.png \
      --output-dir /tmp/opencode/cw282-trial-01 \
      --exercise-id cw282 --single-sunburst-medium
  ```

- [ ] **Step 4: Accept only anatomically clear scenes.**

  Reject an image if a hand position makes the Tai Chi variant indistinguishable, a chair is unstable, the neck is pulled, `cw293` presses the knee, or muscle color is painted on joints. After a rejection, write a new targeted prompt and generate a new output directory; never reuse an output directory.

## Task 3: Generate And Review Dynamic Strength Assets

**Files:**
- Create temporarily: prompts and outputs for `cw302-cw313` under `/tmp/opencode`.
- Create later: `assets/exercises/cw302.webp` through `assets/exercises/cw313.webp`.

- [ ] **Step 1: Use draft-as-reference corrections only for named pose defects.**

  `benchmark_exercise_images.py` sends exactly one PNG to the image API. First
  attempts therefore use `cw256-reference.png` as the style reference. If a
  compound movement has a named pose defect, use that rejected draft as the
  sole `--reference` image for the correction request and state which visual
  elements must remain unchanged. For `cw303`, the correction request form is:

  ```bash
  set -a && source /root/.config/fit/openai.env && set +a && \
    python3 tools/benchmark_exercise_images.py \
      --prompt /tmp/opencode/cw303-correction-01-prompt.txt \
      --reference /tmp/opencode/cw303-trial-01/cw303-gpt-image-2.5-sunburst-medium.png \
      --output-dir /tmp/opencode/cw303-correction-01 \
      --exercise-id cw303 --single-sunburst-medium
  ```

  The correction prompt must preserve the accepted styling and phases while
  replacing only the named defect, for example a rotated plank hip.

- [ ] **Step 2: Use the common visual constraints from Task 2 and these exact scenes.**

  | ID | Required prompt scene |
  |---|---|
  | cw302 | Three panels: dumbbells at shoulders, deep controlled squat, then stable overhead lockout. |
  | cw303 | Four panels: push-up on dumbbells, left row, right row, then squat-to-press; wide feet and square hips in plank. |
  | cw304 | Four panels: controlled burpee with dumbbells, low position, hip-driven double-dumbbell snatch, stable overhead finish. |
  | cw305 | Three panels: hip-driven clean to rack, overhead press, controlled return; do not pull with arms from the floor. |
  | cw306 | Three panels: one dumbbell between feet in hinge, hip drive, one-arm lockout; show a safe side change only if room permits. |
  | cw307 | Two panels: dumbbell back-swing in a neutral-spine hinge, then shoulder-height swing from hip drive; never a squat. |
  | cw308 | Four panels: supine start, elbow/hand support, kneeling transition, standing finish; dumbbell remains vertically stacked over shoulder and gaze follows it. |
  | cw309 | Three panels: squat, curl during standing, overhead press; controlled reverse order on return. |
  | cw310 | Three panels: plank on dumbbells, push-up, alternating row; use a wide base and square hips. |
  | cw311 | Two panels: forward lunge with simultaneous curl, then upright return; front knee tracks the toes. |
  | cw312 | Three panels: Romanian deadlift hinge, row toward hips in bottom position, hip extension to upright; neutral spine throughout. |
  | cw313 | Four panels: low bear crawl forward, push-up, crawl backward, push-up; knees hover and hips do not sag. |

- [ ] **Step 3: Apply mandatory safety review before acceptance.**

  Reject any final image with lumbar hyperextension, a bent or unsupported overhead arm, a barbell substituted for dumbbells, a shoulder-height swing driven by arms, a Turkish get-up that loses the vertical dumbbell stack, plank hips rotating in `cw303` or `cw310`, or a front knee collapsing inward in `cw311`.

- [ ] **Step 4: Regenerate only for named defects.**

  A correction prompt must state the visible fault and the required replacement, for example: `Keep the dumbbell directly above the shoulder in every panel; do not lower it behind the torso during the Turkish get-up.`

## Task 4: Convert Accepted Sources And Make The Contract Green

**Files:**
- Create: `assets/exercises/cw282.webp` through `assets/exercises/cw313.webp`
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart`
- Modify: `test/features/exercises/exercise_illustrations_test.dart`

- [ ] **Step 1: Convert each accepted `1024x1024` PNG to a final WebP.**

  For each accepted source, use this command with its ID and source path:

  ```bash
  convert /tmp/opencode/cw282-trial-01/cw282-gpt-image-2.5-sunburst-medium.png \
    -resize 512x512 -strip -quality 90 assets/exercises/cw282.webp
  ```

- [ ] **Step 2: Verify dimensions and existence for all 32 files.**

  Run:

  ```bash
  identify -format '%f %wx%h %b\n' assets/exercises/cw{282..313}.webp
  ```

  Expected: every listed file is a nonempty `512x512` WebP.

- [ ] **Step 3: Add `cw282-cw313` to `illustratedExerciseIds`.**

  Insert every ID in ascending order after `cw281`:

  ```dart
  'cw282', 'cw283', 'cw284', 'cw285', 'cw286', 'cw287', 'cw288', 'cw289',
  'cw290', 'cw291', 'cw292', 'cw293', 'cw294', 'cw295', 'cw296', 'cw297',
  'cw298', 'cw299', 'cw300', 'cw301', 'cw302', 'cw303', 'cw304', 'cw305',
  'cw306', 'cw307', 'cw308', 'cw309', 'cw310', 'cw311', 'cw312', 'cw313',
  ```

- [ ] **Step 4: Run the contract test through Docker and confirm green.**

  Run:

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-02-verified .
  ```

  Expected: analysis has no issues and all Flutter tests, including the registry and 512x512 decoding test, pass.

## Task 5: Update Release Metadata And Deploy One Web Image

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/app/app_version.g.dart`
- Modify: `CHANGELOG.md`
- Modify: `docs/exercise-illustrations-status.md`

- [ ] **Step 1: Apply version `1.6.0+19` and generate its Dart representation.**

  Change `version:` in `pubspec.yaml` from `1.5.1+18` to `1.6.0+19`. Then run:

  ```bash
  docker run --rm --entrypoint /bin/sh -v /opt/fit:/app -w /app \
    ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022 \
    -c 'dart tools/generate_app_version.dart && dart tools/generate_app_version.dart --check'
  ```

- [ ] **Step 2: Record every new illustration in the status document.**

  Add rows for `cw282-cw313` with the final frame counts. Add a `Druga partia`
  heading that identifies the completed `cw282-cw313` batch; retain the
  historical `Pierwsza partia` section. Add a concise changelog entry listing
  the ID range.

- [ ] **Step 3: Build and inspect the web runtime candidate.**

  Run:

  ```bash
  docker build --target runtime -f deploy/docker/web.Dockerfile \
    -t fit-web:batch-02-candidate .
  docker run --rm --entrypoint /bin/sh fit-web:batch-02-candidate -c \
    'test -s /usr/share/nginx/html/assets/assets/exercises/cw282.webp && \
     test -s /usr/share/nginx/html/assets/assets/exercises/cw313.webp && \
     test -s /usr/share/nginx/html/sqlite3.wasm && \
     test -s /usr/share/nginx/html/drift_worker.dart.js'
  ```

- [ ] **Step 4: Preserve rollback and deploy only `web`.**

  Use a timestamped rollback tag for the current `fit-web:production`, promote the inspected candidate, validate all three installed Compose files without printing resolved configuration, then recreate only the web service:

  ```bash
  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  docker tag fit-web:production "fit-web:rollback-1.6.0-19-$timestamp"
  docker tag fit-web:batch-02-candidate fit-web:production
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web
  ```

- [ ] **Step 5: Verify public production.**

  Run:

  ```bash
  curl -fsS https://fit.birek.online/api/health
  curl -fsS https://fit.birek.online/version.json
  curl -fsSI https://fit.birek.online/assets/assets/exercises/cw282.webp
  curl -fsSI https://fit.birek.online/assets/assets/exercises/cw313.webp
  curl -fsSI https://fit.birek.online/sqlite3.wasm
  curl -fsSI https://fit.birek.online/drift_worker.dart.js
  ```

  Expected: API health reports `{"status":"ok"}`, the public version matches `AppVersion.full`, all assets return `200 image/webp`, Wasm returns `200 application/wasm`, and the worker returns `200` with `Cache-Control: no-cache`.

## Plan Self-Review

- Spec coverage: Tasks 2 and 3 implement every `cw282-cw313` scenario; Task 4 integrates and tests the local assets; Task 5 versions and deploys only the web service.
- Placeholder scan: the plan has no incomplete tasks; every selected ID has an explicit scene and acceptance conditions.
- Consistency: asset names, registry IDs, test IDs and production paths all use the same `cw282-cw313` range.
- Commit policy: do not create a Git commit unless the user explicitly requests one.
