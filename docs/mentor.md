# Mentor treningowy: prywatność i operacje

Mentor jest funkcją opcjonalną. Bez poprawnie zamontowanego klucza głównego
oraz klucza wybranego dostawcy API pozostaje niedostępny; aplikacja i klasyczny
tryb offline nadal działają. Sam odczyt ustawień nie kontaktuje się z dostawcą.

## Bramy przed włączeniem

Wdrożenie schematu, web/API oraz overlayu z lokalnym kluczem głównym jest
dozwolone bez włączenia operacji zewnętrznych: klucze providerów muszą pozostać
nieobecne, a zgody tekst/głos `false`. Gotowość storage oznacza wyłącznie
zweryfikowane szyfrowanie lokalne, nie gotowość modelu ani głosu.

Przed rzeczywistym użyciem providerów operator musi ręcznie potwierdzić:

1. zgodę użytkownika na tekst oraz osobno na głos;
2. świadomą decyzję o użyciu OpenAI i/lub ElevenLabs, wraz z aktualną oceną
   umowną, regionu przetwarzania i retencji po stronie dostawcy;
3. ręczną akceptację sprzętową nagrywania i odtwarzania na docelowych
   urządzeniach oraz przeglądarkach.

Po tych bramach test połączenia z dostawcą uruchamia ręcznie użytkownik lub
operator z jego wiedzą. Test oraz ręczne odświeżenie listy głosów są liczone do
limitu i mogą wywołać płatne żądanie; wdrożenie, backup, restore i walidacja
Compose ich nie uruchamiają. W tym wydaniu nie wykonano płatnych testów
dostawców.

Nie deklarujemy usuwania danych ani trybu zero-retention po stronie dostawców:
odpowiednie ustawienia mogą wymagać planu enterprise lub osobnej umowy. Nie
włączaj tej funkcji na podstawie samej dokumentacji technicznej.

Do dostawców trafiają wyłącznie świadomie wysłany tekst użytkownika, zatwierdzona
pamięć mentora, ograniczony kontekst treningowy po stronie serwera i ewentualnie
audio przesłane do transkrypcji. Nie wysyłaj domyślnie danych profilu, masy,
kroków, Apple Zdrowie, prywatnych dokumentów, zrzutów bazy ani kluczy.

## Kontekst wybierany dla każdej wiadomości

Zgoda na tekst pozostaje warunkiem wysłania wiadomości do OpenAI. Niezależnie od
niej ustawienia zawierają osobne, domyślnie wyłączone zgody na kategorie
kontekstu: **trening**, **profil treningowy**, **masa ciała**, **notatka
treningowa** i **Apple Health**. Włączenie kategorii nie wysyła danych samo w
sobie ani nie jest zgodą na inną kategorię.

Przed wysłaniem tekstu użytkownik otwiera okno „Kontekst tej wiadomości” i dla
tej konkretnej wiadomości włącza lub wyłącza dostępne kategorie. Wybiera też
jeden pomiar masy oraz jedną notatkę, jeżeli chce je dołączyć. Okno pokazuje datę
i wartość pomiaru oraz podgląd wybranej notatki; opcje i podglądy istnieją tylko
w otwartym komponencie klienta. Nie są zapisywane w lokalnym eksporcie ani jako
osobna historia podglądów.

Kontekst treningowy obejmuje najwyżej **24 najnowsze sesje z ostatnich 12
tygodni**, po maksymalnie cztery rozpoznane serie na sesję. Dołączany profil to
wyłącznie prawidłowe dane celu, wieku i — jeśli dostępny — wzrostu. Dla Apple
Health do OpenAI trafia co najwyżej podsumowanie kroków z ostatnich 7 dni
(suma i liczba dni z danymi) oraz trend masy z tego samego okresu, a nie surowe
próbki. Zgoda Apple Health dotyczy wyłącznie tego podsumowania dla Mentora; nie
jest zgodą na import przez Skrót iOS ani nie zmienia tokenu importu.

