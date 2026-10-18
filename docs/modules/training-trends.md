# Trendy treningowe — zakres C, tylko odczyt

## Własność i wejście

- `lib/features/progress/trends/domain/training_trend.dart`: czysta agregacja.
- `lib/features/progress/trends/data/training_trend_repository.dart`: SELECT/JOIN
  istniejących tabel, bez nowych DAO, schematu, outboxa czy zapisów.
- `lib/features/progress/trends/providers/training_trend_providers.dart`:
  obserwacja historii i pasywny guard konta.
- `lib/features/progress/trends/presentation/training_trends_page.dart`: wybór
  ćwiczenia, strony i wariantu rzeczywiście obecnych w zakończonej historii.
- `lib/features/progress/presentation/pages/progress_page.dart`: jedyny zmieniony
  istniejący plik; przycisk otwiera `MaterialPageRoute`, bez zmian routera.
- Testy: `test/features/progress/training_trend_test.dart`,
  `training_trend_repository_test.dart`, `training_trend_provider_test.dart`,
  `training_trend_widget_test.dart`.

## Kontrakt danych i porównywalność

Scope jest dokładnym rekordem `exerciseId + nullable side + nullable variantId`.
NULL strony nie oznacza `both`; NULL wariantu nie oznacza dowolnego UUID.
Nie odczytujemy definicji wariantu do identyfikowania historii: usunięty lub
nieznany wariant zachowuje UUID i etykietę ze snapshotu serii. Nazwa ćwiczenia
także pochodzi z historii. Nie trzeba mieć nadal dostępnej definicji w katalogu.

Repozytorium odrzuca aktywne sesje i tombstone'y sesji/serii. Kolejność:
koniec sesji, lokalne ID sesji, numer serii, ID serii. Wiele serii jednej sesji
nie staje się wieloma niezależnymi próbkami. Odczyt nie filtruje brakującego
RPE ani niepoprawnego wyniku: są potrzebne do uczciwego wyjaśnienia wyłączeń.

- **Powtórzenia przy kg:** osobne grupy obciążenia. Kontrakt wymaga tej samej
  całkowitej liczby serii, ich uporządkowanego układu obciążeń i liczby serii
  przy danym kg. Sumowane są tylko powtórzenia przy jednym obciążeniu,
  nigdy wyniki różnych kg ani tonaż jako zastępczy wynik formy.
- Brakujące, ujemne i nieskończone/NaN kg wykluczają sesję z porównań.
  Brak kg nie jest dowodem 0 kg ani identycznej pracy. Jawne skończone 0 kg
  pozostaje osobnym poprawnym zapisem. Konsekwencja: legacy ćwiczenia z masą
  własną bez zapisanego obciążenia mają obserwacje, ale nie udawany trend.
- Brak/niedodatnie powtórzenia lub jednoczesny zapis sekund w protokole reps
  wyłączają całą sesję, zamiast po cichu zmniejszać liczbę jej serii.
- **RPE:** oddzielna seria metryki; maksimum rzeczywiście zapisanych RPE
  wszystkich serii. Każda seria musi mieć RPE 1–10. Kontrakt obejmuje identyczną
  uporządkowaną pracę: powtórzenia i kg każdej serii. Brak RPE nie jest zerem;
  niższy wysiłek przy innym wykonaniu nie jest porównywany.
- **Czas/rundy:** wiersze pokazują rzeczywiście zapisane `czasSekund` oraz
  liczbę rund/powtórzeń. Długość sesji i czas start→koniec nie są wejściem
  agregatora. Obecna historia nie dowodzi pełnego identycznego protokołu
  przerw/rund; konserwatywnie pokazujemy obserwacje jako nieporównywalne.
  Nie rekonstruujemy interwałów z aktualnego katalogu ani `guidanceJson`.
- Nieznany tracking również oznacza obserwacje bez porównania, nie domyślne reps.

Każdy kontrakt osobno: 0/1 sesji = `tooLittleData`, 2 = `comparisonOnly`,
co najmniej 3 = `comparableTrend`. Opis pokazuje zmianę pierwsza→ostatnia,
daty i ID wszystkich próbek, nie regresję statystyczną ani diagnozę.
UI odróżnia pustą historię, zbyt mało porównywalnych sesji, brak metryki,
nieporównywalność protokołu oraz niedostępne konto. Powody wyłączeń są jawne.
Różne kontrakty są pokazane osobno, wraz z uzasadnieniem braku porównania.
Równa liczba serii nie dowodzi identycznego tempa, przerw lub techniki — UI
zaznacza, że jest to porównanie zapisu, nie dowód poprawy formy.

