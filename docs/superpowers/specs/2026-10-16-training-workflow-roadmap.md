# Kolejne usprawnienia — zatwierdzona kolejność

Użytkownik zaakceptował wszystkie propozycje i realizację po kolei.
Etap0: katalog363/filtry/tracking wydano jako1.12.0+25.
Kolejne etapy są oddzielnie testowane i integrowane, bez karate, zmianID,
zależności ani nadpisywania istniejącej historii.

1. **PR per strona.** Addytywny nullable side w PersonalRecords, Drift8→9.
   NULL oznacza historyczne niesklasyfikowane, nigdy nie utożsamiać zboth.
   PR/ostatnia seria/historyczne listy rozdzielone poexerciseID+side; wire
   opcjonalne side left/right/both. Wzór Epley tylko ciężar+powtórzenia,
   nie stosować do sekund/masy własnej. W UI porównania zostatnią serią
   tej samejstrony (kg/reps/sekundy odpowiednio), bez diagnoz asymetrii.
   Zachować backup/sync i immutableattemptedpayloads.
2. **Zapisane filtry.** Nazwane zestawy kryteriów, nie kopie wyników aniID.
   Trwałe na urządzeniu, account-scoped; poprawne po restarcie i aktualizacji
   katalogu. Korzystać z istniejącego shared_preferences; bez nowej encji
   sync. Zapisywanie/wczytanie/usunięcie, walidacja nazwy, wersjonowanyJSON.
3. **Interwały.** Deterministyczna maszyna stanów przygotowanie/praca/przerwa/
   zakończenie, monotoniczny upływ czasu, pauza/wznowienie/pomiń/anuluj.
   Liczbarund/sekundypracy/przerwy konfiguracja. Sygnał dostępnywramach
   istniejącychzależności i politykibrowseraudio; brakfałszywejgwarancji
   powiadomień wtle. Seria zapisana tylko raz i po jawnejakcji użytkownika.
4. **Generator zfiltrów.** Wejściem jest bieżący zbiór kandydatów po filtrach
   i pełne wymagania posiadanegosprzętu. Sekcje rozgrzewka/praca/schłodzenie,
   czas pracy+przerw+przejść. Dobór różnychwzorców i mięśni; brak arbitralnego
   wypełniania ćwiczeniami spoza filtrów gdy brak kandydatów. Wymiana jednego
   ćwiczenia zachowuje inne. Zapis/uruchomienieplanu poprzez istniejącerepo.
5. **Warunki.** Jawne metadane bez skoków/cichy trening/bezklęku/bezpodporu
   nadłoniach/bezschodzenia napodłogę/małomiejsca oraz siedząco/stojąco/
   napodłodze. Wiele wymagań typu 'bez' działaAND, nieOR. Nie klasyfikować
   jako 'bezpiecznedlaczegoś' ani rekomendować rehabilitacji. Źródła/indeks
   offline aktualizowaneodtwarzalnie; fasety/ulubione/query współdziałają.
6. **Progresjastałegociężaru.** Deterministyczne propozycje najbliższej
   sesji perexercise+side na podstawie wiarygodnej historii/RPE, nie AI
   autowrite. Brak zwiększania kg dla sandbaga20kg. Najpierwpowtórzenia
   wustalonymzakresie/czas, ewentualnie utrzymaj/regresja; trudniejszywariant
   lubpauzawymagają jawnejdecyzji. Brak diagnoz i sugestiizwiększania bólu.
   Nie utożsamiać długa praktyka karate zpoziomem wkażdym ruchu.

Weryfikacja: focusedtest każdegoetapu; końcowo pełnyFlutteranalyze/test,
backendpytestprzyzmianiewire, pipelinePythonprzyzmianiemetadanych,
backup/reopen/sync/migracje. Produkcyjnyrelease kolejnychetapów dopiero po
weryfikacji; konfiginfrastruktury/sekrety bez zmian.
