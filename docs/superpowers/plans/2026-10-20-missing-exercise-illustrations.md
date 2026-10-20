# Uzupełnienie ilustracji cw370–cw408

Polecenie: sprawdzić ćwiczenia bez ilustracji i wygenerować brakujące grafiki.
Zakres: dotychczasowy styl ilustracji, bez zmiany katalogu, ID i produkcji.

## Audyt wejściowy

- 408 ćwiczeń, 369 poprawnie dekodowanych ilustracji 512×512 WebP.
- Brakujące: cw370–cw408, w tym 23 indywidualne i 16 partnerskich.
- Nowe pliki wymagają jawnego dodania do rejestru ilustracji aplikacji.

## Prace

- [x] Sprawdzić katalog, pokrycie plikami i powiązania w UI.
- [x] Wygenerować i obejrzeć każdą brakującą ilustrację zgodnie z instrukcją ćwiczenia.
- [x] Dodać zaakceptowane WebP 512×512 bez modyfikowania starych ilustracji.
- [x] Rozszerzyć rejestr i testy do 408 pozycji z zachowaniem fallbacku dla nieznanych ID.
- [x] Uzupełnić raport źródeł, korekt i kosztów oraz stan ilustracji.
- [x] Sprawdzić równość ID katalog/rejestr/test/assety, dekodowanie i niezmienność starych plików.
- [x] Uruchomić analizę, testy oraz niezależny przegląd zmian.

Generowanie przez istniejący skrypt wykonuje pojedyncze żądania, z kontrolą
wyniku przed kolejnym. Przy błędzie nie ponawiać automatycznie niepewnego
żądania. Klucze pozostają poza repozytorium i logami. Zadania generowania
obrazów i integracji rejestru są rozdzielone; końcowa weryfikacja następuje po
obu. Nie wykonywać commita, pusha ani wdrożenia w ramach tego polecenia.
