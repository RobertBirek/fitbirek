# Exercise Illustrations Batch 17 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved illustrations cw073–cw078.

**Architecture:** Red asset contract first, six separate reviewed sources, then whole-package WebP integration and green verification. Preserve earlier unpublished changes and record actual sources, reviews and costs.

**Tech Stack:** Sunburst medium via `tools/benchmark_exercise_images.py`, ImageMagick, Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and files

Approved spec: `docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-17-design.md`.
Read `AGENTS.md`, `docs/modules/training.md` and `assets/data/exercises.json`.
User approved layouts 2/3/2/2/2/2, continuous alternating transition cw074,
35-degree bench cw076–cw077 and floor pike cw078. Current main in `/opt/fit`,
no worktree, preserve Parts07–16 and all other existing changes.
Baseline 138 local / 78 published / 60 unpublished / 178 missing / 316 records;
target144/78/66/172/316. Production1.9.0+22; no version/commit/push/deployment.

- Create `assets/exercises/cw073.webp` through `cw078.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`,
  `lib/features/exercises/presentation/exercise_illustrations.dart`,
  `docs/exercise-illustrations-status.md`.
- Keep prompts, PNGs, previews, ledgers in `/tmp/opencode/cw073-*`
  through `/tmp/opencode/cw078-*`, outside repository.

## Task 1: Red contract

- [ ] Inspect git status/diff before edits, preserve existing work.
- [ ] Add after cw072 before cw251 in test expectedIllustrationIds:

```dart
    'cw073',
    'cw074',
    'cw075',
    'cw076',
    'cw077',
    'cw078',
```

- [ ] Update absence assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw079'), isNull);
  });
```

- [ ] Run with timeout >=1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-17-red .
```

Expected missing cw073 in registry as sole failure; other tests, fallback,
analysis and version check pass. Resolve unrelated failures before paid calls.

## Task 2: Prepare/review exact prompts

- [ ] Read style cw256 and verify existing `/tmp/opencode/cw256-reference.png`.
- [ ] Write six `cwNNN-trial-01-prompt.txt` in `/tmp/opencode`, via file tool.
  Exact text: common block plus ID-specific scene in approved spec's “Sześć
  promptów bazowych”, lines156–195. Do not combine different exercise scenes.
- [ ] Specification then quality review: forward/pronated grip, actual side
  transition, flye not row, torso-relative Y with thumb-up grip, chest contact
  and pike head clearance. Resolve findings before paid calls.

## Task 3: Generate cw073–cw075 sequentially

Verify parent directory and fresh output before each call; timeout >=240s.
Do not print secrets or raw provider payloads. Read original PNG and512px
preview, review spec then quality before another paid request.

- [ ] cw073:

```bash
test ! -e /tmp/opencode/cw073-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw073-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw073-trial-01 --exercise-id cw073 --single-sunburst-medium
convert /tmp/opencode/cw073-trial-01/cw073-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw073-trial-01/review-512.png
```

- [ ] Inspect two panels: bilateral forward raise to shoulder height, pronated
  actual grips/neutral wrists, stable feet, no lateral raise, swing or shrug.
- [ ] cw074:

```bash
test ! -e /tmp/opencode/cw074-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw074-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw074-trial-01 --exercise-id cw074 --single-sunburst-medium
convert /tmp/opencode/cw074-trial-01/cw074-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw074-trial-01/review-512.png
```

- [ ] Inspect three columns: anatomical right high→both midrange→left high,
  continuous opposite transition, same camera/torso/feet, both weights visible.
  No bilateral shoulder-height middle, down-arm weight loss or torso rotation.
- [ ] cw075:

```bash
test ! -e /tmp/opencode/cw075-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw075-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw075-trial-01 --exercise-id cw075 --single-sunburst-medium
convert /tmp/opencode/cw075-trial-01/cw075-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw075-trial-01/review-512.png
```

- [ ] Inspect two horizontal rows: same45-degree hinge, hang→wide lateral flye,
  mild unchanged elbow bend, two grips, no row/torso rise/shrug/cropped hands.

## Task 4: Generate cw076–cw078 sequentially

- [ ] cw076:

```bash
test ! -e /tmp/opencode/cw076-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw076-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw076-trial-01 --exercise-id cw076 --single-sunburst-medium
convert /tmp/opencode/cw076-trial-01/cw076-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw076-trial-01/review-512.png
```

