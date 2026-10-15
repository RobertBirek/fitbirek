# Exercise Illustrations Batch 27 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved cw133–cw138 illustrations.

**Architecture:** Exact asset contract red first, six individual sources with
source/512px reviews before next paid request, accepted WebP integration and
complete client suite green. Direct reviews after earlier subagent limit.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-27-design.md`.
Read AGENTS.md/docs/modules/training.md. Current /opt/fit main, preserve all
unpublished07–26. Baseline198/78/120/118/316, target204/78/126/112/316.
Create assets/exercises/cw133.webp throughcw138.webp. Modify registry,
test/features/exercises/exercise_illustrations_test.dart, status and batch docs.
No catalog/model/dependency/WebSQLite/version/commit/push/deployment changes.

## Task1: Red contract

- [x] Inspect scoped status and preserve previous work.
- [x] Add aftercw132 beforecw251 in expectedIllustrationIds:

```dart
    'cw133',
    'cw134',
    'cw135',
    'cw136',
    'cw137',
    'cw138',
```

- [x] Set fallback `expect(exerciseIllustrationAsset('cw139'), isNull);`.
- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-27-red .
```

Expected only missingcw133 registry failure,365otherpass,analysis0issues.

## Task2: Exact prompts and sequential generation

- [x] Verify /tmp/opencode/referencePNG. Write6prompts cw133-trial-01-prompt.txt
  throughcw138-trial-01-prompt.txt under /tmp/opencode, each full commonblock
  plus approved respective scene from spec “Sześć promptów bazowych”.
- [x] Review spec then geometry: crossed foot notvalgus,actual ribcagerotation,
  rightfullsole atop fixedbench,correctLEFTkneedrive,rightheel/freeleftfoot,
  highfrontanchor/twobranches/grips/no leanback for assistedpistol.

Run separately,timeout>=240seconds,freshexclusiveoutput,parentverify,no secrets
or rawpayloads in logs. Read sourcePNG and512preview before next paid call.

- [x] Generate cw133:

```bash
test ! -e /tmp/opencode/cw133-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw133-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw133-trial-01 --exercise-id cw133 --single-sunburst-medium
convert /tmp/opencode/cw133-trial-01/cw133-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw133-trial-01/review-512.png
```

- [x] Review133:3bands,stand→leftcrossesbehindrightHIGH→low,rightfootanchored,
  twoweights,longarms,nofrontkneecollapse or plainreverse.
- [x] Generate cw134:

```bash
test ! -e /tmp/opencode/cw134-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw134-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw134-trial-01 --exercise-id cw134 --single-sunburst-medium
convert /tmp/opencode/cw134-trial-01/cw134-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw134-trial-01/review-512.png
```

- [x] Review134:4grid,lowrightneutral→samefeettwistright→rise/leftpassesneutral
  →lowlefttwistleft,actualshoulders/ribcagerotation,2DBinfrontchest,nocameraflip.
- [x] Generate cw135:

```bash
test ! -e /tmp/opencode/cw135-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw135-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw135-trial-01 --exercise-id cw135 --single-sunburst-medium
convert /tmp/opencode/cw135-trial-01/cw135-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw135-trial-01/review-512.png
```

- [x] Review135:2bands,rightfullsolebench/leftfloor→BOTHfeetbench,twoDBsides,
  samebench/rightsolecontact/camera/scale,headroom,no knee-drive/jump.
- [x] Generate cw136:

```bash
test ! -e /tmp/opencode/cw136-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw136-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw136-trial-01 --exercise-id cw136 --single-sunburst-medium
convert /tmp/opencode/cw136-trial-01/cw136-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw136-trial-01/review-512.png
```

- [x] Review136: final3COLUMNS (layout changed),rightfullsolebench→rightsinglelegsupport/leftLOWfree
  →LEFTkneedrive,lefthasNOseatcontact2/3,no sidechange,twoDBsides/headroom.
- [x] Generate cw137:

```bash
test ! -e /tmp/opencode/cw137-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw137-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw137-trial-01 --exercise-id cw137 --single-sunburst-medium
convert /tmp/opencode/cw137-trial-01/cw137-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw137-trial-01/review-512.png
```

- [x] Review137:2bands,rightfullsolefixed,leftstraightforward/AIR,botharmsforward,
  high→deep,pelvisnearheel,naturallean,noextraequipment/leftsupport/heelraise.
- [x] Generate cw138:

```bash
test ! -e /tmp/opencode/cw138-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw138-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw138-trial-01 --exercise-id cw138 --single-sunburst-medium
convert /tmp/opencode/cw138-trial-01/cw138-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw138-trial-01/review-512.png
```

- [x] Review138:2bands,pistolsupportas137,highfrontanchor/twotautbranches/
  tworealgrips,longerbandlow,no leanback/footanchor/leftsupport/bench/weights.

