# Exercise Illustrations Batch 07 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, review and locally integrate six two-frame dumbbell press and flye illustrations for `cw013–cw018`.

**Architecture:** Generate separate 1024×1024 PNGs, inspect each source and its 512×512 preview, then convert all accepted sources to one WebP per exercise. The existing registry, exact asset-set test and decoding test remain the integration contract. Production stays at 1.9.0+22 until a separate release decision.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6 (`convert`), Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-12-exercise-illustrations-batch-07-design.md`.
- Work in `/opt/fit`, current `main`, without a worktree, following the user's existing preference. Preserve any work already present when execution starts.
- Create: `assets/exercises/cw013.webp`, `cw014.webp`, `cw015.webp`, `cw016.webp`, `cw017.webp`, `cw018.webp`.
- Modify: `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary only: prompts, PNGs, review previews and ledgers under `/tmp/opencode/cw013-*` through `/tmp/opencode/cw018-*`.
- Style reference: `assets/exercises/cw256.webp`; first-request PNG reference: `/tmp/opencode/cw256-reference.png`.
- Baseline: 78 local/published illustrations and 238 missing from 316 catalog records. Final local state: 84 illustrations, 78 published, 6 unpublished, 232 missing.
- `cw015` is explicitly approved as a standing squeeze press, not a lying bench press.
- No automatic deployment, version bump, commit or push. The earlier request to publish Parts 04–06 has already been fulfilled.

## Task 1: Establish the red registry contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` before editing.
- [ ] Add the following entries after `cw012`, before `cw251`, in `expectedIllustrationIds`, retaining the previous 78 entries:

```dart
    'cw013',
    'cw014',
    'cw015',
    'cw016',
    'cw017',
    'cw018',
```

- [ ] Move the existing absent-asset assertion to `cw019`:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw019'), isNull);
  });
```

- [ ] Run with a timeout of at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-07-red .
```

Expected: registry equality fails because production lacks `cw013`; fallback for `cw019` passes. Investigate unrelated failures before any paid image request. Leave production registry and asset files unchanged until all six images pass their reviews.

## Task 2: Prepare and review the six exact prompts

**Files:** `/tmp/opencode/cw013-trial-01-prompt.txt` through `/tmp/opencode/cw018-trial-01-prompt.txt`.

