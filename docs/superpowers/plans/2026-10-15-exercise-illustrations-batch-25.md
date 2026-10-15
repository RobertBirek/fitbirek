# Exercise Illustrations Batch 25 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate approved cw121–cw126 illustrations.

**Architecture:** Extend exact asset contract and confirm red first. Generate
six sources individually with source/512px review before next paid call;
integrate accepted WebP set and restore full client suite green.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context and files

Approved design: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-25-design.md`.
Read AGENTS.md/docs/modules/training.md. Work at current /opt/fit main,
preserve unpublished07–24. Direct reviews after earlier subagent limit,
not independent. Baseline186/78/108/130/316,target192/78/114/124/316.
Create assets/exercises/cw121.webp throughcw126.webp. Modify registry,
test/features/exercises/exercise_illustrations_test.dart,status and batch docs.
No catalog/models/dependencies/WebSQLite/version/commit/push/deployment changes.

## Task1: Red contract

- [x] Inspect scoped status and preserve previous work.
- [x] Add aftercw120 beforecw251 to expectedIllustrationIds:

```dart
    'cw121',
    'cw122',
    'cw123',
    'cw124',
    'cw125',
    'cw126',
```

- [x] Set fallback `expect(exerciseIllustrationAsset('cw127'), isNull);`.
- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-25-red .
```

Expected missingcw121 exactcontract failure,365other tests pass,analysis0issues.

## Task2: Exact prompts and sequential generation

- [x] Verify parent /tmp/opencode/referencePNG. Write6prompts
  /tmp/opencode/cw121-trial-01-prompt.txt throughcw126-trial-01-prompt.txt;
  each full commonblock+respective scene in approved spec “Sześć promptów”.
- [x] Direct spec→geometry review: towelcontinuity/fixedgrips/chinhandheight,
  realpinchhead122,rollercoils/cordlength123,wrists124,squatchestgrip/feet125,
  sideweights/floorclearance126. No paid call until this review.

Each command separately,timeout>=240seconds,freshexclusiveoutput,parentverify.
Read originalPNG/512preview before nextcall; no secrets or raw payloads in logs.

- [x] cw121 request:

```bash
test ! -e /tmp/opencode/cw121-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw121-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw121-trial-01 --exercise-id cw121 --single-sunburst-medium
convert /tmp/opencode/cw121-trial-01/cw121-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw121-trial-01/review-512.png
```

- [x] Review121:2towels/4tails,eachhandbothownends,neutralgrips,fixedbar/
  towellength/griponfabric,fullhang→chinathands,feetair,nokip/crop.
- [x] cw122 request:

```bash
test ! -e /tmp/opencode/cw122-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw122-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw122-trial-01 --exercise-id cw122 --single-sunburst-medium
convert /tmp/opencode/cw122-trial-01/cw122-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw122-trial-01/review-512.png
```

- [x] Review122:1frame,rightthumbvs4fingersSIDEpinchupperhead,oneverticalDB,
  freehandle/lowerhead,leftempty,nohandlegrip/undersidehook/thighsupport.
- [x] cw123 request:

```bash
test ! -e /tmp/opencode/cw123-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw123-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw123-trial-01 --exercise-id cw123 --single-sunburst-medium
convert /tmp/opencode/cw123-trial-01/cw123-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw123-trial-01/review-512.png
```

- [x] Review123:3columns,fixedtube/armsatshoulderheight,onecord/twoactualknots,
  increasingcoils/shorteningfreecord,sameweightlow→mid→high,nolegcollision.
- [x] cw124 request:

```bash
test ! -e /tmp/opencode/cw124-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw124-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw124-trial-01 --exercise-id cw124 --single-sunburst-medium
convert /tmp/opencode/cw124-trial-01/cw124-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw124-trial-01/review-512.png
```

- [x] Review124:2DBbehindhips,palmsBACKbothphases,wristsflexback/up,
  elbows/forearmsfixed,noarmraise/rotation/curl,clearancefrombody,readable512.
- [x] cw125 request:

```bash
test ! -e /tmp/opencode/cw125-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw125-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw125-trial-01 --exercise-id cw125 --single-sunburst-medium
convert /tmp/opencode/cw125-trial-01/cw125-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw125-trial-01/review-512.png
```

- [x] Review125:1verticalDBbothpalmsunderupperhead,stand→thighsparallel,
  samefullfootcontacts/kneestracktoes,neutralspine,noheelraise/secondweight.
- [x] cw126 request:

