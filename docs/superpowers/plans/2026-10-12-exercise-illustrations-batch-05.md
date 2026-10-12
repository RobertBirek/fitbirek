# Exercise Illustrations Batch 05 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and integrate six reviewed offline push-up illustrations for `cw001–cw006`.

**Architecture:** Generate separate two-frame PNGs, accept each scene at full and final resolution, then integrate all six as one package of 512×512 WebP assets. The existing Flutter registry, exact asset-set test and decoding test remain the contract. New assets remain unreleased until a separate release decision.

**Tech Stack:** OpenAI image edits through `tools/benchmark_exercise_images.py`, ImageMagick 6 (`convert`), Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read: `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-12-exercise-illustrations-batch-05-design.md`.
- Create: `assets/exercises/cw001.webp`, `cw002.webp`, `cw003.webp`, `cw004.webp`, `cw005.webp`, `cw006.webp`.
- Modify: `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary only: prompts, original PNGs, review previews and ledgers in `/tmp/opencode/cw001-*` through `/tmp/opencode/cw006-*`.
- Reference: `assets/exercises/cw256.webp`; generator reference PNG `/tmp/opencode/cw256-reference.png`.
- Work in `/opt/fit`, current `main`, no worktree, following the existing user preference. Preserve uncommitted Batch 04 files and documentation.
- Do not commit or push without an explicit request. This plan does not promote production images or change release metadata. Current production remains `1.8.0+21`.

## Task 1: Establish the red contract

**Files:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect the starting workspace with `git status --short` and `git diff`; identify existing Batch 04 changes before editing.
- [ ] Insert the following entries at the beginning of `expectedIllustrationIds`, immediately before `cw251`, preserving all existing entries:

```dart
    'cw001',
    'cw002',
    'cw003',
    'cw004',
    'cw005',
    'cw006',
```

- [ ] Change the existing absent-asset test to the next unillustrated exercise:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw007'), isNull);
  });
```

- [ ] Run the red verification with a timeout of at least 600 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-05-red .
```

Expected: registry equality fails because production lacks `cw001`; the absent-asset test for `cw007` passes. Do not add production registry entries or WebP assets yet. If failure comes from infrastructure or a different test, investigate before generating images.

## Task 2: Prepare exact generation prompts

**Files:** six temporary prompt files `/tmp/opencode/cw001-trial-01-prompt.txt` through `/tmp/opencode/cw006-trial-01-prompt.txt`.

- [ ] Read the reference image. Verify its PNG exists; if missing, create it after checking `/tmp/opencode` exists:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Create each prompt using the following common paragraph plus its exact scene paragraph below. Use the file-editing tool, not shell redirection:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark outlines, faceless adult in dark neutral clothes. No text, numbers, arrows, labels or watermark. Square 1024x1024. Exactly two separated side-by-side panels, read left to right. Same adult, camera and working side in both panels. Entire body, hands and feet visible with generous margins. No required colored muscle overlays. Show a stable torso and a neutral head aligned with the spine. Ensure both movement phases and this specific push-up variant remain clearly distinguishable when reduced to 512x512. Anatomically coherent limbs, hands and floor contacts, no duplicated limbs.
```

`/tmp/opencode/cw001-trial-01-prompt.txt` scene:

```text
Classic push-up. Slightly elevated side three-quarter camera showing both hands. Left: high plank with straight arms, hands about shoulder width, toes grounded, body straight from head to heels. Right: chest close to the floor, elbows bent approximately 45 degrees away from the torso, chest and hips lowered together. Keep hips from sagging, no elbows flared 90 degrees, no head-only descent.
```

`/tmp/opencode/cw002-trial-01-prompt.txt` scene:

```text
Diamond push-up. Slightly elevated front-side three-quarter camera from the head end clearly revealing the close hand placement. Left: high plank, thumbs and index fingers of both hands touching to form one diamond directly below the chest. Right: chest just above those hands, elbows bent close to the torso. Both hands remain close and in contact with the floor. Maintain a straight stable body. No wide hand placement, hidden hand diamond, sagging hips or outward-flared elbows.
```

`/tmp/opencode/cw003-trial-01-prompt.txt` scene:

```text
Wide push-up. Slightly elevated front-side three-quarter camera clearly revealing the spacing between both hands. Left: high plank, hands approximately 1.5 times shoulder width apart, clearly wider than a classic push-up but not excessively wide. Right: controlled descent with chest close to the floor between the hands. Keep shoulders supported and torso straight, no collapsed shoulders or sagging hips. Hand spacing must visibly distinguish this from a classic push-up.
```

`/tmp/opencode/cw004-trial-01-prompt.txt` scene:

