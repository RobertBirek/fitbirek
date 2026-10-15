# Exercise Illustrations Batch 08 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, review and locally integrate six two-frame illustrations for `cw019–cw024`, including supported dumbbell movements and resistance-band exercises.

**Architecture:** Generate separate 1024×1024 PNGs and inspect every source and its 512×512 preview before the next paid request. Integrate all accepted sources together as one WebP per exercise, extending the existing registry and exact asset-set/decoding tests. Publication remains a separate decision.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6 (`convert`), Flutter 3.35.4/Dart 3.9.2 in Docker.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json`, `docs/superpowers/specs/2026-10-12-exercise-illustrations-batch-08-design.md`.
- Work in `/opt/fit`, current `main`, without a worktree, following the existing user preference. Preserve all uncommitted Part 07 files and any other pre-existing work.
- Create `assets/exercises/cw019.webp`, `cw020.webp`, `cw021.webp`, `cw022.webp`, `cw023.webp`, `cw024.webp`.
- Modify `test/features/exercises/exercise_illustrations_test.dart`, `lib/features/exercises/presentation/exercise_illustrations.dart`, `docs/exercise-illustrations-status.md`.
- Temporary only: prompts, PNGs, previews and ledgers under `/tmp/opencode/cw019-*` through `/tmp/opencode/cw024-*`.
- Style reference: `assets/exercises/cw256.webp`; first-request PNG reference: `/tmp/opencode/cw256-reference.png`.
- Baseline: 84 local illustrations, 78 published, 6 unpublished, 232 missing from 316 catalog records. Final local state: 90, 78, 12, 226, 316 respectively.
- Approved variants: `cw019` lies lengthwise along a flat bench; `cw024` stands with a high anchor behind the body.
- No automatic version bump, deployment, commit or push. Production remains `1.9.0+22`.

## Task 1: Establish the red registry contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect `git status --short` and `git diff` to identify existing Part 07 changes before editing.
- [ ] Add these entries after `cw018`, before `cw251`, in `expectedIllustrationIds`, preserving the previous 84 IDs:

```dart
    'cw019',
    'cw020',
    'cw021',
    'cw022',
    'cw023',
    'cw024',
```

- [ ] Move the existing absent-asset assertion to `cw025`:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw025'), isNull);
  });
```

- [ ] Run with a timeout of at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-08-red .
```

Expected: registry equality fails because production lacks `cw019`; fallback `cw025` passes. Investigate unrelated failures before paid generation. Leave production IDs and WebP files unchanged until all six scenes pass their reviews.

## Task 2: Prepare and review six exact prompts

**Files:** `/tmp/opencode/cw019-trial-01-prompt.txt` through `/tmp/opencode/cw024-trial-01-prompt.txt`.

- [ ] Read the reference WebP and existing PNG; require a matching reference. If the PNG is missing, create it after verifying its parent directory:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

- [ ] Write each prompt through the file-editing tool using this common paragraph followed by its exact scene paragraph:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark outlines, faceless adult in dark neutral clothes. No text, numbers, arrows, labels or watermark. Square 1024x1024. EXACTLY TWO separated side-by-side panels, read left to right. Same adult, fixed camera, equipment and body support contacts in both panels. Entire body and all essential equipment fit within each panel with generous margins. Make grips, hands, feet and support contacts readable after reduction to 512x512. Natural spatial perspective and occlusion, no transparent anatomy, collisions, missing grips or duplicated limbs. No required colored muscle overlays. Show controlled movement and stable posture.
```

`/tmp/opencode/cw019-trial-01-prompt.txt` scene:

```text
Dumbbell pullover, adult lying LENGTHWISE along a FLAT bench, not crosswise. Fixed side three-quarter camera showing the grip and space behind the head. Head, upper back and buttocks supported, both feet on floor. Exactly ONE dumbbell held with BOTH hands cupping beneath the same upper head. Left: dumbbell above the chest, elbows slightly bent. Right: move the same dumbbell in an arc behind the head, retaining the SAME slight elbow bend and all body supports. Movement comes from the shoulders, not a triceps elbow-extension action. Controlled range without forcing arms far below the bench. No second dumbbell, floating grip, lifted hips, exaggerated back arch or collision with head or bench.
```

`/tmp/opencode/cw020-trial-01-prompt.txt` scene:

```text
Dumbbell chest press while HOLDING a glute bridge on the FLOOR. Fixed slightly elevated side three-quarter camera showing both dumbbells and hips. Head and upper back supported, knees bent, both feet flat. Hips lifted to form a stable shoulder-to-knee line, with exactly the SAME hip height in both panels. Left: TWO separate dumbbells beside the chest, one hand per handle, wrists above elbows, elbows about 45 degrees from torso. Right: press the two weights above the chest, arms straight without exaggerated hyperextension, weights separate. No lowered hips, support on the neck instead of upper back, lifted feet, excessive lumbar arch, bent-back wrists, facial weights or merged dumbbells.
```

`/tmp/opencode/cw021-trial-01-prompt.txt` scene:

```text
Standing resistance-band chest press. Fixed side three-quarter camera revealing a stable ANCHOR BEHIND the body at CHEST HEIGHT on a simple support post, plus both hand grips. Stable split stance with a forward step giving tension, upright still torso. TWO working band branches connect the same rear anchor to separate handles, one in each hand, passing outside the body. Left: hands beside chest, elbows bent, band already taut. Right: press both hands forward at chest height, elbows nearly straight, band more stretched. Same stance, anchor position and band connections. Flexible tensioned band, not rigid rods. No front anchor, loose band, disconnected grip, band through neck/head/torso, backward lean or overhead motion. Bent-to-straight elbows must make this clearly a PRESS.
```

`/tmp/opencode/cw022-trial-01-prompt.txt` scene:

```text
Standing resistance-band flye, NOT a press. Fixed elevated front-side three-quarter camera revealing arm opening, both grips and the stable REAR ANCHOR at CHEST HEIGHT on a simple support post. Stable split stance, upright still torso. TWO taut working branches connect the same anchor to one handle in each hand, outside the body. Left: arms open sideways around chest height, elbows slightly bent, not forced far behind the torso. Right: bring hands close in an arc in front of chest, retaining the SAME slight elbow bend, with no need for handles to touch. Same stance, anchor and connections. No elbow straightening as in a press, torso rotation, loose or vanishing band, disconnected grip or band penetrating neck/head/torso.
```

`/tmp/opencode/cw023-trial-01-prompt.txt` scene:

```text
Band-resisted push-up, NO external anchor. Fixed slightly elevated side three-quarter camera showing both palms and the upper back. Left: high plank, hands about shoulder width, toes supported, straight head-to-heel body line. The middle of ONE resistance band runs across the UPPER BACK BELOW THE NECK, with BOTH ENDS trapped under the palms on the floor. Right: chest lowered close to floor, elbows about 45 degrees from torso, stable hips, same band route across the back and under the same palms, less stretched than in the high plank. Band must be distinguishable from clothing and its route evident. No band through neck or torso, loose ends without palm fixation, external anchor, dropped hips, extra arms or elbows flared 90 degrees.
```

`/tmp/opencode/cw024-trial-01-prompt.txt` scene:

```text
Standing resistance-band pullover from overhead to hips, NOT lying and NOT a triceps extension. Fixed side three-quarter camera clearly revealing a HIGH stable anchor BEHIND the adult on a simple support post and TWO band branches to separate hand grips. Feet about hip width, knees relaxed, upright still torso. Left: arms raised upward and slightly in front of head, elbows slightly bent, band taut. Both branches pass OUTSIDE the silhouette from the high rear anchor to the hands, never through head or neck. Right: pull hands in an arc down beside hips, band more stretched, retaining the SAME slight elbow bend, stance and anchor. Movement is at shoulders, not bending and straightening elbows. No low or front anchor, torso lean, lumbar hyperextension, disconnected grips or band penetrating the body.
```

- [ ] Review prompt scene compliance first, then clarity and anatomical coherence. Verify fixed anchors, plausible branch routing and approved variants before paid requests. For subagent execution use independent reviewers in that order.

## Task 3: Generate and review cw019–cw021 sequentially

**Files:** temporary PNGs, previews and ledgers only. Use timeout at least 240 seconds per paid request. Never display credential-file contents or environment values.

- [ ] Verify the output directory is absent and issue `cw019` alone:

```bash
test ! -e /tmp/opencode/cw019-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw019-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw019-trial-01 --exercise-id cw019 --single-sunburst-medium
```

- [ ] Read its source PNG, then create and read the preview:

```bash
convert /tmp/opencode/cw019-trial-01/cw019-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw019-trial-01/review-512.png
```

Require lengthwise supported lying, one dumbbell, a coherent two-hand upper-head grip, shoulder-led arc behind head and unchanged slight elbow bend. Record an accepted path or named defect before the next paid request.

- [ ] After reviewing `cw019`, issue `cw020` alone:

```bash
test ! -e /tmp/opencode/cw020-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw020-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw020-trial-01 --exercise-id cw020 --single-sunburst-medium
```

- [ ] Read the original and create/read its preview:

```bash
convert /tmp/opencode/cw020-trial-01/cw020-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw020-trial-01/review-512.png
```

Require equal raised hip height, upper-back/head and flat-foot support, two independent dumbbell grips and low/high press distinction. Compare with accepted Part 07 `assets/exercises/cw014.webp`: bridge must be unmistakable rather than ordinary floor press.

- [ ] After reviewing `cw020`, issue `cw021` alone:

```bash
test ! -e /tmp/opencode/cw021-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw021-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw021-trial-01 --exercise-id cw021 --single-sunburst-medium
```

- [ ] Read the original and create/read its preview:

```bash
convert /tmp/opencode/cw021-trial-01/cw021-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw021-trial-01/review-512.png
```

Require rear chest-height anchor, two taut outside-body branches to independent hand grips, stable split stance and bent-to-straight press. In both source and preview trace anchor → branch → hand for each side in each phase. Natural occlusion is acceptable only when adjacent visible segments make the route unambiguous.

- [ ] Complete scene-compliance review then quality review, resolving issues before the next task. For subagent execution use separate reviewers.

## Task 4: Generate and review cw022–cw024 sequentially

**Files:** temporary PNGs, previews and ledgers only.

- [ ] Issue `cw022` alone:

```bash
test ! -e /tmp/opencode/cw022-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw022-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw022-trial-01 --exercise-id cw022 --single-sunburst-medium
```

- [ ] Read the original and create/read its preview:

```bash
convert /tmp/opencode/cw022-trial-01/cw022-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw022-trial-01/review-512.png
```

Require rear chest-height anchor, two continuous tensioned branches and unchanged soft elbow bend from wide opening to closure. Compare accepted `cw021` at 512px: flye must not look like a press. Trace both branch routes and check their grips in both phases.

- [ ] After reviewing `cw022`, issue `cw023` alone:

```bash
test ! -e /tmp/opencode/cw023-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw023-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw023-trial-01 --exercise-id cw023 --single-sunburst-medium
```

- [ ] Read the original and create/read its preview:

```bash
convert /tmp/opencode/cw023-trial-01/cw023-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw023-trial-01/review-512.png
```

Require palms trapping both band ends, middle over upper back below neck, no external anchor, stable straight body and lower press phase. Compare with published `assets/exercises/cw001.webp`; band route must be visible and meaningful at 512px, not just a stripe on clothing.

- [ ] After reviewing `cw023`, issue `cw024` alone:

```bash
test ! -e /tmp/opencode/cw024-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw024-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw024-trial-01 --exercise-id cw024 --single-sunburst-medium
```

- [ ] Read the original and create/read its preview:

```bash
convert /tmp/opencode/cw024-trial-01/cw024-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw024-trial-01/review-512.png
```

Require standing, high anchor behind the body, two taut outside-silhouette branches and overhead-to-hip shoulder-led movement with the same slight elbow bend. Trace both branches from rear anchor to each grip and reject any neck/head/torso penetration, anchor relocation or triceps-extension substitution.

- [ ] Complete independent scene-compliance review then quality review, including comparison and branch-route checks at full and final resolution. Resolve findings before integration.

### Correction procedure for Tasks 3 and 4

**Approved camera revision for cw022 and cw024:** After the initial reviews,
the user approved a slight change of camera angle and clearer separation of
hand grips in projection for these two exercises. Apply the same revised camera
to both panels of each image, retaining its anchor, posture, phase and soft
elbow bend. Show each branch ending on its own handle, with visible terminal
segments rather than a line entering a forearm. Use the latest rejected source
as the sole reference: `cw022-trial-03` and `cw024-trial-02`, respectively,
with fresh next-numbered prompt/output paths. Inspect both new images before
any further paid request and complete specification review before quality review.

Name the actual visible defect before correction. Create a fresh numbered prompt/output directory, keeping the actual exercise ID and `--single-sunburst-medium`. Use the immediately rejected PNG as the sole reference and correct only that defect while preserving accepted phases, equipment, camera and style. Verify the output directory is absent before requesting. Read the new source and 512px preview before another paid request. Maintain an explicit accepted-source list for all six IDs. For bands, distinguish natural occlusion from impossible routing; do not accept disconnected ends or body penetration. If successive corrections fail to remove the same defect, stop paid calls and ask to revise the scene. Never automatically repeat failed API requests or change approved `cw019`/`cw024` variants or anchor positions without agreement.

## Task 5: Integrate all approved assets and restore green

**Files:** six WebP assets; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm all six source paths passed both reviews and verify `assets/exercises/` exists. Convert accepted sources using `-resize 512x512 -strip -quality 90`. For accepted first trials, exact commands are:

```bash
convert /tmp/opencode/cw019-trial-01/cw019-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw019.webp
convert /tmp/opencode/cw020-trial-01/cw020-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw020.webp
convert /tmp/opencode/cw021-trial-01/cw021-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw021.webp
convert /tmp/opencode/cw022-trial-01/cw022-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw022.webp
convert /tmp/opencode/cw023-trial-01/cw023-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw023.webp
convert /tmp/opencode/cw024-trial-01/cw024-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw024.webp
```

If a correction was accepted, replace only its source path with the recorded accepted PNG. Never convert a rejected first trial merely because it appears in the example.

- [ ] Check final nonempty dimensions:

```bash
identify -format '%f %wx%h %b\n' assets/exercises/cw019.webp assets/exercises/cw020.webp assets/exercises/cw021.webp assets/exercises/cw022.webp assets/exercises/cw023.webp assets/exercises/cw024.webp
```

Expected: six nonempty 512×512 WebP files. Read final files to confirm two visual frames, supported variants and readable band routes survived conversion.

- [ ] Insert these entries after `cw018`, before `cw251`, in `illustratedExerciseIds`, preserving prior entries and mapping function:

```dart
  'cw019',
  'cw020',
  'cw021',
  'cw022',
  'cw023',
  'cw024',
```

- [ ] Run with timeout at least 1200 seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-08-verified .
```

Expected: generated version check succeeds, analysis has no findings, full suite passes, 90 files match the registry and expected IDs, each image decodes as 512×512, and fallback `cw025` remains correct. Visual frame count, anatomy and routing are review responsibilities. No host model regeneration or dependency/Web SQLite update is needed.

- [ ] Complete specification review then integration-quality review before marking the task done.

## Task 6: Update package status and perform final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Preserve production `1.9.0+22`, Part 07's unpublished status and all prior release/rollback evidence. Replace opening counts with:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 90 ilustracji:
78 wydanych oraz 12 lokalnie zintegrowanych, niewydanych z Partii 07 i 08.
226 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Insert these rows after `cw018`, before `cw251`, under the existing mixed published/local table heading:

```markdown
| cw019 | Przenoszenie hantla za głowę w leżeniu na ławce | 2 | Lokalnie zintegrowane; niewydane; leżenie wzdłuż ławki. |
| cw020 | Wyciskanie hantli w moście biodrowym | 2 | Lokalnie zintegrowane; niewydane. |
| cw021 | Wyciskanie gumy przed klatkę piersiową w staniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw022 | Rozpiętki z gumą w staniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw023 | Pompka z gumą na plecach | 2 | Lokalnie zintegrowane; niewydane. |
| cw024 | Ściąganie gumy znad głowy do bioder na prostych ramionach | 2 | Lokalnie zintegrowane; niewydane; wariant w staniu. |
```

- [ ] Add after Part 07 and before the general rules:

```markdown
## Ósma partia

Zakres ósmej partii obejmuje `cw019–cw024`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry i jest lokalnie zintegrowanych. `cw019` pokazuje
leżenie wzdłuż ławki z jednym hantlem, a `cw024` wariant w staniu z wysoką
tylną kotwą. Przebieg gum i chwyty zweryfikowano w docelowym rozmiarze.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów. Pakiet nie
jest jeszcze wydany; wersja produkcyjna pozostaje `1.9.0+22`.
```

- [ ] Run `git diff --check`, inspect `git status --short` and `git diff`, and require only intended Part 08 additions on top of preserved Part 07 work.
- [ ] Perform final specification and quality review of all six final files, mapping/test and status. Confirm 90 local vs 78 published, 12 unpublished, 226 missing, two frames per new file, correct dumbbell counts and complete band routes.
- [ ] Report accepted source paths, verification results, paid-request count and ledger-estimated costs, plus any unresolved findings. Stop at a prepared package; release metadata, deployment, commit and push are separate user decisions.

## Plan self-review

- Coverage: Task 2 defines all six approved variants, exact cameras and equipment connections; Tasks 3/4 inspect each source/preview sequentially and compare related exercises.
- Band contract: rear chest-height anchors for `cw021/022`, no external anchor for `cw023`, high rear anchor and standing for `cw024`; all branches and grips reviewed at 512px.
- Integration: Task 5 adds all accepted assets together, preserves the previous 84, and restores the automated exact-set/decoding contracts.
- Fallback/order: new IDs follow `cw018`; the absent-asset case moves to `cw025`.
- Counts and boundaries: 90 local = 78 published + 12 unpublished, 226 missing, 316 catalog records. Part 07 work and production 1.9.0+22 remain preserved; no automatic Git or deployment actions.
