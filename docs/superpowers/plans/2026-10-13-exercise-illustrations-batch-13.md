# Exercise Illustrations Batch 13 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and locally integrate six rowing and shoulder illustrations for `cw049–cw054`.

**Architecture:** Generate and inspect individual PNGs, including their 512×512 previews, then integrate all six accepted sources together as WebP assets. Five exercises use two frames; the alternating floor row uses three vertical columns. Extend the existing exact-set and decoding contracts while retaining all earlier unpublished work.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-13-exercise-illustrations-batch-13-design.md`.
- Work in `/opt/fit`, current `main`, no worktree. Preserve unpublished Parts 07–12 and any other existing user work.
- Create `assets/exercises/cw049.webp`, `cw050.webp`, `cw051.webp`, `cw052.webp`, `cw053.webp`, `cw054.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary prompts, PNGs, previews and ledgers stay under `/tmp/opencode/cw049-*` through `/tmp/opencode/cw054-*`.
- Baseline 114 local / 78 published / 36 unpublished / 202 missing / 316 records. Final 120 / 78 / 42 / 196 / 316.
- cw050 decision delegated by user: grip the actual HANDLE with a pronated hand; upright-weight wording is interpreted as setup before the pictured bottom row. Do not claim this interpretation is explicitly specified by the catalog, edit data, draw a head grip or substitute landmine equipment.
- Right working hand for cw049/cw050, three alternating columns for cw052, prone neutral-grip Kelso on 30–45° bench.
- Preparation does not start paid calls. No automatic version, commit, push or deployment; production remains `1.9.0+22`.

## Task 1: Establish red registry contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` before editing.
- [ ] Insert after cw048, before cw251, into `expectedIllustrationIds`:

```dart
    'cw049',
    'cw050',
    'cw051',
    'cw052',
    'cw053',
    'cw054',
```

- [ ] Replace existing absent-asset assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw055'), isNull);
  });
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-13-red .
```

Expected: registry equality fails at missing cw049; fallback cw055 passes. Investigate unrelated failures before generating. Leave production registry and WebP files unchanged until all six images pass reviews.

## Task 2: Prepare and review exact prompts

**Files:** `/tmp/opencode/cw049-trial-01-prompt.txt` through `/tmp/opencode/cw054-trial-01-prompt.txt`.

- [ ] Read `assets/exercises/cw256.webp` and existing `/tmp/opencode/cw256-reference.png`. If absent, verify its parent and create PNG:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write each prompt through the file-editing tool using common block + layout + scene below:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark comic outlines, faceless adult in dark neutral clothes. Square 1024x1024. SAME fixed camera, adult scale, equipment positions and support contacts across the exercise's frames. Entire body, both hands, feet and essential equipment fit with generous margins. Correct grips, coherent hand/thumb anatomy, no fused limbs, floating apparatus, penetrating equipment or duplicate weights. Neutral neck and controlled back. Natural perspective and partial occlusion only when support/grip geometry remains clear at 512x512. No text, numbers, timer, labels, arrows, watermark, ghosts or extra figures. No required muscle overlays.
```

Layout for cw049/cw050/cw051/cw053/cw054:

```text
EXACTLY TWO separate side-by-side panels, read LEFT TO RIGHT: starting/lowered position then pulled or contracted position.
```

Layout for cw052 instead of two-panel paragraph:

```text
EXACTLY THREE VERTICAL COLUMNS side by side, read LEFT TO RIGHT: both weights grounded, right-arm row, left-arm row. Not horizontal stacked rows. SAME camera, stance, equipment and scale in every column.
```

`cw049-trial-01-prompt.txt` scene:

```text
RENEGADE ROW, fixed slightly elevated front-side three-quarter camera showing both dumbbells. Exactly TWO hex dumbbells, palms gripping the HANDLES, flat heads stably resting on floor. Left: high plank on both handles, feet WIDE on toes, straight body and hips parallel to floor. Right: ANATOMICAL RIGHT elbow pulls back, right dumbbell raised near HIP; LEFT hand stays on the handle of the LEFT grounded dumbbell and both toe supports unchanged. Hips and torso do NOT rotate, lift or shift sideways. No knees on floor, added push-up, both hands airborne, third weight or palm support on dumbbell heads. Show one working side; alternating repetitions stay in catalog text.
```