Corrections: nameddefect,lastrejectedPNGONLY,newprompt/output;readsource/preview
before nextcall. After2failedsameissue stopthatcomposition and assess newone,
continue to correctresult peruser withoutblindrepeats. Providererror/uncertainty:
retainledger/path,noautomaticretry,unknowncostseparate,nosecretlogs.

## Task3: Integration

- [x] Confirm all6acceptedpaths and freshdestinations. Trialpaths ONLY if
  accepted,substituteactualacceptedcorrections forrejectedtrials:

```bash
convert /tmp/opencode/cw133-trial-01/cw133-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw133.webp
convert /tmp/opencode/cw134-trial-01/cw134-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw134.webp
convert /tmp/opencode/cw135-trial-01/cw135-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw135.webp
convert /tmp/opencode/cw136-trial-01/cw136-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw136.webp
convert /tmp/opencode/cw137-trial-01/cw137-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw137.webp
convert /tmp/opencode/cw138-trial-01/cw138-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw138.webp
```

- [x] Readfinal6WebP,512×512,frames3/4/2/3/2/2.
- [x] Add aftercw132 beforecw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw133',
  'cw134',
  'cw135',
  'cw136',
  'cw137',
  'cw138',
```

## Task4: Green

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-27-verified .
docker run --rm fit-web:batch-27-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass,analysis0issues,versioncheckpass,204exactIDs/assets,512decode,
fallbackcw139,format0changes.

## Task5: Documentation and close

- [x] Status204local/78published/126unpublished07–27/112missing/316;6rows
  exactnames/framecounts,“Dwudziesta siódma partia” before rules.
- [x] Recordrealacceptedpaths/reviews/corrections,actualvariantchanges andlogs,
  directnotindependentafterearlierquota,preserveallprevioushistory.
- [x] Readledgers,successonly/uniquerequest_id/sumcost,nodoublecountresponse_received;
  unknownerrorsseparate,upper_bound_no_cacheestimate notproviderbilling.
- [x] Finaldirectasset/integrationreview,204matchingregistry/test/files/status,
  scopedstatus and:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expectedcleandiff,production1.9.0build22,APIstatusok;packagelocal/unpublished.

## Self-review

All6specscenes covered,3/4/2/3/2/2frames,correctgearonly,step/twist/support
assignments explicit,red-green204contract/fallback139,realreview/error/costrules.

## Execution record — 2026-10-15

- Accepted: cw133-approved-aligned.png (local trial-01 derivative),
  cw134-new-01, cw135-new-correction-01, cw136-new-correction-02,
  cw137-trial-01, cw138-correction-01 under /tmp/opencode.
- Frames3/4/2/3/2/2. Cw136 final layout THREE VERTICAL COLUMNS instead of
  planned horizontal bands: more vertical room for full support-leg extension,
  same physical anatomy and correct support identity. Final exact frontal view.
- Cw133 top region translated rigidly +65px, rows0–364 only; lower scenes/
  dividers pixel-identical. RGB comparison verified original0..958 maps to
  new65..1023 and entire y>=365 unchanged. No scale/mirror/deformation/APIcall.
- Cw134 rejected first same-leg sequence; new frontal composition shows
  actual torso rotation toward each front leg with two weights before chest.
- Cw135 rejected first shortened-leg result, new composition plus bench
  consistency correction. Cw136 rejected trial/new-01/new-02 and its correction
  due support/extension/side/grip problems; new-03 correctly showed right
  support/left drive, last correction reduced enlarged final bench.
  new-correction-02 references ONLY new-03, not earlier correction directory.
- Cw137 first try accepted; cw138 correction straightened top support knee
  with deep bottom pose/heel/freeleg and bandcontinuity preserved.
- Each source/512preview read before nextrequest; localalignedPNG/preview
  read, all final6WebP read after resize512/strip/quality90. Direct spec→quality
  reviews, not independent after earlier subagent quota limit.
- Red: missingcw133 only,365other tests pass; log
  `/root/.local/share/opencode/tool-output/tool_13fb48c75001EhS67gmmzCLC6H`.
- Green:366pass,analysis0issues,versioncheckpass,2Dartfiles format0changes.
  `/root/.local/share/opencode/tool-output/tool_13fdee8cf001Q6giiBpQ5Nxs6j`.
  Registry/test/files204IDs,512decode,fallbackcw139,status204/78/126/112/316.
- Read15successledgers,unique request_id,no double-count response_received,
  noHTTPerrors.11sources/newcompositions+4corrections,total0.348425USD
  upper_bound_no_cache estimate,not providerbilling. Itemized table in spec.
  Package local/unpublished,production1.9.0+22,earlierhistorypreserved.
- Final checks:git diff --check clean,scopedstatus reviewed,204matching IDs
  across registry/test/assets/status, fallbackcw139. Publicversion1.9.0build22,
  APIhealth statusok. No outstanding batch tasks.
