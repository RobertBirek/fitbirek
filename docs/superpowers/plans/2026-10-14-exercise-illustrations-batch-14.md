# Exercise Illustrations Batch 14 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and locally integrate six band and prone back-extension illustrations for `cw055–cw060`.

**Architecture:** Generate individual PNGs, inspect original and 512×512 preview before another paid request, then integrate the whole accepted package as WebP. Five movements use two frames; Superman hold uses one full-body pose. Extend exact asset-set/decoding contracts while preserving all unpublished packages.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-14-design.md`.
- Work in `/opt/fit`, current `main`, no worktree. Preserve unpublished Parts 07–13 and all other existing work.
- Create `assets/exercises/cw055.webp`, `cw056.webp`, `cw057.webp`, `cw058.webp`, `cw059.webp`, `cw060.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary prompts, sources, previews and ledgers: `/tmp/opencode/cw055-*` through `/tmp/opencode/cw060-*`.
- Baseline 120 local / 78 published / 42 unpublished / 196 missing / 316 records. Final 126 / 78 / 48 / 190 / 316.
- Chosen draft variants: floor-seated cw056 with external front anchor, bilateral kneeling cw057, standing split-stance cw058, single-frame cw060.
- No paid calls before execution approval; no automatic version, commit, push or deployment. Production stays `1.9.0+22`.

## Task 1: Establish red contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` before editing.
- [ ] Add after cw054, before cw251, in `expectedIllustrationIds`:

```dart
    'cw055',
    'cw056',
    'cw057',
    'cw058',
    'cw059',
    'cw060',
```

- [ ] Replace the existing absent-asset assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw061'), isNull);
  });
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-14-red .
```

Expected: registry equality fails beginning with missing cw055; fallback cw061 passes. Resolve unrelated failures before paid generation. Keep production entries and assets unchanged until all six images pass checks.

## Task 2: Prepare and review exact prompts

**Files:** `/tmp/opencode/cw055-trial-01-prompt.txt` through `/tmp/opencode/cw060-trial-01-prompt.txt`.

- [ ] Read `assets/exercises/cw256.webp` and existing `/tmp/opencode/cw256-reference.png`. If PNG is absent, verify parent directory and create it:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write each prompt through the file-editing tool: common block + layout + scene.

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark comic outlines, faceless adult in dark neutral clothes. Square 1024x1024. Entire body, hands, feet and essential apparatus inside each frame with generous margins. In multiple frames use the SAME fixed camera, adult scale, apparatus positions and support contacts. Anatomically coherent hands/thumbs and actual grips, no fused limbs, floating equipment or collisions. Neutral neck and controlled spine. Natural spatial perspective and occlusion allowed only if grip/support geometry is still logical and readable at 512x512. No text, numbers, timer, labels, arrows, watermark, ghosts or additional figures. No required muscle overlays.
```

Layout cw055–cw059:

```text
EXACTLY TWO separate side-by-side panels, read LEFT TO RIGHT: starting position then active pull, stretch or lift.
```

Layout cw060 instead:

```text
EXACTLY ONE full-body pose in a SINGLE undivided square image, no panels, repeated phases or timer. This is a held position, not an illustrated time measurement.
```

`cw055-trial-01-prompt.txt` scene:

```text
STANDING BAND PULL-APART, NO external anchor. Fixed front-side three-quarter view. Scale adult consistently to fit the WIDEST extended-arm span in the right panel without cropping hands. Stable upright stance, feet grounded. ONE flexible band held between two separate hand grips. Left: arms STRAIGHT forward at chest height, hands around shoulder width, band mildly taut. Right: open both arms WIDE to the sides at chest height, elbows STILL STRAIGHT, scapulae retract, band stretched continuously between hands IN FRONT of torso. Same stance and head position. No elbow curl, overhead arms, shoulder shrug, disconnected band, external anchor, rigid rod, clipped hand or ghost motion.
```

`cw056-trial-01-prompt.txt` scene:

```text
FLOOR-SEATED BAND ROW with an EXTERNAL FRONT anchor on a simple fixed support, at abdominal height relative to the seated adult. Fixed side three-quarter view exposing anchor, two working branches and both grips. Buttocks and heels supported on floor, legs forward with mild knee bend allowed, upright flat back. Left: arms lengthened toward anchor, two band branches run ABOVE legs to one grip per hand, already taut. Right: draw both hands to ABDOMEN, elbows close and back, controlled scapular retraction, SAME upright torso and leg supports. No band around feet, rear anchor, line through legs/body, rounding or leaning back, face-height pull or detached grip. Same anchor position in both panels, flexible taut rubber not rods.
```

