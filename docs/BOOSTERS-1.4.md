# 1.4.0 — pomocniki i ładowanie reklam

## Nagrody użyteczne podczas gry

Jedna ukończona reklama z nagrodą daje **1 Młotek i 2 Zmiany**. Pakiet trafia do lokalnego plecaka wyłącznie po earned-reward SDK; samo kliknięcie, błąd lub zamknięcie reklamy nie daje nagrody. Powtórzony callback nie wypłaca drugiego pakietu. Monety i pomocniki nie mają wartości pieniężnej.

- **Młotek:** dotknij i puść wybrany obszar, aby usunąć do 9 zajętych pól (3×3, przy krawędzi mniej). W trakcie wskazywania widać podgląd; ponowne wybranie Młotka lub Wstecz anuluje. Pusty cel nie zużywa ładunku. Nie dodaje sztucznych punktów.
- **Zmiana:** nowy zestaw trzech figur bez zmiany planszy, wyniku i pozostałego czasu. Przy wolnym miejscu co najmniej jedna nowa figura pasuje.
- Pakiet startowy **1 + 2 gratis**, także po aktualizacji starego zapisu. Kolejny pakiet można kupić za **90 monet zdobytych w grze**, bez reklam. Użycie pomocnika i stan planszy są zapisywane razem; błąd zapisu cofa zużycie.
- Przyciski pod planszą i osobny ekran POMOCNIKI w menu. Przy braku ruchów można wybrać pomocnika lub zakończyć grę. Koniec nie jest naliczany przed wyborem gracza.
- Classic i Time Attack. Daily nie dopuszcza pomocników, aby zachować ten sam deterministyczny układ dla wszystkich.

PLASMA pozostaje dodatkowym motywem kosmetycznym w sklepie. Główna oferta z nagrodą prowadzi teraz do pakietu ratunkowego.

## Reklamy

W 1.3 inicjalizacja była wywoływana przed podłączeniem sygnału odpowiedzi. Szybki lub powtórny callback SDK mógł zginąć, pozostawiając adapter bez ładowania reklam. Zmieniono kolejność; test z natychmiastową odpowiedzią natywnego mostka przechodzi.

Rozwiązywanie natywnych singletonów odbywa się ponownie przy inicjalizacji, po pierwszej klatce gry. W wariancie testowym nie wymagamy nieużywanego modułu UMP do załadowania reklam demonstracyjnych. Produkcja nadal wymaga UMP i zachowuje zamknięcie reklam przy błędzie/nieustalonym wymogu zgody.

Inicjalizacja ma limit 45 s, pobranie 75 s i ponawianie. Przeterminowane odpowiedzi nie nadpisują aktualnego żądania. Ekran **Status reklam / Ponów** pokazuje etapy i rzeczywisty kod, domenę oraz komunikat błędu SDK, zamiast samego „niedostępna”. Nie pokazujemy pozorowanej reklamy ani nagrody bez earned-reward.

Naprawiono także czas życia loaderów GDScript: normalna referencja do oczekującego żądania zastępuje ręczne reference/unreference. Test sprawdza zwolnienie po odpowiedzi; nie ma ostrzeżeń o wycieku na końcu aktualnego zestawu testów.

APK używa **oficjalnych jednostek testowych Google**, nie zarabia. Prawdziwe ID właściciela pozostają w konfiguracji przyszłego wydania produkcyjnego. Profil dla wszystkich: child-directed/under-age/G/npa=1. Nie zmieniono odbiorców: dzieci od 3 lat i dorośli.

## Weryfikacja i granice

**2760 sprawdzeń Godot i 18 testów Python zaliczonych**. Obejmują migrację, atomowy zapis, dwukrotne earned-reward, brak nagrody za sam przycisk, dotyk Młotka, pełny przepływ pakietu, ratunek przy braku ruchów, blokadę Daily, szybką inicjalizację SDK, błędy i spóźnione odpowiedzi. Kontrola renderera: 7 zrzutów 720×1280 i dopasowanie 360×640, 1080×1920, 720×1600.

Właściciel potwierdził, że poprzednia paczka z osobnym launcherem uruchamia grę na jego Samsungu. Zachowano tę ścieżkę w debug APK oraz lokalny raport awarii. Nie potwierdzono jeszcze wyświetlenia reklamy 1.4 na fizycznym telefonie. Testy mostka nie są dowodem emisji ani zarobku. Jeżeli SDK odmówi ładowania, ekran statusu zawiera teraz szczegóły potrzebne do rozpoznania powodu.

Do produkcji nadal potrzebne są: aktualna weryfikacja Families dla dokładnej wersji SDK, publiczna polityka/strona, konfiguracja konta AdMob/UMP, własny podpis i deklaracje Play. Nie są zastępowane tą aktualizacją.
