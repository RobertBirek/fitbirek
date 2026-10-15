# Exercise Illustrations Batch 09 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, independently review and locally integrate six catalog-faithful exercise illustrations for `cw025–cw030`.

**Architecture:** Generate one 1024×1024 PNG at a time, inspect its source and 512×512 preview before another paid call, and integrate all six accepted sources together. Extend the existing exact-set/decoding test and registry, preserving unpublished Parts 07/08. Five assets have two side-by-side frames; `cw030` has three full-width horizontal rows stacked vertically.

**Tech Stack:** OpenAI Sunburst medium through `tools/benchmark_exercise_images.py`, ImageMagick 6 `convert`/`identify`, Flutter 3.35.4 and Dart 3.9.2 through Docker verification.

---

## Context and file map

- Read `AGENTS.md`, `docs/modules/training.md`, `assets/data/exercises.json:823–1032`, and `docs/superpowers/specs/2026-10-13-exercise-illustrations-batch-09-design.md`.
- Work in `/opt/fit`, preserving all pre-existing uncommitted work, particularly Parts 07 and 08. User has requested continuation using the same subagent workflow without repetitive approval pauses.
- Create only during implementation: `assets/exercises/cw025.webp`, `cw026.webp`, `cw027.webp`, `cw028.webp`, `cw029.webp`, `cw030.webp`.
- Modify during implementation: `test/features/exercises/exercise_illustrations_test.dart` (expected IDs and fallback), `lib/features/exercises/presentation/exercise_illustrations.dart` (registry), `docs/exercise-illustrations-status.md` (counts, table, history).
- Temporary prompts, sources, previews, acceptance records and API ledgers: `/tmp/opencode/cw025-*` through `/tmp/opencode/cw030-*`.
- Style reference: `assets/exercises/cw256.webp`; first-request reference: `/tmp/opencode/cw256-reference.png`.
- Baseline: 90 local = 78 published + 12 unpublished, 226 missing, 316 records. Final: 96 local = 78 published + 18 unpublished, 220 missing, 316 records.
- Production remains `1.9.0+22`. No automatic commits, push, version bump or deployment. The verification build is not a release build.

## Task 1: Establish the red registry contract

**File:** `test/features/exercises/exercise_illustrations_test.dart`.

- [ ] Inspect starting changes and retain them as the baseline:

```bash
git status --short
git diff
```

- [ ] Through `apply_patch`, insert after `cw024`, before `cw251`, in `expectedIllustrationIds`, preserving all previous 90 entries:

```dart
    'cw025',
    'cw026',
    'cw027',
    'cw028',
    'cw029',
    'cw030',
```

- [ ] Replace the existing absent-asset assertion with:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw031'), isNull);
  });
```

- [ ] Run from `/opt/fit` with tool timeout at least 1200000 ms:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-09-red .
```

Expected: registry equality fails because `cw025–cw030` are absent, beginning with missing `cw025`; fallback `cw031` passes. Investigate unrelated failures before any paid call. Do not extend the production registry or create WebPs yet.

## Task 2: Prepare and independently review exact prompts

**Files:** `/tmp/opencode/cw025-trial-01-prompt.txt` through `/tmp/opencode/cw030-trial-01-prompt.txt`.

- [ ] Read `assets/exercises/cw256.webp` and existing `/tmp/opencode/cw256-reference.png` using the image-reading tool. If the PNG is absent, verify `/tmp/opencode` exists and create it:

```bash
ls /tmp/opencode
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
identify /tmp/opencode/cw256-reference.png
```

Expected: PNG matches the reference WebP. Do not overwrite an existing unrelated reference.

- [ ] Use `apply_patch` to write each prompt as the common paragraph, its layout paragraph, then its exact scene paragraph below. Each resulting file is the complete English prompt passed to the script.

Common paragraph for **all six**:

```text
Use supplied image only as style reference. Clean 2D fitness art, cream background, dark comic outlines, faceless adult in dark neutral clothes matching the reference. Square 1024x1024. Same adult, fixed camera, scale and equipment across all frames. Entire body and all essential equipment fit in every frame with generous margins. Make hands, fingers, feet and support contacts readable after reduction to 512x512. Natural spatial perspective and occlusion, coherent anatomy with five fingers per hand, no transparent anatomy, collisions, duplicated or missing limbs. No text, numbers, timers, labels, arrows, watermark, motion ghosts or multiple silhouettes within one frame. No required colored muscle overlays. Stable body mechanics and anatomically plausible joints.
```