Serwer przyjmuje dla wiadomości tylko przełączniki i nieprzezroczyste selektory
rekordów. Sprawdza aktualność ustawień oraz zgody ponownie przed wywołaniem
dostawcy, a właściwy projekcyjny kontekst buduje wyłącznie w pamięci. Treść
źródłowych danych pozostaje w ich istniejących rekordach synchronizacji; Mentor
nie tworzy dodatkowej kopii wybranego kontekstu. Zapis operacji idempotentnej
może zachować techniczny wybór kategorii i selektory, lecz nie projekcję danych.

## Klucz główny i overlay

`deploy/compose.mentor.yaml` jest opcjonalnym overlayem wyłącznie dla `api`.
Ustawia `MENTOR_MASTER_KEY_FILE` na sekret kontenera i nie tworzy klucza ani
nie instaluje żadnego oprogramowania w runtime. Brak pliku oznacza, że backend
ma pozostawić mentora niedostępnego.

Operator tworzy niezależny klucz Fernet poza repozytorium oraz poza `/docker` i
`/etc`, na przykład w `/var/lib/fit-mentor-secrets/master.key`. Przed ustawieniem
uprawnień ustala numeryczny UID i GID obrazu API w izolacji, bez sieci i bez
montowania sekretu, na zatwierdzonym lokalnie obrazie: `docker run --rm --network
none fit-api:production id`. Katalog nadrzędny ma należeć do roota i mieć tryb
`0700`; plik ma należeć do wykrytego UID:GID API i mieć `0400`, aby czytać go
mógł wyłącznie użytkownik API oraz root. Nie używaj pliku root:root `0400`: proces
API działa jako użytkownik `app` i nie odczyta takiego bind mountu.

W Compose sekret ze źródła `file:` jest bind mountem; pola `uid`, `gid` i `mode`
nie zapewniają wiarygodnej zmiany właściciela ani trybu dla takiego źródła.
Bezpieczeństwo zapewniają zatem uprawnienia pliku na hoście, nie metadane
Compose. Ten katalog nie jest objęty obecnym zakresem Restic, więc klucz wymaga
osobnego, szyfrowanego escrow i udokumentowanej kontroli dostępu. Nie zapisuj
klucza w `.env`, w repozytorium ani w dumpie PostgreSQL.
Lokalna instalacja z pustym magazynem poświadczeń może poprzedzać escrow;
nie jest jego realizacją. Przed zapisaniem wartościowych kluczy providerów
użytkownik/operator musi zapewnić oddzielny szyfrowany backup poza hostem,
kontrolę dostępu i sprawdzić odzyskanie oryginalnego klucza. Do tego czasu
status odzyskania poza hostem pozostaje oczekujący. Nie tworzyć zastępczej
kopii na tym samym hoście ani nie zmieniać wspólnego Restic.

Po ręcznej instalacji szablonu jako `/docker/fit/compose.mentor.yaml` wszystkie
komendy Compose dotyczące aktywnego mentora muszą zawierać ten plik (oraz,
jeśli zainstalowany, istniejący `compose.push.yaml`). Przed użyciem operator
waliduje konfigurację wyłącznie przez `docker compose ... config --quiet`; nie
wyświetla rozwiniętej konfiguracji.

## Retencja, backup i odtworzenie

Historia nie wygasa automatycznie. Użytkownik usuwa rozmowy, czyści zatwierdzoną
pamięć i usuwa klucze w aplikacji. Usunięcie rozmowy usuwa treść jej wiadomości
oraz zapisane kopie odpowiedzi idempotencyjnych i blokuje spóźniony zapis.
Pozostają techniczne identyfikatory, digest żądania, stan i czas operacji;
liczniki oraz te minimalne dane nie są zerowane przez kasowanie rozmów, aby nie
obchodzić limitów ani deduplikacji. Nie ma automatycznego usuwania tych metadanych
w v1. Usunięcie w aplikacji nie odwołuje danych już przekazanych dostawcy.
Kopia usuniętych danych może pozostać w lokalnych bundle'ach do ich rotacji:
zachowywane jest ostatnie 35 pełnych backupów, a starsze mogą dodatkowo żyć w
snapshotach Restic. Usunięcie z backupów jest więc opóźnione.

