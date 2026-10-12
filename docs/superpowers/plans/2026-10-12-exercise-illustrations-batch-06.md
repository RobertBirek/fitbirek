# Exercise Illustrations Batch 06 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, review and locally integrate six offline illustrations for `cw007–cw012`, with three frames for `cw007` and `cw011` and two for the other exercises.

**Architecture:** Generate separate 1024×1024 PNGs, inspect every result and its 512×512 preview, then convert all accepted sources to one WebP per exercise. The existing registry, exact asset-set test and decoding test remain the integration contract. Publication is a separate decision.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6 (`convert`), Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Working context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json` and `docs/superpowers/specs/2026-10-12-exercise-illustrations-batch-06-design.md`.
- Work in `/opt/fit`, current `main`, without a worktree, following the user's existing preference. Preserve all uncommitted work from Parts 04 and 05, including their asset files and release metadata.
- Create six files: `assets/exercises/cw007.webp`, `cw008.webp`, `cw009.webp`, `cw010.webp`, `cw011.webp`, `cw012.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary only: prompts, PNGs, previews and ledgers under `/tmp/opencode/cw007-*` through `/tmp/opencode/cw012-*`.
- Style reference: `assets/exercises/cw256.webp`. First-request PNG reference: `/tmp/opencode/cw256-reference.png`.
- Baseline: 72 local illustrations, 66 published, 6 unpublished, 244 without illustrations, 316 catalog records. Final local counts: 78, 66, 12, 238, 316 respectively.
- Do not change catalog IDs, dependency versions, release metadata or production configuration. No deployment, commit or push without a separate explicit request.

## Task 1: Establish the red registry contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` to identify preserved earlier work.
- [ ] Add these six entries after `cw006`, before `cw251`, in `expectedIllustrationIds`:

```dart
    'cw007',
    'cw008',
    'cw009',
    'cw010',
    'cw011',
    'cw012',
```

- [ ] Move the existing absent-asset assertion to the next unillustrated ID:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw013'), isNull);
  });
```

- [ ] Run with a timeout of at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-06-red .
```

Expected: registry equality fails because production lacks `cw007`; the `cw013` fallback passes. Investigate unrelated failures before proceeding. Production IDs and WebP assets remain unchanged until all six scenes are accepted.

## Task 2: Prepare and review exact prompts

**Files:** `/tmp/opencode/cw007-trial-01-prompt.txt` through `/tmp/opencode/cw012-trial-01-prompt.txt`.

