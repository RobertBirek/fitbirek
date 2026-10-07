import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled offline help. Deliberately has no account, API or token input.
/// Keep the instructions aligned with docs/apple-health-shortcut.md and v1 API.
class HealthSetupGuidePage extends StatelessWidget {
  const HealthSetupGuidePage({super.key});

  Future<void> _copyExample(BuildContext context) async {
    try {
      await Clipboard.setData(const ClipboardData(text: healthExampleJson));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skopiowano przykład bez tokenu.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nie udało się skopiować. Zaznacz przykład i skopiuj go ręcznie.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Łączenie ze Zdrowiem')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Instrukcja dostępna offline. Konfigurację wykonujesz w aplikacji Skróty na iPhone; wysłanie danych i synchronizacja wymagają internetu. Angielskie nazwy akcji pomagają odnaleźć je niezależnie od języka iOS.',
                  ),
                  const _Section(
                    '1. Przygotuj dostęp i token',
                    '''W FitBirek wróć do Ustawienia → Apple Zdrowie. Zaloguj się online, odśwież status, wybierz „Generuj token” i przeczytaj zgodę na wysłanie danych zdrowotnych na VPS. Po zaznaczeniu zgody wybierz „Generuj”.

Token jest pokazywany tylko raz. Przenieś go wyłącznie do prywatnego Skrótu, do nagłówka Authorization. Zmiana aplikacji lub zamknięcie dialogu ukrywa token; jeśli go utracisz, użyj „Obróć token”. Kopiowanie przez zaznaczenie używa schowka systemowego — usuń token ze schowka po wklejeniu.

Ta instrukcja nie pobiera ani nie wyświetla Twojego tokenu. „Obróć token” natychmiast wyłącza poprzedni — zaktualizuj nagłówek Skrótu. „Odbierz dostęp” blokuje przyszłe importy, ale nie usuwa wcześniejszych danych. Nie udostępniaj Skrótu z tokenem; po ujawnieniu odwołaj dostęp.''',
                  ),
                  const _Section(
                    '2. Ręcznie potwierdź kroki',
                    '''1. W aplikacji Skróty utwórz nowy Skrót „FitBirek — Zdrowie”.
2. W Zdrowiu otwórz Aktywność → Kroki, widok dnia. Odczytaj dzienny wynik dla wybranego dnia Europe/Warsaw. Przy podróży nie przypisuj zagranicznego przedziału dnia do dnia warszawskiego.
3. Dodaj Ask for Input, typ Text: „Dzień wyniku (Europe/Warsaw), YYYY-MM-DD”, np. 2026-09-10.
4. Dodaj Ask for Input, typ Number: „Dzienny wynik kroków widoczny w Zdrowiu”. Bez domyślnego zera. Gdy brak wyniku lub zgody, anuluj; 0 wyślij tylko jako świadomie potwierdzony wynik.
5. Dodaj Dictionary: day (Text, odpowiedź z punktu 3), value (Number, odpowiedź z punktu 4), method (Text, manual_verified_total).
6. Dodaj List z jednym elementem: ten Dictionary.

To ręcznie potwierdzony dzienny total, NIE automatyczny import kroków. Nie sumuj surowych próbek Apple Watch i iPhone, także przez Group by Day. Nie dodawaj automatyzacji w tle.''',
                  ),
                  const _Section(
                    '3. Ustaw żądanie w Skrótach',
                    '''1. Dodaj URL. Użyj adresu HTTPS właściwego serwera FitBirek i ścieżki poniżej. <SERWER_FITBIREK> zastąp domeną serwera; pierwszą próbę wykonaj na koncie i serwerze testowym, nie produkcyjnym.

https://<SERWER_FITBIREK>/api/integrations/apple-health/import

2. Dodaj Get Contents of URL i rozwiń opcje:
• Method: POST
• Headers → Authorization: Bearer <TWOJ_TOKEN>
• Headers → Content-Type: application/json

<TWOJ_TOKEN> to wyłącznie placeholder. W prywatnym Skrócie zastąp go swoim tokenem, zachowując „Bearer” i jedną spację. Token nigdy nie trafia do URL, query, JSON, notatek ani logów. Nie dodawaj cookies.

3. Request Body ustaw na JSON:
• version: Number, 1
• weights: pusta Array
• steps: Array ze słownikiem kroków (lub zmienna List z poprzedniej sekcji).

Sprawdź typ Array w edytorze iOS. Słownik ma być obiektem, nie tekstem zawierającym JSON. Liczby ustaw jako Number, nie sklejaj tekstu z polskim przecinkiem dziesiętnym.

4. Dodaj Show Result dla odpowiedzi API — nigdy dla nagłówków ani tokenu. Uruchamiaj Skrót ręcznie.''',
                  ),
                  const _Section(
                    '4. Dodaj wybraną masę w kg',
                    '''Przed akcją URL dodaj:
1. Find Health Samples: Body Mass (czasem Weight), zakres np. ostatnich 7 dni, jednostka kg, bez grupowania, sortowanie Start Date od najnowszych, limit np. 10. Zezwól tylko na odczyt masy. Nie dodawaj Log Health Sample.
2. Choose from List: na początek wybierz jedną próbkę, nie całą historię.
3. Get Details of Health Sample: odczytaj Value, Unit, Start Date i Source wybranej próbki. Porównaj je ze Zdrowiem. Jeśli Unit nie jest kg, przerwij i popraw konfigurację — zmiana etykiety lb na kg nie przelicza wartości.
4. Format Date dla Start Date: ISO 8601 z offsetem lub UTC Z, np. 2026-09-10T08:00:00+02:00. Użyj czasu próbki, nie uruchomienia Skrótu.
5. Dictionary: measuredAt (Text, sformatowana data), value (Number, Value), unit (Text, kg), source (Text, Source). Źródło: 1–100 znaków, stała nazwa przy powtórzeniach, bez danych osobowych.
6. W JSON akcji POST zamień weights na Array z tym Dictionary. Dla samej masy pomiń pytania o kroki i ustaw steps na pustą Array.

Nie wysyłaj surowego Health Sample ani jednostki dopisanej do liczby. Nie wymagamy UUID HealthKit; nie generuj losowego UUID. Późniejszy wybór wielu próbek można obsłużyć przez Repeat with Each i listę słowników, do 100 elementów łącznie i 64 KiB.''',
                  ),
                  const _Section(
                    '5. Przykład JSON bez sekretów',
                    '''Przycisk kopiuje tylko poniższy szablon, nigdy token ani nagłówki. Placeholdery w nawiasach <…> zastąp czasem próbki (ISO 8601 z offsetem lub Z), nazwą źródła oraz dniem YYYY-MM-DD. 80.5 i 7500 to liczby syntetyczne — też zastąp je wybranymi własnymi wartościami. Nie wysyłaj szablonu bez zmian ani danych przykładowych na produkcję.

Samą masę wyślij z steps: [], same kroki z weights: []. Nie wysyłaj obu list pustych. Liczby JSON mają kropkę i nie są w cudzysłowach.''',
                  ),
                  const SelectableText(healthExampleJson),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _copyExample(context),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Kopiuj przykładowy JSON'),
                  ),
                  const _Section(
                    '6. Wynik, powtórzenia i synchronizacja',
                    '''Sukces zwraca liczniki imported, duplicates, ignoredDeleted oraz czas lastImportAt. Błąd nie oznacza udanego importu. Wróć do FitBirek i zsynchronizuj dane na tym samym koncie; sprawdź masę w Postępach i kroki na Dziś z właściwą datą. Offline pozostają ostatnio zsynchronizowane dane — brak nowego wyniku nie oznacza zera.

Identyczna masa jest duplikatem. Zmiana czasu, wartości lub źródła tworzy nową próbkę; błędną poprzednią usuń osobno. Równoważne czasy UTC i z offsetem oznaczają tę samą próbkę.

Kroki zastępują cały total dnia, także mniejszym wynikiem — nie dodają się. Po korekcie ponowne wysłanie starej, wcześniej przyjętej wartości jest ignorowane jako replay; nie obchodź tego zmianą dnia.

Usunięte próbki nie odradzają się po imporcie. Usunięcie w FitBirek nie usuwa danych ze Zdrowia i odwrotnie. Pomiary ręczne FitBirek są odrębne.''',
                  ),
                  const _Section(
                    '7. Rozwiązywanie problemów',
                    '''401 — sprawdź właściwy serwer i nagłówek Authorization: Bearer, spację oraz aktualny token. Po rotacji poprzedni nie działa. W razie utraty tokenu wróć do panelu online i wykonaj rotację. Nie wklejaj tokenu do zgłoszenia błędu.

429 — limit to 30 importów/min/token. Odczekaj co najmniej minutę przed ponowieniem; nie uruchamiaj pętli ani automatyzacji.

Błąd walidacji (422) — zastąp wszystkie placeholdery. Sprawdź version = 1, Array/Dictionary, Number zamiast tekstu, unit = kg, method = manual_verified_total i brak dodatkowych pól. Masa 1–500 kg, kroki całkowite 0–100000, źródło 1–100 znaków. Data masy wymaga offsetu; daty od 2000-01-01, nie przyszłe (API dopuszcza do 5 minut tolerancji dla czasu masy). Dzień kroków licz w Europe/Warsaw, jeden wynik na dzień w żądaniu. Obie listy nie mogą być puste.

Za duże żądanie (413) — zmniejsz listę: maksymalnie 100 elementów łącznie i 64 KiB.

Brak próbki / odmowa odczytu Zdrowia — sprawdź dostęp Skrótu do odczytu masy, zakres dat i czy aplikacja wagi zapisuje do Zdrowia. FitBirek nie łączy się bezpośrednio z wagą. Anuluj bez wysyłania zera.

Brak sieci / nieznany status — instrukcja działa offline, lecz token i import wymagają połączenia. Po odzyskaniu sieci odśwież status. Jeśli odpowiedź generowania tokenu zaginęła, wykonaj rotację. Jeśli import był udany, a danych nie widać, sprawdź konto, wersję PWA i synchronizację; pierwszy odczyt dużej historii może potrwać dłużej.''',
                  ),
                  const _Section(
                    '8. Prywatność i ograniczenia',
                    '''PWA nie ma dostępu do HealthKit. Odczyt wykonuje ręcznie uruchamiany Skrót na iPhone. Kierunek jest tylko do FitBirek — nic nie zapisujemy do Apple Zdrowie.

Czas, masa, źródło oraz dzień i liczba kroków są przesyłane przez HTTPS na VPS FitBirek i synchronizowane na zalogowane urządzenia. Po opuszczeniu Apple nie zachowują ochrony end-to-end iCloud. Backup serwera może zawierać te dane, a eksport aplikacji jest osobnym plikiem użytkownika.

Przywrócenie kopii aplikacji nie tworzy nowych importów ani nie usuwa istniejących próbek lub oczekujących usunięć. Na nowym urządzeniu historię zdrowia pobierzesz przez synchronizację właściwego konta. Token nie jest częścią kopii.

Nie ma gotowego pliku .shortcut ani linku iCloud. Test odczytu i wysyłania na rzeczywistym iPhone pozostaje do wykonania na izolowanym środowisku testowym. Testy API i widgetów nie potwierdzają działania na iPhone.''',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

const healthExampleJson = '''{
  "version": 1,
  "weights": [
    {
      "measuredAt": "<CZAS_PROBKI_ISO_8601>",
      "value": 80.5,
      "unit": "kg",
      "source": "<NAZWA_ZRODLA>"
    }
  ],
  "steps": [
    {
      "day": "<DZIEN_YYYY-MM-DD>",
      "value": 7500,
      "method": "manual_verified_total"
    }
  ]
}''';
