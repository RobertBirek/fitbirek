# Ilustracje EZ i rower stacjonarny — 2026-10-21

Dodano cztery zaakceptowane ilustracje: `assets/exercises/cw409.webp`–`cw412.webp`.
Zakres obejmuje trzy ćwiczenia EZ i zatwierdzone rozszerzenie o spokojną jazdę
na rowerze stacjonarnym. Wszystkie wcześniejsze **408/408 obrazów pozostały
identyczne bajtowo**, porównane SHA-256 z migawką sprzed pracy.

## Metoda i źródła

Dowody poza repozytorium: `/tmp/opencode/ez-illustrations-20261021` (dalej **R**).
`R/style.png` skonwertowano z istniejącego `cw256.webp`. Prompty:
`R/cwNNN-prompt.txt`. Źródło dla danego wiersza tabeli:
`R/cwNNN/trial-TT/cwNNN-gpt-image-2.5-sunburst-medium.png`; ledger:
`R/cwNNN/trial-TT/ledger.jsonl`.

Każde żądanie uruchomiono istniejącym `tools/benchmark_exercise_images.py
--single-sunburst-medium`: jeden Sunburst medium, jedno PNG 1024×1024,
świeży katalog, bez równoległych żądań, automatycznych retry lub zmiany dostawcy.
Każde źródłowe PNG i jego WebP512 odczytano **indywidualnie przed kolejnym
żądaniem**. Nie było odrzuconych wizualnie źródeł ani korekt.

Konwersja: `convert SOURCE -resize 512x512 -strip -quality 90 preview.webp`.
Zaakceptowane bajty skopiowano do docelowych assetów. Każdy finalny asset
odczytano ponownie indywidualnie. `identify` zdekodował cztery PNG jako
1024×1024 oraz cztery finalne WebP jako 512×512. Migawka starych plików:
`R/before.json`; podsumowanie kontroli: `R/verification.json`.

## Zaakceptowane źródła

| ID | Kadry i kontrola wizualna | TT | Request ID | USD |
|---|---|---|---|---:|
| cw409 | 2; uginanie stojąc, chwyt podchwytem, dłonie pod gryfem; łokcie przy tułowiu | 02 | req_bc7e0d86126148cea215db751fdb7979 | 0.023527 |
| cw410 | 2; uginanie nachwytem, grzbiety dłoni nad gryfem, czytelna pronacja odmienna od cw409 | 01 | req_3c9bc140ab1a40ed8a4f208df7451cfd | 0.023667 |
| cw411 | 2 poziome; leżenie na płaskiej ławce, głowa/plecy/miednica podparte, obie stopy na podłodze, zgięcie łokci sprowadza gryf nad czoło bez kontaktu, ramiona stabilne | 01 | req_b06cd90efa70421690f962ea8a34810c | 0.023867 |
| cw412 | 1; zwykły pionowy rower stacjonarny, stabilna podstawa, siedząca spokojna pozycja, stopy na przeciwnych pedałach, dolne kolano nie zablokowane | 01 | req_91f6eb42f2704a8caeb76a305ca0e432 | 0.023552 |

We wszystkich trzech scenach EZ widoczne są dwie rzeczywiste dłonie,
symetryczne skośne odcinki chwytu, ciągły metalowy łamany gryf i dwa obciążone
końce. Bez zastępowania prostym gryfem/hantlami, podpisów ciężaru lub 40 kg.
Styl: kremowe tło, ciemna odzież, komiksowy kontur, twarze bez rysów.

## Rzeczywiste żądania i koszt

**4 żądania API, 4 `success`, 4 unikalne request ID, 4 zaakceptowane źródła,
0 odrzuceń wizualnych, 0 błędów API, 0 kosztów nieznanych.** Suma końcowych
zdarzeń `success`, deduplikowanych po request ID: **0.094613 USD
(`upper_bound_no_cache`)**. To szacowany górny koszt tokenowy, nie faktura.

Przed pierwszym żądaniem wystąpiło jedno lokalne zatrzymanie narzędzia:
brak katalogu nadrzędnego `cw409` uniemożliwił utworzenie katalogu wyjściowego.
Nie powstał ledger, nie doszło do `send_request` ani wywołania API (kolejność
operacji potwierdzona w narzędziu). Po utworzeniu katalogów użyto świeżego
`trial-02`. Nie był to retry błędu API ani niepewnego żądania; zapis:
`R/preflight-note.txt`. Stąd TT=02 dla cw409 mimo jednego żądania tego ID.

## Ograniczenia i zakres

Wynik kontroli obrazów: **PASS 4/4**. Statyczne ilustracje pokazują wybrane
pozycje, nie tempo, oddychanie, pełny tor ruchu, dobór obciążenia lub wszystkie
zalecenia bezpieczeństwa. Perspektywa skraca dalszą dłoń na kierownicy roweru;
obie stopy i przeciwne pozycje pedałów pozostają widoczne. Zmiana projekcji
załamań EZ przy obrocie przedramion nie jest zmianą sprzętu.

Ta praca zmieniła wyłącznie cztery nowe assety i ten raport. Nie edytowano
katalogu, rejestru Dart, testów, wersji, narzędzia ani historycznych ledgerów;
integrację katalogu/rejestru prowadzi osobna praca. Nie uruchamiano testów
aplikacji, commita, pusha, wdrożenia ani zapisu danych produkcyjnych.
Brak niezakończonych żądań i pracy generującej w tle.