Wybór kontekstu ma zasięg jednej wiadomości, nie staje się pamięcią Mentora ani
nie zmienia retencji rekordów treningu, profilu, masy czy Apple Health. Po
wysłaniu projekcja jest używana tylko do bieżącego żądania; nie jest zapisywana
w rozmowie. Ustawienia zgód i techniczne metadane operacji podlegają opisanej
wyżej retencji serwera. `store: false` w żądaniu OpenAI nie jest gwarancją
zero-retention u dostawcy, a usunięcie rozmowy lub cofnięcie zgody nie usuwa
danych przekazanych już dostawcy.

Audio STT nie jest przechowywane przez serwer. Nagranie klienta ma maksimum
30 sekund i 2 MiB. Pobrane TTS pozostaje wyłącznie w pamięci klienta maksymalnie
60 sekund, potem jest usuwane.

**Chronione DR:** pełny logiczny dump zachowuje użytkowników, treningi, dane
mentora i szyfrogramy w `mentor_credentials`. To zastępuje wcześniejszy wymóg
wykluczania wierszy poświadczeń. Lokalne dumpy są wrażliwe: katalogi bundle'ów
root `0700`, pliki `0600` (umask `0077`). Istniejący szyfrowany Restic obejmuje
`/docker` i `/etc`, także runtime secrets; nie deklarujemy więc backupów „bez
sekretów”. Nie zmieniamy zakresu ani konfiguracji wspólnego Restic. Kopie plików
żywej bazy nie są spójnym źródłem odtworzenia — służy do tego logiczny dump.

Klucz główny pozostaje osobnym materiałem runtime/recovery w niezależnym escrow,
poza dumpem i obecnym zakresem Restic. Same szyfrogramy nie wystarczają: po restore
potrzebny jest **oryginalny** klucz główny oraz zachowane powiązanie konta i dostawcy.
Utrata klucza wymaga ponownego podania poświadczeń; wygenerowanie innego nie
odszyfruje starych danych. Przed włączeniem sprawdzić pełne odtworzenie i odzyskanie
klucza na izolowanej instalacji, bez wypisywania sekretów lub szyfrogramów.

**Eksport aplikacji Flutter** to odrębna, ograniczona granica danych Drift/JSON:
nie zawiera kluczy mentora, ich szyfrogramów, rozmów ani pamięci mentora. Nie jest
pełnym DR serwera ani eksportem surowej bazy PostgreSQL. Stare snapshoty nadal
podlegają retencji operatora; w tej sesji nie uruchamiano hostowego Restic.

## Limity i rozliczalność żądań

Na użytkownika i dzień UTC backend egzekwuje: 60 żądań, 12 000 znaków TTS,
20 971 520 bajtów STT, 600 sekund STT i 48 000 tokenów wyjściowych. Równolegle
dozwolone jest jedno żądanie mentora na użytkownika (ograniczona dzierżawa).
Pojedyncza odpowiedź rezerwuje maksymalnie 800 tokenów wyjściowych. Nie jest to
deklaracja budżetu pieniężnego. Każda transkrypcja konserwatywnie rezerwuje pełne
30 sekund oraz rzeczywistą liczbę bajtów. Nieudane lub niejednoznaczne wywołania
zachowują rezerwację; poprawna odpowiedź OpenAI rozlicza zweryfikowaną liczbę
tokenów wyjściowych. Odświeżenie głosów i testy mają dodatkowo odstęp 10 sekund.

Każde płatne lub dostawcowe żądanie ma identyfikator idempotencji rezerwowany i
trwale zapisywany przed wywołaniem. Powtórzenie tego samego identyfikatora zwraca
wynik, jeśli jest dostępny, ale nigdy nie uruchamia ponownie płatnego wywołania —
również po niejednoznacznym timeoutie albo rozłączeniu. Gdy wynik TTS nie jest
już dostępny w pamięci, odpowiedzią jest `409` z kodem `result_unavailable`, zamiast ponownego
naliczenia u dostawcy. Transkrypcji i binarnego TTS nie przechowuje się w bazie
na potrzeby replayu: ponowienie zużytego identyfikatora zwraca `409`. Anulowanie
po stronie klienta nie gwarantuje anulowania naliczenia u dostawcy.

### Odzyskanie operacji po utracie odpowiedzi

