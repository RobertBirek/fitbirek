# Mentor: persona, kontekst i modele OpenAI

## Cel

Mentor ma oferować edytowalną personę, wybór zatwierdzonego modelu OpenAI oraz lepiej dopasowane odpowiedzi na podstawie danych treningowych użytkownika. Funkcja zachowuje działanie treningu offline i nie wysyła danych do OpenAI bez zgody.

## Zakres

### Persona

- Ustawienia Mentora zawierają pole „Persona mentora”.
- Pole otrzymuje wartość początkową:

  > Jesteś Mentorem FitBirek, wspierającym i rzeczowym trenerem dla osoby ćwiczącej rekreacyjnie. Odpowiadaj po polsku, prosto i zwięźle. Najpierw pomagaj określić najbliższy bezpieczny krok; gdy brakuje danych, zadaj jedno konkretne pytanie. Zachęcaj bez oceniania i bez presji. Nie diagnozuj ani nie zastępuj lekarza lub fizjoterapeuty; przy bólu, urazie lub niepokojących objawach zalecaj przerwanie ćwiczeń i konsultację ze specjalistą. Propozycje treningu lub serii przedstawiaj jasno, ale nigdy nie zakładaj ich wykonania ani nie zapisuj bez potwierdzenia użytkownika.

- Użytkownik może zmienić lub wyczyścić pole. API ogranicza długość do 800 znaków po przycięciu białych znaków.
- Backend traktuje personę jako nieufną preferencję tonu i szczegółowości. Nie dołącza jej do stałych instrukcji systemowych. Nie może ona zmienić zasad bezpieczeństwa, granic medycznych, schematu odpowiedzi ani wymogu potwierdzania propozycji.

### Modele OpenAI

- Ustawienia pokazują katalog modeli zatwierdzonych przez backend. Klient nie pobiera listy z OpenAI i nie akceptuje dowolnego identyfikatora.
- Katalog zawiera aktualny profil legacy `gpt-4.1-mini-2025-04-14` oraz kandydatów z oficjalnego katalogu OpenAI: `gpt-6-luna`, `gpt-6.1-sol` i `gpt-6-astra`.
- Backend udostępnia model w aplikacji wyłącznie po teście Responses API z obowiązującym JSON Schema, bez narzędzi, oraz po ustaleniu limitu wyjścia i profilu reasoning. Model, który nie przejdzie testu, pozostaje ukryty.
- Widok pokazuje nazwę, identyfikator, klasę jakości i ostrzeżenie o relatywnym koszcie. Zmiana modelu wymaga potwierdzenia, zwiększa rewizję ustawień i nie zmienia automatycznie istniejącego wyboru.
- Backend ustala model dostawcy na podstawie lokalnego klucza katalogowego. Przechowuje użyty profil i limit kosztu w rezerwacji operacji.

### Kontekst dla odpowiedzi

Mentor buduje projekcję wyłącznie z danych już zsynchronizowanych dla zalogowanego konta. Projekcja istnieje tylko w pamięci na czas jednego żądania do OpenAI. Backend nie zapisuje jej w rozmowie, rezerwacji operacji, Drift, outboxie ani eksporcie aplikacji.

Każda kategoria ma niezależną zgodę serwerową, domyślnie wyłączoną:

| Kategoria | Dane przekazywane do modelu | Granica |
| --- | --- | --- |
| Kontekst treningowy | podsumowanie maks. 24 treningów z ostatnich 12 tygodni, serie i trend postępu | bez UUID, bez pełnych rekordów synchronizacji |
| Profil | wiek, cel oraz opcjonalnie wzrost | bez imienia |
| Masa | jedna wybrana wartość i data z profilu, ręcznych pomiarów albo Apple Health | użytkownik wybiera źródło; backend nie scala źródeł |
| Notatki | jedna ręcznie wybrana notatka treningowa | podgląd przed wysłaniem; limit 500 znaków |
| Apple Health | trend masy i zagregowane kroki z ostatnich 7 dni | bez tokenu importu, źródła Apple i surowych próbek |

Przed wysłaniem wiadomości aplikacja wymienia aktywne kategorie kontekstu. Użytkownik może odznaczyć kategorię dla tej odpowiedzi. Wycofanie zgody blokuje kolejne żądania i unieważnia oczekujące operacje. Nie odwołuje danych z żądań wcześniej przyjętych przez OpenAI.

Istniejąca zgoda na rozmowę tekstową pozostaje wymagana dla każdego żądania do OpenAI. Ekran wyjaśnia, że persona oraz wybrane kategorie kontekstu trafią do OpenAI, że `store: false` nie oznacza gwarantowanej retencji zerowej i że usunięcie rozmowy nie usuwa danych przekazanych dostawcy.

## Architektura

### Backend