`cw057-trial-01-prompt.txt` scene:

```text
KNEELING BAND LAT PULLDOWN, adult on BOTH knees facing a HIGH EXTERNAL FRONT anchor. Fixed front-side three-quarter view showing the fixed anchor and two branches to separate hand grips. Upright still torso. Left: arms raised and lengthened overhead slightly toward front anchor, band taut. Right: pull both ends to UPPER CHEST by BENDING elbows and driving them DOWN close to torso, controlled shoulders, neutral neck. Knees/body stay in place. Both routes pass outside head/neck and attach to real grips, logical occlusion only. No behind-neck or rear-anchor pull, straight-arm pullover, standing conversion, rocking, body penetration or floating branch. Same high anchor and scale in both panels.
```

`cw058-trial-01-prompt.txt` scene:

```text
STANDING BAND FACE PULL with fixed EXTERNAL FRONT anchor at HEAD HEIGHT. Fixed front-side three-quarter view exposing both branches and separate hand grips. Stable split stance and upright torso. Left: arms lengthened forward at head height, band taut. Right: pull ends apart toward the SIDES OF FACE around upper cheeks/temples, elbows BENT and wide, SLIGHTLY HIGHER than wrists, external shoulder rotation. Keep head/neck and torso still, band outside the face/head, no joined grips. No abdomen/chin-only pull, straight-arm pull-apart, shoulder shrug, impossible branch entering head, extra branch or detached grip. Same anchor, feet and camera in both panels, each branch traceable anchor-to-grip.
```

`cw059-trial-01-prompt.txt` scene:

```text
SUPERMAN on floor, fixed LOW side three-quarter view revealing BOTH arms and BOTH legs. Left: prone rest, arms STRAIGHT overhead, legs long, neutral neck and gaze toward floor. Right: lift BOTH arms and BOTH legs simultaneously a SMALL controlled distance, knees remain lengthened, ABDOMEN AND PELVIS stay on floor. Allow only gentle controlled back extension, not an extreme banana arch. Whole hands and feet visible in both phases. No opposite-arm/leg-only regression, bent knees, entire body floating, raised chin, neck hyperextension, excessive lift or labels. Same body position and camera across both panels.
```

`cw060-trial-01-prompt.txt` scene:

```text
SUPERMAN HOLD, fixed LOW side three-quarter view. ONE prone held pose: BOTH straight arms reach overhead and BOTH lengthened legs stay mildly lifted above floor, ABDOMEN AND PELVIS supported on floor. Gentle controlled back extension, head aligned with spine and gaze down. All hands and feet visible, no maximum arch. The 3-5 second duration stays in catalog text, no timer or repeated pose. No opposite-limb-only regression, bent knees, floating whole body or chin lifted toward viewer. The pose may match the raised endpoint of dynamic Superman; no invented visual uniqueness required.
```

- [ ] Review compliance then clarity/anatomy. Trace band routes and anchor heights, distinguish straight vs bent elbows and confirm support of the prone pelvis. Resolve findings before paid requests.

## Task 3: Generate and review cw055–cw057 sequentially

**Files:** temporary PNGs, previews, ledgers. Request timeout at least 240 seconds. Never print credentials or environment values.

- [ ] Issue cw055 alone in a fresh output directory:

```bash
test ! -e /tmp/opencode/cw055-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw055-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw055-trial-01 --exercise-id cw055 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw055-trial-01/cw055-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw055-trial-01/review-512.png
```

Require unanchored continuous hand-to-hand band, full straight-arm forward→wide opening, whole body and unclipped hands. Review compliance then quality.

- [ ] After inspecting cw055, issue cw056 alone:

```bash
test ! -e /tmp/opencode/cw056-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw056-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw056-trial-01 --exercise-id cw056 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw056-trial-01/cw056-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw056-trial-01/review-512.png
```

Trace two branches from low front anchor over legs to both hands. Require floor seat, unchanged upright torso and abdomen-level pull with tucked elbows. Review scene then quality.

- [ ] After inspecting cw056, issue cw057 alone:

```bash
test ! -e /tmp/opencode/cw057-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw057-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw057-trial-01 --exercise-id cw057 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw057-trial-01/cw057-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw057-trial-01/review-512.png
```

