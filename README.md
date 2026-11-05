# Neon Block Master — poprawka 1.3.1

## Pobierz nowe APK

**[APK 1.3.1 — poprawiony start aplikacji](neon-block-master-1.3.1.apk)**. Otwórz plik i wybierz **Download raw**. Android 7.0+, ARM64, OpenGL ES 3.0. To version code 5, z dotychczasowym certyfikatem debugowym. Zainstaluj jako aktualizację; nie trzeba odinstalowywać gry ani usuwać postępu.

Naprawiono dwa błędy startu: stare ustawienia Next-Gen usuwały główną bibliotekę klasycznego AdMob z paczki, a adapter wyciszał SDK przed jego inicjalizacją. [Opis i testy regresji](docs/STARTUP-1.3.1.md). Wersja 1.3.0 jest wadliwa; użyj 1.3.1.

- [Pełne źródła Godot (ZIP)](neon-block-master-source.zip).
- [Release AAB bez podpisu](neon-block-master-release-unsigned.aab) — konfiguracja testowa, wymaga właściwej konfiguracji i klucza przed Google Play.
- [Pliki strony i polityki (ZIP)](neon-block-master-website.zip).
- [Sumy SHA-256](SHA256SUMS.txt).

## Reklamy i test

Gra dla dzieci od 3 lat i dorosłych. Klasyczny Google Mobile Ads 24.9.0 / Poing 4.3.1 z jednolitym profilem child-directed, under-age, G i npa=1. **Reklamy pozostają włączone**; nie rozwiązano problemu przez ich usunięcie. APK do testów używa oficjalnych jednostek Google i nie zarabia. Produkcyjne trzy ID właściciela są zapisane osobno do przyszłego wydania.

Po aktualizacji włącz internet, otwórz **Ustawienia → Reklamy testowe — status**, potem sklep/NEON LAB. Nagrody przyznaje wyłącznie earned-reward SDK. Zwykła gra działa offline, a PLASMA jest też dostępna za 240 monet z gry.

**2731 sprawdzeń Godot i 18 testów Python zaliczonych.** Weryfikator sprawdza rzeczywiste definicje MobileAds, AdRequest, RewardedAd i InterstitialAd w DEX, a nie same odwołania do tych nazw. Odrzuca wadliwe poprzednie APK. Sprawdzono manifest SDK, podpis, AAB i 16 KB. [Aktualny raport wraz z ograniczeniami testu urządzenia](docs/VALIDATION.md).

## Publikacja produkcyjna

Wydawca: **Krystian Development**, **kogonowski52@gmail.com**. Zaktualizowane pliki polityki są w `gh-pages`. [Ustawienia Pages](https://github.com/kogonowski52-png/puzle/settings/pages): **Deploy from a branch → gh-pages → /(root) → Save**. Push gałęzi nie potwierdza publicznego hostingu. app-ads.txt musi być też w katalogu głównym hosta.

Pozostają działające publiczne URL, konfiguracja AdMob/UMP, aktualne potwierdzenie Families dla dokładnej wersji SDK, własny klucz upload, testy telefonu i deklaracje Play/IARC. Nie deklarujemy zatwierdzenia przez Google. Nie publikuj klucza ani hasła w czacie/repozytorium.

[Stan reklam](docs/ADS-1.3.md) · [Instrukcja publikacji](docs/PUBLIKACJA-KROK-PO-KROKU.md) · [Bezpieczeństwo danych](docs/DATA-SAFETY.md).
