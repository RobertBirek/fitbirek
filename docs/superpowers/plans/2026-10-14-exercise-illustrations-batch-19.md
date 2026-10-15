# Exercise Illustrations Batch 19 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate cw085–cw090, five new illustrations plus approved reuse of cw055 as cw086.

**Architecture:** Red exact asset contract, five individually reviewed sources and one verified copy, then whole-package integration/green verification. Preserve prior unpublished work. Reviews direct because subagent quota was exhausted during Part18; do not claim independent review.

**Tech Stack:** Sunburst medium via `tools/benchmark_exercise_images.py`, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec: `docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-19-design.md`.
Read AGENTS.md,docs/modules/training.md,assets/data/exercises.json.
Current `/opt/fit` main/no worktree, preserve Parts07–18 and other work.
Baseline150/78/72/166/316; target156local/78published/78unpublished/160missing/316.
Production1.9.0+22, no version/commit/push/deployment without separate request.

- Create assets/exercises/cw085.webp throughcw090.webp.
- Modify test/features/exercises/exercise_illustrations_test.dart,
  lib/features/exercises/presentation/exercise_illustrations.dart,
  docs/exercise-illustrations-status.md; execution record here/in spec.
- Temporary sources/prompts/previews/ledgers in `/tmp/opencode/cw085-*`,
  cw087-* throughcw090-*; NO generation for cw086.

## Task1: Red contract

- [ ] Inspect status/scoped diff before editing, preserve prior work.
- [ ] Add aftercw084 beforecw251 in test expectedIllustrationIds:

```dart
    'cw085',
    'cw086',
    'cw087',
    'cw088',
    'cw089',
    'cw090',
```

- [ ] Change absence assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw091'), isNull);
  });
```

- [ ] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-19-red .
```

Expected missingcw085 registry failure only, other tests/version/analysis pass.

## Task2: Prompts and reuse review

- [ ] Read cw055.WebP and confirm cw086 unanchored straight-arm pull-apart
  technique; read cw256referencePNG, verify dimensions with identify.
- [ ] Write FIVE separate cwNNN-trial-01-prompt.txt under /tmp/opencode,
  approved spec common block+respective scenes in “Prompty i kontrakt reuse”.
  No cw086 paid prompt. Direct spec review then clarity/geometry review.
- [ ] Check eye-height cw085 anchor, rightarm and correct opposite anchor
  sides087/088, towel087,90degreefixedelbows,4Cuban stages and leftside/rightarm090.

## Task3: Generate cw085,cw087,cw088 sequentially

Fresh exclusive output paths, verifyparentexists, timeout>=240seconds each.
No secrets/rawpayload logging. Read source and512preview before another call,
spec then quality; no automatic retry after provider error/uncertainty.

- [ ] cw085:

```bash
test ! -e /tmp/opencode/cw085-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw085-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw085-trial-01 --exercise-id cw085 --single-sunburst-medium
convert /tmp/opencode/cw085-trial-01/cw085-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw085-trial-01/review-512.png
```

- [ ] Review eyeheightfrontanchor,2tautbranches/connectedseparategrips,
  longarms→facepull, elbowsabove wrists, no shrug/overheadanchor.
  Foreground overlay alone is not penetration; trace actual route.
- [ ] cw087:

```bash
test ! -e /tmp/opencode/cw087-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw087-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw087-trial-01 --exercise-id cw087 --single-sunburst-medium
convert /tmp/opencode/cw087-trial-01/cw087-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw087-trial-01/review-512.png
```

- [ ] Review anatomicalLEFTanchor/RIGHThand, towelatfixedelbow90,
  abdomen→outward forearm rotation notelbowcurl/extension/bodytwist.
- [ ] cw088:

```bash
test ! -e /tmp/opencode/cw088-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw088-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw088-trial-01 --exercise-id cw088 --single-sunburst-medium
convert /tmp/opencode/cw088-trial-01/cw088-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw088-trial-01/review-512.png
```

- [ ] Review anatomicalRIGHTanchor/RIGHThand, fixedelbow90,
  outward→abdomen rotation; sameemptyLEFThand/feet/torso, band routecontinuous.

## Task4: Generate cw089,cw090 sequentially

- [ ] cw089:

```bash
test ! -e /tmp/opencode/cw089-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw089-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw089-trial-01 --exercise-id cw089 --single-sunburst-medium
convert /tmp/opencode/cw089-trial-01/cw089-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw089-trial-01/review-512.png
```

- [ ] Review4panels2x2 in order TL→TR→BL→BR,2connectedDB each,
  thighs→high elbows withweightsbelow→forearmsUP vertical/elbows90→press.
  No skippedstages, wristtwist, changingcamera/scale/feet or clipping.
- [ ] cw090:

```bash
test ! -e /tmp/opencode/cw090-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw090-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw090-trial-01 --exercise-id cw090 --single-sunburst-medium
convert /tmp/opencode/cw090-trial-01/cw090-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw090-trial-01/review-512.png
```

- [ ] Review2horizontalrows, LEFTside/rightupperarm1DB,loweremptyarmsupporthead,
  fixedupperarm/elbow90, forearmabdomen→up, notcurl/row/elbowlift/bodyroll.

### Corrections

Name actual defect, fresh prompt/output, ONLY last rejectedPNG as reference,
preserveacceptedparts; readsource/preview before nextcall. After2failed
corrections ofsameissue stop/evaluate materiallynewcomposition beforepaid
continuation. Providererror:retainledger/path,no automaticretry,unknowncost
notfree. Recordactualacceptedpaths/directreview, no independentreviewclaims.

## Task5: Integrate all six, including copy, restore green

