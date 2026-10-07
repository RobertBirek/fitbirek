# Apple Zdrowie — implementacja i weryfikacja 1.1.0+3

> Raport pierwszej weryfikacji, sprzed poprawek review. Wykryte następnie
> blokery dotyczyły blokad FK i obsługi starszych PWA. Aktualny kontrakt wymaga
> opt-in pull i niezależnego pełnego kursora w lokalnym schemacie v7; wyniki poniżej oraz obrazy pierwszego
> kandydata nie stanowią weryfikacji tych poprawek.
> Aktualne wyniki i obrazy: [niezależny pełny kursor v7](apple-health-shared-cursor-fix.md).

**2026-09-11: implementacja i testy ukończone, bez wdrożenia produkcyjnego.**
Prace backend i Flutter wykonano w oddzielnych sesjach roboczych według
[wspólnego kontraktu](apple-health-contract.md), ustalonego przed delegacją.
Nie uruchamiano reviewera. Wcześniejsze niezatwierdzone w Git zmiany użytkownika
dotyczące push/versioning zostały zachowane. Nie wykonywano commitów ani
operacji na produkcyjnych danych zdrowotnych; nie odczytywano sekretów logowania.

## Co zaimplementowano

- `backend/app/health/`: status, tworzenie/rotacja/odwołanie tokenu i import
  przez HTTPS POST. Zarządzanie wymaga sesji i CSRF; import wymaga osobnego
  Bearer, bez cookies. Token losowy, zapisany jako hash, ujawniany tylko raz
  po jawnej zgodzie; odpowiedzi i błędy mają `Cache-Control: no-store`.
- Strumieniowy limit 64 KiB, 100 elementów, trwały limit 30 prób/min/token,
  ścisła walidacja liczb, jednostek i dat. Błędy integracji nie ujawniają
  tokenów, danych ani parametrów SQL.
- Alembic **0008** po **0007**: tokeny, limiter i trwałe digests przyjętych
  wyników kroków. Dane są publikowane jako `healthSample` przez istniejący
  protokół sync, z atomową transakcją i wspólnymi blokadami rekordów/publishera.
- Masa: deterministyczna tożsamość per użytkownik/czas UTC/źródło/wartość kg;
  równoważne offsety dają tę samą próbkę. Zmiana tożsamości daje nową próbkę.
- Kroki: jeden wynik na warszawski dzień, zastępowanie całego totalu,
  nigdy sumowanie źródeł. Wcześniej przyjęte wartości po korekcie są replay
  i nie cofają wyniku. `measuredAt: null` uczciwie reprezentuje wynik dnia.
- Import nie odradza tombstone. Sync pozwala tylko usuwać istniejące próbki;
  ponowne usunięcie tombstone po rebase jest akceptowane, więc dwa urządzenia
  nie zapętlają outbox. Ręczne pomiary pozostają odrębnymi rekordami.
- Flutter: osobna tabela `HealthSamples`, Drift **v5**, wygenerowany kod,
  odczyt offline i trwały outbox usunięć. Settings zawiera zgodę, status,
  jednorazowy token, rotację/revoke, instrukcję Skrótu i JSON.
- Dziś: ostatnia masa, kroki dnia, czas ostatniego udanego importu z API;
  przy braku sieci jawnie oznaczona świeżość lokalnych danych. Brak danych nie
  staje się zerem. Postępy łączą masę ręczną i importowaną, pokazując źródła
  i daty Europe/Warsaw. Importy można usuwać, także wcześniejsze dni kroków.
- Wersja `pubspec.yaml`: **1.1.0+3**, zaktualizowany changelog i wygenerowana
  stała wersji. Brak zmian wersji Flutter/Dart i zależności.

Szczegóły klienta: [raport Flutter](apple-health-flutter-report.md).

## Kopie zapasowe

Format kopii aplikacji pozostaje **schemaVersion 2**. Opcjonalna sekcja
`healthSamples` jest archiwum danych, bez tokenu i metadanych sync. Restore
nie tworzy importów z pliku, nie usuwa istniejących próbek i nie narusza
oczekujących usunięć. Na nowym urządzeniu historię importów przywraca pull
bieżącego konta. Ta polityka jest pokazana w UI i objęta testami; zapobiega
odradzaniu usunięć przez starą kopię oraz wysyłaniu niedozwolonych upsertów.
Backup PostgreSQL obejmuje nowe tabele standardowym dumpem.

## Wyniki weryfikacji