`cw050-trial-01-prompt.txt` scene:

```text
SINGLE-DUMBBELL Meadows-style row, fixed front-side three-quarter camera from the ANATOMICAL RIGHT working side showing the actual grip. Stable staggered stance, both feet planted, about 45-degree hip hinge with braced flat back; free LEFT hand may rest on LEFT thigh, no bench. Exactly ONE dumbbell held by RIGHT hand gripping its HANDLE with PRONATED OVERHAND orientation. Left: extended right arm, weight suspended beside right leg, pictured after pickup. Right: drive right elbow BACK, weight near HIP, controlled scapular retraction, SAME torso angle, feet and overhand grip. The catalog's upright resting dumbbell is a setup detail BEFORE the pictured movement; do not force a vertical shaft with an impossible wrist. No head grip, second upright weight, barbell, landmine anchor, underhand grip, torso rotation, standing-up pull or biceps curl with stationary elbow.
```

`cw051-trial-01-prompt.txt` scene:

```text
REVERSE-GRIP TWO-DUMBBELL ROW. Fixed front-side three-quarter camera exposing BOTH hands and forearms. Exactly TWO separate dumbbells, one handle per hand with SUPINATED UNDERHAND grips, anatomically coherent palms/thumbs rather than neutral hammer grips. Stable 45-degree HIP HINGE, knees soft, whole soles planted, flat braced back. Left: arms extended, weights beneath shoulders clear of floor. Right: pull both weights toward HIPS along torso, elbows tucked close and driven BACK. SAME hinge, feet and supination in both phases. No neutral/pronated substitution, wrist-only twist with wrong fingers, merged weights, standing upright, rounded back or curl without backward elbow travel.
```

`cw052-trial-01-prompt.txt` scene:

```text
GORILLA ROW, standing in a stable WIDE stance with hip hinge, bent knees and braced flat back, NOT a plank. Exactly TWO hex dumbbells on the floor between the feet, each hand on its own handle. First column: both weights grounded, arms lengthened. Second: ANATOMICAL RIGHT weight pulled near right HIP with right elbow back; LEFT weight remains grounded with left hand gripping it. Third: RIGHT weight returned to floor with right hand gripping it; LEFT weight pulled near left HIP with left elbow back. SAME stance, torso inclination, hips, foot contacts, camera and weights throughout. No both weights lifted together, hip rotation, standing-up torso, knee-floor support, changed equipment or extra weights. Return between sides is implicit, not an added fourth frame.
```

`cw053-trial-01-prompt.txt` scene:

```text
KELSO SCAPULAR RETRACTION on incline bench around 30-45 degrees, NOT an elbow-bending row. Fixed REAR-SIDE three-quarter camera exposing upper back and chest-pad contact. Adult lies PRONE with chest supported, feet grounded, TWO separate dumbbells with neutral grips hanging outside bench frame. BOTH elbows remain STRAIGHT in BOTH panels. Left: relaxed shoulders and scapulae, arms hanging. Right: retract scapulae ONLY, shoulders drawn BACK with a small natural weight shift from shoulder motion; chest stays on pad and arms stay straight. No dumbbells pulled all the way to hips, elbow bending, upward shoulder shrug toward ears, lifted chest, craned neck, changing bench angle, frame penetration or timer.
```

`cw054-trial-01-prompt.txt` scene:

```text
STANDING TWO-DUMBBELL SHRUG. Fixed front-side three-quarter camera showing BOTH shoulders and weights. Upright stance, feet about hip width, whole soles planted, TWO separate dumbbells by SIDES with neutral grips, elbows STRAIGHT. Left: shoulders relaxed/lowered. Right: elevate BOTH shoulders toward ears, retaining straight elbows; the small weight rise comes ONLY from shoulder-girdle elevation. Head, torso and feet stay still and neck neutral. No elbow curl, shoulder rolling front-to-back, head bending to fake elevation, weight toss, squat or one merged dumbbell. Pause duration stays in catalog, no timer.
```

- [ ] Review scene compliance and prompt clarity/anatomy, focusing on support count, actual overhand/supinated grip, alternating rows and retraction-vs-elevation. Resolve findings before paid requests.

