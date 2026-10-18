# Training Rhythm — końcowy raport integracji, 2026-10-17

> **Aktualizacja 2026-10-18:** opisane niżej FAIL reloadu/PWA są historycznymi
> wynikami wcześniejszych obrazów. [Nowszy raport Offline Readiness](offline-readiness-results-2026-10-18.md)
> zastępuje je wyłącznie dla rzeczywiście ponowionych scenariuszy na
> `fit-web:offline-final` (w tym recovery i SC 404/retry). Zachowujemy całą
> historię; telefon nadal **MANUAL PENDING**, rollout dwóch compiled wydań
> **NOT TESTED** — nie ma zbiorczego „wszystko PASS”.

## Werdykt i stan lokalny

**Trzy funkcje są zaimplementowane i przeszły końcowe testy integracyjne;
review implementacji nie ma otwartych HIGH/MEDIUM. Pełna akceptacja produktu
nie ma zbiorczego PASS.** Pozostają znane ograniczenia automatycznego reloadu
aktywnego ekranu i offline PWA oraz **MANUAL PENDING** na fizycznym telefonie.

Stan to lokalne, niecommitowane zmiany względem **`e0fe9a6`**, bez bumpa wersji
(**1.14.0+27**), commit/push/deploy. Ten raport konsoliduje istniejące dowody;
aktualizacja dokumentacji nie uruchamiała ponownie testów ani builda.
Flutter **3.35.4**, Dart **3.9.2**; katalog369, ilustracje, zależności, lockfile
i artefakty Web SQLite pozostają bez zmian.

## Zaimplementowany zakres

| Moduł | Stan i granica zachowania | Dowody |
|---|---|---|
| Powtórz trening | Wierny snapshot oryginalnego planu albo wszystkie rzeczywiste serie jako cele. Nowy UUID, bez kopiowania wykonania/PR. Zachowane mixed reps+seconds i obciążenia czasowe; RPE historyczne jest odniesieniem. | [Moduł repeat](modules/workout-repeat.md), **26 focused PASS**, workout+planner **269 PASS**. |
| Rytm tygodnia | Kalendarz lokalnych dni, UUID reguły i deterministyczne UUIDv5 wystąpienia; pojedyncze przesunięcie, jawne zaliczenie sesją z wykonaniem. Drift **13**, addytywna migracja 12→13 i nullable profil. | [Moduł weekly schedule](modules/weekly-schedule.md), testy migracji/CAS/restore/routera, browser retest poniżej. |
| Trendy | Tylko odczyt zakończonej nieusuniętej historii; exact scope `exerciseId + nullable side + nullable variantUUID`, NULL ≠ both. **2** porównywalne sesje = porównanie, **≥3** = trend; ciężary i kontrakty RPE osobno. | [Moduł trends](modules/training-trends.md), **28 focused PASS**, dowody read-only SQLite/API/PostgreSQL. |

Cele wykonania repeat i ich kursor są **lokalnym szkicem**, nie synchronizują
się i nie są eksportowane w backupie. Nie odtwarzamy nieznanych legacy
protokołów timerów. Niedostępne ćwiczenie/wariant blokuje potwierdzenie bez
cichego mapowania. Trendy pokazują czas/rundy jako obserwacje, gdy zapis nie
dowodzi porównywalnego protokołu; nie zmieniają PR ani zaleceń progresji.

### Cloud i kompatybilność

- `weeklySchedule` jest opcjonalnym rozszerzeniem istniejącego profilu, bez
  nowego `SyncEntityType`. Backend zachowuje omission **po kontroli hash/CAS**;
  explicit NULL czyści, obecna wartość zastępuje całą kolekcję. Hash dotyczy
  oryginalnego requestu, nie payloadu wzbogaconego przez serwer.
- Kwarantanna/hold obejmuje **wszystkie trzy kolekcje**: `filterPresets`,
  `exerciseVariants`, `weeklySchedule`. Nieczytelne dane zatrzymują operacje
  danego profilu; niezależne encje i **globalny pull** nadal postępują.
- Zachowane są raw remote/deferred i niezmienne attempted requesty
  (UUID/payload/baseVersion/hash). Hold przeżywa restart; poprawiony remote
  ani zwykłe „Synchronizuj teraz” nie zwalniają go automatycznie.
- Recovery jest ręczne przez guarded API serwisu klienta
  `SyncService.retryProfileCollectionConflict(accountId, profileId)`, nie nowy
  endpoint HTTP ani automatyczny przycisk naprawy. Przed recovery zachować
  backup **i osobny eksport surowego deferred/outboxa**; walidacja poprzedza
  rekonstrukcję nowej operacji, a końcowy status wymaga rzeczywistego ACK.
