# Ilustracje ćwiczeń bez obciążenia — 2026-10-29

**Zaakceptowano wizualnie i zapisano 7/7 ilustracji:**
`assets/exercises/cw425.webp`–`cw431.webp`. Wszystkie wcześniejsze **424/424
assety pozostały identyczne bajtowo** według SHA-256 sprzed i po pracy.
Łącznie katalog obrazów zawiera **431 plików WebP512**.

To lokalny odbiór obrazów przez wykonawcę, nie niezależny przegląd sesji
nadrzędnej, wynik testów Fluttera, builda ani publikacja.

## Końcowy odbiór integracji

Po generacji niezależny przegląd otworzył indywidualnie siedem assetów:
**7 PASS /0 FAIL**, bez wymaganych korekt. cw431 przedstawia boczne odwodzenie
ugiętej nogi; perspektywa nie pozwala potwierdzić liczbowo kątów.
Raport: `R/independent-visual-review.md`.

Focused Flutter: **25 PASS** — dokładne431 ID/pliki/manifest, rzeczywiste
dekodowanie wszystkich obrazów512×512 oraz siedem kart szczegółów z własnymi
ilustracjami bez pending. Analiza całego bieżącego projektu: **No issues found**.
Prywatny build web i generator offline PASS; **508/508 hashów i długości**,
48 608 913B, packageId
`b0d92848cb7b5017dc6412eabb7b73087a68447471e64cecfb1c032775ad3e1c`.
Wszystkie431 obrazów pakietu są bajtowo zgodne ze źródłami; poza CORE, bez
zmiany zgody na pełny pakiet. Nie ponawiano całego Flutter suite ani backendu.

Pierwszy izolowany analyze miał stare testy z narzędziowego obrazu, niezgodne
z aktualnym API logSet. Poprawiono wyłącznie runner: skopiowano także bieżące
test/tests. Drugi przebieg PASS bez zmiany kodu aplikacji. Oba logi zachowano.
Znane ostrzeżenia opcjonalnego Wasm dry-run nie blokują builda JS/CanvasKit.
Brak zmiany wersji, commita, pusha lub publikacji; produkcja pozostaje bez zmian.

## Metoda i dowody

Dowody poza repo: `/tmp/opencode/bodyweight-illustrations-20261029/` (**R**).
Przeczytano `AGENTS.md`, `docs/modules/training.md`,
`docs/modules/bodyweight-catalog.md`, rzeczywiste siedem wierszy
`assets/data/exercises.json`, `tools/bodyweight_additions.py` oraz
`tools/source_data/bodyweight_instructions_en.json`. Wzorzec stanowił raport
sprzętu właściciela z 2026-10-22 i historyczny prompt cw415. Nie prowadzono
nowego badania źródeł w sieci ani nie kopiowano ilustracji wydawców.

`R/style.png` jest lokalną konwersją `assets/exercises/cw256.webp`.
Zachowano kremowe tło, czarne kontury, ciemną odzież i twarz bez rysów;
pominięto pomarańczowe efekty wzorca. Bez liter, liczb, logo, strzałek,
fikcyjnych efektów aktywacji mięśni i obietnic terapeutycznych.

Każde żądanie wykonał istniejący `tools/benchmark_exercise_images.py`
z `--single-sunburst-medium`: **gpt-image-2.5-sunburst, medium, n=1,
PNG1024**. Wyłącznie sekwencyjnie, bez innych modeli, high, flare,
automatycznych retry lub wznawiania katalogów prób. Użyto zatwierdzonego
źródła klucza wyłącznie w pamięci i środowisku procesu potomnego; bez
zapisywania sekretu w argumentach, logach lub dowodach.

Wykorzystano **9 z maksymalnie 11 żądań**: siedem pierwszych prób i dwie
ręczne korekty po odrzuceniu obrazu. Każdy PNG1024 i WebP512 odczytano
indywidualnie narzędziem obrazu przed następnym żądaniem API. Sukces API
nie był traktowany jako akceptacja wizualna. Konwersja:
`convert SOURCE -resize 512x512 -strip -quality 90 preview.webp`.
Tylko zaakceptowane podglądy skopiowano do siedmiu nowych assetów.

Każdy `R/cwNNN/trial-TT/` zawiera dokładny `prompt.txt`, źródłowy PNG,
`preview.webp`, oryginalny `ledger.jsonl` i decyzję `review.json`.
Zachowano również odrzucone próby. `R/before.json`, `R/verification.json`,
`R/provenance.json` i `R/reviews.json` utrwalają hashe, pochodzenie i oceny.
Zweryfikowano hashe promptów i referencji z ledgerem, zgodność zaakceptowanych
podglądów z assetami oraz dekodowanie wszystkich dziewięciu PNG1024,
dziewięciu podglądów WebP512 i siedmiu finalnych WebP512 przez `identify`.