- [ ] Read the reference WebP and existing PNG; require a matching reference. If the PNG is missing, create it after checking its parent directory:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write each prompt through the file-editing tool, using this common paragraph followed by its exact scene paragraph below:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark outlines, faceless adult in dark neutral clothes. No text, numbers, arrows, labels or watermark. Square 1024x1024. EXACTLY TWO separated side-by-side panels, read left to right. Same adult, fixed camera, equipment and body support contacts in both panels. Entire body and equipment fit within each panel with generous margins. Exactly TWO separate dumbbells, one handle gripped by each hand. Make both grips, elbow positions, dumbbell placement and relevant floor or bench contacts readable at 512x512. Natural perspective and occlusion, no transparent anatomy, merged weights or duplicated limbs. No required colored muscle overlays. Keep wrists aligned, stable body support and controlled movement.
```

`/tmp/opencode/cw013-trial-01-prompt.txt` scene:

```text
Incline dumbbell press. Fixed slightly elevated side three-quarter camera showing both weights and the bench angle. Bench backrest inclined about 30-45 degrees, not flat and not steeper than 60 degrees. Both feet flat on the floor; head, upper back and buttocks supported. Left: dumbbells beside the UPPER CHEST, elbows bent about 45 degrees away from the torso, wrists above elbows. Right: press both dumbbells above the upper chest, arms straight without exaggerated hyperextension; weights remain separate and body contacts unchanged. No dumbbells beside the face or above the face, lifted back, bent-back wrists or seated overhead-press pose.
```

`/tmp/opencode/cw014-trial-01-prompt.txt` scene:

```text
Dumbbell floor press, NO BENCH. Fixed slightly elevated side three-quarter camera showing both arms and their floor contacts. Adult supine on the floor, knees bent, both feet flat, head, back and buttocks grounded. Left: elbows and backs of upper arms gently contact the floor; elbows bent about 90 degrees and angled about 45 degrees from the torso, wrists vertically above elbows, two separate weights beside the chest. Right: press the weights above the chest, arms straight, weights separate, all body and foot contacts unchanged. Show a controlled floor-limited range, not a bounce. No floating low elbows, floor penetration, lifted hips or weights above the face.
```

`/tmp/opencode/cw015-trial-01-prompt.txt` scene:

```text
Standing dumbbell squeeze press, NOT LYING. Fixed front-side three-quarter camera revealing both independent hand grips. Upright stable stance, feet about hip width, knees relaxed, torso still. Left: hold TWO separate dumbbells side by side, actively pressed together in front of the chest, one hand gripping EACH separate handle, elbows bent. Right: press forward and slightly upward to about upper-chest height, elbows nearly straight, with the SAME TWO dumbbells STILL TOUCHING. Show separate heads and handles despite contact. No shared bar, one weight held by both hands, separation of weights in the second phase, backward body lean or overhead press.
```

`/tmp/opencode/cw016-trial-01-prompt.txt` scene:

```text
Dumbbell flye on a FLAT bench, NOT a press. Fixed elevated front-side three-quarter camera revealing the spread of both arms. Adult supine, both feet flat on floor, head, upper back and buttocks supported. Left: open arms widely sideways only to chest level, elbows SOFTLY BENT, neutral grips with palms facing each other. Right: bring the dumbbells close above the chest in an arc, without colliding, retaining the SAME slight elbow bend. Body supports unchanged. The movement comes from bringing the upper arms together, not bending and straightening the elbows as in a press. No fully straight low elbows, arms far below chest level, collapsed shoulders or inclined bench.
```

`/tmp/opencode/cw017-trial-01-prompt.txt` scene:

```text
Incline dumbbell flye, NOT a press. Fixed elevated front-side three-quarter camera showing both arms and the backrest clearly inclined about 30 degrees. Head, upper back and buttocks supported, both feet on floor. Left: arms open widely sideways to chest level, elbows softly bent, neutral grips. Right: bring the dumbbells close above the UPPER CHEST without collision, retaining the SAME slight elbow bend and all body supports. No flat or steep backrest, elbow straightening, excessive low depth or bent-to-straight pressing action. Make both the incline and flye arm path distinct at 512x512.
```

`/tmp/opencode/cw018-trial-01-prompt.txt` scene:

```text
Dumbbell floor flye, NO BENCH and NOT a floor press. Fixed elevated front-side three-quarter camera revealing both arms and elbow contacts. Adult supine on floor, knees bent, both feet flat, head, back and buttocks grounded. Left: arms open widely to the sides, elbows only SLIGHTLY bent and gently touching the floor as a range limiter. Right: bring both weights close above the chest in an arc, without colliding, retaining the SAME slight elbow bend and unchanged body support. Low arms must be visibly wider and straighter than in a floor press, not bent 90 degrees. No absent low elbow contact, impact or floor penetration, elbow straightening or lifted hips.
```

- [ ] Review scene compliance first, then prompt clarity and anatomical coherence. Resolve findings before paid requests. For subagent execution use independent reviewers in that order.

## Task 3: Generate and review cw013–cw015 sequentially

**Files:** temporary PNGs, previews and ledgers only. Use request timeout at least 240 seconds. Never display credential-file contents or environment values.

- [ ] Check the output directory is fresh and issue the `cw013` request alone:

```bash
test ! -e /tmp/opencode/cw013-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw013-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw013-trial-01 --exercise-id cw013 --single-sunburst-medium
```

- [ ] Read the source PNG, then create and read the preview:

```bash
convert /tmp/opencode/cw013-trial-01/cw013-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw013-trial-01/review-512.png
```

Require visible 30–45° backrest, upper-chest low weights, wrist/elbow alignment, separated top weights and stable bench/foot contacts. Record accepted path or name a defect before the next paid request.

- [ ] After reviewing `cw013`, issue `cw014` alone:

```bash
test ! -e /tmp/opencode/cw014-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw014-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw014-trial-01 --exercise-id cw014 --single-sunburst-medium
```

- [ ] Read its original and create/read the preview:

```bash
convert /tmp/opencode/cw014-trial-01/cw014-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw014-trial-01/review-512.png
```

Require floor contact of low elbows/upper arms, knees bent and feet flat, two correct grips, no bench, floor penetration or lifted hips.

- [ ] After reviewing `cw014`, issue `cw015` alone:

```bash
test ! -e /tmp/opencode/cw015-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw015-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw015-trial-01 --exercise-id cw015 --single-sunburst-medium
```

- [ ] Read its original and create/read the preview:

```bash
convert /tmp/opencode/cw015-trial-01/cw015-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw015-trial-01/review-512.png
```

Require standing posture, two separate handles and weights remaining in contact during forward/slightly-upward extension, without backward lean or overhead motion.

- [ ] Complete scene-compliance review, then quality review of originals and previews; resolve findings before the next task. For subagent execution use separate reviewers.

## Task 4: Generate and review cw016–cw018 sequentially

**Files:** temporary PNGs, previews and ledgers only.

- [ ] Issue `cw016` alone:

```bash
test ! -e /tmp/opencode/cw016-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw016-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw016-trial-01 --exercise-id cw016 --single-sunburst-medium
```

- [ ] Read its original and create/read the preview:

```bash
convert /tmp/opencode/cw016-trial-01/cw016-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw016-trial-01/review-512.png
```

Require flat bench, broad arm opening only to chest level, constant slight elbow bend and neutral grips. Compare against the published `assets/exercises/cw012.webp`: flye must not resemble a press.

- [ ] After reviewing `cw016`, issue `cw017` alone:

```bash
test ! -e /tmp/opencode/cw017-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw017-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw017-trial-01 --exercise-id cw017 --single-sunburst-medium
```

- [ ] Read its original and create/read the preview:

```bash
convert /tmp/opencode/cw017-trial-01/cw017-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw017-trial-01/review-512.png
```

Require approximately 30° backrest, same slight elbow bend in both positions, open-to-close flye. Compare against accepted `cw013` for press-vs-flye and `cw016` for incline-vs-flat distinction.

- [ ] After reviewing `cw017`, issue `cw018` alone:

```bash
test ! -e /tmp/opencode/cw018-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw018-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw018-trial-01 --exercise-id cw018 --single-sunburst-medium
```

- [ ] Read its original and create/read the preview:

```bash
convert /tmp/opencode/cw018-trial-01/cw018-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw018-trial-01/review-512.png
```

Require gently floor-contacting low elbows, wide arm spread, stable slightly bent elbows and grounded body/feet. Compare against accepted `cw014`: distinguish flye from floor press at 512px.

- [ ] Complete scene-compliance review then quality review, including all three comparisons. Resolve findings before integration.

### Correction procedure for Tasks 3 and 4

Name the visible defect before correction. Create a fresh numbered prompt/output directory; preserve accepted phases, body, equipment and style while correcting only that defect. Use the immediately rejected PNG as the sole reference, keeping the actual exercise ID and `--single-sunburst-medium`. Verify the output directory is absent before the paid request. Read the new original and 512px preview before another request. Keep an explicit accepted-source list for all six IDs. Evaluate overlap in actual spatial perspective, not against a single projected horizontal line; do not accept real collisions, missing grips or merged equipment. If successive corrections do not remove the same defect, stop paid calls and ask to revise the scene. Never automatically repeat failed API requests or change the approved standing `cw015` to a lying variant.

## Task 5: Integrate all six approved assets and restore green

**Files:** six WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all six sources have passed both reviews. Verify `assets/exercises/` exists. Convert recorded accepted sources using `-resize 512x512 -strip -quality 90`. For accepted first trials the exact commands are:

```bash
convert /tmp/opencode/cw013-trial-01/cw013-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw013.webp
convert /tmp/opencode/cw014-trial-01/cw014-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw014.webp
convert /tmp/opencode/cw015-trial-01/cw015-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw015.webp
convert /tmp/opencode/cw016-trial-01/cw016-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw016.webp
convert /tmp/opencode/cw017-trial-01/cw017-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw017.webp
convert /tmp/opencode/cw018-trial-01/cw018-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw018.webp
```

If a correction was accepted, replace only its source path with the recorded accepted PNG. Do not convert a rejected first trial because it appears in this example.

- [ ] Verify nonempty dimensions:

```bash
identify -format '%f %wx%h %b\n' assets/exercises/cw013.webp assets/exercises/cw014.webp assets/exercises/cw015.webp assets/exercises/cw016.webp assets/exercises/cw017.webp assets/exercises/cw018.webp
```

Expected: six nonempty 512×512 WebP files. Read final files to confirm two frames and unchanged pose/grip distinctions.

- [ ] Insert these entries after `cw012`, before `cw251`, in `illustratedExerciseIds`, preserving earlier entries and the mapping function:

```dart
  'cw013',
  'cw014',
  'cw015',
  'cw016',
  'cw017',
  'cw018',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-07-verified .
