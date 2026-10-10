# Image Cost Benchmark Implementation Plan

**Goal:** Dostarczyć standard-library CLI porównujące trzy zatwierdzone konfiguracje obrazów; implementacja i weryfikacja wyłącznie offline.

**Architecture:** Jeden sekwencyjny runner, multipart POST do `/v1/images/edits`, bez retry i przekierowań. Nowy katalog wyjściowy stanowi blokadę ponownego uruchomienia. Append-only `ledger.jsonl` jest synchronizowany na dysk przed każdym żądaniem oraz przed dekodowaniem obrazu. PNG są osobnymi plikami.

**Tech Stack:** Python standard library, unittest, urllib, Decimal.

## Zakres i kontrakt

- CLI: `--prompt PATH --reference PATH --output-dir PATH --exercise-id cwNNN`; klucz wyłącznie z `OPENAI_API_KEY`.
- Kolejność: `gpt-image-2.5-sunburst/medium`, `gpt-image-2.5-sunburst/high`, `gpt-image-2.5-flare/medium`; każda `1024x1024`, `n=1`, PNG.
- Sukces pełnego przebiegu oznacza dokładnie trzy żądania. Błąd zatrzymuje przebieg bez retry; timeout/network ma status niepewny. Istniejący katalog nie jest wznawiany ani nadpisywany.
- Ledger zawiera wyłącznie konfigurację, SHA-256 wejść, czas, oczyszczone liczniki usage, request ID, status i estymatę USD. Bez treści promptu, ścieżek wejść, klucza, odpowiedzi base64 i surowych błędów.
- Stawki obu modeli (USD/1M tokenów): tekst 5, obraz 8, output 30, cached tekst 1.25, cached obraz 2. Obliczenia Decimal, zapis jako string. Cache bez wiarygodnego podziału modalności oznacza jawne `upper_bound_no_cache`; brak lub niepełne usage oznacza `unknown`, nigdy domyślne zero.
- Zmiany tylko w runnerze, jego testach i niniejszym planie; bez commitów i płatnych wywołań podczas implementacji.

## Kroki

- [x] Dodać `tools/tests/test_benchmark_exercise_images.py`: koszt zwykły i cache, brak/niepełne usage, sanitizacja, multipart i kolejność, blokada katalogu, ledger przed żądaniem i dekodowaniem, HTTP/timeout bez retry, CLI offline.
- [x] RED: `python3 -m unittest discover -s tools/tests -p 'test_benchmark_exercise_images.py' -v`; 11 niepowodzeń z powodu brakującego runnera.
- [x] Dodać `tools/benchmark_exercise_images.py`: `estimate_cost`, sanitizacja liczników, multipart, transport bez redirect, sekwencyjny runner i CLI ze stałymi bezpiecznymi komunikatami.
- [x] GREEN: powtórzyć powyższy unittest; 14 testów OK, atrapy transportu zastępują wszystkie wywołania sieciowe. Dodatkowy test przerwanej odpowiedzi HTTP ujawnił nieobsługiwany `IncompleteRead`; po obsłużeniu `HTTPException` status jest `uncertain` bez retry.
- [x] Sprawdzić `python3 tools/benchmark_exercise_images.py --help` i `git diff --check`; oba polecenia zakończone kodem 0. Uruchomienie i ograniczenia estymacji poniżej.

## Uruchomienie po implementacji (płatne, wyłącznie przez użytkownika)

```bash
python3 tools/benchmark_exercise_images.py --prompt /path/prompt.txt --reference /path/reference.png --output-dir /path/new-benchmark --exercise-id cw265
```

Klucz powinien być już ustawiony w środowisku. Nie używać ponownie katalogu poprzedniej próby: `started` bez zakończenia może oznaczać naliczony koszt. `estimated_cost_usd.kind` rozróżnia `estimate`, `upper_bound_no_cache` i `unknown`. Jawny podział cache jest odczytywany z `input_tokens_details.cached_tokens_details.{text_tokens,image_tokens}`; nieznane schematy cache nie uprawniają do rabatu.
