# Exercise Illustrations Batch 10 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and locally integrate six two-frame pull-up illustrations for `cw031–cw036`.

**Architecture:** Generate separate 1024×1024 PNGs, inspect each original and 512×512 preview, and review grip anatomy before integrating all six as WebP assets. Extend the existing exact asset-set and decoding contracts while retaining all prior unpublished batches. This plan is preparation, not a deployment or an automatic authorization to start paid calls.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json` and `docs/superpowers/specs/2026-10-13-exercise-illustrations-batch-10-design.md`.
- Work in `/opt/fit`, current `main`, no worktree. Preserve unpublished Parts 07–09, their assets, tests, registry and documentation.
- Create `assets/exercises/cw031.webp`, `cw032.webp`, `cw033.webp`, `cw034.webp`, `cw035.webp`, `cw036.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary prompts, sources, previews and ledgers stay under `/tmp/opencode/cw031-*` through `/tmp/opencode/cw036-*`.
- Baseline 96 local / 78 published / 18 unpublished / 220 missing / 316 catalog records. Final 102 / 78 / 24 / 214 / 316.
- Proposed illustration choices: narrow pronated grip for `cw034`; shoulder-width pronated grip for `cw036`; anatomical right pronated/left supinated for `cw035`. Do not describe unspecified grips as explicit catalog facts.
- No automatic commit, push, version bump or deployment. Production stays `1.9.0+22`.

## Task 1: Establish red contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` before edits.
- [ ] Insert after `cw030`, before `cw251`, in `expectedIllustrationIds`:

```dart
    'cw031',
    'cw032',
    'cw033',
    'cw034',
    'cw035',
    'cw036',
```

- [ ] Replace the existing missing-illustration assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw037'), isNull);
  });
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-10-red .
```

Expected: registry equality fails because production lacks `cw031`; fallback `cw037` passes. Resolve unrelated failures before paid calls. Do not add production IDs or WebP files yet.

## Task 2: Prepare and review six prompts

**Files:** `/tmp/opencode/cw031-trial-01-prompt.txt` through `/tmp/opencode/cw036-trial-01-prompt.txt`.

- [ ] Read `assets/exercises/cw256.webp` and `/tmp/opencode/cw256-reference.png`. If the PNG is missing, verify its parent directory and create it:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Use the file-editing tool to write the common block plus the exact scene paragraph for each file:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark comic outlines, faceless adult in dark neutral clothes. Square 1024x1024. EXACTLY TWO separated side-by-side panels, read left to right: lower hang then upper pull-up position. SAME fixed camera, scale, apparatus and bar height in both panels. Entire body, both hands and essential equipment attachments fit in each panel with generous margins. Both feet remain off the floor, no step, foot support, assistance band or added weight. Light knee bend is allowed but remains consistent, with no kicking or swinging. Physically attached horizontal pull-up apparatus, not floating or moving with the adult. Anatomically coherent hands and thumbs actually wrap their grips, no fused hands, extra limbs, transparent anatomy or collisions. Make grip orientation, spacing and body-to-bar position readable at 512x512. No text, numbers, timer, labels, arrows, watermark or motion ghosts. No required colored muscle overlays.
```

`cw031-trial-01-prompt.txt` scene:

```text
Wide pronated pull-up on a STRAIGHT horizontal bar attached to a simple stable frame. Fixed front-side three-quarter camera showing BOTH wrapped hand grips. Hands clearly WIDER THAN SHOULDERS, palms directed away from the adult, pronated wrists. Left: full dead hang with straight arms, natural overhead shoulder position, body suspended. Right: elbows bent, controlled raised body, chin ABOVE the bar without neck-only extension, torso steady. SAME wide overhand grips and spacing. No shoulder-width grip, underhand grip, incomplete hang, kip or head passing through the bar.
```

`cw032-trial-01-prompt.txt` scene:

```text
Chin-up with SUPINATED UNDERHAND grip on a straight horizontal bar, hands at SHOULDER WIDTH, palms toward the adult. Fixed front-side three-quarter camera showing correct hand and thumb wrapping. Left: full straight-arm hang, feet suspended. Right: chin above the bar, chest approaching the bar, elbows directed down, body steady. SAME shoulder-width underhand grip in both panels. No pronated grip, floating hands, head/bar collision, neck-only chin lift, kicking or swinging.
```

`cw033-trial-01-prompt.txt` scene:

```text
Neutral-grip pull-up using TWO SEPARATE PARALLEL fore-aft handles attached to one stable overhead frame, NOT a neutral grip on a single straight transverse bar. Fixed front-side three-quarter camera revealing both handle directions and their attachment. Each hand wraps its OWN handle, palms facing EACH OTHER. Left: full straight-arm hang. Right: elbows down and back, chest close to handle level, chin above grip height with no collision against the overhead frame. SAME handles and neutral grip in both panels. No unattached handles, single straight bar substitute, changing grip, kicking or swinging.
```

`cw034-trial-01-prompt.txt` scene:

```text
Close-grip PRONATED pull-up on a straight horizontal bar. Fixed front-side three-quarter camera clearly revealing both grips. Hand spacing distinctly NARROWER THAN SHOULDERS, but hands remain separately wrapped, not joined or touching as one grip. Palms away from adult, pronated orientation in both phases. Left: full straight-arm hang. Right: elbows down, chest toward bar and chin above bar, stable torso. No shoulder-width spacing, underhand conversion, merged hands, shortened hang, shrugging or swing.
```

`cw035-trial-01-prompt.txt` scene:

```text
Mixed-grip pull-up on a straight bar, approximately shoulder-width spacing. Fixed front-side three-quarter camera chosen so BOTH hand orientations are visible. The adult's ANATOMICAL RIGHT hand is PRONATED overhand; ANATOMICAL LEFT hand is SUPINATED underhand. This asymmetry remains exactly the SAME in both panels, do not swap hands between phases. Left: full straight-arm hang. Right: chin above bar with elbows bent, torso and hips staying square rather than rotating. Both hands correctly wrap the bar with coherent fingers/thumbs. No two identical grips, fake asymmetry from elbow pose alone, grip-side swap, head collision, twist or swing.
```

`cw036-trial-01-prompt.txt` scene:

```text
Pull-up with an upper HOLD, using SHOULDER-WIDTH PRONATED grips on a straight horizontal bar. Fixed front-side three-quarter camera. Left: full straight-arm hang, feet suspended. Right: controlled stable top hold, chin visibly above bar, elbows bent, active shoulder blades, braced body without shrugging or swinging. Same grip, bar height and support frame in both panels. A still illustration cannot encode three seconds; duration stays in the catalog. No timer, clock, text, duplicate top pose or invented visual distinction. No chin lift from neck extension alone or incomplete upper position.
```

- [ ] Review prompt scene compliance, then clarity and hand/suspension geometry. Resolve findings before generation. Confirm proposed `cw034/cw036` variants before execution.

## Task 3: Generate and review cw031–cw033 sequentially

**Files:** temporary PNGs, previews and ledgers. Use request timeout at least 240 seconds. Never display secrets or environment values.

- [ ] Issue `cw031` alone, only if the output directory is fresh:

```bash
test ! -e /tmp/opencode/cw031-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw031-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw031-trial-01 --exercise-id cw031 --single-sunburst-medium
```

- [ ] Read its original PNG, create and read the preview:

```bash
convert /tmp/opencode/cw031-trial-01/cw031-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw031-trial-01/review-512.png
```

Require wide pronated grip in both panels, full hang then chin-over-bar, no floor contact, fixed apparatus. Independently review compliance, then quality before acceptance.

- [ ] After inspecting `cw031`, issue `cw032` alone:

```bash
test ! -e /tmp/opencode/cw032-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw032-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw032-trial-01 --exercise-id cw032 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw032-trial-01/cw032-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw032-trial-01/review-512.png
```

Require supinated shoulder-width hand wrapping, full lower hang, controlled upper position. Compare with `cw031` at 512px for real grip/spacing distinction. Independently review scene then quality.

- [ ] After inspecting `cw032`, issue `cw033` alone:

```bash
test ! -e /tmp/opencode/cw033-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw033-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw033-trial-01 --exercise-id cw033 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw033-trial-01/cw033-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw033-trial-01/review-512.png
```

Trace each independent parallel handle to the fixed frame, verify palms face each other and remain attached in both phases. Review compliance, then quality. Resolve findings before the next task.

## Task 4: Generate and review cw034–cw036 sequentially

**Files:** temporary PNGs, previews and ledgers only.

- [ ] Issue `cw034` alone:

```bash
test ! -e /tmp/opencode/cw034-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw034-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw034-trial-01 --exercise-id cw034 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw034-trial-01/cw034-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw034-trial-01/review-512.png
```

Compare with accepted `cw031/cw032`: close pronated spacing must be distinct without labels. Hands stay separate and anatomically wrapped. Review compliance then quality.

- [ ] After inspecting `cw034`, issue `cw035` alone:

```bash
test ! -e /tmp/opencode/cw035-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw035-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw035-trial-01 --exercise-id cw035 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw035-trial-01/cw035-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw035-trial-01/review-512.png
```

Inspect anatomical right/left orientation in both phases; verify pronated vs supinated fingers/thumbs, not just wrist or elbow asymmetry. No swapping or torso rotation. Review scene then quality.

- [ ] After inspecting `cw035`, issue `cw036` alone:

```bash
test ! -e /tmp/opencode/cw036-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw036-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw036-trial-01 --exercise-id cw036 --single-sunburst-medium
```

- [ ] Read source, create and read preview:

```bash
convert /tmp/opencode/cw036-trial-01/cw036-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw036-trial-01/review-512.png
```

Require stable upper hold with chin above bar, shoulder-width pronated grips and no timer. Three-second duration remains in catalog text. Review compliance then quality, without requiring an artificial unique symbol for the pause.

### Correction procedure

