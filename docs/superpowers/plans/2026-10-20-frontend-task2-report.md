# Frontend usability — zadanie 2: głos i układ Mentora

## Zakres i dokładne pliki

- `lib/features/mentor/presentation/pages/mentor_page.dart` — przegląd transkrypcji, dostępność, naturalny przepływ i composer.
- `lib/features/mentor/providers/mentor_providers.dart` — po poprawce P2 jawny wynik pojedynczego wysłania; bez zmian rejestru/API i stanu trwałego.
- `test/features/mentor/mentor_flow_test.dart` — istniejące scenariusze głosowe wymagają teraz ręcznego Wyślij; sprawdzają 0→1 POST i poprawiony payload. Fixture rejestruje treść oraz pozwala kontrolować odczyt ustawień. Jedyny zmieniony selektor istniejącej akcji Stop to tooltip zamiast tekstu.
- `test/features/mentor/mentor_usability_test.dart` — 13 nowych testów rzeczywistej strony.
- `test/features/mentor/mentor_send_audio_test.dart` — 12 regresji P2: puste/niepoprawne wysłanie i przypisanie opcjonalnego audio do właściwej operacji.
- `docs/superpowers/plans/2026-10-20-frontend-task2-report.md` — ten raport.

Zachowano wszystkie zastane zmiany Ustawień i zadania 1. Bez zmian innych ekranów, backendu, endpointów, modeli/schematu, zależności, wersji ani globalnego motywu/fontów. `mentor_settings_page.dart` pozostaje bez zmian: obietnica korekty transkrypcji jest teraz zgodna z wykonaniem. Bez subagentów, commit/push/deploy.

## Przyczyny i decyzje

1. `_record()` po STT wywoływał `_send(autoPlayReply: true)`, mimo obietnicy poprawienia tekstu. Teraz wynik trafia wyłącznie do istniejącego kontrolera szkicu. Widoczna instrukcja „Sprawdź transkrypcję i wybierz Wyślij” oraz akcja „Anuluj transkrypcję” nie wykonują operacji dostawcy. Ręczny przycisk albo świadomy submit klawiatury korzysta z dotychczasowego `_send`, zgód i kontekstu. Dotychczasowa intencja głosowej odpowiedzi jest przenoszona w nietrwałym znaczniku szkicu; TTS może nastąpić dopiero po ręcznym wysłaniu, nie po STT. Anulowanie szkicu usuwa tę intencję.
2. Dwa stałe panele flex 2:3 odbierały przestrzeń rozmowie; stan niedostępności znajdował się pod harmonogramem i sugestiami, a drugi panel zawierał powtórzony CTA. Niedostępny Mentor ma teraz jedną listę: rzeczywisty powód/loading/error, ustawienia, jeden klasyczny trening, następnie harmonogram. Przy błędzie konfiguracji dostępne jest ponowienie odczytu, bez płatnej operacji. Nie renderuje martwego czatu ani sugestii. Wejście szablonu zachowuje szkic i ręczną alternatywę również bez konfiguracji.
3. Skonfigurowany Mentor ma jeden główny scroll rozmowy. Harmonogram/podpowiedzi są rozwijane wewnątrz tego samego przepływu, nie w drugim małym scrollporcie. Composer ma pełnej szerokości pole i osobny wiersz ikon z celami co najmniej 48×48. Desktop ma limit 960 px; istniejący Inter, grafit/pomarańcz i jasny motyw są dziedziczone bez zmian.
4. Status nagrania/przetwarzania, Odtwórz i instrukcja przeglądu należą do przewijanej rozmowy. Pozostawienie ich w stałej stopce powodowało rzeczywisty overflow przy małej wysokości i 200%. Dodatkowy test bounds wykrył, że sama instrukcja mogła być częściowo poza widokiem: zagnieżdżony Scaffold konsumuje `viewInsets`, więc pole zachowywało trzy linie mimo klawiatury. `LayoutBuilder` reaguje teraz również na rzeczywistą wysokość body <500 px; wtedy pole ma jedną przewijalną linię. Przy większej wysokości zachowuje trzy linie. Placeholder ma jedną linię, nie przycina się treści transkrypcji ani instrukcji. Stop jest ikoną przy composerze wyłącznie podczas nagrania, transportu głosowego albo przygotowanego audio; wywołuje istniejące zatrzymanie/anulowanie lokalnego audio i transportu, nie obiecuje cofnięcia kosztu u dostawcy.

## Bezpieczeństwo i kompatybilność