Klient zapisuje przed wywołaniem wyłącznie metadane operacji per konto:
UUID żądania, rodzaj, ID rozmowy/wiadomości i skrót porównawczy treści.
Nie zapisuje w tym rejestrze tekstu rozmowy, transkrypcji, audio, pamięci ani kluczy.
Rejestr SharedPreferences jest niezależny od czasu życia widoku i transportu;
nawigacja anuluje HTTP i czyści prywatny stan, lecz nie przydziela nowego UUID.
Zmiana konta unieważnia poprzedni rejestr w pamięci, a przestrzenie kont są rozdzielone.
Te metadane nie należą do eksportu aplikacji.

Przed kolejnym płatnym wywołaniem następuje odczyt `/api/mentor/operations`
lub `/operations/{request_id}`. Są to wyłącznie uwierzytelnione odczyty bez
kontaktu z dostawcą. Filtry rodzaju, rozmowy i ID odpowiedzi działają przed
limitem 100 wyników, aby wcześniejsze TTS nie znikało za innymi operacjami.
Odpowiedź czatu można odzyskać z serwera i historii bez ponownego generowania;
jej treść i pierwotna wiadomość użytkownika pozostają po stronie serwera.
Starsze rekordy bez powiązania tekstu lub TTS są traktowane zachowawczo.

### Marker zgód kontekstu po odtworzeniu

`MENTOR_CONTEXT_GENERATION` jest **niesekretnym**, losowym identyfikatorem
operatora: co najmniej 32 znaki URL-safe. API zapisuje w PostgreSQL wyłącznie
jego SHA-256 razem z wersją polityki; sama wartość nie trafia do dumpu, odpowiedzi
API ani repozytorium. Wartość jest ustawiana wyłącznie w zainstalowanym
`/docker/fit/.env`, nie w `deploy/.env.example`.

Przed **każdym rzeczywistym odtworzeniem produkcyjnej bazy** operator, pod
istniejącą blokadą `/run/lock/fit-backup-restore.lock`, najpierw zastępuje tę
wartość nowym losowym identyfikatorem, następnie odtwarza bazę i odtwarza API.
Nie wolno przywracać poprzedniej wartości z Restic ani z kopii `.env`. Zmiana
markera powoduje fail-closed: zwykły czat bez kontekstu nadal działa, ale wszystkie
zgody kontekstowe z dumpu są nieskuteczne, dopóki użytkownik online nie wyśle
pełnego zestawu pięciu zgód dla aktualnej `context_policy_version`. Izolowany
`fit_restore` używany przez automatyczny drill nie jest produkcyjnym restore i
nie zmienia markera.

Kody `409` rozróżniają `operation_pending`, `result_unavailable`,
`operation_failed`, `operation_cancelled` i `operation_conflict`. Błąd odczytu
statusu nie uprawnia klienta do utworzenia nowego płatnego żądania. Nowy UUID
zastępujący niejednoznaczną operację wymaga przycisku
**„Wygeneruj ponownie — ponowne użycie limitu i koszt”** i potwierdzenia.
Dotyczy to także zmienionego tekstu zastępującego niedokończone żądanie.
Po zakończonej operacji wysłanie innej wiadomości jest nowym jawnym działaniem.

Audio TTS i transkrypcja STT nie są przechowywane jako wynik do odzyskania.
Ponowne STT po utracie nagrania wymaga nowego nagrania i jawnej zgody na kolejne
użycie limitu/koszt. Szkic nie jest lokalnie utrwalany; tekst czatu pozostaje
dostępny w historii serwera. Odtworzenie starszego DR cofa również rejestr operacji:
nie należy zakładać deduplikacji naliczeń wykonanych już po punkcie odtworzenia.

## Rotacja i incydent

Rotację kluczy dostawcy wykonuje użytkownik przez usunięcie starego klucza i
wprowadzenie nowego po świadomej decyzji. W razie podejrzenia ujawnienia
natychmiast odłącz dostawcę, unieważnij klucz u dostawcy i oceń zakres zdarzenia
bez zapisywania sekretów w logach lub zgłoszeniach.

