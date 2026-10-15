# Exercise Illustrations Batch 20 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate cw091–cw096 with approved scaption/grip/curl variants.

**Architecture:** Red exact asset contract, six sequentially generated sources reviewed at source/512px, then complete-package WebP integration and green verification. Preserve earlier unpublished work. Direct reviews because prior subagent quota is exhausted; no independent-review claims.

**Tech Stack:** Sunburst medium via tools/benchmark_exercise_images.py, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec: docs/superpowers/specs/2026-10-14-exercise-illustrations-batch-20-design.md.
Read AGENTS.md,docs/modules/training.md,assets/data/exercises.json.
Work /opt/fit main/no worktree; preserve Parts07–19 and all other work.
Baseline156/78/78/160/316; target162local/78published/84unpublished/154missing/316.
Layouts2/2/2/2/3/2,scaption30°forwardoflateral,091thumbdown/092thumbup,
093neutral→supinated,094neutral,095alternatingfixedsupinated,096bench55°.
Production1.9.0+22; no version/commit/push/deployment without separate request.

- Create assets/exercises/cw091.webp throughcw096.webp.
- Modify test/features/exercises/exercise_illustrations_test.dart,
  lib/features/exercises/presentation/exercise_illustrations.dart,
  docs/exercise-illustrations-status.md; record execution here/in spec.
- Prompts,PNG,previews,ledgers in /tmp/opencode/cw091-* throughcw096-*,outside repo.

## Task1: Red contract

- [ ] Inspect status/scoped diff before edits,preserve existing changes.
- [ ] Add aftercw090 beforecw251 to expectedIllustrationIds:

```dart
    'cw091',
    'cw092',
    'cw093',
    'cw094',
    'cw095',
    'cw096',
```

- [ ] Change absence assertion:

```dart
  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw097'), isNull);
  });
```

