# Illustration Batch 01 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Autonomicznie przygotować, ocenić, zintegrować i wydać ilustracje `cw252`, `cw251`, `cw253` i `cw262` w pojedynczym wydaniu webowym.

**Architecture:** Każde ćwiczenie pozostaje pojedynczym WebP 512×512 z panelami wymaganymi przez specyfikację pierwszej partii. Wyniki płatnych prób i ledgery są izolowane w kolejnych katalogach `/tmp/opencode/<id>-trial-XX`; zaakceptowane PNG są konwertowane lokalnie, a rejestr Dart oraz test kontrolują dokładne dopasowanie plików i ID.

**Tech Stack:** OpenAI Images edits `gpt-image-2.5-sunburst` medium, ImageMagick, Flutter 3.35.4/Dart 3.9.2, Docker web runtime.

---

### Task 1: Wygenerować i ocenić cztery assety

**Files:**
- Create outside repository: `/tmp/opencode/{cw252,cw251,cw253,cw262}-trial-XX/*`
- Reference: `assets/exercises/cw256.webp`
- Specification: `docs/superpowers/specs/2026-10-09-exercise-illustrations-design.md:35-47`

- [ ] **Step 1: Przygotować osobny prompt i katalog dla każdej próby**

Użyć `cw256.webp` jako jedynej referencji stylu, PNG 1024×1024, trzech
równych pionowych paneli tylko gdy wymagane przez scenę, bez tekstu, numerów,
strzałek i znaków wodnych. Zapisać prompt obok wyniku w nowym katalogu próby.

- [ ] **Step 2: Wykonać pojedyncze żądanie Sunburst medium**

Run dla każdego ID:

```bash
python3 tools/benchmark_exercise_images.py \
  --prompt /tmp/opencode/<id>-trial-XX/prompt.txt \
  --reference /tmp/opencode/cw256-reference.png \
  --output-dir /tmp/opencode/<id>-trial-XX \
  --exercise-id <id> \
  --single-sunburst-medium
```

Oczekiwane: dokładnie jeden PNG i ledger z `started`, `response_received`,
`success`. Każdy inny status kończy daną próbę bez retry tego samego katalogu.

- [ ] **Step 3: Ocenić każdy wynik**

Wymagania scen:

- `cw252`: dwa kadry, siad na piętach z szerokimi kolanami → tułów między udami
  i wyprostowane ręce; pomarańcz na widocznych najszerszych/prostownikach
  grzbietu i pośladkach, bez wymuszonego turkusu.
- `cw251`: dwa kadry, leżenie na brzuchu → cobra z dłońmi pod barkami,
  wyprostowanymi ramionami i miednicą na podłodze; pomarańcz na prostym brzucha
  oraz widocznym piersiowym, turkus tylko na widocznych aktywnych prostownikach,
  tricepsie i zębatym przednim.
- `cw253`: dwa kadry, plank → downward dog; pomarańcz na widocznych
  kulszowo-goleniowych, łydkach i najszerszych; turkus wyłącznie na widocznych
  tricepsach, zębatych, stabilizatorach łopatek i brzuchu. Pięty mogą pozostać
  nad podłogą.
- `cw262`: dwa kadry, prosta noga z piętą na niskiej ławce → skłon z bioder z
  długim neutralnym kręgosłupem; pomarańcz na kulszowo-goleniowych uniesionej
  nogi, turkus tylko na widocznym pośladkowym średnim nogi podporowej i
  prostownikach grzbietu.

Odrzucić obraz przy złym ruchu, anatomii, sprzęcie, mapie mięśni, kadrze,
stylu albo błędzie technicznym. Zmienić wyłącznie scenę/prompt adresujący
udokumentowaną wadę; maksymalnie pięć prób, potem nowe przeprojektowanie i
kolejna pula do pięciu prób. Nie pomijać ID.

### Task 2: Dodać tylko zaakceptowane assety przez TDD

**Files:**
- Create: `assets/exercises/{cw252,cw251,cw253,cw262}.webp`
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart`
- Modify: `test/features/exercises/exercise_illustrations_test.dart`
- Modify: `docs/exercise-illustrations-status.md`

- [ ] **Step 1: Dopisać testy RED**

Dodać cztery ID do `expectedIllustrationIds`, po jednym teście mapowania i po
jednym teście dekodowania `512×512` według wzorca `cw278`, bez modyfikowania
rejestru ani assetów.

- [ ] **Step 2: Uruchomić Docker verification i potwierdzić RED**

Run:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-01-red .
```

Oczekiwane: błędy wyłącznie brakujących ID/assetów czterech nowych ilustracji.

- [ ] **Step 3: Dodać assety i minimalny rejestr GREEN**

Konwertować tylko zaakceptowane PNG:

```bash
convert /tmp/opencode/<id>-trial-XX/<id>-gpt-image-2.5-sunburst-medium.png \
  -resize 512x512! -quality 90 assets/exercises/<id>.webp
```

Rozszerzyć `illustratedExerciseIds`, status wydanych zasobów i liczbę
pozostałych tylko o faktycznie zaakceptowane assety.

- [ ] **Step 4: Uruchomić Docker verification i potwierdzić GREEN**

Run:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:batch-01-green .
```

Oczekiwane: `flutter analyze` oraz cały `flutter test` kończą się powodzeniem.

### Task 3: Wydać zaakceptowaną partię webową

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/app/app_version.g.dart`
- Create: `docs/exercise-illustrations-release-2026-10-10-batch-01.md`

- [ ] **Step 1: Podnieść patch i numer buildu**

Po integracji czterech assetów zmienić `1.4.7+14` na `1.4.8+15`; uruchomić
generator wersji w obrazie Fluttera i jego `--check`.

- [ ] **Step 2: Wykonać finalne verification i runtime candidate**

Uruchomić pełny Docker verification, wykonać backup, zachować aktualny web pod
unikalnym tagiem rollback, zbudować target `runtime`, sprawdzić `version.json`
i obecność wszystkich czterech WebP.

- [ ] **Step 3: Promować tylko web i zweryfikować publicznie**

Oznaczyć zaakceptowany candidate jako `fit-web:production`, uruchomić Compose z
base + push + mentor tylko dla `web`, a następnie publicznie sprawdzić
`/version.json`, `/api/health` i każdy nowy WebP (200, `image/webp`, 512×512).

- [ ] **Step 4: Udokumentować i zatwierdzić wydanie**

Zapisać koszt i wynik prób, checksumy, backup, tag rollback oraz wynik kontroli
publicznej. Commit ma obejmować wyłącznie assety zaakceptowane w tej partii,
rejestr, testy, wersję i raport wydania.

## Przegląd planu

Plan ogranicza każde płatne wywołanie do jednej audytowalnej próby, wymusza
osobną kontrolę sceny na ID, kontrolę RED/GREEN rejestru i pojedyncze,
odwracalne wdrożenie webowe. Nie modyfikuje katalogu ćwiczeń, bazy, synchronizacji,
API, migracji, Compose ani Caddy.
