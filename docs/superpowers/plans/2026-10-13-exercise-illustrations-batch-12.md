# Exercise Illustrations Batch 12 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and locally integrate six hanging and dumbbell-row illustrations for `cw043–cw048`.

**Architecture:** Generate one PNG at a time, inspect original and 512×512 preview, then integrate all accepted sources together as WebP. Dead and active hangs are single-frame holds; scapular pull-up and three rows use two phases. Extend existing exact-set/decoding tests and preserve all prior unpublished work.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-13-exercise-illustrations-batch-12-design.md`.
- Work in `/opt/fit`, current `main`, no worktree. Preserve unpublished Parts 07–11 and all existing user work.
- Create `assets/exercises/cw043.webp`, `cw044.webp`, `cw045.webp`, `cw046.webp`, `cw047.webp`, `cw048.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary prompts, sources, previews and ledgers: `/tmp/opencode/cw043-*` through `/tmp/opencode/cw048-*`.
- Baseline 108 local / 78 published / 30 unpublished / 208 missing / 316 records. Final 114 / 78 / 36 / 202 / 316.
- Proposed layouts `1/1/2/2/2/2`; rear three-quarter view for hanging exercises; right working arm and left bench supports for cw046.
- No paid requests before execution approval. No automatic commit, push, version bump or deployment; production stays `1.9.0+22`.

## Task 1: Establish red contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` before changes.
- [ ] Add after `cw042`, before `cw251`, in `expectedIllustrationIds`:

```dart
    'cw043',
    'cw044',
    'cw045',
    'cw046',
    'cw047',
    'cw048',
```

- [ ] Replace the existing absent-asset assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw049'), isNull);
  });
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-12-red .
```

Expected: registry equality fails because production lacks `cw043`; fallback `cw049` passes. Investigate unrelated failures before paid generation. Do not create production asset files or entries yet.

## Task 2: Prepare and review six exact prompts

**Files:** `/tmp/opencode/cw043-trial-01-prompt.txt` through `/tmp/opencode/cw048-trial-01-prompt.txt`.

- [ ] Read `assets/exercises/cw256.webp` and existing `/tmp/opencode/cw256-reference.png`. If PNG is missing, verify its parent directory and create it:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write each prompt through the file-editing tool: common block + layout + scene below.

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark comic outlines, faceless adult in dark neutral clothes. Square 1024x1024. Entire body, both hands, feet and essential equipment fit with generous margins. Stable physically attached equipment, coherent hands and actual grips, no floating apparatus, fused limbs or collisions. Neutral neck and controlled spine. Natural spatial perspective and partial occlusion allowed only when support/grip geometry remains clear at 512x512. No text, numbers, timer, labels, arrows, watermark, motion ghosts or additional figures. No required muscle overlays. In a multi-panel illustration, SAME fixed camera, adult scale, equipment positions and support contacts across both phases.
```

Layout for cw043/cw044:

```text
EXACTLY ONE complete full-body pose in a SINGLE undivided square image, no panels or repeated phases. This is an isometric hold, not an illustrated duration measurement.
```

Layout for cw045–cw048:

```text
EXACTLY TWO separate side-by-side panels, read LEFT TO RIGHT: lower/starting position then active/pulled position. No text or arrows to communicate movement.
```

`cw043-trial-01-prompt.txt` scene:

```text
DEAD HANG, fixed REAR three-quarter camera showing shoulders and upper back. Shoulder-width PRONATED grip on a horizontal bar attached to a stable simple frame. Both elbows STRAIGHT, relaxed arms, natural overhead shoulder ELEVATION, NOT actively pulling shoulder blades down/back. Torso controlled without swinging, legs together or lightly crossed, BOTH feet OFF the floor. No bent elbows, active scapular depression, assistance or toe-to-floor regression. Whole stationary bar and essential attachments readable, no timer.
```

`cw044-trial-01-prompt.txt` scene:

