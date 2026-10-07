# FitBirek 1.2.0+4 — raport implementacji i weryfikacji

Stan wdrożenia z **15.09.2026 07:37:51 Europe/Warsaw**: **1.2.0+4 wdrożone**,
Alembic `0009`, wyłącznie konfiguracja i lokalne szyfrowanie. Klucze providerów
nieobecne, domyślne zgody false; providerzy i sprzęt nieprzetestowani, escrow
poza hostem oczekuje. [Raport wdrożenia](mentor-deployment-2026-09-15.md).

Poniżej historyczny raport implementacji z 14.09.2026. Implementację wykonano na
zastanym drzewie roboczym `/opt/fit`, zachowując niezatwierdzone zmiany Push,
Apple Zdrowie i wersjonowania. Nie wykonywano commita ani instalacji runtime.
Uwzględniono dwa P2 zgłoszone w niezależnym review. Nie uruchamiano kolejnego
reviewera. Poniższe wyniki i obrazy dotyczą aktualnych źródeł po poprawkach P2.

## Zrealizowany zakres

- Główny `/today` to rozmowa z mentorem, z podpowiedziami czasu, energii i krótkiej
  sesji. Poprzedni panel z samopoczuciem i Apple Zdrowie jest dostępny przez
  `/today/classic` (`classic_today_page.dart`). Klasyczny trening działa offline.
- OpenAI Responses: ścisły JSON Schema, sprawdzanie kompletności, odmów i danych,
  allowlista rzeczywistych modeli, ograniczona historia i jawnie zatwierdzona pamięć.
- ElevenLabs: nagrywanie push-to-talk, transkrypcja do edytowalnego szkicu oraz
  TTS własnej odpowiedzi asystenta. Przygotowanie audio i odtwarzanie wymagają
  osobnych działań; dostępny Stop. Brak utrwalania audio na dysku serwera/klienta.
- Ustawienia: odrębne zgody, pamięć, modele, głos, jednorazowe formularze kluczy,
  wymiana/usuwanie, jawne testy i odświeżanie głosów, liczniki i limity użycia.
- Klucze wyłącznie w backendzie: Fernet, koperta powiązana z kontem/dostawcą,
  niezależny runtime master key. Brak tego pliku pozostawia mentora wyłączonego.
- Rozmowy są prywatne dla konta, z historią i usuwaniem. Usunięcie, wylogowanie
  lub zmiana konfiguracji odrzucają spóźnioną odpowiedź. Limity są rezerwowane
  atomowo przed wywołaniem; timeout nie powoduje automatycznego ponownego naliczenia.
- Propozycje startu treningu, serii i otwarcia katalogu wymagają potwierdzenia.
  Serie można poprawić przed zapisem. Istniejący repozytorium/outbox i UUID v5
  zapewniają deduplikację bez nowych typów synchronizacji ani tabel Drift mentora.
- Migracja `0009`, opcjonalny overlay API i pełny chroniony DR zachowujący
  szyfrogramy poświadczeń. Eksport aplikacji pozostaje bez kluczy i szyfrogramów.
  Szczegóły oraz ograniczenia retencji: [mentor.md](mentor.md).
- Trwałe identyfikatory operacji per konto i serwerowe odczyty statusu po utracie
  odpowiedzi/reloadzie; TTS/STT używają identyfikatora od wywołującego. Ponowne
  generowanie po niejednoznacznym wyniku wymaga jawnego potwierdzenia kosztu i limitu.

## Wyniki weryfikacji

| Obszar | Wynik |
| --- | --- |
| Pełny backend, Python 3.12 / izolowany PostgreSQL 16 Testcontainers | **267 passed**, 415,14 s |
| Pełny Flutter w etapie `verification` finalnego obrazu web | **334 passed** |
| `flutter analyze` | **No issues found** |
| Generator wersji `--check` przed buildem i w etapach Docker | OK, `1.2.0+4` |
| JS voice, mockowane MediaRecorder/strumienie/czas/odtwarzanie | **9 passed** |
| JS istniejącego Push worker | **9 passed** |
| `tools/tests` pod Xvfb: Chromium/IndexedDB/worker i monitor | **12 passed**, bez pominięć |
| Guardy backupu/restore | PASS |
| Rzeczywisty pełny `pg_dump`/`pg_restore` do osobnego kontenera PostgreSQL | PASS: konto, trening, mentor i szyfrogramy odtworzone; oryginalny master key odszyfrowuje, inny nie |
| Szablony Compose z Push i Mentor, bez rozwiązywania env | PASS |
| `git diff --check` | PASS |

Sprawdzono również realne kontenery **WebM i fragmentowany MP4** wygenerowane
przez Chromium z **symulowanym mikrofonem** i przekazane w pamięci do walidatora
backendu. Test automatycznego zakończenia nagrania dał deklarowane 30 s,
zweryfikowane 29,97 s i 452 793 bajty. To nie jest test sprzętu iPhone/Safari.

