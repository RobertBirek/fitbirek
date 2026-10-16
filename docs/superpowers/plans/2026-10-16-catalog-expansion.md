# Catalog Expansion Implementation Plan

**Goal:** rozszerzenie zatwierdzonego katalogu z wyszukiwaniem fasetowym i wynikiem dopasowanym do ćwiczenia.
**Architecture:** niezależne katalog/metadata, czyste funkcje filtrowania, addytywna zgodna reprezentacja strony serii.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Drift, FastAPI/PostgreSQL, XLSX→JSON.

- [x] Zapisać projekt docs/superpowers/specs/2026-10-16-catalog-expansion-design.md.
- [x] Katalog: test zachowania316 starych wpisów, nowe unikalneID/źródła,
  sprzętSandbag/Kółko do brzucha; rozszerzyć walidację konwertera i mapęnazw.
- [x] Indeks: offline asset zgodny z projektem, pełneID bez danglingreferencji;
  model i provider metadanych oddzielny od istniejącego Exercise.
- [x] Filtry: jednostkowe testy OR/AND, obu kierunków zawężania, supporting,
  aliasów/diakrytyki/query/counts; widget test zachowania wyborów i czyszczenia.
- [x] Wyniki: test starej serii bezstrony i roundtrip left/right/both w SQLite,
  backupie i sync; addytywna migracja jeśli wymagana, nie zmieniać starych.
- [x] UI sesji: jednostki reps/time/rounds, obciążenie opcjonalne, wybórstrony,
  poprzedniwynik dla właściwejstrony; testy skupione.
- [x] Ilustracje: zaakceptowanePNG/podgląd512 przed każdym kolejnym żądaniem,
  rejestr/test/assety zgodne; nie obniżać kontroli dla nowego sprzętu.
- [x] Regeneracja modeli Drift/Freezed tylko po zmianie ich deklaracji.
- [x] Docker verification: `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:catalog-expanded-verified .`.
- [x] Backend focused/full pytest jeśli backend zmieniony, gitdiffcheck,
  kontrola niezmienionychID/historii/ulubionych oraz dokumentacja wyniku.

## Wynik

47 nowych unikalnych ćwiczeń (16/3/16/8/4) po odrzuceniu duplikatów
i niezweryfikowanych wariantów;363 łącznie. Wszystkie47 nowe ilustracje.
55 unikalnychsuccess,szacunek1.219730USD,bezbłędów. Analiza0,399testówFlutter,
336backendu,23pipeline. Lokalny finalnyNginx skompilowany i sprawdzony363ID.
Ograniczenie: PRy jawnychstron wyłączone, patrz docs/modules/workout-catalog-tracking.md.
Raport: docs/catalog-expansion-2026-10-16.md. Bez wydania/commit/push.