```

Expected: version check passes, analysis has no findings, full suite passes, 84 asset files match the 84 registry/expected IDs, every image decodes as 512×512, and `cw019` still returns no illustration. Tests do not replace visual scene review. No host model regeneration or dependency/Web SQLite update is needed.

- [ ] Complete specification review then integration-quality review before marking this task complete.

## Task 6: Update status and complete final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve the published version `1.9.0+22`, previous release evidence and rollback. Replace opening counts with:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 84 ilustracje:
78 wydanych oraz 6 lokalnie zintegrowanych, niewydanych z Partii 07.
232 ćwiczenia pozostają bez ilustracji.
```

- [ ] Rename the table heading to `## Ilustracje — wydane i lokalnie zintegrowane` and insert these rows after `cw012`, before `cw251`:

```markdown
| cw013 | Wyciskanie hantli na ławce skośnej głową w górę | 2 | Lokalnie zintegrowane; niewydane. |
| cw014 | Wyciskanie hantli w leżeniu na podłodze | 2 | Lokalnie zintegrowane; niewydane. |
| cw015 | Wyciskanie ściskające hantlami | 2 | Lokalnie zintegrowane; niewydane; wariant w staniu. |
| cw016 | Rozpiętki z hantlami na ławce płaskiej | 2 | Lokalnie zintegrowane; niewydane. |
| cw017 | Rozpiętki z hantlami na ławce skośnej głową w górę | 2 | Lokalnie zintegrowane; niewydane. |
| cw018 | Rozpiętki z hantlami w leżeniu na podłodze | 2 | Lokalnie zintegrowane; niewydane. |
```

