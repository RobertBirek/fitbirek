# Jawny powrót do sesji po reloadzie

## Przyczyna i zakres

Reprodukcja przeglądarkowa jest zachowana w
`docs/training-rhythm-browser-acceptance-2026-10-17.md`, sekcja „Osobna
nierozwiązana obserwacja: reload bezpośredniego URL”, obraz fixed
`d93e53313b83fb16316fe55498c65a76ef75c418ae22760179704c657ef2741e`.
Reload `/#/workout/session` tworzył pusty `ActiveWorkoutNotifier`. Trasa
renderowała pusty wybór z RAM, choć sesja i szkic nadal istniały w SQLite.
To nie była utrata guidance ani powrót błędu nawigacji harmonogramu.

Implementacja realizuje wyłącznie sekcję 1 zatwierdzonego
`docs/superpowers/specs/2026-10-17-offline-readiness-design.md`.
Punkt odniesienia: HEAD `e0fe9a6` **wraz z zastanymi niecommitowanymi**
repeat/schedule/trends i schematem Drift 13. Nie cofano tego stanu.

## Pliki i kontrakt

- `lib/features/workout/providers/session_recovery_provider.dart`: nowy,
  wyłącznie odczytowy `StreamProvider.autoDispose`. Jedno obserwowane zapytanie
  łączy aktywne, nieusunięte sesje, odblokowany binding `sync_state` i szkice
  danego konta. `readsFrom` obejmuje wszystkie trzy tabele, również zmiany
  z pull/DELETE. Szkic innego konta nie staje się lokalnym szkicem aktualnego.
- `lib/features/workout/presentation/widgets/session_recovery_panel.dart`:
  sprawdzanie, błąd odczytu/retry, pusty wynik, identyfikator i data sesji,
  jawny przycisk **Wznów trening** przy każdym poprawnym kandydacie.
  Wiele sesji wymaga wyboru; kolejność listy nie jest decyzją wznowienia.
- `active_session_page.dart`: pusty świeży stan pokazuje panel, nie „Wybierz
  ćwiczenia”. Nieaktywna sesja z już świadomie wybranymi ćwiczeniami zachowuje
  dotychczasowy ręczny formularz. Zakończenie jest ukryte na pustym recovery.
- `workout_providers.dart`: jedyna zmiana notifikatora to dodatkowe opcjonalne
  guardy `expectedAccountId`/`expectedAuthorityEpoch` w `resumeSession` oraz
  ponowna kontrola bindingu, UUID/row ID, finish/DELETE i guidance po zakończeniu
  transakcji odczytu. Anulowanie starego obserwatora następuje przed ostatnią
  walidacją, nie po opublikowaniu odtworzonego stanu.

Sam odczyt nie inicjalizuje `authStateProvider`, HTTP ani synchronizacji.
Obserwuje pasywne `CachedAuthWriteAuthority.revision`; każda zmiana authority
odcina poprzednią emisję. UI nie wyświetla poprzednich danych w stanie ponownego
ładowania. Kliknięcie przekazuje konto i epoch **pokazanego snapshotu**, a nie
nowe uprawnienie pobrane dopiero po await. A–B–A nie ożywia starego przycisku
ani oczekującego wznowienia. Jak pozostałe repozytoria, legacy wiersze bez pola
konta należą do zbioru danych wskazanego przez binding `sync_state`; nie
wprowadzono drugiego modelu właściciela ani obsługi wielu użytkowników.

Wznowienie używa istniejącego `resumeSession`, nie tworzy sesji, serii, PR ani
outboxa. Zachowuje UUID, plan, slot, pola strony/wariantu, checkpointy i lokalne
cele/kursor powtórzenia. Odtworzenie silnika timera nadal używa istniejącego
`IntervalTimer.restore`, który pozostaje w pauzie i nie dolicza nieobecności
do pracy. Nie zmieniono znaczenia ściennego czasu całej sesji przy jej finish.
Kolejki draftów, CAS, tokeny checkpointów i `_persistentDatabaseZone` pozostają
bez zmian; panel nie jest nowym writerem szkiców.

