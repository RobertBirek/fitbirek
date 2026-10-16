# Domknięcie ilustracji cw157–cw250 — plan wykonania

**Zgoda:** użytkownik zatwierdził samodzielny wybór scen i korekt dla wszystkich
94 brakujących ilustracji, bez kolejnych potwierdzeń. Kontynuacja w /opt/fit,
z zachowaniem lokalnych Partii 28–30 i istniejących zasad technicznych.

**Cel:** 316 ilustracji dla 316 ćwiczeń; 204 wydane, 112 lokalnych niewydanych.

**Projekt:** Sunburst medium, styl cw256, PNG1024 → WebP512 quality90 strip.
Sceny wynikają z katalogowych wskazówek. Jeden kadr dla statycznego utrzymania,
dwa dla prostego ruchu, trzy/cztery dla sekwencji lub naprzemiennych faz.
Ta sama kamera/skala i stałe podpory w ramach ćwiczenia. Bez napisów,
strzałek i timerów; tempo/tętno/liczba obrotów pozostają w opisie katalogowym.
Reuse wyłącznie przy zgodności ruchu/sprzętu/wariantu, jawnie odnotowany.

**Realizacja bezpośrednia:** nie uruchamiać subagentów. Żądania pojedynczo;
źródło i podgląd512 odczytać przed kolejnym żądaniem. Korekty nazwanych wad
z ostatnim odrzuconym PNG jako jedyną referencją, w świeżym katalogu.
Błąd API: odczytać ledger, nie ponawiać automatycznie, nieznany koszt osobno.

## Kroki

- [x] Sprawdzić katalog i potwierdzić brakujące cw157–cw250 (94).
- [x] Dla kolejnych ćwiczeń zapisać dokładny prompt poza repozytorium,
  wykonać jedno żądanie tools/benchmark_exercise_images.py
  --single-sunburst-medium, ocenić PNG1024 i podgląd512.
- [x] Akceptowane źródło skonwertować przez
  `convert SOURCE -resize 512x512 -strip -quality 90 assets/exercises/cwNNN.webp`.
  Odczytać finalny WebP; zapisać źródło, kadry i ocenę w rejestrze wykonania.
- [x] Integrować kolejne ukończone zakresy w
  lib/features/exercises/presentation/exercise_illustrations.dart i
  test/features/exercises/exercise_illustrations_test.dart, aktualizować
  docs/exercise-illustrations-status.md. Nie zmieniać katalogu ćwiczeń ani ID.
- [x] Po pełnej integracji uruchomić
  `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:illustrations-complete .`
  i format check dwóch zmienionych Dartów; oczekiwane 366 testów/analiza0.
- [x] Porównać 316 ID katalog/rejestr/test/assety/tabela, dekodowanie512,
  sprawdzić git diff --check i koszty success deduplikowane request_id.
- [x] Uzupełnić dokumentację wyniku. Bez commita/pusha/wersji/wdrożenia
  bez osobnej prośby. Nie deklarować działania w tle po zakończeniu sesji.

## Wynik

Wszystkie94 pozycje uzupełnione:87 nowych źródeł i7 zgodnych reuse.
Szczegóły scen/odstępstw i adaptacji:
`docs/superpowers/specs/2026-10-15-exercise-illustrations-completion-results.md`.
115 żądańsuccess/unikalnychrequest_id,0błędów, szacunek2.549335USD.
Pełny Docker green:366testów/analiza0/kontrolawersjiOK, log
`/root/.local/share/opencode/tool-output/tool_141d83e80001biO0U9xvWXpFpL`.
Po poprawieniu samego formatowania castu:format2plików0zmian, focused14/14.
Audyt316 zgodnychID,204 wydaneassetybez zmian,94dodane512×512,
git diff --check czysty; publicversion1.10.0+23 iAPIhealthok.
Stan316/204/112/0/316, zmiany lokalne zachowane w /opt/fit.