- [ ] Add before the general rules, preserving earlier batch and deployment sections:

```markdown
## Siódma partia

Zakres siódmej partii obejmuje `cw013–cw018`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry i jest lokalnie zintegrowanych. `cw015` pokazuje
zatwierdzony wariant w staniu z dwoma dociśniętymi hantlami. Weryfikacja
Dockerowa obejmuje analizę i pełny zestaw testów. Pakiet nie jest jeszcze
wydany; wersja produkcyjna pozostaje `1.9.0+22`.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`, and confirm only intended package changes on top of any preserved user work.
- [ ] Perform final compliance and quality review of all six final files, registry/test and documentation, including all flye-vs-press comparisons, 84 local vs 78 published, and fallback `cw019`.
- [ ] Report accepted paths, analysis/test results, request count and ledger-estimated costs, plus any unresolved findings. Finish at a prepared package; release version, deployment, commit and push remain separate decisions.

## Plan self-review

- Coverage: Task 2 defines all six exact prompts and standing `cw015`; Tasks 3/4 review each image sequentially and compare similar exercises at 512px.
- Integration: Task 5 adds all accepted WebP files together, preserves 78 previous IDs and restores the existing automated contracts.
- Fallback and ordering: new IDs follow `cw012`; missing illustration moves to `cw019`.
- Counts: 84 local = 78 published + 6 unpublished; 232 missing; 316 catalog records.
- Scope: Task 6 retains production `1.9.0+22` and previous evidence. No release metadata, deployment or automatic Git operations are included.
