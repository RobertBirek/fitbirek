# Exercise Illustrations Batch 11 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and locally integrate six advanced pull-up illustrations for `cw037–cw042`.

**Architecture:** Generate one 1024×1024 PNG at a time, inspect the source and 512×512 preview, then integrate all six accepted sources together. Four assets have two side-by-side phases; two eccentric exercises have three vertical columns showing descent. Extend the exact asset-set/decoding contracts while preserving all prior unpublished packages.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-13-exercise-illustrations-batch-11-design.md`.
- Work in `/opt/fit`, current `main`, no worktree. Preserve unpublished Parts 07–10 and any other existing work.
- Create `assets/exercises/cw037.webp`, `cw038.webp`, `cw039.webp`, `cw040.webp`, `cw041.webp`, `cw042.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary prompts/sources/previews/ledgers: `/tmp/opencode/cw037-*` through `/tmp/opencode/cw042-*`.
- Baseline 102 local / 78 published / 24 unpublished / 214 missing / 316 records. Final 108 / 78 / 30 / 208 / 316.
- Proposed grips: shoulder-width pronated for 037/040/041/042; wide pronated for 038; anatomical right pronated supporting hand for 039, free left hand visible. These clarify unspecified catalog details, not edit records.
- No paid requests before execution approval, automatic version bump, commit, push or deployment. Production remains `1.9.0+22`.

## Task 1: Establish the red contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` before editing.
- [ ] Add after `cw036`, before `cw251`, in `expectedIllustrationIds`:

```dart
    'cw037',
    'cw038',
    'cw039',
    'cw040',
    'cw041',
    'cw042',
```

- [ ] Replace the existing absent-asset assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw043'), isNull);
  });
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-11-red .
```

Expected: only registry equality fails, beginning with missing `cw037`; fallback `cw043` passes. Investigate unrelated failures before paid calls. Production registry and assets remain unchanged until all six scenes pass reviews.

## Task 2: Prepare and review exact prompts

**Files:** `/tmp/opencode/cw037-trial-01-prompt.txt` through `/tmp/opencode/cw042-trial-01-prompt.txt`.

- [ ] Read reference `assets/exercises/cw256.webp` and existing `/tmp/opencode/cw256-reference.png`. If the PNG is absent, verify its parent directory and create it:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write each prompt through the file-editing tool as common block + its layout + its scene:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark comic outlines, faceless adult in dark neutral clothes. Square 1024x1024. Same fixed camera, adult scale, horizontal bar height and physically attached stable apparatus in EVERY panel. Entire body, hands, feet and essential attachments fit inside each panel with generous margins. Feet always suspended, no step, assistance band, weight or foot support. Correct wrapped hand/thumb anatomy, no fused or extra limbs, missing free hand, floating bar or collisions. Neutral neck; height comes from raising or lowering the body, never neck-only extension. Natural overhead shoulder position is allowed in lower hangs. Make grips, support counts and phases readable at 512x512. No text, numbers, timer, arrows, labels, watermark or motion ghosts. No required muscle overlays.
```

Layout for 037/038/040/041:

```text
EXACTLY TWO separate side-by-side panels, read left to right: lower hang then upper pull-up position. Same apparatus position and camera in both panels.
```

Layout for 039/042, instead of the two-panel paragraph:

```text
EXACTLY THREE VERTICAL COLUMNS side by side, read LEFT TO RIGHT: upper starting position, middle of descent, lower finish. Not horizontal stacked rows. Each column shows one entire body, with the SAME camera, scale, bar height and attachments. The body progressively LOWERS as the elbow angle opens; the apparatus does not move.
```

`cw037-trial-01-prompt.txt` scene:

```text
L-sit pull-up, shoulder-width PRONATED grips on a straight bar. Fixed SIDE three-quarter camera showing BOTH straight legs extending forward. Left: full straight-arm hang, both legs together STRAIGHT and HORIZONTAL at hip height, forming an L. Right: pull until chin is ABOVE the bar, elbows bent, while BOTH legs remain straight and horizontal relative to the floor at the rising hip level. No knee bend, dropped leg, ordinary dangling-leg pull-up, swing or cropped feet. Entire L shape readable in both phases.
```

