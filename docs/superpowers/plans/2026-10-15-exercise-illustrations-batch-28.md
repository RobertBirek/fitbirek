# Exercise Illustrations Batch 28 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate six approved cw139–cw144 illustrations.

**Architecture:** Exact registry/asset contract red first. Generate individual
sources and read each source/512px preview before next paid call. Integrate
accepted WebP set and restore full client suite green; direct reviews.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved spec: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-28-design.md`.
Read AGENTS.md/docs/modules/training.md. Current /opt/fit main, preserve all
released assets and history. Baseline204/204/0/112/316,target210/204/6/106/316.
Create assets/exercises/cw139.webp throughcw144.webp. Modify registry,
test/features/exercises/exercise_illustrations_test.dart,status and batch docs.
No catalog/model/dependency/WebSQLite/version/commit/push/deployment changes.

## Task1: Red contract

- [x] Inspect scoped status and preserve existing work.
- [x] Add aftercw138 beforecw251 in expectedIllustrationIds:

```dart
    'cw139',
    'cw140',
    'cw141',
    'cw142',
    'cw143',
    'cw144',
```

- [x] Set fallback `expect(exerciseIllustrationAsset('cw145'), isNull);`.
- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-28-red .
```

Expected missingcw139 exactregistry failure only,365otherpass,analysis0issues.

## Task2: Prompts and sequential generation

- [x] Verify /tmp/opencode/referencePNG. Write6promptfiles
  /tmp/opencode/cw139-trial-01-prompt.txt throughcw144-trial-01-prompt.txt,
  each full commonblock+respective scene from spec “Sześć promptów bazowych”.
- [x] Review spec→geometry: freebentleg139,sissy140raisedheels/straightbody,
  actualwallcontact/90knees141/142,onegoblet142/143,fixedheelscossack,
  bothfeetAIR144/floorconstant/landingkneesbent.

Run separately,timeout>=240seconds,fresh exclusiveoutput,parentverify.
Read source and512preview before next paidcall,no secrets/rawpayload logs.

- [x] Generate139:

```bash
test ! -e /tmp/opencode/cw139-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw139-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw139-trial-01 --exercise-id cw139 --single-sunburst-medium
convert /tmp/opencode/cw139-trial-01/cw139-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw139-trial-01/review-512.png
```

- [x] Review139:2bands,rightsolefixed,leftbentbehindFREE,kneeclosefloor,
  notpistol/reverselunge,armsforward,no leftfoot/kneesupport.
- [x] Generate140:

```bash
test ! -e /tmp/opencode/cw140-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw140-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw140-trial-01 --exercise-id cw140 --single-sunburst-medium
convert /tmp/opencode/cw140-trial-01/cw140-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw140-trial-01/review-512.png
```

- [x] Review140:2bands,bothforefeetgrounded/heelsUP,rightfixedhandpost,
  kneesforward/straightknees-hips-headlineback,no hiphinge/kneeling.
- [x] Generate141:

```bash
test ! -e /tmp/opencode/cw141-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw141-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw141-trial-01 --exercise-id cw141 --single-sunburst-medium
convert /tmp/opencode/cw141-trial-01/cw141-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw141-trial-01/review-512.png
```

- [x] Review141:1frame,back/pelvisWALL,thighshorizontal,knees90aboveankles,
  armscrossed/notthighsupport,no chair/timer.
- [x] Generate142:

```bash
test ! -e /tmp/opencode/cw142-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw142-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw142-trial-01 --exercise-id cw142 --single-sunburst-medium
convert /tmp/opencode/cw142-trial-01/cw142-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw142-trial-01/review-512.png
```

- [x] Review142:1frame,wall/90geometry,1verticalDBchest,bothpalmsunderhead,
  no weightonthighs/secondDB/chair/timer.
- [x] Generate143:

```bash
test ! -e /tmp/opencode/cw143-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw143-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw143-trial-01 --exercise-id cw143 --single-sunburst-medium
convert /tmp/opencode/cw143-trial-01/cw143-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw143-trial-01/review-512.png
```

- [x] Review143:3bands,rightlow→centerhigh→leftlow,fixedwideHEELanchors,
  workingfullsole/freeheeltoesmayUP,1goblet,no step/mirror.
- [x] Generate144:

```bash
test ! -e /tmp/opencode/cw144-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw144-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw144-trial-01 --exercise-id cw144 --single-sunburst-medium
convert /tmp/opencode/cw144-trial-01/cw144-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw144-trial-01/review-512.png
```

