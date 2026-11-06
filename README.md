# Neon Block Master 1.4.2 — poprawka reklam, code 9

**[Pobierz paczkę Windows 1.4.2](neon-block-master-1.4.2-windows-signing.zip)** → **Download raw**. Rozpakuj i uruchom `podpisz.cmd`, używając swojego istniejącego klucza upload. Wynik: `wynik/neon-block-master-1.4.2-play-signed.aab`. Zaktualizuj tę samą grę i używaną ścieżkę testową w Google Play. Klucz i hasło pozostają u właściciela; paczka sprawdza zgodność publicznego certyfikatu z poprzednim uploadem.

Naprawiono trzy problemy: brak eksportu wersji pluginu, podłączenie odpowiedzi UMP po żądaniu i podłączenie nagrody po rozpoczęciu pokazywania reklamy. **2798 sprawdzeń źródeł, 2798 sprawdzeń skompilowanych zasobów finalnego AAB, 21 testów Python i 12 testów podpisywania zaliczonych.** Testy z kontrolowanymi callbackami nie są prawdziwymi wyświetleniami Google. [Raport kontroli](docs/ADS-AUDIT-1.4.2.md).

**Zarabianie i rzeczywista emisja nadal nie zostały potwierdzone.** Właściciel nie instalował jeszcze wersji z Play. AAB ma jego produkcyjne ID, ale status AdMob, publiczny app-ads.txt/polityka i aktualna lista Families pozostają do sprawdzenia. Code9 jest niepodpisany do czasu uruchomienia paczki na komputerze właściciela; code8 był już podpisany i wysłany przez właściciela.

## app-ads.txt

Zrzut z AdMob potwierdza treść wpisu, a nie jego publikację. Dla używanego hosta wymagany adres to **https://kogonowski52-png.github.io/app-ads.txt**. Odczyt repozytorium głównej strony zwracał `Repository not found`; nie opublikowano go tam z tego środowiska. [Instrukcja dodania pliku](docs/APP-ADS.md), [gotowy plik](app-ads.txt) i **[cała gotowa strona GitHub](neon-block-master-github-site.zip)** do wgrania w repozytorium strony głównej. Paczka zawiera root app-ads.txt oraz stronę i politykę pod /puzle/.

## Aktualne pliki

- [AAB 1.4.2 z produkcyjnymi ID — unsigned](neon-block-master-1.4.2-production-candidate-unsigned.aab).
- [Źródła](neon-block-master-production-source.zip).
- [Materiały Play Console](neon-block-master-play-console.zip).
- [Strona i polityka](neon-block-master-production-website.zip).
- [Aktualny stan](production-readiness.json), [kontrola AAB](production-artifact-validation.json), [raport reklamy](production-ad-audit.json), [sumy](SHA256SUMS.txt).

Poprzednie pliki i raporty poniżej dotyczą historii przygotowania wersji 1.4.1.

---

# Podpisanie AAB na Windows — pierwszy upload

**[Pobierz paczkę Windows](neon-block-master-windows-signing.zip)** → **Download raw**. Rozpakuj całość i uruchom `podpisz.cmd`. Gdy brakuje JDK, instrukcja podaje instalację Microsoft OpenJDK 21 przez winget. Hasło ustawiasz i potwierdzasz na swoim komputerze. Klucz powstaje w `%USERPROFILE%\NeonBlockMaster-Signing\neon-upload.p12` i nie jest nigdzie wysyłany.

Podpisany AAB powstaje w folderze **wynik**, wraz z publicznym raportem. Zachowaj prywatną kopię klucza i hasła. **Nie wysyłaj klucza ani hasła na czat/GitHub.**

[Dokładna instrukcja Windows i dalsze kroki Play](docs/WINDOWS-PLAY.md). Dziewięć testów podpisywania zaliczono w PowerShell 7.4.6/JDK 21 na Linuksie; nie deklarujemy wykonanego testu natywnego Windows. Sprawdzono rzeczywisty podpis AAB, zachowanie zawartości paczki, ponowne użycie klucza, błędne hasło, potwierdzenie hasła i odrzucenie certyfikatu debugowego. [Raport](windows-signing-tests.json).

Samo podpisanie **nie potwierdza** Families, publicznego hostingu, ustawień kont ani zgody Google. Nie wysłano wydania do Play. Po pozostałych sprawdzeniach zacznij od testu wewnętrznego; wymagania konta i weryfikacja Google mogą uniemożliwić publiczny start tego samego dnia.

---

# Przygotowanie pierwszego wydania Google Play

**Dotychczasowy APK 1.4.1 nadal służy do testów i wyświetla oficjalne reklamy testowe Google.** Poniżej są osobne pliki z prawdziwymi ID właściciela, przygotowane do dalszego podpisania i kontroli przed Play.

