# Exercise Illustrations Batch 24 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate approved cw115–cw120 illustrations.

**Architecture:** Exact asset contract red first. Five individual sources,
source/512px direct reviews before next paid request; byte-identical cw043 reuse
for cw120. Integrate six assets and restore full client suite green.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-24-design.md`.
Read AGENTS.md/docs/modules/training.md. Current /opt/fit main, preserve all
unpublished07–23. Direct review after earlier subagent limit, not independent.
Baseline180/78/102/136/316,target186/78/108/130/316. Create assets/exercises/
cw115.webp throughcw120.webp. Modify registry,test,status and batch docs only.
No catalog/model/dependency/WebSQLite/version/Git/deployment changes.

## Task1: Red contract

- [x] Inspect scoped status, preserve earlier changes.
- [x] Add aftercw114 beforecw251 in
  test/features/exercises/exercise_illustrations_test.dart expectedIllustrationIds:

```dart
    'cw115',
    'cw116',
    'cw117',
    'cw118',
    'cw119',
    'cw120',
```

- [x] Change fallback to `expect(exerciseIllustrationAsset('cw121'), isNull);`.
- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-24-red .
```

Expected only exactregistry missingcw115 failure,365otherpass,analysis0issues.

## Task2: Prompt preparation and sequential generation

- [x] Verify /tmp/opencode and stylePNG cw256-reference.png. Write5prompts
  /tmp/opencode/cw115-trial-01-prompt.txt throughcw119-trial-01-prompt.txt,
  each full approved commonblock+respective scene from spec “Pięć promptów”.
- [x] Direct spec→geometry review: lowrearanchor115,Tatepronation/elbowsoutside,
  wristmovement117/118 with forearmsfixed and oppositegrips,alternatingsteps119.

Execute each request separately,read source and512preview before nextcall;
timeout>=240seconds,freshexclusiveoutput,parentverify,nosecrets/rawpayloadlog.

- [x] cw115:

```bash
test ! -e /tmp/opencode/cw115-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw115-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw115-trial-01 --exercise-id cw115 --single-sunburst-medium
convert /tmp/opencode/cw115-trial-01/cw115-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw115-trial-01/review-512.png
```

- [x] Review115: rear-side3/4,lowexternalrearanchor,twogrips/branches,
  elbowsUP,bent→extended,bandoutsidehead/back,noshoulderpress/crop.
- [x] cw116:

```bash
test ! -e /tmp/opencode/cw116-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw116-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw116-trial-01 --exercise-id cw116 --single-sunburst-medium
convert /tmp/opencode/cw116-trial-01/cw116-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw116-trial-01/review-512.png
```

- [x] Review116: horizontalbands,2DBpronated,extendabovechest→elbowsflareoutside
  hands/weightsinwardchest,notJM/skullcrusher/ordinarypress,supportedhead/feet.
- [x] cw117:

```bash
test ! -e /tmp/opencode/cw117-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw117-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw117-trial-01 --exercise-id cw117 --single-sunburst-medium
convert /tmp/opencode/cw117-trial-01/cw117-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw117-trial-01/review-512.png
```

- [x] Review117: seatedfullbody,forearmsONthighs/wristsBEYONDknees,2smallDBs,
  SUPINATIONbothphases,onlyWRISTextensiondown→palmarflexionup,readable512.
- [x] cw118:

```bash
test ! -e /tmp/opencode/cw118-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw118-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw118-trial-01 --exercise-id cw118 --single-sunburst-medium
convert /tmp/opencode/cw118-trial-01/cw118-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw118-trial-01/review-512.png
```

- [x] Review118: same seatedsupports,PRONATIONbothphases,onlyWRIST
  palmarflexiondown→dorsalextensionup,noelbowcurl/fingerrolling,readable512.
- [x] cw119:

```bash
test ! -e /tmp/opencode/cw119-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw119-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw119-trial-01 --exercise-id cw119 --single-sunburst-medium
convert /tmp/opencode/cw119-trial-01/cw119-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw119-trial-01/review-512.png
```

- [x] Review119: 2weightsatSidesboth,LEFTlead→RIGHTlead,truewalkingcontacts,
  uprightbody/longarms,notstatic/suitcase/shrug/run,no time/distanceproof.

Corrections: nameddefect,lastrejectedPNGONLY,newprompt/output,readsource/preview.
After2failedsameissue stopthatcomposition and evaluate new one,not blindrepeat.
User instructed continue to correctresult; retain sequentialreview/costdiscipline.
Providererror/uncertainty:ledgerinspect,noautomaticretry,unknowncostseparate.