## Task 3: Generate and review cw049–cw051 sequentially

**Files:** temporary PNGs, previews, ledgers. Timeout at least 240 seconds/request. Never print credentials or environment values.

- [ ] Issue cw049 alone in a fresh output directory:

```bash
test ! -e /tmp/opencode/cw049-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw049-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw049-trial-01 --exercise-id cw049 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw049-trial-01/cw049-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw049-trial-01/review-512.png
```

Trace each handle, supporting left weight and two toe contacts. Require raised right weight near hip without pelvic twist, duplicate weights or added push-up. Review compliance then quality.

- [ ] After inspecting cw049, issue cw050 alone:

```bash
test ! -e /tmp/opencode/cw050-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw050-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw050-trial-01 --exercise-id cw050 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw050-trial-01/cw050-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw050-trial-01/review-512.png
```

Require one dumbbell with right hand actually on HANDLE, pronated forearm/finger wrapping, fixed staggered hinge and elbow-back pull. Apply the documented setup interpretation, not a fabricated head grip, extra weight or landmine apparatus. Compare cw046 for unsupported stance vs bench-supported row. Review compliance then quality.

- [ ] After inspecting cw050, issue cw051 alone:

```bash
test ! -e /tmp/opencode/cw051-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw051-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw051-trial-01 --exercise-id cw051 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw051-trial-01/cw051-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw051-trial-01/review-512.png
```

Compare cw047 neutral grip: two genuinely supinated grips and tucked backward-moving elbows, not only changed wrist outlines. Keep torso/foot supports unchanged. Review scene then quality.

## Task 4: Generate and review cw052–cw054 sequentially

- [ ] Issue cw052 alone:

```bash
test ! -e /tmp/opencode/cw052-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw052-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw052-trial-01 --exercise-id cw052 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw052-trial-01/cw052-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw052-trial-01/review-512.png
```

Require three vertical columns, two-grounded → right-row/left-grounded → left-row/right-grounded, with fixed stance and hinge. Compare cw049: standing hinge rather than plank. Review compliance then quality.

- [ ] After inspecting cw052, issue cw053 alone:

```bash
test ! -e /tmp/opencode/cw053-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw053-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw053-trial-01 --exercise-id cw053 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw053-trial-01/cw053-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw053-trial-01/review-512.png
```

Compare cw048: chest supported and same two weights, but STRAIGHT elbows throughout and only scapular retraction, not weight pull to hips. Require readable modest shoulder change without shrug. Review scene then quality.

- [ ] After inspecting cw053, issue cw054 alone:

```bash
test ! -e /tmp/opencode/cw054-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw054-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw054-trial-01 --exercise-id cw054 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw054-trial-01/cw054-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw054-trial-01/review-512.png
```

Require upright body, straight elbows, lower → raised shoulders toward ears and modest weight rise, no curls or rolling. Differentiate elevation from Kelso retraction. Review compliance then quality.

### Correction procedure

Record the actual named defect and rejected PNG. Write a fresh numbered prompt/output path; use only the last rejected PNG as reference with `--single-sunburst-medium`. Correct only the grip/support/phase/equipment defect and preserve accepted parts. Read source and preview before another paid request. No automatic retry after uncertain API outcomes. After two unsuccessful corrections of the same issue, stop spending and assess a materially different approach. Maintain accepted-source paths and unique successful-request ledger totals; no integration until all six pass. Record direct review honestly if subagents are unavailable.

## Task 5: Integrate all accepted assets and restore green

**Files:** six WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm accepted paths and destination directory. For accepted first trials:

```bash
convert /tmp/opencode/cw049-trial-01/cw049-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw049.webp
convert /tmp/opencode/cw050-trial-01/cw050-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw050.webp
convert /tmp/opencode/cw051-trial-01/cw051-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw051.webp
convert /tmp/opencode/cw052-trial-01/cw052-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw052.webp
convert /tmp/opencode/cw053-trial-01/cw053-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw053.webp
convert /tmp/opencode/cw054-trial-01/cw054-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw054.webp
```

Replace rejected initial sources with recorded accepted corrections; never convert an unreviewed trial.

