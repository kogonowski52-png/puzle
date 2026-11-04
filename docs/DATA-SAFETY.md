# Szkic deklaracji Bezpieczeństwo danych

**1.2.0:** native SDK reklamowy Google został usunięty z eksportu. Brak Internet/AD_ID w manifeście i brak klas Google Ads w DEX. Gra zapisuje postęp lokalnie, nie ma kont ani własnej analityki i nie pyta o wiek w wariancie bez reklam. Poniższe uwagi o AdMob dotyczą wcześniejszej/przyszłej integracji, nie obecnego artefaktu. Uwzględnij rzeczywisty wariant przy formularzu Play; odwiedzenie publicznej strony w przeglądarce podlega również zasadom jej hostingu.


To materiał do wypełnienia formularza, nie automatyczna deklaracja zgodności. Potwierdź aktualne definicje Play i dokumentację faktycznie dołączonego **Google Next-Gen Mobile Ads SDK 1.4.0 / UMP** przed wysłaniem. Nie zaznaczaj „brak zbierania danych” tylko dlatego, że wyniki gry są offline.

| Element | Stan aplikacji / co sprawdzić |
|---|---|
| Konto gracza | Brak rejestracji i logowania; nie ma serwera kont ani formularza usunięcia konta. |
| Wyniki, monety, motywy, wyzwania | Lokalny JSON na urządzeniu. Aplikacja nie wysyła ich na serwer gry. Czyszczenie danych aplikacji usuwa postęp. |
| Identyfikatory urządzenia/reklam | SDK reklam może je przetwarzać; zadeklaruj zgodnie z dokumentacją Google, faktyczną zgodą i konfiguracją. |
| Przybliżona lokalizacja/IP | SDK może przetwarzać adres IP i wnioskować lokalizację; brak uprawnienia GPS nie oznacza automatycznie braku danych lokalizacyjnych. |
| Interakcje z aplikacją/reklamą | SDK reklam może raportować wyświetlenia i interakcje. Celem jest obsługa reklam, pomiar i zapobieganie nadużyciom według dokumentacji Google. |
| Diagnostyka / awarie / wydajność | Zależności Google mogą je przetwarzać. Zweryfikuj zakres oraz ewentualne ustawienia wyłączenia przed deklaracją. |
| Udostępnianie / role dostawców | Nie utożsamiaj każdego dostawcy automatycznie z wyjątkiem „service provider”. Sprawdź definicje i warunki Google dla tego SDK. |
| Szyfrowanie transmisji | Gra nie ma własnych żądań API. Sprawdź deklarację Google dla całego ruchu SDK; nie zgaduj odpowiedzi za zewnętrzne biblioteki. |
| Zgody i opcjonalność | UMP przed żądaniem reklam. Rewarded dobrowolne, osobna korzyść pokazana wcześniej; odmowa nie blokuje gry. Interstitial ograniczone i między rozgrywkami. |
| Dzieci / Families | Nie zadeklarowano zgodności Families. Pipeline wymaga świadomego wyboru 16+ lub 18+ zgodnego z rzeczywistymi odbiorcami. |
| Zakupy | Nie są zaimplementowane. Neon Coins nie mają wartości pieniężnej i nie są wymienialne. |

Rzeczywisty scalony manifest poprzedniej kompilacji zawierał m.in. Internet, stan sieci, wibracje, AD_ID, READ_BASIC_PHONE_STATE, WAKE_LOCK i FOREGROUND_SERVICE. Sprawdź bieżący manifest po każdej aktualizacji SDK.

Źródła do aktualnego sprawdzenia:
- https://developers.google.com/admob/android/privacy/play-data-disclosure
- https://developers.google.com/admob/android/privacy
- https://support.google.com/googleplay/android-developer/answer/10787469

Stan zadań dla wydawcy: prawdziwy URL polityki, kontakt, wybór grupy, konfiguracja UMP, analiza deklaracji SDK i wpisanie formularza w Play Console. Nie zostały potwierdzone przez samą walidację AAB.
