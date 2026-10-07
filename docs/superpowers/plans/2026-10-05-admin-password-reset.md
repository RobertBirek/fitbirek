# Administracyjne resetowanie hasła — plan implementacji

> **Dla agentów wykonawczych:** WYMAGANA PODUMIEJĘTNOŚĆ: do wykonywania tego planu zadanie po zadaniu użyj `superpowers:subagent-driven-development` (zalecane) albo `superpowers:executing-plans`. Kroki używają składni list zadań (`- [ ]`).

**Cel:** Umożliwić właścicielowi pojedynczej instancji FitBirek ustawienie nowego hasła z SSH i unieważnienie wszystkich dotychczasowych sesji bez dodawania mechanizmu HTTP.

**Architektura:** Logika domenowa w `app.identity.service` wykona w jednej transakcji blokadę konta, wymianę hasha Argon2, usunięcie subskrypcji push należących do jego sesji oraz unieważnienie tych sesji. Nowy moduł CLI pobierze e-mail i dwa wpisy hasła z terminala, a następnie wywoła tę logikę przez istniejącą fabrykę sesji. Dokumentacja wdrożeniowa opisze interaktywne uruchomienie polecenia wewnątrz działającego kontenera API.

**Stos technologiczny:** Python 3.12, FastAPI/SQLAlchemy async, PostgreSQL 16, Argon2, pytest/Testcontainers, Docker Compose.

---

## Struktura plików

- Modyfikacja `backend/app/identity/service.py`: błąd domenowy i transakcyjna funkcja zmiany hasła z unieważnieniem sesji.
- Utworzenie `backend/app/cli/reset_password.py`: interaktywne, dostępne wyłącznie lokalnie przez SSH polecenie administracyjne.
- Modyfikacja `backend/tests/test_identity.py`: test atomowego resetu logiki domenowej, w tym unieważniania sesji i usuwania subskrypcji push.
- Modyfikacja `backend/tests/test_bootstrap.py`: testy procesu CLI uruchamianego jako moduł Pythona.
- Modyfikacja `DEPLOY.md`: krótka procedura odzyskania dostępu bez przekazywania hasła w argumentach lub logach.

### Zadanie 1: Transakcyjny reset w warstwie tożsamości

**Pliki:**
- Modyfikacja: `backend/app/identity/service.py:25-65`
- Modyfikacja: `backend/tests/test_identity.py:13-28`, koniec pliku

- [ ] **Krok 1: Napisz test zmiany hasła i unieważnienia dostępu.**

  W `backend/tests/test_identity.py` zaimportuj `PushSubscription`, `authenticated_session`, `hash_token`, `reset_password` oraz `AccountNotFoundError`. Dodaj test tworzący konto, dwie ważne sesje i subskrypcję push pierwszej sesji:

  ```python
  async def test_reset_password_rehashes_password_and_revokes_all_sessions(session, account):
      from app.identity.service import authenticated_session, hash_token, reset_password
      from app.push.models import PushSubscription

      first_token = "first-session-token"
      second_token = "second-session-token"
      first_session = Session(
          user_id=account.id,
          token_hash=hash_token(first_token),
          csrf_hash="a" * 64,
          expires_at=datetime.now(timezone.utc) + timedelta(days=1),
      )
      second_session = Session(
          user_id=account.id,
          token_hash=hash_token(second_token),
          csrf_hash="b" * 64,
          expires_at=datetime.now(timezone.utc) + timedelta(days=1),
      )
      session.add_all([first_session, second_session])
      await session.flush()
      session.add(PushSubscription(
          installation_id=uuid4(), user_id=account.id, session_id=first_session.id,
          endpoint="https://push.example/subscription", endpoint_hash="c" * 64,
          p256dh="d" * 87, auth="e" * 22, categories={},
      ))
      await session.commit()

      await reset_password(session, account.email.upper(), "new password")

      await session.refresh(account)
      assert PasswordHasher().verify(account.password_hash, "new password")
      assert await authenticated_session(session, first_token) is None
      assert await authenticated_session(session, second_token) is None
      assert await session.scalar(select(PushSubscription)) is None
  ```

  Dodaj także test braku konta:

  ```python
  async def test_reset_password_rejects_a_missing_account(session):
      from app.identity.service import AccountNotFoundError, reset_password

      with pytest.raises(AccountNotFoundError):
          await reset_password(session, "missing@example.com", "new password")
  ```

