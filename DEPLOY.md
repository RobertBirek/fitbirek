# Wdrożenie FitBirek na VPS — `fit.birek.online`

Ten dokument opisuje **kompletną procedurę** wdrożenia aplikacji web FitBirek (Flutter Web) na własnym VPS, pod domeną `fit.birek.online`. Zawiera zarówno instrukcje krok-po-kroku dla człowieka, jak i gotowy prompt dla agenta AI, który może wykonać to wdrożenie automatycznie.

**Status DNS**: rekord DNS dla `fit.birek.online` jest już skonfigurowany i propagowany (zweryfikowano: wskazuje na IP VPS). Można przejść od razu do wdrożenia + SSL.

---

## 📋 Wymagania wstępne

- VPS z dostępem root/sudo (Ubuntu/Debian — instrukcje poniżej zakładają `apt`; dla innych dystrybucji dostosuj komendy instalacji `nginx`/`certbot`)
- Domena `fit.birek.online` z rekordem **A** wskazującym na IP VPS (✅ już zrobione)
- Porty 80 i 443 otwarte w firewallu VPS
- Dostęp SSH do VPS

---

## 📦 Co jest wdrażane

Statyczna aplikacja **Flutter Web** (skompilowana do JS/Wasm), z bazą danych **Drift SQLite działającą w przeglądarce przez WebAssembly** (`sqlite3.wasm` + `drift_worker.dart.js`). To nie wymaga żadnego backendu/serwera aplikacyjnego — nginx serwuje same pliki statyczne, cała logika i baza danych działają lokalnie w przeglądarce użytkownika (IndexedDB/OPFS).

**Krytyczny szczegół techniczny**: nginx musi serwować plik `.wasm` z poprawnym MIME typem `application/wasm`. Bez tego przeglądarka odmawia załadować moduł WebAssembly i baza danych aplikacji nie wystartuje (biały ekran lub błąd w konsoli). Konfiguracja w tym repo (`deploy/fitbirek-nginx.conf`) już to obsługuje.

---

## 🗂️ Pliki w tym repo potrzebne do wdrożenia

| Plik | Cel |
|---|---|
| `deploy/fitbirek-nginx.conf` | Konfiguracja nginx (server block, MIME types, gzip, cache) |
| `deploy/fitbirek-deploy-vps.sh` | Skrypt automatyzujący całe wdrożenie (instalacja nginx/certbot, rozpakowanie, SSL) |
| *(build/web/ nie jest w repo — patrz "Budowanie aplikacji" poniżej)* | Skompilowana aplikacja |

> **Uwaga**: katalog `build/` jest w `.gitignore` (standard dla projektów Flutter — artefakty budowania nie trafiają do repo). Aplikację trzeba **zbudować** przed wdrożeniem — patrz kroki poniżej.

---

## 🚀 Procedura wdrożenia — krok po kroku

### Krok 1: Sklonuj repo (na maszynie z Flutter SDK — sandbox deweloperski lub lokalnie)

```bash
git clone https://github.com/RobertBirek/fitbirek.git
cd fitbirek
```

### Krok 2: Zainstaluj zależności i zbuduj wersję web

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release
```

Wynik: katalog `build/web/` zawierający kompletną, gotową do wdrożenia aplikację (m.in. `index.html`, `main.dart.js`, `sqlite3.wasm`, `drift_worker.dart.js`).

**Weryfikacja przed wdrożeniem** (zalecane):
```bash
flutter analyze   # powinno zwrócić "No issues found!"
ls -la build/web/sqlite3.wasm build/web/drift_worker.dart.js   # muszą istnieć
```

### Krok 3: Spakuj i wgraj na VPS

```bash
cd build && tar -czf fitbirek-web-release.tar.gz web/ && cd ..

scp build/fitbirek-web-release.tar.gz deploy/fitbirek-nginx.conf deploy/fitbirek-deploy-vps.sh \
    TWOJ_USER@84.46.252.130:~/
