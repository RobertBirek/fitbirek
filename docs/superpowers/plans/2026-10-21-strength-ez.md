# Strength EZ Implementation Plan

> **For agentic workers:** use subagent-driven-development; independent catalog,
> image and private-pack work has separate file ownership.

**Goal:** Przygotować katalog EZ i zatwierdzone osobiste szablony siłowe/cardio.
**Architecture:** Odtwarzalne dopisanie XLSX→JSON→metadata, jawny rejestr obrazów;
osobny prywatny pakiet planów i reguł przez istniejące kontrakty synchronizacji.
**Tech Stack:** Flutter 3.35.4 / Dart 3.9.2, Python, istniejący FastAPI/Drift.
**Spec:** `docs/superpowers/specs/2026-10-21-strength-ez-design.md`.

## Global Constraints

- Nie zmieniać starych 408 rekordów, ID i ilustracji.
- Bez migracji, zależności, zmiany toolchainu, zgód i poświadczeń.
- Bez zapisu osobistych planów z nowymi ID przed publikacją właściwego katalogu.
- Publikacja/merge/push i promocja wymagają potwierdzenia użytkownika.
- Nie zakładać wieku z niejednoznacznego opisu stażu karate.

## Review Focus

1. Odtwarzalność z 408-wpisowego XLSX i ochrona całego historycznego prefiksu.
2. EZ/ławka wymagane w obu generatorach, ustawieniach i filtrach.
3. Chwyty i anatomia w ilustracjach; stare pliki identyczne bajtowo.
4. Uczciwa estymacja czasu, tracking, jednostronność i brak arbitralnych kg.
5. Tylko jednoznaczna wymiana wieczornej reguły; poranki i karate bez zmian.

## Task 1: Katalog, sprzęt i integracja klienta

- [x] TDD: nowe ID 409–412, sprzęt, niezmienność prefiksu i idempotentny replay.
- [x] Dopisać dane źródłowe i źródła techniki, odtworzyć XLSX/JSON/metadata.
- [x] Rozszerzyć opcje sprzętu, rejestr ilustracji i testy pokrycia do 412.
- [x] Uruchomić testy danych/focused Flutter oraz niezależny review.

Wynik Task 1: 53 testy katalogu i 53 focused Flutter PASS; kanoniczny runtime
zaliczył 1348 testów i analizę. Niezależny review CLEAR. Pełny Python discovery
nie jest GREEN: w catalog venv brakuje playwright dla test_push_browser.

## Task 2: Cztery ilustracje

- [x] Zapisać prompty, wygenerować pojedynczo w dotychczasowym stylu.
- [x] Obejrzeć PNG i finalne WebP512; korekty tylko nazwanych wad.
- [x] Zachować ledgery i koszt; niezależny przegląd nowych obrazów.

Wynik Task 2: cztery obrazy, cztery żądania success, szacunek 0.094613 USD.
Niezależny przegląd wszystkich czterech obrazów: brak HIGH/MEDIUM. Audyt
dekodowania 412 WebP512 i niezmienności 408 starych plików PASS. Ograniczenie:
dalsza dłoń na kierownicy jest częściowo zasłonięta perspektywą.

## Task 3: Prywatny pakiet siłowy/cardio

- [x] Sprawdzić reguły 18:00 i zachować pozostałe wpisy.
- [x] TDD: przygotować plany A/B/C, garaż i osobne cardio; bez zapisu produkcyjnego.
- [x] Sprawdzić kodeki Dart, tracking, czas i atomowy CAS w dwóch sesjach.

Wynik Task 3: siedem szablonów w prywatnym dry-pack-v3.json; A/B/C mają
63:30 / 55:24 / 59:27. Własne 19 testów PASS, rzeczywisty CAS dwóch sesji,
review CLEAR po dodaniu warunków uchwytu/siły dla neutralnego podciągania.
Finalny pakiet v3 przeszedł kodeki Dart; własne 19 testów powtórzono z PASS.
Nie utworzono osobistego journala; apply pozostaje bezwarunkowo zablokowane.

## Task 4: Końcowa weryfikacja i przekazanie

- [x] Pełna analiza/Flutter tests i kanoniczny build, testy danych, review katalogu.
- [x] Podać gotowy zakres i poprosić o potwierdzenie publikacji katalogu,
  następnie backup/restore, promocja i zapis osobistych planów.
- [x] Nie przedstawiać lokalnego katalogu/pakietu jako już działającego na koncie.

Końcowy przegląd całości CLEAR dla lokalnego kandydata. Publikacja, backup
wydania, zmiana ogólnej reguły 18:00 i zapis nowych planów nadal NIEWYKONANE;
uzyskały już osobne potwierdzenie użytkownika „tak” (2026-10-21), a wykonanie
publikacji i zapisu jest w toku. Szczegóły artefaktu i ograniczeń:
`docs/releases/2026-10-21-web-1.20.0-36-candidate.md`.

## Ustalenia wykonawcze

- Ruling: dodać cw412 i sprzęt „Rower stacjonarny” — katalog zawiera bieżnię
  i skakankę, lecz nie rowerek. Inne ćwiczenie nie może udawać jazdy na rowerze.
  Koszt decyzji: jedna dodatkowa pozycja, ilustracja i testy; bez nowej funkcji.
- Ruling: praca w dotychczasowym /opt/fit z rozdzielonym właścicielstwem plików,
  bez commita/pusha/merge. Repo było czyste, a lokalne narzędzia i ścieżki źródłowe
  są związane z tym katalogiem. Zmiany podlegają przeglądowi przed publikacją.
- Ruling: niedziela bez obowiązkowego terminu 18:00 jest częścią zatwierdzonego
  tygodnia regeneracyjnego; usunięcie ogólnej reguły codziennej nie usuwa historii.
- Ruling: pierwotny pakiet miał tylko około 4 min rozgrzewki i 3 min zakończenia,
  stąd A/B/C 51:02 / 42:56 / 46:59 zamiast zatwierdzonej około godziny. Uzupełnić
  rzeczywiste lekkie ćwiczenia przygotowawcze do około 9 min oraz spokojne
  zakończenie do około 10 min, zgodnie z przyjętymi widełkami. Nie zwiększać
  serii roboczych, ciężarów ani fikcyjnego czasu pracy/przerw. Koszt: więcej
  bloków mobilności i rozluźnienia; można świadomie skrócić je przy braku czasu.
