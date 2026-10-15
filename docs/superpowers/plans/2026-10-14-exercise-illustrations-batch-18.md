# Exercise Illustrations Batch 18 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved illustrations cw079–cw084.

**Architecture:** Establish red asset-set contract, prepare six exact prompts, generate sources sequentially with source/512px review before another paid call. Integrate the full accepted package as WebP, restore green, record evidence and preserve earlier unpublished work.

**Tech Stack:** Sunburst medium via `tools/benchmark_exercise_images.py`, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and files

Approved spec: `docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-18-design.md`.
Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`.
User approved layouts2/1/2/2/2/2, back-to-wall handstand/HSPU and
left-foot/right-hand unilateral band raise. Work in `/opt/fit`, main without
worktree. Preserve Parts07–17 and all other existing work.
Baseline144/78/66/172/316; target150 local/78 published/72 unpublished/
166 missing/316 records. Production1.9.0+22; no version/commit/push/deployment.

- Create `assets/exercises/cw079.webp` through `cw084.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`,
  `lib/features/exercises/presentation/exercise_illustrations.dart`,
  `docs/exercise-illustrations-status.md`.
- Temporary prompts, PNGs, previews and ledgers in `/tmp/opencode/cw079-*`
  through `/tmp/opencode/cw084-*`, outside repository.

## Task 1: Red contract

- [ ] Inspect git status/scoped diff before edits; preserve existing changes.
- [ ] Add after cw078 before cw251 in test expectedIllustrationIds:

```dart
    'cw079',
    'cw080',
    'cw081',
    'cw082',
    'cw083',
    'cw084',
```

- [ ] Change absence assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw085'), isNull);
  });
```

