# Kandydat1.21.0+37 — własne testy sprawnościowe

**Status: lokalny kandydat, nie wdrożono.** Produkcja pozostaje1.20.0+36.
Użytkownik udzielił osobnej zgody na commit/push i wdrożenie API→web po końcowej
weryfikacji. Ten dokument opisuje niezmienny kandydat i dowody przed publikacją;
wynik rzeczywistego wdrożenia zostanie zapisany osobno. Brak zgody na produkcyjne
zapisy domenowe, reset hasła lub zmianę konfiguracji powiadomień.

## Funkcje

- Postępy podzielone na Ciało/Testy/Trening, zachowane pomiary i Apple Health.
- Własne testy dla dowolnego z412 ćwiczeń, wejścia z listy i karty ćwiczenia.
- Lokalna ilustracja, opis zasad, metryka, obciążenie/strona/wariant/limit czasu,
  kierunek poprawy, wersje protokołu i archiwum bez kasowania historii.
- Rzeczywista data i godzina wykonania, również wcześniejszej próby; historia
  w naturalnych jednostkach, porównanie tylko identycznej wersji zasad.
- Bez automatycznego zapisu treningów/serii/PR. Dawne11 testów, zapisane daty,
  wartości i score bez przeliczenia; wykres prezentuje surowe jednostki.
- Lokalny Barlow Condensed SemiBold z OFL; bez fontów i ilustracji runtime z CDN.

## Dane i zgodność

- Drift13→14: nullable fitnessProtocolsJson profilu i customProtocolJson wyniku.
  Bez resetu, backfillu i zmiany istniejących danych. PostgreSQL Alembic0010.
- Rozszerzenia istniejących profile/fitnessTest, bez nowego entityType. Backend
  chroni omission, CAS, immutable snapshot i attempted request/digest.
- Backup3 zachowuje UUID rodziny/rewizji i snapshoty; czytane także formaty1/2.
  Stary klient nie zapewnia bezstratnego eksportu/restore własnych testów.
- Flutter3.35.4/Dart3.9.2. Lock, sqlite3.wasm, drift_worker.dart.js, źródłowy
  katalog412 i wszystkie412 ilustracji identyczne z bazowym HEAD06d3c95.
- Odświeżony wyłącznie publiczny wygenerowany bundle Mentora z369 do412,
  istniejącym generatorem; bez zmian logiki, zgód lub wywołań dostawcy.

## Weryfikacja

- Pełny backend618 PASS. Pełny końcowy Docker gate:analiza bez problemów,
  Flutter1432 PASS/1 DST skip w UTC; osobny test Europe/Warsaw PASS. Release
  JavaScript/CanvasKit zbudowany; ostrzeżenia Wasm dry-run nie blokują tego targetu.
- Niezależne review backendu, danych i UI. Poprawiono także interleaved CAS
  z późniejszą lokalną rewizją, historyczny/bieżący wariant o tym samym UUID,
  metrykę przed pierwszym wynikiem, ułamkową oś oraz stan historii w formularzu.
-32 testy offline worker/client PASS. Wspólne41 przypadków kontraktu PASS po
  stronie Dart i Python. Wszystkie488 hashów/długości końcowego pakietu PASS.
- Pierwszy kandydat:rzeczywiste izolowane HTTPS/Flutter/FastAPI/PG E2E potwierdziło
  migrację13→14 z zachowaniem dwóch pełnych pending operacji przed ACK, offline
  zapis/reload, datę wcześniejszej próby, rewizję, archiwum, drugi kontekst oraz
  rzeczywisty backup3 export/import/export. Końcowo pending0 i zero treningów/PR.
- Pierwotna próba CDP text200 była nieskuteczna, nie oznaczono jej PASS. Ustalono
  prawdziwą metodę:preferencja Chromium default_font_size32, html32/16→skala2,
  przy320×844/DPR1/zoom1. Odczyt screenshotów potwierdza większy tekst, historię
  i przycisk zapisu dostępne pionowym scrollem. Nie jest to pełny audyt WCAG.
- Końcowy kandydat różni się od pierwszego wyłącznie dwiema stronami prezentacji
  i dwoma testami historii formularza; core/DB/API identyczne. Końcowy UI re-smoke
  na nowym obrazie **PASS**: rzeczywisty nowy main hash, pusta i istniejąca
  historia, wynik17 zapisany na drugim kontekście, live pull do otwartego
  formularza bez utraty niezapisanego23/daty, zachowany archiwalny13 i data.
- Końcowy ograniczony text200/320 PASS: preferencja32px, DPR1/zoom1, powiększone
  glify, wynik/data i pełny przycisk zapisu osiągalne scrollem. Parent odczytał
  rozstrzygające screenshoty. Odbiór fizycznego iPhone'a/VoiceOver pending.
- Końcowo syntetyczne konto ma legacy7 oraz custom13/17, pending0, zero sesji,
  serii i PR. Wykonano też eksport3, bez ponownego restore w finalnym smoke.
  Po odczycie dowodów usunięto wyłącznie etykietowany izolowany stos E2E;
  obrazy, profile i prywatne dowody zachowane, produkcja nietknięta.

Próby anulowane limitem narzędzia i FAIL brakującego fixture w kontekście Docker
zachowane w logach. Poprawiono precyzyjną allowlistę .dockerignore, nie testy.
Dowody browsera, trace i kopie danych syntetycznych są prywatne; nie publikować
ich bez sanityzacji. Raporty implementacji w docs/superpowers/plans/.

## Dokładne artefakty lokalne

| Artefakt | Image ID |
|---|---|
| API | sha256:4d9c40e9945f20a8fb1d75c95336852a03a029cebd1650e9ee7ca62062726356 |
| Migrator | sha256:343840169c77f71196c8e8161882b388a2b48d9c31536c6e7f9b1a2310f437b2 |
| Końcowy web | sha256:b79bd4eb31dc74cc11c2982f8d8bff850075567d4b238f590db52f2bfc7f5b3e |

PackageId53342ee35dddad82c522184dc97295f4429cfb47152cf5811b7b0c5e058330bf,
488 plików/48 072 362B. Manifest1225 plików źródłowych nie zmienił się podczas
końcowego buildu; wersja pakietu i UI1.21.0+37 pochodzą z pubspec.yaml.

## Warunki ewentualnej publikacji

1. Osobna zgoda na commit/push i wdrożenie; nie wykonywano ich w tym zadaniu.
2. Zamknięty końcowy UI smoke; przed publikacją świeży backup i izolowany restore
   według DEPLOY (aplikacyjny backup3 nie zastępuje DR backupu PostgreSQL).
3. Najpierw API z rozszerzeniem, dopiero potem web. Nie zmieniać Caddy, ingress,
   portów ani danych konta. Uaktualnić dokumentację produkcji dopiero po dowodach.
4. W razie blokady schematu zamknąć wszystkie okna/PWA i cały proces przeglądarki,
   potem otworzyć ten sam profil. Nie czyścić IndexedDB, storage lub pending.
5. Rollback weba do schematu13 nie cofa lokalnej migracji14; nie obiecywać, że
   stary klient otworzy nową bazę. Zachować API rozumiejące nowe rozszerzenia i
   dane; nie wykonywać ręcznej edycji SQLite lub downgrade'u snapshotów.
