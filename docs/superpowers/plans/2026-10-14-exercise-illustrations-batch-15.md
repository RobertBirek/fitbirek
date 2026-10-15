# Exercise Illustrations Batch 15 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved illustrations cw061–cw066.

**Architecture:** Preserve all earlier unpublished work, establish red asset-set contract, generate each PNG separately and inspect source plus preview before another paid call. Integrate only the full accepted package as WebP; restore green and record evidence.

**Tech Stack:** Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and files

Approved spec: `docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-15-design.md`.
Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`.
User approved scope, 3/2/2/2/2/2 frames and cw064 directional interpretation.
Work in `/opt/fit`, current main without worktree. Preserve Parts 07–14.
No commit, push, release, deployment or version bump without a separate request.
Baseline 126 local / 78 published / 48 unpublished / 190 missing / 316 records.
Target 132 / 78 / 54 / 184 / 316, production still 1.9.0+22.

- Create `assets/exercises/cw061.webp` through `cw066.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart` and
  `lib/features/exercises/presentation/exercise_illustrations.dart`.
- Modify `docs/exercise-illustrations-status.md`; record execution here.
- Keep prompts, PNGs, previews and ledgers in `/tmp/opencode/cw061-*`
  through `/tmp/opencode/cw066-*`, not in the repository.

## Task 1: Red contract

- [ ] Inspect `git status --short` and scoped `git diff`, preserving existing changes.
- [ ] Add after cw060, before cw251, in test `expectedIllustrationIds`:

```dart
    'cw061',
    'cw062',
    'cw063',
    'cw064',
    'cw065',
    'cw066',
```

- [ ] Change absent-asset assertion to:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw067'), isNull);
  });
```

