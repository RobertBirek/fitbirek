---
name: fit-flutter-workflow
description: Uzywaj przy zmianach Fluttera, Drift, Freezed, json_serializable lub artefaktow Web SQLite w FitBirek.
---

# Flutter FitBirek

Przeczytaj `AGENTS.md`. Po zmianie deklaracji Drift, Freezed lub JSON uruchom `dart run build_runner build --delete-conflicting-outputs` i uwzglednij wygenerowane pliki. Przy zmianie wersji `drift` lub `sqlite3` zaktualizuj razem `web/sqlite3.wasm` i `web/drift_worker.dart.js`. Uruchom wlasciwy test, a dla pelnej weryfikacji `dart format . && flutter analyze && flutter test`.