- [ ] Read the reference WebP and existing PNG; require pixel-equivalent style reference. If the PNG is missing, create it after verifying its parent directory:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write six prompt files using the file-editing tool. Each starts with this common paragraph followed by its exact scene paragraph:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark outlines, faceless adult in dark neutral clothes. No text, numbers, arrows, labels or watermark. Square 1024x1024. Same adult, camera, equipment and working side across all frames of the exercise; any torso rotation is the movement, not a camera change. Entire body, hands, feet and equipment visible with clear support contacts and generous margins. No required colored muscle overlays. Anatomically coherent limbs and grips, no duplicated limbs. Make every phase and relevant floor or equipment contact distinguishable after reduction to 512x512.
```

`/tmp/opencode/cw007-trial-01-prompt.txt` scene:

```text
Hindu push-up. EXACTLY THREE separated full-width horizontal panels stacked vertically, read top to bottom. Fixed side three-quarter camera. Top: hands and feet grounded, straight arms, hips high in an inverted V. Middle: elbows bent, head and chest sweep low forward between the hands in a visible diving transition, distinct from both end positions. Bottom: straight arms, chest opened and lifted, hips lowered in an upward-dog-like finish, hands and feet still supported. Keep a controlled spine, no collapsed lumbar region or forceful backward head tilt. Do not show a divebomber return sequence. All three entire-body poses must fit within their separate panels.
```

`/tmp/opencode/cw008-trial-01-prompt.txt` scene:

```text
Spiderman push-up. EXACTLY TWO separated side-by-side panels, read left to right. Slightly elevated side three-quarter camera on the working-leg side. Left: high plank, both palms and both sets of toes grounded. Right: low push-up, the nearer knee moves outward toward the SAME-SIDE elbow; that foot is off the floor and the opposite toes remain supported. Chest lowers while the torso stays stable and hips parallel to the floor. Show one side only, no change of working leg between frames. No knee toward the opposite elbow, pelvic twist, raised hips or mountain-climber-only pose without a push-up descent.
```

`/tmp/opencode/cw009-trial-01-prompt.txt` scene:

```text
Decline push-up with feet elevated. EXACTLY TWO separated side-by-side panels, read left to right. Fixed side three-quarter camera showing both hands and the entire stable low bench, naturally about 30-50 cm high relative to the adult. Left: high plank with both feet supported on the bench and both palms on the floor. Right: bent elbows, chest lowered between the hands, feet still supported in the same place. Maintain a straight head-to-heel line without folding at the hips. No high pike position, sagging hips, head-only descent or floating bench contacts.
```

`/tmp/opencode/cw010-trial-01-prompt.txt` scene:

```text
Deep push-up on dumbbells. EXACTLY TWO separated side-by-side panels, read left to right. Fixed side three-quarter camera revealing both hand grips and the hand height above the floor. Left: high plank, each hand grips the HANDLE of one of exactly two normal-sized hexagonal dumbbells; flat dumbbell heads rest stably on the floor, toes grounded. Right: elbows about 45 degrees from the torso and chest lowered BELOW hand level but not through the floor, with identical dumbbell placement. Show the increased range without collapsing shoulders or exaggerating depth. No rolling round dumbbells, hands resting on dumbbell heads, floating equipment or artificially tall dumbbells.
```

`/tmp/opencode/cw011-trial-01-prompt.txt` scene:

```text
T push-up with torso rotation. EXACTLY THREE separated full-width horizontal panels stacked vertically, read top to bottom. Fixed front-side three-quarter camera facing the side toward which the chest opens. Top: low push-up with both palms and feet supported. Middle: high plank after pressing up, both arms straight. Bottom: rotate chest AND pelvis together into a side support, one palm directly under its shoulder, opposite arm straight vertically upward, head turned toward the raised hand. Feet rotate onto their edges and may be slightly staggered for balance; no need to stack them. Hips stay lifted, the arms form a straight line creating a T with the torso. Same working side and fixed camera. No dropped hips, bent upper arm, extra supporting hand or arm-only rotation.
```

`/tmp/opencode/cw012-trial-01-prompt.txt` scene:

```text
Dumbbell bench press on a FLAT bench. EXACTLY TWO separated side-by-side panels, read left to right. Slightly elevated side three-quarter camera showing both dumbbells, elbows, full bench and feet. Left: adult lying supine, both feet flat on the floor, head, upper back and buttocks supported; dumbbells beside the chest, wrists above elbows, elbows about 45 degrees from the torso. Right: press the two dumbbells above the CHEST, arms straight without exaggerated hyperextension, dumbbells separate and not colliding. Preserve all body support contacts, allow a small natural back curve. No inclined bench, lifted feet or buttocks, bent-back wrists, uneven pressing or weights above the face.
```

- [ ] Review prompt specification compliance, then clarity and anatomical coherence. Resolve findings before the first paid request. For subagent execution, use independent reviewers in that order.

## Task 3: Generate and review cw007–cw009

**Files:** temporary PNGs, previews and ledgers only. Use a 240-second or longer request timeout. Never display the credential file or environment values.

- [ ] Execute the `cw007` request alone, after confirming the output directory does not exist:

```bash
test ! -e /tmp/opencode/cw007-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw007-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw007-trial-01 --exercise-id cw007 --single-sunburst-medium
```

- [ ] Read its source PNG, create the preview, and read the preview:

```bash
convert /tmp/opencode/cw007-trial-01/cw007-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw007-trial-01/review-512.png
```

Require three stacked phases including the distinct low diving transition, stable supports and no lumbar collapse. Record an accepted path or name the defect before any next paid request.

- [ ] After reviewing `cw007`, issue one `cw008` request:

```bash
test ! -e /tmp/opencode/cw008-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw008-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw008-trial-01 --exercise-id cw008 --single-sunburst-medium
```

- [ ] Read the original, create and read its preview:

```bash
convert /tmp/opencode/cw008-trial-01/cw008-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw008-trial-01/review-512.png
```

Require a low push-up with a same-side knee-to-elbow approach, the working foot off the floor, opposite toes supported, and hips not twisted or raised.

- [ ] After reviewing `cw008`, issue one `cw009` request:

```bash
test ! -e /tmp/opencode/cw009-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw009-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw009-trial-01 --exercise-id cw009 --single-sunburst-medium
```

- [ ] Read the original, create and read its preview:

```bash
convert /tmp/opencode/cw009-trial-01/cw009-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw009-trial-01/review-512.png
```

Require both feet clearly supported on the same low bench, straight body and a chest-led descent rather than a pike or head-only motion.

- [ ] Complete specification review first, quality review second, checking the actual original and 512px files. For subagent execution use separate review agents, fixing any findings before proceeding to the next task.

## Task 4: Generate and review cw010–cw012

**Files:** temporary PNGs, previews and ledgers only.

- [ ] Execute one `cw010` request:

```bash
test ! -e /tmp/opencode/cw010-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw010-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw010-trial-01 --exercise-id cw010 --single-sunburst-medium
```

- [ ] Read the original, create and read its preview:

```bash
convert /tmp/opencode/cw010-trial-01/cw010-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw010-trial-01/review-512.png
```

Require two grounded hex dumbbells, handle grips and chest visibly below hand level in the low phase, without impossible floor penetration or collapsed shoulders.

- [ ] After reviewing `cw010`, execute one `cw011` request:

```bash
test ! -e /tmp/opencode/cw011-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw011-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw011-trial-01 --exercise-id cw011 --single-sunburst-medium
```

- [ ] Read the original, create and read its preview:

```bash
convert /tmp/opencode/cw011-trial-01/cw011-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw011-trial-01/review-512.png
```

Require three stacked phases, chest and pelvis rotating together, one supporting palm, a straight raised arm, supported feet and lifted hips, with no camera change.

- [ ] After reviewing `cw011`, execute one `cw012` request:

```bash
test ! -e /tmp/opencode/cw012-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw012-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw012-trial-01 --exercise-id cw012 --single-sunburst-medium
```

- [ ] Read the original, create and read its preview:

```bash
convert /tmp/opencode/cw012-trial-01/cw012-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw012-trial-01/review-512.png
```

Require flat bench, head/back/buttocks supported, both feet grounded, low wrists above elbows and top weights over chest rather than face, with no dumbbell collision.

- [ ] Complete independent specification and quality reviews in that order, resolving issues before integration.

### Correction procedure for Tasks 3 and 4

Record the specific visible defect before correction. Write a new prompt preserving accepted phases, body and style while correcting only that defect. Use the immediately rejected PNG as the sole reference and a fresh numbered prompt/output path, retaining the actual exercise ID and `--single-sunburst-medium`. Check the output directory is absent before the request. Inspect both new source and preview before another paid request. Keep an explicit accepted-source list for all six IDs. If successive corrections do not remove the same defect, stop paid calls and ask to revise the scene. Never automatically repeat failed API requests or silently switch a three-frame exercise to two frames.

## Task 5: Integrate all six approved assets and restore green

**Files:** six new WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all six source paths have passed both reviews and verify `assets/exercises/` exists. Convert the accepted sources using `-resize 512x512 -strip -quality 90`. If first trials were accepted, the exact commands are:

```bash
convert /tmp/opencode/cw007-trial-01/cw007-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw007.webp
convert /tmp/opencode/cw008-trial-01/cw008-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw008.webp
convert /tmp/opencode/cw009-trial-01/cw009-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw009.webp
convert /tmp/opencode/cw010-trial-01/cw010-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw010.webp
convert /tmp/opencode/cw011-trial-01/cw011-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw011.webp
convert /tmp/opencode/cw012-trial-01/cw012-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw012.webp
```

For a corrected image replace only its source path with the recorded accepted PNG. Do not convert a rejected source simply because it appears in the example.

- [ ] Check final dimensions and nonempty sizes:

```bash
identify -format '%f %wx%h %b\n' assets/exercises/cw007.webp assets/exercises/cw008.webp assets/exercises/cw009.webp assets/exercises/cw010.webp assets/exercises/cw011.webp assets/exercises/cw012.webp
```

Expected: six nonempty `512x512` WebP files. Read final files to confirm frame counts 3/2/2/2/3/2 survived conversion.

- [ ] Insert these entries after `cw006`, before `cw251`, in `illustratedExerciseIds`, preserving all previous entries and the mapping function:

```dart
  'cw007',
  'cw008',
  'cw009',
  'cw010',
  'cw011',
  'cw012',
