# Wydanie ilustracji ćwiczeń — 2026-10-10

## Zakres

Wydano wyłącznie usługę web w wersji **1.4.6+13** (commit `e55010a`).
Do rejestru ilustracji i artefaktu PWA dodano:

- `cw257` — rozciąganie motylkowe, jeden kadr;
- `cw264` — rozciąganie łydki przy ścianie, dwa kadry.

`cw278` pozostaje odrzucone i nie zostało opublikowane.

## Weryfikacja

- Python: `tools.tests.test_benchmark_exercise_images` — 17 testów.
- Flutter 3.35.4 / Dart 3.9.2: skupiony test rejestru ilustracji — 12 testów.
- Kandydat `fit-web:candidate-1.4.6-13-e55010a`: pełne `flutter analyze`,
  `flutter test` (364 testy) i build web zakończone powodzeniem.
- Kandydat oraz publiczny `version.json` potwierdziły wersję `1.4.6+13`.
- Publiczne zasoby HTTP zwróciły `200` i `image/webp`; przeglądarka anonimowo
  pobrała i zdekodowała oba obrazy jako 512×512. Worker usługi jest
  zarejestrowany, a jego odpowiedź ma `Cache-Control: no-cache`.
- SHA-256 `cw257.webp`:
  `0d530e0529bc342788c70a6bb6f2408f37d5c32b12d9b802eb0ec0988b8ae42c`.
- SHA-256 `cw264.webp`:
  `175c58c5220e5cadbdf1eba9ad3b6b4bb08f7b84f8ea0eaf902ce2e810c443a0`.
- Publiczne `/api/health` zwróciło `{"status":"ok"}`. Po wdrożeniu web jest
  healthy; API i push-sender zachowały wcześniejsze identyfikatory obrazów oraz
  czasy uruchomienia.

## Odzyskanie i rollback

Przed promocją utworzono i zweryfikowano backup
`20261010T180207668606Z`: usługa zakończyła się `Result=success` i
`ExecMainStatus=0`, a SHA-256 dumpu
`5a16dfe60bf17bc0ca2259d6da584b3272a61ee8434054eb796eb467fac9c8e0`
zgadza się z manifestem.

Poprzedni obraz web zachowano jako
`fit-web:rollback-1.4.5-12-70091bf98a043f4990032e89db7e62c6550b4b4e5ccee3ebde4b324a4678d06c`
(ID `sha256:70091bf98a043f4990032e89db7e62c6550b4b4e5ccee3ebde4b324a4678d06c`).
Rollback ogranicza się do ponownego oznaczenia tego obrazu jako
`fit-web:production` i odtworzenia wyłącznie usługi `web`; nie obejmuje API,
sendera, migracji, Caddy ani sieci.

## Koszty prób ilustracji

Zarejestrowane górne oszacowania bez cache dla pojedynczych prób Sunburst
medium wyniosły: `cw257` 0,022722 USD, `cw264` 0,023577 USD oraz odrzucone
`cw278` 0,023562 USD. Suma trzech historycznych prób: **0,069861 USD**;
wydane zasoby `cw257` i `cw264`: **0,046299 USD**. W tym wydaniu nie wykonano
żadnego żądania generowania obrazu.
