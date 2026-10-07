# Kontrakt progresji planu — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rozszerzyć synchronizowany plan o walidowane reguły progresji i zaakceptowane cele, bez możliwości ich cichego usunięcia przez starszego klienta.

**Architecture:** Reguły i cele stanowią pełny snapshot w JSONB istniejącej encji `workoutPlan`, nie nowe encje ani kopie wykonanych serii. Warunek zapisu zawiera niezależną rewizję planu, sprawdzaną pod istniejącą blokadą rekordu; rozpoznany konflikt kontraktu blokuje zapis całego batcha. Backend przechowuje i waliduje deklaracje klienta, natomiast silnik sugestii i sprawdzenie aktualności historii przed akceptacją działają lokalnie.

**Tech Stack:** Python 3.12, FastAPI, Pydantic 2, SQLAlchemy async, PostgreSQL 16, pytest/Testcontainers; interfejs do Flutter 3.35.4/Dart 3.9.2/Drift.

---

## Status, zakres i granice

To **propozycja kontraktu i pomocniczy plan etapu 3**, nie implementacja ani plan nadrzędny. Dokument powstał na podstawie `AGENTS.md` i `docs/superpowers/specs/2026-09-28-plany-historia-progresja-design.md`. Nie zmieniono kodu, nie uruchamiano testów ani wdrożenia, nie czytano sekretów. W repozytorium są liczne wcześniejsze zmiany; należy je pozostawić bez porządkowania.

Przyszłe zmiany serwerowe wyłącznie w `backend/`. W tym zadaniu zapisywany jest wyłącznie niniejszy dokument. Nie wykonywać commitów. Zadania klienta poniżej to warunki integracji dla autora planu nadrzędnego, nie przydział implementacji Fluttera temu planowi.

## 1. Ustalenia z rzeczywistego kodu

| Miejsce | Stan obecny i konsekwencja |
|---|---|
| `backend/app/sync/schemas.py:17-40` | `PushOperation.payload` to dowolny obiekt JSON; walidowane są tylko skończone liczby. Nie ma schematu planu. |
| `backend/app/sync/service.py:172-249` | Deduplikacja po `operationId` i digest, następnie CAS przez `baseVersion`; zapis zastępuje cały payload. Samo dopisanie nowych pól nie chroni ich przed starym klientem. |
| `backend/app/sync/service.py:251-303` | Konflikt wycofuje cały batch; odpowiedź może zawierać wyłącznie duplikaty już zatwierdzonych operacji. Blokady obejmują użytkownika i rekord. Zachować te właściwości. |
| `backend/app/sync/service.py:288-298` | Log zmian przechowuje payload danej operacji. Nie wolno zastąpić go końcowym snapshotem batcha, jeżeli w batchu są dwie wersje tego samego planu. |
| `backend/app/sync/models.py` | `SyncRecord`, `SyncChange`, `SyncOperation`; JSONB wystarczy, bez nowej tabeli i migracji PostgreSQL. |
| `lib/core/database/tables/plans_table.dart` | Plan ma `nazwa`, tekst JSON `cwiczeniaIds`, `cel`, `dataUtworzenia` i metadata sync. |
| `lib/features/planner/data/planner_repository.dart` | `SavedPlan` jest zwykłą klasą, nie Freezed. `_payload` tworzy cztery pola; zarówno zapis, jak usuwanie pomijałyby progresję. |
| `lib/core/sync/sync_store.dart:63-180,256-314` | Pull dekoduje wiersz przez wygenerowany parser, enqueueAll buduje payload ponownie z wiersza. Konwersja string↔JSON dotyczy tylko list. Nieznane pola nie są trwałym magazynem nowych danych. |
| `lib/core/database/daos/sync_dao.dart:88-123` | Niewysłane operacje są scalane do najnowszego snapshotu. Próbowane operacje pozostają niezmienne. Nowy warunek rewizji musi być trwale przechowywany i uwzględniony przy scalaniu. |
| `lib/core/sync/sync_store.dart:38-60` | Odebrana wersja zmienia `baseVersion` niewysłanych operacji. To nie może zmieniać warunku rewizji planu. |
| `lib/core/sync/sync_service.dart:176-217` | Konflikt z `kind != null` blokuje operację i pozwala przejść do pull. Zwykły konflikt przy `preserveLocal` może automatycznie ponowić stary payload z nowym `baseVersion`. Dlatego używamy konfliktu z `kind`, nie tylko istniejącego `SyncConflict`. |
| `lib/core/services/backup_service.dart` | Wersja backupu wynosi 2. Export używa `row.toJson()` bez metadata sync; import nadaje nowe UUID, kolejkuje usunięcia obecnych rekordów i odtworzenie w transakcji. Ochrona wyłącznie upsertu nie zabezpiecza przed starym restore. |
| `lib/core/widgets/rpe_slider.dart:52-58` | RPE to **liczba całkowita 1–10**, nie 0–10 i nie ułamki. |
| `lib/core/database/app_database.dart` | Obecna wersja Drift to 7; numer migracji klienta należy skoordynować z pozostałymi etapami. Nie zakładać bezwarunkowo, że nadal wolna będzie wersja 8. |

## 2. Dokładny kontrakt JSON (propozycja v1)

### 2.1. Pełna operacja push

Endpointy i `entityType` pozostają bez zmian. Nowe pole **operacji**, nie payloadu, to `planWrite`. Przykład utworzenia planu offline:

```json
{
  "operations": [{
    "operationId": "10000000-0000-4000-8000-000000000001",
    "entityType": "workoutPlan",
    "entityId": "20000000-0000-4000-8000-000000000001",
    "baseVersion": 0,
    "deleted": false,
    "planWrite": {
      "schemaVersion": 1,
      "baseRevision": null
    },
    "payload": {
      "nazwa": "Trening A",
      "cwiczeniaIds": ["cw001"],
      "cel": "Siła",
      "dataUtworzenia": "2026-09-28T10:00:00.000Z",
      "progression": {
        "schemaVersion": 1,
        "revision": "30000000-0000-4000-8000-000000000001",
        "rules": {
          "cw001": {
            "revision": "40000000-0000-4000-8000-000000000001",
            "sets": 3,
            "repMin": 8,
            "repMax": 12,
            "incrementGrams": 1000,
            "maxWeightGrams": 20000,
            "maxRpe": 8
          }
        },
        "acceptedTargets": {
          "cw001": {
            "ruleRevision": "40000000-0000-4000-8000-000000000001",
            "weightGrams": 11000,
            "sets": 3,
            "repMin": 8,
            "repMax": 12,
            "acceptedAt": "2026-09-28T10:05:00.000Z",
            "source": {
              "endedAt": "2026-09-27T18:00:00.000Z",
              "fingerprint": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }
          }
        }
      }
    }
  }]
}
```