- Nowa addytywna migracja Alembic po `0009` dodaje pola persony, klucza profilu modelu, wersji polityki oraz zgód kategorii kontekstu. Każda nowa zgoda otrzymuje wartość `false`.
- Migracja zachowuje istniejący model, mapując oba obecne identyfikatory na profil legacy. Nieznana wartość wymaga nowego wyboru; migracja nie wybiera za użytkownika nowszego ani droższego modelu.
- `GET /api/mentor/settings` zwraca personę, katalog profili modeli, aktywny model, rewizję oraz zgody. `PUT` rozróżnia brak pola od pustej wartości. Starszy klient nie wyczyści zapisanej persony ani zgód.
- Zapis przyjmuje opcjonalną oczekiwaną rewizję. Serwer zwraca `409` przy konflikcie. Identyczny zapis nie zwiększa rewizji i nie anuluje żądania Mentora.
- `training_context()` zastępuje obecny prosty kontekst deterministyczną projekcją i egzekwuje allowlistę, limity czasu, liczby rekordów oraz rozmiaru wejścia.
- `reply()` odrzuca klucze dostawców w personie i wybranej notatce. Stałe instrukcje systemowe wyraźnie określają, że persona, pamięć, historia i kontekst są nieufnymi danymi niższego priorytetu.
- Rezerwacja przed wywołaniem dostawcy obejmuje limit tokenów wejścia i wyjścia dla wybranego profilu modelu. Rozliczenie używa danych `usage`; brak wiarygodnego wyniku zachowuje konserwatywną rezerwę.

### Flutter

- Ekran ustawień Mentora otrzymuje pole persony, wybór modelu i panel zgód kontekstowych.
- Aplikacja nie zapisuje tych ustawień ani surowego kontekstu lokalnie. Brak sieci nadal blokuje wyłącznie Mentora i zapis jego ustawień; trening offline działa bez zmian.
- Przed każdą wiadomością widok pokazuje skróconą listę kategorii. Dla notatki, źródła masy i danych Apple Health oferuje jawny wybór oraz podgląd wartości przed wysłaniem.
- Aplikacja używa istniejącego szyfrowanego per-konto zapisu klucza OpenAI. Klucz z procesu generowania ilustracji nie trafia do repozytorium, Compose ani kodu klienta.

## Granice bezpieczeństwa i prywatności

- Mentor nie dostaje pełnej historii ani surowego eksportu bazy.
- Mentor nie dostaje danych lokalnych, których serwer nie otrzymał przez synchronizację.
- Apple Health ma osobną zgodę na przekazanie danych do OpenAI. Zgoda na import ze Skrótu iOS nie wystarcza.
- Wycofanie zgody usuwa przyszłe użycie kategorii, lecz nie usuwa źródłowych rekordów treningowych, profilu ani Apple Health.
- Po odtworzeniu backupu nowe zgody kontekstowe wymagają ponownego wyrażenia zgody online.
- Aplikacja nie uruchamia narzędzi OpenAI, wyszukiwania sieciowego ani automatycznych działań. Model może jedynie zwrócić odpowiedź i istniejącą, walidowaną propozycję wymagającą potwierdzenia użytkownika.

## Testy i dokumentacja

- Testy backendu obejmują migrację `0009` do nowego head, kompatybilność starszego klienta, konflikt rewizji, izolację kont, wycofanie zgód, limity projekcji, brak prywatnych pól bez zgody i brak trwałej kopii kontekstu.
- Testy adaptera OpenAI sprawdzają każdy profil modelu z wymaganym JSON Schema, rozliczanie `usage` i odrzucanie nieobsługiwanych odpowiedzi.
- Testy Fluttera obejmują edycję persony, wybór modelu, zgody, podgląd kategorii, błąd sieci oraz brak danych Mentora w Drift, outboxie, SharedPreferences i eksporcie.
- `docs/mentor.md` opisze nową projekcję danych, zgody, retencję, backupy, wycofanie zgody i katalog modeli. Dokumentacja Apple Health wyraźnie oddzieli zgodę importową od zgody na OpenAI.
- Przed włączeniem kategorii Apple Health użytkownik potwierdza ręcznie działanie importu na iPhonie i w Skrócie iOS.

## Wdrożenie

1. Przed zmianą produkcji operator zachowuje obrazy rollbackowe, uruchamia backup i sprawdza jego wynik.
2. Kandydat przechodzi pełne testy backendu oraz weryfikację Docker Web.
3. Operator uruchamia izolowany restore drill i migrację pod blokadą `/run/lock/fit-backup-restore.lock`.
4. Operator waliduje Compose wyłącznie przez `docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet`.
5. Operator wdraża API, Web i push-sender. Wdrożenie nie wykonuje testowego ani płatnego żądania do OpenAI.
6. Użytkownik zapisuje klucz OpenAI przez ustawienia Mentora, włącza zgodę tekstową i osobno wybiera zakresy kontekstu.