`cw038-trial-01-prompt.txt` scene:

```text
Archer pull-up, WIDE PRONATED grip on a straight bar. Fixed front-side three-quarter view showing both arms. Left: symmetrical full straight-arm hang. Right: move the chest toward the adult's ANATOMICAL RIGHT working hand, right elbow bent and chin near that side of the bar. ANATOMICAL LEFT assisting arm stays STRAIGHT sideways with its hand still contacting the bar; a controlled slide of that grip is allowed. Same working side throughout, hips and torso not twisting, feet suspended. No two bent elbows, detached assisting hand, side swap or swing.
```

`cw039-trial-01-prompt.txt` scene:

```text
ONE-ARM NEGATIVE pull-up on a straight bar, descending LEFT TO RIGHT across three columns. ANATOMICAL RIGHT hand is the ONLY supporting grip, PRONATED; ANATOMICAL LEFT hand is released and visibly beside the body, not touching the bar or supporting the right wrist. Left: chin above bar, right elbow strongly bent, already after releasing the other hand. Middle: body lower, right elbow partly straightened, free hand still released. Right: lower controlled position, right arm almost fully extended without forced elbow hyperextension, feet suspended, shoulder controlled and torso resisting rotation. Exactly one supporting hand in EVERY phase. No two-hand starting frame, wrist assistance, missing free arm, reversed ascending sequence, identical elbow angles or timer. Entry and 5-10 second descent duration stay in catalog text.
```

`cw040-trial-01-prompt.txt` scene:

```text
CHEST-TO-BAR pull-up, shoulder-width PRONATED grips, fixed side three-quarter camera showing chest-to-bar contact. Left: full straight-arm hang. Right: lift until the UPPER CHEST at the upper sternum TOUCHES the bar, not merely chin above bar. Controlled slight rearward torso arch, elbows down and back, neutral neck, body braced. The bar is in front of and touches the chest, never passes through it or the face. No chin-only finish, neck contact, kip or exaggerated lumbar arch.
```

`cw041-trial-01-prompt.txt` scene:

```text
EXPLOSIVE HIGH pull-up, shoulder-width PRONATED grips, fixed side three-quarter camera revealing the high torso position relative to the bar. Left: full hang with a straight or slightly hollow braced body, feet suspended. Right: HIGH PULL with the bar near the LOWER STERNUM, visibly higher than an upper-chest-to-bar pull. BOTH hands keep the original pronated grips, elbows remain bent, with NO turnover into a straight-arm support above the bar. Neutral neck and controlled body, no leg kick or kip. This is not a completed muscle-up and not an ordinary chin-over-bar finish. Static artwork shows target height; explosive timing stays in the catalog, no arrows or ghosts.
```

`cw042-trial-01-prompt.txt` scene:

```text
TWO-HAND NEGATIVE pull-up, shoulder-width PRONATED grips, descending LEFT TO RIGHT across three columns. Left: upper start with chin clearly ABOVE the bar and elbows bent. Middle: lower the body under control, elbows more open and body visibly lower. Right: finish in a FULL STRAIGHT-ARM dead hang, feet still suspended. Both hands retain exactly the same grips in EVERY phase, neutral neck and stable torso. No released hand, reversed hang-to-top ascent, three identical elbow angles, shortened final hang or timer. Entry by a jump or step and the 5-8 second duration stay in catalog instructions, not additional illustrated equipment.
```

- [ ] Review prompt compliance then clarity/anatomy, focusing on retained L, archer assisting arm, eccentric direction, supporting-hand count and high-pull vs muscle-up distinction. Resolve findings before paid generation.

## Task 3: Generate and review cw037–cw039 sequentially

**Files:** temporary PNGs, previews, ledgers. Timeout at least 240 seconds per request. Never print credentials or environment values.

- [ ] Issue `cw037` alone in a fresh output directory:

```bash
test ! -e /tmp/opencode/cw037-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw037-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw037-trial-01 --exercise-id cw037 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw037-trial-01/cw037-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw037-trial-01/review-512.png
```

Require two complete L-shaped bodies, straight horizontal legs in both phases and complete pull-up without moving the apparatus. Compare ordinary `cw032` for retained-leg distinction. Review scene then quality.

- [ ] After inspecting `cw037`, issue `cw038` alone:

```bash
test ! -e /tmp/opencode/cw038-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw038-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw038-trial-01 --exercise-id cw038 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw038-trial-01/cw038-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw038-trial-01/review-512.png
```

Require one bent working arm, straight assisting arm in contact, no side swap or rotation. Compare `cw031`: upper archer asymmetry must be unmistakable at 512px. Review compliance then quality.

- [ ] After inspecting `cw038`, issue `cw039` alone:

```bash
test ! -e /tmp/opencode/cw039-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw039-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw039-trial-01 --exercise-id cw039 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw039-trial-01/cw039-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw039-trial-01/review-512.png
```

Require three VERTICAL columns, descending upper → middle → lower, exactly one wrapped support and visible released hand throughout. Do not mistake hidden free arm for absence or wrist support for one-arm independence. Review scene then quality.

## Task 4: Generate and review cw040–cw042 sequentially

- [ ] Issue `cw040` alone:

```bash
test ! -e /tmp/opencode/cw040-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw040-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw040-trial-01 --exercise-id cw040 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw040-trial-01/cw040-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw040-trial-01/review-512.png
```

Require upper sternum actually at bar, not a chin-only pull-up, coherent outside chest contact and controlled arch. Compare `cw031` upper height; review scene then quality.

- [ ] After inspecting `cw040`, issue `cw041` alone:

```bash
test ! -e /tmp/opencode/cw041-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw041-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw041-trial-01 --exercise-id cw041 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw041-trial-01/cw041-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw041-trial-01/review-512.png
```

Compare accepted `cw040`: lower-sternum high pull, still bent arms and retained grips, no muscle-up turnover or kip. Do not demand visual measurement of speed. Review compliance then quality.

- [ ] After inspecting `cw041`, issue `cw042` alone:

```bash
test ! -e /tmp/opencode/cw042-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw042-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw042-trial-01 --exercise-id cw042 --single-sunburst-medium
```

- [ ] Read original, create and read preview:

```bash
convert /tmp/opencode/cw042-trial-01/cw042-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw042-trial-01/review-512.png
```

Require three vertical columns with two hands attached throughout, increasing elbow extension and full final dead hang. Compare `cw039` for one-vs-two support; order must represent descent. Review scene then quality.

### Correction procedure

Name the actual defect, record rejected source and write a fresh numbered prompt/output path. Use only the immediately rejected PNG as reference, with `--single-sunburst-medium`; preserve accepted parts while correcting the defective phase, grip, legs, support count or apparatus. Read source and preview before another request. No automatic retries after uncertain API outcomes. After two failed corrections of the same problem, stop paid attempts and evaluate a materially different view. Maintain six accepted-source paths and actual successful-request ledger totals. No integration before all six scenes pass compliance and quality checks. If subagents are unavailable, record direct-review substitution honestly rather than claim independent reviews.

## Task 5: Integrate all accepted assets and restore green

**Files:** six WebP assets, `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all accepted sources, verify destination directory, then convert. For accepted first trials:

```bash
convert /tmp/opencode/cw037-trial-01/cw037-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw037.webp
convert /tmp/opencode/cw038-trial-01/cw038-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw038.webp
convert /tmp/opencode/cw039-trial-01/cw039-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw039.webp
convert /tmp/opencode/cw040-trial-01/cw040-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw040.webp
convert /tmp/opencode/cw041-trial-01/cw041-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw041.webp
convert /tmp/opencode/cw042-trial-01/cw042-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw042.webp
```

Substitute each accepted correction source where required; never convert an unreviewed or rejected trial.

- [ ] Check nonempty dimensions and read final images:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw037.webp assets/exercises/cw038.webp assets/exercises/cw039.webp assets/exercises/cw040.webp assets/exercises/cw041.webp assets/exercises/cw042.webp
```

