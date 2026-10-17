# Cloud browser acceptance — 2026-10-17

## Wynik

Wykonano rzeczywisty Chromium E2E na dwóch niezależnych kontekstach C1/C2
konta X, z aktualnym lokalnym FastAPI i PostgreSQL 16. Potwierdzono rzeczywiste
ACK, **3 konflikty CAS** (2 główne i 1 uzupełniający), konwergencję kolekcji,
osobne historie/PR, checkpoint guided i zachowanie tombstone’ów.
Nie potwierdzono błędu aplikacji w wykonanych przypadkach. Izolacja X/Y jest
**UNTESTED**: Y nie istnieje, oficjalny initial-account CLI odmawia drugiego konta.

## Środowisko i metoda

- Origin wszystkich nawigacji i logowania: **https://localhost**.
- Browser network namespace: `container:fit-cloud-accept-20261017-3a79f6c9-web`.
  Web/API/Postgres nie miały opublikowanych portów hosta; po akceptacji testowy
  stack posprzątano (szczegóły na końcu raportu).
- Obraz web: `sha256:e25b29c3ab64c48e74fbf8cf68e21aeaa6e45dc280dcddf80698e2d3dd86c007`.
- Faktycznie pobrany `main.dart.js`: SHA256
  `eb8774e5c9f7bfd1d8177a4bbd22c1706c12508633f6a03a91a308c0e1918f93`.
- API image: `sha256:5c9bf38690ccca463c627eda8aa6dd62afd6d915cf72c44882f8e7e1d3403ef7`.
  Handoff `verification.json` potwierdza zgodność z bieżącymi źródłami backendu,
  PostgreSQL/Alembic `0010`; identyfikatory uruchomionych obrazów sprawdzono ponownie.
- Browser image `fit-guided-browser-test:20261017`, Chromium **140.0.7339.16**;
  lokalny Drift **12**, inspekcja istniejącego fallback IDB `fitbirek_v2/blocks`.
- Realny `fetch /api/auth/login` w każdym kontekście, następnie rzeczywisty session
  i UI. Sprawdzono Secure/HttpOnly/SameSite=Strict cookie sesji. Credentials wyłącznie
  z zamontowanego read-only `account-X.json`; bez utrwalania cookies, HAR i trace logowania.
- `ignore_https_errors` wyłącznie w izolowanych kontekstach testowego originu.
  W końcowym harnessie origin guard i API gate są jedną regułą routingu.
- Offline oznacza abort prawdziwych żądań `/api`, nigdy fulfill/stub/ACK mock.
  Service workers blokowane dla deterministycznego API gate; to nie test PWA cache.
- Seed zapisuje wyłącznie stare SharedPreferences przed pierwszym bootstrapem.
  Bieżąca DB/outbox były tylko odczytywane przez readonly IDB i SQLite w RAM.
  Wszystkie edycje domenowe wykonano przez UI, w tym rzeczywisty onboarding X.
- Oczekiwanie na SELECT/outbox/deferred i konkretne UI; interwały 100–200 ms tylko
  w ograniczonym pollingu/przewijaniu. Sam `networkidle` nie stanowił dowodu sync.
- Readonly obserwator API `context.request.get(sync/pull)` działał poza API gate;
  jego wynik nie był wstrzykiwany do aplikacji ani traktowany jako ruch app sync.

## Macierz wyników