`cw001` jest przykładowym ID, nie poleceniem dodania/zmiany ćwiczenia w katalogu. `fingerprint` w przykładzie jest poprawnym syntaktycznie 64-znakowym hex, nie wyliczonym skrótem rzeczywistej sesji.

Aktualizacja: `baseVersion` jest znaną wersją serwera, `planWrite.baseRevision` jest odczytaną wcześniej `progression.revision`, a nowy payload zawiera **nowe UUID v4 rewizji całego planu**. UUID są małymi literami, kanoniczne z myślnikami. Rewizje nie są datami ani licznikami serwera; mogą powstać offline.

### 2.2. Snapshot, brak i usuwanie

- Payload bez klucza `progression` to stary format. Odczyt oznacza brak reguł i celów, ale nie automatyczne włączenie progresji.
- `progression: null` jest błędem, a nie poleceniem czyszczenia. Puste ustawienia nowego planu: `{"schemaVersion":1,"revision":"<nowe UUID v4>","rules":{},"acceptedTargets":{}}`.
- `rules` i `acceptedTargets` są wymaganymi mapami `exerciseId → obiekt`. Brak klucza ćwiczenia oznacza brak reguły/celu. Nie używać map wartości `null` ani tablic zawierających duplikaty ID.
- Każdy nowy zapis jest pełnym snapshotem, nie patchem. Jawne skasowanie reguły usuwa też cel tego ćwiczenia; czyszczenie wszystkich reguł pozostawia pusty obiekt progresji **z rewizją**. Ochrona przed starymi klientami pozostaje aktywna na zawsze dla tego UUID planu.
- Reguły kluczowane po ID ćwiczenia (nie pozycji): odpowiada to deduplikacji planu w etapie 1. Duplikaty w starej liście `cwiczeniaIds` pozostają dozwolone; reguła jest jedna na ID.
- Usunięcie chronionego planu wymaga `planWrite` i zgodnej rewizji. Payload usunięcia jest dokładnie ostatnim snapshotem, łącznie z tą samą rewizją. Backend nie przyjmuje usunięcia jako sposobu przepisania ustawień.
- Dla wszystkich planów z istniejącym tombstone zabronić `deleted:false`, także po zmianie `baseVersion`. Odtwarzanie tworzy nowe `entityId`, nie wskrzesza starego. Ponowne świadome usunięcie tombstone z aktualnymi warunkami może pozostać dozwolone.

### 2.3. Walidacja

Walidacja nowego formatu jest ścisła (`extra="forbid"`, bez konwersji string→number i bool→int). Stary format bez progresji pozostaje przy dotychczasowej walidacji ogólnego JSON; nie zaostrzać historycznych danych całej aplikacji przy okazji tej funkcji.

| Pole/inwariant | Reguła |
|---|---|
| `schemaVersion` | Dokładnie integer `1`; nie `true`, `1.0`, `"1"`. Nieznana wersja → 422. |
| Rewizje | Kanoniczny UUID v4. `planWrite.baseRevision` wymagane w obiekcie; jawne `null` tylko przy tworzeniu lub pierwszym przejściu ze starego formatu. |
| `sets`, `repMin`, `repMax` | Integer od 1 do `9007199254740991` (bezpieczny integer web); `repMin <= repMax`. UI może mieć niższe limity, ale nie dopisywać ich do kontraktu bez uzgodnienia. |
| Ciężary | Dodatnie całkowite **gramy**, maksimum bezpiecznego integera web. `incrementGrams <= maxWeightGrams`; cel `weightGrams <= maxWeightGrams`. 1250 oznacza 1,25 kg. Bez NaN/Infinity, floatów i jednostek domyślnych. |
| RPE | Integer 1–10. |
| Klucze map | Niepusty string, obecny w `cwiczeniaIds`. Backend nie ma autorytatywnego katalogu i nie zakłada regexu `cw\d+`. |
| Cel | Musi istnieć reguła; `ruleRevision` identyczne; `sets`, `repMin`, `repMax` identyczne z bieżącą regułą. |
| Daty nowych pól | UTC RFC3339 z `Z`, sekundy i opcjonalnie 1–6 cyfr ułamka; data kalendarzowa musi istnieć. Brak arbitralnego porównania z zegarem serwera, bo praca offline i rozjechane zegary są możliwe. |
| `source.fingerprint` | 64 małe znaki hex, SHA-256. Opis pochodzenia, **nie** token autoryzacyjny ani backendowy dowód wykonania. |
| Obecne pola payloadu v1 | Wymagane `nazwa`, `cwiczeniaIds` (lista stringów), `cel`, `dataUtworzenia` (UTC jak wyżej); bez `id`/metadata lokalnych. |

Decyzja o gramach eliminuje drift arytmetyki binarnej przy krokach ułamkowych. Nie zmieniać formatu historycznych `ciezarKg` serii. Klient konwertuje konfigurację kg→gramy dokładnie; nie zaokrągla po cichu konfiguracji o rozdzielczości mniejszej niż 0,001 kg. Jeżeli wynik źródłowy nie daje dokładnej dodatniej liczby gramów w przyjętej normalizacji klienta, nie generuje akceptowalnego celu zamiast zmieniać wynik historyczny.

Reguła przy edycji wartości dostaje nowe UUID `rules[id].revision`; niezmieniona zachowuje UUID. Zmiana tej rewizji wymaga usunięcia celu albo ponownej jawnej akceptacji celu odwołującego się do nowej rewizji. Backend sprawdza różne wartości pod tym samym UUID reguły; nie pozwala wykorzystać tego do ominięcia invalidacji.

### 2.4. Trzy różne rodzaje rewizji

1. `version`/`baseVersion`: istniejący serwerowy CAS całej encji i kolejność sync.
2. `progression.revision`/`planWrite.baseRevision`: offline UUID rewizji **całego planu**, także edycji nazwy/listy ćwiczeń; nie tylko reguł. Chroni przed automatycznym rebase starego snapshotu po pull.
3. `rules[id].revision`: wersja konfiguracji konkretnej reguły; cel wiąże się przez `ruleRevision`.

Każdy odrębny nowy upsert v1 zmienia rewizję całego planu. Retry nie tworzy nowej rewizji ani `operationId`. Wielokrotna akceptacja tej samej sugestii jest lokalnym no-op: przechować ten sam cel i `acceptedAt`, nie dodawać kolejnego kroku. Sugestia jest liczona z wyników sesji, nigdy z poprzedniego zaakceptowanego celu.