Layout paragraph for `cw025–cw029`:

```text
EXACTLY TWO separated side-by-side panels, read left to right. Left shows the upper phase; right shows the lower phase. Maintain the same camera and support arrangement in both panels.
```

Layout paragraph for `cw030` **instead of** the two-panel paragraph:

```text
EXACTLY THREE full-width HORIZONTAL ROWS STACKED VERTICALLY, read TOP TO BOTTOM, not three narrow columns. Each row contains one complete body. Use the SAME slightly elevated front-side three-quarter camera and framing in all three rows. A faint straight floor seam stays in exactly the SAME image position in all three rows as a stationary ground reference; do not move the camera or seam with the adult.
```

`/tmp/opencode/cw025-trial-01-prompt.txt` scene:

```text
Bench chest dip between TWO stable flat benches, fixed side three-quarter view clearly showing both hand and heel contacts. BOTH hands grip the near edge of ONE flat bench BEHIND the hips. BOTH straight legs extend forward with BOTH heels supported on a SECOND stable flat bench IN FRONT. Both benches are fully visible, separate and grounded. Buttocks remain suspended off the rear bench. Left: arms straight, body supported by hands and heels, torso near upright with a small support-induced backward inclination permitted. Right: lower the suspended body with elbows bent roughly 90 degrees and a clear forward torso tilt for chest bias, retaining identical hand and heel contacts; shoulders stay down, with no forced excessively deep shoulder position. Forward tilt belongs to the descent, not necessarily the straight-arm upper support. No feet on the floor, bent-knee regression, parallel bars, seated buttocks, floating heels, shoulder shrug or impossible arm/bench intersection.
```

`/tmp/opencode/cw026-trial-01-prompt.txt` scene:

```text
Pseudo planche push-up on the FLOOR, not a full airborne planche. Fixed side three-quarter view revealing hand position and forward lean. BOTH palms are near the HIPS, fingers turned OUTWARDS to the sides, not forced backwards. Shoulders are clearly AHEAD OF the hands in both panels, with a pronounced forward lean and protracted upper back. BOTH sets of toes remain on the floor and the body stays in a stable straight line. Left: straight arms in the forward-leaning upper support. Right: bent elbows and lowered chest while preserving the SAME forward lean, outward hand orientation and toe support. No ordinary hands-under-shoulders push-up, airborne feet, collapsed shoulder blades, sagging hips or extreme wrist contortion.
```

`/tmp/opencode/cw027-trial-01-prompt.txt` scene:

```text
Fingertip push-up with support on the PADS of ALL FIVE widely spread fingers of EACH hand. Fixed LOW front-side three-quarter camera showing the finger-pad floor contacts and the clear gap beneath both PALMS. Five anatomically coherent fingers per hand; natural partial perspective occlusion is allowed, but no missing or fused fingers. Fingers form plausible strong support, not a tightly curled nail-supported claw. Left: upper push-up support, straight arms, toes on floor and straight head-to-heel body line. Right: chest lowered close to floor, elbows about 45 degrees from torso, SAME fingertip-pad contacts and lifted palms, stable body line and grounded toes. Entire body must remain visible; do not replace the scene with a hand close-up. No flat palms, knuckles, nail support, four-finger progression, kneeling regression, hyperbent fingers or dropped hips.
```

`/tmp/opencode/cw028-trial-01-prompt.txt` scene:

```text
Archer DECLINE push-up with BOTH feet supported on ONE LOW stable bench about 30-50 cm high and BOTH palms on the FLOOR in a wide stance. Fixed slightly elevated front-side three-quarter view showing the full bench, raised feet, both arms and lateral load shift. Left: symmetrical wide upper support, both arms straight. Right: shift chest and weight toward ONE working arm with its elbow bent, while the OTHER assisting arm stays straight out to the side and its palm stays on the floor. Keep the same working-side identity, toe support and hand positions; pelvis remains square with no twisting and torso stays controlled. No feet on floor, both elbows bent like an ordinary decline push-up, lifted assisting hand, very high bench, rotated hips or bent assisting arm.
```