Expected six WebP 512×512, layouts `2/2/3/2/2/3`, correct descent order and retained body/support distinctions.

- [ ] Add after `cw036`, before `cw251`, in `illustratedExerciseIds`:

```dart
  'cw037',
  'cw038',
  'cw039',
  'cw040',
  'cw041',
  'cw042',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-11-verified .
```

Expected version check, analysis and full suite pass; 108 assets match registry/expectations, each decodes as 512×512, fallback `cw043` passes. No host model/dependency/Web SQLite changes needed. Review integration compliance and quality after green.

## Task 6: Update status and final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve production version, previous unpublished Parts 07–10 and all historic release/rollback evidence. Replace opening counts:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 108 ilustracji:
78 wydanych oraz 30 lokalnie zintegrowanych, niewydanych z Partii 07–11.
208 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Add rows after `cw036`, before `cw251`:

```markdown
| cw037 | Podciąganie z prostymi nogami uniesionymi do poziomu | 2 | Lokalnie zintegrowane; niewydane; L utrzymane w obu fazach. |
| cw038 | Podciąganie łucznika | 2 | Lokalnie zintegrowane; niewydane; prawa ręka robocza, lewa pomocnicza prosta. |
| cw039 | Opuszczanie na jednej ręce z podciągnięcia | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny, prawa ręka podporowa. |
| cw040 | Podciąganie do klatki | 2 | Lokalnie zintegrowane; niewydane; drążek przy górnym mostku. |
| cw041 | Podciąganie eksplozywne | 2 | Lokalnie zintegrowane; niewydane; wysokie podciągnięcie do dolnego mostka, bez podporu muscle-up. |
| cw042 | Opuszczanie z podciągnięcia | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny opuszczania oburącz. |
```

- [ ] Add after Part 10, before general rules, only after verification succeeds:

```markdown
## Jedenasta partia

Zakres jedenastej partii obejmuje `cw037–cw042`. Wszystkie sześć WebP 512×512
jest lokalnie zintegrowanych i niewydanych. Układ kadrów: 2/2/3/2/2/3.
`cw039` i `cw042` pokazują opuszczanie w trzech pionowych kolumnach od lewej
do prawej: góra, środek, dół. Czasy zjazdu pozostają w opisie katalogowym.
Sprawdzono utrzymanie L, prostą rękę pomocniczą łucznika, jedną podporową
dłoń `cw039`, kontakt górnej klatki z drążkiem `cw040` i wyższą pozycję
dolnego mostka `cw041` bez przejścia do podporu muscle-up.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów. Produkcja
pozostaje `1.9.0+22`; Partie 07–11 obejmują 30 niewydanych ilustracji.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`; only intended additions atop preserved work.
- [ ] Final scene, quality and integration review: six accepted images, layouts `2/2/3/2/2/3`, 108/78/30/208/316, correct `cw043` fallback and truthful production/local distinction.
- [ ] Report accepted sources, actual verification, request count and ledger estimates; no automatic version, Git or deployment actions.

## Plan self-review

**Execution record:** The approved package was completed directly in the main
session because the subagent usage limit was already reached. Source images,
512px previews and final WebPs were visually checked without claiming an
independent subagent review. The full Docker verification was executed after
integration. For cw041, repeated joint apparatus alignment was stopped and
replaced with a bounded left-panel-only alignment approach; its resulting
upper-body height regression received one localized correction without moving
the now-aligned bar. The status document records accepted trials and costs.

- All catalog phases and explicit grip/working-side assumptions appear in Task 2 and are checked in Tasks 3/4.
- Descending images use three vertical columns, not ascending order or horizontal stacked rows; speed/duration remain catalog-only.
- Task 1 establishes red and fallback `cw043`; Task 5 registers all six accepted sources together and restores green.
- Task 6 preserves prior packages and release evidence, distinguishes 30 unpublished assets from 78 published, and records 208 missing.
