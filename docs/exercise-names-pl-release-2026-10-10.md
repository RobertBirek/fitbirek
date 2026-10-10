# Wdrożenie polskich nazw ćwiczeń — 2026-10-10

## Zakres

Wdrożono wyłącznie usługę web w wersji **1.4.5+12**. Katalog zachowuje
identyfikatory `cw...` i angielskie `nazwaEn`; spolonizowano `nazwaPl`.
Import przyrostowy aktualizuje na istniejących klientach wyłącznie zmienione
`nazwaPl`, bez migracji, usuwania rekordów ani naruszania ulubionych.

## Czas

- Start kontenera web: **2026-10-10 14:29:50.825 UTC**
  (**16:29:50.825 CEST**).
- Weryfikacja publiczna: **2026-10-10 14:31:56 UTC**
  (**16:31:56 CEST**).

## Dowody

- Backup: `20261010T141749013582Z`; usługa zakończona `Result=success`,
  `ExecMainStatus=0`; SHA-256 dumpu:
  `9e1f4bfd463ab7f8a10928ab7a71977c2bb0d249cdffe7c29f2199327e77496e`.
- Kandydat/runtime: `fit-web:candidate-1.4.5-12-20261010T141749Z`,
  image ID `sha256:70091bf98a043f4990032e89db7e62c6550b4b4e5ccee3ebde4b324a4678d06c`.
- W zatwierdzonym kontenerze Flutter 3.35.4 / Dart 3.9.2: generator wersji
  i `--check`, analiza bez problemów, 358 testów oraz build web zakończone
  powodzeniem.
- W obrazie i publicznie potwierdzono `cw261.nazwaPl`:
  `Rozciąganie mięśnia czworogłowego uda w staniu`; `nazwaEn` nadal wynosi
  `Standing quad stretch`. Katalog ma 316 pozycji, a wpis katalogu jest obecny
  w service workerze.
- Publicznie: `https://fit.birek.online/version.json` zwraca `1.4.5+12`,
  katalog i zdrowie API są dostępne, a kontener web jest healthy.
- API i sender nie zostały odtworzone.

## Rollback

- Tag: `fit-web:rollback-1.4.4-11-20261010T141602Z`
- Image ID:
  `sha256:0d73b82850159dae567df912a895b4adb39c89f56718b7c591c16129934d9883`

W razie rollbacku należy ponownie wskazać ten obraz dla usługi web i wykonać
wyłącznie jej kontrolowane odtworzenie; nie obniżać migracji ani nie zmieniać
usług API, sender, bazy, proxy lub sieci.