`/tmp/opencode/cw029-trial-01-prompt.txt` scene:

```text
Paused push-up shown as an upper support and a controlled LOWER HOLD. Fixed low side three-quarter view making the chest-to-floor clearance visible. Left: high plank with straight arms, both palms and toes on floor, body in a straight line. Right: HOLD the chest hovering about 2 cm ABOVE the floor, elbows about 45 degrees from torso, shoulders controlled and whole body tension maintained. Chest does NOT touch the ground; hips neither sag nor pike. Same hands, toes, camera and body alignment. A still image cannot encode a three-second duration: do not add a timer, text, clock, repeated lower phase or artificial visual distinction from a regular push-up. No bouncing, floor contact, wide 90-degree elbow flare or loss of tension.
```

`/tmp/opencode/cw030-trial-01-prompt.txt` scene:

```text
Side-to-side PLYOMETRIC push-up, travelling laterally from LEFT to RIGHT relative to the FIXED floor seam. TOP row: low starting push-up at the LEFT ground position, both palms grounded, elbows bent, toes on floor and stable straight body. MIDDLE row: explosive sideways transfer of the upper body, BOTH hands visibly CLEAR OF THE FLOOR with clear air gaps; toes retain floor contact as a pivot, torso remains braced and the hand/shoulder position is between the left start and right landing. BOTTOM row: land at the RIGHT ground position, both palms grounded and elbows BENT for a soft controlled landing, stable torso and straight body line. The same toe pivot and stationary seam make the lateral hand and upper-body displacement unmistakable. Whole body in every row, exactly one adult per row. No purely vertical jump, clap, hands on floor in the airborne middle phase, straight-elbow landing, torso collapse, moving camera, motion arrows or duplicate ghost bodies.
```

- [ ] Independently review prompt compliance first, then quality/readability. Verify catalog-supported assumptions: two benches for `cw025`, outward fingers for `cw026`, five finger pads for `cw027`, low bench for `cw028`, duration only in catalog for `cw029`, toe-pivot lateral flight for `cw030`. Resolve findings within these chosen variants without repetitive approval requests.

## Task 3: Generate and review cw025–cw027 sequentially

**Files:** temporary source PNGs, previews, ledgers and acceptance record only. Tool timeout at least 240000 ms per paid request. Never print credential contents or environment values. Verify `/tmp/opencode` exists before requests; the script exclusively creates each fresh output directory.

- [ ] Issue `cw025` alone:

```bash
test ! -e /tmp/opencode/cw025-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw025-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw025-trial-01 --exercise-id cw025 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw025-trial-01/cw025-gpt-image-2.5-sunburst-medium.png`, create then read its preview:

```bash
convert /tmp/opencode/cw025-trial-01/cw025-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw025-trial-01/review-512.png
```

Require exactly two side-by-side phases, fully visible two benches, hands behind hips on one bench, straight-leg heels on the other, suspended buttocks, upper straight arms with a near-upright torso, lower approximately 90° elbows with clear forward tilt, and no shoulder hike or extreme depth. This clarified phase distinction preserves the selected two-bench variant and reflects the geometry review of cw025-trial-02. Complete independent scene then quality review and record accepted path or named defect **before the next paid call**.

- [ ] Issue `cw026` alone after reviewing the previous result:

```bash
test ! -e /tmp/opencode/cw026-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw026-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw026-trial-01 --exercise-id cw026 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw026-trial-01/cw026-gpt-image-2.5-sunburst-medium.png`, create then read its preview:

```bash
convert /tmp/opencode/cw026-trial-01/cw026-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw026-trial-01/review-512.png
```

Require hands near hips, fingers outward, shoulders clearly forward of hands, protracted upper back, constant lean and toe support in both upper/lower phases. Compare `assets/exercises/cw001.webp` at 512px: the pseudo-planche geometry must be evident. Complete independent scene then quality review and record acceptance or defect before another paid call.

- [ ] Issue `cw027` alone:

```bash
test ! -e /tmp/opencode/cw027-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw027-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw027-trial-01 --exercise-id cw027 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw027-trial-01/cw027-gpt-image-2.5-sunburst-medium.png`, create then read its preview:

```bash
convert /tmp/opencode/cw027-trial-01/cw027-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw027-trial-01/review-512.png
```

