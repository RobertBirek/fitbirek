# Niezawodny start i jawne przygotowanie offline

## Zgoda i granice

Użytkownik zaakceptował naprawę startu/wznowienia i kontrolowany pakiet offline.
Pozostaje jeden użytkownik. Multi-user jest odłożone zgodnie z
`docs/future-private-accounts.md`. Bez commit/push/deploy, bumpa wersji,
zmiany Flutter 3.35.4/Dart 3.9.2, nowych zależności i zmian danych produkcji.
Zachować niecommitowane repeat/schedule/trends i Drift13.

## 1. Powrót do aktywnej sesji

- Bezpośredni reload `/workout/session` odczytuje stan aktywnego konta i sesji
  z lokalnej bazy. Nie pokazuje mylącego „Wybierz ćwiczenia”, gdy istnieje szkic.
- Pokazać jawne wznowienie, informacje o znalezionej sesji oraz błąd/retry
  zamiast automatycznego tworzenia lub kończenia treningu.
- Wznowienie korzysta z obecnego `resumeSession`; zachowuje UUID, guidance,
  cele powtórzenia i kursor, stronę/wariant, wpisane wartości oraz pauzę timera.
- Nie uruchamiać automatycznie timera, nie dopisywać czasu nieobecności ani serii.
- Obsłużyć brak szkicu/legacy sesję i konflikt wielu aktywnych sesji bez
  arbitralnego wyboru. Zmiana konta i spóźniony odczyt nie ujawniają starego stanu.

## 2. Powłoka i trasy PWA

- Worker instalowany przy zwykłej wizycie zapisuje sprawdzoną powłokę i zapewnia
  równoważne wejście root oraz index.html. Pierwsza wizyta nie wymaga drugiej
  kontrolowanej nawigacji, by root był dostępny po udanej instalacji SW.
- Offline nawigacje HTML do tras aplikacji, w tym `/today`, mają fallback do
  powłoki; zwykłe zasoby i API nigdy nie dostają HTML zamiast brakującego pliku.
- Nie cache'ować API, cookies/sesji, tokenów, exportów ani danych użytkownika.
  Osobny worker `/push/` pozostaje bez zmian.

## 3. Kontrolowany pakiet offline

- Po finalnym buildzie generować deterministyczny manifest statycznych zasobów:
  relatywna ścieżka, rzeczywista liczba bajtów, SHA-256, identyfikator pakietu
  zależny od treści. Nie polegać wyłącznie na numerze aplikacji.
- Pakiet obejmuje powłokę, skrypty/manifesty, lokalny CanvasKit/SQLite,
  katalog, ilustracje, fonty i inne wymagane statyki tej wersji. Wykluczyć
  API, worker/manifests z cyklicznym hashem, source maps i obce originy.
- Pobieranie całego pakietu wyłącznie po jawnym zatwierdzeniu rozmiaru w UI.
  Mały precache powłoki przy instalacji jest niezależny od tej zgody.
- Postęp to liczba/rozmiar zweryfikowanych plików, nie procent upływu czasu.
  Sprawdzać odpowiedź, długość i hash przed zapisem; HTML pod 200 nie wystarcza.
- Przerwanie sieci, anulowanie, błąd integralności, quota lub zatrzymanie SW nie
  mogą dać ready. Retry wykorzystuje poprawne części pakietu. Obsłużyć restart
  aplikacji i wiele kart bez równoległego niszczenia cache.
- Stan ready wynika z kontroli aktualnego kompletnego cache, nie z flagi w
  SharedPreferences. Utrata cache lub aktualizacja pakietu odbiera gotowość.
- Zmiana pakietu nie czyści IndexedDB/Drift ani outboxa. Bez arbitralnego usuwania
  starych cache innych workerów; aktywacja nie może niszczyć jedynej działającej
  powłoki przed przygotowaniem następnej.
- Tryb offline nie jest gwarancją trwałego storage na iOS ani pracy w tle.

## 4. Kontrakt adaptera UI–web

JavaScript udostępnia `window.fitOffline`, o ile platforma obsługuje SW/cache:
`status()`, `prepare({packageId})`, `cancel()` zwracają Promise obiektu JSON.
`prepare({packageId})` wymaga ID pakietu zaakceptowanego w dialogu; brak lub
niezgodność są odrzucane kodem `packageChanged` przed rozpoczęciem transferu.
Nowy pakiet wymaga nowego odczytu i zgody, bez automatycznego pobrania.
Poprawne `prepare({packageId})` rozpoczyna/coalescuje pracę i zwraca snapshot bez oczekiwania na
cały transfer; UI odpytuje status. Status ma pola:

```json
{
  "protocolVersion": 1,
  "state": "notReady",
  "packageId": "content-hash",
  "totalFiles": 0,
  "cachedFiles": 0,
  "totalBytes": 0,
  "cachedBytes": 0,
  "errorCode": null,
  "message": null
}
```

Stany: `unsupported`, `notReady`, `checking`, `downloading`, `ready`, `error`,
`cancelled`. Błędy mają stabilny kod (network/integrity/quota/timeout) i tekst
bez sekretów. Operacje przenosi MessageChannel do kontrolującego workera;
worker nie przyjmuje dowolnych URL/cache name od klienta. Jeśli rejestracja
lub kontroler nie są jeszcze gotowe, UI oferuje ponowne sprawdzenie i nie
udaje przygotowania offline. Odmowa/timeout nie powoduje nieograniczonego await.

## 5. Ekran i akceptacja

- Punkt wejścia w ustawieniach, prawdziwy rozmiar przed zgodą, postęp, anuluj,
  ponów i ponownie sprawdź. Unsupported poza web nie udaje gotowości PWA.
- Rozdzielić „zasoby gotowe offline” od aktualnego konta/danych i oczekujących
  zmian synchronizacji. Nie uruchamiać dodatkowego HTTP auth na odczycie statusu.
- Testy jednostkowe z fake bridge; statyczne/JS worker tests i manifest validation;
  rzeczywisty browser z SW i zatrzymanym originem, czystym profilem i restartem.
- Sprawdzić cold root/deep link, nieodwiedzone ilustracje i emoji po przygotowaniu,
  przerwany transfer/retry i brak fałszywego ready po utracie cache.
- Zachować historyczne FAIL. Fizyczny iPhone/Android nadal wymaga manualnej
  akceptacji; test Chromium nie jest testem instalacji ani usypiania telefonu.
