# Neon Block Master — 1.3.0 z reklamami testowymi

## Pobierz APK

**[APK 1.3.0 do zainstalowania na telefonie — 85 MB](neon-block-master-debug.apk)**. Otwórz plik i wybierz **Download raw**. Android 7.0+, ARM64, OpenGL ES 3.0. Zachowano dotychczasowy certyfikat debugowy, więc można zainstalować aktualizację.

- [Pełne źródła Godot (ZIP)](neon-block-master-source.zip).
- [Release AAB bez podpisu](neon-block-master-release-unsigned.aab) — również konfiguracja testowa, wymaga właściwej konfiguracji i klucza przed Google Play.
- [Pliki strony i polityki (ZIP)](neon-block-master-website.zip).
- [Sumy kontrolne SHA-256](SHA256SUMS.txt).

## Reklamy dla dzieci i dorosłych

Gra jest przeznaczona dla dzieci od 3 lat i dorosłych. Ta wersja zawiera **rzeczywisty klasyczny Google Mobile Ads SDK 24.9.0 / Poing 4.3.1**, zamiast wariantu 1.2 bez reklam. Wszyscy gracze używają profilu child-directed, under-age, G i npa=1; brak uprawnienia AD_ID. Ocena sklepu jest ustalana przez IARC.

APK do Twoich testów używa **oficjalnych jednostek testowych Google i nie zarabia**. Produkcyjne App ID, Rewarded i Interstitial od właściciela są zapisane w konfiguracji źródeł do przyszłego wydania produkcyjnego.

Na telefonie włącz internet, otwórz **Ustawienia → Reklamy testowe — status**, następnie sklep/NEON LAB i poczekaj na załadowanie reklamy. Za earned-reward SDK dostępne są monety, dodatkowa szansa, podwojenie monet z rozgrywki albo ładunek do PLASMA. Nagrody nie wymagają klikania reklamy. Motyw można też zdobyć za 240 monet z gry.

**2727 sprawdzeń Godot i 14 testów Python zaliczonych.** Sprawdzono podpis APK, manifest, obecność klasycznego SDK, brak Next-Gen, strukturę AAB, wyrównanie bibliotek 16 KB oraz zgodność skryptów w paczkach. W chmurze nie ma fizycznego telefonu, więc nie potwierdzono rzeczywistego wyświetlenia reklamy ani wydajności telefonu.

## Strona i wydanie produkcyjne

Publiczny wydawca: **Krystian Development**, **kogonowski52@gmail.com**. Aktualne pliki strony i polityki są na gałęzi `gh-pages`. [Ustawienia GitHub Pages](https://github.com/kogonowski52-png/puzle/settings/pages): **Deploy from a branch → gh-pages → /(root) → Save**. Push plików nie potwierdza działającego publicznego hostingu; zweryfikuj URL. Dla AdMob app-ads.txt musi być także w katalogu głównym hosta.

Do produkcji nadal potrzebne są: działający URL polityki/strony, konfiguracja konta AdMob i UMP, aktualna weryfikacja dokładnej wersji SDK na oficjalnej liście Families, własny klucz upload, testy urządzenia i deklaracje Play. Dokumentacja Google jest blokowana przez sieć środowiska; nie zadeklarowano certyfikacji ani zatwierdzenia przez Google Play. Klucza ani hasła nie wysyłaj do czatu lub repozytorium.

[Stan reklam i testowanie](docs/ADS-1.3.md) · [Publikacja krok po kroku](docs/PUBLIKACJA-KROK-PO-KROKU.md) · [Raport walidacji](docs/VALIDATION.md) · [Bezpieczeństwo danych](docs/DATA-SAFETY.md).
