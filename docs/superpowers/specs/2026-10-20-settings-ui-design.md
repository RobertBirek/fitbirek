# Ustawienia — kompaktowy panel FitBirek

## Zakres zatwierdzony w rozmowie

Użytkownik zlecił poprawę UI /#/settings, przyjął rekomendacje i zatwierdził
projekt oraz implementację. Bez ponownego projektowania reszty aplikacji.
Główny ekran przestaje być jedną długą listą: kompaktowa synchronizacja na
górze, wyróżniony harmonogram, grupy trening/profil, aplikacja i dane/integracje,
o aplikacji i wylogowanie na dole. Powiadomienia i kopia zapasowa osobno.

## Projekt

- FitBirek zachowuje grafit/pomarańcz, lokalny Inter i istniejący jasny motyw.
  Dark: tło#1A1D23, surface#23262E, border#3B414C, główny tekst#F5F6F8,
  pomocniczy#B8C0CC, akcent#FF6B35. Light: semantyczne scheme tła/tekstu,
  pomarańcz jako znacznik, bez białego drobnego tekstu na pomarańczu.
- Inter ExtraBold nagłówek, SemiBold sekcje/pozycje, Regular opisy. Bez nowych
  fontów sieciowych, zależności, hero, gradientów ani dekoracyjnej animacji.
- Jedyny mocny element: kafel Harmonogram aktywności z pionowym akcentem
  pomarańczowym przypominającym znacznik w planerze. Nie tworzyć fałszywych
  liczników/terminów; opis „Dni, godziny, treningi i przypomnienia”.
- Maksymalna szerokość treści960px, wyśrodkowana. Powyżej dostępnych760px dwie
  kolumny „Trening i profil” / „Aplikacja”, poniżej jedna. Przy text200% wrócić
  do jednej kolumny, kontrolki zawijają się bez przepełnienia.
- Spacing: content16mobile/24desktop; sekcje24; nagłówki12dozawartości;
  karty borderRadius16 z delikatnym border i bez cieni; interaktywne cele>=48px.
- Przyciski/chevrony blisko tekstu, nie na drugim końcu całego monitora.
  Widoczne keyboardfocus/hover; kolejność semantyczna zgodna z odczytem.

## Informacja i nawigacja

1. Synchronizacja: stan i pending, odświeżenie; szczegóły długiego błędu/hold
   zachowane i dostępne, nie zamienione na „gotowe”. Wylogowanie poza tym kaflem.
2. Harmonogram → istniejące /settings/activities.
3. Trening i profil: Edytuj profil, Generator planu treningowego, Kalkulator
   kalorii/makro, Mentor treningowy — istniejące ścieżki/nazwy zgodne testom.
4. Aplikacja: Motyw (dropdown/formfield wewnątrz szerokości), Dźwięk gongu,
   Wibracje, Powiadomienia → nowa /settings/notifications.
5. Dane i integracje: Tryb offline (obecny widget), Kopia zapasowa i
   przywracanie → /settings/backup, Apple Zdrowie → /settings/health.
6. AppInfoTile z rzeczywistą wersją; Wyloguj z istniejącym callbackiem,
   bez zmiany polityki danych/konta.

Ekran powiadomień ma ograniczoną szerokość, status PWA/native, kategorie i akcje,
stan migracji/7-dniowy native horizon. Instrukcje platformy rozwijane ręcznie
lub pokazane jeśli needsInstall, nie całe na głównej stronie. Prawdziwe statusy
z providerów, bez pobierania prywatnych danych ponownie w samych summarykaflach.
Nie wolno wywołać permissionRequest automatycznie przy wejściu na stronę.
Gesture enable musi nadal wywoływać synchronously oryginalny PushClient.enable.

Backup wyraźnie oddziela eksport od destrukcyjnego importu. Zachować istniejący
warning/picker/share/service/busy/error/cancel i bezpieczeństwo danych.
Nie skracać ostrzeżenia tak, by zniknęło zastępowanie danych lub wyjątek Apple.
Health ekran zawiera istniejący HealthIntegrationTile z ochroną tokenów/zgód;
nie inicjować rotacji/zgody ani utrzymywać sekretu na ekranie głównym.
Podstrony nested settings GoRouter, nie drugi shell; back/deeplink działa.

## Ograniczenia i akceptacja

Flutter3.35.4/Dart3.9.2, bez zmian backendu/Drift13/Alembic0010, dependencies,
Web SQLite, wersji wydania, kluczy i danych. Bez commit/push/deploy bez nowego
polecenia. Nie zmieniać głównych providerów przypomnień/synchronizacji.
Cały refaktor jest prezentacją i przeniesieniem istniejących komponentów.

RED/GREEN realrouter: wszystkie pozycje osiągalne, subpages/back/authredirect,
main short/no nested giant panels, syncconflict readable, busyimport/export
cancel/error no sideeffects, PWA categoryguard and clickgesture zachowane.
320/375/768/1280px, oba motywy, text200%, keyboardfocus i bez overflows.
Pełne analyze/test i rzeczywisty Chromium desktop+mobile z screenshotami
izolowanego kandydata przed zakończeniem; bez logowania/zapisów na produkcji.