```text
ACTIVE HANG, fixed REAR three-quarter camera showing shoulders and upper back. Shoulder-width PRONATED grip on a horizontal bar attached to a stable frame. Both elbows remain STRAIGHT while shoulder blades draw DOWN and BACK; shoulders farther from the ears, chest slightly open, braced torso. Body rises only a SMALL scapular range, still FAR BELOW a chin-over-bar pull-up. BOTH feet OFF floor. No bent-elbow pull-up, shoulders lifted to ears, excessive back arch, assistance or timer. Make the depressed shoulder position readable at 512x512 without invented labels or colored joint markings.
```

`cw045-trial-01-prompt.txt` scene:

```text
SCAPULAR pull-up, fixed REAR three-quarter camera, stationary horizontal bar and shoulder-width PRONATED grips. Left: relaxed straight-arm hang, natural elevated shoulders. Right: shoulder blades draw DOWN and BACK, shoulders visibly farther from ears, chest opens slightly and body rises a SMALL natural amount. BOTH elbows remain STRAIGHT in BOTH panels, SAME hands and bar height; feet remain airborne and body does not swing. This is not a bent-elbow pull-up or chin-to-bar motion. No two identical shoulder poses, moving apparatus, exaggerated lift, elbow bending or timer. Make the modest shoulder/neck-space distinction visible at 512x512.
```

`cw046-trial-01-prompt.txt` scene:

```text
ONE-ARM dumbbell row with a FLAT bench. Fixed side three-quarter camera from the ANATOMICAL RIGHT working-arm side. LEFT hand and LEFT knee supported on bench, RIGHT foot planted on floor, flat braced back with torso near horizontal and neutral neck. Exactly ONE dumbbell held by RIGHT hand on its handle. Left: right arm lengthened under shoulder, weight suspended clear of floor and bench. Right: drive RIGHT elbow back close to torso, weight near HIP, controlled scapular retraction. SAME three supports and body angle in both phases. No second weight, right-hand bench support, side swapping, torso rotation or rising, shoulder shrug or biceps curl without elbow moving backward.
```

`cw047-trial-01-prompt.txt` scene:

```text
BENT-OVER TWO-DUMBBELL ROW, no bench. Fixed side three-quarter camera revealing both weights and the back. Feet hip-to-shoulder width, whole soles planted, knees softly bent, HIP HINGE with torso about 45 degrees to floor and controlled flat back. Exactly TWO separate dumbbells, one handle per hand, NEUTRAL grips. Left: arms lengthened, weights beneath shoulders clear of floor. Right: pull weights toward HIPS, elbows up and back around 45 degrees from torso. SAME torso hinge angle and foot contacts in both panels. No rounded back, rising upright during pull, chest-support bench, merged weight, floor contact or curl toward shoulders.
```

`cw048-trial-01-prompt.txt` scene:

```text
CHEST-SUPPORTED TWO-DUMBBELL ROW on an incline bench at 30-45 degrees. Fixed side three-quarter camera showing chest contact with the pad and both weights. Adult lies PRONE, face above the upper pad end, neck neutral and gaze down, chest supported, feet planted on floor. Exactly TWO separate dumbbells, one per hand with NEUTRAL grips, arms outside the bench frame. Left: arms lengthened down, weights suspended clear of floor and bench. Right: elbows pull up and back, weights toward hips, shoulder blades draw together. Chest STAYS on pad and all supports/bench angle remain unchanged. No supine bench press, lifted chest, head craned up, weights penetrating pad/frame, rocking or shoulder shrug.
```

- [ ] Review compliance then clarity/anatomy. Compare proposed dead/active shoulder cues, maintain straight elbows in all hanging poses, and verify one-vs-two dumbbell/support configurations. Resolve findings before execution.

## Task 3: Generate and review cw043–cw045 sequentially

**Files:** temporary PNGs, previews and ledgers. Timeout at least 240 seconds per request. Never display secrets or environment values.

- [ ] Issue cw043 alone in a fresh directory:

```bash
test ! -e /tmp/opencode/cw043-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw043-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw043-trial-01 --exercise-id cw043 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw043-trial-01/cw043-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw043-trial-01/review-512.png
```

Require ONE pose, full-body dead hang, relaxed natural overhead shoulders, straight elbows and feet suspended. No invented timing or active scapular cue. Review scene then quality.

- [ ] After inspecting cw043, issue cw044 alone:

```bash
test ! -e /tmp/opencode/cw044-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw044-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw044-trial-01 --exercise-id cw044 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw044-trial-01/cw044-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw044-trial-01/review-512.png
```

Compare cw043/cw044 at 512px: active shoulders down/back, longer visible neck space, elbows still straight. No chin-over-bar pose. Review compliance then quality.

- [ ] After inspecting cw044, issue cw045 alone:

```bash
test ! -e /tmp/opencode/cw045-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw045-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw045-trial-01 --exercise-id cw045 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw045-trial-01/cw045-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw045-trial-01/review-512.png
```

Require TWO different shoulder phases but straight elbows in both, small natural body lift and fixed bar. Compare endpoints to cw043/cw044, without inventing a uniqueness requirement for the active endpoint. Review scene then quality.

## Task 4: Generate and review cw046–cw048 sequentially

- [ ] Issue cw046 alone:

```bash
test ! -e /tmp/opencode/cw046-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw046-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw046-trial-01 --exercise-id cw046 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw046-trial-01/cw046-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw046-trial-01/review-512.png
```

Trace left hand/knee to bench, right foot to floor and right hand to ONE dumbbell. Require lower extension then elbow-back/hip-level pull with unchanged torso and supports. Review compliance then quality.

- [ ] After inspecting cw046, issue cw047 alone:

```bash
test ! -e /tmp/opencode/cw047-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw047-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw047-trial-01 --exercise-id cw047 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw047-trial-01/cw047-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw047-trial-01/review-512.png
```

Require TWO independent weights, fixed 45-degree hip hinge and grounded feet, no standing extension or curl. Compare supported cw046 vs unsupported two-weight row. Review scene then quality.

- [ ] After inspecting cw047, issue cw048 alone:

```bash
test ! -e /tmp/opencode/cw048-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw048-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw048-trial-01 --exercise-id cw048 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw048-trial-01/cw048-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw048-trial-01/review-512.png
```

Require prone chest support on 30–45° pad in BOTH phases, neutral neck, floor feet and two weights outside apparatus. Compare cw047: pad contact and bench must be unmistakable. Review compliance then quality.

### Correction procedure

Name the actual defect and record the last rejected source. Write a fresh numbered prompt/output path. Use only that rejected PNG as reference, retain `--single-sunburst-medium`, correct only the defective shoulder pose, support, grip, equipment or phase, and preserve accepted parts. Read source/512px preview before another request. No automatic retry after uncertain API results. After two unsuccessful corrections of the same issue, stop spending and assess a materially different approach. Maintain accepted-source paths and successful request ledger totals. No integration until the whole six-image package passes reviews. If subagents are unavailable, accurately record direct checking rather than claim independent review.

## Task 5: Integrate accepted assets and restore green

**Files:** six new WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all accepted source paths and destination directory. For accepted first trials, conversion commands are:

```bash
convert /tmp/opencode/cw043-trial-01/cw043-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw043.webp
convert /tmp/opencode/cw044-trial-01/cw044-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw044.webp
convert /tmp/opencode/cw045-trial-01/cw045-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw045.webp
convert /tmp/opencode/cw046-trial-01/cw046-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw046.webp
convert /tmp/opencode/cw047-trial-01/cw047-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw047.webp
convert /tmp/opencode/cw048-trial-01/cw048-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw048.webp
```

Replace any rejected first trial with its recorded accepted correction, never an unreviewed file.

