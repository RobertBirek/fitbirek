# Single Image Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dodać bezpieczny tryb jednego żądania Sunburst medium i użyć go do kontrolowanych prób cw257 oraz cw264; odnotować odrzuconą próbę cw278.

**Architecture:** Istniejący runner benchmarku zachowuje domyślne trzy konfiguracje. Jawna flaga CLI wybiera wyłącznie pierwszą, już zdefiniowaną konfigurację `gpt-image-2.5-sunburst` / `medium`; ledger, blokada istniejącego katalogu, brak ponowień i filtracja danych odpowiedzi pozostają bez zmian.

**Tech Stack:** Python 3 standard library, OpenAI Images edits API, `gpt-image-2.5-sunburst`, ImageMagick do lokalnej konwersji WebP→PNG, Flutter assets WebP.

---

## Zakres i bramki

- Nie uruchamiać płatnego żądania przed przejściem testów Task 1 i ręcznym
  zatwierdzeniem scenariusza danego ćwiczenia.
- Użyć osobnego, wcześniej nieistniejącego katalogu `/tmp/opencode/<id>-trial-01`
  dla każdego ID. Nigdy nie wznawiać katalogu po błędzie lub timeoutcie.
- Próby cw257 i cw264 wykonujemy kolejno. Po każdej oceniamy obraz i ledger;
  odrzucony wynik nie trafia do `assets/`. Pojedyncza próba cw278 została
  odrzucona i jest odroczona do przeprojektowania sceny.
- Status serii, styl i opublikowane zasoby opisuje
  `docs/exercise-illustrations-status.md`.

## Task 1: Tryb pojedynczego żądania

**Files:**
- Modify: `tools/benchmark_exercise_images.py:108-190`
- Modify: `tools/tests/test_benchmark_exercise_images.py:39-99,115-141`

- [ ] **Step 1: Napisać test RED trybu pojedynczego**

Rozszerzyć pomocnik testowy o parametr `single=False` i przekazać flagę tylko
gdy jest ustawiony:

```python
def run_benchmark(self, transport, single=False):
    argv = ['--prompt', str(self.prompt), '--reference', str(self.reference),
            '--output-dir', str(self.out), '--exercise-id', 'cw265']
    if single:
        argv.append('--single-sunburst-medium')
    with patch.object(self.mod, 'send_request', side_effect=transport), \
            patch.dict('os.environ', {'OPENAI_API_KEY': 'SECRET-KEY'}), \
            contextlib.redirect_stdout(io.StringIO()) as stdout, \
            contextlib.redirect_stderr(io.StringIO()) as stderr:
        code = self.mod.main(argv)
    return code, stdout.getvalue(), stderr.getvalue()
```

Dodać test:

```python
def test_single_sunburst_medium_makes_one_audited_request(self):
    bodies = []
    def transport(request):
        self.assertEqual(self.ledger()[-1]['status'], 'started')
        bodies.append(request.data)
        return self.response()

    code, stdout, stderr = self.run_benchmark(transport, single=True)

    self.assertEqual((code, stderr), (0, ''))
    self.assertEqual(len(bodies), 1)
    self.assertIn(b'gpt-image-2.5-sunburst', bodies[0])
    self.assertIn(b'medium', bodies[0])
    self.assertNotIn(b'gpt-image-2.5-flare', bodies[0])
    self.assertEqual(len(list(self.out.glob('*.png'))), 1)
    self.assertEqual(len(stdout.splitlines()), 1)
    self.assertEqual([event['status'] for event in self.ledger()],
                     ['started', 'response_received', 'success'])
    self.assertEqual(self.ledger()[-1]['configuration']['model'],
                     'gpt-image-2.5-sunburst')
    self.assertEqual(self.ledger()[-1]['configuration']['quality'], 'medium')
```

- [ ] **Step 2: Uruchomić test RED**

Run:

```bash
python3 -m unittest tools.tests.test_benchmark_exercise_images.BenchmarkTests.test_single_sunburst_medium_makes_one_audited_request -v
```

Expected: FAIL, ponieważ parser nie rozpoznaje `--single-sunburst-medium`.

- [ ] **Step 3: Zaimplementować minimalny wybór konfiguracji**

W `main()` dodać argument:

```python
parser.add_argument(
    '--single-sunburst-medium',
    action='store_true',
    help='make exactly one paid gpt-image-2.5-sunburst medium request',
)
```

W `run()` przed pętlą ustalić sekwencję:

```python
configurations = (
    CONFIGURATIONS[:1]
    if args.single_sunburst_medium
    else CONFIGURATIONS
)
```

Następnie zastąpić:

```python
for model, quality in CONFIGURATIONS:
```

przez:

```python
for model, quality in configurations:
```

Nie zmieniać endpointu, formatu ledgera, timeoutu, obsługi błędów ani
`CONFIGURATIONS`.

- [ ] **Step 4: Uruchomić test GREEN i regresję domyślnego benchmarku**

Run:

```bash
python3 -m unittest discover -s tools/tests -p 'test_benchmark_exercise_images.py' -v
```

Expected: PASS. Test trybu pojedynczego potwierdza jedno żądanie; istniejący
`test_three_sequential_requests_and_started_ledger` nadal potwierdza trzy
żądania bez flagi.

- [ ] **Step 5: Dodać test blokady katalogu także w trybie pojedynczym**

W `test_existing_directory_prevents_any_request` wywołać pomocnik drugi raz z
`single=True` i innym istniejącym `self.out`; transport nadal wywołuje
`self.fail('duplicate request')`. Oczekiwany kod to `1`, a istniejący plik
`user-file` ma pozostać niezmieniony.