- [x] Review144:3columns,squat→BOTHfeetflight→bentlanding,constantfloor/scale,
  headroom,nottiptoestand/tuckjump/turn,shadowandairgap.

Correctionrules:nameddefect,lastrejectedPNGONLY,freshprompt/output,readsource/
previewbeforenextcall. After2failedsameissue stopcomposition andassessnewone,
continue tocorrectresult peruser,no blindrepeats. Providerfailure/uncertainty:
retainledger/path,noautomaticretry,unknowncostseparate,nosecretlogs.

## Task3: Integration

- [x] Confirm all6acceptedpaths/newdestinations. Trialpaths below ONLY if
  accepted;substituteactualacceptedcorrectionpaths:

```bash
convert /tmp/opencode/cw139-trial-01/cw139-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw139.webp
convert /tmp/opencode/cw140-trial-01/cw140-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw140.webp
convert /tmp/opencode/cw141-trial-01/cw141-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw141.webp
convert /tmp/opencode/cw142-trial-01/cw142-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw142.webp
convert /tmp/opencode/cw143-trial-01/cw143-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw143.webp
convert /tmp/opencode/cw144-trial-01/cw144-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw144.webp
```

- [x] Readfinal6WebP512×512,frames2/2/1/1/3/3.
- [x] Add aftercw138 beforecw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw139',
  'cw140',
  'cw141',
  'cw142',
  'cw143',
  'cw144',
```

## Task4: Green

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-28-verified .
docker run --rm fit-web:batch-28-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass,analysis0issues,versioncheckpass,210exactIDs/files,512decode,
fallbackcw145,format0changes.

## Task5: Record/close

- [x] Status210local/204published/6unpublished28/106missing/316,sixrows,
  “Dwudziesta ósma partia” before rules. Preserve release1.10.0+23 evidence.
- [x] Recordactualsources/reviews/corrections/sissyinterpretation,grip/support
  exceptions,greenlogs;directnotindependentreviewafterearlierquota.
- [x] Readledgers,successonly/uniquerequest_id/costsum,notdoublecountresponse_received,
  unknownfailuresseparate,estimatekindnotbilling.
- [x] Final210matchingregistry/test/files/status,scopedstatus and:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expectedcleandiff,production1.10.0build23,APIstatusok;batchlocalunpublished.

## Self-review

All6scenescovered,2/2/1/1/3/3frames,sissy/jumpheelruleexceptions,staticwall
holds,fixedcossackheels,red-green210contract/fallback145,cost/errorrules explicit.

## Execution record — 2026-10-15

- Accepted: cw139-correction-01,cw140-correction-01,cw141-trial-01,
  cw142-trial-01,cw143-trial-01,cw144-trial-01 under /tmp/opencode.
- Cw139 correction deepened rear knee descent while freeleg remained airborne.
  Cw140 correction restored horizontalbands (trial had side-by-side) and
  fixedhandanchor; approved interpretation bothforefeet/raisedheels/post.
- Other four firsttries accepted. Hold1frame each,142chestheldgoblet,
  cossackright-center-left/fixedheels, jump3columns/samefloor/flight/softlanding.
- Each source and512preview read before nextcall, allfinal6WebP read after
  resize512/strip/quality90; frames2/2/1/1/3/3,no reuse or local transformations.
  Direct spec→quality review, not independent after earlier subagentlimit.
- Red: missingcw139 only,365other tests pass,analysis0issues; log
  `/root/.local/share/opencode/tool-output/tool_140224706001s2dqfwpsSj1L6Q`.
- Green:366pass,analysis0issues,versioncheckpass,2Dartfiles format0changes;
  log `/root/.local/share/opencode/tool-output/tool_1403c7499001LSNHSVAKUtKzGj`.
  Registry/test/files210IDs,512decode,fallbackcw145,status210/204/6/106/316.
- Read8successledgers,unique request_id,no doublecountresponse_received,
  noHTTPerrors.6sources+2corrections,total0.185311USD upper_bound_no_cache
  estimate,not providerbilling. Itemized table in spec.
- Release1.10.0+23 evidence/history and publishedassets preserved. No catalog,
  model/dependency/WebSQLite/version/Git/deployment changes. Batchlocalunpublished.
- Final checks:git diff --check clean,scopedstatus reviewed,210matchingIDs in
  registry/test/files/status table,fallbackcw145; publishedassets/version/catalog/
  lockfile/WebSQLite unchanged. Publicversion1.10.0build23,APIhealth statusok.