```

- [ ] Run with a timeout of at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-06-verified .
```

Expected: generated version check succeeds, analysis has no findings, full test suite passes, 78 files match 78 registered/expected IDs, each image decodes as 512×512, and `cw013` remains the absent-asset case. Visual frame count is a review responsibility, not a pixel-count test. Generated model code stays inside the Docker build; no dependency or Web SQLite updates are needed.

- [ ] Review specification compliance then integration quality before recording the task complete.

## Task 6: Update package status and perform final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve the published version `1.8.0+21` and all prior history, including Part 04 rollback and unpublished Part 05 status. Replace opening counts with:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 78 ilustracji:
66 wydanych oraz 12 lokalnie zintegrowanych z Partii 05 i 06.
238 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Insert these table rows immediately after `cw006`, before `cw251`:

```markdown
| cw007 | Pompki hinduskie | 3 | Lokalnie zintegrowane; niewydane. |
| cw008 | Pompki z przyciąganiem kolana do łokcia | 2 | Lokalnie zintegrowane; niewydane. |
| cw009 | Pompki z podniesionymi nogami | 2 | Lokalnie zintegrowane; niewydane. |
| cw010 | Głębokie pompki na hantlach | 2 | Lokalnie zintegrowane; niewydane. |
| cw011 | Pompki z rotacją | 3 | Lokalnie zintegrowane; niewydane. |
| cw012 | Wyciskanie hantli na ławce płaskiej | 2 | Lokalnie zintegrowane; niewydane. |
```

