# Wydanie ilustracji batch 01 - 2026-10-11

## Zakres

Wydano wyłącznie usługę web w wersji **1.4.9+16**. Dodano WebP 512x512 z dwoma
kadrami dla `cw251`, `cw252`, `cw253` i `cw262`. API, `push-sender`, migracje,
Compose, Caddy i sieci nie zostały zmienione ani odtworzone.

Wersja `1.4.8+15` została krótko opublikowana, a następnie wycofana do
`1.4.7+14` po niezależnym review `cw251` i `cw253`; finalne poprawki wydano pod
nowym numerem `1.4.9+16`.

## Weryfikacja

- Docker `verification`: kontrola wersji, `flutter analyze` i **374** testy.
- Kandydat `fit-web:candidate-1.4.9-16-20261011T071213Z` zawierał wersję i
  wszystkie cztery assety.
- Publiczne `/version.json` zwróciło `1.4.9+16`, a `/api/health`
  `{"status":"ok"}`.
- Każdy asset publiczny zwrócił `200`, `image/webp` i dekoduje się jako
  `512x512`.
- SHA-256 `cw251`: `57c3977330a88bb6a78ca9d38f7c6514689e41e87a24cbc18afd7e57f71975f7`.
- SHA-256 `cw252`: `e4bbf55150bb0a0c28610cdfa880b06279833e832e1fcbb0fad3915699bbd66b`.
- SHA-256 `cw253`: `207fcab59964e987d8d7e2bc1102a3e1914f75115160eeb47e39a74121070190`.
- SHA-256 `cw262`: `e7ecb94d5b205b24c36b5a509491c8f304693e37a045697f5130113db3db1ae9`.

## Odzyskanie i koszt

Backup `20261011T071511058657Z` został zweryfikowany przed promocją. Rollback:
`fit-web:rollback-1.4.7-14-20261011T071213Z`, następnie odtworzenie wyłącznie
usługi `web` przez trzy aktualne pliki Compose.

Łączny koszt wszystkich prób batch 01: **0.366482 USD**: `cw251` `0.183856`,
`cw252` `0.022797`, `cw253` `0.068466`, `cw262` `0.091363 USD`.
