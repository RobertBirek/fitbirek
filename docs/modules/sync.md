# Working set: Konto i synchronizacja

## Odpowiedzialność

Sesje, CSRF, API, Drift, outbox, rekordy synchronizacji i migracje baz danych.

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
