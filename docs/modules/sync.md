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
- Role serii, programy, raw/hold i restore: `training-sets-programs-data.md`,
  `backup.md` oraz `backend/SYNC_EXTENSIONS.md` → „Role serii i programy A/B”.

## Granice

- Nie edytuj historycznych migracji.
- Zmiana tabel Drift wymaga migracji, regeneracji i testu istniejącej bazy.
- Zmiana synchronizowanej encji wymaga klienta, backendu, outboxa, pull/push i testów restore.
- Bieżący Drift15 dodaje nullable `SetsLog.setRole` i
  `UserProfiles.trainingProgramsJson` (14→15, bez backfillu). Opcjonalny wire
  `setRole` zachowuje omission żywej serii, explicit NULL resetuje do legacy;
  revival nie dziedziczy roli. `trainingPrograms` to oddzielna kolekcja profilu,
  nie nowy kind weeklySchedule. Backend zachowuje ją opaque; klient waliduje
  immutable core/cutoff, referencje i dowody, także przed LWW/CAS/restore.
  Próby attempted pozostają niezmienne. Przed przyszłą publikacją wymagane
  API-first i aktualizacja klientów; sam omission nie daje zgodności semantycznej.
- Planner etap 4: nullable `WorkoutPlans.structureJson` (Drift 10), optional wire
  `structure` mapa v1; szczegóły i brak backfillu: `structured-planner.md`.
- Warianty i filtry: Drift12, optional kolekcje w istniejącym `profile`, bez
  nowych typów encji i kursora; per-ID merge po odrzuconym CAS, tombstone'y,
  limity i warunek osobnego wydania API: `user-variants-cloud.md`.
- Kwarantanna pull, trwałe blokady push i generacja powiązania przy logout:
  [audyt klienta 2026-10-18](../2026-10-18-client-sync-audit.md).
