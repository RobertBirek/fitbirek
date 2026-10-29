# Backup4 i restore

## Working set

- `lib/core/services/backup_service.dart`, `lib/core/sync/` i kodeki kolekcji.
- `test/core/training_program_backup_test.dart`,
  `test/features/settings/backup_snapshot_test.dart`,
  `test/features/schedule/training_programs_cloud_backup_test.dart`.
- [Pełny kontrakt danych](training-sets-programs-data.md#backup4-i-raw-quarantine),
  [sync](sync.md), [programy](training-sets-programs-ui.md#programy-ab--task4).

## Format i granice

Nowy eksport ma `schemaVersion: 4`; import akceptuje także formaty1–3.
Starszy klient musi odrzucić backup4, a nie odtworzyć go stratnie. Nie obniżaj
wersji w pliku, nie usuwaj nieznanych pól i nie naprawiaj SQLite ręcznie.
Backup aplikacji nie jest produkcyjnym dumpem PostgreSQL/Restic z `DEPLOY.md`.

Eksport zachowuje nullable role serii, structure/guidance v1/v2 oraz raw
niedostępnych rozszerzeń, kolekcje profilu, tombstone'y i granice programów.
Restore nadaje nowe UUID planów/sesji/serii i remapuje linki guidance;
wewnętrzny targetId pozostaje niezmieniony. Importowane programy są kopiami
z nowymi UUID programu i przeliczonymi UUIDv5 wyjątków. Ich plany, sesje
i snapshoty używają tych samych map. Oryginalne lokalne programy nie zmieniają
immutable core; domknięcie ich referencji pozostaje jako archiwalne tombstone'y,
nie nowy dowód ukończenia. `archiveDeletedAtUtc` zachowuje stan usunięcia kopii.
Brak wymaganej mapy lub przekroczenie łącznego limitu500 wpisów wraz
z tombstone'ami odmawia całego restore transakcyjnie. Lokalne nieczytelne raw
blokuje destrukcyjny import, zamiast zostać pominięte; eksport zachowuje raw.

`data.syncRecovery:{deferredRecords,outbox}` eksportuje pełne raw strings
i attempted payloadJson. Po imporcie trafiają jako **bierne dowody** do
`_backupRecoveryArchive` w deferred, nie jako operacje do wysyłki starego konta.
Reeksport zachowuje również te archiwa. Istniejące lokalne attempted/deferred
nie są resetowane. Backup nie rozstrzyga nieznanego wyniku żądania ani nie daje
uprawnień do retry. Recovery wymaga jawnej weryfikacji zgodnym klientem.
Lokalne szkice/checkpointy sesji nie są przenośnym chmurowym recovery.

Przed przyszłą publikacją: API-first i plan aktualizacji klientów. Ochrona
omission nie sprawi, że stary klient poprawnie policzy warmup lub odczyta v2.
Ta dokumentacja nie stanowi wydania ani odbioru runtime/PWA.