- [ ] **Krok 2: Uruchom nowe testy i potwierdź ich porażkę.**

  Uruchom z `backend/`:

  ```bash
  .venv/bin/python -m pytest -q tests/test_identity.py -k reset_password
  ```

  Oczekiwany wynik: błąd importu, ponieważ `reset_password` i `AccountNotFoundError` jeszcze nie istnieją.

- [ ] **Krok 3: Dodaj minimalną logikę domenową.**

  W `backend/app/identity/service.py` dodaj import `update` z SQLAlchemy, klasę błędu oraz funkcję poniżej `create_initial_account`:

  ```python
  class AccountNotFoundError(Exception):
      pass


  async def reset_password(database: AsyncSession, email: str, password: str) -> User:
      normalized_email = validate_and_normalize_email(email)
      async with database.begin():
          account = await database.scalar(
              select(User).where(User.email == normalized_email).with_for_update()
          )
          if account is None:
              raise AccountNotFoundError
          session_ids = select(Session.id).where(Session.user_id == account.id)
          await database.execute(
              delete(PushSubscription).where(PushSubscription.session_id.in_(session_ids))
          )
          await database.execute(
              update(Session)
              .where(Session.user_id == account.id)
              .values(revoked_at=datetime.now(timezone.utc))
          )
          account.password_hash = hash_password(password)
      return account
  ```

  Zachowaj istniejące `revoke_session()` dla wylogowania pojedynczej sesji; nie wywołuj go w pętli, bo sam zatwierdza transakcję.

- [ ] **Krok 4: Uruchom testy resetu i testy istniejącego logowania.**

  Uruchom z `backend/`:

  ```bash
  .venv/bin/python -m pytest -q tests/test_identity.py -k 'reset_password or login or logout'
  ```

  Oczekiwany wynik: wszystkie wybrane testy przechodzą.

### Zadanie 2: Interaktywne polecenie administratora

**Pliki:**
- Utworzenie: `backend/app/cli/reset_password.py`
- Modyfikacja: `backend/tests/test_bootstrap.py:17-30`, koniec pliku

- [ ] **Krok 1: Napisz testy zachowania procesu CLI.**

  W `backend/tests/test_bootstrap.py` dodaj pomocnik uruchamiający moduł z wejściem standardowym:

  ```python
  def run_reset_password(database_url: str, input_text: str) -> subprocess.CompletedProcess[str]:
      return subprocess.run(
          [sys.executable, "-m", "app.cli.reset_password"],
          cwd=BACKEND_DIR,
          env={**os.environ, "DATABASE_URL": database_url},
          input=input_text,
          text=True,
          capture_output=True,
          check=False,
      )
  ```

  Dodaj test, który najpierw tworzy konto przez `run_bootstrap`, następnie resetuje je przez `run_reset_password(database_url, "me@example.com\nnew secret\nnew secret\n")`, weryfikuje kod `0`, nowy hash i brak łańcucha `new secret` w `stdout` oraz `stderr`. Dodaj osobny test, który przy `"me@example.com\nfirst\nsecond\n"` oczekuje niezerowego kodu, tekstu `Passwords do not match` i poprawności starego hasha.

- [ ] **Krok 2: Uruchom testy CLI i potwierdź ich porażkę.**

  Uruchom z `backend/`:

  ```bash
  .venv/bin/python -m pytest -q tests/test_bootstrap.py -k reset_password
  ```

  Oczekiwany wynik: testy nie przechodzą, bo moduł `app.cli.reset_password` nie istnieje.