Nie trzeba rejestru wszystkich UUID rewizji na serwerze: klient generuje świeże UUID, serwer odrzuca użycie aktualnej rewizji jako nowej. To ochrona przed utratą przez zgodne/stare aplikacje, nie przed świadomie złośliwym właścicielem konta.

### 2.5. Macierz ochrony i format konfliktu

| Stan serwera / zapis | Wynik |
|---|---|
| Brak/żywy stary plan + legacy payload bez `planWrite` | Dotychczasowy sync, z wyjątkiem zakazu wskrzeszenia tombstone. |
| Brak/stary plan + pełne v1 + `baseRevision:null` | Dozwolone przy poprawnym `baseVersion`; jawny upgrade. |
| Chroniony plan + brak `planWrite`, także delete i poprawne `baseVersion` | `planContract / requiresUpgrade`, bez zapisu. |
| `planWrite` bez progresji lub progresja bez `planWrite` | 422, nie downgrade. |
| Chroniony plan + `baseRevision` różne/null | `planContract / revisionMismatch`; nie zmieniać warunku przez automatyczny rebase. |
| Tombstone + upsert | `planContract / deletedPlan`; nie odtwarzać planu. |
| Zgodna rewizja + niezgodne `baseVersion` | Istniejący `SyncConflict`; klient v1 nie ponawia bez analizy aktualnego snapshotu. |
| Ponowienie zatwierdzonego identycznego `operationId` | Dotychczasowe `accepted.duplicate:true`, nawet gdy plan później usunięto/uległ zmianie. Nie jest to nowy zapis. |

HTTP **200**, istniejący envelope `accepted/conflicts`; nowy wariant konfliktu (nie sam status 409):

```json
{
  "accepted": [],
  "conflicts": [{
    "operationId": "10000000-0000-4000-8000-000000000001",
    "kind": "planContract",
    "reason": "requiresUpgrade",
    "record": {
      "entityType": "workoutPlan",
      "entityId": "20000000-0000-4000-8000-000000000001",
      "version": 7,
      "payload": {
        "nazwa": "Trening A",
        "cwiczeniaIds": ["cw001"],
        "cel": "Siła",
        "dataUtworzenia": "2026-09-28T10:00:00.000Z",
        "progression": {
          "schemaVersion": 1,
          "revision": "30000000-0000-4000-8000-000000000001",
          "rules": {},
          "acceptedTargets": {}
        }
      },
      "deletedAt": null,
      "updatedAt": "2026-09-28T10:06:00Z"
    }
  }]
}
```

`reason` enum: `requiresUpgrade`, `revisionMismatch`, `deletedPlan`, `invalidRevision`, `deletePayloadMismatch`, `ruleRevisionReuse`. Snapshot konfliktu zawsze **sprzed batcha**, nigdy stan wycofanych zapisów. Stary `SyncService` rozpoznaje samo niepuste `kind` i blokuje zapis zamiast uruchomić `preserveLocal` rebase. Koszt bezpieczeństwa: taki rekord może blokować batch również z innymi zmianami. Nowy klient powinien izolować zablokowane operacje, wyświetlić wymaganie aktualizacji/ponownej akceptacji i nadal odbierać pull; nie zgłaszać sukcesu zapisu.

Nie da się ochronić nieznanych pól w **lokalnym eksporcie starej aplikacji**, która już ich nie przechowuje. Gwarancja dotyczy nieuszkodzenia istniejących danych serwera i odrzucania backupu v3 przez stary importer. Stary backup importowany jako nowe UUID z definicji nie zawiera progresji.

## 3. Offline, aktualność źródła i backup — umowa z klientem

### Offline i źródło

- W jednej transakcji: odczyt planu i zakończonej, nieusuniętej sesji/serii w bieżącym kontekście konta; porównanie tokenu sugestii; zapis celu + nowej rewizji planu + outbox. Po zmianie reguły, wyników, ostatniej sesji, konta albo usunięciu planu/sesji: przeliczyć i wymagać ponownego potwierdzenia, nie zapisywać celu.
- Token sugestii lokalnie obejmuje `planSyncId`, rewizję planu/reguły, tożsamość źródłowej sesji, wszystkie istotne wartości serii, stan zakończenia/usunięcia i kontekst konta. Fingerprint musi zmieniać się również po zmianie **zestawu** serii, nie tylko ich liczby. Dokładną kanonikalizację tokenu lokalnego ustala plan klienta; backend nie przelicza tego SHA i nie używa go do CAS.
- Trwałe `source` w zaakceptowanym celu zawiera tylko datę i fingerprint. Nie ma FK ani serwerowego wymagania istnienia sesji: cel może dotrzeć przed historią, a backup nadaje sesjom nowe UUID. Nie synchronizować kopii serii w planie.
- Nie mylić aktualności **przed lokalną akceptacją** z gwarancją globalną: serwer nie może znać jeszcze niezsynchronizowanych zmian drugiego urządzenia. Po ujawnieniu nowszej historii nowa sugestia wymaga akceptacji; już zaakceptowany cel pozostaje świadomym ustawieniem planu, nie wykonaniem.
- Wyłącznie klient sprawdza rodzaj ćwiczenia (ciężar i powtórzenia, nie izometria), komplet RPE i algorytm zwiększenia/utrzymania. Backend waliduje strukturę i spójność z regułą, nie udaje walidacji osiągnięć bez katalogu i atomowego snapshotu historii.
- `SyncStore.version` może nadal aktualizować `baseVersion`, ale **nigdy** `planWrite.baseRevision`. Próbowanej operacji nie wolno mutować. Rozwiązanie konfliktu to świadomie utworzona nowa operacja, nie podmiana rewizji w starym żądaniu.
- Scalenie niewysłanych A→B→C zachowuje bazową rewizję A i docelową C. Gdy A→B jest już attempted, następna B→C zostaje oddzielnie z bazą B; wysłać dopiero po ustaleniu wyniku A→B. Pull nie może podmienić tej bazy. Odrzucenie pierwszej operacji wymaga też rozstrzygnięcia operacji zależnych.
- Nowy format outbox ma trwale przechować `planWrite`, poza payloadem encji; migracja starych attempted żądań nie może dopisać mu nowych pól (zmieniłoby to digest). Niewysłane legacy operacje można jawnie przebudować na v1 dopiero po odczycie pełnego snapshotu; nie odgadywać brakujących ustawień.

### Backup