Require bilateral kneeling, high front anchor, overhead start and bent-elbow upper-chest pull, no straight-arm pullover. Compare cw024 for different elbow action and anchor side. Trace both routes and grips; review compliance then quality.

## Task 4: Generate and review cw058–cw060 sequentially

- [ ] Issue cw058 alone:

```bash
test ! -e /tmp/opencode/cw058-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw058-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw058-trial-01 --exercise-id cw058 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw058-trial-01/cw058-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw058-trial-01/review-512.png
```

Require head-height front anchor, ends split beside upper face, bent wide elbows slightly above wrists and outside-head band routes. Compare cw055 straight-arm opening and cw057 low endpoint. Review scene then quality.

- [ ] After inspecting cw058, issue cw059 alone:

```bash
test ! -e /tmp/opencode/cw059-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw059-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw059-trial-01 --exercise-id cw059 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw059-trial-01/cw059-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw059-trial-01/review-512.png
```

Require four lifted extremities, straight legs and controlled gentle back extension, with abdomen/pelvis still grounded and gaze down. No whole-body flight or single-opposite-limb regression. Review compliance then quality.

- [ ] After inspecting cw059, issue cw060 alone:

```bash
test ! -e /tmp/opencode/cw060-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw060-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw060-trial-01 --exercise-id cw060 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw060-trial-01/cw060-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw060-trial-01/review-512.png
```

Require ONE undivided lifted hold, matching the safe dynamic endpoint, with neutral neck and grounded pelvis. Duration is catalog-only; no invented uniqueness cue. Review scene then quality.

### Correction procedure

Name actual defects and last rejected source. Write a fresh numbered prompt/output path; use only that PNG as reference with `--single-sunburst-medium`, correct the defective phase/grip/anchor/route/support, preserve accepted parts. Read source and 512px preview before another call. For bands, distinguish projected foreground overlap from actual physical penetration, while rejecting disconnected grips or unexplained missing segments. After two failed corrections of the same issue, stop paid attempts and evaluate a materially different view. No automatic retry after uncertain API results. Maintain accepted-source paths and unique-success ledger totals; integrate only when all six pass. Record direct checking honestly if subagents are unavailable.

## Task 5: Integrate accepted sources and restore green

**Files:** six WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm six accepted paths and destination directory. For accepted first trials:

```bash
convert /tmp/opencode/cw055-trial-01/cw055-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw055.webp
convert /tmp/opencode/cw056-trial-01/cw056-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw056.webp
convert /tmp/opencode/cw057-trial-01/cw057-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw057.webp
convert /tmp/opencode/cw058-trial-01/cw058-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw058.webp
convert /tmp/opencode/cw059-trial-01/cw059-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw059.webp
convert /tmp/opencode/cw060-trial-01/cw060-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw060.webp
```

Replace rejected initial paths with recorded accepted corrections; never convert an unreviewed trial.

- [ ] Verify dimensions and read final images:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw055.webp assets/exercises/cw056.webp assets/exercises/cw057.webp assets/exercises/cw058.webp assets/exercises/cw059.webp assets/exercises/cw060.webp
```

Expected six nonempty WebP 512×512, frame counts `2/2/2/2/2/1`, correct routes and supported prone pelvis.

- [ ] Add after cw054, before cw251, in `illustratedExerciseIds`, preserving earlier 120 and mapping function:

```dart
  'cw055',
  'cw056',
  'cw057',
  'cw058',
  'cw059',
  'cw060',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-14-verified .
```

Expected version check, analysis and full suite pass; 126 assets match registry/expectations, each decodes as 512×512, fallback cw061 passes. No host model/dependency/Web SQLite changes needed. Review integration compliance and quality.

## Task 6: Record status and final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve published version, unpublished Parts 07–13 and all release/rollback history. Replace counts:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 126 ilustracji:
78 wydanych oraz 48 lokalnie zintegrowanych, niewydanych z Partii 07–14.
190 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Add after cw054, before cw251:

```markdown
| cw055 | Rozciąganie gumy przed klatką piersiową | 2 | Lokalnie zintegrowane; niewydane; bez zewnętrznej kotwy. |
| cw056 | Wiosłowanie gumą w siadzie | 2 | Lokalnie zintegrowane; niewydane; siad na podłodze, niska kotwa przed ciałem. |
| cw057 | Ściąganie gumy z góry do klatki piersiowej | 2 | Lokalnie zintegrowane; niewydane; klęk obunóż, wysoka kotwa przed ciałem. |
| cw058 | Face pull z gumą | 2 | Lokalnie zintegrowane; niewydane; końce rozdzielone przy twarzy. |
| cw059 | Unoszenie ramion i nóg w leżeniu na brzuchu | 2 | Lokalnie zintegrowane; niewydane; obie pary kończyn, podparta miednica. |
| cw060 | Utrzymanie uniesionych ramion i nóg w leżeniu na brzuchu | 1 | Lokalnie zintegrowane; niewydane; czas utrzymania w katalogu. |
```

- [ ] Add after Part 13, before general rules, only after green verification:

```markdown
## Czternasta partia

