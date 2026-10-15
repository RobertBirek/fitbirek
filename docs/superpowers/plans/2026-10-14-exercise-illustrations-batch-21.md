# Exercise Illustrations Batch 21 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved cw097–cw102 illustrations.

**Architecture:** Red exact asset contract first; generate sources individually with source/512px review before another paid call; integrate full package as WebP, restore green and preserve all previous work. Reviews direct after exhausted subagent quota, not independent.

**Tech Stack:** Sunburst medium via tools/benchmark_exercise_images.py, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec:docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-21-design.md.
Read AGENTS.md,docs/modules/training.md,assets/data/exercises.json.
User approved layouts4/2/2/2/3/2 and cw098 SAME supportedworkingRIGHTarm.
Current /opt/fit main/no worktree,preserve Parts07–20 and other changes.
Baseline162/78/84/154/316,target168local/78published/90unpublished/148missing/316.
Production1.9.0+22;no version/commit/push/deployment without separate request.

- Create assets/exercises/cw097.webp throughcw102.webp.
- Modify test/features/exercises/exercise_illustrations_test.dart,
  lib/features/exercises/presentation/exercise_illustrations.dart,
  docs/exercise-illustrations-status.md; record execution here/in spec.
- Temporary prompts,PNGs,previews,ledgers in /tmp/opencode/cw097-* throughcw102-*.

## Task1: Red contract

- [x] Inspect status/scoped diff before edits,preserveexistingwork.
- [x] Add aftercw096 beforecw251 in expectedIllustrationIds:

```dart
    'cw097',
    'cw098',
    'cw099',
    'cw100',
    'cw101',
    'cw102',
```

- [x] Change absence assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw103'), isNull);
  });
```

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-21-red .
```

Expected missingcw097registry failure only,other tests/version/analysis pass.

## Task2: Exact prompt preparation/direct review

- [x] Verify cw256referencePNG/style and parent /tmp/opencode.
- [x] Write6separate cwNNN-trial-01-prompt.txt via filetool,commonblock+
  respective scene from approvedspec “Sześć promptów bazowych”,lines162–201.
- [x] Spec thenclarity/geometryreview: realhands supination/pronation097/100,
  SAMEsupportedarm098,neutralcrossbody099,landmarks101withoutcounts,
  fullhang/underhand/fixedbar/upperchest102.No paidcallbefore review.

## Task3: Generate cw097–cw099 sequentially

Fresh exclusiveoutput,parentverify,timeout>=240seconds.No secret/rawpayloadlog.
Read original/512preview and spec→qualityreview before nextpaidcall.

- [x] cw097:

```bash
test ! -e /tmp/opencode/cw097-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw097-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw097-trial-01 --exercise-id cw097 --single-sunburst-medium
convert /tmp/opencode/cw097-trial-01/cw097-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw097-trial-01/review-512.png
```

- [x] Review4in2x2:lowSUP→topSUP→sameTOPPRON→lowPRON,actualpalm/backswap,
  elbowspinned,2weights/nocrop/wristbend,no fifthresetpanel (catalogonly).
- [x] cw098:

```bash
test ! -e /tmp/opencode/cw098-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw098-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw098-trial-01 --exercise-id cw098 --single-sunburst-medium
convert /tmp/opencode/cw098-trial-01/cw098-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw098-trial-01/review-512.png
```

- [x] Seatedbench/feet,kneesapart,RIGHTelbowagainstINNER RIGHTthighabove
  knee,1DB SAMErightgrip,long→curledforearm,samecontact/emptyLEFThand.
- [x] cw099:

```bash
test ! -e /tmp/opencode/cw099-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw099-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw099-trial-01 --exercise-id cw099 --single-sunburst-medium
convert /tmp/opencode/cw099-trial-01/cw099-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw099-trial-01/review-512.png
```

- [x] 1RIGHTDB neutralgrip,emptyLEFT,low→diagonal towardLEFTshoulder,
  no forcedcontact/forearmstretch/bodytwist/elbowaway;notstraighthammerpath.

## Task4: Generate cw100–cw102 sequentially

- [x] cw100:

```bash
test ! -e /tmp/opencode/cw100-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw100-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw100-trial-01 --exercise-id cw100 --single-sunburst-medium
convert /tmp/opencode/cw100-trial-01/cw100-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw100-trial-01/review-512.png
```

- [x] BothDBPRONATEDthroughout,actualhandsnotonlyaxes,low→curl,
  straightwrists/fixedupperarms,noSUP/hammer/Zottmanswitch or swing.
- [x] cw101:

```bash
test ! -e /tmp/opencode/cw101-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw101-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw101-trial-01 --exercise-id cw101 --single-sunburst-medium
convert /tmp/opencode/cw101-trial-01/cw101-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw101-trial-01/review-512.png
```

- [x] 3landmarksBOTTOM/MID90/TOP,2SUPweights,fixedelbows;notnumeric
  method proof.No labels/count7/21/extrafigures/alternation/pause.
- [x] cw102:

```bash
test ! -e /tmp/opencode/cw102-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw102-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw102-trial-01 --exercise-id cw102 --single-sunburst-medium
convert /tmp/opencode/cw102-trial-01/cw102-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw102-trial-01/review-512.png
```

- [x] Shoulderwidthunderhandrealgrips,fullhang→upperchestclosebar/headabove,
  samebarheight/handpositions/camera/scale,feetAIR,nokip/jump/regrip/crop.

### Correction/failure procedure

Name actualdefect,freshprompt/output,ONLYlastrejectedPNGref,preserveaccepted
details.Read source/previewbeforenextcall.After2failedcorrectionssameissue
stop/evaluatenewcompositionbeforepaidcontinuation.Providererror:retainledger/
exclusivepath,noautomaticretry,unknowncostnotfree.Recorddirectreviewhonestly.

