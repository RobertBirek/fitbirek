# Guided Training Implementation Plan

**Goal:** sześć zatwierdzonych usprawnień plus kolekcja kręgosłupa.
**Architecture:** strukturalne cele/zdarzenia sesji, lokalne trwałe szkice,
profile extensions dla kolekcji użytkownika, kompatybilne optional pola.
**Tech Stack:** Flutter3.35.4/Dart3.9.2/Drift/Riverpod, FastAPI/JSONB, XLSX.

- [x] Sprawdzić baseline6f3eb79, zapisać projekt i kontrakty etapów.
- [x] Dane kręgosłupa: audyt źródeł i duplikatów, noweID/XLSXeksport,
  odtwarzalne metadane/warunki/kolekcja spine i pipeline testy.
- [x] Wyjaśnienia wyboru i zamiany: czysta logika/testy z realnych kryteriów,
  prezentacja bez płatnegoAI i bez nieprawdziwych gwarancji.
- [x] Backend: backwards-compatible omissionmerge znanych rozszerzeń,
  testy niezmiennościhash/retry/CAS/isolation/tombstones.
- [x] Guided/resume/summary: migracja11, snapshot sesji i szkic konta,
  ręczne wykonanie/pomiń/zamień, przywrócenie bez zaliczania downtime.
- [x] Warianty/cloudpresets: migracja12, utrwalenie własnych parametrów,
  pervariant historia/PR, profile collections i konflikt/restart/restoretesty.
- [x] Obrazy nowych ćwiczeń i pełny audyt ID/źródeł/indexu.
- [x] Niezależne review i naprawy, pełny Flutter/backend/pipeline,
  wygenerowane pliki, format i raport końcowy zakresu/ograniczeń.

## Zamknięcie implementacji — 2026-10-17

- Release candidate 1.14.0+27: Flutter 683 testy, analiza bez problemów,
  17 plików generowanych bez różnic po ponownym build_runner.
- Backend 373 testy; pipeline katalogu 45 testów. Katalog 369 ćwiczeń,
  19 spine, sześć nowych ilustracji; stare 363 rekordy i obrazy zachowane.
- [Guided, wznowienie i timer](../../guided-browser-acceptance-2026-10-17-fixed.md).
- [Fonty offline i znany warning silnika VS16](../../guided-browser-acceptance-2026-10-17-fonts.md).
- [Dwa klienty z rzeczywistym API, migracja, trzy konflikty CAS i tombstone'y](../../cloud-browser-acceptance-2026-10-17.md).
- Review bez pozostałych HIGH/MEDIUM. Izolacja dwóch różnych kont i fizyczne
  urządzenia/PWA pozostają poza wykonaną akceptacją; raporty nie zaliczają ich
  na podstawie testów dwóch klientów tego samego konta.
- Wdrożenie jest osobnym etapem: API z ochroną omission przed nowym webem,
  backup, restore drill i weryfikacja produkcyjna według `DEPLOY.md`.