- [ ] Run with timeout >=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-18-red .
```

Expected missingcw079 registry failure only, other tests/fallback/version/
analysis pass. Investigate unrelated failures before paid generation.

## Task 2: Prepare/review exact prompts

- [ ] Read cw256 style and identify existing `/tmp/opencode/cw256-reference.png`.
- [ ] Write six `/tmp/opencode/cwNNN-trial-01-prompt.txt` via file tool,
  common block plus respective ID scene from approved spec “Sześć promptów
  bazowych”, lines166–205. No other exercise scene in each prompt.
- [ ] Specification then clarity/geometry review. Pay attention to floor
  wrist extension vs band grip alignment, fixed palm contacts but sliding
  heels in HSPU, source-foot/handle routes and frontal anatomical sides cw083.
  Resolve concrete findings before paid requests.

## Task 3: Generate/review cw079–cw081 sequentially

Verify parent/output freshness, timeout >=240seconds each. Never print
secrets/raw API payloads. Read original/preview and review spec then quality
before another paid request; inspect all contacts and meaningful range.

- [ ] cw079:

```bash
test ! -e /tmp/opencode/cw079-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw079-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw079-trial-01 --exercise-id cw079 --single-sunburst-medium
convert /tmp/opencode/cw079-trial-01/cw079-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw079-trial-01/review-512.png
```

- [ ] Inspect two horizontal rows: forefeet on same horizontal bench,
  palms floor, highhips/longlegs, fixedcontactspans, longarms→bentelbows
  with head close to floor and free. No kneeling/flat decline push-up.
- [ ] cw080:

```bash
test ! -e /tmp/opencode/cw080-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw080-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw080-trial-01 --exercise-id cw080 --single-sunburst-medium
convert /tmp/opencode/cw080-trial-01/cw080-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw080-trial-01/review-512.png
```

- [ ] Inspect ONE full-body hold: backtowall/heelcontact, flatpalms with
  wallgap, active straightarms, straightbody, headclearance/gazedown,
  no entry sequence/timegraphic/banana/headstand.
- [ ] cw081:

```bash
test ! -e /tmp/opencode/cw081-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw081-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw081-trial-01 --exercise-id cw081 --single-sunburst-medium
convert /tmp/opencode/cw081-trial-01/cw081-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw081-trial-01/review-512.png
```

- [ ] Inspect two sidebyside panels: backtowall both, same wall/floor/palms,
  straightarms→controlled deepdescent, heels LOWER and still contactwall.
  No head support, footheightfreeze, pike/knee-tuck/kip/banana or crop.

## Task 4: Generate/review cw082–cw084 sequentially

- [ ] cw082:

```bash
test ! -e /tmp/opencode/cw082-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw082-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw082-trial-01 --exercise-id cw082 --single-sunburst-medium
convert /tmp/opencode/cw082-trial-01/cw082-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw082-trial-01/review-512.png
```

- [ ] Inspect source/preview: singleband middle pinned BOTHsoles,2tautbranches
  to2same-side handles, shoulderheight→overhead, palmsforward, foot/spine
  stability, logical route outsidehead. No dumbbells/wallanchor/loosegrip.
- [ ] cw083:

```bash
test ! -e /tmp/opencode/cw083-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw083-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw083-trial-01 --exercise-id cw083 --single-sunburst-medium
convert /tmp/opencode/cw083-trial-01/cw083-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw083-trial-01/review-512.png
```

- [ ] Inspect twohorizontalrows/frontcamera: anatomicalLEFTfoot anchor,
  RIGHThand onlyworking grip, BOTHfeetfloor, emptyLEFThand. Onebranch
  travels across FRONT of body, explained foreground overlay is allowed,
  lateral shoulderheight/mildelbows/neutralwrist, no side switch/shrug.
- [ ] cw084:

```bash
test ! -e /tmp/opencode/cw084-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw084-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw084-trial-01 --exercise-id cw084 --single-sunburst-medium
convert /tmp/opencode/cw084-trial-01/cw084-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw084-trial-01/review-512.png
```

- [ ] Inspect source/preview:2panels,ONEband underBOTHsoles,2traceablehandles,
  hips→bilateralFORWARDshoulderheight withpronatedgrips, no legdrive,
  rocking or dumbbells. Differentiate from lateral/overhead scene.

### Correction/failure procedure

Name actual defects, fresh numbered prompt/output, ONLY last rejected PNG
as reference. Preserve accepted parts; inspect source/preview before next
call. After two unsuccessful corrections of same issue stop and evaluate
materially different composition before paid continuation. For HTTP or
uncertain outcome inspect ledger, preserve exclusive output directory and
do not automatically retry. Unknown costs remain unknown, not free. Track
actual accepted paths, direct/independent reviews and success-only totals.

## Task 5: Whole-package integration and green verification

- [ ] Confirm6acceptedpaths and assetdestination. For acceptedinitialsources
  use below; replace rejected paths only with recordedacceptedcorrection:

```bash
convert /tmp/opencode/cw079-trial-01/cw079-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw079.webp
convert /tmp/opencode/cw080-trial-01/cw080-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw080.webp
convert /tmp/opencode/cw081-trial-01/cw081-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw081.webp
convert /tmp/opencode/cw082-trial-01/cw082-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw082.webp
convert /tmp/opencode/cw083-trial-01/cw083-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw083.webp
convert /tmp/opencode/cw084-trial-01/cw084-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw084.webp
identify -format '%f %m %wx%h %b\n' assets/exercises/cw079.webp assets/exercises/cw080.webp assets/exercises/cw081.webp assets/exercises/cw082.webp assets/exercises/cw083.webp assets/exercises/cw084.webp
```

- [ ] Read all6WebP, nonempty512×512, frames2/1/2/2/2/2, supports/grips/routes
  readable. Add aftercw078 beforecw251 in illustratedExerciseIds:

```dart
  'cw079',
  'cw080',
  'cw081',
  'cw082',
  'cw083',
  'cw084',