- [ ] After all5accepted and reuse review, confirm destination and sources.
  Initial paths below ONLY ifaccepted; replace rejected paths with actual
  accepted corrections. For cw086 copy original unchanged:

```bash
convert /tmp/opencode/cw085-trial-01/cw085-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw085.webp
cp assets/exercises/cw055.webp assets/exercises/cw086.webp
cmp assets/exercises/cw055.webp assets/exercises/cw086.webp
convert /tmp/opencode/cw087-trial-01/cw087-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw087.webp
convert /tmp/opencode/cw088-trial-01/cw088-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw088.webp
convert /tmp/opencode/cw089-trial-01/cw089-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw089.webp
convert /tmp/opencode/cw090-trial-01/cw090-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw090.webp
identify -format '%f %m %wx%h %b\n' assets/exercises/cw085.webp assets/exercises/cw086.webp assets/exercises/cw087.webp assets/exercises/cw088.webp assets/exercises/cw089.webp assets/exercises/cw090.webp
```

- [ ] Read all6WebP, nonempty512×512,frames2/2/2/2/4/2; copyidenticalbytes.
- [ ] Add aftercw084 beforecw251 in illustratedExerciseIds:

```dart
  'cw085',
  'cw086',
  'cw087',
  'cw088',
  'cw089',
  'cw090',
```

- [ ] Timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-19-verified .
docker run --rm fit-web:batch-19-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expectedfullsuite/version/analysisgreen,156exactfiles/IDs,512decode,
fallbackcw091,formatting0changes.No catalog/model/dependency/WebSQLitechanges.

## Task6: Status and closing review

- [ ] Preserve earlier history; current counters:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 156 ilustracji:
78 wydanych oraz 78 lokalnie zintegrowanych, niewydanych z Partii 07–19.
160 ćwiczeń pozostaje bez ilustracji.
```

- [ ] Addrows85..90after84before251:

```markdown
| cw085 | Face pull z gumą | 2 | Lokalnie zintegrowane; niewydane; przednia kotwa na poziomie oczu. |
| cw086 | Rozciąganie gumy przed klatką piersiową | 2 | Lokalnie zintegrowane; niewydane; kopia grafiki cw055, bez nowej generacji. |
| cw087 | Rotacja zewnętrzna ramienia z gumą | 2 | Lokalnie zintegrowane; niewydane; prawa ręka, lewa kotwa, ręcznik przy łokciu. |
| cw088 | Rotacja wewnętrzna ramienia z gumą | 2 | Lokalnie zintegrowane; niewydane; prawa ręka, prawa kotwa. |
| cw089 | Wyciskanie kubańskie z hantlami | 4 | Lokalnie zintegrowane; niewydane; cztery fazy w siatce 2×2. |
| cw090 | Rotacja zewnętrzna ramienia z hantlem w leżeniu bokiem | 2 | Lokalnie zintegrowane; niewydane; lewy bok, prawa ręka robocza. |
```

- [ ] Add“Dziewiętnasta partia” beforegeneralrules:actualsources/reviews/corrections,
  reuse86zerorequests,successonlyuniqueledgercost/unknownerrorsseparate,
  greenlog,156/78/78/160/316,production1.9.0+22. Execution record here/in spec.
- [ ] Directfinal6asset/integrationreview, readledgersdeduprequest_id,
  git diff --check/scopedstatus,recordquota/directreviewhonestly.
  Noautomaticversion/Git/deploymentoperations.

## Self-review

All5prompts/calls/previews+reusecontractcovered,elbow/anchor/gripchecks,
Cuban4phases/side-lyingupperarmexplicit.Tasks1/5red-green,Task6correct
accounting/earlierworkpreservation/nohiddenreusegenerationcost.

## Execution record — 2026-10-14

- [x] Task1: red missingcw085 only,365 other tests passed, analysis clean.
- [x] Task2: five exact prompts and reuse contract reviewed directly; no independent review after prior quota exhaustion.
- [x] Task3: cw085 corrected elbows twice, cw087/cw088 anchor sides and forearm/grip once each; accepted source+512preview after spec then quality checks.
- [x] Task4: cw089 third phase corrected to shoulder-level humeri, cw090 initial accepted; full source/preview inspection.
- [x] Task5: five newWebP plus identical cw055→cw086copy,cmp passed,all512×512,156exactfiles/IDs,fallbackcw091;Docker366tests passed,analysisclean,format0changes.
- [x] Task6: documentation, direct final6asset review and10successledgers complete; closingdiff/status/copyidentity checks passed, public production version1.9.0+22 andhealthok confirmed.

Accepted sources under `/tmp/opencode`:

| ID | Directory/source | Frames |
|---|---|---:|
| cw085 | cw085-correction-02 | 2 |
| cw086 | assets/exercises/cw055.webp copied unchanged | 2 |
| cw087 | cw087-correction-01 | 2 |
| cw088 | cw088-correction-01 | 2 |
| cw089 | cw089-correction-01 | 4 in2×2 |
| cw090 | cw090-trial-01 | 2 horizontal rows |

New-source filename `cwNNN-gpt-image-2.5-sunburst-medium.png` in listed
directory. Five initial requests+five corrections=10unique successes,
upper-bound estimate0.226785USD,0HTTPerrors. Success records only counted;
all10 request_id distinct, response_received not counted again. Reuse86
adds0paidcalls; cmp confirms copiedbytes and original preserved.
All reviews direct, not independent. Catalog/version/dependencies untouched.
Greenlog:`/root/.local/share/opencode/tool-output/tool_13b4d8a53001vs0tOI2IEYoX57`.
Current156/78/78/160/316,production1.9.0+22,no version/Git/deploymentoperations.