- [ ] Run with timeout >= 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-15-red .
```

Expected one missing-registry failure beginning with cw061; remaining tests,
analysis and fallback pass. Investigate unrelated failures before generation.

## Task 2: Prepare and review exact prompts

- [ ] Read `assets/exercises/cw256.webp` and existing
  `/tmp/opencode/cw256-reference.png`; check image dimensions with `identify`.
- [ ] Write separate `/tmp/opencode/cw061-trial-01-prompt.txt` through
  `cw066-trial-01-prompt.txt` using the file editing tool. Exact contents:
  the common block and respective ID scene from approved spec sections
  “Prompty do przygotowania przed wykonaniem”, lines 149–189. Preserve all
  layout, grip, support and geometry constraints; do not add other scenes.
- [ ] Review specification first, then quality. Resolve genuine findings
  before any paid call. Specifically evaluate the single short cw064
  dumbbell's fixed supported head, invariant radius and two free-head grips.

## Task 3: Generate cw061–cw063 sequentially

Timeout >= 240 seconds for each paid request. Verify output parent exists
and the numbered output directory is absent. Never print environment secrets.

- [ ] Generate cw061 alone:

```bash
test ! -e /tmp/opencode/cw061-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw061-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw061-trial-01 --exercise-id cw061 --single-sunburst-medium
convert /tmp/opencode/cw061-trial-01/cw061-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw061-trial-01/review-512.png
```

- [ ] Read source and preview. Require THREE horizontal rows, hips→T→overhead,
  both arms off floor, legs grounded, same camera, complete hands. Spec
  review then quality review before next call.
- [ ] Generate cw062 alone:

```bash
test ! -e /tmp/opencode/cw062-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw062-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw062-trial-01 --exercise-id cw062 --single-sunburst-medium
convert /tmp/opencode/cw062-trial-01/cw062-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw062-trial-01/review-512.png
```

- [ ] Read source/preview; one dumbbell supported under upper head by two hands,
  chest-relative placement, same grip, neutral hinge nearly horizontal and
  only mild knee bend. No squat or RDL. Spec then quality review.
- [ ] Generate cw063 alone:

```bash
test ! -e /tmp/opencode/cw063-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw063-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw063-trial-01 --exercise-id cw063 --single-sunburst-medium
convert /tmp/opencode/cw063-trial-01/cw063-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw063-trial-01/review-512.png
```

- [ ] Read source/preview; two separate dumbbells close to legs, shin endpoint,
  straight elbows, hip hinge rather than squat, stable feet and spine.
  Spec then quality review.

## Task 4: Generate cw064–cw066 sequentially

- [ ] Generate cw064 alone:

```bash
test ! -e /tmp/opencode/cw064-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw064-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw064-trial-01 --exercise-id cw064 --single-sunburst-medium
convert /tmp/opencode/cw064-trial-01/cw064-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw064-trial-01/review-512.png
```

- [ ] Read source/preview. Trace the supported head at floor/wall corner,
  short handle, free head and BOTH grips; compare pivot coordinates and
  equipment length across phases. Free head moves only within its radius;
  upward pull TOWARD chest does not require chest contact. Reject barbell,
  lifted/teleported pivot, variable length, torso rise or rotation. Stop
  if preserving real short geometry cannot depict the movement; do not
  reinterpret as a different exercise. Spec then quality review.
- [ ] Generate cw065 alone:

```bash
test ! -e /tmp/opencode/cw065-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw065-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw065-trial-01 --exercise-id cw065 --single-sunburst-medium
convert /tmp/opencode/cw065-trial-01/cw065-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw065-trial-01/review-512.png
```

- [ ] Read source/preview; seated upright bench, both feet/hips/back supported,
  two distinct grips/dumbbells, ear-height start, overhead endpoint and
  no lumbar arch or elbow hyperextension. Spec then quality review.
- [ ] Generate cw066 alone:

```bash
test ! -e /tmp/opencode/cw066-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw066-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw066-trial-01 --exercise-id cw066 --single-sunburst-medium
convert /tmp/opencode/cw066-trial-01/cw066-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw066-trial-01/review-512.png
```

- [ ] Read source/preview; strict standing press, unchanged feet/knees/hips,
  two weights and connected hands, ear-height→overhead, neutral neck/spine,
  no push press, Arnold rotation or clipped weights. Spec then quality review.

### Corrections

Write fresh numbered correction prompt and output path. Name actual defects,
use ONLY last rejected PNG as reference, preserve accepted parts and avoid
automatic paid retries after uncertainty. Inspect source/preview before
next call. After two unsuccessful corrections of the same issue stop and
evaluate materially different composition before another paid attempt.
Maintain exact accepted paths and unique-success ledger totals. Record actual
direct/independent review, including any unavailable subagent support.

## Task 5: Integrate entire accepted package, restore green

- [ ] Confirm all six accepted sources and destination `assets/exercises`.
  For accepted first trials use:

```bash
convert /tmp/opencode/cw061-trial-01/cw061-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw061.webp
convert /tmp/opencode/cw062-trial-01/cw062-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw062.webp
convert /tmp/opencode/cw063-trial-01/cw063-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw063.webp
convert /tmp/opencode/cw064-trial-01/cw064-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw064.webp
convert /tmp/opencode/cw065-trial-01/cw065-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw065.webp
convert /tmp/opencode/cw066-trial-01/cw066-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw066.webp
```

Substitute only recorded accepted correction paths; never use rejected trials.

- [ ] Identify and read all six final WebP, requiring nonempty 512×512:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw061.webp assets/exercises/cw062.webp assets/exercises/cw063.webp assets/exercises/cw064.webp assets/exercises/cw065.webp assets/exercises/cw066.webp
```

- [ ] Add after cw060 before cw251 in `illustratedExerciseIds`:

```dart
  'cw061',
  'cw062',
  'cw063',
  'cw064',
  'cw065',
  'cw066',
```

- [ ] Run with timeout >= 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-15-verified .
docker run --rm fit-web:batch-15-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected analysis/version check/full tests green, 132 matching ID/file set,
512×512 decode, cw067 fallback, format check 0 changes. No codegen or
dependency/Web SQLite changes needed.

## Task 6: Document and final review

