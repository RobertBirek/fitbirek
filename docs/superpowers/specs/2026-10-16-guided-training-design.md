# Prowadzony trening, trwałość i rozszerzenie kręgosłupa

Użytkownik zatwierdził sześć propozycji po wydaniu1.13.0+26 i dodatkową
kolekcję ćwiczeń kręgosłupa. Bez karate, bez zmiany istniejących363ID/treści.

## Etapy i granice

1. Prowadzenie przez plan: bieżący blok/ilustracja/wskazówka i cele,
   potwierdzenie rzeczywistej serii, pominięcie/zamiana, następny blok.
2. Wznowienie: lokalny trwały szkic per konto+syncIDsesji, nie sam lokalnyID.
   Odtwarzanie po zamknięciu/reloadzie nie zalicza niepotwierdzonego czasu.
   Wznowienie/startodcinkaodnowa/zakończenie wymagają decyzji użytkownika.
3. Plan a wykonanie: oryginalny snapshot planu, zdarzenia wykonania,
   faktyczne serie/sekundy, zmiany/pominięcia i krótka notatka. Bez ocen
   zdrowotnych i automatycznej krytyki mniejszej objętości.
4. Wyjaśnienia generatora: deterministyczne powody z rzeczywistych kryteriów,
   mięśni, sprzętu i wzorców; zamiennik jawnie pokazuje podobieństwa/różnice.
5. Własne warianty: stabilneUUID, bazoweexerciseID, nazwa i parametry
   zakres/tempo/pauza/obciążenie/wskazówka. Nie tworzyć nowychcwID ani nie
   kodować wariantu w nazwie/ciężarze. Historia/PR scopeexercise+side+variantID;
   NULL wariant bazowy, nie przypisywać go historycznym rekordom.
6. Synchronizacja zapisanych filtrów i definicji wariantów, offline-first,
   z tombstones i deterministycznym scalaniem konfliktów per element.

## Kontrakty trwałości

- Drift10→11 zarezerwowany dla prowadzonego treningu i trwałego szkicu.
  Snapshot/progress guided zapisuje się opcjonalnie jako payload.guidance
  workoutSession, schemaVersion1; klient waliduje przed zapisem i izoluje
  uszkodzony snapshot, zachowując zwykłą historię. Szkice formularzy i
  niezapisanych interwałów lokalne, nie tworzą rekordów domenowych/PR.
- Drift11→12 zarezerwowany dla wariantów i chmurowych preferencji. Pola
  nullablevariantId/variantLabel w seriach iPR, pełny backup/restore/sync.
- NIE dodawać nowego entityType do wspólnego pull: stare klienty nie znają
  go i blokowałyby kursor. Kolekcje to ustawienia właściciela w istniejącym
  profile: optionalpayload.filterPresets i payload.exerciseVariants.
- Obie kolekcje: version1, wpisy ze stabilnymid iupdatedAtUtc/deletedAtUtc;
  brak usuwania tombstones bez świadomej polityki. ProfileCAS zachowany;
  konflikty kolekcji scalane perID, scalona świeża operacja po odrzuceniu,
  nigdy mutacja attempted payloadu. Pozostałe pola profilu zachowują istniejącą
  politykę konfliktów. Nie przywracać usuniętego profilu automatycznie.
- Backend zachowuje z aktualnego snapshotu znane opcjonalne rozszerzenia,
  gdy starszy klient ich nie wysyła: profile.filterPresets/exerciseVariants,
  workoutSession.guidance, workoutSet/personalRecord.variantId/variantLabel.
  Weryfikacja idempotency/hash dotyczy ORYGINALNEJ operacji; merge dopiero
  do utrwalanego rekordu. ExplicitNULL to nie omission. Nie modyfikować CAS,
  globalnego kursora, tombstones i izolacji kont.
- Skopiować lokalne presetySharedPreferences jednorazowo pod tym samym kontem,
  bez dublowania i bez wymazania danych przed potwierdzonym zapisem transakcji.

## Kręgosłup

Osobna kolekcja spine w istniejącym słowniku styles indeksu offline,
etykieta 'Kręgosłup — ruch i stabilizacja', grupa UI 'Styl / kolekcja'.
Nie dodawać nowego klucza kryteriów planu: starszy parser odrzuca nieznane
restrykcje. DynamiczneID istniejącego styles jest kompatybilne. To kolekcja,
nie grupa mięśni 'kręgosłup'; dotychczasowe style wpisów zachowane.
Uwzględnić stosowne istniejące ćwiczenia i kilka rzeczywiście nowych ruchów
po audycie AAOS/NHS/fizjoterapii. ŹródłemXLSX i konwerter, noweID odcw364,
wszystkie wcześniejsze dane zachowane. Opisy ogólnego ruchu/stabilizacji,
bez obietnicy leczenia dyskopatii i bez wymuszania ruchu przez ból.
Nowe ruchy z ilustracjami512, źródło1024/preview przed kolejnym żądaniem.

## Sprawdzanie i publikacja

Testy restarts/offline/accountswitch/restore i niezmiennościoutboxa,
porównańwariantów, konfliktówdwóchurządzeń/oldprofileomission, retry/hash.
Brak nowych zależności i toolchain. Bez operacji produkcyjnych podczas
implementacji. Publikacja wymaga osobnego bezpiecznego etapu API+web, bo
backend omissionmerge jest nowym zachowaniem, mimo braku Alembic.
