# Exercise Illustrations Batch 23 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Locally integrate approved cw109–cw114 illustrations.

**Architecture:** Extend exact asset contract first and confirm red. Generate
five sources individually with source/512px review before the next request;
reuse cw002 bytes for cw110. Integrate all six and restore full suite green.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 in Docker.

---

## Context/files

Approved design: `docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-23-design.md`.
Read AGENTS.md, docs/modules/training.md. Work in current /opt/fit main;
preserve unpublished Parts07–22. Direct review after earlier quota exhaustion,
not independent. Baseline174/78/96/142/316,target180/78/102/136/316.
Create assets/exercises/cw109.webp throughcw114.webp. Modify registry,
test/features/exercises/exercise_illustrations_test.dart and status document.
No catalog/model/dependency/WebSQLite edits, version/commit/push/deployment.

## Task1: Red contract

- [x] Inspect scoped Git status and preserve all prior work.
- [x] Add aftercw108 beforecw251 in expectedIllustrationIds:

```dart
    'cw109',
    'cw110',
    'cw111',
    'cw112',
    'cw113',
    'cw114',
```

- [x] Set fallback assertion `expect(exerciseIllustrationAsset('cw115'), isNull);`.
- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-23-red .
```

Expected only missingcw109 exact registry failure, analysis0issues,365otherpass.

## Task2: Prompts and sequential generation

- [x] Verify /tmp/opencode and cw256-reference.png; write five prompts to
  cw109-trial-01-prompt.txt and cw111-trial-01-prompt.txt through
  cw114-trial-01-prompt.txt under /tmp/opencode. Each contains full common
  block plus respective approved scene in design “Pięć promptów bazowych”.
- [x] Direct spec→geometry review: horizontal upper arm109, hand/heel supports,
  thigh-supported dumbbell112, JM elbow lowering113, high anchor114.

Run each command separately, timeout>=240seconds; source and512px must be read
and accepted/rejected before next paid request. Verify output parent, fresh
exclusive directory. Do not print secrets or raw provider payload.

- [x] cw109 generation:

```bash
test ! -e /tmp/opencode/cw109-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw109-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw109-trial-01 --exercise-id cw109 --single-sunburst-medium
convert /tmp/opencode/cw109-trial-01/cw109-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw109-trial-01/review-512.png
```

- [x] Review109: right workingarm,oneDB,upperarmhorizontal,torso45degrees,
  elbowfixed,forearmdown→extendedback,empty left hand on leftthigh,no row.
- [x] cw111 generation:

```bash
test ! -e /tmp/opencode/cw111-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw111-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw111-trial-01 --exercise-id cw111 --single-sunburst-medium
convert /tmp/opencode/cw111-trial-01/cw111-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw111-trial-01/review-512.png
```

- [x] Review111: two horizontal bands,onebench,both palms/fingerstowardfeet,
  straightlegs,heelsfloor,samecontacts,hipsclosetobench,elbowsabout90low.
- [x] cw112 generation:

```bash
test ! -e /tmp/opencode/cw112-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw112-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw112-trial-01 --exercise-id cw112 --single-sunburst-medium
convert /tmp/opencode/cw112-trial-01/cw112-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw112-trial-01/review-512.png
```

- [x] Review112: same dips supports,onecompactDB acrossproximal thighs,
  weightactualcontact inboth,not handholding/thirdarm/floating/legpenetration.
- [x] cw113 generation:

```bash
test ! -e /tmp/opencode/cw113-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw113-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw113-trial-01 --exercise-id cw113 --single-sunburst-medium
convert /tmp/opencode/cw113-trial-01/cw113-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw113-trial-01/review-512.png
```

- [x] Review113: twoDBneutralgrips,gapallowed,highabovechest→lowbychin,
  elbowsbendANDlower,moderate45flare,not fixedverticalskullcrusher/ordinarypress,
  returnendsabovechestnotpelvis,head/body/feet supported.
- [x] cw114 generation:

```bash
test ! -e /tmp/opencode/cw114-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw114-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw114-trial-01 --exercise-id cw114 --single-sunburst-medium
convert /tmp/opencode/cw114-trial-01/cw114-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw114-trial-01/review-512.png
```

- [x] Review114: visiblefixedhighfrontanchor,oneband/twobranches/twogrips,
  elbowsatsides90→straightdown,shouldersstill,tautcontinuousbandoutsidebody.

Corrections: name defect, only last rejected PNG reference, freshprompt/output,
read source/preview before nextcall. After2failedcorrectionssameissue stop that
composition and assess new one. Providerfailure: preserveledger/path, noauto
retry,unknowncostnotzero. User authorized continuing to correct result in prior
batch; do not repeat ineffective composition or accept incorrect geometry.

## Task3: Reuse and integration

- [x] Re-read cw002 and verify approvedreuse. Verify asset directory and new
  destinations, then copy without conversion:

```bash
cp assets/exercises/cw002.webp assets/exercises/cw110.webp
cmp assets/exercises/cw002.webp assets/exercises/cw110.webp
```

- [x] Once all5new sources accepted, convert using actual accepted paths.
  Below commands apply if trial-01 accepted; substitute acceptedcorrectionpath
  for any rejected trial, do not integrate rejected PNG:

```bash
convert /tmp/opencode/cw109-trial-01/cw109-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw109.webp
convert /tmp/opencode/cw111-trial-01/cw111-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw111.webp
convert /tmp/opencode/cw112-trial-01/cw112-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw112.webp
convert /tmp/opencode/cw113-trial-01/cw113-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw113.webp
convert /tmp/opencode/cw114-trial-01/cw114-gpt-image-2.5-sunburst-medium.png -resize 512x512 -strip -quality 90 assets/exercises/cw114.webp
```

- [x] Read sixfinalWebP,verify512×512/2frames,cmpreuse.
- [x] Add aftercw108 beforecw251 in
  lib/features/exercises/presentation/exercise_illustrations.dart:

```dart
  'cw109',
  'cw110',
  'cw111',
  'cw112',
  'cw113',
  'cw114',
