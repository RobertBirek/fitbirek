# Harmonogram aktywności zewnętrznych i FitBirek

## Zatwierdzony zakres

Użytkownik chce zastąpić stałe karate listą CRUD dowolnych aktywności, np.
Basen niedziela12:30, i zarządzać treningami FitBirek (poranne6:00,
wieczorne18:00), wybierając dni tygodnia i godziny. Przyjął rekomendacje:
jeden harmonogram, dwie listy, opcjonalny szablon, wiele terminów dziennie,
czasowe wyłączenie, opcjonalny czas trwania, Dziś w kolejności czasowej,
offline/sync, zachowanie istniejących ustawień i historii, bez automatycznego
włączania powiadomień. Polecenie „ok, działaj” zatwierdza implementację.

## Decyzje wykonawcze

- Rozszerzamy istniejące weeklySchedule, nie tworzymy drugiego magazynu
  terminów ani kopii WorkoutPlans. Bez nowej tabeli, migracji i zależności.
- Zachować dotychczasowe `rule`/`override` i ich identyfikatory. Nowe rodzaje
  `activityRule`/`activityOverride` w tej samej kolekcji v1, z własną ścisłą
  walidacją. Stary klient uzna nieznany rodzaj za niedostępny i zachowa raw
  przez istniejącą kwarantannę; nigdy nie zmieniać nieczytelnego JSON na pusty.
- Nowa reguła: koperta UserCollections, typ `external`/`fitbirek`, zbiór
  weekdays ISO1..7, `time` HH:mm, `timeZone` Europe/Warsaw, opcjonalne
  durationMinutes1..1440, enabled bool, opcjonalny planSyncId (tylko FitBirek),
  effectiveFromDate. Nazwa1..80 Unicode. Limit kolekcji500/262144B bez prune.
- Reguły edytujemy przez tombstone starego ID i nowy ID w jednej transakcji,
  żeby historyczne snapshoty celów/terminów nie zmieniały się. Edytor przenosi
  pełny optimistic baseline wpisu; równoległe zmiany nie są nadpisywane.
- Wystąpienia UUIDv5(ruleId,originalDate), generowane tylko na żądane okno.
  Wyjątek zawiera snapshot reguły, pierwotny i ewentualnie przesunięty dzień,
  state planned/completed oraz sessionSyncId wyłącznie przy wykonaniu FitBirek.
  Zewnętrzne completed jest jawnym ręcznym potwierdzeniem, nie tworzy sesji/PR.
- Wyłączenie/usunięcie dotyczy przyszłych wirtualnych terminów, nie zapisanej
  historii. Wyjątki pozostają czytelne po usunięciu reguły. Stare wpisy bez
  godziny pokazać jako „Bez godziny”, nie dopisywać domyślnej godziny.
- Start wyłącznie po kliknięciu/potwierdzeniu: istniejący PlannerWorkflow dla
  szablonu, ActiveWorkoutNotifier dla swobodnego; brak/usunięcie szablonu daje
  wyjaśnienie, bez cichego zastąpienia. Nie nadpisywać aktywnej sesji.
- Zakończone FitBirek zaliczamy przez jawny wybór rzeczywistej zakończonej
  sesji z >=1 live set, bez nowych serii. Start może sugerować powiązanie,
  ale samo uruchomienie/termin nie zalicza. Podwójne przypisanie sesji jest
  konfliktem jak dziś. Zdalnie usunięte wykonanie unieważnia zaliczenie.

## Ekrany

Ustawienia → Harmonogram, dwie sekcje „Aktywności zewnętrzne” i „Treningi
FitBirek”, osobne Dodaj, lista nazwa/dni/godzina/czas/szablon/status oraz
Edytuj/Usuń/Włącz-wyłącz. Formularz ma nazwę, wielokrotny wybór dni, timepicker
i dostępne tekstowo godziny, czas trwania, szablon albo trening swobodny.
Nie ukrywać starszych reguł: można je edytować do nowego formatu.
Usunięcie potwierdzane, anulowanie nic nie zapisuje, błąd zachowuje formularz.

