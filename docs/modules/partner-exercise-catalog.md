# Ćwiczenia indywidualne i w parach

## Lokalne rozszerzenie EZ i rowerek — 2026-10-21

`tools/ez_additions.py` → `tools/expand_ez_catalog.py` → ten sam XLSX →
`tools/xlsx_to_json.py` → `tools/build_catalog_metadata.py`. Nowe ID to
cw409 (uginanie EZ podchwytem), cw410 (nachwytem), cw411 (triceps na ławce
płaskiej) i cw412 (spokojny rowerek, tracking czasu). Sprzęt EZ nie jest
hantlami ani domyślną sztangą; cw411 wymaga też `Ławeczka`. Rowerek wymaga
jawnego `Rower stacjonarny`. Oba generatory sprawdzają wszystkie wymagania.
Ciężar EZ oznacza sumę gryfu i talerzy, nigdy wartość na rękę.

Chroniony prefiks 408 ma własny SHA256 w konwerterze. Replay z historycznego
408-wpisowego fixture i ponowna generacja są testowane, stare zakresy testów
partnerskich pozostają ograniczone do cw370–cw408. Licznik bieżącej walidacji
to 412; nie zmienia to historycznych hashy. Rejestr ilustracji obejmuje nowe ID,
a pliki tworzy niezależny proces. Stan publikacji i osobistych szablonów należy
potwierdzić osobno — lokalne dopisanie katalogu nie instaluje planów na koncie.

## Dane i odtwarzanie

Rozszerzenie 2026-10-20: `cw370–cw392` (23 indywidualne), `cw393–cw408`
(16 partnerskich). Zachowany semantycznie cały prefiks 369 ćwiczeń i metadane.
Źródło: `tools/partner_additions.py` → `tools/expand_partner_catalog.py` → XLSX.
Potem uruchom `tools/xlsx_to_json.py` i `tools/build_catalog_metadata.py`.
`--check` ekspandera sprawdza dane bez zapisu. Stare ekspandery pozostają
idempotentne także po rozszerzeniu. Testy zachowują historyczne hashe.

## Wykonanie i wyszukiwanie

Style `partner` („W parach”) i `pilates` działają przez istniejące fasety i query.
Alias `partnerskie` wyszukuje dokładnie grupę partnerską. Partner jest jawnym
wymaganiem w istniejącym słowniku sprzętu, nie diagnozą i nie stanem innej osoby.
Oba generatory wymagają wszystkich elementów sprzętu, więc brak `Partner`
w wyposażeniu blokuje takie zadania. Zaznaczenie partnera w ustawieniach jest
świadomym opt-in do ich automatycznego proponowania. Piłka to lekka miękka
piłka (w zadaniu reakcyjnym musi się odbijać), nie domyślnie ciężka lekarska.
Ślizgacze i duża piłka gimnastyczna są osobnymi wymaganiami.

Role A/B, zmiana ról, STOP, błędy i regresje są w instrukcjach offline. Rejestrowany
jest wynik użytkownika, nie wynik drugiej osoby. Brak migracji Drift/Freezed,
nowych danych osobowych, nowych endpointów lub zmiany wire synchronizacji.

## Warianty bez nowych ID

Z rozmowy odłożono jako warianty: RDL z gumą → cw063/cw148; Z press → cw065;
floor press jednorącz → cw014; rozciąganie uda w leżeniu → cw262; chód bokiem
bez gumy → cw162; zgięcie grzbietowe z gumą → cw168; zgięcie podeszwowe z gumą
→ cw163. Nie zmieniono starych instrukcji, bo importer istniejącym rekordom
odświeża tylko nazwę PL. Te siedem opisów pozostaje propozycją redakcyjną,
nie jest automatycznie instalowane jako wariant użytkownika w synchronizacji.

Cztery warianty partnerskie w regresjach nowych wpisów: pompka z piątką i
gąsienica z piątką → cw393; utrzymanie półprzysiadu → cw394; przekazywanie
piłki w półprzysiadzie stojąc → cw404. Podstawa nadal definiuje wymagania
wykonania; wariant nie dziedziczy gwarancji filtrów dla innej pozycji.

## Granice

To katalog, nie program dla konkretnego wieku/choroby. Dawki są ostrożnymi
przykładami redakcyjnymi, źródła potwierdzają technikę, nie indywidualną
kwalifikację. Prowadzący powinien ocenić zadania z partnerem. W wydaniu web
1.19.0+34 nowe ID mają placeholder, bez podmieniania obrazów innych ruchów.
Wdrożenie i granice weryfikacji opisuje
`docs/releases/2026-10-20-web-1.19.0-34.md`.

## Ilustracje — wydane w 1.19.1+35

Rejestr, testy i pliki obejmują wszystkie 408 ID, w tym 39 nowych
dedykowanych ilustracji `cw370–cw408`. Sprawdzono zgodność ID i dekodowanie
512×512, przeprowadzono przegląd obrazów oraz Docker verification:
1346 testów PASS, analiza bez problemów. Wydano web 1.19.1+35: publiczne
482/482 pliki pakietu, w tym 408 ilustracji, zgodne bajtowo z kandydatem.
Dowody: `docs/releases/2026-10-20-web-1.19.1-35.md`.
Źródła i sceny: `docs/exercise-illustrations-2026-10-20-results.md`.
Bieżący bilans i historia:
`docs/exercise-illustrations-status.md`.