```

## Task4: Green verification

- [x] Run timeout>=1200seconds:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-23-verified .
docker run --rm fit-web:batch-23-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected all366tests/analysis/versioncheckgreen,180exactIDs/files,512decode,
fallbackcw115,format0changes. No unrelatedcatalog/dependency/WebSQLitechanges.

## Task5: Documentation and close

- [x] Update status counts180local/78published/102unpublished07–23/136missing/316.
  Add6rows with exact names from design,2frames,locallyintegrated/unpublished.
- [x] Add “Dwudziesta trzecia partia” before rules: actualacceptedpaths/reviews,
  corrections/layouts/variants,zeroAPIreusecw110,cw113interpretation,greenlog.
- [x] Read allledgers,successonly/uniquerequest_id/costsum;response_receivednot
  countedagain.Unknownerrorsseparate,upper_bound_no_cacheestimate notbilling.
- [x] Record execution in spec/plan,allprevioushistorypreserved.
- [x] Finaldirectasset/integrationreview,180matchingregistry/test/files/status,
  scopedGitstatus,productionversion/health,and:

```bash
git diff --check
curl --fail --silent --show-error https://fit.birek.online/version.json
curl --fail --silent --show-error https://fit.birek.online/api/health
```

Expectedcleandiff,production1.9.0build22,APIstatusok;packageunpublished.

## Self-review

All6IDs/5newscenes/reuse covered;red-green exactcontract;180-IDcounts/fallback
consistent;geometry/cost/errorrules explicit;directreviewnotindependent;no
version/Git/deploymentsteps. Five completepromptblocks in approvedspec.

## Execution record — 2026-10-15

- Red confirmed only missingcw109 exactregistry contract;365other tests passed,
  analysis0issues. Log:
  `/root/.local/share/opencode/tool-output/tool_13e5a4a8c001Afa6rZBFeNTPF7`.
- Accepted sources: cw109-correction-01, cw111-new-01, cw112-trial-01,
  cw113-new-correction-02, cw114-trial-01, all under /tmp/opencode.
  cw110 is byte-identical copy of cw002, cmp passed, zeroAPI requests.
- Kickback correction fixed droppingelbow. Dips two failed sideview corrections
  followed by new frontfoot-end3/4 showing bothpalm supports. Before firstcw112
  call used same frontcamera; thighweight/supports accepted withoutcorrection.
- JM press: two rejected oldview corrections, new elevated foot-end camera,
  two further corrections separating parallel weightaxes/actualneutralgrips.
  Interpretation45degrees/footwardreturn as approved, catalogunchanged.
- Direct source/512px review before each nextcall;final6WebP read after
  resize512/strip/quality90 (cw110 copied without recompression). Each2frames,
  horizontal111–113,side-by-side109/110/114. No independent subagentreview.
- Integrated IDs109–114, fallback115. Full Docker green:366tests passed,
  analysis0issues,versioncheckpass,format2Dartfiles0changes. Log:
  `/root/.local/share/opencode/tool-output/tool_13e71e0d60019bPctAEs4CySLa`.
- All14success ledgers read, unique request_id, response_received not counted
  twice, no HTTPerrors. 7sources/newcompositions + 7corrections, total0.321043USD
  upper_bound_no_cache estimate, notbilling. Itemized cost table in spec.
- Status updated180local/78published/102unpublished/136missing/316.
  Previous packages preserved; package local/unpublished, production1.9.0+22.
- Final checks: git diff --check clean, scoped status reviewed,180matching IDs
  across registry/test/files/status, fallbackcw115, cmpreusepassed.
  Publicversion1.9.0build22 and APIhealth statusok.