- [ ] Preserve existing release and earlier batch history in status; replace
  only current counters and add six rows after cw060:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 132 ilustracje:
78 wydanych oraz 54 lokalnie zintegrowane, niewydane z Partii 07–15.
184 ćwiczenia pozostają bez ilustracji.
```

```markdown
| cw061 | Przenoszenie ramion łukiem nad głowę w leżeniu na brzuchu | 3 | Lokalnie zintegrowane; niewydane; trzy poziome pasy, nogi podparte. |
| cw062 | Skłony tułowia z hantlem i cofnięciem bioder | 2 | Lokalnie zintegrowane; niewydane; jeden hantel oburącz przed klatką. |
| cw063 | Rumuński martwy ciąg z hantlami | 2 | Lokalnie zintegrowane; niewydane; dwa hantle blisko goleni. |
| cw064 | Wiosłowanie oburącz hantlem opartym jednym końcem w rogu | 2 | Lokalnie zintegrowane; niewydane; jeden krótki hantel, stały podparty koniec. |
| cw065 | Wyciskanie hantli nad głowę w siadzie | 2 | Lokalnie zintegrowane; niewydane; plecy i stopy podparte. |
| cw066 | Wyciskanie hantli nad głowę w staniu | 2 | Lokalnie zintegrowane; niewydane; strict press bez wybicia nogami. |
```

- [ ] Add “Piętnasta partia” after Part14 before general rules; record
  actual source paths, frame counts, cw064 interpretation and geometry,
  meaningful corrections/reviews, request count and ledger estimate (not
  provider billing), Docker evidence and preserved production1.9.0+22.
- [ ] Run `git diff --check` and scoped `git status --short`; review integration
  and final images independently, confirm132/78/54/184/316, fallbackcw067,
  preserved earlier work and no unexpected files.
- [ ] Record execution here and report result; leave local unpublished work
  on main as explicitly approved, without Git/deployment operations.

## Plan self-review

Every ID has prompt reference and individual call, preview and concrete
scene/quality criteria. The only three-frame layout is cw061; cw064 short
pivot geometry is explicitly reviewed before corrections. Tasks1/5 implement
red/green for the real asset contract. Task6 preserves all earlier work,
published evidence and version while recording actual costs and sources.

## Execution record — 2026-10-14

- [x] Task 1: test contract expanded; red Docker failed only for missing cw061, 365 remaining tests passed, no analysis issues.
- [x] Task 2: six exact prompts written, specification and quality independently approved before paid generation.
- [x] Task 3: cw061–cw063 accepted; cw062 corrected for hinge depth and under-head palm support.
- [x] Task 4: cw064–cw066 accepted; cw064 corrected for shaft length then supported-head position; cw066 for wrist/stance/head clarity.
- [x] Task 5: six WebP 512×512 integrated, 132 matching files/IDs, fallback cw067; Docker full suite 366 passed, no analysis issues, Dart format 0 changes.
- [x] Task 6: status updated, earlier work and release evidence preserved, sources and costs recorded.

Accepted sources under `/tmp/opencode`:

| ID | Directory | Frames |
|---|---|---:|
| cw061 | cw061-trial-01 | 3 horizontal rows |
| cw062 | cw062-correction-01 | 2 |
| cw063 | cw063-trial-01 | 2 |
| cw064 | cw064-correction-02 | 2 |
| cw065 | cw065-trial-01 | 2 |
| cw066 | cw066-correction-01 | 2 |

Source filename in each directory: `cwNNN-gpt-image-2.5-sunburst-medium.png`.
All sources/previews directly inspected, independently reviewed in order
specification then quality. Six initial requests and four corrections:
10 successful unique requests, estimate upper_bound_no_cache 0.227790 USD,
not confirmed provider billing. No automatic retries or scene changes.

Green verification output:
`/root/.local/share/opencode/tool-output/tool_13957b7cd001oeMpq6kxg7LoCe`.
Current counters132/78/54/184/316, production remains1.9.0+22. Work remains
local on main with all previous unpublished packages, without commit/push/deploy.