Require five anatomically coherent spread fingers per hand, pad support, lifted palms, two whole-body phases, grounded toes, stable line and roughly 45° low-phase elbows. Inspect both hands in both phases at source resolution, then check that support remains visible at 512px. Natural occlusion is acceptable, missing/fused digits or nail support are not. Complete independent compliance then quality review before proceeding.

## Task 4: Generate and review cw028–cw030 sequentially

**Files:** temporary PNGs, previews, ledgers and acceptance record only. Same timeout and credential handling as Task 3.

- [ ] Issue `cw028` alone:

```bash
test ! -e /tmp/opencode/cw028-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw028-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw028-trial-01 --exercise-id cw028 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw028-trial-01/cw028-gpt-image-2.5-sunburst-medium.png`, create then read its preview:

```bash
convert /tmp/opencode/cw028-trial-01/cw028-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw028-trial-01/review-512.png
```

Require low stable bench supporting both feet, palms on floor, upper symmetrical wide straight arms, lower one bent working arm/one straight assisting arm, no hip twist. Compare `assets/exercises/cw004.webp` (feet on floor) and `assets/exercises/cw009.webp` (both elbows bend): accepted `cw028` must combine archer asymmetry with decline support. Independently review compliance then quality before the next paid call.

- [ ] Issue `cw029` alone:

```bash
test ! -e /tmp/opencode/cw029-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw029-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw029-trial-01 --exercise-id cw029 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw029-trial-01/cw029-gpt-image-2.5-sunburst-medium.png`, create then read its preview:

```bash
convert /tmp/opencode/cw029-trial-01/cw029-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw029-trial-01/review-512.png
```

Require high plank and low hold approximately 2 cm above floor, roughly 45° elbows, stable line and no chest contact/bounce. Compare `assets/exercises/cw001.webp` for technique without demanding an invented visual distinction. Three-second duration stays in existing catalog text, never in an overlay. Independently review compliance then quality before the next paid call.

- [ ] Issue `cw030` alone:

```bash
test ! -e /tmp/opencode/cw030-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw030-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw030-trial-01 --exercise-id cw030 --single-sunburst-medium
```

- [ ] Read `/tmp/opencode/cw030-trial-01/cw030-gpt-image-2.5-sunburst-medium.png`, create then read its preview:

```bash
convert /tmp/opencode/cw030-trial-01/cw030-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw030-trial-01/review-512.png
```

Require exactly three full-width stacked rows, identical camera/seam, left low start, lateral airborne middle with both hands clearly off floor and toes as pivot, right landing with bent elbows. Compare `assets/exercises/cw006.webp`: no clap or purely vertical flight. Check the seam stays fixed and the hand/shoulder positions genuinely move sideways at both resolutions. Complete independent scene then quality review before acceptance.

### Correction procedure for Tasks 3 and 4

**Bounded new approach after initial blockers:** Reviews of `cw027-trial-03`
and `cw030-correction-02` identified an actual missing far-hand digit and a
reversal of body orientation, respectively. The initial correction series
stopped. Within the user's request to finish and continue, use one new attempt
per ID with a materially revised camera: a low, more frontal view of both
five-finger hands for cw027; an exactly frontal, slightly elevated fixed view
for cw030 with the adult facing the viewer in every row. Preserve all exercise
variants, phases, equipment and style, using the last rejected PNG as the sole
reference. Toe support/pivot must be physically coherent, without artificial
identical x-coordinate requirements. If either new attempt still fails, stop
that ID and report the unresolved blocker; do not start another paid loop.
The frontal cw030-correction-03 resolved the original camera/orientation
defect; review identified a new, localized middle-row leg/boot geometry issue.
Allow one defect-only middle-row repair using correction-03 as sole reference,
preserving the accepted camera, start, landing and lateral displacement.
Stop cw030 if this repair does not pass; no further automatic requests.

- [ ] Record the actual visible defect, rejected source path, review findings and attempt number through the file-editing tool. Use `/tmp/opencode/cwNNN-acceptance.md` per exercise; include the accepted source path only after both reviews pass.
- [ ] Create a fresh next-numbered prompt and output directory. Correct **only** the named defect, preserving accepted camera, phases, equipment, style and support contacts. Use the immediately rejected PNG as the **sole** reference. Do not use the original style PNG as a second reference.

