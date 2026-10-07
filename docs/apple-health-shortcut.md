# Apple Zdrowie → FitBirek: ręczny Skrót iOS

Status: wersja **1.1.0+3 wdrożona produkcyjnie**; pomiar z hosta
**2026-09-13 10:36:20 Europe/Warsaw (08:36:20 UTC)**. Finalna PWA zawiera
instrukcję offline i etykietę „Wersja 1.1.0 · build 3”.
[Dowody wdrożenia i rollback](apple-health-deployment-2026-09-13.md).
**Odbiór rzeczywistego iPhone/Skrótu: pending.** Deployment nie tworzył tokenu
ani nie importował danych zdrowotnych. Test odczytu i wysłania pozostaje do wykonania na
izolowanym środowisku testowym. Nie udostępniamy niezweryfikowanego pliku
`.shortcut` ani linku iCloud.

## Co trafia do FitBirek

- **Masa**: wybrane pojedyncze próbki masy ciała w kg ze Zdrowia, także z wagi,
  której aplikacja zapisuje masę do Zdrowia. FitBirek nie łączy się z wagą.
- **Kroki**: użytkownik odczytuje dzienny wynik ze Zdrowia i podaje go w Skrócie.
  To **ręcznie potwierdzony dzienny total**, nie automatyczny import kroków.
  Nie sumujemy surowych próbek z Apple Watch i iPhone.
- Kierunek jest tylko jeden: do FitBirek. Nic nie jest zapisywane do Zdrowia.
- PWA nie ma dostępu do HealthKit. Skrót działa na iPhone, po ręcznym uruchomieniu.

Dane są przesyłane przez HTTPS na VPS FitBirek i synchronizowane na zalogowane
urządzenia. Obejmują czas, masę, źródło oraz dzień/liczbę kroków. Nie zachowują
ochrony end-to-end iCloud po opuszczeniu ekosystemu Apple. Backup serwera może
zawierać zaimportowane dane; eksport aplikacji jest osobnym plikiem użytkownika.

## Potwierdzone możliwości i ograniczenia

Dokumentacja sprawdzona 2026-09-11, najpierw źródła Apple:

1. Apple: [Find and Filter](https://support.apple.com/guide/shortcuts/apd3c845e881/ios)
   wymienia rzeczywistą akcję **Find Health Samples**.
2. Apple: [Ask for Input](https://support.apple.com/guide/shortcuts/apd68b5c9161/ios)
   obsługuje liczby i daty.
3. Apple: [Get Contents of URL / POST JSON](https://support.apple.com/guide/shortcuts/apd58d46713f/ios)
   dokumentuje POST i ciało JSON ze zmiennych.
4. Apple: [Priorytety źródeł Zdrowia](https://support.apple.com/en-us/108779)
   opisuje priorytety danych iPhone/Watch/aplikacji. Suma próbek nie jest dowodem
   zgodności z wynikiem wyświetlanym w Zdrowiu.
5. Uzupełniająco katalog Matthew Cassinelli:
   [Find Health Samples](https://matthewcassinelli.com/actions/find-health-samples/)
   i [Get Details of Health Sample](https://matthewcassinelli.com/actions/get-details-of-health-sample/)
   opisują Value, Unit, Start Date, Source. Opcja Group by Day jest opisana,
   ale **nie potwierdza deduplikacji między źródłami**. Nie używamy jej do kroków.

Nie potwierdzono udostępnienia UUID próbki HealthKit przez Skróty. Nie generuj
losowego UUID przy każdym uruchomieniu. Serwer rozpoznaje masę po kanonicznym
czasie UTC, wartości kg i źródle, oddzielnie dla każdego użytkownika.

## 1. Skonfiguruj dostęp

Po udostępnieniu wersji w środowisku testowym zaloguj się do FitBirek →
Ustawienia → Apple Zdrowie. Przeczytaj zgodę na wysłanie danych zdrowotnych
na VPS i wygeneruj token. Token jest pokazywany tylko raz; przechowuj go wyłącznie
w prywatnym Skrócie jako wartość nagłówka **Authorization**.

- Nie umieszczaj tokenu w URL, parametrach zapytania, JSON, notatkach ani logach.
- Nagłówek ma postać `Bearer ` + token skopiowany z dialogu.
- Nie udostępniaj Skrótu zawierającego token; jeśli to się zdarzy, odwołaj token.
- Rotacja od razu wyłącza poprzedni token. Uaktualnij nagłówek w Skrócie.
- Odwołanie wyłącza przyszłe importy, ale pozostawia już zaimportowane dane.

## 2. Najpierw zbuduj minimalny Skrót kroków

Angielskie nazwy akcji poniżej identyfikują je niezależnie od tłumaczenia iOS.

1. Utwórz nowy Skrót w aplikacji Skróty, nazwij „FitBirek — Zdrowie”.
2. W aplikacji Zdrowie otwórz **Aktywność → Kroki**, widok dnia. Odczytaj
   wynik dla wybranego dnia. Używaj dnia **Europe/Warsaw**; przy podróży przez
   strefy nie przypisuj zagranicznego przedziału dnia do dnia warszawskiego.
3. Dodaj **Ask for Input**, typ Text, pytanie „Dzień wyniku ze Zdrowia
   (Europe/Warsaw), YYYY-MM-DD”. Wpisz np. `2026-09-10`.
4. Dodaj **Ask for Input**, typ Number, pytanie „Wpisz dzienny wynik kroków
   widoczny w Zdrowiu dla tego dnia — nie sumę źródeł”. Bez domyślnego zera.
   Brak wyniku oznacza anulowanie, nie wysłanie 0. Wartość 0 wysyłaj tylko,
   gdy rzeczywiście potwierdzasz zero.
5. Dodaj **Dictionary**: `day` (Text: odpowiedź z kroku 3), `value` (Number:
   odpowiedź z kroku 4), `method` (Text: `manual_verified_total`).
6. Dodaj **List** z jednym elementem: powyższy Dictionary.
7. Dodaj **URL** z adresem HTTPS testowego FitBirek i ścieżką
   `/api/integrations/apple-health/import`.
8. Dodaj **Get Contents of URL**, rozwiń opcje:
   - metoda **POST**;
   - Headers: `Authorization` = `Bearer ` + własny token;
   - Headers: `Content-Type` = `application/json`;
   - Request Body **JSON**: `version` Number `1`, `weights` pusta Array,
     `steps` Array zawierająca słownik z kroku 5 (lub zmienna List z kroku 6).
   W edytorze iOS sprawdź typ Array — słownik nie może stać się tekstem JSON.
9. Dodaj **Show Result** dla odpowiedzi API. Nie pokazuj nagłówków/tokenu.
   Sukces ma liczniki `imported`, `duplicates`, `ignoredDeleted` i czas
   `lastImportAt`. Komunikat błędu nie oznacza importu.

Nie dodawaj automatyzacji w tle. Użytkownik uruchamia Skrót i potwierdza wynik.

## 3. Dodaj wybraną masę

Przed akcją URL dodaj:

1. **Find Health Samples**: typ masa ciała/Body Mass (na niektórych wersjach
   Weight), zakres dat ograniczony np. do ostatnich 7 dni, jednostka **kg**,
   bez grupowania, sortowanie Start Date od najnowszych, limit np. 10.
   Zezwól tylko na odczyt masy. Nie dodawaj **Log Health Sample**.
2. **Choose from List** z wyników: wybierz jedną próbkę do przesłania.
   Na pierwszym teście wybierz jedną, nie eksportuj całej historii.
3. **Get Details of Health Sample** dla wybranego elementu: odczytaj
   **Value**, **Unit**, **Start Date** i **Source**. Skontroluj zgodność
   z ekranem Zdrowia. Jeśli Unit nie jest kg, przerwij i popraw konfigurację;
   nie zmieniaj etykiety z lb na kg bez przeliczenia.
4. **Format Date** dla Start Date: ISO 8601 z offsetem lub UTC `Z`,
   np. `2026-09-10T08:00:00+02:00`. Nie używaj czasu uruchomienia Skrótu!
5. **Dictionary**: `measuredAt` Text z datą, `value` Number z Value,
   `unit` Text `kg`, `source` Text z Source. Zachowuj tę samą nazwę źródła
   przy powtórzeniach; maksymalnie 100 znaków, bez danych osobowych w nazwie.
6. W JSON akcji POST zamień pustą `weights` na Array z tym Dictionary.
   Jeśli chcesz przesłać samą masę, pomiń pytania o kroki i ustaw `steps: []`.

Wielokrotny wybór można później obsłużyć **Repeat with Each** i listą słowników,
ale cały batch ma limit 100 elementów i 64 KiB. Nie wysyłaj surowego obiektu
Health Sample — tylko jawnie wymienione pola. Nie doklejaj jednostki do liczby.

## Przykład JSON do skopiowania (bez tokenów)

```json
{
  "version": 1,
  "weights": [
    {
      "measuredAt": "2026-09-10T08:00:00+02:00",
      "value": 80.5,
      "unit": "kg",
      "source": "Apple Health"
    }
  ],
  "steps": [
    {
      "day": "2026-09-10",
      "value": 7500,
      "method": "manual_verified_total"
    }
  ]
}
```

To dane syntetyczne do testu kontraktu, nie polecenie importu na produkcję.
Walidacja obu przykładów z rzeczywistym modelem żądania API, bez sieci i bazy:

```bash
backend/.venv/bin/python tools/verify_apple_health_example.py
```

Liczby JSON używają kropki, bez cudzysłowów. W Skrótach użyj pól Number,
nie sklejania tekstu z polskim przecinkiem dziesiętnym. Data masy musi mieć
offset; `08:00+02:00` i `06:00Z` reprezentują tę samą próbkę.

## Powtórzenia, korekty i usuwanie

- Identyczna masa to duplikat. Zmiana czasu, wartości lub źródła tworzy
  **nową** próbkę; błędną poprzednią usuń osobno w FitBirek.
- Kroki zastępują cały total dnia, nigdy się nie dodają. Nowa wartość może
  być mniejsza. Powtórzenie wcześniej przyjętej wartości po korekcie jest
  ignorowane jako replay: v1 nie pozwala ponownie zastosować starej wartości
  tego samego dnia. Nie obchodź tego zmianą dnia.
- Usunięta próbka pozostaje tombstone i nie odradza się po replay/importach.
  Usunięcie w FitBirek nie usuwa próbki w Apple Zdrowie i odwrotnie.
- Ręczne pomiary FitBirek są odrębne i nie są nadpisywane przez import.
- Nieudany/pusty import nie oznacza zera kroków. Dane z wcześniejszego dnia
  pozostają oznaczone datą; powrót do PWA wymaga udanej synchronizacji.
- Starsza wersja PWA nadal synchronizuje zwykłe dane, ale nie otrzymuje próbek
  zdrowotnych. Aktualny klient deklaruje ich obsługę przez `include_health=true`
  i przy pierwszym uruchomieniu jednorazowo pobiera historię od początku.
  Od schematu v7 używa osobnego pełnego kursora: zapis starej karty, nawet
  spóźniona odpowiedź jej synchronizacji, nie przesuwa postępu nowego klienta.
  Przy dużej historii ten pierwszy odczyt może potrwać dłużej; przerwany odczyt
  wznawia się z trwale zapisanego kursora i nie usuwa oczekujących operacji.

### Kopie zapasowe

Próbki Apple Zdrowie są rekordami publikowanymi przez serwer. Przywracanie
kopii aplikacji nie tworzy z nich nowych importów i nie kasuje istniejących
próbek ani oczekujących usunięć. Dotyczy to również starszych kopii bez sekcji
zdrowotnej. Na nowym urządzeniu zaloguj się na właściwe konto i zsynchronizuj
dane z serwera; sam plik kopii nie odtwarza autorytatywnej historii importów.
To zapobiega odradzaniu usuniętych próbek przez stary backup oraz blokowaniu
outbox operacjami tworzenia, których API celowo nie przyjmuje. Token nie jest
częścią kopii aplikacji.

## Ręczna bramka akceptacji iPhone — jeszcze niewykonana

Na testowym koncie i testowym serwerze HTTPS, po review implementacji:

- [ ] Zapisz model iPhone, wersję iOS i język; potwierdź nazwy akcji i pola.
- [ ] Odczytaj jedną rzeczywistą próbkę masy z wagi; sprawdź kg, czas i źródło.
- [ ] Porównaj JSON przed siecią z przykładem; obejrzyj bez nagłówka tokenu.
- [ ] Potwierdź total kroków dla dnia, w którym używano iPhone i Watch.
- [ ] Wyślij, sprawdź Dziś/Postępy oraz drugi zalogowany klient.
- [ ] Powtórz ten sam batch: brak dodatkowej masy i brak podwojonych kroków.
- [ ] Sprawdź nowy total, replay starego totalu, usunięcie i ponowny import.
- [ ] Wyłącz sieć PWA: ostatnie dane nadal widoczne ze świeżością i źródłem.
- [ ] Rotacja i revoke: stary token odrzucony, dane zachowane.
- [ ] Odmowa zgody Zdrowia/brak próbki/anulowanie pytania: bez fałszywego zera.

Automatyczne testy API/UI nie zastępują tego testu sprzętowego.