Rejestr operacji i API pozostają nietknięte. Nieznany wynik STT zachowuje identyfikator i nadal blokuje cichą nową próbę. Następne nagranie wymaga istniejącego dialogu o ponownym limicie/koszcie; Anuluj nie rozpoczyna nagrania. Stop i nawigacja nie usuwają metadanych nieznanej operacji.

Generacje konta/głosu nadal odrzucają spóźnione wyniki. Zmiana konta/nawigacja usuwa prywatny szkic i znacznik przeglądu; zwykłe loading/odświeżenie konfiguracji nie kasuje szkicu. Nic z transkrypcji/audio nie jest utrwalane. Usunięcie/zmiana/nowa rozmowa zeruje znacznik głosowego szkicu. Istniejące guards kontekstu, źródłowej generacji propozycji oraz scroll-to-latest/reading gesture/new-reply nie zostały osłabione.

## RED → GREEN i wyniki

Wszystkie polecenia Flutter/Dart wykonano w istniejącym obrazie `fit-web:release-1.13.0-26-verified`, bind `/opt/fit:/app`, z `--no-pub`. Potwierdzono Flutter **3.35.4**, Dart **3.9.2**.

- `/tmp/opencode/task2-red.log`: przed implementacją 6 porażek — auto-send daje POST=1 zamiast 0; brak stanu dostępności na początku, zbyt wąskie pole. Zmieniono oczekiwane zachowanie dwóch istniejących testów głosowych, nie usunięto ich asercji TTS/odtwarzania.
- `/tmp/opencode/task2-green2.log`: dodatkowa reprodukcja overflow 38/70 px podczas głosu przy 320/375×550, tekst 200%, keyboard 180. Usunięcie stałego stosu statusów z footera daje GREEN bez ukrywania treści. Test ponowienia STT wymagał zaczekania na zamknięcie SnackBar, który zasłaniał ikonę; nie wyciszono ostrzeżenia trafienia kliknięcia.
- Pierwsza próba GREEN wykryła także CTA obecny w drzewie, ale poza trafialną częścią viewportu. Skrócono stan niedostępności i usunięto redundantny opis. Nowe testy sprawdzają bounds i `hitTestable`, nie tylko findery.
- `/tmp/opencode/task2-focused-final.log`: **203/203 PASS** dla `test/features/mentor`, `test/features/schedule`, `test/app/router_test.dart`. Pierwsza analiza po nich wykryła jedną uwagę o klamrach; poprawiono ją.
- `/tmp/opencode/task2-hint-red.log`: po wzmocnieniu testu do rzeczywistych bounds instrukcji wykryto top=-30 px przy 320/375 i keyboard. Sama zmiana `hintMaxLines` nie wystarczyła. Oparcie `maxLines` o rzeczywistą wysokość przez LayoutBuilder usunęło przyczynę. `/tmp/opencode/task2-visible-final.log`: **13/13 PASS**, w tym bounds/trafialność całej instrukcji przeglądu przed wysłaniem.
- `/tmp/opencode/task2-final-verify.log` (ponowienie po końcowej poprawce wysokości): świeże `flutter analyze --no-pub` — **No issues found**, `dart tools/generate_app_version.dart --check` — PASS, pełne `flutter test --no-pub --reporter expanded` — **1292/1292 PASS**. Wcześniejsze pełne przejście znajduje się w `task2-full-final.log`. Formatowano tylko trzy własne pliki Dart. Testy harmonogramu emitują istniejące ostrzeżenia Drift o wielu instancjach testowej bazy; nie ukrywano ich.
- `git diff --check` — PASS.

Nowe scenariusze obejmują edycję/anulowanie szkicu, zero chat/TTS przed wysłaniem, oczekujące STT po zmianie konta/Stop/zakładki, nieznany wynik i jawne płatne ponowienie, prywatność SharedPreferences, odświeżenie ustawień bez kasowania szkicu, szerokości 320/375 z tekstem 200% i keyboard, focus pola, bounds/cel 48 px oraz limit desktopu i rozwijanie harmonogramu we wspólnym scrollu. Istniejące testy zachowują reading drag/wheel/jump, wyścigi scroll callback, historię i nową odpowiedź, kontekst, ledger oraz źródłowe generacje propozycji.

Nie zmieniono deklaracji Drift/Freezed/JSON, więc generator nie był potrzebny. SHA-256 `pubspec.lock`, `web/sqlite3.wasm` i `web/drift_worker.dart.js` są identyczne z obrazem bazowym (Drift 2.28.2/sqlite3 2.9.4).