- [ ] Verify nonempty dimensions and read final assets:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw049.webp assets/exercises/cw050.webp assets/exercises/cw051.webp assets/exercises/cw052.webp assets/exercises/cw053.webp assets/exercises/cw054.webp
```

Expected six WebP 512×512, layouts `2/2/2/3/2/2`, retained correct supports/grips/shoulder cues.

- [ ] Add after cw048, before cw251, in `illustratedExerciseIds`, preserving previous 114 and mapping function:

```dart
  'cw049',
  'cw050',
  'cw051',
  'cw052',
  'cw053',
  'cw054',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-13-verified .
```

Expected version check, analysis and full suite pass; 120 files match registry/expectations, each decodes as 512×512; fallback cw055 passes. No host model/dependency/Web SQLite changes needed. Review integration compliance and quality.

## Task 6: Record status and final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve published version, unpublished Parts 07–12 and all deployment/rollback history. Replace counts:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 120 ilustracji:
78 wydanych oraz 42 lokalnie zintegrowane, niewydane z Partii 07–13.
196 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Insert after cw048, before cw251:

```markdown
| cw049 | Wiosłowanie hantlami w podporze przodem | 2 | Lokalnie zintegrowane; niewydane; prawa ręka robocza. |
| cw050 | Wiosłowanie Meadowsa z hantlem | 2 | Lokalnie zintegrowane; niewydane; chwyt za uchwyt nachwytem, ustawienie pionowe traktowane jako przygotowanie. |
| cw051 | Wiosłowanie hantlami podchwytem | 2 | Lokalnie zintegrowane; niewydane; dwa podchwyty, stały zawias biodrowy. |
| cw052 | Naprzemienne wiosłowanie hantlami z podłogi w opadzie | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny: start, prawa, lewa. |
| cw053 | Ściąganie łopatek Kelso z hantlami na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; retrakcja bez zgięcia łokci. |
| cw054 | Wzruszanie barkami z hantlami | 2 | Lokalnie zintegrowane; niewydane; proste łokcie, pionowe uniesienie barków. |
```

- [ ] Add after Part 12, before general rules, only after verification succeeds:

```markdown
## Trzynasta partia

Zakres trzynastej partii obejmuje `cw049–cw054`. Wszystkie sześć WebP 512×512
jest lokalnie zintegrowanych i niewydanych. Układ kadrów: 2/2/2/3/2/2.
`cw052` ma trzy pionowe kolumny: oba ciężary na podłodze, prawa ręka, lewa ręka.
W `cw050` zgodnie z decyzją powierzoną asystentowi przyjęto chwyt za uchwyt
nachwytem; nietypowe ustawienie pionowe potraktowano jako przygotowanie
przed zilustrowanym ruchem, bez zmiany katalogu. Sprawdzono podpory planku,
podchwyty cw051, nieruchome biodra oraz retrakcję Kelso i elewację barków
bez uginania łokci. Weryfikacja Dockerowa obejmuje analizę i pełne testy.
Produkcja pozostaje `1.9.0+22`; Partie 07–13 obejmują 42 niewydane ilustracje.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`; require only intended Part 13 additions atop retained prior work.
- [ ] Final scene/quality/integration review: layouts `2/2/2/3/2/2`, 120/78/42/196/316, fallback cw055, correct cw050 documented interpretation and preserved historical evidence.
- [ ] Report accepted paths, actual verification, unique successful paid-request count and ledger cost estimate. No automatic Git, release or deployment operations.

## Plan self-review

**Execution record:** The user's delegated cw050 choice was documented as a
handle-grip/setup interpretation, not a catalog-data correction. Execution and
source/512px/final-image checks continued directly in the session. Only cw053
needed a correction for far-weight visibility and scapular phase clarity,
retaining straight arms and chest support. The full Docker verification ran
after integration. Accepted sources and ledger estimates are recorded in the
status document. No independent subagent review, version change, commit, push
or deployment is claimed.

- All six prompts specify actual equipment, support counts, grip orientations and phase order; cw050 delegated choice is documented rather than asserted as catalog fact.
- Gorilla row shows both alternating sides; other rows retain their side and supports, and Kelso/shrug preserve straight elbows.
- Task 1 establishes red and cw055 fallback; Task 5 integrates all accepted sources together and restores green.
- Task 6 preserves Parts 07–12, distinguishes 42 unpublished from 78 published, and records 196 missing.