| Przypadek | Status | Dowód / zakres |
|---|---|---|
| Niezależne C1/C2, real login i runtime | PASS | Różne `sync_state.device_id`, wspólne prawdziwe konto X; hash JS, schema 12. |
| Migracja legacy X | PASS | Jeden UUID `a1700000-0000-4000-8000-000000000001`, created/updated = epoka UTC; marker X po imporcie, źródło nietknięte, marker drugiego klucza nieobecny. |
| Brak ponownego importu po reload/sync | PASS | Jeden wpis per UUID, następnie jeden tombstone, także po dwóch cyklach i świeżym kontekście. |
| Wczytanie migrowanych filtrów w UI | PASS, uzupełnienie | V3: identyczne legacy filtry pod nowym UUID `…000003`, `LEGACY LOAD TEST`: query cw012, strength + Hantle, wynik 1. Oryginalnego `LEGACY X` w C1 nie wczytano przed usunięciem — ten dokładny krok UNTESTED. |
| Równoległe dodatki offline | PASS | C1: ACC A + OFFLINE C1; C2: ACC B + OFFLINE C2. Lokalne commity/outboxy, brak nowych wariantów na serwerze przed reconnect. |
| C1 ACK → C2 rzeczywisty CAS/merge → konwergencja | PASS | Konflikt base 3 / remote 4; nowy operationId na base 4, ACK v5; oba warianty i oba presety w obu DB i rzeczywistym pull. |
| Guided selected variant + durable reload | PASS | Ten sam UUID sesji, fields/wybór A i szkic 12×5; sesje, serie, PR i lokalny outbox bez zmian od reload/resume. |
| Osobne historie/PR A/B/base, cw012, NULL side | PASS | A: 2 serie/2 PR; B: 1/1; base: 1/1. UUID oraz wartości lokalne porównane między klientami i z payloadami rzeczywistego API. |
| Zakończenie i summary | PASS | Cztery rzeczywiste serie dodatkowe, etykiety snapshot ACC A/B, bez duplikacji przez guidance. |
| Stale snapshot vs usunięcie A/legacy | PASS | C2 offline ma pending unrelated preset ze starymi live A/legacy; C1 commituje oba tombstone’y; CAS base 6 / remote 8; merge/ACK v9 zachowuje usunięcia i nowy preset. |
| Jednocześnie pending nowy wariant i preset vs delete | PASS, uzupełnienie | V2 offline tworzy ACC D PENDING + PENDING VARIANT DELETE; V1 usuwa ACC C + STALE C2; CAS base 13 / remote 15, ACK v16; nowe wpisy i stare/nowe tombstone’y pozostają. |
| Historia usuniętego A nadal czytelna | PASS | Cztery serie/PR nietknięte; nowe V1/V2 pokazują dwie pozycje PR ACC A, mimo braku A w live details. B pozostaje live. |
| Fresh context + legacy seed bez resurrection | PASS | C2prime oraz później V1/V2 z pustymi storage i seedem: UUID `…000001` pozostaje tombstone, brak LEGACY X w UI, marker true, źródło nienaruszone. |
| Izolacja rzeczywistych kont X/Y | UNTESTED | Y nieutworzone; drugi klucz był jedynie sentinelowym account ID, nie tożsamością Y. Nie tworzono users w DB. |

## Konkretne tożsamości i wyniki

- VA / ACC A: `50f5ebd9-64f1-468d-a38a-11fd627facb6`.
- VB / ACC B: `349d4d6b-f1ec-4cef-be37-b52b47b68500`.
- Sesja guided: `caf6cc65-4a45-4bf3-bafe-8bb52375d9eb`.
- A: 12×5 → 1RM 14; 12×6 → 14.4. B: 5×5 → 5.833333333333334.
  Bazowy: 3×5 → 3.5. Wszystkie SQL `side IS NULL`, bazowy `variant_id IS NULL`.
- Zmiana A→B z `Zachowaj` zachowała A; `Zastąp` przełączyło B i domyślny ciężar 20.
- Po końcowym uzupełnieniu trzy nowe konteksty V1/V2/V3 miały zgodne kolekcje,
  profil v16, puste outbox/deferred oraz nadal 4 serie i 4 PR. Skalary profilu zachowane.

### HTTP / CAS

Główne konflikty C2 zwrócono jako HTTP **200** z niepustym `conflicts`, nie HTTP 409:

1. `4298302e-856b-4d24-9ca4-1991071fb6e4`, base 3 / remote 4;
   nowa operacja merge `cf3b9a24-a350-4069-96b3-eef01c7fdb6e`, base 4, ACK v5.
2. `4546c393-ffc3-41cb-8059-ad3b8f5d9adf`, base 6 / remote 8, końcowy ACK v9.
3. Uzupełniający V2: base 13 / remote 15, końcowy ACK v16.

Snapshot końcowego audytu (liczniki ruchu browser, bez późniejszych logoutów i bez
readonly obserwatora API): login 204 ×6; session 200 ×262; pull 200 ×201;
push 200 ×25; push/status 200 ×88; mentor/settings 403 ×9. Ostatnie 403 dotyczą
nieaktywnego w tym teście obszaru mentora; nie były odpowiedziami sync ani mockiem.
Surowe logi sync zawierają rzeczywiste payloady/odpowiedzi, bez nagłówków sekretów.

## Odtworzenie i uwagi o przebiegu

1. Użyć stacka i konta X z handoff, dwóch pustych kontekstów, seedować legacy
   SharedPreferences X + drugi sentinel, zalogować realnym API; onboarding przez UI.
2. Doprowadzić oba klienty do pustych outbox/deferred. Offline API w obu, utworzyć
   warianty A/B i różne presety; C1 online/ACK, potem C2 online/CAS/merge, pull C1.
3. Guided z filtra spine; przez SPA dodać cw012 jako extra. Wybrać A, ustawić 12×5,
   poczekać na checkpoint SELECT. Reload → Kontynuuj → Wznów; sprawdzić fields/UUID.
4. Zalogować A 12×5, B 5×5, base 3×5, A 12×6; zakończyć, sprawdzić summary i PR;
   synchronizować i porównać sync UUID oraz payloady.