- [ ] **Step 6: Uruchomić pełny zestaw i kontrolę stylu**

Run:

```bash
python3 -m unittest discover -s tools/tests -p 'test_benchmark_exercise_images.py' -v
python3 -m py_compile tools/benchmark_exercise_images.py
git diff --check
```

Expected: każdy kod wyjścia `0`.

## Task 2: Kontrolowana próba cw257

**Files:**
- Create outside repo: `/tmp/opencode/cw257-trial-01/prompt.txt`
- Create outside repo: `/tmp/opencode/cw256-reference.png`
- Create outside repo: `/tmp/opencode/cw257-trial-01/ledger.jsonl`

- [ ] **Step 1: Zapisać zatwierdzony prompt cw257**

Zapisać poniższy tekst do `/tmp/opencode/cw257-trial-01/prompt.txt`:

```text
Create one clean, single-frame exercise illustration for “Butterfly Stretch”,
using the attached cw256 image only as the visual style reference: cream
background, charcoal comic outlines, flat shading, the same anonymous athlete,
dark shirt and muted shorts. No text, labels, arrows or diagrams.

Show a full-body, comfortable seated butterfly position. The soles of both feet
touch in front of the pelvis without being forced into the groin. The athlete
lightly holds the feet or ankles, never the knees. Keep the torso upright, the
spine long and neutral, and the forward hinge between zero and five degrees.
Both knees open only in a natural comfortable range; show no downward pressure.
Use a slightly elevated front three-quarter camera, about 15–25 degrees off
center, with both feet, hands and medial thighs clearly separated at 512px.

Apply translucent orange only along both visible medial thigh muscle regions,
from the upper thigh to above each knee, for the adductors. Do not color the
groin, pelvis, hip joints, knees, feet or whole legs. Use no turquoise. Reject
any forced range, rounded back, extra limbs or departure from cw256 style.
```

- [ ] **Step 2: Przygotować referencję PNG poza repozytorium**

Run:

```bash
convert assets/exercises/cw256.webp /tmp/opencode/cw256-reference.png
```

Expected: PNG z poprawną sygnaturą; nie zmienia `cw256.webp`.

- [ ] **Step 3: Wykonać jedno żądanie**

Run tylko po załadowaniu klucza z zatwierdzonego źródła poza czatem:

```bash
python3 tools/benchmark_exercise_images.py \
  --prompt /tmp/opencode/cw257-trial-01/prompt.txt \
  --reference /tmp/opencode/cw256-reference.png \
  --output-dir /tmp/opencode/cw257-trial-01 \
  --exercise-id cw257 \
  --single-sunburst-medium
```

Expected: dokładnie jeden PNG, trzy wpisy ledgera (`started`,
`response_received`, `success`) i jedna linia kosztu. Przy `uncertain`,
`http_error`, `response_error` albo `image_error` zatrzymać serię bez retry.

- [ ] **Step 4: Obejrzeć i podjąć decyzję**

Odrzucić obraz, jeśli kolana są dociskane, kręgosłup jest zaokrąglony,
pomarańcz obejmuje pachwinę/stawy/kolana albo obraz zawiera turkus. Tylko
zaakceptowany wynik można później przekonwertować do WebP 512×512 i dodać do
repozytorium.

## Task 3: cw264 po akceptacji cw257; cw278 odroczone po odrzuceniu

**Files:**
- Create outside repo: `/tmp/opencode/cw264-trial-01/prompt.txt`

- [ ] **Step 1: Przeprowadzić cw264 po akceptacji cw257**

Zapisać do `/tmp/opencode/cw264-trial-01/prompt.txt` scenariusz dwóch równych
kadrów: anatomicznie lewa noga z tyłu, prawa z przodu, dłonie płasko na ścianie
na wysokości barków, identyczna kamera 3/4 z boku i z tyłu, cała sylwetka wraz
z piętą tylnej nogi. W pierwszym kadrze tylne kolano jest proste, a dokładnie
jeden pomarańczowy obszar obejmuje oba brzuśce brzuchatego łydki poniżej dołu
podkolanowego i powyżej przejścia mięśniowo-ścięgnistego. W drugim kadrze
wyłącznie tylne kolano jest ugięte; dokładnie jeden pomarańczowy obszar obejmuje
dolno-boczną masę płaszczkowatego przed ścięgnem Achillesa. Pięta tylnej nogi
pozostaje płasko na podłodze w obu kadrach. Zakazać turkusu, strzałek,
kolorowania ścięgien, stawów, kości i nerwów.

- [x] **Step 2: Odrzucić i odroczyć cw278 po jednej próbie**

Próba cw278 została odrzucona: guma przebiega z przodu w końcowym panelu.
Nie planować kolejnego żądania ani publikacji zasobu. Ćwiczenie wymaga
przeprojektowanego scenariusza przed ewentualną przyszłą próbą.

- [ ] **Step 3: Po każdej próbie sprawdzić ledger i obraz**

Nie kopiować obrazów do `assets/`, nie aktualizować rejestru Fluttera, nie
bumpować wersji i nie wdrażać przed osobną akceptacją użytkownika każdego
wyniku.

## Przegląd planu

Task 1 pokrywa dokładnie jedno płatne żądanie, utrzymuje trzyżądaniowy
benchmark bez flagi oraz testuje blokadę katalogu. Task 2 i Task 3 zachowują
sekwencję oceny, limit kosztu i rozdzielają robocze wyniki od aplikacji.
Plan nie obejmuje publikacji assetów ani zmian wdrożeniowych.
