# Exercise Illustrations Batch 30 Implementation Plan

> **For agentic workers:** Use executing-plans task-by-task; checkboxes track execution.

**Goal:** Locally integrate approved cw151–cw156.

**Architecture:** Exact asset contract red first; sequential source/512px reviews,
then accepted WebP integration and full client verification. Direct reviews.

**Tech Stack:** Sunburst medium, ImageMagick, Flutter3.35.4/Dart3.9.2 Docker.

## Context

Approved spec: docs/superpowers/specs/2026-10-15-exercise-illustrations-batch-30-design.md.
Preserve current main /opt/fit, released assets and local batches28–29.
Baseline216/204/12/100/316; target222/204/18/94/316. No release/Git operations.

## Tasks

- [x] Extend expectedIllustrationIds aftercw150 beforecw251 with:

```dart
    'cw151',
    'cw152',
    'cw153',
    'cw154',
    'cw155',
    'cw156',
```

Set fallback `expect(exerciseIllustrationAsset('cw157'), isNull);`.
Run `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-30-red .`.
Expected missingcw151 only,365otherpass,analysis0issues.

- [x] Save six exact commonblock+scene prompts from approved spec to
  /tmp/opencode/cw151-trial-01-prompt.txt through cw156-trial-01-prompt.txt.
  Review spec→geometry: sumo lowheadgrip,closedband/upperback,actualankleblock,
  fixed floor bridge supports,weightpelviscontact,upperbackbench hipthrust.
- [x] Generate cw151; read source and512preview before next request.
- [x] Generate cw152; read source and512preview before next request.
- [x] Generate cw153; read source and512preview before next request.
- [x] Generate cw154; read source and512preview before next request.
- [x] Generate cw155; read source and512preview before next request.
- [x] Generate cw156; read source and512preview.

Each ID uses its corresponding exact prompt and fresh exclusive trial-01 dir:

```bash
test ! -e /tmp/opencode/cw151-trial-01 && set -a && source /root/.config/fit/openai.env && set +a && python3 tools/benchmark_exercise_images.py --prompt /tmp/opencode/cw151-trial-01-prompt.txt --reference /tmp/opencode/cw256-reference.png --output-dir /tmp/opencode/cw151-trial-01 --exercise-id cw151 --single-sunburst-medium
convert /tmp/opencode/cw151-trial-01/cw151-gpt-image-2.5-sunburst-medium.png -resize 512x512 /tmp/opencode/cw151-trial-01/review-512.png
```

For subsequent IDs substitute cw152,cw153,cw154,cw155,cw156 respectively in
all paths and exercise-id; each call separately,timeout240seconds. Never print
secrets. Corrections only nameddefects,lastrejectedPNG sole reference,freshdir.
After two ineffective corrections stop composition/assess new one. On provider
error/uncertainty inspect ledger,no automatic retry,unknowncost separate.

- [x] Convert six accepted sources to assets/exercises/cw151.webp–cw156.webp
  using `convert SOURCE -resize 512x512 -strip -quality 90 DESTINATION`.
  Use actual accepted source,never rejected trial. Read all six finalWebP.
- [x] Add same sixIDs aftercw150 beforecw251 to
  lib/features/exercises/presentation/exercise_illustrations.dart.
- [x] Full green:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-30-verified .
docker run --rm fit-web:batch-30-verified dart format --output=none --set-exit-if-changed lib/features/exercises/presentation/exercise_illustrations.dart test/features/exercises/exercise_illustrations_test.dart
```

Expected366pass,analysis0issues,versioncheckpass,222IDs/files,512decode,
fallbackcw157,format0changes.

- [x] Status222/204/18/94/316,sixrows and “Trzydziesta partia” before rules;
  preserve previous batches/release evidence. Record real sources/corrections/
  directnotindependentreviews and costs from success only,deduprequest_id,
  no doublecountresponse_received,upper_bound_no_cache estimate notbilling.
- [x] Final matchingregistry/test/files/statustable,scopedstatus,
  `git diff --check`,publicversion1.10.0build23 and APIhealth statusok.

## Self-review

Six scenes/2-2-3-2-2-2frames covered. No catalog/model/dependency/WebSQLite/
version/deployment changes. Direct review after earlier subagent quota limit.

## Execution evidence

Red log: `/root/.local/share/opencode/tool-output/tool_140939d8c001BKwXBsppQFeI8n`.
Green log: `/root/.local/share/opencode/tool-output/tool_140af9415001mYSMk7BeqJFhUg`:
version check passed, analysis0,366tests passed. Formatting2files0changes.
Accepted trial-01 for151/152/154/155; correction-01 for153/156.
Exact prompts saved outside repo are shorter equivalent scenes of approved
baseblocks; actual paths and deviations recorded in spec execution section.
Eightunique success request_ids, no errors; estimate0.180536USD.
Final registry/test/assets/status check:222 matchingIDs,fallbackcw157.
`git diff --check` passed; scoped status contains only local batches28–30.
Public version.json:1.10.0/build23; api/health:statusok.