- Podnieść **backup `schemaVersion` do 3**, niezależnie od wersji Drift. Stary importer v2 już odrzuca większy numer przed transakcją.
- W `data.workoutPlans[]` zachować dotychczasowe pola backupu, w tym lokalne `id`, tekst JSON `cwiczeniaIds` oraz format `dataUtworzenia` z Drift. Dodać `progression` jako **obiekt JSON identyczny z wire**, nie podwójnie zakodowany string. Ewentualne wewnętrzne `progressionJson` nie jest nazwą pola backupu/wire.
- Import v1/v2 bez progresji: brak reguł/celów; po odtworzeniu nowy klient może utworzyć pusty obiekt v1 z nową rewizją. Nie nadaje domyślnych reguł.
- W v3 każdy plan musi mieć poprawny obiekt `progression`; eksport legacy wiersza normalizuje brak do pustego obiektu v1. Import starszego deklarowanego formatu z obecnym `progression` powinien odrzucić niezgodność wersji, nie ignorować pola.
- Validate wszystkie plany przed kasowaniem danych; rollback istniejącej transakcji chroni całą bazę/outbox także przy błędzie późniejszego wiersza. Błąd typu wersji/envelope przechwycić jako `ImportResult(success:false)`, nie wyjątek uciekający przed `try`.
- Odtworzenie nadaje nowe `syncId` planu, `syncVersion=0`, nową rewizję całego planu i `planWrite.baseRevision=null`; zachowuje wartości reguł, ich rewizje, cele, `acceptedAt` oraz archiwalne `source`. To round-trip danych domenowych, nie tożsamości synchronizacji. Fingerprint pochodzenia nie oznacza, że można ponownie zaakceptować starą sugestię bez odczytu bieżącej historii.
- Usunięcia zastępowanych planów muszą być kolejką v1 z oryginalnym snapshotem i oryginalną rewizją bazową. Stary restore nie przejdzie tego warunku na serwerze. Nowy restore po zdalnej zmianie również wymaga jawnego rozstrzygnięcia konfliktu.

### Ścieżki klienta do planu nadrzędnego (bez edycji w tym zadaniu)

`lib/core/database/tables/plans_table.dart`, `lib/core/database/tables/sync_tables.dart`, `lib/core/database/app_database.dart`, `lib/core/database/app_database.g.dart`, `lib/core/database/daos/plans_dao.dart`, `lib/core/database/daos/plans_dao.g.dart`, `lib/core/database/daos/sync_dao.dart`, `lib/core/database/daos/sync_dao.g.dart`, `lib/core/sync/sync_models.dart`, `lib/core/sync/sync_store.dart`, `lib/core/sync/sync_service.dart`, `lib/core/services/backup_service.dart`, `lib/features/planner/data/planner_repository.dart`.

Testy istniejące do rozszerzenia: `test/core/sync_persistence_test.dart`, `test/core/sync_service_test.dart`, `test/core/deferred_sync_test.dart`, `test/core/restore_sync_regression_test.dart`, `test/features/settings/backup_service_test.dart`. Nowe modele i testy silnika progresji pozostają decyzją autora klienta. Wymagane przypadki: restart z attempted + następną zmianą; scalenie niewysłanych; pull podczas dirty; brak rewizji nie znaczy pusty snapshot; zdalne usunięcie planu; zmiana konta; backup v1/v2/v3; cały rollback po jednym wadliwym celu; podwójna akceptacja bez nowej serii i bez kolejnego kroku.

## 4. Mapa przyszłych plików backendu

| Operacja | Ścieżka | Odpowiedzialność |
|---|---|---|
| Utworzyć | `backend/app/sync/plan_contract.py` | Modele v1, walidacja requestu i czysta kontrola przejścia rewizji. |
| Zmienić | `backend/app/sync/schemas.py` | Opcjonalne `planWrite`, walidacja zależna od typu encji, wariant konfliktu. |
| Zmienić | `backend/app/sync/service.py` | Digest rozszerzonego żądania oraz kontrola kontraktu pod blokadą przed CAS. |
| Utworzyć | `backend/tests/test_plan_contract.py` | Granice i ścisła walidacja payloadu. |
| Rozszerzyć | `backend/tests/test_sync.py` | HTTP/persistence, zgodność legacy, CAS, idempotencja, rollback, izolacja właściciela. |

`backend/app/sync/router.py` pozostaje bez zmiany logiki: request/response modele już są używane. `backend/app/sync/models.py` i migracje bez zmian. Nie dodawać zależności, nie aktualizować locków ani plików wdrożeniowych. Nie dodawać endpointu „zaakceptuj progresję” wymagającego sieci.

## 5. Zadania RED/GREEN dla przyszłej implementacji

Polecenia poniżej wykonywać z katalogu `/opt/fit/backend` przez `workdir`, nie w produkcyjnej bazie. Najpierw `docker info` (Docker wymagany również dla testów pozornie jednostkowych przez autouse `reset_database`), potem `make test-health PYTHON=python3.12`. Makefile sprawdza Python 3.12 i instaluje `requirements-build.lock` oraz `requirements-dev.lock` z `--require-hashes`. Brak Dockera/Pythona to blokada środowiska, nie wynik RED. Nie zastępować PostgreSQL SQLite.

### Zadanie 1: ścisłe modele i zależności między polami

**Pliki:** utworzyć `backend/tests/test_plan_contract.py`, `backend/app/sync/plan_contract.py`.

- [ ] **RED — dodać rzeczywiste testy wejścia:**

```python
from copy import deepcopy

import pytest
from pydantic import ValidationError

from app.sync.plan_contract import PlanPayload


def payload():
    return {
        "nazwa": "A", "cwiczeniaIds": ["cw001"], "cel": "Siła",
        "dataUtworzenia": "2026-09-28T10:00:00Z",
        "progression": {
            "schemaVersion": 1,
            "revision": "30000000-0000-4000-8000-000000000001",
            "rules": {"cw001": {
                "revision": "40000000-0000-4000-8000-000000000001",
                "sets": 3, "repMin": 8, "repMax": 12,
                "incrementGrams": 1250, "maxWeightGrams": 20000,
                "maxRpe": 8,
            }},
            "acceptedTargets": {},
        },
    }


@pytest.mark.parametrize("field,value", [
    ("sets", 0), ("sets", True), ("sets", "3"),
    ("repMin", 13), ("maxRpe", 0), ("maxRpe", 11),
    ("maxRpe", 8.5), ("incrementGrams", 1.25),
    ("incrementGrams", 20001), ("maxWeightGrams", 0),
])
def test_invalid_rule(field, value):
    data = payload()
    data["progression"]["rules"]["cw001"][field] = value
    with pytest.raises(ValidationError):
        PlanPayload.model_validate(data)


def test_fractional_kg_are_exact_integer_grams():
    data = payload()
    assert PlanPayload.model_validate(data).model_dump() == data


def test_target_must_match_rule_and_membership():
    data = payload()
    rule = data["progression"]["rules"]["cw001"]
    target = {
        "ruleRevision": rule["revision"], "weightGrams": 11250,
        "sets": 3, "repMin": 8, "repMax": 12,
        "acceptedAt": "2026-09-28T10:05:00Z",
        "source": {"endedAt": "2026-09-27T18:00:00Z", "fingerprint": "a" * 64},
    }
    data["progression"]["acceptedTargets"]["cw001"] = target
    PlanPayload.model_validate(data)
    for field, value in [("sets", 4), ("weightGrams", 20001),
                         ("ruleRevision", "40000000-0000-4000-8000-000000000002")]:
        invalid = deepcopy(data)
        invalid["progression"]["acceptedTargets"]["cw001"][field] = value
        with pytest.raises(ValidationError):
            PlanPayload.model_validate(invalid)
    data["cwiczeniaIds"] = []
    with pytest.raises(ValidationError):
        PlanPayload.model_validate(data)
```