- [ ] Inspect source/preview: two horizontal rows, prone35-degree bench,
  chest/pelvis contact, head beyond pad, both forefeet supported and two
  weights. Wide lateral flye, not row; no lost chest contact or collision.
- [ ] cw077:

```bash
test ! -e /tmp/opencode/cw077-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw077-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw077-trial-01 --exercise-id cw077 --single-sunburst-medium
convert /tmp/opencode/cw077-trial-01/cw077-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw077-trial-01/review-512.png
```

- [ ] Inspect source/preview: same bench/contact criteria; arms FORWARD relative
  to torso into Y, not T or vertical ceiling press; thumb sides up without
  breaking grips, no shrug/chest lift. Camera reveals both hands and supports.
- [ ] cw078:

```bash
test ! -e /tmp/opencode/cw078-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw078-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw078-trial-01 --exercise-id cw078 --single-sunburst-medium
convert /tmp/opencode/cw078-trial-01/cw078-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw078-trial-01/review-512.png
```

- [ ] Inspect source/preview: high V both phases, long legs, both palms and
  forefeet grounded at same locations, bent elbows lowered head with small
  gap (not head support). No flat push-up, kneeling or elevated feet.

### Correction/failure handling

Name genuine defects; fresh numbered prompt/output; ONLY last rejected PNG
as reference; preserve accepted details. Read source/preview before another
paid call. Stop after two failed corrections of same issue and evaluate new
composition before further spending. For provider error/uncertainty read
ledger, retain directory and do not automatically repeat; costs without data
remain unknown. Never reuse failed output paths. Maintain accepted sources
and actual independent/direct review records, no hypothetical defect fixes.

## Task 5: Integrate all accepted sources and restore green

- [ ] Confirm all six accepted paths and asset destination. Initial paths
  below apply ONLY if accepted; replace with recorded accepted corrections:

```bash
convert /tmp/opencode/cw073-trial-01/cw073-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw073.webp
convert /tmp/opencode/cw074-trial-01/cw074-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw074.webp
convert /tmp/opencode/cw075-trial-01/cw075-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw075.webp
convert /tmp/opencode/cw076-trial-01/cw076-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw076.webp
convert /tmp/opencode/cw077-trial-01/cw077-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw077.webp
convert /tmp/opencode/cw078-trial-01/cw078-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw078.webp
identify -format '%f %m %wx%h %b\n' assets/exercises/cw073.webp assets/exercises/cw074.webp assets/exercises/cw075.webp assets/exercises/cw076.webp assets/exercises/cw077.webp assets/exercises/cw078.webp
```

- [ ] Read six final WebP; nonempty512×512, frames2/3/2/2/2/2, maintained
  grips/directions/supports. Add after cw072 before cw251 in illustratedExerciseIds:

```dart
  'cw073',
  'cw074',
  'cw075',
  'cw076',
  'cw077',
  'cw078',
```

- [ ] Run with timeout >=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-17-verified .
docker run --rm fit-web:batch-17-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected version/analysis/full suite pass;144 exact assets/registry/expected
IDs,512px decode, fallbackcw079; formatting0 changes. No codegen/dependencies.

## Task 6: Document and final review

