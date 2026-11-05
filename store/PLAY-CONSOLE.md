# Pola do pierwszego zgłoszenia w Play Console

| Pole | Przygotowana wartość |
|---|---|
| Nazwa aplikacji | Neon Block Master – Puzzle |
| Typ | Gra |
| Kategoria | Łamigłówki / Puzzle |
| Cena | Bezpłatna; brak zakupów w aplikacji |
| Zawiera reklamy | Tak — rewarded i ograniczone interstitiale |
| Wydawca | Krystian Development |
| E-mail wsparcia | kogonowski52@gmail.com |
| Pakiet | com.neonblockmaster.puzzle |
| Wersja AAB | 1.4.1 / code 8 |
| Dostęp do aplikacji | Pełny dostęp bez logowania i bez konta gracza |
| Odbiorcy | Dzieci od 3 lat i dorośli; wybierz odpowiadające im rzeczywiste zakresy wieku w panelu |
| Ocena treści | Wypełnij IARC. „3+” nie jest automatycznie nadaną oceną |
| Witryna | https://kogonowski52-png.github.io/puzle/ — działanie niepotwierdzone |
| Polityka | https://kogonowski52-png.github.io/puzle/privacy.html — działanie niepotwierdzone |

Teksty gotowe do wklejenia: `play-console/pl-PL/` i `play-console/en-US/`; nie zawierają not roboczych dla wydawcy. Ikona, feature graphic i zrzuty są dołączone oddzielnie. Dotychczasowe zrzuty przedstawiają grę; nie stanowią dowodu wyświetlenia reklamy produkcyjnej.

Bezpieczeństwo danych trzeba wypełnić zgodnie z używanym SDK Google, nie jako „brak danych” na podstawie lokalnego zapisu gry. [Szkic deklaracji](../docs/DATA-SAFETY.md). Brak konta gracza oznacza brak funkcji usuwania takiego konta; dane postępu usuwa wyczyszczenie danych aplikacji. Brak GPS lub AD_ID nie oznacza braku przetwarzania IP/diagnostyki przez SDK.

Najpierw utwórz aplikację i test wewnętrzny. Włącz Play App Signing i dodaj dopiero finalny AAB podpisany własnym kluczem upload. Nie wgrywaj debug APK ani niepodpisanego production-candidate. Weryfikacja tożsamości, aktualne wymagania testów i wybór krajów należą do właściciela konta. Ta paczka niczego nie wysyła do Google Play.