- [ ] Verify nonempty formats/dimensions and read final files:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw043.webp assets/exercises/cw044.webp assets/exercises/cw045.webp assets/exercises/cw046.webp assets/exercises/cw047.webp assets/exercises/cw048.webp
```

Expected six WebP 512×512, frame counts `1/1/2/2/2/2` and retained support/shoulder distinctions.

- [ ] Add after cw042, before cw251, in `illustratedExerciseIds`, preserving previous 108 and mapping function:

```dart
  'cw043',
  'cw044',
  'cw045',
  'cw046',
  'cw047',
  'cw048',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-12-verified .
```

Expected version check, analysis and full suite pass; 114 assets match registry/expectations, every image decodes as 512×512, fallback cw049 passes. No host model/dependency/Web SQLite edits needed. Review final integration compliance and quality.

## Task 6: Record status and final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve production version, previous unpublished Parts 07–11 and release/rollback history. Replace counts:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 114 ilustracji:
78 wydanych oraz 36 lokalnie zintegrowanych, niewydanych z Partii 07–12.
202 ćwiczenia pozostają bez ilustracji.
```

- [ ] Add after cw042, before cw251:

```markdown
| cw043 | Zwis martwy | 1 | Lokalnie zintegrowane; niewydane; rozluźniony zwis. |
| cw044 | Aktywny zwis | 1 | Lokalnie zintegrowane; niewydane; aktywne barki, proste łokcie. |
| cw045 | Podciąganie łopatkowe | 2 | Lokalnie zintegrowane; niewydane; proste łokcie w obu fazach. |
| cw046 | Wiosłowanie hantlem jednorącz | 2 | Lokalnie zintegrowane; niewydane; prawa ręka robocza, lewa dłoń i kolano na ławce. |
| cw047 | Wiosłowanie hantlami w opadzie | 2 | Lokalnie zintegrowane; niewydane; stały zawias biodrowy. |
| cw048 | Wiosłowanie hantlami z klatką opartą na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; klatka podparta w obu fazach. |
```

- [ ] Add after Part 11, before general rules, only after green verification:

```markdown
## Dwunasta partia

Zakres dwunastej partii obejmuje `cw043–cw048`. Wszystkie sześć WebP 512×512
jest lokalnie zintegrowanych i niewydanych. Układ kadrów: 1/1/2/2/2/2.
Statyczne zwisy mają po jednym kadrze; czasy utrzymania opisuje katalog.
Sprawdzono naturalne barki zwisu martwego, depresję łopatek aktywnego zwisu
i podciągania łopatkowego bez uginania łokci. W wiosłowaniach kontrolowano
liczbę hantli, kierunek łokci, stałą pozycję tułowia oraz podparcia ławki.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów. Produkcja
pozostaje `1.9.0+22`; Partie 07–12 obejmują 36 niewydanych ilustracji.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`; require only intended Part 12 additions atop preserved earlier work.
- [ ] Final scene/quality/integration review: six accepted assets, layouts `1/1/2/2/2/2`, 114/78/36/202/316, fallback cw049 and preserved historical evidence.
- [ ] Report accepted source paths, actual verification, paid-request counts and ledger estimates. No automatic version, Git or deployment operations.

## Plan self-review

**Execution record:** The user approved the single-frame static holds and
requested completion. Execution and visual checks were performed directly in
the session, with sequential single requests and source/512px inspection.
Only cw045 required a correction to its active shoulder phase. Final WebP,
registry, fallback and complete Docker verification were checked; the status
document records accepted sources and ledger estimates. No independent
subagent review, version change, commit, push or deployment is claimed.

- Task 2 defines exact dead-vs-active shoulder cues and all row supports/grips; Tasks 3/4 compare endpoints and related exercises.
- Static holds remain single poses, dynamic exercises two phases; no artificial timing overlay.
- Task 1 establishes red and fallback cw049; Task 5 integrates all six and restores green.
- Task 6 distinguishes 36 unpublished local assets from 78 published, preserves Parts 07–11 and records 202 missing.