## Task5: Integrate all6 and restore green

- [x] Confirm allacceptedpaths/destination;belowinitialpathsONLYifaccepted,
  replace rejectedones with actualacceptedcorrections:

```bash
convert /tmp/opencode/cw097-trial-01/cw097-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw097.webp
convert /tmp/opencode/cw098-trial-01/cw098-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw098.webp
convert /tmp/opencode/cw099-trial-01/cw099-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw099.webp
convert /tmp/opencode/cw100-trial-01/cw100-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw100.webp
convert /tmp/opencode/cw101-trial-01/cw101-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw101.webp
convert /tmp/opencode/cw102-trial-01/cw102-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw102.webp
identify -format '%f %m %wx%h %b\n' assets/exercises/cw097.webp assets/exercises/cw098.webp assets/exercises/cw099.webp assets/exercises/cw100.webp assets/exercises/cw101.webp assets/exercises/cw102.webp
```

- [x] Readfinal6WebP512×512,frames4/2/2/2/3/2,support/grip/rangeclarity.
- [x] Add aftercw096 beforecw251 in illustratedExerciseIds:

```dart
  'cw097',
  'cw098',
  'cw099',
  'cw100',
  'cw101',
  'cw102',
```

- [x] Timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-21-verified .
docker run --rm fit-web:batch-21-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expectedfullsuite/version/analysisgreen,168exactfiles/IDs,512decode,
fallbackcw103,formatting0changes.No catalog/model/dependency/WebSQLitechanges.

## Task6: Record and close

- [x] Preserveearlierstatus/history,updatecounters:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 168 ilustracji:
78 wydanych oraz 90 lokalnie zintegrowanych, niewydanych z Partii 07–21.
148 ćwiczeń pozostaje bez ilustracji.
```

- [x] Addrowsaftercw096 beforecw251:

```markdown
| cw097 | Uginanie Zottmana z hantlami | 4 | Lokalnie zintegrowane; niewydane; podchwyt w górę, nachwyt w dół, siatka 2×2. |
| cw098 | Uginanie przedramienia z hantlem w oparciu o udo | 2 | Lokalnie zintegrowane; niewydane; prawa ręka i podparcie o prawe udo. |
| cw099 | Uginanie młotkowe z hantlem do przeciwnego barku | 2 | Lokalnie zintegrowane; niewydane; jeden hantel, prawa ręka ku lewemu barkowi. |
| cw100 | Uginanie przedramion z hantlami nachwytem | 2 | Lokalnie zintegrowane; niewydane; nachwyt przez obie fazy. |
| cw101 | Uginanie przedramion z hantlami metodą 21 powtórzeń | 3 | Lokalnie zintegrowane; niewydane; punkty dół/połowa/góra, 7+7+7 w katalogu. |
| cw102 | Podciąganie podchwytem z naciskiem na biceps | 2 | Lokalnie zintegrowane; niewydane; podchwyt, pełny zwis i górna klatka blisko drążka. |
```

- [x] “Dwudziesta pierwsza partia” beforegeneralrules: actualsources/reviews/
  corrections,cw098approvedinterpretation,cw101landmarksnotcountproof,
  successonlyuniqueledgercost/unknownerrorsseparate,greenlog168/78/90/148/316,
  production1.9.0+22.Executionrecordhere/spec,directnotindependentreviews.
- [x] Directfinal6asset/integrationreview,ledgerrequest_iddedup,
  git diff --check/scopedstatus.Noautomaticversion/Git/deploymentoperations.

## Self-review

6exactpromptreferences/calls/previews,pronation/samearm/crossbody/range/
barchecks.Allvariantsexplicit,catalogunchanged.Tasks1/5red-green,
Task6correctaccounting/earlierworkpreserved/directreviewhonesty.

## Execution record — 2026-10-15

- Six accepted trial-01 sources, frames 4/2/2/2/3/2; no corrections or HTTP
  errors. Exact prompts, source PNGs, previews and ledgers retained under
  `/tmp/opencode/cw097-*` through `/tmp/opencode/cw102-*`.
- Before requesting cw102, clarified headroom above the fixed bar.
- Direct source/512px reviews before subsequent calls, then final WebP review;
  no independent subagent reviews after quota exhaustion.
- cw098 uses the approved SAME supported right arm holding the only weight;
  catalog unchanged. cw101 depicts range landmarks, not proof of 21 reps.
- Red: missing cw097 only, other 365 tests passed; log
  `/root/.local/share/opencode/tool-output/tool_13bd69caf001g05NFI36001vJa`.
- Green: 366 tests passed, analysis 0 issues, 2 Dart files formatted with
  0 changes; log
  `/root/.local/share/opencode/tool-output/tool_13befbeff001TlBy4AREJ9szGN`.
  Build repeated successfully 2026-10-15 using the same cached verification
  layer; formatting rechecked with 0 changes.
- Registry/test/files: 168 IDs and 512×512 decoding, fallback cw103.
  Status updated to 168 local / 78 published / 90 unpublished / 148 missing / 316.
- Six success records with unique request_id, response_received not counted
  twice: 0.023247 + 0.022982 + 0.022952 + 0.022927 + 0.022992 + 0.023277
  = 0.138377 USD upper_bound_no_cache estimate, not provider billing.
- Detailed outcomes and cost table recorded in the approved spec and status.
  Package remains local and unpublished; production version 1.9.0+22.
- Final checks 2026-10-15: `git diff --check` clean; registry, test, assets
  and status table contain the same 168 IDs; all six new WebP are 512×512.
  Public `/version.json` returns 1.9.0 build 22; `/api/health` returns
  `{"status":"ok"}`. Scoped Git status confirms the local package files.