## Konto i brak skutków ubocznych

Provider nie inicjuje `authStateProvider`, HTTP ani aktywnego treningu.
Korzysta z istniejącego `CachedAuthWriteAuthority`, epoch/revision i trwałego
bindingu account/device/offlineAccess. Ekran utrzymuje jeden lease odczytu
przez zmiany selekcji i odświeżenia. Obserwowana zmiana bindingu go odwołuje,
również A→B→A; nie przenosi otwartego ekranu na inne konto. Po awaitach
ponownie sprawdzane są epoch, autoryzacja, binding i disposal. UI nie pokazuje
poprzedniej wartości `AsyncValue` podczas loading/error.

Historia odświeża się po zmianach sesji/serii, w tym po tombstone. Nie zmienia
PR/1RM, progresji stałego ciężaru, celu kolejnej sesji ani historii. Testy
kontrolują brak outboxa i PR, a także brak dodatkowych bootstrapów auth.

## Weryfikacja 2026-10-17

Przypięty lokalny obraz `235818d883dd` (`fit-web:catalog-expanded-verified`),
potwierdzone Flutter **3.35.4 / Dart 3.9.2**. `/opt/fit` montowane wyłącznie
readonly. Testy i analiza działają na kopiach w `/tmp` kontenera, nie na starych
źródłach obrazu. Nie uruchamiano generatora ani pełnego build/runtime/deploy.

1. **Bieżący wspólny snapshot:** cztery nowe pliki testów: **28 PASS / 0 FAIL**
   (16 silnik, 1 repo DB, 7 provider, 4 UI). Focused analyze modułu, wejścia
   progress i czterech plików testowych: **No issues found**.
2. **Baseline `e0fe9a6` + wyłącznie pliki zakresu C:**
   `flutter test --no-pub test/features/progress` plus
   `fixed_load_progression_test.dart`, `progression_history_test.dart`,
   `progression_provider_test.dart`, `progression_widget_test.dart`:
   **148 PASS / 0 FAIL**. Pełny analyze baseline z trendami był bez uwag.
3. **Ten sam szerszy focused zestaw na wspólnym snapshotcie:**
   **147 PASS / 1 FAIL**. Istniejący `pr_side_roundtrip_test.dart`, test
   `v8 -> v9 preserves legacy PR and immutable attempted outbox on reopen`,
   zgłasza `duplicate column name: weekly_schedule_json` podczas migracji.
   Nowe testy trendów i istniejąca progresja przechodzą. Nie poprawiano migracji
   ani fixture'u poza własnością trendów.
4. Pełny analyze tego wspólnego snapshotu: **22 uwagi**, wszystkie poza
   własnością trendów; błąd blokujący to `undefined_operator` dla `&` w
   `features/schedule/providers/schedule_providers.dart:70`. Pozostałe dotyczą
   równoległych schedule/planner/backup i testu schedule. Jest to stan
   przechwyconej kopii, nie deklaracja stanu końcowego równoległych prac.

Zakres testów: progi 0/1/2/3; różne liczby serii i kg; NULL/both oraz UUID;
NaN/Infinity/ujemne/brakujące/zerowe kg; niepełne RPE i inna praca; czas/rundy
bez znanego protokołu; aktywne/usunięte sesje i serie; snapshot usuniętego
wariantu; read-only; aktualizacja po tombstone; logout przed/po odczycie;
zmiana account/device/lock i A→B→A; pusta historia, opóźnione UI oraz przełączanie
ćwiczenia/strony/wariantu. Test opóźnionego UI używa kontrolowanego providera;
testy DB/guardów osobno używają prawdziwego Drift w pamięci.

Lockfile i artefakty Web SQLite bez zmian: Drift **2.28.2**, sqlite3 **2.9.4**.
SHA256 zgadza się z udokumentowaną wcześniej weryfikacją upstream:

- `web/sqlite3.wasm`:
  `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- `web/drift_worker.dart.js`:
  `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## Pozostałe ograniczenia

Brak paginacji/budżetu dla bardzo dużej historii — obecnie SELECT pobiera
całą dostępną zakończoną historię. Brak statystycznych przedziałów ufności,
wykresu, rekomendacji treningowych i rekonstrukcji legacy protokołów.
Nie przeprowadzono fizycznego browser/device acceptance ani niezależnej
recenzji subagentem. Pełna wspólna analiza/testy po integracji i jednolite
formatowanie pozostają bramką właściciela integracji. Nie zmieniano zależności,
toolchainu, wersji, DB declarations, profilu/sync/plannera/routera/workoutu;
bez commitu, push i publikacji.