- [AAB z produkcyjną konfiguracją — NIEPODPISANY KANDYDAT](neon-block-master-production-candidate-unsigned.aab). **Nie jest gotowy do wgrania do Play.**
- [Materiały Play Console: opisy PL/EN i grafiki](neon-block-master-play-console.zip).
- [Źródła wariantu produkcyjnego i narzędzia podpisywania/kontroli](neon-block-master-production-source.zip).
- [Strona i polityka dla wariantu produkcyjnego](neon-block-master-production-website.zip).
- [Aktualna instrukcja i pozostałe kroki](docs/PRODUCTION-PREP.md).
- [Raport gotowości](production-readiness.json) i [kontrola AAB](production-artifact-validation.json).

Potwierdzono w rzeczywistym AAB tryb production, trzy ID AdMob właściciela, brak debugowego podpisu/launchera, target API 36 i biblioteki 16 KB. 2771 sprawdzeń Godot i 21 testów Python przeszło. **Nie ma jeszcze podpisanego pliku do Play:** brakuje klucza upload, aktualnego sprawdzenia Families, potwierdzenia hostingu oraz ustawień/deklaracji kont. Nic nie wysłano do Play Console. Oczekiwane URL są wpisane w konfiguracji, ale dostęp do nich i do dokumentacji Google jest blokowany przez obecną sieć środowiska. app-ads.txt musi być w głównym katalogu hosta, nie tylko /puzle/.

---

# Neon Block Master — 1.4.1

**[Pobierz APK 1.4.1](neon-block-master-1.4.1.apk)** → **Download raw**. Zainstaluj jako aktualizację, bez usuwania gry. Code 8, ten sam certyfikat debugowy i zachowane zapisy. Android 7+, ARM64.

## WebView i reklamy

Odpowiedź na zgłoszenie `Unable to obtain a JavascriptEngine`: przed uruchomieniem AdMob aplikacja przygotowuje systemowy WebView na wątku UI i sprawdza wykonanie lokalnego JavaScript. Na Androidzie 9+ próbuje też oddzielić profil WebView według procesu. To poprawka sposobu przygotowania oraz diagnostyki; sam ogólny komunikat SDK nie ustala dokładnej przyczyny na telefonie.

W **POMOCNIKI → Status reklam / Ponów** są wersja WebView, wynik JS i pełny błąd SDK. Debug APK po ponownym błędzie próbuje zebrać ograniczony log SDK z własnego procesu. **Kopiuj szczegóły** kopiuje lokalny raport; nic nie jest automatycznie wysyłane. Naprawiono też nachodzenie długiego komunikatu na dolny przycisk.

**Nie potwierdzono jeszcze emisji 1.4.1 na fizycznym Samsungu.** Test lokalnego JS i testy mostka nie dowodzą wyświetlenia reklamy. APK używa oficjalnych jednostek testowych Google, które nie generują przychodu. Prawdziwe ID właściciela są zachowane do przyszłej konfiguracji produkcyjnej. Nie symulujemy reklam ani nagrody za błąd SDK.

## Nagrody

- Jedna ukończona reklama daje **1 Młotek 3×3 + 2 Zmiany klocków**; wyłącznie po earned-reward SDK.
- Młotek usuwa do 9 zajętych pól, Zmiana wymienia trzy figury bez kasowania planszy i wyniku.
- Pakiet startowy gratis; kolejny pakiet także za 90 monet zdobytych w grze.
- Pomocniki działają w Classic i Time Attack. Przy braku ruchów można wybrać ratunek; Daily pozostaje bez pomocników.

Zachowano działający launcher i lokalny raport awarii. Odbiorcy: dzieci od 3 lat i dorośli. Profil reklam nadal child-directed/under-age/G/npa=1, bez AD_ID.

## Weryfikacja i pliki

**2769 sprawdzeń Godot, 18 testów Python i 11 testów Android/Robolectric zaliczonych.** Zweryfikowano manifest i definicje klas DEX, podpis APK, AAB, wyrównanie 16 KB i zgodność skryptów w paczkach. Renderowane scenariusze błędów są jawnymi danymi testowymi UI, nie zdjęciami emisji reklamy.

- [Źródła](neon-block-master-source.zip).
- [Release AAB unsigned — konfiguracja testowa](neon-block-master-release-unsigned.aab).
- [Strona i polityka prywatności](neon-block-master-website.zip).
- [Opis poprawki i ograniczeń](docs/WEBVIEW-1.4.1.md).
- [Opis pomocników](docs/BOOSTERS-1.4.md).
- [SHA-256](SHA256SUMS.txt).

Wydawca: **Krystian Development**, **kogonowski52@gmail.com**. Do produkcji pozostają publiczne URL strony/polityki, weryfikacja Families dla dokładnej wersji SDK, konfiguracja AdMob/UMP, własny klucz upload oraz deklaracje Play/IARC. Pliki strony są na `gh-pages`; sam push nie potwierdza działającego hostingu. AAB nie jest gotowym, podpisanym wydaniem Google Play.
