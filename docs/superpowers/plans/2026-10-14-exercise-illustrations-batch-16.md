# Exercise Illustrations Batch 16 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate cw067–cw072 with approved grip interpretations, frame layouts and support variants.

**Architecture:** Establish red asset-set contract, prepare six prompts from approved spec, generate each source separately with source/512px inspection before another paid call. Integrate the full accepted package as WebP and restore green while preserving all earlier unpublished work.

**Tech Stack:** Sunburst medium via `tools/benchmark_exercise_images.py`, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

Approved spec: `docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-16-design.md`.
Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`.
User approved execution, layouts3/2/3/2/2/2 and cw067 palms-to-own-face start.
Work in `/opt/fit`, main without worktree; preserve Parts07–15 and other work.
Baseline132 local/78 published/54 unpublished/184 missing/316 catalog records.
Final138/78/60/178/316. Production1.9.0+22; no version, commit, push or deployment.

- Create `assets/exercises/cw067.webp` through `cw072.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`,
  `lib/features/exercises/presentation/exercise_illustrations.dart`,
  `docs/exercise-illustrations-status.md`.
- Temporary prompts, PNG, previews, ledgers: `/tmp/opencode/cw067-*`
  through `/tmp/opencode/cw072-*`. Keep these outside repository.

## Task 1: Red contract

- [ ] Inspect `git status --short` and scoped `git diff` before edits.
- [ ] Add after cw066 before cw251 in expectedIllustrationIds:

```dart
    'cw067',
    'cw068',
    'cw069',
    'cw070',
    'cw071',
    'cw072',
```

- [ ] Change absent-asset assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw073'), isNull);
  });
```