- [ ] Uruchomić `.venv/bin/python -m pytest -q tests/test_plan_contract.py`; oczekiwany RED: brak `app.sync.plan_contract`, nie błąd infrastruktury.
- [ ] **GREEN — kod modeli w `backend/app/sync/plan_contract.py`:**

```python
from datetime import datetime
import re
from typing import Annotated
from uuid import UUID

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, model_validator


def uuid4_text(value: str) -> str:
    parsed = UUID(value)
    if parsed.version != 4 or str(parsed) != value:
        raise ValueError("canonical UUID v4 required")
    return value


def utc_text(value: str) -> str:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z", value):
        raise ValueError("UTC RFC3339 required")
    datetime.fromisoformat(value.replace("Z", "+00:00"))
    return value


Revision = Annotated[str, AfterValidator(uuid4_text)]
UtcText = Annotated[str, AfterValidator(utc_text)]
Positive = Annotated[int, Field(ge=1, le=9007199254740991)]
V1 = Annotated[int, Field(ge=1, le=1)]


class StrictModel(BaseModel):
    model_config = ConfigDict(strict=True, extra="forbid")


class PlanWrite(StrictModel):
    schemaVersion: V1
    baseRevision: Revision | None


class Rule(StrictModel):
    revision: Revision
    sets: Positive
    repMin: Positive
    repMax: Positive
    incrementGrams: Positive
    maxWeightGrams: Positive
    maxRpe: Annotated[int, Field(ge=1, le=10)]

    @model_validator(mode="after")
    def bounds(self):
        if self.repMin > self.repMax or self.incrementGrams > self.maxWeightGrams:
            raise ValueError("invalid rule bounds")
        return self


class Source(StrictModel):
    endedAt: UtcText
    fingerprint: Annotated[str, Field(pattern=r"^[0-9a-f]{64}$")]


class Target(StrictModel):
    ruleRevision: Revision
    weightGrams: Positive
    sets: Positive
    repMin: Positive
    repMax: Positive
    acceptedAt: UtcText
    source: Source


class Progression(StrictModel):
    schemaVersion: V1
    revision: Revision
    rules: dict[str, Rule]
    acceptedTargets: dict[str, Target]


class PlanPayload(StrictModel):
    nazwa: str
    cwiczeniaIds: list[str]
    cel: str
    dataUtworzenia: UtcText
    progression: Progression

    @model_validator(mode="after")
    def references(self):
        p = self.progression
        for exercise_id in p.rules:
            if not exercise_id or exercise_id not in self.cwiczeniaIds:
                raise ValueError("rule exercise not in plan")
        for exercise_id, target in p.acceptedTargets.items():
            rule = p.rules.get(exercise_id)
            if rule is None:
                raise ValueError("target without rule")
            if (target.ruleRevision != rule.revision
                    or target.sets != rule.sets
                    or target.repMin != rule.repMin
                    or target.repMax != rule.repMax
                    or target.weightGrams > rule.maxWeightGrams):
                raise ValueError("target does not match rule")
        return self
```

Nazwy camelCase modeli domenowych są tutaj celowe: dokładnie oddają wire, nie wymagają reserializacji payloadu. Metadane istniejących modeli sync nadal używają ich dotychczasowych aliasów.

- [ ] Ponowić powyższe polecenie; oczekiwany GREEN. Przed integracją dodać poniższe przypadki i ponowić polecenie:

```python
@pytest.mark.parametrize("change", [
    {"schemaVersion": 2}, {"schemaVersion": True}, {"extra": 1},
    {"revision": "not-a-uuid"},
])
def test_rejects_unknown_or_invalid_progression(change):
    data = payload()
    data["progression"].update(change)
    with pytest.raises(ValidationError):
        PlanPayload.model_validate(data)


@pytest.mark.parametrize("value", [None, [], "{}"])
def test_progression_is_required_object(value):
    data = payload()
    data["progression"] = value
    with pytest.raises(ValidationError):
        PlanPayload.model_validate(data)


@pytest.mark.parametrize("value", ["2026-02-30T10:00:00Z", "2026-09-28T10:00:00", 0])
def test_invalid_date(value):
    data = payload()
    data["dataUtworzenia"] = value
    with pytest.raises(ValidationError):
        PlanPayload.model_validate(data)


@pytest.mark.parametrize("rpe", [1, 10])
def test_rpe_edges_and_duplicate_plan_ids(rpe):
    data = payload()
    data["cwiczeniaIds"] = ["cw001", "cw001"]
    data["progression"]["rules"]["cw001"]["maxRpe"] = rpe
    PlanPayload.model_validate(data)
```

### Zadanie 2: envelope operacji i zachowanie digestu legacy

**Pliki:** zmienić `backend/app/sync/schemas.py`, `backend/app/sync/service.py`; rozszerzyć `backend/tests/test_plan_contract.py`.

- [ ] **RED — testować, że stary digest pozostaje identyczny, a nowy warunek jest jego częścią:**