Record the named actual defect and last rejected source before a correction. Write a fresh numbered prompt/output path. Use only the rejected PNG as reference, retain `--single-sunburst-medium`, and correct only the defective grip, apparatus or phase while preserving accepted parts. Read source and preview before another request. Never automatically retry uncertain API outcomes or overwrite output directories. After two failed corrections of the same issue, stop paid requests and assess a materially different view before any further spending. Maintain six accepted-source paths, actual request counts and ledger cost estimates; no integration until all six pass scene and quality reviews.

## Task 5: Integrate and restore green

**Files:** six WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all six accepted paths and destination directory. Convert only accepted sources. If first trials passed, exact commands are:

```bash
convert /tmp/opencode/cw031-trial-01/cw031-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw031.webp
convert /tmp/opencode/cw032-trial-01/cw032-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw032.webp
convert /tmp/opencode/cw033-trial-01/cw033-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw033.webp
convert /tmp/opencode/cw034-trial-01/cw034-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw034.webp
convert /tmp/opencode/cw035-trial-01/cw035-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw035.webp
convert /tmp/opencode/cw036-trial-01/cw036-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw036.webp
```

Replace rejected first-trial paths with the recorded accepted corrections, never substitute an unreviewed source.

- [ ] Verify formats, nonempty dimensions and final images:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw031.webp assets/exercises/cw032.webp assets/exercises/cw033.webp assets/exercises/cw034.webp assets/exercises/cw035.webp assets/exercises/cw036.webp
```

Expected: six WEBP 512×512. Read each final file for two visual frames and retained grip distinctions.

- [ ] Add after `cw030`, before `cw251`, in `illustratedExerciseIds`, preserving the existing 96 and mapping function:

```dart
  'cw031',
  'cw032',
  'cw033',
  'cw034',
  'cw035',
  'cw036',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-10-verified .
```

Expected: version check, analysis and full suite pass; 102 files match registry and expectations; each decodes as 512×512; fallback `cw037` passes. No host model/dependency/Web SQLite changes needed. Complete independent integration compliance then quality review.

## Task 6: Record status and final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve production version, all unpublished Parts 07–09 and earlier deployment/rollback evidence. Replace opening counts:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 102 ilustracje:
78 wydanych oraz 24 lokalnie zintegrowane, niewydane z Partii 07–10.
214 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Insert after `cw030`, before `cw251`:

```markdown
| cw031 | Podciąganie szerokim nachwytem | 2 | Lokalnie zintegrowane; niewydane. |
| cw032 | Podciąganie podchwytem | 2 | Lokalnie zintegrowane; niewydane. |
| cw033 | Podciąganie chwytem neutralnym | 2 | Lokalnie zintegrowane; niewydane; równoległe uchwyty. |
| cw034 | Podciąganie wąskim chwytem | 2 | Lokalnie zintegrowane; niewydane; wariant nachwytem. |
| cw035 | Podciąganie chwytem mieszanym | 2 | Lokalnie zintegrowane; niewydane. |
| cw036 | Podciąganie z pauzą na górze | 2 | Lokalnie zintegrowane; niewydane; nachwyt na szerokość barków, czas pauzy w katalogu. |
```

- [ ] Add after Part 09, before general rules, only after verification succeeds:

```markdown
## Dziesiąta partia

Zakres dziesiątej partii obejmuje `cw031–cw036`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry: dolny zwis i górną pozycję. Kontrolowano
rozstaw, orientację obu chwytów i mocowanie sprzętu w docelowym rozmiarze.
`cw033` używa dwóch równoległych uchwytów; `cw034` wąskiego nachwytu,
`cw035` stałego zestawu prawa dłoń nachwytem/lewa podchwytem, a `cw036`
nachwytu na szerokość barków. Czas pauzy opisuje katalog, nie timer w obrazie.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów. Pakiet pozostaje
niewydany; wersja produkcyjna to `1.9.0+22`.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`. Require only intended Part 10 additions atop preserved prior work.
- [ ] Final independent compliance and quality review: six correct grip variants, two frames, fixed apparatus, 102 local / 78 published / 24 unpublished / 214 missing / 316 records, fallback `cw037` and preserved historical evidence.
- [ ] Report accepted source paths, actual verification outcomes, request count and ledger cost estimates. No automatic commit, push or deployment.

## Plan self-review

**Execution adaptation:** The user approved the proposed grips and requested
completion after the subagent usage limit was reached before generation.
Red-contract and prompt reviews were completed by subagents; image generation,
visual checks and final integration were completed directly in the main
session. This is not an independent subagent review of the final images.
Sequential single-image requests, named-defect corrections, source/512px
inspection and full Docker verification remained in place.

- All six catalog scenes, proposed grip assumptions and neutral apparatus are explicit in Task 2 and visually checked in Tasks 3/4.
- Task 1 establishes red and changes fallback to `cw037`; Task 5 registers all accepted sources together and restores green.
- Task 6 distinguishes 24 unpublished local assets from 78 published, preserving Parts 07–09 and production 1.9.0+22.
- Timing remains catalog-only; no artificial pause overlay or hand anatomy shortcuts.