| Kontrola | Wynik |
| --- | --- |
| Pełny backend, Python 3.12.3, hash-locked venv, PostgreSQL 16 Testcontainers | **183 passed**, 324.92 s |
| Generator Drift, Flutter 3.35.4 / Dart 3.9.2 | poprawny |
| Generator wersji i `--check` | poprawny, 1.1.0+3 |
| Pełny `flutter analyze` | **No issues found** |
| Pełny `flutter test` | **275 passed** |
| Etap Docker `verification` w finalnym buildzie web | analiza + **275 passed** |
| `tools/verify_apple_health_example.py` | **2 przykłady JSON** zgodne z modelem API; bez sieci/bazy |
| Build API `runtime` i `migration` | poprawne, hash-locked zależności |
| Build web finalny `runtime` (Nginx) | poprawny, JS + CanvasKit/SQLite Wasm |
| Smoke obrazu API, bez sieci i bazy | 4 trasy integracji oraz Europe/Warsaw obecne |
| `alembic heads` w obrazie migracyjnym, bez bazy | **0008 (head)** |
| Smoke Nginx w jednorazowym kontenerze `--network none`, bez publikowania portów | konfiguracja poprawna; `/healthz`, `/today`, `/version.json` działają; artefakty SQLite obecne |
| Metadane serwowanego `version.json` | `version: 1.1.0`, `build_number: 3` |
| `git diff --check` | poprawny |

Pierwsze wywołanie pełnego builda web przekroczyło limit narzędzia 600 s
po zakończeniu weryfikacji. Ponowienie wykorzystało te same zweryfikowane
warstwy i ukończyło kompilację oraz finalny obraz Nginx. Istniejące ostrzeżenia
o opcjonalnym pełnym Dart-Wasm (`flutter_secure_storage_web`) nie blokują
wybranego buildu JS. Smoke Nginx zgłosił także istniejącą podwójną deklarację
MIME `wasm`; konfiguracja i serwowanie przeszły kontrolę.

Testy regresyjne obejmują m.in. współbieżne duplikaty, atomowe publikowanie,
revoke/rotation kontra rozpoczęty import, reverse-order sync delete, dwa
usuwające klienty, izolację kont, Bearer import-only, limity, redakcję błędów,
offline/retry, migrację Drift, restore, zgodę i czyszczenie tokenu oraz
warszawską północ i zmiany czasu.

## Obrazy-kandydaty — nie wdrożone

| Obraz | ID |
| --- | --- |
| `fit-api:apple-health-1.1.0-candidate` | `sha256:c5e29dbc6ee7d3b16117c1008a52d183fe6f2e060d5fab54ac4624a570b3067a` |
| `fit-migration:apple-health-1.1.0-candidate` | `sha256:af9eb06851f194d7224a83f7476611a53b8cfc2916e92b9c25e6727d9ea77761` |
| `fit-web:apple-health-1.1.0-candidate` | `sha256:812b31ff56e50ba0fc2fd769efc6ca2322fd89b8e14ca12512598ec34d54fa82` |

Pliki lock zachowały hashe z początku prac:

```text
6db08345b88fd18540260ef36a56d65ea1948b7095b1e50e24091e4c1d26004a  backend/requirements.lock
290ac69cc461f34e9dca55f82046e8d2c2fe7414cab3ebeca50e329b6d3eb934  backend/requirements-dev.lock
28eafb11fbd994abc5a1af6a3c79e3cf488f1af5e7d841529421c41bcefc5e13  backend/requirements-build.lock
ffc65c07f8b897b12eef4aaf7a84ac2916b5563d87be2784c2b43fcbd48854a0  backend/requirements-push.lock
3653342b2fdbdf643d3041fc89658d23c7da6c59e23f84e0e5923f5846d1fa57  pubspec.lock
```

## Co wymaga rzeczywistego iPhone

**Nie potwierdzono jeszcze sprzętowo odczytu i transferu z iPhone.** Backend,
PWA i testy są gotowe, ale automatyczne testy nie wykonują akcji Zdrowia na iOS.
[Instrukcja ręcznego Skrótu](apple-health-shortcut.md) zawiera źródła Apple,
konfigurację akcji oraz checklistę testu urządzenia na izolowanym środowisku.

Kroki pozostają **ręcznie potwierdzanym wynikiem ze Zdrowia przez Ask for Input**.
Nie udajemy automatycznego, zdeduplikowanego importu HealthKit ani dostępu do
UUID próbki ze Skrótów. Nie utworzono fikcyjnego `.shortcut` ani linku iCloud.
Przed przyszłym wdrożeniem potrzebne są odrębne review oraz bramka iPhone;
procedura wdrożeniowa nadal podlega `DEPLOY.md`.