```python
import hashlib
import json
from uuid import uuid4

from app.sync.schemas import PushOperation
from app.sync.service import request_digest


def test_plan_write_is_bound_to_digest_without_changing_legacy_digest():
    raw = {
        "operationId": str(uuid4()), "entityType": "workoutPlan",
        "entityId": str(uuid4()), "baseVersion": 0,
        "payload": {"nazwa": "legacy"}, "deleted": False,
    }
    expected = hashlib.sha256(json.dumps(
        raw, sort_keys=True, separators=(",", ":")
    ).encode()).hexdigest()
    assert request_digest(PushOperation.model_validate(raw)) == expected
    raw["payload"] = payload()
    raw["planWrite"] = {"schemaVersion": 1, "baseRevision": None}
    first = request_digest(PushOperation.model_validate(raw))
    raw["planWrite"]["baseRevision"] = str(uuid4())
    assert request_digest(PushOperation.model_validate(raw)) != first


@pytest.mark.parametrize("mode", ["missing_write", "missing_payload", "other_entity", "null_write"])
def test_rejects_partial_plan_envelope(mode):
    raw = {
        "operationId": str(uuid4()), "entityType": "workoutPlan",
        "entityId": str(uuid4()), "baseVersion": 0, "deleted": False,
        "payload": payload(),
        "planWrite": {"schemaVersion": 1, "baseRevision": None},
    }
    if mode == "missing_write":
        del raw["planWrite"]
    elif mode == "missing_payload":
        del raw["payload"]["progression"]
    elif mode == "other_entity":
        raw["entityType"] = "mood"
    else:
        raw["planWrite"] = None
    with pytest.raises(ValidationError):
        PushOperation.model_validate(raw)
```

- [ ] Uruchomić `.venv/bin/python -m pytest -q tests/test_plan_contract.py`; RED dla nowego pola/warunku.
- [ ] **GREEN — w `PushOperation` dodać pole i walidator, importując `model_validator`, `PlanWrite`, `PlanPayload`:**

```python
plan_write: PlanWrite | None = Field(default=None, alias="planWrite")

@model_validator(mode="after")
def validate_plan_contract(self):
    supplied = "plan_write" in self.model_fields_set
    has_progression = "progression" in self.payload
    if self.entity_type != "workoutPlan":
        if supplied:
            raise ValueError("planWrite is only allowed for workoutPlan")
        return self
    if supplied != has_progression or (supplied and self.plan_write is None):
        raise ValueError("progression and non-null planWrite must occur together")
    if supplied:
        PlanPayload.model_validate(self.payload)
    return self
```

Walidator tylko sprawdza; nie przypisuje `model_dump()` do payloadu i nie wstawia domyślnych pól. W `request_digest` przed dotychczasowym `return`:

```python
if operation.plan_write is not None:
    canonical_operation["planWrite"] = operation.plan_write.model_dump(mode="json")
```

W ten sposób stare żądania **nie** dostają `planWrite:null` w digest i zachowują możliwość retry po aktualizacji backendu.

- [ ] Uruchomić `.venv/bin/python -m pytest -q tests/test_plan_contract.py tests/test_sync.py`; oczekiwany GREEN bez zmian wyników legacy.

### Zadanie 3: ochrona rewizji i tombstone pod istniejącą blokadą

**Pliki:** `backend/app/sync/plan_contract.py`, `backend/app/sync/schemas.py`, `backend/app/sync/service.py`, `backend/tests/test_sync.py`.

- [ ] **RED — dopisać do `test_sync.py` (korzysta z istniejących `account`, `authenticate`, `operation`):**

```python
def plan_operation(*, entity_id=None, base_version=0, base_revision=None,
                   revision=None, protected=True, deleted=False):
    value = {
        "nazwa": "A", "cwiczeniaIds": ["cw001"], "cel": "Siła",
        "dataUtworzenia": "2026-09-28T10:00:00Z",
    }
    if protected:
        value["progression"] = {
            "schemaVersion": 1, "revision": revision or str(uuid4()),
            "rules": {}, "acceptedTargets": {},
        }
    op = operation(entity_id=entity_id, base_version=base_version,
                   payload=value, deleted=deleted)
    op["entityType"] = "workoutPlan"
    if protected:
        op["planWrite"] = {"schemaVersion": 1, "baseRevision": base_revision}
    return op


@pytest.mark.parametrize("deleted", [False, True])
async def test_legacy_cannot_overwrite_or_delete_protected_plan(client, account, deleted):
    headers = await authenticate(client, account)
    first = plan_operation()
    result = await client.post("/api/sync/push", json={"operations": [first]}, headers=headers)
    assert result.status_code == 200 and len(result.json()["accepted"]) == 1
    legacy = plan_operation(entity_id=first["entityId"], base_version=1,
                            protected=False, deleted=deleted)
    result = await client.post("/api/sync/push", json={"operations": [legacy]}, headers=headers)
    assert result.json()["accepted"] == []
    conflict = result.json()["conflicts"][0]
    assert conflict["kind"] == "planContract"
    assert conflict["reason"] == "requiresUpgrade"
    assert conflict["record"]["payload"] == first["payload"]
    pull = await client.get("/api/sync/pull")
    assert len(pull.json()["changes"]) == 1


async def test_plan_revision_blocks_automatic_base_version_rebase(client, account):
    headers = await authenticate(client, account)
    first = plan_operation()
    await client.post("/api/sync/push", json={"operations": [first]}, headers=headers)
    stale = plan_operation(entity_id=first["entityId"], base_version=1,
                           base_revision=str(uuid4()))
    response = await client.post("/api/sync/push", json={"operations": [stale]}, headers=headers)
    assert response.json()["conflicts"][0]["reason"] == "revisionMismatch"
```

- [ ] Uruchomić `.venv/bin/python -m pytest -q tests/test_sync.py -k 'protected_plan or plan_revision'`; RED: stary zapis dziś zostaje zaakceptowany.
- [ ] **GREEN — dopisać czysty strażnik w `plan_contract.py`:**

```python
from typing import Literal

PlanConflictReason = Literal[
    "requiresUpgrade", "revisionMismatch", "deletedPlan",
    "invalidRevision", "deletePayloadMismatch", "ruleRevisionReuse",
]


def transition_reason(*, old_payload: dict, old_deleted: bool,
                      new_payload: dict, deleted: bool,
                      write: PlanWrite | None) -> PlanConflictReason | None:
    old = old_payload.get("progression")
    protected = "progression" in old_payload
    if protected and write is None:
        return "requiresUpgrade"
    if old_deleted and not deleted:
        return "deletedPlan"
    if write is None:
        return None
    # Uszkodzony/nieznany stan chroniony nigdy nie staje się legacy.
    if protected and (not isinstance(old, dict) or old.get("schemaVersion") != 1
                      or not isinstance(old.get("revision"), str)):
        return "requiresUpgrade"
    expected = old["revision"] if protected else None
    if write.baseRevision != expected:
        return "revisionMismatch"
    new = new_payload["progression"]
    if deleted and protected:
        return None if new_payload == old_payload else "deletePayloadMismatch"
    if not deleted and new["revision"] == expected:
        return "invalidRevision"
    if protected:
        for exercise_id, rule in new["rules"].items():
            previous = old.get("rules", {}).get(exercise_id)
            if previous is not None and previous.get("revision") == rule["revision"] and previous != rule:
                return "ruleRevisionReuse"
    return None
```

