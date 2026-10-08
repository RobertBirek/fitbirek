# Working set: Mentor

## Odpowiedzialność

Prywatny Mentor, szyfrowane klucze dostawców, zgody, ograniczony kontekst treningowy, idempotencja operacji i UI rozmowy.

## Czytaj najpierw

- `docs/mentor.md`
- `backend/app/mentor/{router,service,context,schemas,models,catalog,vendor,audio,middleware}.py`
- `lib/features/mentor/**`
- `backend/tests/test_mentor*.py`
- `test/features/mentor/**`

## Granice

- Nie zapisuj persony, zgód, podglądu kontekstu ani selektorów do Drift, outboxa, eksportu lub SharedPreferences.
- Dane do dostawcy AI buduje wyłącznie backend z rekordów zsynchronizowanych.
- Klient nie wysyła wartości zdrowotnych ani notatek; przesyła jedynie zatwierdzone selektory.
- Zmiany sekretów, klucza głównego i wdrożenia wymagają `DEPLOY.md` oraz `deploy/compose.mentor.yaml`.