```text
Archer push-up. Elevated front three-quarter camera showing both arms. Left: symmetric wide high plank with both arms straight, hands grounded. Right: shift weight toward one working side, bend that elbow and lower the chest toward that hand, while the opposite arm remains straight sideways with its hand on the floor. Same working side throughout. Keep pelvis and torso stable without twisting or collapsing. Do not bend both elbows like a wide push-up and do not lift the assisting hand.
```

`/tmp/opencode/cw005-trial-01-prompt.txt` scene:

```text
One-arm push-up. Side three-quarter camera from the free-arm side, clearly showing the supporting palm and the wide stance of both feet. Left: high plank supported by exactly one hand and two widely spaced feet; free hand visibly tucked behind the lower back, not touching the floor. Right: bend only the working elbow, lower chest and hips together as one stable unit, same supporting side. No supporting second hand, extra limbs, pelvic twisting or uneven torso descent.
```

`/tmp/opencode/cw006-trial-01-prompt.txt` scene:

```text
Plyometric clap push-up. Side three-quarter camera clearly showing both hands and toe contacts. Left: low push-up just before explosive takeoff, chest near floor, elbows bent, both palms grounded. Right: upper body airborne after push-off, BOTH hands visibly clear of the floor and meeting in a clap in front of the chest, toes still grounded. Torso remains straight and braced. Right panel is flight, not landing: no supporting palms during the clap, no extra hands, no collapsed torso. Make the air gap underneath both hands unmistakable.
```

## Task 3: Generate and review cw001–cw003 sequentially

**Files:** temporary PNGs, ledgers and review previews only.

- [ ] For `cw001`, verify the first output directory is fresh, then issue exactly one paid request. Do not display the credentials file or environment values:

```bash
test ! -e /tmp/opencode/cw001-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw001-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw001-trial-01 --exercise-id cw001 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw001-trial-01/cw001-gpt-image-2.5-sunburst-medium.png`. Create a review copy and read it as well:

```bash
convert /tmp/opencode/cw001-trial-01/cw001-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw001-trial-01/review-512.png
```

- [ ] Check the exact scene, anatomy, hand spacing, elbow position, hips and phase difference against the spec. Record the accepted source path or name a specific defect before continuing.
- [ ] Once `cw001` is reviewed, run one request for `cw002`:

```bash
test ! -e /tmp/opencode/cw002-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw002-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw002-trial-01 --exercise-id cw002 --single-sunburst-medium
convert /tmp/opencode/cw002-trial-01/cw002-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw002-trial-01/review-512.png
```

Read both PNGs. Require a clearly visible diamond hand placement, close elbows and stable body.

- [ ] Once `cw002` is reviewed, run one request for `cw003`:

```bash
test ! -e /tmp/opencode/cw003-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw003-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw003-trial-01 --exercise-id cw003 --single-sunburst-medium
convert /tmp/opencode/cw003-trial-01/cw003-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw003-trial-01/review-512.png
```

Read both PNGs. Compare with accepted `cw001` and `cw002` at 512px: hand placement must distinguish all three variants.

- [ ] Review specification compliance first, quality second. For subagent execution, use separate review agents. Resolve findings before marking this task complete.

## Task 4: Generate and review cw004–cw006 sequentially

**Files:** temporary PNGs, ledgers and review previews only.

- [ ] Generate `cw004`, then inspect full resolution and preview before another paid request:

```bash
test ! -e /tmp/opencode/cw004-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw004-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw004-trial-01 --exercise-id cw004 --single-sunburst-medium
convert /tmp/opencode/cw004-trial-01/cw004-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw004-trial-01/review-512.png
```

Read both PNGs; require one bent working elbow and one straight assisting arm in the lower phase, with both hands grounded and no pelvic twist.

- [ ] After reviewing `cw004`, generate `cw005`:

```bash
test ! -e /tmp/opencode/cw005-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw005-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw005-trial-01 --exercise-id cw005 --single-sunburst-medium
convert /tmp/opencode/cw005-trial-01/cw005-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw005-trial-01/review-512.png
```

Read both PNGs; exactly one supporting hand, wide feet, visible free hand behind back, one coherent lowering motion.

- [ ] After reviewing `cw005`, generate `cw006`:

```bash
test ! -e /tmp/opencode/cw006-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw006-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw006-trial-01 --exercise-id cw006 --single-sunburst-medium
convert /tmp/opencode/cw006-trial-01/cw006-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw006-trial-01/review-512.png
```

Read both PNGs; right phase must show a clap with both hands airborne and toes grounded, not an impossible supported clap.

- [ ] Review specification compliance first, quality second. Resolve findings before integration.

### Correction procedure for Tasks 3 and 4

