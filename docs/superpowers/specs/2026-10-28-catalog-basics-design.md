# Etap 2 — siedem podstawowych ćwiczeń bez obciążenia

## Cel i autoryzacja
Użytkownik polecił wykonać etap 2, a następnie etap 3 od razu, kontynuując
wcześniejszy wybór izolowanego worktree. Zakres etapu 2 to wybieralne podstawowe
ćwiczenia, które dotąd występowały jedynie w opisach regresji lub wariantach
z obciążeniem. Implementacja nie oznacza automatycznej publikacji na produkcji.

## Zakres danych
- cw425: Pompki od ściany / Wall push-up.
- cw426: Przysiad bez obciążenia / Bodyweight squat.
- cw427: Zakroki bez obciążenia / Bodyweight reverse lunge.
- cw428: Marsz w miejscu / March in place.
- cw429: Marsz w siadzie / Seated march.
- cw430: Prostowanie kolana w siadzie bez gumy / Seated knee extension.
- cw431: Odwodzenie ugiętej nogi w bok w klęku podpartym bez gumy /
  Bodyweight fire hydrant.

Nie są to nowe warianty użytkownika ani zmiany dawnych ID. Wybór i generowanie
planów mają działać przy rzeczywiście wymaganym sprzęcie i pozycji, także
dla filtrów bez podłogi/klęku/podpierania rękami/skoków, tam gdzie jest to prawdą.
Krzesło jest wymagane dla cw429/cw430; ściana nie jest dodatkową kategorią
sprzętu, lecz warunkiem instrukcji cw425. Nie zakładać gumy/hantli/maty ani
nie zaznaczać nowego wyposażenia w profilach.

## Treść i pochodzenie
Opisy PL/EN, wskazówki, błędy, tempo, dawka startowa, progresja i regresja
mają być autorskie, konkretne, zachowawcze i bez obietnic leczniczych lub
redukcji miejscowej. Źródła muszą być jawne i weryfikowalne. Nazwy ruchów mogą
odpowiadać materiałom użytkownika, ale nie kopiujemy tekstów, zdjęć ani grafik
z poradnika/Google Drive. Nie uruchamiamy płatnego generowania ilustracji.

Decyzja wykonawcza: nowe pozycje mogą mieć jawny tekstowy fallback ilustracji,
zamiast niezweryfikowanego obrazu. Musi być oddzielnie wskazane, że ilustracje
tych siedmiu pozycji oczekują; istniejące424 ilustracje pozostają kompletne
i bajtowo niezmienione. Nigdy nie podstawiać obrazu innego ruchu.

## Pipeline i zachowanie danych
Źródłem pozostaje XLSX i `tools/xlsx_to_json.py`, bez ręcznej edycji bazy SQLite
lub wycofanego generatora. Wymagana reprodukowalność JSON, źródeł, nazw,
metadanych i warunków. Dotychczasowy surowy prefiks424, korekty katalogu,
ilustracje i istniejące hashe muszą pozostać bez zmian.

Import424→431 dopisuje wyłącznie nowe ID, bez modyfikacji historii, ulubionych,
wariantów, outboxa lub profilu. Ponowny import jest bez zapisów. Bieżąca projekcja
katalogu używana przez Mentora i offline cache nie może rozjechać się z klientem.
Sama treść katalogu nie wymaga migracji ani zmiany schematów wire.

## Kryteria odbioru
1. Dokładnie431 niepowtarzalnych ciągłych ID; pierwsze424 rekordy identyczne.
2. Wszystkie7 wpisów mają pełną treść, poprawne metadane i źródła; JSON
   odtwarza się z XLSX bez różnic.
3. Bez sprzętu nowe cw425/cw426/cw427/cw428/cw431 są dostępne, a ćwiczenia
   wymagające krzesła nie pojawiają się bez krzesła. Filtry wykonania działają
   na realnych pozycjach, nie na opisach dawnych regresji.
4. Upgrade zachowuje lokalne dane i sync; drugi import nie zwiększa total_changes.
5. Wszystkie stare424 ilustracje są bez zmian; nowy fallback działa w UI i offline.
6. Testy pipeline/klienta/projekcji katalogu przechodzą bez osłabiania kontroli.

## Ograniczenia
Flutter3.35.4/Dart3.9.2 bez upgrade i nowych zależności aplikacji. Bez resetu
danych, publikacji, zmiany wersji wydania lub konfiguracji produkcyjnej.
Etap3 może zacząć implementację dopiero po odbiorze etapu2.