## Pozostałe bramy

Niezależny review oraz finalny immutable build i screenshoty przeglądarkowe light/dark/768/1280 pozostają do sesji integrującej. W tej sesji przeczytano audyt i obejrzano wskazany zrzut „przed”, nie wykonano browserowego „po”. Rzeczywisty mikrofon/Safari/iPhone, zgody sprzętowe i odtwarzanie na urządzeniu pozostają ręcznymi bramami z `docs/mentor.md`. Nie wykonano żadnego płatnego żądania AI ani testu produkcyjnego.

## Poprawka po review P2 — pusty szkic i niewłaściwa odpowiedź TTS

Potwierdzona przyczyna: po wyczyszczeniu transkrypcji `_voiceDraft` nadal przenosił zamiar audio. Provider kończył `send` pustego tekstu jako no-op, ale UI interpretował brak błędu jako sukces i wybierał ostatnią odpowiedź z historii. Mogło to wywołać płatne TTS starej odpowiedzi bez nowego czatu. Ten sam problem dotyczył odzyskanego wyniku wcześniejszej operacji.

Zmiany ograniczone do ścieżki wysyłania/audio i jej testów:

- `_send` waliduje trim: pusto albo ponad 2000 znaków kończy się **przed** send, rejestrem, odczytem wyniku i audio. Wyczyszczenie pola przez użytkownika usuwa również znacznik intencji głosowej, bez operacji dostawcy.
- `MentorConversation.send` zwraca `Future<MentorSendResult?>`: null dla no-op/błędu/unieważnienia; potwierdzony wynik zawiera konkretną odpowiedź, rozmowę i flagę `newReply`. Flaga jest prawdziwa wyłącznie dla nowo przydzielonej operacji oraz ID odpowiedzi asystenta nieobecnego w aktualnej historii. Replay/reconcile i próba o wcześniejszym nieznanym wyniku nigdy nie upoważniają do automatycznego TTS.
- UI nie wybiera już `replies.last`. Odtwarza wyłącznie `result.reply` z nowego potwierdzonego send, po sprawdzeniu generacji strony/głosu, konta, tożsamości kontrolera, rozmowy i aktualnych zgód/gotowości głosu. Późny wynik po zmianie konta/rozmowy nie przywraca szkicu ani audio.
- Szkic i znacznik przeglądu są czyszczone dopiero po potwierdzonym wyniku i tylko jeśli pole nadal zawiera tekst tej próby. Edycja podczas await pozostaje w polu. Błąd/no-op nie czyści szkicu.
- Dwa istniejące scenariusze prawidłowego głosu używają teraz różnych ID wcześniejszej i nowej odpowiedzi. Nie usunięto asercji czatu/TTS/odtwarzania; dodano osobną regresję duplikatu starego ID.

RED: `/tmp/opencode/task2-review-p2-red.log`, **6 porażek / 11 scenariuszy** przed poprawką: pusty/biały/nadmierny tekst powodował TTS, replay odtwarzał `old`, reconcile nieznanego wyniku odtwarzał `answer`, a cofnięta podczas await zgoda głosowa nie blokowała audio. Po poprawce dodano także scenariusz starego ID zwróconego przez send.

Końcowy GREEN: `/tmp/opencode/task2-review-p2-final.log`, przypięty obraz `fit-web:release-1.13.0-26-verified`, format tylko czterech własnych plików Dart, **114/114 Mentor PASS**, **analyze: No issues found**, version check PASS, **pełna suita 1304/1304 PASS**, `git diff --check` PASS. Pierwsza analiza poprawki zgłosiła dwie brakujące pary klamer; naprawiono przed końcowym przebiegiem.

Test pustego szkicu porównuje pełny snapshot technicznego rejestru sprzed Wyślij z rejestrem po Wyślij: **0 chat POST, 0 TTS, 0 nowych rezerwacji**, żadnego odtworzenia poprzedniej odpowiedzi. Poprawny, edytowany STT daje jeden chat i wyłącznie audio nowego ID; błąd, no-op, replay i stare ID nie tworzą TTS. Zgody, wybór kontekstu i rejestr operacji pozostają bez zmian. Nie zmieniono UI poza czyszczeniem nieaktualnej intencji przy pustym polu; brak zmian backendu/schema/deps/generatora i brak commit/push/deploy. Poprzednie wyniki 1292/1292 powyżej dotyczą stanu przed tą poprawką; aktualny wynik to 1304/1304.