Obsługiwana procedura rotacji klucza głównego w v1: usuń oba klucze dostawców
przez ustawienia każdego konta, zatrzymaj API podczas zatwierdzonego okna
serwisowego, przygotuj nowy niezależny klucz Fernet i escrow, odtwórz kontener API
z nowym mountem, a następnie ponownie wprowadź klucze dostawców przez ustawienia.
Samo podmienienie pliku pozostawia stare zaszyfrowane wiersze nieczytelne.
Re-encryption bez ponownego podania kluczy wymaga osobnego, sprawdzonego narzędzia
migracyjnego; nie jest dostarczone w tym wydaniu. Przećwicz rotację na izolowanej
instalacji. Pełny dump zachowuje szyfrogramy; do ich odzyskania potrzebny jest
oryginalny klucz główny, przechowywany i odzyskiwany osobno.

## Kontrakt i zakres v1

- Wydanie 1.4.0+7 wymaga zaplanowanej migracji Alembic `0010`; treść rozmów,
  pamięć i poświadczenia mentora są na serwerze. Brak nowych typów
  protokołu synchronizacji i brak rozmów, pamięci czy kluczy w Drift/backupie klienta.
- `/api/mentor/settings`, `/keys/{openai|elevenlabs}`; odczyt nigdy nie zwraca
  klucza, jego fragmentu ani szyfrogramu. Klucz Fernet szyfruje kopertę powiązaną
  z kontem i dostawcą. Wszystkie endpointy wymagają sesji i HTTPS, mutacje CSRF.
- `/sessions`, `/sessions/{id}/messages`, usuwanie `/sessions/{id}`: maksymalnie
  20 aktywnych rozmów, widok ostatnich 40 wiadomości, do OpenAI ostatnie 20.
- `/voices` i `/test/{provider}` to wyłącznie jawne działania użytkownika.
- `/stt` przyjmuje ograniczony surowy kontener audio; odpowiedź jest szkicem do
  poprawienia. `/messages/{id}/tts` przyjmuje wyłącznie ID własnej odpowiedzi
  asystenta, nigdy dowolny tekst lub URL. Audio jest obrabiane w pamięci.
- Przed parserem JSON działa limit ASGI 32 KiB, dla audio 2 MiB, również dla
  chunked transfer; upload ma 15 s, wywołanie dostawcy 45 s całkowitego timeoutu.
- Kontekst jest wybierany dla każdej wiadomości po osobnej zgodzie kategorii.
  Historia treningów to najwyżej 24 sesje z 12 tygodni i po cztery rozpoznane
  serie na sesję; masa i notatka wymagają jawnego wyboru jednego rekordu, a Apple
  Health jest podsumowaniem 7 dni. Żadna z tych kategorii nie jest dodawana bez
  wyboru w oknie wiadomości. Niezsynchronizowany trening może nie być jeszcze
  widoczny.
- Mentor proponuje rozpoczęcie treningu, serię znanego ćwiczenia albo przejście
  do katalogu. Dopiero potwierdzenie użytkownika wywołuje lokalne repozytorium i
  outbox. Stabilne UUID propozycji służą deduplikacji istniejących rekordów.
  Brak automatycznej zmiany ustawień, wykonywania komend, otwierania URL lub diagnoz.

Zweryfikowane oficjalne kontrakty (14.09.2026):
[OpenAI Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs),
[GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini),
[ElevenLabs STT](https://elevenlabs.io/docs/api-reference/speech-to-text/convert),
[TTS](https://elevenlabs.io/docs/api-reference/text-to-speech/convert),
[lista głosów](https://elevenlabs.io/docs/api-reference/voices/search).
Modele początkowe: `gpt-4.1-mini-2025-04-14` (lub alias `gpt-4.1-mini`),
`scribe_v2`, `eleven_multilingual_v2`; wybory są walidowane allowlistą.
Responses korzysta z `text.format`/JSON Schema i `store: false`; nie oznacza to
gwarantowanej zerowej retencji dostawcy. Nie ma automatycznych ponowień HTTP.

Przed włączeniem na prawdziwym urządzeniu sprawdź ręcznie: zgodę i odmowę dostępu
do mikrofonu, start/stop po geście, automatyczny koniec po 30 s, poprawienie tekstu
przed wysłaniem, przygotowanie/odtwarzanie/stop głosu, zmianę zakładki, wylogowanie
i wygaśnięcie sesji. Safari/iPhone oraz rzeczywiste klucze, modele, głosy i naliczenia
pozostają bramami ręcznymi. Nie deklarujemy ciągłego nasłuchu ani działania
mikrofonu pod blokadą ekranu.