5. C2 offline/pending unrelated preset, C1 delete A i legacy. **Poczekać na oba
   commity tombstone w SELECT przed nawigacją**; ACK C1, reconnect C2/CAS, pull C1.
6. Puste nowe konteksty + ten sam seed: tombstone znanego legacy UUID nie może
   odrodzić się. W uzupełnieniu powtórzono też równoczesny pending wariant+preset
   versus delete na innych UUID (ACC C/STALE C2).

Pierwsza próba delete nawigowała przed zakończeniem asynchronicznego zapisu;
nie dostarczyła dowodu tombstone i została powtórzona z pollingiem commitów.
Dlatego nowy ACC C był już zsynchronizowany przy skutecznym usunięciu A; silniejszy
przypadek pending wariant+preset sprawdzono osobno w uzupełnieniu.

Flutter semantyka po resume chwilowo pokazała niedostępny wariant, zanim provider
się załadował; później prawidłowo pokazała A. Semantyczny input nieaktywnego pola
może mieć pustą wartość DOM: po kliknięciu faktyczny ciężar wynosił 12, reps 5;
screenshot i checkpoint potwierdziły oba pola. Nie uznano tych obserwacji za bug.
Korekty harnessu obejmowały też hash routes, zamykanie/nawigację dialogów i scroll
virtualizowanych szczegółów. Nie zmieniono aplikacji.

Pierwszy efemeryczny kontener browser zniknął po zapisaniu głównych dowodów;
przyczyna nieustalona. Odczyty końcowe UI wykonano w kolejnym własnym kontenerze,
w nowych V1/V2/V3. Nie jest to dowód crasha aplikacji. Nie sprawdzono wariantu
„legacy import przed pierwszym pull” — świeże konteksty potwierdzają wynik końcowy.

## Artefakty

Katalog: `/tmp/opencode/cloud-browser-20261017/`.

- `verification.json`, `http.json`: główne asercje, rzeczywiste konflikty i ruch HTTP.
- `baseline-*.json`, `offline-C*.json`, `offline-server.json`, `C1-first-ack.json`,
  `C2-merged-ack.json`, `C1-converged.json`, `converged-server.json`.
- `draft-before-reload.json`, `draft-after-resume.json`, `resumed-focused.png`,
  `resumed-focused.aria.txt`: checkpoint/reload i faktyczny formularz 12×5.
- `history-*.json`, `summary.png`, `summary.aria.txt`, `progress.png`,
  `PR-A-history.aria.txt`: serie, PR, summary i rzeczywiste API.
- `tombstones-*.json`, `reload-cycle*.json`, `fresh-legacy-*`,
  `verified-final-*.json`: delete, kolejne cykle, świeża migracja, quiescence.
- `final-ui/`: screenshoty i ARIA usuniętego A/legacy oraz zachowanej historii,
  `legacy-loaded-query-and-filters.*`, `legacy-load-result.json`,
  `pending-variant-delete-*.json`, `final-audit.json`, `final-summary.json`,
  `identities.json`, osobny `http.json` z uzupełnień.
- Tymczasowy harness: `runner.py`, `control.py`, `actions.py`, `history.py`,
  `verify.py` oraz skrypty uzupełnień w `final-ui/`. To interaktywny harness;
  instrukcje powyżej opisują kolejność, a nie obietnicę jednego polecenia replay.

Jedyny nowy artefakt repo tego zadania to niniejszy raport. Własne kontenery
przeglądarki zakończono. Bez release, commita, generatorów, zmian źródeł aplikacji
i zmian produkcji.

## Sprzątanie po akceptacji

2026-10-17 o 09:18:50 UTC zakończono `docker compose down --volumes` wyłącznie
dla tymczasowego stacka `fit-cloud-accept-20261017-3a79f6c9` (kod 0).
Kontrola po operacji: zero jego kontenerów, sieci i wolumenów. Nie używano `prune`
ani nie usuwano zasobów produkcyjnych. Zachowano obrazy, dowody przeglądarkowe,
handoff i pliki diagnostyczne; pliki sekretów pozostały z uprawnieniami 0600.
Dowody: `cleanup.log`, `cleanup-result.json` i status `CLEANED` w `HANDOFF.md`
w katalogu `/tmp/opencode/local-cloud-acceptance-20261017-3a79f6c9/`.

W tym samym środowisku przygotowania wcześniej wykonano pełny backend suite:
**373 passed in 469.40s** (Python 3.12.3, hash-locked dependencies,
PostgreSQL 16 przez Testcontainers). Nie był to ponowny przebieg podczas cleanupu;
`backend-pytest-373.transcript.log` jest oznaczoną transkrypcją stdout wyniku
narzędzia, a nie oryginalnym logiem zapisanym przez pytest.