Concrete second-trial example if `cw027` has flat palms (use this only for that observed defect): write `/tmp/opencode/cw027-trial-02-prompt.txt` with:

```text
Edit the supplied rejected fingertip push-up illustration only to correct its flat-palm support. In BOTH panels lift BOTH palms visibly above the floor and place support on the PADS of ALL FIVE spread, anatomically coherent fingers of EACH hand, not nails or knuckles. Preserve the existing two side-by-side upper/lower whole-body phases, low front-side three-quarter camera, adult, cream/dark style, grounded toes and stable body line. Natural finger occlusion is allowed but no missing or fused fingers. Do not add text, arrows, timers, extra figures or equipment. Square 1024x1024, support readable at 512x512.
```

```bash
test ! -e /tmp/opencode/cw027-trial-02 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw027-trial-02-prompt.txt --reference /tmp/opencode/cw027-trial-01/cw027-gpt-image-2.5-sunburst-medium.png --output-dir /tmp/opencode/cw027-trial-02 --exercise-id cw027 --single-sunburst-medium
convert /tmp/opencode/cw027-trial-02/cw027-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw027-trial-02/review-512.png
```

- [ ] Read the new source and preview before another request and repeat independent compliance then quality review. Adapt only the actual ID, fresh attempt number, immediately rejected path and defect-specific edit for other observed failures.
- [ ] If two consecutive corrections still fail the same defect, stop paid calls and report the blocker. Do not automatically retry API errors or reuse claimed directories; an uncertain request may already be billable. Maintain a six-ID accepted-source list and all ledgers. No integration until all six pass.

## Task 5: Integrate all six accepted assets and restore green

**Files:** `assets/exercises/cw025.webp` through `cw030.webp`; `lib/features/exercises/presentation/exercise_illustrations.dart`.

- [ ] Confirm six accepted source paths with both reviews, inspect starting status for new work, and verify destination exists:

```bash
ls assets/exercises
git status --short
```

- [ ] Convert only accepted sources. If all first trials passed, exact commands are:

```bash
convert /tmp/opencode/cw025-trial-01/cw025-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw025.webp
convert /tmp/opencode/cw026-trial-01/cw026-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw026.webp
convert /tmp/opencode/cw027-trial-01/cw027-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw027.webp
convert /tmp/opencode/cw028-trial-01/cw028-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw028.webp
convert /tmp/opencode/cw029-trial-01/cw029-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw029.webp
convert /tmp/opencode/cw030-trial-01/cw030-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw030.webp
```

For corrected exercises substitute its recorded accepted PNG path only; never convert a rejected source merely because it appears above. Issue these as separate tool commands, not a paid generation loop.

- [ ] Verify output formats and dimensions:

```bash
identify -format '%f %m %wx%h %b\n' assets/exercises/cw025.webp assets/exercises/cw026.webp assets/exercises/cw027.webp assets/exercises/cw028.webp assets/exercises/cw029.webp assets/exercises/cw030.webp
```

Expected: six nonempty WEBP 512×512 files. Read all final WebPs; require frame counts `2/2/2/2/2/3` and retained contacts/flight clearances.

- [ ] Through `apply_patch`, insert after `cw024`, before `cw251`, in `illustratedExerciseIds`, preserving the previous 90 IDs and mapping function:

```dart
  'cw025',
  'cw026',
  'cw027',
  'cw028',
  'cw029',
  'cw030',
```

