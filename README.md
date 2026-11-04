# Neon Block Master — Android APK 1.1.0

[Pobierz APK](https://github.com/kogonowski52-png/puzle/raw/refs/heads/apk-download/neon-block-master-debug.apk) albo otwórz plik i wybierz **Download raw**.

Android 7.0+ (API 24), ARM64, OpenGL ES 3.0. Wersja 1.1.0, kod 2, podpis debugowy zgodny z poprzednią paczką. To nadal wersja testowa z testowymi identyfikatorami AdMob, nie publikacja Google Play.

Nowości: NEON LAB / PLASMA za trzy dobrowolne reklamy z nagrodą lub 240 monet; jednorazowe podwojenie monet z rozgrywki; migracja zapisów.

2710 sprawdzeń gry i 11 testów narzędzia wydawniczego zaliczonych. APK ma zweryfikowany podpis. Testy prawdziwych reklam/UMP i 60 FPS na fizycznym telefonie pozostają do wykonania.

Ta gałąź służy do dystrybucji APK, AAB i źródeł.

## Źródła i pakiet wydawniczy

- [Pełny projekt Godot / źródła ZIP](neon-block-master-source.zip) — kod gry, grafiki, testy i narzędzia publikacji.
- [AAB release bez podpisu](neon-block-master-release-unsigned.aab) — wymaga własnego klucza upload przed wysłaniem do Google Play.
- [Instrukcja publikacji krok po kroku](docs/PUBLIKACJA-KROK-PO-KROKU.md).
- [Szkic Data safety](docs/DATA-SAFETY.md).
- [Opis nagród reklamowych](docs/REWARDED-DESIGN.md).
- [Raport walidacji i ograniczenia](docs/VALIDATION.md) · [Wyniki testów](test-results.txt) · [SHA-256](SHA256SUMS.txt).

Do aktywacji produkcyjnych reklam potrzebne są własne identyfikatory AdMob, publiczne dane wydawcy, właściwa grupa odbiorców oraz opublikowana polityka i konfiguracja UMP. Nie zostało to wykonane przez samo udostępnienie plików. Klucza podpisu i hasła nie umieszczaj w Git ani czacie.