- Backup schemaVersion **2** zachowuje harmonogram i remapuje referencje
  odtwarzanych planów/sesji. Nie przepisuje attempted payloadów.

Kontrakty i procedura: [weekly schedule — hold/recovery](modules/weekly-schedule.md#high-review--izolacja-konfliktu-nieczytelnej-kolekcji),
[user variants/cloud](modules/user-variants-cloud.md),
[backend SYNC_EXTENSIONS](../backend/SYNC_EXTENSIONS.md).

## Końcowa weryfikacja techniczna

| Bramka | Wynik zapisany w dowodach |
|---|---|
| Pełny Flutter po poprawce startu harmonogramu | **771 PASS / 0 FAIL** |
| `flutter analyze` | **No issues found — 0 uwag** |
| Pełny backend z PostgreSQL 16 | **378 PASS** |
| Generator / końcowa kontrola właściciela | **17/17** `*.g.dart` / `*.freezed.dart` zgodne; 0 zmian w końcowym porównaniu |
| Format zmienionych Dart / version check | Sukces, bez zmiany wersji |
| Runtime web build | **PASS**, `fit-web:rhythm-local-fixed` |

Identyfikacja gotowego obrazu web (index/manifest list SHA256):

```text
sha256:d93e53313b83fb16316fe55498c65a76ef75c418ae22760179704c657ef2741e
```

Źródła końcowych wyników:

- [Log Flutter/analyze/build](file:///root/.local/share/opencode/tool-output/tool_14a8f6e19001IMqk4rOm2tFhh5)
  (`tool_14a8f6e19001IMqk4rOm2tFhh5`): 771, analyze 0 i eksport fixed image.
- [Pełny backend](file:///tmp/opencode/weekly-schedule-backend-full-20261017.log):
  `378 passed in 564.19s`; [backend kontrakt i RED/GREEN](../backend/SYNC_EXTENSIONS.md#weryfikacja-i-przyszłe-wdrożenie).
- [Końcowy owner verify](file:///tmp/opencode/fit-schedule-integration/schedule-router-full/verification.log),
  [17 generated](file:///tmp/opencode/fit-schedule-integration/schedule-router-full/generated-comparison.json),
  [snapshot](file:///tmp/opencode/fit-schedule-integration/schedule-router-full/snapshot-manifest.json),
  [source drift](file:///tmp/opencode/fit-schedule-integration/schedule-router-full/source-drift.json).
- [Wcześniejsze ponowienie generatora](file:///tmp/opencode/fit-schedule-integration/full-current/generated-comparison.json):
  17/17 bez zmian. Późniejsze poprawki nie zmieniały deklaracji generowanych.

Historyczne RED, pośrednie błędy fixture'ów migracji, 22 uwagi analyze oraz
przebiegi 752/770 nie zostały wymazane z raportów modułów. Są chronologią
starszych snapshotów; końcowy stan integracji to powyższe **771/0/378**.

## Rzeczywista przeglądarka i API

[Pełny raport browser](training-rhythm-browser-acceptance-2026-10-17.md)
zachowuje pierwotny **FAIL** harmonogramu oraz
[najnowszy retest](training-rhythm-browser-acceptance-2026-10-17.md#retest-po-poprawce-nawigacji--2026-10-17-najnowszy-wynik).
Oba przebiegi korzystały z rzeczywistego API i osobnego PostgreSQL, nie stubów.

| Przebieg | Wynik i zakres |
|---|---|
| Pierwotny `fit-web:rhythm-local` | Repeat **PASS**: dwa cele 9/7 przy 5 kg, nowy UUID, jawny zapis, trwały kursor. Trends **PASS**: 1/2/3 sesje, odrębne kg/NULL/both/wariant, read-only. Harmonogram **FAIL**: pusta treść po starcie, mimo trwałej sesji. |
| Najnowszy `fit-web:rhythm-local-fixed` | Harmonogram **FIXED PASS** dla anulowania/startu: prawdziwy aktywny ekran i ćwiczenie, jedna sesja/szkic, 0 automatycznych serii/PR. Po jawnym wznowieniu: seria, finish, ręczne zaliczenie i pull drugiej przeglądarki **PASS**. |
| Repeat/trends na fixed | Tylko **smoke PASS** podglądów repeat i trendu jednej sesji, z identycznymi snapshotami SQLite/API/PostgreSQL przed/po. Pełnych wcześniejszych przypadków 2/3 i scope nie ponawiano na fixed. |

### Znane ograniczenie UX — bezpośredni reload aktywnej strony

**FAIL automatycznego odtworzenia ekranu** po reloadzie `/#/workout/session`:
widoczny nagłówek, ale treść „Wybierz ćwiczenia, aby zacząć logować serie”.
UUID, guidance i szkic pozostają zachowane. **Home/Trening → Kontynuuj → Wznów**
skutecznie przywraca plan pod tym samym UUID i umożliwia dokończenie testu.
To znane ograniczenie UX, **nie pełny autorecovery PASS** i nie ponowny pusty
ekran po starcie, który został naprawiony.

Dowody browser:

- [Pierwotny katalog](file:///tmp/opencode/rhythm-accept-20261017-f7c921/):
  `verification.json`, `26-active.png`, `62-repro-start-blank.png`, dowody repeat
  i trendów wskazane w raporcie.
- [Fixed retest](file:///tmp/opencode/rhythm-retest-20261017-a6d482/):
  `05-active-real-exercise.png`, `06-reload-active.png`,
  `08-reload-failure.json`, `11-resume-proof.json`, `15-completed-ui.png`,
  `16-second-pulled-db.json`, `19-smoke-readonly-proof.json`, `verification.json`.

Akceptacja browser nie zastępuje pełnej macierzy guardów, protokołów mieszanych
ani testu fizycznego urządzenia. W fixed retest wszystkie dane domenowe powstały
w UI; syntetyczne próbki trendów w pierwszym przebiegu pochodziły jawnie z real API.

## PWA: wynik baseline, osobny od nowych funkcji

[Raport PWA](pwa-offline-acceptance-2026-10-17.md) badał **1.14.0+27**,
`fit-web:candidate-1.14.0-27`, obraz:

```text
sha256:a2121f18d6cc6ddb4f6d400bcc2ab8d4cb0b41a38d83fe4909a7717213fafa06
```

**Nie był to build repeat/schedule/trends ani fixed runtime.** Nie przenosimy
tych PASS/FAIL jako nowego pomiaru nowych funkcji; znane problemy pozostają
udokumentowane i nie zostały naprawione w tej pracy.

- **Pełna akceptacja offline: FAIL.** Root po jednej wizycie online (także po
  restarcie) nie działa; `/today` bez fallbacku offline nie działa; nieodwiedzone
  ilustracje i fonty są niedostępne, w próbce widoczne braki znaków.
- **PASS warunkowy** dla root/hash link po naturalnym dogrzaniu cache.
- **PASS w opisanym warm-cache scenariuszu**: guided offline, trwały szkic,
  jawna seria, restart procesu Chromium z tym samym profilem offline, finish,
  reconnect i realny ACK/pull bez duplikatów. Cały origin był zatrzymany,
  sprawdzono rzeczywisty SW/cache; harness nie pobierał całego katalogu.
- Reconnect dowodzi wysłania trwałego outboxa po odzyskaniu łączności, nie
  same-process reconnect ani działania synchronizacji w tle.

[Artefakty PWA](file:///tmp/opencode/pwa-offline-20261017-b82e41/):
`verification.json` odróżnia `evidenceAssertions=PASS` od
`functionalAcceptance=FAIL`; zachowano transport proof, cache snapshots,
screeny, restart PID, odczyty SQLite i PostgreSQL.

## Hardware manual pending i przekazanie

**Fizyczny telefon: MANUAL PENDING / UNTESTED.** Przygotowana
[checklista iOS/Android](pwa-offline-acceptance-2026-10-17.md#ręczna-lista-ios--android--nadal-untested)
wymaga platformy/modelu użytkownika, dostępnego nieprodukcyjnego originu z TLS
i konta testowego. Zakres: instalacja standalone, cold/warm start, lock ekranu,
usunięcie z ostatnich aplikacji, oszczędzanie energii, osobny checkpoint timera,
jawne serie i foreground reconnect. Headless restart nie zalicza tych prób.
Nie ma potwierdzenia pracy timera/JS/Wake Lock/background sync w tle.

Prace implementacyjne i testy integracyjne zakończono lokalnie z powyższymi
jawnymi wynikami i ograniczeniami. Nie ma deklaracji „wszystkie acceptance PASS”.
Przyszły release wymaga osobnej zgody i bumpa wersji według `AGENTS.md`;
**API należy wdrożyć przed web**, aby omission starych klientów zachowywało
`weeklySchedule`. **Bez nowej migracji Alembic — pozostaje 0010**; Drift 13 jest
migracją klienta. Nie zmieniano katalogu ani zależności.

Dokumenty źródłowe: [master design](superpowers/specs/2026-10-17-training-rhythm-design.md),
[plan z aktualnym statusem](superpowers/plans/2026-10-17-training-rhythm.md),
[AGENTS](../AGENTS.md), raporty i moduły podlinkowane wyżej.