```

- [ ] Run timeout >=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-18-verified .
docker run --rm fit-web:batch-18-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected version/analysis/fullsuite green,150exactfiles/IDs,512decode,
fallbackcw085 and0formattingchanges. No codegen/dependency/WebSQLitechanges.

## Task 6: Status and final review

- [ ] Preserve earlier status/release evidence, update counters:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 150 ilustracji:
78 wydanych oraz 72 lokalnie zintegrowane, niewydane z Partii 07–18.
166 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Add rows aftercw078 beforecw251:

```markdown
| cw079 | Pompki z biodrami uniesionymi wysoko i nogami na ławce | 2 | Lokalnie zintegrowane; niewydane; stopy na ławce, dłonie na podłodze. |
| cw080 | Stanie na rękach przy ścianie | 1 | Lokalnie zintegrowane; niewydane; plecami do ściany, czas w katalogu. |
| cw081 | Pompki w staniu na rękach przy ścianie | 2 | Lokalnie zintegrowane; niewydane; plecami do ściany, pięty przesuwają się pionowo. |
| cw082 | Wyciskanie gumy nad głowę | 2 | Lokalnie zintegrowane; niewydane; jedna guma pod obiema stopami. |
| cw083 | Unoszenie ramienia bokiem z gumą | 2 | Lokalnie zintegrowane; niewydane; lewa stopa kotwiąca, prawa ręka robocza. |
| cw084 | Unoszenie ramion w przód z gumą | 2 | Lokalnie zintegrowane; niewydane; dwie gałęzie gumy pod obiema stopami. |
```

- [ ] Add “Osiemnasta partia” beforegeneralrules, actualsources/layouts,
  reviews/corrections, successonlycost/requestcount, anyunknownfailurecost
  separate, greenlog and150/78/72/166/316. Record execution here and in spec.
- [ ] Independent finalasset/integration/ledger review, git diff --check,
  scoped git status. Report verified result; production1.9.0+22 preserved,
  no automatic Git/version/deployment operations.

## Self-review

Every ID has exactpromptreference, separatecall/preview and clearchecks.
Supports distinguish heel slide from fixed palms and sole anchor from
singlelegbalance. Gripwrist vspalmfloorextension explicit. Tasks1/5 red/green,
Task6 earlierworkpreservation and150/78/72/166/316 accounting.

## Execution record — 2026-10-14

- [x] Task1: red missingcw079 only;365 other tests passed, analysis clean.
- [x] Task2: exact prompts independently approved; floor wrist extension distinct from neutral band-grip alignment.
- [x] Task3: cw079 initial accepted independently; cw080 corrected inverted head anatomy, cw081 corrected fixed palm contacts/arms. Limit reached at cw080 review dispatch; subsequent reviews conducted directly.
- [x] Task4: cw082/cw084 initial accepted; cw083's reversed anatomical sides fixed by local whole-image horizontal reflection, then reviewed again. No paid regeneration for reflection.
- [x] Task5: sixWebP512×512 integrated,150exactfiles/IDs,fallbackcw085. Interrupted build resumed; completeDocker366tests passed,analysis clean,formatting0changes.
- [x] Task6: status/history/sources updated, all finalWebP and8ledgers read directly; registry150, closing diff/status checks and public production version/health confirmed. Final review performed directly, not independently after quota.

Accepted source paths under `/tmp/opencode`:

| ID | Directory | Filename | Frames |
|---|---|---|---:|
| cw079 | cw079-trial-01 | cw079-gpt-image-2.5-sunburst-medium.png | 2 horizontal rows |
| cw080 | cw080-correction-01 | cw080-gpt-image-2.5-sunburst-medium.png | 1 |
| cw081 | cw081-correction-01 | cw081-gpt-image-2.5-sunburst-medium.png | 2 side-by-side |
| cw082 | cw082-trial-01 | cw082-gpt-image-2.5-sunburst-medium.png | 2 side-by-side |
| cw083 | cw083-trial-01 | cw083-approved-flipped.png | 2 horizontal rows |
| cw084 | cw084-trial-01 | cw084-gpt-image-2.5-sunburst-medium.png | 2 side-by-side |

cw083 source derivation: `convert` original generatedPNG with `-flop` into
a separate approvedPNG, retaining original and ledger. No text/labels were
present; both poses mirrored together, preserving all physical contacts.

Six initial requests and two paid corrections:8unique successes,
upper-bound estimate0.182626USD; no HTTPerrors or unknown final cost in
this batch. Each ledger has response_received+success for same request_id;
only success counted, and all8 IDs distinct. The mirror adds NO request.
Estimate not confirmed provider billing. Independent review unavailable
after quota at cw080; source/preview/final/integration reviews completed
directly and are not represented as independent reviews.

Green log:`/root/.local/share/opencode/tool-output/tool_13b04a1eb0017emcPBeUax0vjP`.
Current150/78/72/166/316,production1.9.0+22,no version/Git/deploymentoperations.
