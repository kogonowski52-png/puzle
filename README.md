# Neon Block Master — 1.4.0

**[Pobierz APK 1.4.0](neon-block-master-1.4.0.apk)** → **Download raw**. Zainstaluj aktualizację bez usuwania aplikacji. Code 7, ten sam certyfikat debugowy, zachowane zapisy. Android 7+, ARM64.

## Pomocniki, które pomagają w grze

- **Młotek 3×3:** wybierz obszar, usuń do 9 zajętych pól i zrób miejsce. Pusty cel nie zużywa ładunku.
- **Zmiana:** trzy nowe figury bez kasowania planszy i wyniku.
- **Jedna ukończona reklama = 1 Młotek + 2 Zmiany.** Nagroda wyłącznie z earned-reward SDK, bez losowania.
- **Pakiet startowy gratis**, także po aktualizacji. Ten sam pakiet można kupić za **90 monet zdobytych w grze**.
- Przyciski pod planszą i w menu **POMOCNIKI**. Przy braku ruchów wybierz ratunek lub zakończenie partii. W Daily pomocniki są wyłączone.

PLASMA zostaje dodatkowym kosmetycznym motywem. Główna oferta nagrody prowadzi teraz do pakietu ratunkowego.

## Reklamy

Naprawiono kolejność inicjalizacji: listener jest podłączany **przed** wywołaniem SDK. Test natychmiastowego natywnego callbacku potwierdza, że odpowiedź nie ginie. Dodano ponowne wiązanie singletonów Android, limity czasu, retry, odrzucanie spóźnionych odpowiedzi i prawidłowe zwalnianie loaderów.

Otwórz **POMOCNIKI → Status reklam / Ponów**. Widać stan i rzeczywisty kod/domenę/komunikat błędu SDK, zamiast samego „niedostępna”. Gdy reklama jest gotowa, oferta pakietu uruchamia rzeczywisty SDK.

APK nadal korzysta z **oficjalnych jednostek testowych Google; nie zarabia**. Prawdziwe ID właściciela pozostają zapisane do przyszłej produkcji. Nie potwierdzono jeszcze emisji 1.4 na fizycznym telefonie — testy mostka nie dowodzą wyświetlenia reklamy. Gra zachowuje launcher z ostatniego APK, którego uruchomienie potwierdził właściciel, oraz lokalny raport awarii.

Odbiorcy: dzieci od 3 lat i dorośli. Wszyscy mają child-directed/under-age/G/npa=1; brak AD_ID. Nie zmieniono grupy na starszą.

## Sprawdzenie i pliki

**2760 sprawdzeń Godot i 18 testów Python zaliczonych.** Migracja, zapis planszy z inventory, earned-reward i jego powtórzenie, dotyk Młotka, ratunek z braku ruchów, blokada Daily i błędy SDK. Sprawdzono DEX, manifest, podpis, AAB, 16 KB i zgodność skryptów w paczkach. Render: siedem zrzutów, kontrola kilku proporcji ekranu; brak deklaracji 60 FPS na telefonie.

- [Pełne źródła Godot](neon-block-master-source.zip).
- [Release AAB bez podpisu — konfiguracja testowa](neon-block-master-release-unsigned.aab).
- [Strona i polityka prywatności](neon-block-master-website.zip).
- [Sumy SHA-256](SHA256SUMS.txt).
- [Opis zmian i nagród](docs/BOOSTERS-1.4.md).

Wydawca: **Krystian Development**, **kogonowski52@gmail.com**. Do produkcji pozostają publiczne URL strony/polityki, aktualne potwierdzenie Families dla dokładnej wersji SDK, konfiguracja AdMob/UMP, własny klucz upload i deklaracje Play/IARC. Pliki strony są na `gh-pages`; sam push nie uruchamia hostingu. Nie deklarujemy zatwierdzenia Play ani certyfikacji sprawdzonej w tej sesji.