- [ ] **Krok 3: Utwórz polecenie CLI bez sekretów w argumentach.**

  Utwórz `backend/app/cli/reset_password.py`:

  ```python
  import asyncio
  import getpass

  from app.database import session_factory
  from app.identity.service import AccountNotFoundError, reset_password, validate_and_normalize_email


  async def change_password(email: str, password: str) -> None:
      async with session_factory() as database:
          await reset_password(database, email, password)


  def main() -> None:
      try:
          email = validate_and_normalize_email(input("Email: "))
      except ValueError as error:
          raise SystemExit(str(error)) from error

      password = getpass.getpass("New password: ")
      confirmation = getpass.getpass("Confirm new password: ")
      if not password.strip():
          raise SystemExit("Password must not be blank")
      if password != confirmation:
          raise SystemExit("Passwords do not match")
      try:
          asyncio.run(change_password(email, password))
      except AccountNotFoundError as error:
          raise SystemExit("Account does not exist") from error


  if __name__ == "__main__":
      main()
  ```

  Nie przyjmuj hasła przez argument wiersza poleceń ani zmienną środowiskową. `getpass` ma pozostać jedynym kanałem pobrania hasła.

- [ ] **Krok 4: Uruchom testy CLI i komplet testów tożsamości.**

  Uruchom z `backend/`:

  ```bash
  .venv/bin/python -m pytest -q tests/test_bootstrap.py tests/test_identity.py
  ```

  Oczekiwany wynik: wszystkie testy przechodzą.

### Zadanie 3: Udokumentuj uruchomienie operacyjne

**Pliki:**
- Modyfikacja: `DEPLOY.md` po sekcji opisującej inicjalne konto (około wiersza 64)

- [ ] **Krok 1: Dodaj sekcję odzyskiwania dostępu.**

  Bezpośrednio po informacji o haśle początkowym dodaj:

  ````markdown
  ### Odzyskanie hasła właściciela

  Dla tej jednoosobowej instancji administrator z dostępem SSH może ustawić nowe
  hasło interaktywnie w działającym kontenerze API. Nie używaj `-T`, ponieważ
  polecenie wymaga terminala do ukrytego wprowadzania hasła:

  ```bash
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml exec api python -m app.cli.reset_password
  ```

  Polecenie pyta o e-mail konta, nowe hasło i jego potwierdzenie. Nowe hasło nie
  jest przekazywane w argumentach ani drukowane. Udany reset unieważnia wszystkie
  aktywne sesje i usuwa ich subskrypcje push; zaloguj się ponownie na każdym urządzeniu.
  ````

  Dopasuj opis, jeśli bieżąca instrukcja runtime wymaga innego zestawu plików Compose, ale nie zapisuj hasła ani adresu e-mail właściciela w nowej sekcji.

- [ ] **Krok 2: Zweryfikuj, że instrukcja nie ujawnia sekretów i nie zmienia konfiguracji.**

  Uruchom z katalogu głównego:

  ```bash
  git diff --check -- DEPLOY.md
  ```

  Oczekiwany wynik: brak wyjścia i kod zakończenia `0`.

### Zadanie 4: Pełna weryfikacja backendu

**Pliki:**
- Modyfikacja: brak

- [ ] **Krok 1: Uruchom pełny zestaw testów backendu.**

  Uruchom z `backend/`:

  ```bash
  .venv/bin/python -m pytest -q
  ```

  Oczekiwany wynik: komplet testów przechodzi. Testcontainers musi mieć dostęp do Dockera i PostgreSQL 16.

- [ ] **Krok 2: Sprawdź zakres zmian.**

  Uruchom z katalogu głównego:

  ```bash
  git diff --check -- backend/app/identity/service.py backend/app/cli/reset_password.py backend/tests/test_identity.py backend/tests/test_bootstrap.py DEPLOY.md
  ```

  Oczekiwany wynik: brak wyjścia i kod zakończenia `0`; nie dodawaj do zmian istniejących, niepowiązanych modyfikacji użytkownika.

## Przegląd planu

- Zakres specyfikacji pokrywają zadania: interaktywny CLI (zadanie 2), Argon2 i atomowość (zadanie 1), unieważnianie sesji i subskrypcji push (zadanie 1), obsługa błędów (zadania 1–2), testy (zadania 1–2 i 4) oraz instrukcja SSH (zadanie 3).
- Plan nie zawiera publicznych endpointów, SMTP, tokenów resetu ani migracji.
- Nazwy używane konsekwentnie: `AccountNotFoundError`, `reset_password`, `change_password` i `app.cli.reset_password`.
