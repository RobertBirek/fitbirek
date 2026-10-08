# Working set: Śledzenie postępów

## Odpowiedzialność

Ręczne pomiary, testy sprawności, nastrój, wykresy oraz import Apple Health.

## Czytaj najpierw

- `lib/features/progress/**`
- `lib/features/mood/**`
- `lib/features/health/**`
- `docs/apple-health-contract.md`
- testy progress, mood i health

## Granice

- Apple Health jest danymi właścicielskimi serwera; klient nie tworzy ani nie odradza rekordów importu.
- Nie łącz automatycznie źródeł masy bez jawnej reguły i testu.
- Zmiana wire payloadów wymaga też working setu synchronizacji.