Dotychczasowy /schedule pozostaje tygodniowym widokiem wspólnych terminów.
Wejście z ustawień oraz Treningu; bez duplikacji root/sheIl Navigatora.
Dziś: wspólna lista chronologiczna, typ, godzina, status i właściwa akcja;
brak godziny po terminach godzinowych, przy równej godzinie stabilny UUID.
Widoczne w klasycznym Dziś i domyślnym Dziś z Mentorem. Nie zmieniać rozmowy.

## Migracja stałych ustawień i przypomnień

Dotychczasowe przypomnienia i harmonogram to różne źródła. Zachować stare
preferencje i nie włączać uprawnień ani nowych kategorii przez migrację.
Deterministyczne ID legacy per profil umożliwiają idempotentne przeniesienie
karate i codziennego treningu, także przy wielu urządzeniach; tombstone chroni
przed powrotem usuniętego domyślnego wpisu. Nie dodawać co restart nowych UUID.
Legacy karate: wt/czw, start20:00 i istniejące przypomnienie30min wcześniej;
stary push opis19:30 jest godziną przypomnienia, nie dowodem startu19:30.
Legacy trening: codziennie18:00, przypomnienie o terminie. Stare preferencje
false nie stają się true. W razie nieznanego stanu push pokazać stan nieznany,
nie zakładać zgody; zachować działające stare przypomnienia do migracji.

Nowe wpisy mają `reminderEnabled:false` i reminderMinutesBefore0..1440;
oddzielny opt-in wymaga istniejącej zgody lokalnego urządzenia/PWA kategorii.
W UI kategorie push zewnętrzne/treningi opisują harmonogram, nie stałe karate.
Przy migracji istniejące category keys karate/training pozostają na wire dla
zgodności: karate to zewnętrzne, training to FitBirek. Bez aktywnej subskrypcji
nie obiecywać dostarczenia. Nie zmieniać mood/operations/kluczy VAPID.

Backend sender odczytuje zsynchronizowany profil przypisany do subskrypcji,
stosuje wyłącznie poprawne reguły, strefę Warsaw i wyjątki/wyłączenia/tombstone;
przed dostarczeniem ponownie sprawdza aktualny termin. Dedup obejmuje regułę,
originalDate, godzinę/rewizję i instalację. Okno15min jak dziś, bez wielodniowego
catchup. Nie uruchamia AI ani nie tworzy domain records. Stare profile bez
migracji zachowują dotychczasowe przypomnienia do pojawienia się jawnego
deterministycznego legacy wpisu (także tombstone); brak podwójnych dostaw.
Native: przeliczanie reguł po zmianie/sync, cancel starych100/101/200 dopiero
po odczycie zgodnego harmonogramu; IDs dynamiczne stabilne i bez kolizji,
nie cancelAll (mood pozostaje). Logout unieważnia prywatne reminders.

## Bezpieczeństwo i testy

Zachować Flutter3.35.4/Dart3.9.2, Drift13/Alembic0010, deps/lock/WebSQLite.
Auth/account epoch i trwały offline binding sprawdzane przed/po await i
w transakcjach; A-B-A unieważnia formularz. Nie zapisywać przy deferred/hold
lub kwarantannie profilu; nie zmieniać attempted bytes/UUID/CAS base.
Backup/restore remapuje nullable plan/session references nowych i starych
rodzajów; bez heurystyk i bez ingerencji w historię.

Testy RED/GREEN dla CRUD/limits/multiweekdays/multiple same day/time/DST,
legacy idempotence i no reappearance, cancel/accountswitch/stale edits,
dwóch baz i sync+reopen/attempted/NULL/backup remap, active startnooverwrite,
external manual no new logs, Fit real completion and invalidateddeleted,
320px/text200%/realrouter. Push mockedtransport, brak prawdziwych push/AI.
Na koniec pełne Flutter analyze/test i backend pytest jeśli zmieniony sender.
Bez commit/push/deploy w tym zadaniu; to wymaga osobnej dyspozycji.