W `schemas.py` dodać wariant i włączyć go do unii `PushResponse.conflicts`:

```python
from app.sync.plan_contract import PlanConflictReason


class PlanContractConflict(SyncSchema):
    operation_id: UUID = Field(alias="operationId")
    kind: Literal["planContract"] = "planContract"
    reason: PlanConflictReason
    record: SyncRecordResponse
```

W `service.py` importować `PlanContractConflict`, `transition_reason`, poszerzyć lokalną adnotację `conflicts` o nowy wariant. W pętli, **po deduplikacji i pobraniu `record`, przed obsługą health i `baseVersion`**, wstawić:

```python
if operation.entity_type == "workoutPlan":
    reason = transition_reason(
        old_payload=record.payload,
        old_deleted=record.deleted_at is not None,
        new_payload=operation.payload,
        deleted=operation.deleted,
        write=operation.plan_write,
    )
    if reason is not None:
        conflicts.append(PlanContractConflict(
            operation_id=operation.operation_id,
            reason=reason,
            record=planned_record_response(committed_records[record_key]),
        ))
        continue
```

Nie dodawać nowego commitu/transakcji ani odrębnych zapytań poza blokadami. Kontrola korzysta z roboczego `records`, aby drugi zapis tego samego planu w batchu widział pierwszy; snapshot błędu korzysta z `committed_records`, bo batch zostanie wycofany. Deduplikacja pozostaje pierwsza.

- [ ] Ponowić testy zadania, następnie `.venv/bin/python -m pytest -q tests/test_plan_contract.py tests/test_sync.py`; oczekiwany GREEN.

### Zadanie 4: rollback, retry, log wersji, izolacja i brak wskrzeszenia

**Pliki:** wyłącznie rozszerzenie testów `backend/tests/test_sync.py`; implementacja zadań 1–3 powinna wystarczyć. Jeżeli test ujawni błąd, poprawić tylko wskazaną funkcję zgodnie z kontraktem i ponowić RED/GREEN.

- [ ] **Sprawdzić round-trip rzeczywistej reguły i zaakceptowanego celu, bez tworzenia sesji/serii:**

```python
async def test_plan_rule_and_target_round_trip_without_workout_records(client, account):
    headers = await authenticate(client, account)
    op = plan_operation()
    rule_revision = str(uuid4())
    op["payload"]["progression"]["rules"] = {"cw001": {
        "revision": rule_revision, "sets": 3, "repMin": 8, "repMax": 12,
        "incrementGrams": 1250, "maxWeightGrams": 20000, "maxRpe": 8,
    }}
    op["payload"]["progression"]["acceptedTargets"] = {"cw001": {
        "ruleRevision": rule_revision, "weightGrams": 11250,
        "sets": 3, "repMin": 8, "repMax": 12,
        "acceptedAt": "2026-09-28T10:05:00Z",
        "source": {"endedAt": "2026-09-27T18:00:00Z", "fingerprint": "a" * 64},
    }}
    response = await client.post("/api/sync/push", json={"operations": [op]}, headers=headers)
    assert response.status_code == 200 and len(response.json()["accepted"]) == 1
    changes = (await client.get("/api/sync/pull")).json()["changes"]
    assert len(changes) == 1
    assert changes[0]["entityType"] == "workoutPlan"
    assert changes[0]["payload"] == op["payload"]
    legacy = plan_operation(entity_id=op["entityId"], base_version=1, protected=False)
    response = await client.post("/api/sync/push", json={"operations": [legacy]}, headers=headers)
    assert response.json()["conflicts"][0]["record"]["payload"] == op["payload"]


async def test_legacy_plan_can_be_upgraded_but_not_downgraded(client, account):
    headers = await authenticate(client, account)
    old = plan_operation(protected=False)
    response = await client.post("/api/sync/push", json={"operations": [old]}, headers=headers)
    assert response.json()["accepted"][0]["version"] == 1
    upgrade = plan_operation(entity_id=old["entityId"], base_version=1)
    response = await client.post("/api/sync/push", json={"operations": [upgrade]}, headers=headers)
    assert response.json()["accepted"][0]["version"] == 2
    old["operationId"] = str(uuid4())
    old["baseVersion"] = 2
    response = await client.post("/api/sync/push", json={"operations": [old]}, headers=headers)
    assert response.json()["conflicts"][0]["reason"] == "requiresUpgrade"
```

- [ ] **RED/GREEN — dodać integracyjny test łańcucha offline i niezmiennego retry:**

```python
async def test_plan_chain_pull_snapshots_retry_and_tombstone(client, account):
    from copy import deepcopy

    headers = await authenticate(client, account)
    first = plan_operation()
    revision_a = first["payload"]["progression"]["revision"]
    second = plan_operation(entity_id=first["entityId"], base_version=1,
                            base_revision=revision_a)
    body = {"operations": [first, second]}
    response = await client.post("/api/sync/push", json=body, headers=headers)
    assert [a["version"] for a in response.json()["accepted"]] == [1, 2]
    response = await client.post("/api/sync/push", json=body, headers=headers)
    assert all(a["duplicate"] for a in response.json()["accepted"])
    pull = (await client.get("/api/sync/pull")).json()
    assert [c["payload"] for c in pull["changes"]] == [first["payload"], second["payload"]]

    altered = deepcopy(second)
    altered["planWrite"]["baseRevision"] = str(uuid4())
    response = await client.post("/api/sync/push", json={"operations": [altered]}, headers=headers)
    assert response.json()["conflicts"][0]["kind"] == "operationReuse"

    deletion = deepcopy(second)
    deletion.update(operationId=str(uuid4()), baseVersion=2, deleted=True)
    deletion["planWrite"]["baseRevision"] = second["payload"]["progression"]["revision"]
    response = await client.post("/api/sync/push", json={"operations": [deletion]}, headers=headers)
    assert response.json()["accepted"][0]["version"] == 3
    revival = plan_operation(entity_id=first["entityId"], base_version=3,
                             base_revision=deletion["planWrite"]["baseRevision"])
    response = await client.post("/api/sync/push", json={"operations": [revival]}, headers=headers)
    assert response.json()["conflicts"][0]["reason"] == "deletedPlan"
    response = await client.post("/api/sync/push", json={"operations": [first]}, headers=headers)
    assert response.json()["accepted"][0]["duplicate"] is True
```

- [ ] **Dodać test braku częściowego zapisu i snapshotu sprzed batcha:**

