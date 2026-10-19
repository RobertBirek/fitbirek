# FitBirek — akceptacja przeglądarkowa kandydata C

## Wynik

**30 PASS / 0 FAIL / 5 NOTTESTED** w rzeczywistym Chromium, na finalnym
skompilowanym Flutter Web z service workerem, izolowanym FastAPI i PostgreSQL16.
Nie używano atrap logowania, odpowiedzi push/ACK, ręcznej edycji bazy ani
czyszczenia storage między aktualizacjami i restartami profili.

To akceptacja kandydata rozwojowego, **nie wydanie ani wdrożenie produkcyjne**.
Wersja pozostaje `1.15.0+28`; obrazy rozróżnia dokładna tożsamość poniżej.

## Artefakty

| Składnik | Tożsamość |
| --- | --- |
| Web runtime | `sha256:9c580e7cc4b885e56a433a1114ce5143236f1ed2e5378226a5e4600b9274ebf9` |
| API runtime | `sha256:e13f18be837acbf9348dbc173d26cb559cabf32fd05c5aec905343adbf087693` |
| Migration image | `sha256:0a5f6ee195275077c54637093bd91c5ddebc7666b290e9c1cf5c06f28e270853` |
| Offline packageId | `f0802fba5c7f49de41c64960bdfa2f0fdc97bc4a548311bcb202649ac44accf6` |

Pakiet offline: **443 pliki / 46 865 718 bajtów**. Cały runtime web: 448 plików
/ 47 011 293 bajty. Sprawdzono rozmiary, SHA256 i wyliczenie packageId.
Wszystkie 40 modułów produkcyjnego API w obrazie zgadzały się ze źródłami.

Obrazy zbudowano kanonicznymi Dockerfile. Web `runtime` zależy od pełnego
verification: **1053 testy Flutter PASS**, analiza bez uwag, kontrola wersji PASS.
Końcowy pełny backend: **448 PASS** (`.venv/bin/python -m pytest -q --tb=short`,
456,14 s), z rzeczywistym PostgreSQL Testcontainers.

Po buildzie zmieniono wyłącznie fixture w `backend/tests/test_apple_health.py`
(prawidłowe `data` i `wagaKg` zamiast niepełnego `weight`) oraz dokumentację.
Nie należy deklarować identyczności całego drzewa z manifestem buildu;
produkcyjne źródła kandydata pozostały zgodne.

## Scenariusze potwierdzone na C

- API C uruchomiono i sprawdzono przed webem C. Stara otwarta karta zachowała
  przypięcie B. Normalne zamknięcie Chromium i otwarcie tego samego profilu
  uruchomiło dokładny kod C; nie usuwano IndexedDB, cache ani cookies.
- Jasna nawigacja jest czytelna przy szerokościach 320/375/1280. Przy 375
  sprawdzono każdą z pięciu aktywnych zakładek; przy 320 „Ustawienia” jest
  skracane wielokropkiem. Zachowano kontrolny widok ciemny.
- Nowy ręczny pomiar utworzony przez UI zachował UUID i dokładną datę
  `2026-10-19T05:27:30.391Z`: create, ACK/restart, edycja online, edycja offline,
  DELETE; wersje API **1 → 2 → 3 → 4**. Niezależny profil potwierdził wartości.
- Anulowanie usunięcia zachowało pomiar. Potwierdzenie utworzyło tombstone;
  po synchronizacji i restartach obu profili rekord nie wrócił.
- Jawne przygotowanie offline osiągnęło **443/443**. Zatrzymano cały origin
  HTTPS, zamknięto proces przeglądarki i otwarto ten sam profil: działały UI,
  dane i ilustracja. Lokalna edycja pozostała w kolejce; po powrocie originu
  licznik przeszedł **1 → 0**, bez duplikacji na drugim urządzeniu testowym.
- Po wylogowaniu offline karty z prywatnymi Postępami i niezapisanym
  formularzem przeszły do logowania **bez reloadu**. Prywatna nawigacja była
  zablokowana, szkic nie został zapisany. Sam powrót originu nie przywrócił
  sesji; nowe jawne logowanie zadziałało.
- Nowy trening C: prawa strona, **13 kg × 8, RPE 7**, zapis serii, timer ±15 s,
  pominięcie przerwy i poprawne podsumowanie. Drugi profil nie wykazał duplikacji.
- Zachowany UUID wcześniejszego planu, działający widoczny skrót planera.
  Mentor prawidłowo prezentował brak konfiguracji; bez płatnego providera.

## Regresje wykryte i poprawione podczas akceptacji