Zakres czternastej partii obejmuje `cw055–cw060`. Wszystkie sześć WebP 512×512
jest lokalnie zintegrowanych i niewydanych. Układ kadrów: 2/2/2/2/2/1.
Sprawdzono ciągłość gum, położenia przednich kotew i chwyty obu dłoni,
rozróżnienie prostoramiennego pull-apart i zginanych ramion w przyciągnięciach.
`cw056` pokazuje siad na podłodze, `cw057` klęk obunóż, `cw058` stój wykroczny.
W Superman kontrolowano łagodne uniesienie obu par kończyn, podparcie brzucha
i miednicy oraz neutralną szyję. Statyczny cw060 ma jeden kadr; czas opisuje
katalog. Weryfikacja Dockerowa obejmuje analizę i pełne testy. Produkcja
pozostaje `1.9.0+22`; Partie 07–14 obejmują 48 niewydanych ilustracji.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`; require only intended Part 14 additions atop preserved prior work.
- [ ] Final scene/quality/integration review: six accepted assets, frames `2/2/2/2/2/1`, 126/78/48/190/316, fallback cw061 and retained release evidence.
- [ ] Report accepted sources, actual verification, unique paid-request count and ledger estimate. No automatic version, Git or deployment operations.

## Plan self-review

- All six scenes, chosen floor/kneeling/standing positions and anchor heights appear in Task 2 and are checked in Tasks 3/4.
- Pull-apart has no anchor; other bands have traceable front anchor-to-hand branches; physical overlap is evaluated spatially.
- Superman hold is a single frame, time remains catalog-only, and pelvis support is required in both exercises.
- Task 1 establishes red/fallback cw061; Task 5 integrates all accepted sources together and restores green.
- Task 6 preserves Parts 07–13, distinguishes 48 unpublished from 78 published and records 190 missing.

## Execution record — 2026-10-14

- [x] Task 1: red Docker verification failed only for missing cw055; 365 other tests passed.
- [x] Task 2: six prompts prepared and independently reviewed for specification and quality, findings resolved before paid calls.
- [x] Tasks 3/4: all six accepted, after the user approved new compositions for cw057–cw059 following two unsuccessful corrections each.
- [x] Task 5: six WebP 512×512 integrated, registry and expected IDs extended to 126, fallback cw061; full Docker verification passed 366 tests with no analysis issues.
- [x] Task 6: status updated to 126 local / 78 published / 48 unpublished / 190 missing / 316 catalog entries.

Approved composition amendment supersedes original camera/layout requirements:
cw057 and cw058 use the SAME frontal camera in both panels; cw059 uses
two full-width horizontal rows read top-to-bottom. Other technique and
support requirements remain applicable. New attempts used the last rejected
PNG as their sole reference, preserving provenance.

Accepted PNG sources under `/tmp/opencode`:

| ID | Directory | Frames |
|---|---|---:|
| cw055 | cw055-trial-01 | 2 |
| cw056 | cw056-trial-01 | 2 |
| cw057 | cw057-new-01 | 2 |
| cw058 | cw058-new-02 | 2 |
| cw059 | cw059-new-01 | 2 horizontal rows |
| cw060 | cw060-trial-01 | 1 |

Each source filename is `cwNNN-gpt-image-2.5-sunburst-medium.png` in its
listed directory, alongside the preview and ledger. Six initial attempts,
six original corrections, three new compositions and one subsequent
cw058 correction: 16 successful requests, upper-bound estimate 0.362602 USD.
This is not confirmed provider billing. Sources and previews were read
directly and reviewed independently. Verification output:
`/root/.local/share/opencode/tool-output/tool_1390ab3e00010mm4OcVCunKSCq`.
Production version remains 1.9.0+22; no version bump, commit, push or deployment.
