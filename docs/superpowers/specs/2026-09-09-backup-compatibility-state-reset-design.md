# Backup Compatibility and State Reset Design

## Scope

Restore legacy schema-v1 exercise favorite flags and reset local sync state on
successful imports without affecting schema-v2 favorite restores.

## Design

- During a schema-v1 restore, inspect each exercise's legacy `ulubione` flag
  before creating `ExerciseData`. Create a fresh, active `ExerciseFavorites`
  row only for `true` values.
- Continue restoring schema-v2 favorites exclusively from `exerciseFavorites`.
- Delete `SyncState` and `SyncOutbox` inside the existing import transaction.
  A failed restore rolls these deletions back with all other database changes.

## Tests

- Verify a v1 backup with `ulubione: true` creates an active favorite.
- Seed nonempty sync state and outbox, then verify successful v1 and v2
  restores clear both.
- Verify failed restore retains the original sync state and outbox.