- [ ] Run with timeout at least 1200000 ms:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-09-verified .
```

Expected: generated-version check passes, Flutter analysis reports no findings, full Flutter suite passes, the 96 files match registry and expected IDs exactly, every image decodes as 512×512 and `cw031` fallback passes. The target already runs the full analysis/test commands; do not claim green from an image-only check. Docker regenerates models inside its build; no host model/dependency/Web SQLite edits are needed.

- [ ] Complete independent specification review then integration-quality review. Automated tests do not verify anatomical detail, visual frame count or lateral displacement; those require the completed image reviews.

## Task 6: Update status and final review

**File:** `docs/exercise-illustrations-status.md`.

- [ ] Replace opening counts only, preserving production version and release evidence:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 96 ilustracji:
78 wydanych oraz 18 lokalnie zintegrowanych, niewydanych z Partii 07, 08 i 09.
220 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Add after `cw024`, before `cw251`, in the existing table:

```markdown
| cw025 | Pompki między krzesłami lub na ławce (na klatkę piersiową) | 2 | Lokalnie zintegrowane; niewydane; dłonie i pięty na dwóch ławkach. |
| cw026 | Pompki z dłońmi przy biodrach i pochyleniem w przód | 2 | Lokalnie zintegrowane; niewydane; palce dłoni na zewnątrz. |
| cw027 | Pompki na palcach | 2 | Lokalnie zintegrowane; niewydane; podpór na opuszkach pięciu palców każdej dłoni. |
| cw028 | Pompki łucznika z nogami na ławce | 2 | Lokalnie zintegrowane; niewydane. |
| cw029 | Pompki z pauzą | 2 | Lokalnie zintegrowane; niewydane; czas pauzy określa katalog. |
| cw030 | Pompki eksplozywne z przeskokiem w bok | 3 | Lokalnie zintegrowane; niewydane; trzy poziome pasy od góry do dołu. |
```

- [ ] After „Ósma partia”, before general rules, add the following **only after verification succeeds**:

```markdown
## Dziewiąta partia

Zakres dziewiątej partii obejmuje `cw025–cw030`. Wszystkie sześć zatwierdzonych
WebP 512×512 jest lokalnie zintegrowanych. `cw025–cw029` mają po dwa kadry
obok siebie; `cw030` ma trzy poziome pasy pełnej szerokości ułożone pionowo,
od góry do dołu: niski start po lewej, boczny lot dłoni z podporowymi palcami
stóp, lądowanie po prawej na ugiętych łokciach. Stała kamera i punkt odniesienia
podłogi pozwalają porównać przemieszczenie.
`cw025` wykorzystuje dwie ławki, `cw026` palce dłoni skierowane na zewnątrz,
a `cw027` podpór na opuszkach wszystkich pięciu palców każdej dłoni.
`cw028` łączy podporowe stopy na niskiej ławce z asymetrią łucznika.
`cw029` pokazuje zatrzymanie klatki około 2 cm nad podłogą; trzysekundowy
czas pauzy opisuje istniejący katalog, nie statyczna ilustracja.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów. Pakiet nie jest
jeszcze wydany; wersja produkcyjna pozostaje `1.9.0+22`. Partie 07, 08 i 09
obejmują łącznie 18 lokalnie zintegrowanych, niewydanych ilustracji.
```

- [ ] Verify final diff and whitespace:

```bash
git diff --check
git status --short
git diff
```

Expected: no whitespace errors; only intended Part 09 additions on top of preserved starting Part 07/08 changes. Check all six new files explicitly because untracked images do not appear in `git diff`.

- [ ] Perform final independent specification and quality review of six WebPs, mapping, test and status. Confirm exactly 96 local, 78 published, 18 unpublished, 220 missing, 316 records; fallback `cw031`; correct order; retained Part 07/08 history; no changed production/version/deployment files.
- [ ] Report created assets, accepted source paths, source/preview/final reviews, Docker result, paid-request count, ledger-estimated costs and any unresolved issue. Distinguish unknown costs from estimates when the API ledger lacks usage. Finish at a locally prepared package without automatic Git or release operations.

## Plan self-review

- Spec coverage: Task 2 contains full common/layout/scene prompts for all six selected variants; Tasks 3/4 inspect source and preview sequentially with per-ID criteria and comparisons.
- Anatomy and contacts: two benches, outward fingers and grounded toes, five-pad support, low-bench archer asymmetry, low paused clearance and toe-pivot lateral flight all have explicit acceptance checks.
- Layout: exactly two side-by-side frames for `cw025–cw029`, exactly three stacked full-width rows for `cw030`; timing remains catalog-only.
- Spend control: single medium `n=1`, fresh directories, named-defect corrections with rejected PNG as sole reference, two-successive-correction stop, independent review before acceptance.
- Integration: Task 1 establishes red; Task 5 integrates all accepted sources, preserves previous 90 and verifies the full suite; Task 6 updates counts/history only after green.
- Boundaries: production `1.9.0+22`, pre-existing Part 07/08 work and prior release evidence preserved; no automatic commits, push or deployment.