- [ ] Add the following section after Part 05 and before the general rules:

```markdown
## Szósta partia

Zakres szóstej partii obejmuje `cw007–cw012`. Wszystkie sześć zatwierdzonych
WebP 512×512 jest lokalnie zintegrowanych. `cw007` i `cw011` mają po trzy
kadry w poziomych pasach, pozostałe cztery ćwiczenia po dwa kadry.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów. Pakiet nie jest
jeszcze wydany; wersja produkcyjna pozostaje `1.8.0+21`.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`, and confirm only intended Part 06 additions on top of preserved earlier work.
- [ ] Perform final compliance and quality review of all six final files, mapping/test and status. Confirm local 78 vs published 66, correct 3/2/2/2/3/2 frame counts and fallback `cw013`.
- [ ] Report accepted source paths, analysis/test results, request count and ledger-estimated costs, and any unresolved findings. Stop at a prepared package; publication, version bump, deployment, commit and push require separate decisions.

## Plan self-review

- Coverage: Tasks 2–4 define all six scenes, prescribed cameras and frame layouts with separate visual checks; Task 5 integrates accepted sources together and restores green.
- Fallback and order: test and production insert `cw007–cw012` after `cw006`; Task 1 moves the missing-asset case to `cw013`.
- Counts: 78 local, 66 published, 12 unpublished, 238 missing, 316 catalog records.
- Review boundary: code tests verify asset sets and decoding; actual images are reviewed for pose correctness, anatomy and 3/2/2/2/3/2 frames at 512px.
- Scope: Task 6 records local status without modifying release metadata or production; earlier parts remain preserved and no commit/push is automatic.