W testach dostawców używano mocków. Nie odczytywano istniejących kluczy ani
danych kont produkcyjnych, nie wywoływano płatnych API i nie wykonywano
produkcyjnych kontroli zdrowia/importów użytkownika.

## Zbudowane artefakty

| Obraz | Target | SHA-256 obrazu |
| --- | --- | --- |
| `fit-web:mentor-1.2.0-4-p2` | **runtime — Nginx** | `1500bd4121f4909f4181e2b6512b49ba755f50a78ee2656d48d36735f0b439ae` |
| `fit-api:mentor-1.2.0-4-p2` | runtime | `6810f3656f00e964cec708d7e7238f96c5177f26ff3f2eb73456339cc6e0d2cb` |
| `fit-migration:mentor-1.2.0-4-p2` | migration | `af84d39733f79b8dc66f5b1633313b34c8154c479d2afbf4c48043b4bb58207d` |

Smoke obrazów wykonano w jednorazowych kontenerach bez sieci zewnętrznej:

- Nginx: konfiguracja poprawna; HTTP 200 dla `/today`, `/mentor_voice.js` i
  `/version.json`; wersja pakietu `1.2.0`, build `4`. Zastany szablon Nginx
  emituje nieblokujące ostrzeżenie o powtórzonej deklaracji MIME `wasm`.
- API: routery mentora obecne, `httpx 0.28.1`, `pip check` poprawny,
  brak master key daje status wyłączony. Obraz działa jako UID 100 / GID 101.
- Migrator: `alembic heads` zwraca `0009 (head)`.

Regresje P2 obejmują naliczenie w mocku dostawcy i utratę odpowiedzi, kolejne
kliknięcie, zmianę zakładki, odtworzenie rejestru po reloadzie i utratę lokalnych
metadanych. Bez nowego POST odzyskiwana jest odpowiedź czatu; utracone audio
zwraca stan niedostępności. Dopiero potwierdzona regeneracja używa nowego UUID.
Sprawdzono również właściwy serwerowy rodzaj `message`, filtry przed paginacją,
rozdzielenie kont i brak nowego wywołania, gdy nie można odczytać statusu.

Granice: nie ma trwałego audio ani lokalnego prywatnego szkicu. Ponowne STT
wymaga nowego nagrania i potwierdzenia użycia. Rejestr deduplikacji w DR ma stan
z chwili backupu; nie gwarantuje rozliczenia operacji po tym punkcie odtworzenia.
Migracja `0009` została uzupełniona przed wdrożeniem — do wydania używać aktualnego
migratora P2, nie wcześniejszego niewdrożonego kandydata.

HTTPX przeniesiono do zależności runtime wraz z istniejącymi pinami i hashami
HTTP Core/Certifi z development locka. Wersje Flutter **3.35.4**, Dart **3.9.2**,
Drift i SQLite nie zostały podniesione.

## Ręczne bramy przed włączeniem

1. Osobny przegląd wydania oraz zwykła procedura zatwierdzonego wdrożenia/migracji.
2. Niezależny plik klucza Fernet poza repo, `/docker` i `/etc`, właściwe UID/GID,
   uprawnienia i osobne escrow; instalacja overlayu tylko do API. Niczego z tego
   nie utworzono ani nie zainstalowano w tej sesji.
3. Chronione pełne DR obejmuje szyfrogramy `mentor_credentials`, użytkowników,
   treningi i dane mentora. Zastępuje to wcześniejsze wykluczenia poświadczeń;
   wspólny szyfrowany Restic pozostaje bez zmian. Lokalne bundle root `0700`,
   pliki `0600`. Zweryfikować izolowany dump/restore oraz odzyskanie oryginalnego
   klucza z osobnego escrow, zachowując powiązanie konta/dostawcy. Eksport Flutter
   nie zawiera kluczy ani szyfrogramów i nie zastępuje DR. Backupów serwera nie
   należy opisywać jako pozbawionych sekretów (Restic obejmuje też runtime secrets).
4. Rzeczywiste konto OpenAI/ElevenLabs: dostępność modelu i głosu, uprawnienia
   kluczy, retencja dostawcy, jawny test połączenia i kontrola naliczeń. Lokalne
   limity jednostek użycia nie są gwarancją kosztu w dolarach.
5. Safari/iPhone/PWA: zgoda/odmowa mikrofonu, limit czasu/rozmiaru, poprawienie
   transkrypcji, oddzielny gest odtwarzania, Stop, opuszczenie ekranu i wylogowanie.
   Brak deklaracji ciągłego nasłuchu lub mikrofonu pod blokadą ekranu.
