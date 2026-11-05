# Szkic deklaracji Bezpieczeństwo danych — 1.3.0

Wariant z klasycznym Google Mobile Ads **24.9.0 / Poing 4.3.1 / UMP 4.0.0**. APK testowy korzysta z oficjalnych jednostek demonstracyjnych; docelowi odbiorcy to dzieci od 3 lat i dorośli. [Stan reklam](ADS-1.3.md).

To materiał do wypełnienia formularza, nie automatyczna deklaracja zgodności. Potwierdź aktualne definicje Play i dokumentację dołączonej wersji SDK. Nie zaznaczaj „brak zbierania danych” tylko dlatego, że wyniki gry są offline.

| Element | Stan aplikacji / co sprawdzić |
|---|---|
| Konto gracza | Brak rejestracji i logowania; nie ma serwera kont ani formularza usunięcia konta. |
| Wyniki, monety, motywy, wyzwania | Lokalny JSON na urządzeniu. Aplikacja nie wysyła ich na serwer gry. Czyszczenie danych aplikacji usuwa postęp. |
| Identyfikatory urządzenia/reklam | Usunięto uprawnienia AD_ID, telefonu i reklamowe Privacy Sandbox. To nie jest deklaracja braku wszystkich identyfikatorów technicznych SDK; potwierdź zakres w aktualnej dokumentacji Google. |
| Przybliżona lokalizacja/IP | SDK może przetwarzać adres IP i wnioskować lokalizację; brak uprawnienia GPS nie oznacza automatycznie braku danych lokalizacyjnych. |
| Interakcje z aplikacją/reklamą | SDK reklam może raportować wyświetlenia i interakcje. Celem jest obsługa reklam, pomiar i zapobieganie nadużyciom według dokumentacji Google. |
| Diagnostyka / awarie / wydajność | Zależności Google mogą je przetwarzać. Zweryfikuj zakres oraz ewentualne ustawienia wyłączenia przed deklaracją. |
| Udostępnianie / role dostawców | Nie utożsamiaj każdego dostawcy automatycznie z wyjątkiem „service provider”. Sprawdź definicje i warunki Google dla tego SDK. |
| Szyfrowanie transmisji | Gra nie ma własnych żądań API. Sprawdź deklarację Google dla całego ruchu SDK; nie zgaduj odpowiedzi za zewnętrzne biblioteki. |
| Zgody i opcjonalność | W produkcji UMP under-age przed żądaniem reklam; testowe ID bez formularza dla dorosłych. Rewarded dobrowolne, osobna korzyść pokazana wcześniej; odmowa nie blokuje gry. Interstitial ograniczone i między rozgrywkami. |
| Dzieci / Families | Dzieci od 3 lat i dorośli, jednolity profil child-directed/under-age/G/npa. Bieżąca certyfikacja dokładnej wersji SDK wymaga potwierdzenia; nie zadeklarowano zatwierdzenia Play. |
| Zakupy | Nie są zaimplementowane. Neon Coins nie mają wartości pieniężnej i nie są wymienialne. |


Bieżący manifest ma Internet i metadane SDK; AD_ID, uprawnienia telefonu i reklamowe Privacy Sandbox są usunięte. Sprawdź manifest po aktualizacji biblioteki. Brak tych uprawnień nie oznacza, że Google nie przetwarza IP, diagnostyki lub interakcji z reklamą.

Źródła do aktualnego sprawdzenia:

- https://developers.google.com/admob/android/privacy/play-data-disclosure
- https://developers.google.com/admob/android/privacy
- https://support.google.com/googleplay/android-developer/answer/10787469

Pozostają: publiczny URL polityki, konfiguracja konta AdMob/UMP, potwierdzenie Families dla dokładnej wersji SDK, analiza deklaracji dostawcy i wpisanie formularza w Play Console. Walidacja AAB ich nie potwierdza.