- [ ] Preserve earlier status/release history, update current counters:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 144 ilustracje:
78 wydanych oraz 66 lokalnie zintegrowanych, niewydanych z Partii 07–17.
172 ćwiczenia pozostają bez ilustracji.
```

- [ ] Add rows after cw072 before cw251:

```markdown
| cw073 | Unoszenie hantli w przód | 2 | Lokalnie zintegrowane; niewydane; równoczesny wznos obu rąk, nachwyt. |
| cw074 | Naprzemienne unoszenie hantli w przód | 3 | Lokalnie zintegrowane; niewydane; prawa, obie w połowie, lewa. |
| cw075 | Odwrotne rozpiętki z hantlami w opadzie | 2 | Lokalnie zintegrowane; niewydane; stały zawias około 45°, dwa poziome pasy. |
| cw076 | Odwrotne rozpiętki z hantlami na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; klatka podparta, dwa poziome pasy. |
| cw077 | Unoszenie hantli w kształt litery Y na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; Y względem tułowia, kciuki w górę. |
| cw078 | Pompki z biodrami uniesionymi wysoko | 2 | Lokalnie zintegrowane; niewydane; podstawowy pike na podłodze. |
```

- [ ] Add “Siedemnasta partia” before general rules with actual sources,
  layout/variant and review findings, corrections, success-only unique
  request totals and cost estimates (unknown failures separate), green log
  evidence,144/78/66/172/316 and production1.9.0+22. Record execution here.
- [ ] Final independent asset/integration/ledger review; git diff --check
  and scoped git status. Preserve all earlier changes; no commit/push/deploy.

## Self-review

Each ID has exact approved prompt reference, separate single call and preview,
concrete spec/quality checks. Front raises distinguish both sides, flye is
not row, Y is torso-relative, bench/pike supports explicit. Tasks1/5 prove
red/green; Task6 preserves prior work and144/78/66/172/316 accounting.

## Historical checkpoint — before approval of new cw078 composition

- [x] Task1: red Docker failure only for missing cw073;365 other tests passed,
  analysis clean. Expectationscw073–cw078, fallbackcw079.
- [x] Task2: exact six prompts independently approved for spec and quality.
- [x] Task3: cw073–cw075 trial-01 accepted, source/512px preview inspected
  directly and reviewed in order spec→quality.
- [ ] Task4: cw076 trial-01 accepted; cw077 correction-01 accepted after
  making body-relative Y readable and uniformly rescaling both scenes.
  cw078 initial and two corrections rejected for near-hand support slide;
  final remainder35–40px at1024, approximately8–10% foot-to-hand span change.
  Other pike technique/support criteria were accepted, but fixed contact
  requirement remains unmet. Stop paid corrections of this composition.
- [ ] Tasks5/6: full integration/green verification pending acceptedcw078.
  No new WebP/registry entries yet; integrated count remains138.

Accepted sources outside repository: cw073-trial-01 throughcw076-trial-01,
cw077-correction-01. Nine successful single requests, upper-bound sum
0.205318USD; no failed HTTP requests in this batch so far. Costs are
estimates, not confirmed provider billing. All rejected PNGs/ledgers retained.

Proposed materially different cw078 composition for user approval: true
side profile, more compact highV, same two horizontal rows, subtle unlabeled
floor seams to anchor hand/foot contacts. This would amend original3/4
camera requirement; do not generate until approved.

## Final execution record — 2026-10-14

- [x] Task1: red contract missing cw073 only;365 other tests passed, no analysis issues.
- [x] Task2: six exact prompts reviewed independently for specification and quality.
- [x] Task3: cw073–cw075 initial sources accepted with correct directions/grips/sequence.
- [x] Task4: cw076 accepted; cw077 corrected Y; after explicit user approval new cw078 side-profile composition accepted with stable supports.
- [x] Task5: six WebP512×512 integrated,144 exact assets/IDs,fallbackcw079; full Docker366 tests passed,analysis clean,formatting0 changes.
- [x] Task6: status/counters/history/sources/costs updated; independent final review approved all six WebP, integration counts, preserved earlier work and deduplicated ledger totals.

Accepted sources under `/tmp/opencode`:

| ID | Directory | Frames |
|---|---|---:|
| cw073 | cw073-trial-01 | 2 side-by-side |
| cw074 | cw074-trial-01 | 3 vertical columns |
| cw075 | cw075-trial-01 | 2 horizontal rows |
| cw076 | cw076-trial-01 | 2 horizontal rows |
| cw077 | cw077-correction-01 | 2 horizontal rows |
| cw078 | cw078-new-01 | 2 horizontal rows, side profile |

Filename in each directory: `cwNNN-gpt-image-2.5-sunburst-medium.png`.
Each source/preview directly inspected and independently reviewed in order
specification then quality. Six initial attempts, three corrections and one
approved new composition:10 successful requests,upper-bound sum0.228200USD.
No HTTP errors/unknown-cost attempts in this batch, no automatic retries.
Retain all rejected images and ledgers. Estimate is not provider billing.
The approved side-profile amendment supersedes original3/4 for cw078 only;
same layouts/support technique apply otherwise.

Green verification output:
`/root/.local/share/opencode/tool-output/tool_13a7bc8f8001Wtof4glXjYpgJx`.
Current144/78/66/172/316; production1.9.0+22, no version/Git/deployment operations.