On rejection, record the exact visible defect and create a new prompt specifying only that correction while preserving accepted parts of the scene. Use the immediately rejected PNG as the sole reference, and a fresh next-numbered directory; never reuse an output directory or automatically retry a paid request. Use the same script with `--single-sunburst-medium`, substituting the actual exercise ID, new prompt/output paths and rejected PNG reference. Read both new full-resolution and 512px images before any next request. Keep an explicit accepted-source list for all six IDs. If successive corrections fail to remove the same defect, stop paid calls and ask to revise the scene rather than escalating the request count without discussion.

## Task 5: Integrate the accepted six assets

**Files:** six WebP assets and `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all six accepted sources have passed both reviews. Convert each recorded accepted source to its matching destination with `-resize 512x512 -strip -quality 90`. For accepted first attempts, the exact commands are:

```bash
convert /tmp/opencode/cw001-trial-01/cw001-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw001.webp
convert /tmp/opencode/cw002-trial-01/cw002-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw002.webp
convert /tmp/opencode/cw003-trial-01/cw003-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw003.webp
convert /tmp/opencode/cw004-trial-01/cw004-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw004.webp
convert /tmp/opencode/cw005-trial-01/cw005-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw005.webp
convert /tmp/opencode/cw006-trial-01/cw006-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw006.webp
```

When a correction was accepted, replace only that source path with the recorded accepted PNG; never convert a rejected trial merely because it appears in this example.

- [ ] Verify the six dimensions and nonempty byte counts:

```bash
identify -format '%f %wx%h %b\n' assets/exercises/cw00{1..6}.webp
```

Expected: six nonempty WebP files, each `512x512`.

- [ ] Insert these entries at the start of `illustratedExerciseIds`, immediately before `cw251`, preserving the existing 66:

```dart
  'cw001',
  'cw002',
  'cw003',
  'cw004',
  'cw005',
  'cw006',
```

- [ ] Run full green verification with timeout at least 600 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-05-verified .
```

Expected: no analysis findings, all tests pass, exact asset-set and 512px decoding contracts pass, absent illustration for `cw007` remains correct. Do not regenerate models or update dependencies on the host; verification manages generated build code inside Docker.

## Task 6: Record package status and final review

**Files:** `docs/exercise-illustrations-status.md`.

- [ ] Keep the current published version as `1.8.0+21`. Replace the opening counts with:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 72 ilustracje:
66 wydanych oraz 6 lokalnie zintegrowanych z Partii 05.
244 ćwiczenia pozostają bez ilustracji.
```

- [ ] Add these rows before `cw251` in the status table and rename its heading to `## Ilustracje — wydane i lokalnie zintegrowane`:

```markdown
| cw001 | Pompki klasyczne | 2 | Lokalnie zintegrowane; niewydane. |
| cw002 | Pompki wąskie (diamentowe) | 2 | Lokalnie zintegrowane; niewydane. |
| cw003 | Pompki szerokie | 2 | Lokalnie zintegrowane; niewydane. |
| cw004 | Pompki łucznika | 2 | Lokalnie zintegrowane; niewydane. |
| cw005 | Pompki na jednej ręce | 2 | Lokalnie zintegrowane; niewydane. |
| cw006 | Pompki plyometryczne z klaśnięciem | 2 | Lokalnie zintegrowane; niewydane. |
```

- [ ] Add before `## Obowiązujące zasady`:

```markdown
## Piąta partia

Zakres piątej partii obejmuje `cw001–cw006`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry i jest lokalnie zintegrowanych. Weryfikacja
Dockerowa obejmuje analizę i pełny zestaw testów. Pakiet nie jest jeszcze
wydany; wersja produkcyjna pozostaje `1.8.0+21`.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`. Require only the intended Batch 05 additions on top of preserved Batch 04 work.
- [ ] Perform final specification and quality review of all six WebP files, registry/test and documentation. Check the package has 72 registered files while the public release still has only the prior 66.
- [ ] Report accepted source paths, successful verification, number and ledger-estimated costs of paid requests, and any unresolved findings. Stop at a prepared, reviewed package; release version, deployment, commit and push are separate user decisions.

## Plan self-review

- Coverage: Tasks 2–4 define and review all six approved scenes; Task 5 integrates all assets together and restores green; Task 6 records the correct local/published distinction.
- Fallback: Task 1 replaces the obsolete `cw001` no-asset assertion with `cw007`.
- Ordering: both test and production register `cw001–cw006` before `cw251`.
- Consistency: six new images, 72 local illustrations, 66 published, 244 unillustrated, 316 catalog entries.
- Boundaries: no automatic release/version changes and no commits or push; existing Batch 04 work is preserved.
