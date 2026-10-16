# Exercise Illustrations Batch 29 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved cw145–cw150 illustrations.

**Architecture:** Exact contract red first, five individual sources with source/
512px review before next paid request, byte-identical cw063 reuse for cw148,
accepted WebP integration and complete client suite green. Reviews direct.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-29-design.md`.
Read AGENTS.md/docs/modules/training.md. Current /opt/fit main, preserve released
assets and local Part28. Baseline210/204/6/106/316,target216/204/12/100/316.
Create assets/exercises/cw145.webp throughcw150.webp. Modify registry,
test/features/exercises/exercise_illustrations_test.dart,status and batch docs.
No catalog/model/dependency/WebSQLite/version/commit/push/deployment changes.

## Task1: Red contract

- [x] Inspect scoped status and preserve previous work.
- [x] Add aftercw144 beforecw251 in expectedIllustrationIds:

```dart
    'cw145',
    'cw146',
    'cw147',
    'cw148',
    'cw149',
    'cw150',
```

- [x] Set fallback `expect(exerciseIllustrationAsset('cw151'), isNull);`.
- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-29-red .
```

Expected missingcw145 contract failure only,365otherpass,analysis0issues.

## Task2: Prompts and sequential generation

- [x] Verify /tmp/opencode/referencePNG. Write5promptfiles cw145-trial-01-prompt.txt,
  cw146-trial-01-prompt.txt,cw147-trial-01-prompt.txt,cw149-trial-01-prompt.txt,
  cw150-trial-01-prompt.txt under /tmp/opencode,fullcommonblock+respective
  approved scene from spec “Pięć promptów bazowych”.
- [x] Direct spec→geometry review: body180/camerafixed,benchfullsoles/landing/
  stand,broadhorizontaltravel,reuse148/63,singlelegsquarehips,softstraightknees150.

Each command separately,timeout>=240seconds,freshexclusiveoutput,parentverify.
Read source/512preview before nextpaidcall,no secrets/rawpayloadlogs.

- [x] Generate145:

```bash
test ! -e /tmp/opencode/cw145-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw145-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw145-trial-01 --exercise-id cw145 --single-sunburst-medium
convert /tmp/opencode/cw145-trial-01/cw145-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw145-trial-01/review-512.png
```

- [x] Review145:3columns,RIGHTfacingcrouch→FRONTfacingflight→LEFTfacingbentlanding,
  BOTHfeetAIR,coherentwholebodyrotation,constantfloor/scale,nocamerachange.
- [x] Generate146:

```bash
test ! -e /tmp/opencode/cw146-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw146-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw146-trial-01 --exercise-id cw146 --single-sunburst-medium
convert /tmp/opencode/cw146-trial-01/cw146-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw146-trial-01/review-512.png
```

- [x] Review146:4grid,groundcrouch→bothfeetflight→bentlandingBOTHfullsolesONseat
  →standBOTHseat,constantbenchdimensions/scale,nojumpdown/stepup/shortlegs.
- [x] Generate147:

```bash
test ! -e /tmp/opencode/cw147-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw147-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw147-trial-01 --exercise-id cw147 --single-sunburst-medium
convert /tmp/opencode/cw147-trial-01/cw147-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw147-trial-01/review-512.png
```

- [x] Review147:3bands,leftcrouch→centerflight→rightbentlanding,bodymovesrelative
  samefloorseams/notrecentered,samebodysize,BOTHfeetflight/landing,novertjump.
- [x] Generate149:

```bash
test ! -e /tmp/opencode/cw149-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw149-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw149-trial-01 --exercise-id cw149 --single-sunburst-medium
convert /tmp/opencode/cw149-trial-01/cw149-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw149-trial-01/review-512.png
```

- [x] Review149:2bands,RIGHTfullsoleonly,leftfreebehind,2DBrealgripsalongrightleg,
  hiphinge/pelvissquare/softknee,not squatorrow,nokickstand/legrotation.
- [x] Generate150:

```bash
test ! -e /tmp/opencode/cw150-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw150-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw150-trial-01 --exercise-id cw150 --single-sunburst-medium
convert /tmp/opencode/cw150-trial-01/cw150-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw150-trial-01/review-512.png
```

- [x] Review150:2sideframes,tinysoftkneebend/notlocked,deephinge/neutralback,
  2DBscloselegs/nearfloor,noforcingfloorwithroundedspine/longarms/squat.

Corrections:nameddefect,lastrejectedPNGONLY,freshprompt/output,readsource/preview.
After2failedsameissue stopcomposition/assessnewone,continuetocorrectresultperuser
notblindrepeats. Providerfailure/uncertainty:retainledger/path,noautoretry,
unknowncostseparate,nosecretlogs.