## Odbiór wizualny

| ID | Próba | Ocena techniki i czytelności 512 | Request ID | USD |
|---|---|---|---|---:|
| cw425 | 01 | dłonie na ścianie, całe stopy na podłodze, prosta linia tułów–biodra, odrębna faza zgięcia łokci | req_78730c934eab4cef9751cc99a4c8778b | 0.022772 |
| cw426 | 01 | ta sama szerokość ustawienia stóp, pięty podparte, płytki przysiad i kolana zgodnie ze stopami | req_4e0f5c7bffb74a5fb491818885d57918 | 0.022552 |
| cw427 | 01 | stanie i noga cofnięta na przodostopie, tylne kolano wyraźnie nad podłogą, bez ciężaru | req_40449c4213404183a548749868fa386c | 0.022772 |
| cw428 | 02 | naprzemienne niewysokie uniesienie stóp, jedna stopa podparta w każdym kadrze, pionowy tułów | req_e4a9737d49f34e018eaf1efcd66f74e4 | 0.023462 |
| cw429 | 02 | naprzemienne ugięte nogi, obie dłonie chwytają boki siedziska w obu kadrach, stabilne krzesło | req_1fa57e82a8a040ed9647dccc8194aed5 | 0.023467 |
| cw430 | 01 | wyprost jednej nogi, udo na siedzisku, dłonie swobodnie na udach, bez gumy/ciężarka/przeprostu | req_6dcbbfe8077d46ee9f976027e746a70a | 0.022897 |
| cw431 | 01 | odwodzenie ugiętej nogi w bok, obie dłonie i kolano podporowe na podłodze, bez gumy lub prostego kopnięcia w tył | req_76406fa9ee1b45d4a82749522cdc73b2 | 0.022982 |

### Odrzucenia

- **cw428/01:** ta sama noga i układ ramion w obu kadrach; brak naprzemienności.
  Korekta /02 jawnie przypisała podparcie i uniesienie przeciwnym stronom
  obrazu przy tej samej kamerze od przodu.
- **cw429/01:** powtórzona ta sama uniesiona noga i niepotrzebnie duże
  uniesienie kolana. Korekta /02 zmniejszyła zakres i pokazała obie strony,
  zachowując obie dłonie na siedzisku i niezmienione krzesło.

## Koszt i ograniczenia

**9 rzeczywistych żądań, 9 `success`, 9 unikalnych request ID, 0 błędów API,
0 `uncertain`, 0 nieznanych kosztów.** Suma końcowych zdarzeń `success`,
deduplikowanych po request ID, wynosi **0.206483 USD (`upper_bound_no_cache`)**.
To górne oszacowanie tokenowe z ledgerów, nie faktura; obejmuje dwie odrzucone
próby, nie sumuje wielokrotnie zdarzeń jednego żądania.

Statyczne kadry nie dowodzą tempa, oddychania, płynności, braku podskoku
w całym cyklu ani rzeczywistej stabilności sprzętu. cw427 pokazuje stanie
i zakrok, lecz bez strzałek nie dowodzi samodzielnie kierunku kroku.
Perspektywa cw431 nie pozwala zmierzyć dokładnego kąta odwodzenia;
instrukcja tekstowa nadal ogranicza go do około 45 stopni i dopuszcza mniejszy
zakres. Naturalne zasłonięcia dalszych kończyn są akceptowane, gdy połączenia
anatomiczne i podpory pozostają wiarygodne. Ilustracje nie zastępują instrukcji.

cw430 celowo pokazuje dłonie na udach, zgodnie z rzeczywistą instrukcją,
a nie chwyt siedziska wymagany w cw429. Dla cw427 zachowano autorską adaptację
bez obciążenia; nie przenoszono sztangi z publikacji źródłowej. Dla cw430 nie
przejmowano kontekstu pooperacyjnego ani opcjonalnego dodatkowego oporu.

Zakres wykonawcy: wyłącznie siedem nowych assetów i ten raport. Bez zmian
katalogu, rejestru, kodu, testów, wersji, backendu i wdrożenia. Integracja,
niezależny odbiór wizualny i build należą do sesji nadrzędnej. Nie wykonywano
commita, pusha ani publikacji; brak generacji w tle.