- [ ] Run with timeout >=1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-16-red .
```

Expected only missing-registry failure beginning cw067; fallback and other
tests/analysis pass. Resolve unrelated failures before paid generation.

## Task 2: Exact prompt preparation and review

- [ ] Read style `assets/exercises/cw256.webp` and verify existing
  `/tmp/opencode/cw256-reference.png` with `identify`.
- [ ] Write six `cwNNN-trial-01-prompt.txt` files in `/tmp/opencode` via
  file-editing tool. Each contains EXACT common block plus its corresponding
  scene from approved spec “Sześć promptów bazowych” (lines145–184).
- [ ] Specification review first, then clarity/quality review; resolve
  actual ambiguity before paid requests. Require own-face→forward palms
  for cw067, mutually facing palms throughout cw068, shallow dip cw069,
  correct support side cw071 and no time graphics cw072.

## Task 3: Generate cw067–cw069, separately

Verify `/tmp/opencode` exists and each new output directory is absent.
Timeout >=240 seconds, do not print secrets. Inspect source and preview,
specification first then quality, before the next paid call.

- [ ] Generate cw067:

```bash
test ! -e /tmp/opencode/cw067-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw067-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw067-trial-01 --exercise-id cw067 --single-sunburst-medium
convert /tmp/opencode/cw067-trial-01/cw067-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw067-trial-01/review-512.png
```

- [ ] Read both PNG. Three vertical columns with actual palm/forearm rotation,
  not merely different dumbbell axes; neutral wrists, stable body, two
  distinct connected grips, no crop at widest or highest phase.
- [ ] Generate cw068:

```bash
test ! -e /tmp/opencode/cw068-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw068-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw068-trial-01 --exercise-id cw068 --single-sunburst-medium
convert /tmp/opencode/cw068-trial-01/cw068-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw068-trial-01/review-512.png
```

- [ ] Read source/preview; two panels, palms toward EACH OTHER in both,
  ear-height→overhead, forearms/grips readable, stable feet and spine.
  Compare against cw067 and earlier locally integrated cw066, not only weight axes.
- [ ] Generate cw069:

```bash
test ! -e /tmp/opencode/cw069-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw069-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw069-trial-01 --exercise-id cw069 --single-sunburst-medium
convert /tmp/opencode/cw069-trial-01/cw069-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw069-trial-01/review-512.png
```

- [ ] Read source/preview; three vertical columns upright→shallow dip→extended
  legs/overhead, vertical trunk, same floor/camera/scale/feet. No squat,
  jerk catch, jump or scale change falsely simulating dip.

## Task 4: Generate cw070–cw072, separately

- [ ] Generate cw070:

```bash
test ! -e /tmp/opencode/cw070-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw070-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw070-trial-01 --exercise-id cw070 --single-sunburst-medium
convert /tmp/opencode/cw070-trial-01/cw070-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw070-trial-01/review-512.png
```

- [ ] Read source/preview; two full-width horizontal rows top→bottom, lateral
  shoulder-height endpoint, slightly bent elbows, neutral wrists, no shrug,
  fixed small torso lean and two grounded feet. Complete full hand span.
- [ ] Generate cw071:

```bash
test ! -e /tmp/opencode/cw071-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw071-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw071-trial-01 --exercise-id cw071 --single-sunburst-medium
convert /tmp/opencode/cw071-trial-01/cw071-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw071-trial-01/review-512.png
```

- [ ] Read source/preview; two horizontal rows, anatomical RIGHT leg grounded,
  LEFT foot clearly off floor in both, stable pelvis, same lateral arm
  action as cw070. Reject side switch, hidden support or hop.
- [ ] Generate cw072:

```bash
test ! -e /tmp/opencode/cw072-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw072-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw072-trial-01 --exercise-id cw072 --single-sunburst-medium
convert /tmp/opencode/cw072-trial-01/cw072-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw072-trial-01/review-512.png
```

- [ ] Read source/preview; two horizontal rows, two grounded feet, controlled
  shoulder-level endpoint, no timer/extra duplicate phase. Similarity to
  cw070 is acceptable; duration stays in catalog, not image.

### Correction handling

Only after reading the rejected source/preview: name genuine defects,
write a fresh numbered prompt/output path, use ONLY the last rejected PNG
as reference, preserve accepted parts. Inspect corrected source/preview
before another request; no automatic retry after uncertain provider outcome.
After two failed corrections of the same issue stop and evaluate a materially
different view before another paid attempt. Record accepted paths, actual
reviews and success-only request/cost totals; keep all trials outside repo.

## Task 5: Integrate accepted sources together and restore green

- [ ] Verify all six accepted PNG paths and destination. For accepted initial
  trials use the following; replace ONLY rejected initial paths with the
  actual accepted correction directory:

```bash
convert /tmp/opencode/cw067-trial-01/cw067-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw067.webp
convert /tmp/opencode/cw068-trial-01/cw068-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw068.webp
convert /tmp/opencode/cw069-trial-01/cw069-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw069.webp
convert /tmp/opencode/cw070-trial-01/cw070-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw070.webp
convert /tmp/opencode/cw071-trial-01/cw071-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw071.webp
convert /tmp/opencode/cw072-trial-01/cw072-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw072.webp
identify -format '%f %m %wx%h %b\n' assets/exercises/cw067.webp assets/exercises/cw068.webp assets/exercises/cw069.webp assets/exercises/cw070.webp assets/exercises/cw071.webp assets/exercises/cw072.webp
```

- [ ] Read six final WebP; nonempty512×512, correct scenes and3/2/3/2/2/2 frames.
- [ ] Add after cw066 before cw251 in illustratedExerciseIds:

```dart
  'cw067',
  'cw068',
  'cw069',
  'cw070',
  'cw071',
  'cw072',