## Task3: Reuse and integration

- [x] Re-readcw063 and comparecue148midshin/grip/hinge;approvedreuseONLYifvalid.
  Verifyassetparent/freshdestination,copywithoutrecompression:

```bash
cp assets/exercises/cw063.webp assets/exercises/cw148.webp
cmp assets/exercises/cw063.webp assets/exercises/cw148.webp
```

- [x] Convert5acceptednewPNGs. TrialpathsONLYifaccepted,substituteactual
  acceptedcorrectionpaths forrejectedtrials:

```bash
convert /tmp/opencode/cw145-trial-01/cw145-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw145.webp
convert /tmp/opencode/cw146-trial-01/cw146-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw146.webp
convert /tmp/opencode/cw147-trial-01/cw147-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw147.webp
convert /tmp/opencode/cw149-trial-01/cw149-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw149.webp
convert /tmp/opencode/cw150-trial-01/cw150-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw150.webp
```

- [x] Readfinal6WebP512×512,frames3/4/3/2/2/2,cmpreusepassed.
- [x] Add aftercw144 beforecw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw145',
  'cw146',
  'cw147',
  'cw148',
  'cw149',
  'cw150',
```

## Task4: Green

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-29-verified .
docker run --rm fit-web:batch-29-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass,analysis0issues,versioncheckpass,216exactIDs/assets,512decode,
fallbackcw151,format0changes.

## Task5: Record/close

- [x] Status216local/204published/12unpublished28–29/100missing/316,sixrows,
  “Dwudziesta dziewiąta partia” before rules. Preserve Part28 and releaseevidence.
- [x] Recordactualacceptedpaths/reviews/corrections,reusezeroAPI/variantchanges,
  directnotindependentafterearlierquota,greenlogs in spec/plan/status.
- [x] Readledgers,successonly/uniquerequest_id/costsum,notdoublecountresponse_received,
  unknownfailuresseparate,estimatekindnotbilling.
- [x] Final216matchingregistry/test/files/status,scopedstatus,then:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expectedcleandiff,production1.10.0build23,APIstatusok,batchlocalunpublished.

## Self-review

All6IDs/5newscenes/reuse covered,3/4/3/2/2/2frames,bodyrotation/camerafixed,
horizontaltravel/benchphysics/reuseRDL/softknees explicit. Red-green216/fallback151,
review/cost/errorrules included,priorworkpreserved.

## Execution record — 2026-10-15

- Accepted: cw145-trial-01,cw147-trial-01,cw149-trial-01,
  cw150-correction-02 under /tmp/opencode; cw146-approved-aligned.png from
  cw146-new-01; cw148 byte-identical copy of cw063 (cmp passed,zeroAPI).
- Cw146 firsttrial/correction changed benchlocation/perspective; new pureSIDE
  camera simplifiedgeometry. Local4scene layout:uniform85percent scaling
  ALL complete crops,translations only,no independentbody/bench scaling or
  anatomydeformation. Exact command in spec. RGBcomparison verified4/4crops
  match uniformlyscaledoriginals;source/alignedPNG/512preview retained/read.
- Cw150 two corrections deepenedhiphinge/loweredweightsnearankles/floor,
  tinysoftkneebend/neutralspine retained,not forcinggroundcontact.
- Source/512preview read before nextrequest,allfinal6WebP read after
  resize512/strip/quality90 (reusewithoutconversion). Direct spec→quality
  reviews,not independent after earlier subagentquota. Frames3/4/3/2/2/2.
- Red:missingcw145 only,365other tests pass,analysis0issues;log
  `/root/.local/share/opencode/tool-output/tool_14058a1ed001JTX5oS8svaTgka`.
- Green:366pass,analysis0issues,versioncheckpass,2Dartfiles format0changes;
  log `/root/.local/share/opencode/tool-output/tool_14077ebf1001w93VqBt67qAkA8`.
  Registry/test/files216IDs,512decode,fallbackcw151,status216/204/12/100/316.
- Read9successledgers,unique request_id,no doublecountresponse_received,
  noHTTPerrors.6sources/newcompositions+3corrections,0.209028USD
  upper_bound_no_cache estimate,not providerbilling. Itemized table in spec.
- Local Part28/releasedassets/history preserved. No catalog/model/dependency/
  WebSQLite/version/Git/deployment changes,production1.10.0+23.
- Finalchecks:git diff --check clean,scopedstatus reviewed,216matchingIDs in
  registry/test/assets/status,fallbackcw151,cmpreusepassed. Version/catalog/
  lockfile/WebSQLite unchanged;publicversion1.10.0build23,APIhealth statusok.
