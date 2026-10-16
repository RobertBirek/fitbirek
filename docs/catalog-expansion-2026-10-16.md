# Rozszerzenie katalogu i wyszukiwanie — wynik 2026-10-16

## Stan

**363 ćwiczenia i363 ilustracje**, w tym47 nowych cw317–cw363.
Rozszerzenie przygotowano do wydania **1.12.0+25** i wypchnięto na main.
**Wdrożenie wstrzymane przed backupem/promocją**: automatyczna retencja
usunęłaby najstarszy istniejący backup, wbrew zakazowi czyszczenia.
Produkcja pozostaje1.11.0+24 z316 ćwiczeniami. Dowody i pozostałe kroki:
[raport wydania](releases/2026-10-16-web-1.12.0-25.md).

## Katalog i sprzęt

- 16 ćwiczeń z sandbagiem za uchwyty,3 z podwójnym kółkiem,16 pozycji jogi,
  8 ruchów kalistenicznych,4 przygotowawcze/ruchowe tai chi siedzące.
- Bez karate. Liczbę zmniejszono z orientacyjnych56 zamiast tworzyć dublety
  lub dodawać niezweryfikowane warianty. Regresje kółka przy ścianie/krótki
  zakres i progresje zawarto w opisach, nie jako sztuczne osobne ID.
- Sandbag i Kółko do brzucha są osobnymi opcjami sprzętu. Sandbag20kg to
  posiadany sprzęt użytkownika, nie narzucony ciężar każdej serii; kółko nie
  ma zakładanych pasków do stóp ani mechanizmu wspomagającego powrót.
- Wszystkie pola cw001–cw316 zachowane. Źródłem pozostaje XLSX, eksport przez
  tools/xlsx_to_json.py; walidacja obejmuje integralność historycznego prefiksu.
- Pełna lista nowych pozycji, URL źródeł, ograniczenia i odtwarzanie:
  [tools/CATALOG_EXPANSION.md](../tools/CATALOG_EXPANSION.md).
- Jawny indeks offline zawiera6 stylów i21 grup mięśni z oddzielnymi rolami
  główne/wspierające; pokrywa wszystkie363 ID.

## Baza ćwiczeń

- Wyszukiwanie po PL/EN, stylach, sprzęcie, mięśniach i aliasach, bez
  rozróżniania wielkości liter/diakrytyków; taichi oraz tai chi równoważne.
- Wielowyrazowa fraza wymaga dopasowania każdego tokenu.
- OR wewnątrz grupy filtrów, AND między grupami. Mięśnie główne i wspierające
  wspólnie kwalifikują ćwiczenie; role są widoczne w szczegółach.
- Opcje i liczniki reagują na pozostałe filtry i frazę; własna grupa jest
  pomijana przy obliczaniu jej opcji, umożliwiając rozszerzenie wyboru OR.
- Opcje zerowe niezaznaczone ukryte; zaznaczone pozostają usuwalne. Reset
  usuwa także widoczny tekst wyszukiwania; chipy wyborów widoczne poza sheetem.
- Jawne loading/error. Przy niedostępnym indeksie filtry klasyfikacji są
  tymczasowo pomijane z komunikatem, a wybory zachowane. Filtry podstawowe
  nadal działają. Rekordy custom/legacy korzystają ze stabilnych aliasów mięśni.

## Serie i synchronizacja

- Powtórzenia dla ruchów, sekundy dla utrzymań/pracy ciągłej i rund; ręczny
  wpis czasu lub stoper. Masa własna bez wymuszania kilogramów.
- Dla pozycji jednostronnych jawny wybór Lewa/Prawa/Obie; właściwy ostatni
  wynik i oznaczenie strony w podsumowaniu.
- Drift7→8: addytywne nullable side zCHECK left/right/both. Stare serieNULL
  bez backfillu. Pole przenoszone przez JSON, backup/restore i sync.
- Backend przechowuje payload wJSONB; nie wymaga migracji Alembic ani zmiany
  produkcyjnego API. Testy potwierdzają push/pull i duplicate retry.
