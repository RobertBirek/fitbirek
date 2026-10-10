# Wydanie ilustracji cw278 — 2026-10-10

## Zakres

Wydano wyłącznie usługę web w wersji **1.4.7+14**. Do rejestru ilustracji i
artefaktu PWA dodano `cw278` — Przenoszenie gumy nad głową, trzy kadry.
Pierwsze dwa kadry używają widoku front 3/4, a ostatni widoku rear 3/4, aby
jednoznacznie pokazać gumę za biodrami.

API, `push-sender`, migracje, Compose, Caddy i sieci nie zostały odtworzone ani
zmienione.

## Weryfikacja

- TDD: test `cw278` najpierw zakończył się błędem braku rejestru i assetu,
  następnie pełny target Docker `verification` zakończył się powodzeniem
  (`flutter analyze`, **366** testów i kontrola wersji).
- Kandydat runtime `fit-web:candidate-1.4.7-14-20261010T200812637292044`
  potwierdził `version.json` `1.4.7+14` i obecność assetu `cw278.webp`.
- Publiczne `/api/health` zwróciło `{"status":"ok"}`, a publiczne
  `/version.json` zwróciło `1.4.7+14`.
- Publiczny `cw278.webp` zwrócił `200`, `image/webp`, jest identyczny z assetem
  źródłowym i dekoduje się jako `512×512`.
- SHA-256 `cw278.webp`:
  `6235cf428dcf5f21f4e5cef048a7db4f4cde46bef1eb2cc8f3830038c955b155`.

## Odzyskanie i rollback

Przed promocją utworzono i zweryfikowano backup
`20261010T200759656501Z`. Poprzedni obraz web zachowano jako
`fit-web:rollback-1.4.6-13-20261010T200758801279978`. Rollback ogranicza się
do ponownego oznaczenia tego obrazu jako `fit-web:production` i odtworzenia
wyłącznie usługi `web`.

## Koszt prób cw278

Wykonano cztery pojedyncze próby Sunburst medium: trzy odrzucone kosztowały
odpowiednio `0.023562`, `0.023657` i `0.023327 USD`; zaakceptowana czwarta
próba kosztowała `0.023192 USD`. Łączny koszt `cw278` wyniósł
**0.093738 USD**.