## Task3: Reuse and integration

- [x] Re-read cw043 and verifyapprovedreuse; verifydestinationdirectory/newpaths.

```bash
cp assets/exercises/cw043.webp assets/exercises/cw120.webp
cmp assets/exercises/cw043.webp assets/exercises/cw120.webp
```

- [x] Convert5acceptedPNGs. BelowtrialpathsONLYifaccepted;substituteactual
  acceptedcorrectionpaths forrejectedtrials:

```bash
convert /tmp/opencode/cw115-trial-01/cw115-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw115.webp
convert /tmp/opencode/cw116-trial-01/cw116-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw116.webp
convert /tmp/opencode/cw117-trial-01/cw117-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw117.webp
convert /tmp/opencode/cw118-trial-01/cw118-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw118.webp
convert /tmp/opencode/cw119-trial-01/cw119-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw119.webp
```

- [x] Readfinal6WebP,512×512,frames2/2/2/2/2/1,cmpreusepass.
- [x] Add aftercw114 beforecw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw115',
  'cw116',
  'cw117',
  'cw118',
  'cw119',
  'cw120',
```

## Task4: Green

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-24-verified .
docker run --rm fit-web:batch-24-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass,analysis0issues,versioncheckpass,186exactIDs/assets,512decode,
fallbackcw121,format0changes.

## Task5: Documentation and close

- [x] Update docs/exercise-illustrations-status.md186local/78published/
  108unpublished07–24/130missing/316. Sixrows with exactnames/specframes.
- [x] Add “Dwudziesta czwarta partia” before rules: realpaths/layouts/reviews,
  corrections,Tateinterpretation,WRISTmovementexceptions,walkphases,reusezeroAPI.
- [x] Readledgers,successonly/deduprequest_id/costsum,nodoublecountresponse_received;
  unknownerrorsseparate,estimatekindnotproviderbilling.
- [x] Recordexecution/spec/plan,earlierhistorypreserved,directnotindependentreview.
- [x] Final186matchingregistry/test/files/statustable,scopedstatus andchecks:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expectedcleandiff,production1.9.0build22,APIstatusok;packagelocal/unpublished.

## Self-review

All6IDs/5newscenes/1reuse covered. Tateinterpretation and wristmotionexplicit;
hold1frame/walk2steps,no staticproofcounts. Red-green186contract/fallback121,
review/cost/errorrules andpreviousworkpreservationincluded.

## Execution record — 2026-10-15

- Accepted sources: trial-01 for cw115/cw116/cw118, new-correction-01 for
  cw117, new-01 for cw119, byte-identical cw043.webp for cw120 (cmp passed).
- Cw117: two rejected corrections of raised forearms, new more lateral
  composition with supported forearms, one correction restoring bottom
  supination. Cw118 support clarified before initial call; accepted first try.
- Cw119: two ineffective corrections of repeated lead leg, then new FRONT
  camera showing left lead then right lead. No local mirroring/reordering.
- Tate interpreted as approved: elbows outside hands, pronated grips, weights
  inward to chest. Wrist motion explicit for cw117/118, not elbow curl.
- Source and 512px preview read before next paid call; final six WebP read
  after resize512/strip/quality90 (reuse copied without recompression).
  Direct spec→quality reviews, not independent after earlier subagent limit.
- Red: only missingcw115 contract failure,365other tests pass, analysis0issues.
  `/root/.local/share/opencode/tool-output/tool_13e96af82001kMjdkJMHfpndiL`.
- Green:366tests passed,analysis0issues,version check pass,2Dartfiles format
  0changes. `/root/.local/share/opencode/tool-output/tool_13eaf3d36001pdW40eXnQwoKfF`.
  Registry/test/files186IDs, fallbackcw121,512decode. Status186/78/108/130/316.
- Read12successledgers,unique request_id,no double-count response_received,
  noHTTPerrors. 7sources/newcompositions+5corrections,0.276504USD
  upper_bound_no_cache estimate, notproviderbilling. Itemized table in spec.
  ZeroAPIcalls for cw120. Package local/unpublished, production1.9.0+22.
- Final checks: git diff --check clean; scoped status reviewed;186matching IDs
  in registry/test/assets/status table, fallbackcw121; cmpreusepassed.
  Publicversion1.9.0build22;APIhealth statusok.
