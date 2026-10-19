# Związanie podglądu Mentora z zatwierdzonymi danymi

Selektory notatki i pojedynczej masy (ręcznej oraz Apple Health) są tokenami
Fernet, nie surowymi ID. Poza kontem, ID rekordu, kategorią, źródłem i rewizją
ustawień zawierają teraz SHA-256 ograniczonej projekcji w uwierzytelnionej,
zaszyfrowanej części tokenu. Nie przechowujemy dodatkowego snapshotu zdrowia,
nie logujemy payloadów ani digestów i nie zmieniamy schematu bazy.

Digest obejmuje normalizowaną datę oraz wartość masy albo datę sesji i notatkę
po trim i ograniczeniu do 500 znaków — dokładnie dane użyte do podglądu/projekcji.
Źródło i kategoria są osobno związane tokenem. Zmiana daty unieważnia selektor,
nawet jeśli UI pokazuje tylko dzień. Zmiana pól niewysyłanych (np. metadanych
importu), wersji sync lub części notatki poza limitem nie unieważnia zgody.
Nie wiążemy tokenu z całym JSONB ani z numerem wersji rekordu. Identyczna
projekcja pozostaje dozwolona, także po ponownym zapisie źródła.

Przy rozwiązywaniu kontekstu backend pobiera aktualny żywy rekord należący do
konta i porównuje digest. Zmiana projekcji, usunięcie, inne konto, inna rewizja
lub stary token bez digestu daje ogólne HTTP 409:
`{"detail":"Context selection unavailable"}`. Nie ujawniamy powodu, ID ani
wartości. Kontrola następuje przed `reserve`, zapisem wiadomości, naliczeniem
limitu i wywołaniem dostawcy. Po kontroli wysyłana jest wyłącznie ta zweryfikowana
projekcja w pamięci, nie ponownie odczytana treść po ewentualnej zmianie źródła.
Przełączniki agregatów treningu/profilu/Apple Health nie są selektorami rekordu
i zachowują dotychczasowy kontrakt zgód.

## Rollout i klient

**Podglądy należy odświeżyć po zmianie źródła oraz po aktualizacji backendu.**
Stare selektory celowo nie mają ścieżki zgodności omijającej digest. Ponowienie
starego tokenu nie wywoła dostawcy; należy pobrać `/api/mentor/context-options`
i ponownie zatwierdzić wybór. W mieszanej puli stary/nowy backend tokeny mogą
być wzajemnie odrzucane; należy zakończyć aktualizację wszystkich instancji
przed ponownym wyborem kontekstu. To dokumentacja kontraktu, nie wdrożenie.

Flutter rozpoznaje tę dokładną odpowiedź HTTP 409 (bez kodu innego konfliktu)
wyłącznie przy wysyłaniu wiadomości jako `MentorContextSelectionUnavailable`.
`MentorConversation.send` usuwa optymistyczną wiadomość, zachowuje szkic w polu
tekstu i informuje o odrzuceniu przed wywołaniem dostawcy oraz konieczności
odświeżenia podglądu, ponownego wyboru i potwierdzenia. Ponowne jawne otwarcie
okna pobiera świeże opcje; poprzednie selektory nie są przywracane. Nie ma
automatycznego POST, zatwierdzenia ani fallbacku wysyłającego zmienione dane.

Po takim odrzuceniu klient usuwa z lokalnego rejestru tylko wpis nowej próby,
o której wiadomo, że nie doszła do `reserve`. Jeżeli jest to ponowienie próby
o nieznanym wyniku, jej wpis pozostaje: późniejsze odrzucenie nie dowodzi braku
wcześniejszego kosztu. Inne konflikty 409, błędy transportu i błędy odczytu
statusu nie zwalniają tej ochrony. Błąd zapisu rejestru również nie pozwala
automatycznie uruchomić nowej operacji. Zmiana konta zamyka podgląd i ignoruje
spóźnione odpowiedzi, bez przywracania szkicu ani selektorów starego konta.

Regresje klienta pokrywa `test/features/mentor/mentor_context_rejection_test.dart`:
rzeczywisty Dio z adapterem HTTP, klasyfikacja konfliktów, odrzucone wysłanie,
zachowany tekst, świeży podgląd, ponowny wybór i jawne pojedyncze wysłanie,
ochrona nieznanego wyniku oraz zmiana konta. Zestaw Mentora (68 testów) i analiza
`lib/features/mentor test/features/mentor` przeszły w obrazie
`fit-web:release-1.13.0-26-verified` z `--network none`.

Testy HTTP z uwierzytelnieniem pokrywają trzy rodzaje źródeł, zmiany treści/dat,
brak zmian, pola nieistotne, usunięcia, stare selektory, inne konto i rewizję.
Dla odrzucenia sprawdzają ogólną odpowiedź, zero wywołań dostawcy i brak
`MentorRequest`; po odświeżeniu podglądu zmieniona treść może zostać zatwierdzona.
