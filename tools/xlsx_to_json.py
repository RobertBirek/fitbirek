#!/usr/bin/env python3
"""
xlsx_to_json.py - Konwerter prawdziwej bazy ćwiczeń (Excel) do JSON zgodnego
z modelem Freezed `Exercise` (lib/core/models/exercise.dart).

Autor bazy źródłowej: Robert Birek (2026-08-08), 316 ręcznie kuratorowanych
ćwiczeń domowych z realnymi źródłami wiedzy (Athlean-X, Muscle & Strength,
Healthline, Harvard Health, GMB Fitness, Calisthenics Family, ChairTaiChi.org,
Peloton, Cleveland Clinic, AAOS OrthoInfo, Barbend).

Zastępuje syntetyczną bazę wygenerowaną przez scripts/generate_exercises.py.

WEJŚCIE:  tools/source_data/baza_cwiczen_316.xlsx, zakładka BAZA_GLOWNA
          (jedyna istotna z 12 zakładek - pozostałe to podziały tematyczne
          i README, nieużywane przy imporcie)
WYJŚCIE:  assets/data/exercises.json (316 pozycji, id w formacie cwNNN)

Kluczowe decyzje projektowe (patrz CHANGELOG.md [0.8.0] po uzasadnienie):

1. `typ` - Excel ma 10 wartości (Hipertrofia, Siła, Wytrzymałość, Cardio,
   Rozgrzewka, Regeneracja, Explosive, Rozciąganie, Izometria, Mobilność).
   Poprzedni enum aplikacji miał tylko 4. ROZSZERZAMY AppConstants.typyOpcje
   do 10 wartości Excela 1:1 (żadnego mapowania/utraty informacji), ale
   POPRAWIAMY nazwę 'Izometria' (nie 'Izometryczne') w
   active_session_page.dart, bo to od niej zależy przełączenie UI na stoper.

2. `partiaGlowna` - Excel ma ~163 granularne wartości (np. 'Latissimus
   dorsi', 'Kwadryceps, Pośladki'). ZACHOWUJEMY oryginalną, bogatą wartość
   1:1 w tym polu (więcej informacji w szczegółach ćwiczenia), a osobna
   funkcja pomocnicza `mapToKategoria()` (lib/core/utils/partia_kategoria.dart)
   redukuje ją do 10 prostych kategorii UI (Klatka/Plecy/Barki/Biceps/
   Triceps/Nogi/Pośladki/Brzuch/Cardio/Mobilność) używanych przez filtry
   i PlanGenerator. Brak zmian w schemacie Drift/Freezed - brak migracji.

3. `sprzet` - Excel ma złożone/warunkowe stringi ('Drążek lub Masa własna',
   'Guma opcjonalnie', formy singularne 'Hantel'/'Ławka'). NORMALIZUJEMY:
   - "X lub Y" -> bierzemy X (łatwiejszy/podstawowy wariant)
   - "X/Y" -> bierzemy X
   - "X opcjonalnie" -> pomijamy (sprzęt nieobowiązkowy)
   - synonimy -> kanoniczna nazwa (Hantel->Hantle, Ławka/Ławka skośna->Ławeczka,
     Guma/Guma oporowa->Gumy oporowe)
   - nowe typy sprzętu (Krzesło, Ręcznik) - DODANE do
     AppConstants.dostepnySprzetOpcje (patrz zmiany w lib/app/constants.dart)

4. Pola z separatorami: Partie_wspierajace (przecinki), Kluczowe_wskazowki
   i Czeste_bledy (średniki) -> rozbite na List<String> w JSON, każdy
   fragment .strip()owany.

5. `id` - Excel ma int 1-316. Model Freezed/Drift TextColumn oczekuje
   string. Zachowujemy istniejącą konwencję `cwNNN` (zero-padded do 3
   cyfr) dla zgodności z resztą architektury (Drift primary key, testy
   regex ^cw\\d{3}$).

6. `ulubione` - brak w Excelu (to pole stanu użytkownika, nie metadanych
   ćwiczenia) -> zawsze `False` przy imporcie (użytkownik ustawia sam).

Użycie:
    python3 tools/xlsx_to_json.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("BŁĄD: brak biblioteki openpyxl. Zainstaluj: pip install openpyxl")
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
XLSX_PATH = ROOT / "tools" / "source_data" / "baza_cwiczen_316.xlsx"
OUTPUT_PATH = ROOT / "assets" / "data" / "exercises.json"
SHEET_NAME = "BAZA_GLOWNA"

EXPECTED_HEADER = [
    "ID",
    "Nazwa_PL",
    "Nazwa_EN",
    "Partia_glowna",
    "Partie_wspierajace",
    "Sprzet",
    "Typ",
    "Poziom",
    "Wzorzec_ruchu",
    "Serie_x_Powtorzenia",
    "Tempo",
    "Kluczowe_wskazowki",
    "Czeste_bledy",
    "Progresja",
    "Regresja",
    "Zrodlo",
]

# --- Normalizacja nazw sprzętu -> kanoniczne wartości używane w aplikacji ---
SPRZET_ALIASY = {
    "Hantel": "Hantle",
    "Hantle (z linką na sznurku)": "Hantle",
    "Ławka": "Ławeczka",
    "Ławka skośna": "Ławeczka",
    "Guma": "Gumy oporowe",
    "Guma oporowa": "Gumy oporowe",
}

# Kanoniczna, rozszerzona lista sprzętu (musi być zgodna z
# lib/app/constants.dart -> AppConstants.dostepnySprzetOpcje po aktualizacji).
VALID_SPRZET = {
    "Masa własna",
    "Hantle",
    "Ławeczka",
    "Drążek",
    "Gumy oporowe",
    "Bieżnia",
    "Skakanka",
    "Krzesło",
    "Ręcznik",
}

# Rozszerzony enum typów - 1:1 z wartościami z Excela (musi być zgodny z
# lib/app/constants.dart -> AppConstants.typyOpcje po aktualizacji).
VALID_TYP = {
    "Hipertrofia",
    "Siła",
    "Wytrzymałość",
    "Cardio",
    "Rozgrzewka",
    "Regeneracja",
    "Explosive",
    "Rozciąganie",
    "Izometria",
    "Mobilność",
}

VALID_POZIOM = {"Początkujący", "Średni", "Zaawansowany"}


def normalize_sprzet(raw: str) -> list[str]:
    """Rozbija i normalizuje pole Sprzet do listy kanonicznych tokenów.

    Przykłady:
        "Masa własna" -> ["Masa własna"]
        "Hantel, Ławka" -> ["Hantle", "Ławeczka"]
        "Drążek lub Masa własna" -> ["Drążek"]  (bierzemy pierwszy wariant)
        "Masa własna, Guma opcjonalnie" -> ["Masa własna"]  (opcjonalny odpada)
        "Masa własna, Guma/Drążek" -> ["Masa własna", "Gumy oporowe"]
    """
    tokens = [t.strip() for t in raw.split(",")]
    result: list[str] = []
    for token in tokens:
        if not token:
            continue
        if "opcjonalnie" in token.lower():
            # Sprzęt nieobowiązkowy - nie wymagamy go, pomijamy z listy
            # wymaganego sprzętu (ćwiczenie da się wykonać bez niego).
            continue
        if " lub " in token:
            token = token.split(" lub ")[0].strip()
        if "/" in token:
            token = token.split("/")[0].strip()
        token = SPRZET_ALIASY.get(token, token)
        if token not in VALID_SPRZET:
            raise ValueError(f"Nieznany token sprzętu po normalizacji: {token!r} (z {raw!r})")
        if token not in result:
            result.append(token)
    return result or ["Masa własna"]


def split_semicolon(raw: str) -> list[str]:
    return [x.strip() for x in raw.split(";") if x.strip()]


def split_comma(raw: str) -> list[str]:
    return [x.strip() for x in raw.split(",") if x.strip()]


def convert() -> list[dict]:
    if not XLSX_PATH.exists():
        raise FileNotFoundError(f"Nie znaleziono pliku źródłowego: {XLSX_PATH}")

    wb = openpyxl.load_workbook(XLSX_PATH, data_only=True)
    if SHEET_NAME not in wb.sheetnames:
        raise ValueError(f"Zakładka {SHEET_NAME!r} nie istnieje. Dostępne: {wb.sheetnames}")
    ws = wb[SHEET_NAME]

    header = [c.value for c in next(ws.iter_rows(min_row=1, max_row=1))]
    if header != EXPECTED_HEADER:
        raise ValueError(
            f"Nagłówek zakładki BAZA_GLOWNA nie zgadza się z oczekiwanym.\n"
            f"Oczekiwano: {EXPECTED_HEADER}\nOtrzymano:  {header}"
        )
    idx = {h: i for i, h in enumerate(header)}

    rows = list(ws.iter_rows(min_row=2, values_only=True))
    # Odfiltruj ewentualne całkowicie puste wiersze na końcu zakresu.
    rows = [r for r in rows if r[idx["ID"]] is not None]

    result: list[dict] = []
    seen_ids: set[int] = set()

    for r in rows:
        excel_id = r[idx["ID"]]
        if not isinstance(excel_id, int):
            raise ValueError(f"ID musi być liczbą całkowitą, otrzymano: {excel_id!r}")
        if excel_id in seen_ids:
            raise ValueError(f"Zduplikowane ID w Excelu: {excel_id}")
        seen_ids.add(excel_id)

        typ = r[idx["Typ"]]
        poziom = r[idx["Poziom"]]
        if typ not in VALID_TYP:
            raise ValueError(f"Nieznana wartość Typ: {typ!r} (ID={excel_id})")
        if poziom not in VALID_POZIOM:
            raise ValueError(f"Nieznana wartość Poziom: {poziom!r} (ID={excel_id})")

        entry = {
            "id": f"cw{excel_id:03d}",
            "nazwaPl": str(r[idx["Nazwa_PL"]]).strip(),
            "nazwaEn": str(r[idx["Nazwa_EN"]]).strip(),
            "partiaGlowna": str(r[idx["Partia_glowna"]]).strip(),
            "partieWspierajace": split_comma(str(r[idx["Partie_wspierajace"]])),
            "sprzet": normalize_sprzet(str(r[idx["Sprzet"]])),
            "typ": typ,
            "poziom": poziom,
            "wzorzecRuchu": str(r[idx["Wzorzec_ruchu"]]).strip(),
            "seriexPowtorzenia": str(r[idx["Serie_x_Powtorzenia"]]).strip(),
            "tempo": str(r[idx["Tempo"]]).strip(),
            "kluczoweWskazowki": split_semicolon(str(r[idx["Kluczowe_wskazowki"]])),
            "czesteBledy": split_semicolon(str(r[idx["Czeste_bledy"]])),
            "progresja": str(r[idx["Progresja"]]).strip(),
            "regresja": str(r[idx["Regresja"]]).strip(),
            "zrodlo": str(r[idx["Zrodlo"]]).strip(),
            "ulubione": False,
        }
        result.append(entry)

    result.sort(key=lambda e: e["id"])

    # --- Walidacje końcowe całego zbioru ---
    if len(result) != 316:
        raise ValueError(f"Oczekiwano 316 pozycji, otrzymano {len(result)}")

    ids = [e["id"] for e in result]
    if len(set(ids)) != len(ids):
        raise ValueError("Zduplikowane id po konwersji!")
    import re

    for eid in ids:
        if not re.match(r"^cw\d{3}$", eid):
            raise ValueError(f"Nieprawidłowy format id: {eid}")

    return result


def main() -> None:
    print(f"Wczytywanie: {XLSX_PATH}")
    data = convert()
    print(f"Skonwertowano {len(data)} ćwiczeń.")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Zapisano: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
