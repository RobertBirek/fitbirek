# Working set: Konto i synchronizacja

## Odpowiedzialność

Sesje, CSRF, API, Drift, outbox, rekordy synchronizacji i migracje baz danych.

## Decyzja o zakresie

Na razie aplikacja pozostaje osobista, z jednym użytkownikiem — właścicielem.
Prywatne konta dla znajomych na zaproszenia są **odłożonym planem**, nie bieżącym
zadaniem implementacyjnym: [uzgodnienia na przyszłość](../future-private-accounts.md).

## Czytaj najpierw

- `lib/features/auth/**`
- `lib/core/{api,database,sync}/**`
- `backend/app/{identity,security,sync}/{router,service,models,schemas}.py`
- `backend/migrations/env.py` oraz najnowszą migrację
- `backend/tests/test_{identity,sync,schema,bootstrap}.py`

## Granice

- Nie edytuj historycznych migracji.
- Zmiana tabel Drift wymaga migracji, regeneracji i testu istniejącej bazy.
- Zmiana synchronizowanej encji wymaga klienta, backendu, outboxa, pull/push i testów restore.
- Planner etap 4: nullable `WorkoutPlans.structureJson` (Drift 10), optional wire
  `structure` mapa v1; szczegóły i brak backfillu: `structured-planner.md`.
- Warianty i filtry: Drift12, optional kolekcje w istniejącym `profile`, bez
  nowych typów encji i kursora; per-ID merge po odrzuconym CAS, tombstone'y,
  limity i warunek osobnego wydania API: `user-variants-cloud.md`.
- Kwarantanna pull, trwałe blokady push i generacja powiązania przy logout:
  [audyt klienta 2026-10-18](../2026-10-18-client-sync-audit.md).