```

> Zamień `TWOJ_USER` na swoją nazwę użytkownika SSH na VPS. IP `84.46.252.130` to potwierdzony adres, na który wskazuje już `fit.birek.online`.

### Krok 4: Zaloguj się na VPS i odpal skrypt wdrożeniowy

```bash
ssh TWOJ_USER@84.46.252.130
chmod +x fitbirek-deploy-vps.sh
./fitbirek-deploy-vps.sh fitbirek-web-release.tar.gz
```

Skrypt automatycznie:
1. Instaluje `nginx` i `certbot` (jeśli nie są zainstalowane)
2. Rozpakowuje aplikację do `/var/www/fitbirek/web`
3. Wgrywa konfigurację nginx (`fitbirek-nginx.conf`) do `/etc/nginx/sites-available/fit.birek.online` + aktywuje symlinkiem
4. Testuje konfigurację (`nginx -t`) i restartuje nginx
5. Pyta, czy DNS jest już propagowany — **odpowiedz `t`** (DNS jest już potwierdzony jako działający) — skrypt uruchomi `certbot --nginx -d fit.birek.online` i skonfiguruje darmowy SSL (Let's Encrypt) z auto-odnawianiem

**Podczas działania certbota** zostaniesz zapytany o adres e-mail (do powiadomień o odnowieniu certyfikatu) — podaj swój prawdziwy e-mail, nie przykładowy z domyślnego skryptu.

### Krok 5: Weryfikacja

```bash
curl -I https://fit.birek.online
```

Powinno zwrócić `HTTP/2 200`. Otwórz `https://fit.birek.online` w przeglądarce i sprawdź konsolę dewelopera (F12 → Console) — nie powinno być błędów związanych z `sqlite3.wasm` czy `drift_worker`. Jeśli aplikacja się ładuje i przechodzi przez onboarding, wdrożenie jest w 100% udane.

**Na iPhone**: otwórz `https://fit.birek.online` w Safari → Udostępnij → "Dodaj do ekranu głównego" — aplikacja instaluje się jak natywna (ikona, pełny ekran, offline).

---

## 🔄 Aktualizacja aplikacji po zmianach w kodzie

Gdy w repo pojawią się nowe commity (nowe funkcje, poprawki):

```bash
# Na maszynie deweloperskiej
git pull
flutter build web --release
cd build && tar -czf fitbirek-web-release.tar.gz web/ && cd ..
scp build/fitbirek-web-release.tar.gz TWOJ_USER@84.46.252.130:~/

# Na VPS
ssh TWOJ_USER@84.46.252.130
sudo rm -rf /var/www/fitbirek/web
sudo tar -xzf fitbirek-web-release.tar.gz -C /var/www/fitbirek
sudo chown -R www-data:www-data /var/www/fitbirek
sudo systemctl reload nginx
```

Nie trzeba ponownie uruchamiać certbota — certyfikat SSL jest niezależny od zawartości plików.

---

## 🐛 Troubleshooting

| Problem | Diagnoza | Rozwiązanie |
|---|---|---|
| Biały ekran, konsola: błąd `WebAssembly` | Nginx serwuje `.wasm` z błędnym MIME typem | Sprawdź czy `fitbirek-nginx.conf` ma sekcję `types { application/wasm wasm; }` i czy jest aktywna (`nginx -t`, `systemctl status nginx`) |
| `certbot` fail: "DNS problem" | DNS jeszcze nie propagowany globalnie | Sprawdź: `python3 -c "import socket; print(socket.gethostbyname('fit.birek.online'))"` — musi zwrócić IP VPS. Jeśli nie, poczekaj i spróbuj `certbot` ręcznie później |
| Strona 404 po odświeżeniu na podstronie (np. `/workout`) | Brak SPA fallback w nginx | Sprawdź czy `location /` w konfiguracji ma `try_files $uri $uri/ /index.html;` |
| Stare dane/UI po aktualizacji | Cache przeglądarki/service workera | Sprawdź czy `flutter_service_worker.js` ma nagłówek `no-cache` (jest w konfiguracji), wymuś hard refresh (Ctrl+Shift+R) |
| `nginx -t` fail | Błąd składni w konfiguracji | Sprawdź `sudo nginx -t` — pokaże dokładną linię błędu w configu |

---

## 🤖 Prompt dla agenta AI wdrażającego tę aplikację

Jeśli chcesz zlecić wdrożenie innemu agentowi AI (np. mającemu dostęp SSH do VPS), skopiuj poniższy prompt **w całości**:

```
Twoje zadanie: wdroż aplikację webową FitBirek (Flutter Web) na VPS pod domeną
fit.birek.online. Masz dostęp SSH do VPS (Ubuntu/Debian) z uprawnieniami sudo.

KONTEKST:
- Repo źródłowe: https://github.com/RobertBirek/fitbirek
- Domena fit.birek.online już ma skonfigurowany rekord DNS A wskazujący na ten VPS
  (zweryfikowane, propagacja zakończona)
- Aplikacja to statyczny build Flutter Web z bazą danych SQLite działającą w
  przeglądarce przez WebAssembly (Drift + sqlite3.wasm) — nie wymaga backendu,
  tylko serwera plików statycznych (nginx)
- W repo, w katalogu deploy/, znajdują się dwa gotowe pliki:
  - deploy/fitbirek-nginx.conf — konfiguracja nginx (KRYTYCZNE: zawiera poprawny
    MIME type dla .wasm, bez którego baza danych aplikacji nie wystartuje w
    przeglądarce)
  - deploy/fitbirek-deploy-vps.sh — skrypt automatyzujący wdrożenie

KROKI DO WYKONANIA:

1. Na maszynie z Flutter SDK (3.35.4 / Dart 3.9.2 — NIE aktualizuj wersji):
   git clone https://github.com/RobertBirek/fitbirek.git
   cd fitbirek
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter build web --release

   Zweryfikuj przed kontynuacją:
   - `flutter analyze` powinno zwrócić "No issues found!"
   - build/web/sqlite3.wasm i build/web/drift_worker.dart.js MUSZĄ istnieć —
     jeśli ich nie ma, build się nie powiódł poprawnie, zatrzymaj się i
     zdiagnozuj błąd zamiast kontynuować wdrożenie na produkcję

2. Spakuj build:
   cd build && tar -czf fitbirek-web-release.tar.gz web/ && cd ..

3. Wgraj na VPS (tarball + konfigurację nginx + skrypt deploy):
   scp build/fitbirek-web-release.tar.gz deploy/fitbirek-nginx.conf \
       deploy/fitbirek-deploy-vps.sh USER@VPS_IP:~/
   (zapytaj użytkownika o USER i VPS_IP jeśli nie zostały podane)

4. Na VPS, wykonaj skrypt wdrożeniowy:
   ssh USER@VPS_IP
   chmod +x fitbirek-deploy-vps.sh
   ./fitbirek-deploy-vps.sh fitbirek-web-release.tar.gz

   Skrypt zainstaluje nginx+certbot jeśli brak, rozpakuje aplikację do
   /var/www/fitbirek/web, skonfiguruje nginx i zapyta czy DNS jest propagowany
   — odpowiedz "t" (TAK, jest już potwierdzone), żeby skrypt automatycznie
   skonfigurował SSL przez Let's Encrypt (certbot --nginx -d fit.birek.online).
   Certbot zapyta o adres e-mail do powiadomień o odnowieniu certyfikatu —
   użyj prawdziwego adresu e-mail podanego przez użytkownika, NIGDY placeholder
   typu "twoj-email@example.com".

5. Zweryfikuj wdrożenie:
   curl -I https://fit.birek.online
   Powinno zwrócić HTTP/2 200. Jeśli nie — sprawdź logi nginx:
   sudo journalctl -u nginx -n 50
   sudo tail -50 /var/log/nginx/error.log

6. Potwierdź użytkownikowi końcowy status z konkretnym dowodem (kod HTTP,
   ewentualne błędy z logów), nie tylko "wdrożenie zakończone" bez weryfikacji.

ZASADY BEZPIECZEŃSTWA:
- Nie modyfikuj deploy/fitbirek-nginx.conf bez wyraźnej potrzeby — MIME type
  dla .wasm jest krytyczny dla działania bazy danych, nie usuwaj tej sekcji
- Jeśli na VPS działa już inna strona/aplikacja na porcie 80/443, NIE nadpisuj
  jej konfiguracji — dodaj nowy server block obok istniejących (sprawdź
  /etc/nginx/sites-enabled/ przed działaniem) i zapytaj użytkownika o
  potwierdzenie przed restartem nginx
- Nie commituj żadnych sekretów/kluczy SSH/tokenów do repo
- Jeśli certbot zawiedzie z powodu DNS, NIE próbuj wielokrotnie w krótkim
  czasie (Let's Edge Encrypt ma rate limity) — zgłoś błąd użytkownikowi i
  poczekaj na jego decyzję
```

---

## 📝 Znane szczegóły techniczne dla przyszłej konserwacji

- **Wersje Drift/sqlite3 są zablokowane**: `drift: 2.28.2`, `sqlite3: 2.9.4` (patrz `pubspec.lock`). Pliki `web/sqlite3.wasm` i `web/drift_worker.dart.js` w repo źródłowym MUSZĄ odpowiadać tym wersjom — zostały pobrane z oficjalnych GitHub Releases tych pakietów. Jeśli kiedyś zaktualizujesz `drift`/`sqlite3` w `pubspec.yaml`, musisz też pobrać nowe wersje tych dwóch plików binarnych, inaczej worker↔wasm protocol mismatch spowoduje trudne do zdiagnozowania błędy runtime.
- **Certyfikat SSL** (Let's Encrypt via certbot) odnawia się automatycznie przez systemowy timer/cron zainstalowany przez certbot — nie wymaga ręcznej interwencji, ale warto od czasu do czasu sprawdzić: `sudo certbot certificates`.
- **Brak backendu** — cała logika i dane działają po stronie klienta (przeglądarka). To oznacza, że dane użytkownika (treningi, pomiary) są przechowywane lokalnie w przeglądarce (IndexedDB) i **nie synchronizują się** między urządzeniami. To jest świadome ograniczenie obecnej wersji — jeśli w przyszłości potrzebna będzie synchronizacja wielourządzeniowa, wymaga to dodania prawdziwego backendu (np. Firebase, patrz sekcja Firebase w głównej dokumentacji projektu).