## Legacy i brak/uszkodzenie szkicu

Sesja bez lokalnego szkicu jest widoczna, lecz nie udajemy, że da się odtworzyć
niezapisany formularz/timer. Panel wyjaśnia brak szkicu i udostępnia zapisane
serie oraz powrót do treningów. Nie tworzy zastępczego guidance ani nowej sesji.
Poprawny ręczny szkic z `guidance == null` nie jest traktowany jako uszkodzenie.
Niepoprawny szkic lub zmieniony podpis guidance blokuje wznowienie z jawnym
wyjaśnieniem, bez naprawiania danych. Istniejąca ścieżka Home/finishPendingSession
pozostaje niezmieniona.

## Testy i weryfikacja — 2026-10-17

Nowe pliki:

- `test/features/workout/active_session_recovery_test.dart`: rzeczywisty
  `createRouter(initialLocation: '/workout/session')`, świeży kontener po
  zapisaniu/flush i usunięciu starego, prawdziwy `ActiveSessionPage`, panel,
  jawny klik i ten sam UUID. Guided zachowuje pola i checkpoint w pauzie,
  zero serii/PR oraz niezmienny outbox. Powtórzenie mieszane reps+seconds
  zachowuje drugi cel, stronę, wariant i kursor po jednym **jawnym** logu,
  bez następnego automatycznego zapisu. Dodatkowo loading/error/retry,
  wiele wyborów i brak automatycznego wznowienia, usunięcie podczas await.
- `test/features/workout/session_recovery_provider_test.dart`: reakcje na
  draft/binding/lock/DELETE, legacy bez szkicu, uszkodzenie, niezmienność
  odczytu, zakaz inicjalizacji auth/HTTP, natywny SQLite i transport RPC
  (`NativeDatabase.createInBackground`), stary snapshot i A–B–A podczas await.

TDD RED przed implementacją: rzeczywista trasa pokazała „Wybierz ćwiczenia”
zamiast panelu; osobny test otrzymał `true` ze wznowienia wiersza usuniętego
w trakcie pobierania serii. Oba przypadki przeszły po poprawce.
Podczas szerszego przebiegu wykryto regresję siedmiu testów ręcznego formularza;
ograniczenie panelu do pustego wyboru usunęło ją bez edycji tych testów.

Weryfikacja przez istniejący przypięty obraz:

```sh
docker run --rm --network none -v /opt/fit:/source:ro -w /tmp/check \
  sha256:241e5ef93f049c6b306d028e7210268c4970b75c3a79b23d3a1f3e61601d84b8 \
  bash -lc 'cp -a /source/. /tmp/check/ && flutter test --no-pub -r expanded test/features/workout'
# 181 passed
```

Końcowe ponowienie obu nowych plików: **7 passed**. Pełne
`flutter analyze --no-pub`: **No issues found**. Kontrola formatu
`dart format --output=none --set-exit-if-changed` sześciu plików tego zakresu:
**0 changed**. Wszystkie trzy kontrole wykonano na kolejnej świeżej kopii
read-only w tym samym przypiętym obrazie.

Flutter **3.35.4**, Dart **3.9.2**. Testy i pełna analiza działają na kopii
read-only źródła w kontenerze, bez dostępu do sieci. Format ograniczony do
sześciu własnych/zmienionych plików Dart. Bez builda runtime, generatora,
zmian deklaracji Drift/Freezed/JSON, zależności, wersji, katalogu ćwiczeń,
ustawień, offline/web/deploy i bez commit/push.

Artefakty Web SQLite pozostały zgodne z lockiem Drift **2.28.2** / sqlite3
**2.9.4** (kontrolne SHA-256):

- `web/sqlite3.wasm`: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- `web/drift_worker.dart.js`: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

Nie wykonano nowego compiled-browser retestu ani testu telefonu. Native/RPC
nie zastępują akceptacji Web SQLite w rzeczywistym procesie przeglądarki.
Historyczny browser FAIL pozostaje zachowany; ten etap dostarcza poprawkę
źródeł i testy regresyjne, nie nowy runtime ani deklarację gotowości PWA offline.