```bash
test ! -e /tmp/opencode/cw126-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw126-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw126-trial-01 --exercise-id cw126 --single-sunburst-medium
convert /tmp/opencode/cw126-trial-01/cw126-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw126-trial-01/review-512.png
```

- [x] Review126:2DBatSidesneutral,longarms,deepSquatnotdeadlift,weights
  clearfloor/legswithoutshortarms,samefeet/heelsgrounded/neutralspine.

Corrections: name defect,lastrejectedPNGONLY,newprompt/output,source/preview
before nextcall. After2failedsameissue stopthatcomposition,evaluatenewone;
continue to correctresult per user,not blindrepeats. Providererror/uncertainty:
retainledger/path,noautomaticretry,unknowncostseparate,nosecretlogs.

## Task3: Integration

- [x] Confirm all6acceptedpaths and destinations. Trialpaths below ONLY if
  accepted;substituteactualacceptedcorrectionpaths forrejectedtrials:

```bash
convert /tmp/opencode/cw121-trial-01/cw121-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw121.webp
convert /tmp/opencode/cw122-trial-01/cw122-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw122.webp
convert /tmp/opencode/cw123-trial-01/cw123-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw123.webp
convert /tmp/opencode/cw124-trial-01/cw124-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw124.webp
convert /tmp/opencode/cw125-trial-01/cw125-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw125.webp
convert /tmp/opencode/cw126-trial-01/cw126-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw126.webp
```

- [x] Readfinal6WebP,512×512,frames2/1/3/2/2/2.
- [x] Add aftercw120 beforecw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw121',
  'cw122',
  'cw123',
  'cw124',
  'cw125',
  'cw126',
```

## Task4: Green

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-25-verified .
docker run --rm fit-web:batch-25-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass,analysis0issues,versioncheckpass,192exactIDs/assets,512decode,
fallbackcw127,format0changes.

## Task5: Record and close

- [x] Status192local/78published/114unpublished07–25/124missing/316;6rows
  exactnames/framecounts and “Dwudziesta piąta partia” before rules.
- [x] Recordrealacceptedpaths/reviews/corrections,interpretations/equipment,
  directnotindependentreviews afterearlierquota,greenlogs;preserveearlierhistory.
- [x] Readledgers,successonly/uniquerequest_id/sumcost,nodoublecountresponse_received;
  unknownfailuresseparate,upper_bound_no_cacheestimate notbilling.
- [x] Finaldirect6asset/integrationreview,192matchingregistry/test/assets/status,
  scopedstatus,then:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expectedcleandiff,production1.9.0build22,APIstatusok;packagelocal/unpublished.

## Self-review

Sixspecscenes covered,2/1/3/2/2/2frames. Fixedtowels/realpinch/rollerphysics/
wristmovement/squatgrips andfeet explicit. Red-green192contract/fallback127,
review/error/costrules andpreservation included. No integration/releasecommit.

## Execution record — 2026-10-15

- Accepted source directories under /tmp/opencode: cw121-correction-02,
  cw122-trial-01,cw123-correction-01,cw124-correction-01,cw125-trial-01,
  cw126-trial-01. Frames2/1/3/2/2/2, no reuse.
- Two cw121 corrections raised top body to chin at gripheight while retaining
  bar/towel/grip positions. Cw123 correction increased final coilcount;
  cw124 correction clarified actual wristflexion with fixedforearms.
- All sources and512previews read before nextcall,final6WebP read after
  resize512/strip/quality90. Direct spec→quality review,not independent after
  earlier subagentlimit. Exact prompts/sourcePNGs/previews/ledgers retained.
- Red:only missingcw121 contract failure,365other tests pass,analysis0issues.
  Log `/root/.local/share/opencode/tool-output/tool_13ee14bff001UVD16bMS4cDoAM`.
- Green:366pass,analysis0issues,versioncheckpass,2Dartfilesformat0changes.
  Log `/root/.local/share/opencode/tool-output/tool_13ef76ca0001BlTc05Y6JIjYgv`.
  Registry/test/files192IDs,512decode,fallbackcw127.
- Read10successledgers,unique request_id,response_receivednotdoublecounted,
  noHTTPerrors.6sources+4corrections,0.229705USD upper_bound_no_cache estimate,
  not providerbilling. Itemized table in spec. Status192/78/114/124/316,
  package local/unpublished,production1.9.0+22,earlierworkpreserved.
- Final checks:git diff --check clean,scopedstatusreviewed,192matching IDs
  in registry/test/assets/status, fallbackcw127. Publicversion1.9.0build22,
  APIhealth statusok.
