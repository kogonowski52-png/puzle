# Neon Block Master — 1.2.0

## Pobierz

- [APK do testowania — 77 MB](neon-block-master-debug.apk). Otwórz plik i wybierz **Download raw**. Android 7.0+, ARM64, OpenGL ES 3.0; zachowano podpis poprzedniego APK.
- [AAB release bez podpisu](neon-block-master-release-unsigned.aab) — wymaga własnego klucza upload przed Play.
- [Pełne źródła Godot (ZIP)](neon-block-master-source.zip).
- [Pliki strony i polityki (ZIP)](neon-block-master-website.zip).

## Dzieci i dorośli

Odbiorcy zostali określeni jako dzieci i dorośli. Wydanie 1.2.0 jest **bez reklam i bez natywnego SDK reklamowego Google**. Motywy można odblokować za monety z gry; zachowano starszy zapis. Nie zbieramy wieku w tym wariancie. Ocena treści 3+ nie została nadana automatycznie — określi ją ankieta IARC.

Aktualnych wymagań Families i przydatności poprzedniego SDK nie udało się zweryfikować z powodu blokady dostępu do oficjalnej dokumentacji. Nie deklarujemy certyfikacji SDK ani zgodności/akceptacji Google Play. Realne reklamy pozostają wyłączone do prawidłowej weryfikacji i konfiguracji.

**2725 sprawdzeń gry + 14 testów narzędzi zaliczonych.** W gotowych paczkach sprawdzono brak natywnych klas SDK reklam, reklamowych metadanych i Internet/AD_ID; APK ma tylko uprawnienie wibracji. Sprawdzono podpis, strukturę AAB, 16 KB ELF i zgodność skryptów między paczkami. Telefon, 60 FPS i proces Play Console pozostają do weryfikacji.

## Strona i publikacja

Publiczne dane wydawcy podano i zatwierdzono do publikacji: **Krystian Development**, **kogonowski52@gmail.com**. Pliki strony są na gałęzi `gh-pages`; sam push nie potwierdza uruchomienia hostingu.

[Otwórz ustawienia GitHub Pages](https://github.com/kogonowski52-png/puzle/settings/pages) i wybierz **Deploy from a branch → gh-pages → /(root) → Save**. Sprawdź publiczny adres wyświetlony przez GitHuba.

[Stan wydania rodzinnego i dalsze kroki](docs/FAMILY-EDITION.md) · [Raport walidacji](docs/VALIDATION.md) · [Instrukcja publikacji](docs/PUBLIKACJA-KROK-PO-KROKU.md) · [Data safety](docs/DATA-SAFETY.md).

Nie wysyłaj prywatnego klucza ani hasła do repozytorium lub czatu. Podpisany produkcyjny AAB, działający publiczny URL polityki, deklaracje i testy w Play Console wymagają osobnych czynności właściciela.
