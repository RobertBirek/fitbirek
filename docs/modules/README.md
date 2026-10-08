# Moduły FitBirek

Ten katalog wskazuje minimalny working set dla zmian w kodzie. Najpierw czytaj dokument odpowiedniego modułu, potem tylko wskazane pliki i testy.

## Zasady

- `AGENTS.md` zawiera globalne ograniczenia wersji, danych i wydania.
- `DEPLOY.md` jest wymagany wyłącznie przy zmianach wdrożeniowych.
- Nie czytaj domyślnie wygenerowanych plików `*.g.dart`, `*.freezed.dart`, `web/sqlite3.wasm`, `web/drift_worker.dart.js`, cache ani `node_modules`.
- `docs/superpowers/` zawiera plany i specyfikacje historyczne. Nie jest źródłem bieżącego kontraktu runtime.
- Historycznych migracji Alembic i Drift nie zmieniaj. Dodawaj tylko nowe migracje.

## Working sety

| Typ zadania | Dokument |
| --- | --- |
| Mentor i dostawcy AI | [mentor.md](mentor.md) |
| Trening, ćwiczenia, planowanie i rekordy | [training.md](training.md) |
| Postępy, pomiary, testy, nastrój i Apple Health | [tracking.md](tracking.md) |
| Konto, API, Drift i synchronizacja | [sync.md](sync.md) |

Zmiana routera wymaga dodatkowo `lib/app/router.dart` i `test/app/router_test.dart`. Zmiana wersji wymaga `pubspec.yaml`, generatora wersji i `CHANGELOG.md`.