- [ ] Timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-20-red .
```

Expected missingcw091 registry failure only; other tests/version/analysis pass.

## Task2: Exact prompt preparation/review

- [ ] Verify existing /tmp/opencode/cw256-reference.png and stylecw256.
- [ ] Write six cwNNN-trial-01-prompt.txt via file tool, common block+respective
  scene from approved spec “Sześć promptów bazowych”,lines152–191.
- [ ] Direct specification then clarity/geometry review: thumbsidefromactualhands,
  30°scaptionvsfront/lateral,093supinationvs094hammer,095continuoussides,
  096supine-seat55°/verticalhang/fixedelbows. No paid calls before review.

## Task3: Generate cw091–cw093 sequentially

Fresh exclusive outputs,parent verification,timeout>=240seconds.No secrets/rawpayload.
Read original and512preview and review spec then quality before next paidcall.

- [ ] cw091:

```bash
test ! -e /tmp/opencode/cw091-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw091-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw091-trial-01 --exercise-id cw091 --single-sunburst-medium
convert /tmp/opencode/cw091-trial-01/cw091-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw091-trial-01/review-512.png
```

- [ ] Twohorizontalrows,2smallweights,scaptiontoSHOULDERlevel,
  thumbsideDOWNraisedrealclosedgrips,neutralwrists,mildelbows/no shrug;
  no literal low-pose world-thumb direction requirement.
- [ ] cw092:

```bash
test ! -e /tmp/opencode/cw092-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw092-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw092-trial-01 --exercise-id cw092 --single-sunburst-medium
convert /tmp/opencode/cw092-trial-01/cw092-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw092-trial-01/review-512.png
```

- [ ] Same scaptionconcept,thumbsideUPraised,closedgrips/neutralwrists,
  no changedtrajectory/pureT/front,hugeplates,shrug or crop.Compare091hands.
- [ ] cw093:

```bash
test ! -e /tmp/opencode/cw093-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw093-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw093-trial-01 --exercise-id cw093 --single-sunburst-medium
convert /tmp/opencode/cw093-trial-01/cw093-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw093-trial-01/review-512.png
```

- [ ] Twopanels neutral bottom→bilateralcurlsupination, fixedupperarms/elbows,
  fullbottom/closedrealhandles,neutralwrists,no swing/forwardelbowdrift.

## Task4: Generate cw094–cw096 sequentially

- [ ] cw094:

```bash
test ! -e /tmp/opencode/cw094-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw094-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw094-trial-01 --exercise-id cw094 --single-sunburst-medium
convert /tmp/opencode/cw094-trial-01/cw094-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw094-trial-01/review-512.png
```

- [ ] Realneutralhammerhandsbothphases,2weights,stationaryupperarms/elbows,
  no supination/crossbody/swing;compare actualgrips093,notweightaxesalone.
- [ ] cw095:

```bash
test ! -e /tmp/opencode/cw095-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw095-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw095-trial-01 --exercise-id cw095 --single-sunburst-medium
convert /tmp/opencode/cw095-trial-01/cw095-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw095-trial-01/review-512.png
```

- [ ] ThreecolumnsRIGHTcurled/LEFTdown→BOTHmid90°→LEFTcurled/RIGHTdown,
  continuouschange/supinatedgrips,2weightsallphases,no bodyrotation/elbowdrift.
- [ ] cw096:

```bash
test ! -e /tmp/opencode/cw096-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw096-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw096-trial-01 --exercise-id cw096 --single-sunburst-medium
convert /tmp/opencode/cw096-trial-01/cw096-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw096-trial-01/review-512.png
```

- [ ] Seatedreclined55°bench,back/hips/feet supported,verticalhangslightlybehind
  torsoplane→curlwithSAMEelbows,supinatedgrips,no prone/press/benchcollision.

### Correction/failure procedure

Name realdefect,fresh numberedprompt/output,ONLYlastrejectedPNGref,
preserveacceptedparts;read source/previewbeforenextcall.After2failed
correctionsofsameissue stop/evaluate newcompositionbeforepaidcontinuation.
Providererror/uncertainty:retainledger/exclusivedirectory,noautomaticretry,
unknowncostnotfree.Recordacceptedpaths/directreviews/successonlytotals.

## Task5: Whole-package integration and green

- [ ] Confirm all6acceptedpaths anddestination.InitialpathsONLYifaccepted;
  replace rejectedinitials with actualacceptedcorrection paths:

```bash
convert /tmp/opencode/cw091-trial-01/cw091-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw091.webp
convert /tmp/opencode/cw092-trial-01/cw092-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw092.webp
convert /tmp/opencode/cw093-trial-01/cw093-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw093.webp
convert /tmp/opencode/cw094-trial-01/cw094-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw094.webp
convert /tmp/opencode/cw095-trial-01/cw095-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw095.webp
convert /tmp/opencode/cw096-trial-01/cw096-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw096.webp
identify -format '%f %m %wx%h %b\n' assets/exercises/cw091.webp assets/exercises/cw092.webp assets/exercises/cw093.webp assets/exercises/cw094.webp assets/exercises/cw095.webp assets/exercises/cw096.webp
```

- [ ] Read all6finalWebP,512×512/2-2-2-2-3-2frames,motions/grips/supportsreadable.
- [ ] Add aftercw090 beforecw251 in illustratedExerciseIds:

```dart
  'cw091',
  'cw092',
  'cw093',
  'cw094',
  'cw095',
  'cw096',
