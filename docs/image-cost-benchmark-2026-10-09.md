# Pomiar kosztów ilustracji — 2026-10-09

## Metoda

Trzy pojedyncze wywołania images/edits, bez ponowień. cw261 (standing quad
stretch), jeden kadr. Identyczny prompt zapisany w
`docs/superpowers/specs/2026-10-09-cw261-benchmark-prompt.txt`, referencja cw256
przekonwertowana bez zmiany wymiarów na PNG. Rozmiar wyjściowy 1024×1024.
Nie wdrożono żadnego z trzech wyników benchmarku. Wydane cw261 powstało później
z lokalnie poprawionego wariantu; jego status opisuje
`docs/exercise-illustrations-status.md`.

Narzędzie: `tools/benchmark_exercise_images.py`. Testy offline:
`python3 -m unittest discover -s tools/tests -p 'test_benchmark_exercise_images.py' -v`
— 14/14 zaliczone. Ledger zapisuje rozpoczęcie przed żądaniem, usage przed
dekodowaniem i blokuje ponowne wykorzystanie katalogu.

## Wyniki usage i estymacja

Każde wywołanie: 358 tokenów tekstowych + 1024 tokeny obrazu wejściowego.
API nie podało informacji o cache, więc wyliczenia są górną granicą przy
standardowych stawkach bez rabatu cache, nie potwierdzonym obciążeniem konta.
Stawki USD / milion: tekst 5, obraz wejściowy 8, obraz wyjściowy 30.

| Konfiguracja | Tokeny wyjściowe | Koszt USD bez rabatu cache | Czas do odpowiedzi |
|---|---:|---:|---:|
| Sunburst medium | 439 | 0.023152 | 17.5 s |
| Sunburst high | 1756 | 0.062662 | 37.8 s |
| Flare medium | 439 | 0.023152 | 11.7 s |

Suma trzech żądań: **0.108966 USD**. Sumować tylko zdarzenia końcowe dla
poszczególnych żądań, nie wielokrotne wpisy started/response_received/success.
Przykład: (358×5 + 1024×8 + 439×30) / 1000000 = 0.023152 USD.

Ledger i PNG znajdują się w `/tmp/opencode/cw261-cost-benchmark-01/`.
Request IDs do uzgodnienia z dostawcą:
- Sunburst medium: `req_d5971e19979f4303ae5eaaa3e435cb0d`
- Sunburst high: `req_c2af9f6fe9fe48499ff2ffa491e7c125`
- Flare medium: `req_616747ff41b14e549a46de23ce7ea315`

## Oględziny wyników

- Wszystkie zachowują rozpoznawalny kremowy, komiksowy styl i pokazują całe
  ciało w rozpoznawalnej pozycji rozciągania uda.
- Sunburst medium: czytelny pomarańczowy czworogłowy; turkus umieszczony po
  stronie nogi rozciąganej zamiast lewej podporowej. Odrzucony bez korekty.
- Sunburst high: ostrzejsze granice oznaczeń, lecz ten sam błąd strony
  stabilizatora. Wyższa jakość nie usunęła błędu znaczeniowego. Odrzucony.
- Flare medium: czytelna pozycja, ale turkusowe obszary pojawiają się po obu
  stronach i wychodzą poza wskazaną lokalizację. Odrzucony bez korekty.
- Różni się obuwie, którego prompt nie ustalił. W dalszych scenariuszach trzeba
  to określać dla spójności serii. Żaden wynik nie stanowi certyfikacji anatomii.

## Wniosek

Medium kosztowało w tym pomiarze około **63% mniej** niż high. Flare medium
był szybszy, ale kosztował tyle samo co Sunburst medium. Brak zwycięzcy pod
względem zaakceptowanej ilustracji: wszystkie trzy wymagają korekty oznaczeń.
Nie wyliczamy więc pozornie niskiego kosztu gotowego ćwiczenia.

Do dalszego kontrolowanego testu rekomendowane Sunburst medium, bez masowej
produkcji. Trzeba sprawdzić oddzielne oznaczanie stabilizatora i scenę 3–4
kadrową, zanim rozszerzymy wynik jednego ćwiczenia na cały katalog.

Orientacyjna arytmetyka przy identycznym usage i jednej próbie/ćwiczenie:
24 obrazy medium = 0.555648 USD, high = 1.503888 USD. Nie jest to budżet
zaakceptowanych zasobów: nie obejmuje poprawek, innych promptów, modeli
pomocniczych, podatków ani kosztów pracy. Faktyczną należność potwierdza
panel rozliczeniowy OpenAI, nie sam lokalny kalkulator.