```python
async def test_plan_conflict_rolls_back_whole_batch(client, account):
    headers = await authenticate(client, account)
    first = plan_operation()
    await client.post("/api/sync/push", json={"operations": [first]}, headers=headers)
    good = plan_operation(entity_id=first["entityId"], base_version=1,
                          base_revision=first["payload"]["progression"]["revision"])
    bad = plan_operation(entity_id=first["entityId"], base_version=2,
                         protected=False, deleted=True)
    unrelated = operation()
    response = await client.post("/api/sync/push",
        json={"operations": [unrelated, good, bad]}, headers=headers)
    assert response.json()["accepted"] == []
    conflict = response.json()["conflicts"][0]
    assert conflict["record"]["version"] == 1
    assert conflict["record"]["payload"] == first["payload"]
    pull = (await client.get("/api/sync/pull")).json()
    assert len(pull["changes"]) == 1
    response = await client.post("/api/sync/push",
        json={"operations": [good]}, headers=headers)
    assert response.json()["accepted"][0]["duplicate"] is False


async def test_plan_invalid_payload_rejects_entire_request(client, account):
    headers = await authenticate(client, account)
    bad = plan_operation()
    bad["payload"]["progression"]["schemaVersion"] = True
    response = await client.post("/api/sync/push",
        json={"operations": [operation(), bad]}, headers=headers)
    assert response.status_code == 422
    assert (await client.get("/api/sync/pull")).json()["changes"] == []
```

- [ ] **Dodać test izolacji użytkowników na poziomie serwisu:**

```python
async def test_plan_revision_is_scoped_to_owner(account, session):
    other = User(email=f"other-{uuid4()}@example.com",
                 password_hash=PasswordHasher().hash(PASSWORD))
    session.add(other)
    await session.commit()
    first = plan_operation()
    result = await sync_service.push_operations(session, account.id,
        [PushOperation.model_validate(first)])
    assert len(result.accepted) == 1
    legacy = plan_operation(entity_id=first["entityId"], protected=False)
    result = await sync_service.push_operations(session, other.id,
        [PushOperation.model_validate(legacy)])
    assert len(result.accepted) == 1
    own = await sync_service.pull_changes(session, account.id, 0)
    foreign = await sync_service.pull_changes(session, other.id, 0)
    assert own.changes[0].payload == first["payload"]
    assert "progression" not in foreign.changes[0].payload
```

- [ ] Uruchamiać po każdym teście `.venv/bin/python -m pytest -q tests/test_sync.py -k plan`. Oczekiwany GREEN dla kontraktu; przed dodaniem kodu z zadań 1–3 testy ochrony muszą być RED. Nie osłabiać asercji, żeby dopasować obecne nadpisywanie payloadu.
- [ ] Dodać do istniejących testów współbieżności wariant dwóch nowych operacji tego samego planu z tą samą bazową rewizją: jedna accepted, druga konflikt; użyć istniejącego `transaction_session_factory` i `asyncio.gather`, nie jednego `AsyncSession` w dwóch taskach. Gotowy rdzeń testu:

```python
async def test_concurrent_plan_writes_have_one_winner(account, session, transaction_session_factory):
    first = plan_operation()
    await sync_service.push_operations(session, account.id, [PushOperation.model_validate(first)])
    left = plan_operation(entity_id=first["entityId"], base_version=1,
                          base_revision=first["payload"]["progression"]["revision"])
    right = plan_operation(entity_id=first["entityId"], base_version=1,
                           base_revision=first["payload"]["progression"]["revision"])

    async def send(raw):
        async with transaction_session_factory() as database:
            return await sync_service.push_operations(database, account.id,
                [PushOperation.model_validate(raw)])

    results = await asyncio.wait_for(asyncio.gather(send(left), send(right)), timeout=10)
    assert sum(len(r.accepted) for r in results) == 1
    assert sum(len(r.conflicts) for r in results) == 1
```

### Zadanie 5: odbiór kontraktu bez wdrożenia

**Pliki do weryfikacji:** powyższe pięć plików backendu; brak zmian deploy, modeli DB, migracji serwera i locków.

- [ ] `.venv/bin/python -c 'import sys; assert sys.version_info[:2] == (3, 12)'`.
- [ ] `.venv/bin/python -m pytest -q tests/test_plan_contract.py tests/test_sync.py` — wszystkie przypadki kontraktu i dotychczasowy sync muszą przejść na PostgreSQL Testcontainers.
- [ ] `.venv/bin/python -m pytest -q` — pełna regresja backendu, w szczególności health z jego odmienną polityką tombstone i istniejąca idempotencja.
- [ ] `git diff --check` i przegląd diffu tylko pięciu plików z mapy. Nie przypisywać wcześniejszych zmian backendu tej implementacji. Nie commitować ani wdrażać w ramach tego planu.
- [ ] Autor klienta potwierdza identyczne nazwy JSON, jednostkę gramów, RPE, nowy wariant konfliktu, trwałość `planWrite`, scalanie rewizji, backup v3 oraz brak wskrzeszenia. Dopiero po tym kontrakt jest zamknięty do implementacji obu stron.

## 6. Kryteria domknięcia etapu 3a

- [ ] Stary klient nadal tworzy/modyfikuje niechroniony plan; brak progresji odczytuje się jako brak ustawień.
- [ ] Pierwszy zapis v1 jawnie chroni dany UUID planu, także po wyczyszczeniu obu map.
- [ ] Stary upsert, delete i restore z aktualnym `baseVersion` nie usuwają progresji.
- [ ] Nowy klient nie może ominąć konfliktu przez samo podniesienie `baseVersion`.
- [ ] Nie ma częściowego zapisu batcha, wskrzeszenia tombstone ani przecieku między kontami.
- [ ] Retry legacy zachowuje stary digest; retry v1 jest związane również z warunkiem rewizji; log pull zachowuje osobny snapshot każdej wersji.
- [ ] Reguły/cele mają walidację strict i nie są pomijane w outbox/pull/backup klienta.
- [ ] Akceptacja offline jest lokalnie atomowa i idempotentna; źródło nie wymaga sieci ani nowej kopii historii na serwerze.
- [ ] Backend nie obiecuje globalnej aktualności niezsynchronizowanej historii, a klient nie przedstawia fingerprintu jako takiej gwarancji.

**Przegląd zakresu:** etap 1 i 2, UI progresji oraz deterministyczny silnik nie są implementowane tutaj. Niniejszy plan pokrywa backendowy kontrakt i warunki przekazania do klienta, nie zastępuje jego testów akceptacji sugestii i round-trip backupu. Żadnego wykonania tego planu nie rozpoczęto.