```

- [ ] Timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-20-verified .
docker run --rm fit-web:batch-20-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expectedfullsuite/version/analysisgreen,162exactfiles/IDs,512decode,
fallbackcw097,formatting0changes.No catalog/model/dependency/WebSQLitechanges.

## Task6: Record and close

- [ ] Preserve priorstatus/history,update:

```text
Katalog obejmuje 316 ćwiczeń. Rejestr i assety zawierają 162 ilustracje:
78 wydanych oraz 84 lokalnie zintegrowane, niewydane z Partii 07–20.
154 ćwiczenia pozostają bez ilustracji.
```

- [ ] Add aftercw090 beforecw251:

```markdown
| cw091 | Unoszenie hantli w skos w przód z kciukami w dół | 2 | Lokalnie zintegrowane; niewydane; scaption, kciukowe strony w dół. |
| cw092 | Unoszenie hantli w skos w przód z kciukami w górę | 2 | Lokalnie zintegrowane; niewydane; scaption, kciukowe strony w górę. |
| cw093 | Uginanie przedramion z hantlami w staniu | 2 | Lokalnie zintegrowane; niewydane; oburącz z supinacją. |
| cw094 | Uginanie młotkowe z hantlami | 2 | Lokalnie zintegrowane; niewydane; chwyt neutralny przez cały ruch. |
| cw095 | Naprzemienne uginanie przedramion z hantlami | 3 | Lokalnie zintegrowane; niewydane; prawa, obie w połowie, lewa. |
| cw096 | Uginanie przedramion z hantlami na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; oparcie 55°, ramiona w zwisie. |
```

- [ ] “Dwudziesta partia” beforegeneralrules,actualsources/reviews/corrections,
  successonlyledgeruniqueIDcost,separateunknownfailures,greenlog162/78/84/154/316,
  production1.9.0+22.Record executionhere/spec,directreviewsnotindependent.
- [ ] Finalall6asset/integrationreview,ledgerdeduprequest_id,git diff --check,
  scopedstatus,noautomaticversion/Git/deploymentoperations.

## Self-review

Exact6promptreferences/calls/previews,thumb/scaption/grip/elbow/supportchecks,
alternationandinclineclear.Tasks1/5red-green,Task6correctcounters/earlierworkpreservation.

## Execution record — 2026-10-14

- [x] Task1: red missingcw091 only,365 other tests passed,analysisclean.
- [x] Task2: six exact prompts reviewed directly,spec thenclarity/geometry; no independent review after previousquota.
- [x] Task3: cw091/cw093 initial accepted,cw092 closedgrip/twoheads/endpoint corrected once.
- [x] Task4: cw094 initial accepted,cw095 columns locally reversed in order without mirroring/deforming figures,cw096 farhand/weight revealed after2corrections.
- [x] Task5: all6WebP512×512 integrated,162exactfiles/IDs,fallbackcw097,Docker366tests passed,analysisclean,format0changes.
- [x] Task6: documentation,sixfinalassetreview and9successledgers completed directly; closingdiff/status checks passed,publicproduction1.9.0+22 andhealthok confirmed.

Accepted sources under /tmp/opencode:

| ID | Directory | Filename | Frames |
|---|---|---|---:|
| cw091 | cw091-trial-01 | cw091-gpt-image-2.5-sunburst-medium.png | 2 horizontal rows |
| cw092 | cw092-correction-01 | cw092-gpt-image-2.5-sunburst-medium.png | 2 horizontal rows |
| cw093 | cw093-trial-01 | cw093-gpt-image-2.5-sunburst-medium.png | 2 side-by-side |
| cw094 | cw094-trial-01 | cw094-gpt-image-2.5-sunburst-medium.png | 2 side-by-side |
| cw095 | cw095-trial-01 | cw095-approved-reordered.png | 3 vertical columns |
| cw096 | cw096-correction-02 | cw096-gpt-image-2.5-sunburst-medium.png | 2 side-by-side |

cw095derivation:crop3panelcontents,append inreverseorder withunlabeledblack
dividers;1024×1024 retained, nofiguremirror/resize,deformation or newAPI.
OriginalPNG/ledger retained. Allsource/512preview/finalWebP directlyread,
specification thenquality assessed withoutindependentreviewclaims.
6initial+3paidcorrections=9unique successes,0HTTPerrors,upper-bound
estimate0.205028USD. Successrecords only,all9request_iddistinct,
response_receivednotdoublecounted. Localreorder adds0requests.
Estimate notconfirmedproviderbilling. Catalog/version/earlierwork untouched.
Greenlog:/root/.local/share/opencode/tool-output/tool_13b9172060015rpVXUimydDCXm.
Current162/78/84/154/316,production1.9.0+22,noautomaticGit/deploymentoperations.