1. **Kandydat A — druga karta po offline logout:** synchronizacja była
   zabezpieczona, lecz UI nadal pokazywało prywatne dane. AuthController
   obserwuje teraz trwałe powiązanie Drift, unieważnia intencje opóźnionych
   bootstrap/login/prepare i przekierowuje router. Stare `SyncService.stop()`
   nie może nadpisać nowej generacji. Potwierdzono na B i ponownie na C.
2. **Kandydat B — jasny pasek nawigacji:** domyślne `shifting` dla pięciu pozycji
   dawało białe elementy na jasnym tle. Jasny motyw ma jawne `fixed` i kolory
   semantyczne. Testy rasteryzowanego tła i screenshoty C potwierdzają naprawę.
3. **Kandydat B — precyzja daty pomiaru:** Drift przechowuje DateTime w sekundach,
   a pełny payload edycji nadpisywał milisekundy serwera. Nowy kontrakt omission
   zachowuje dokładne `measurement.data` z żywego rekordu serwera; create
   zachowuje datę z oczekującej operacji. Konflikt z tombstone'em ustanawia
   trwały hold zamiast pętli rebase. Szczegóły: [kontrakt sync](../../backend/SYNC_EXTENSIONS.md).

**Wymagana kolejność przyszłego wydania: API przed webem.** Stary backend nie
uzupełni daty pominiętej przez nowy klient. Rollback API do starego obrazu przy
aktywnych klientach C, również z cache, nie jest bezpieczną procedurą.
Poprawka nie odtwarza precyzji wcześniej utraconej w SQLite lub backupach.

## Screenshoty

Wybrane obrazy z syntetycznego konta, ręcznie przejrzane; bez danych logowania:

- [Jasne ustawienia, 320 px](candidate-c-light320.png)
- [Postępy, jasny motyw, 375 px](candidate-c-progress.png)
- [Ilustracja przy zatrzymanym originie](candidate-c-offline.png)
- [Podsumowanie nowej serii](candidate-c-summary.png)

Pełny zestaw: **96 PNG i 121 operacji**, odkażone logi, daty i snapshoty API:
`/tmp/opencode/audit-ui-sync-20261018T191431Z/recheck-ux-date-20261019T045728Z/`.
Podglądy formularzy logowania w pełnym zestawie mają celowo zamaskowane pola
kolorem magenta; nie jest to błąd renderowania aplikacji.

Pliki `ACCEPTANCE.md`, `evidence/results.json`, `evidence/date-check.json`
i `report.py` opisują dowody C. Dowody wcześniejszych A i B zachowano osobno,
włącznie z ich rzeczywistymi niepowodzeniami. Profile zawierają syntetyczne
dane i pozostają wyłącznie w chronionym katalogu roboczym, nie w repozytorium.

## Granice wyniku

Pięć jawnie niewykonanych scenariuszy:

1. Rzeczywiste skalowanie tekstu przeglądarki 200% — testowane widgetowo,
   nie przypisujemy tego wyniku screenshotom rzeczywistego PWA.
2. Rzeczywisty płatny dostawca Mentora.
3. Celowo zatrzymana i później uwolniona odpowiedź sieciowa po logout.
4. Konflikt wcześniej oczekującej edycji z tombstone'em w rzeczywistej
   przeglądarce — pokryty testami klienta, nie scenariuszem C.
5. Fizyczny iPhone/Android oraz VoiceOver/TalkBack.

Pozostają również oddzielne zadania audytu: retencja cache, pomiary wydajności,
automatyzacja akceptacji i odzyskiwanie poza hostem. Wynik C nie stanowi
akceptacji tych zadań ani zgody na pominięcie wersjonowania i procedury wydania.

## Zamknięcie środowiska

Po zapisaniu dowodów usunięto wyłącznie pięć kontenerów, wewnętrzną sieć
i testowy wolumen o dokładnym prefiksie `fit-audit-ui-sync-20261018T191431Z`.
Cleanup sprawdził etykiety i zachował wszystkie obrazy A/B/C oraz pliki
dowodów, profili i skryptów. Nie było publikowanych portów.

Produkcyjne kontenery Fit zachowały pełne ID, obrazy, czasy startu i liczniki
restartów; API/web/PostgreSQL pozostały healthy. Dowody:
`cleanup-before.json`, `cleanup-result.json` w katalogu C wskazanym powyżej.
Origin testowy nie jest już uruchomiony. Odtworzenie wymaga ponownego
przygotowania izolowanego środowiska i świeżej bazy; zachowane profile nie
zastępują usuniętej testowej bazy serwera.