```

- [ ] Run with timeout>=1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-16-verified .
docker run --rm fit-web:batch-16-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected version check/analysis/full suite green,138 matching files/IDs,
512px decoding, fallbackcw073 and0 formatting changes. No codegen or dependencies.

## Task 6: Status and final review

- [ ] Preserve all earlier release/batch evidence; update current counters:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 138 ilustracji:
78 wydanych oraz 60 lokalnie zintegrowanych, niewydanych z Partii 07–16.
178 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Add rows after cw066 before cw251:

```markdown
| cw067 | Wyciskanie Arnolda z hantlami | 3 | Lokalnie zintegrowane; niewydane; stój, trzy kolumny rotacji chwytu. |
| cw068 | Wyciskanie hantli nad głowę chwytem neutralnym | 2 | Lokalnie zintegrowane; niewydane; dłonie do siebie cały czas. |
| cw069 | Wyciskanie hantli nad głowę z wybiciem z nóg | 3 | Lokalnie zintegrowane; niewydane; stój, dip, wyciskanie. |
| cw070 | Unoszenie hantli bokiem | 2 | Lokalnie zintegrowane; niewydane; dwa poziome pasy. |
| cw071 | Unoszenie hantli bokiem w staniu na jednej nodze | 2 | Lokalnie zintegrowane; niewydane; prawa noga podporowa, dwa poziome pasy. |
| cw072 | Unoszenie hantli bokiem z pauzą | 2 | Lokalnie zintegrowane; niewydane; dwa poziome pasy, czas pauzy w katalogu. |
```

- [ ] Add “Szesnasta partia” before general rules: record actual sources,
  frames/layouts, cw067 approved interpretation, real reviews/corrections,
  unique success ledger totals and estimated cost, red/green evidence,
  138/78/60/178/316 and unchanged production1.9.0+22. Record execution here.
- [ ] `git diff --check`, scoped `git status --short`, final independent
  asset/integration review, and ledger request_id deduplication. Report
  verified results, preserve local main work without commit/push/deployment.

## Self-review

Each ID has exact approved prompt reference, separate paid call, preview and
specific scene/quality checks. Grip rotation and mutual palms are distinct,
push press has a real dip, single support is explicit and time remains text.
Tasks1/5 implement red/green; Task6 preserves all prior work and138/78/60/178/316.

## Historical checkpoint — before approval of cw068 repeat

- [x] Task1: expected IDs expanded to cw067–cw072, fallbackcw073; red
  Docker failed only for missing cw067,365 other tests passed, analysis clean.
- [x] Task2: exact six prompts independently approved for spec and quality.
- [ ] Task3: cw067 correction-01 accepted after separation of initial weights
  and clarified intermediate hand rotation; cw069 trial-01 accepted.
  cw068 trial-01 returned HTTP error, no PNG. Its ledger has started/http_error,
  no status code, usage, request_id or cost; helper closes HTTPError without
  retaining those fields. No automatic retry. At this checkpoint a new request
  still required approval, subsequently granted as recorded below.
- [x] Task4: cw070–cw072 trial-01 accepted, source and512px preview inspected
  directly and reviewed for specification then quality.
- [ ] Tasks5/6: full integration/green verification pending cw068. No new WebP
  or registry additions yet; current integrated count remains132.

Six successful requests have upper-bound sum0.136987USD. One additional
HTTP-error attempt has UNKNOWN cost/billing; do not count it as free or include
it in a success-only estimate. Accepted sources remain outside repository:
cw067-correction-01 and cw069-trial-01 through cw072-trial-01.

## Final execution record — 2026-10-14

- [x] Task1: red contract missingcw067 only,365 other tests passed, no analysis issues.
- [x] Task2: exact prompts independently approved for specification and quality.
- [x] Task3: cw067/cw069 accepted; after explicit user approval of one new cw068 request in fresh trial-02, correction-01 restored true neutral grips and passed review.
- [x] Task4: cw070–cw072 accepted, correct support side and no time graphics.
- [x] Task5: six WebP512×512 integrated,138 exact files/IDs, fallbackcw073; full Docker366 tests passed, analysis clean, formatting0 changes.
- [x] Task6: status updated, earlier work preserved; independent final review approved all six WebP, integration counts and success-only ledger totals including the separate unknown-cost HTTP error.

Accepted sources under `/tmp/opencode`:

| ID | Directory | Frames |
|---|---|---:|
| cw067 | cw067-correction-01 | 3 vertical columns |
| cw068 | cw068-correction-01 | 2 side-by-side |
| cw069 | cw069-trial-01 | 3 vertical columns |
| cw070 | cw070-trial-01 | 2 horizontal rows |
| cw071 | cw071-trial-01 | 2 horizontal rows |
| cw072 | cw072-trial-01 | 2 horizontal rows |

Each source filename is `cwNNN-gpt-image-2.5-sunburst-medium.png`.
Direct source/preview inspection and independent specification→quality review.
Nine single attempts total: eight successes, one HTTP error in cw068-trial-01.
Success-only upper-bound sum 0.182506 USD; failed HTTP attempt has UNKNOWN cost,
not assumed free or included in this estimate. All ledgers and sources retained.
Green log:`/root/.local/share/opencode/tool-output/tool_139fa51a6001lMtj0OyhjnfWvZ`.
Counts 138/78/60/178/316, production 1.9.0+22, no version/commit/push/deployment.
