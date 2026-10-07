# Apple Zdrowie — raport klienta Flutter

> Raport pierwszego kandydata. Aktualny schemat to v7, a bieżące wyniki
> i poprawki kompatybilności opisuje [raport v7](apple-health-shared-cursor-fix.md).

Data: 2026-09-11. Wersja sprawdzona: **1.1.0+3**.
Implementacja klienta zakończona, bez wdrożenia i bez testu rzeczywistego iPhone.

## Zakres

- Osobna tabela Drift `HealthSamples` / `HealthSampleData`, schemat bazy **5**,
  migracja dodająca tabelę bez resetowania kursora. Wygenerowano
  `lib/core/database/app_database.g.dart` przez build_runner.
- Typ synchronizacji `healthSample`, mapowanie SyncStore i snapshoty typed
  companions. `measuredAt` obsługuje ISO dla masy i null dla kroków.
- Repozytorium pozwala tylko usuwać importy: transakcja zapisuje tombstone
  i trwałą operację delete z ISO datami, bieżącą wersją i preserveLocal.
  `SyncDao.enqueueUpsert` jawnie odrzuca healthSample.
  Nie zmieniano `SyncService` w celu obsługi konfliktów dwóch usuwających klientów.
- Settings: status, generowanie/rotacja po osobnej jawnej zgodzie na wysłanie
  danych zdrowotnych na VPS, potwierdzane revoke, bezpieczne komunikaty błędów.
  Do generowania/revoke potrzebny jest odczytany status online oraz konto.
- Token: wyłącznie przejściowa odpowiedź i jednorazowy dialog. Brak zapisu
  do Drift, outbox, preferencji czy backupu. Czyszczenie przy zamknięciu,
  dispose, zmianie konta i lifecycle; spóźniona odpowiedź po utracie kontekstu
  jest odrzucana. Błędy API nie przenoszą DioException/żądań do UI.
  Zaznaczanie tokenu korzysta z systemowego menu; instrukcja ostrzega o schowku.
- W UI jest pełna ręczna instrukcja Skrótu i zaznaczalny JSON bez tokenu:
  Find Health Samples, Choose from List, Get Details, Start Date/Value/Unit/Source,
  kg i ISO z offsetem, słowniki/listy, POST JSON i nagłówek Bearer.
  Kroki: Ask for Input i `manual_verified_total`, bez sumowania iPhone/Watch.
  Nie ma fikcyjnego pliku .shortcut, linku iCloud ani obietnicy autoimportu.
- Dziś: ostatnia masa, kroki warszawskiego dnia, brak danych zamiast zera.
  Osobny account-scoped provider GET statusu pokazuje serwerowy lastImportAt,
  także gdy udany replay jest nowszy od importedAt próbki. Przy braku statusu
  jawnie pokazuje świeżość lokalnych danych. Odświeżanie na wejściu/aktywacji
  zakładki, resume i przyciskiem; timer przelicza dzień, nie odpytuje API.
  Po wylogowaniu provider nie wysyła żądań.
- Postępy: wspólny wykres i historia masy z zachowanymi źródłami, bez zmiany
  ręcznych pomiarów. Źródło w dymku i historii. Daty importowanych punktów
  dla osi/dymków/historii używają Europe/Warsaw; timestamp pozostaje podstawą
  sortowania. Importy są nieedytowalne, ale mają usuwanie z potwierdzeniem.
  Historia kroków pozwala usuwać także wyniki wcześniejszych dni.

## Polityka kopii i przywracania

Format backupu pozostaje **schemaVersion 2**. Dodano opcjonalną, informacyjną
sekcję `healthSamples` bez metadanych sync. Jest to archiwum danych zdrowotnych,
nie mechanizm tworzenia importów na serwerze.

Przywracanie kopii (także starej bez sekcji zdrowia):

1. Nie kasuje lokalnej tabeli HealthSamples ani jej tombstone'ów.
2. Nie zmienia istniejących operacji usunięcia healthSample, także attempted.
3. Nie odtwarza healthSamples z pliku i nie tworzy nowych UUID/upsertów.
4. `enqueueAll`, zarówno zwykłe, jak i `deleted: true`, pomija healthSample.
5. Na nowym urządzeniu/koncie próbki pojawią się tylko przez pull bieżącego
   konta. Kopia innego konta nie wprowadza jego danych zdrowia.

Polityka jest podana w potwierdzeniu restore, komunikacie wyniku oraz instrukcji
Apple Zdrowie. Pozostała semantyka backupu ręcznych danych nie została zmieniona.

## Weryfikacja

Wykorzystano istniejący obraz SDK `fit-web:verified`. `flutter --version`
potwierdził **Flutter 3.35.4 / Dart 3.9.2**, framework `d693b4b9db`.
Nie wykonywano upgrade ani zmiany zależności.

Końcowy przebieg w Dockerze z `/opt/fit:/app`, katalogiem roboczym `/app`:

```text
dart format [zmienione pliki lib/ i test/]
dart run build_runner build --delete-conflicting-outputs
dart tools/generate_app_version.dart --check
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

Wyniki:

- build_runner: sukces (końcowy przebieg 132 s).
- kontrola wygenerowanej wersji: sukces.
- flutter analyze: **No issues found!**
- pełny flutter test: **275 tests, All tests passed!**
- git diff --check: sukces.

Nowe testy w `test/features/health/` obejmują m.in. ISO/null daty w rzeczywistym
SyncService/SyncStore, offline retry i niezmienność operacji, tombstone podczas
pull, migrację v4→v5 z zachowaniem kursora, zakaz upsertów, restore starej kopii,
restore na nowej bazie, nienaruszanie ręcznych pomiarów przy usuwaniu importu,
źródła wykresu/historii, warszawską północ i DST, zgodę/rotację/revoke/błędy,
czyszczenie tokenu przy lifecycle i zmianie konta, status online nowszy od
lokalnego importedAt, offline fallback i brak odpytywania API przez timer lub
po wylogowaniu.

Istniejący test wszystkich lokalnie tworzonych typów w
`test/core/sync_service_test.dart` doprecyzowano: healthSample nie jest typem
tworzonym lokalnie. Jego ścieżkę pull/delete pokrywają osobne testy.

## Przekazanie koordynatorowi

- Zachowano wcześniejsze zmiany Settings/auth/push/backup/versioning.
- Nie edytowano pubspec, changelogu, backendu, wdrożenia ani
  `test/app_version_test.dart`; ten raport jest przyznanym wyjątkiem w docs/.
- Brak commitów, deployu, odczytu sekretów i danych produkcyjnych.
- Koordynator wykonuje finalny web build/runtime Nginx.
- Rzeczywisty odczyt Health Sample, nazwy akcji i uprawnienia iOS oraz transfer
  z iPhone wymagają ręcznej bramki urządzenia opisanej w instrukcji Skrótu.
  Testy Flutter nie stanowią potwierdzenia działania HealthKit na urządzeniu.