- Nie przepisuje się już próbowanych payloadów outboxa.
- **Ograniczenie:** automatyczne PR dla jawnych stron (takżeObie) są wyłączone,
  żeby nie mieszać ich z rekordami historycznymi bez wymiaru strony. Wyniki
  są normalnie zapisywane. UI informuje o ograniczeniu; PR per strona to osobny
  zakres migracji. Szczegóły: [tracking](modules/workout-catalog-tracking.md).

## Ilustracje i koszty

47 nowych źródeł; wszystkie finalne WebP512×512, strip, quality90. Odczyt
źródła1024 i podglądu512 przed kolejnym płatnym żądaniem; finalne pliki
identyczne z zaakceptowanymi podglądami. Stylem bazowym pozostaje cw256.

Źródła zaakceptowane: trial-01 poza cw320/cw349/cw355/cw357/cw361
correction-01 i cw327new-01. Korekty i kadry opisuje
[status ilustracji](exercise-illustrations-status.md#rozszerzenie-katalogu--cw317cw363).
Prompty/PNG/ledgery poza repozytorium w /tmp/opencode.
**55 sukcesów z unikalnymi request_id**,0 błędów HTTP/niepewności:
47 prób bazowych,7 korekt i1 nowa kompozycja. Sumowano wyłącznie success,
nie response_received drugi raz. Szacunek upper_bound_no_cache:
**1,219730 USD** — nie rozliczenie dostawcy.

## Weryfikacja

- `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:catalog-expanded-verified .`:
  **399 testów klienta zaliczonych, analiza0, kontrola wersji poprawna**.
  Log: `/root/.local/share/opencode/tool-output/tool_1446ba48a001nlfbK2V7pkrF57`.
- `backend/.venv/bin/python -m pytest -q` z backend/: **336 testów zaliczonych**.
- `tools/tests/test_catalog_pipeline.py`: **23 testy zaliczone**, checki
  workbook/eksport/mapa nazw/metadata/źródła poprawne.
- Dodatkowe4 testy integracyjne używają prawdziwych assetów, nie fixture:
  wszystkie363 klasyfikacje,16 sandbag, przecięcie hantle+biceps (również
  wspierający), wyszukiwanie jogi/taichi/kółka.
- Formatowanie32 zmienionych/nowych Dartów:0 zmian; git diff --check poprawny.
- Build finalnego lokalnego Nginx: `fit-web:catalog-expanded-local`.
  Sprawdzono363 wpisy manifestu, bajty każdego WebP, faktyczne umieszczenie
  katalogu i indeksu offline oraz niezmienione WebSQLite. JS skompilowany.
- Świeżo wygenerowane Drift/Freezed/JSON zgodne bajtowo z working tree.
- Niezależny review kodu: dwa ustaleniaMEDIUM poprawione, recheck zamknięty
  bez pozostałych konkretnych blockerówHIGH/MEDIUM w ocenionym zakresie.
  Przegląd grafiki był bezpośredni, nie niezależny.

Nie zmieniano zależności, wersji Flutter/Dart, istniejących obrazów ani ID.
Nie wykonywano zmian infrastruktury lub produkcyjnych danych.

## Weryfikacja wydaniowa 1.12.0+25

- Nowy build `fit-web:release-1.12.0-25-candidate`, target runtime:
  kontrola wersji poprawna, analiza0 problemów, **399 testów Flutter**.
  Log: `/root/.local/share/opencode/tool-output/tool_144f27351001mEfg1PWUGBdOw1`.
- Ponownie **336 testów backendu** oraz **23 testy pipeline’u**; wszystkie
  kontrole XLSX/eksport/nazwy/metadane/źródła poprawne.
- Formatowanie33 zmienionych/nowych Dartów:0 zmian. Świeże wygenerowane
  modele, baza i AppVersion zgodne bajtowo z plikami przeznaczonymi do commita.
- Finalny Nginx: wersja1.12.0, build25, dokładnie363 wpisy manifestu i WebP;
  katalog, metadane i Web SQLite zgodne bajtowo; bootstrap/JS/worker obecne.
- Audyt porównał historyczne dane i obrazy316 z niezmiennym `f136ff1`.
  Nie zmieniono zależności ani toolchainu Flutter3.35.4/Dart3.9.2.
- Dwa ustaleniaMEDIUM poprzedniego review są zamknięte (patrz wyżej);
  etap wydania nie dodaje nowych funkcji PR, presetów filtrów ani timera.
