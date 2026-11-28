# Neon Block Master 2.0.0 / kod 12 — aktualizacja gry z Google Play

Przebudowana plansza i obsługa przeciągania, dopasowane tacki, jasne klocki,
krótkie efekty linii, nowe pomocniki i poprawiona obsługa reklam Android.
Pakiet aktualizacji pozostaje `com.neonblockmaster.puzzle`; zapisy i zakupy są zachowane.

**[Instrukcja aktualizacji, testy i ograniczenia](docs/UPDATE-2.0.md).**
AAB wymaga dotychczasowego klucza właściciela. Osobny APK testowy
`com.neonblockmaster.puzzle.preview` instaluje się obok wersji Play.
Nie potwierdzono emisji Google na urządzeniu ani rzeczywistych płatności;
nie publikowano na produkcji. Gotowe pliki: [gałąź apk-download](https://github.com/kogonowski52-png/puzle/tree/apk-download).

Poniżej historyczne instrukcje starszych wydań:

---

# Sklep 1.5.0 / kod 10 — podgląd aktualizacji

Neon Plus (Galaxy + Nova, bez reklam automatycznych), pakiet 10 Młotków + 20 Zmian, Google Play Billing 8.0.0, ekran rodzica i przywracanie trwałego zakupu. **Publiczny klucz licencyjny jest dodany. Właściciel musi jeszcze utworzyć i aktywować produkty w Play oraz sprawdzić transakcje w testach wewnętrznych. Nie potwierdzono sprzedaży.** [Uruchomienie i ograniczenia](docs/SHOP-1.5.0.md).

Wcześniejsze instrukcje poniżej dokumentują wersje historyczne. Wydanie 1.4.2 wysłane do Google pozostaje oddzielne od tej aktualizacji.

---

# Neon Block Master – Puzzle

**1.4.2 / code 9:** poprawione zgody produkcyjne UMP, kolejność podłączenia nagrody i eksport wersji pluginu. Sprawdzono również skompilowane zasoby finalnego AAB. [Raport i granice potwierdzenia zarabiania](docs/ADS-AUDIT-1.4.2.md). [app-ads.txt](docs/APP-ADS.md).

**Windows:** [lokalne podpisanie AAB na komputerze właściciela](docs/WINDOWS-PLAY.md). Klucz i hasło nie trafiają do repozytorium ani na czat.

**Google Play:** przygotowana konfiguracja z ID AdMob właściciela, materiały sklepu i niepodpisany kandydat produkcyjny. Podpis i pozostałe kroki: [PRODUCTION-PREP.md](docs/PRODUCTION-PREP.md). Dotychczasowy APK do instalacji pozostaje testowy; nie należy go wysyłać do Play.

**1.4.1:** przygotowanie systemowego WebView i test lokalnego JavaScript przed reklamą; szczegóły providera w Statusie reklam i poprawiony układ komunikatów. [Opis i ograniczenia](docs/WEBVIEW-1.4.1.md). Emisja na telefonie wymaga potwierdzenia.

**1.4.0: Młotek 3×3 i Zmiana klocków. Jedna reklama = 1 Młotek + 2 Zmiany; pakiet startowy gratis, alternatywa za 90 monet.** Przyciski są pod planszą oraz w menu POMOCNIKI. [Zmiany i stan reklam](docs/BOOSTERS-1.4.md). Poprawiono kolejność inicjalizacji SDK i dodano szczegółowy status/ponawianie. APK testowe, bez przychodu; emisja wymaga sprawdzenia na telefonie.

Kompletna gra logiczna w Godot **4.6.3**, GDScript, Android (pionowo) i desktop. Plansza 8×8, sterowanie dotykiem/myszą, trzy tryby, zapis lokalny, PL/EN, oryginalna grafika i audio. Źródła gry nie wymagają serwera ani płatnych bibliotek.

## Uruchomienie

Otwórz `project.godot` w Godot 4.6.3 i naciśnij **F5**. Z terminala:

```sh
godot --editor --path .
godot --path .
```

Na telefonie zainstaluj `builds/neon-block-master-debug.apk` (jeżeli znajduje się w dostarczonym pakiecie). To podpis debugowy, nie plik do wysyłki do Google Play. Wersja Android obsługuje ARM64, Android 7.0/API 24 lub nowszy, celuje w API 36. Komputery uruchamiają ten sam projekt bez reklam. Wymagany OpenGL ES 3.0.

## Co działa

- Classic, Time Attack (180 sekund aktywnej gry + bonus za wiele linii) i deterministyczne Daily Challenge na podstawie lokalnej daty.
- Trzy figury, wygodne pola chwytania, uniesienie nad palcem, zielony/czerwony podgląd, równoczesne usuwanie rzędów i kolumn, punkty i combo.
- Pauza, automatyczna pauza w tle, wznowienie zapisanej gry, ekran wyniku, rekordy i statystyki.
- Neon Coins: codzienny bonus, rekordy, wyzwania, prawdziwe reklamy nagradzane, jeżeli są dostępne. Sklep z czterema motywami i dwoma efektami; bez płatności i losowania nagród.
- Dźwięki, zapętlona elektroniczna muzyka, cząsteczki, przejścia, wibracje Android, ustawienia PL/EN.
- Atomowy zapis JSON z walidacją oraz ostatnią poprawną kopią; odzyskanie po uszkodzeniu głównego pliku. Brak synchronizacji chmurowej.
- Klasyczna integracja reklam (aktywna dla Android w 1.3.1): przypięty SDK Poing AdMob **4.3.1**, Google Mobile Ads 24.9.0 (MIT) dla Godot 4.6.3. Rewarded i interstitial, UMP, częstotliwość: rewarded ≥60 s; interstitial co trzeci restart po zakończeniu i ≥180 s. Brak SDK/zgody/sieci nie blokuje gry i nie przyznaje nagrody za reklamę.

## Testy

```sh
godot --headless --path . --editor --import --quit
./tools/test.sh
```

`tools/test.sh` używa osobnego katalogu danych. Testy obejmują logikę, 60 symulowanych gier, odtworzenie RNG, uszkodzony zapis, ekonomię, fallback reklam, wszystkie ekrany PL/EN, dotyk/mysz, timer i powrót z tła. Nie zastępują telefonu z Androidem. Raport i ograniczenia: [docs/VALIDATION.md](docs/VALIDATION.md). Rzeczywisty renderer i zrzuty:

```sh
godot --path . --resolution 720x1280 --script tests/capture.gd
```

Ten ostatni skrypt odgrywa legalne ruchy i nadpisuje zrzuty w `store/`; użyj osobnego `XDG_DATA_HOME`, aby chronić osobisty zapis. W chmurze potrzebuje wirtualnego ekranu X11.

## Publikacja i reklamy produkcyjne

Instrukcja krok po kroku: [docs/PUBLIKACJA-KROK-PO-KROKU.md](docs/PUBLIKACJA-KROK-PO-KROKU.md). Publiczne dane wydawcy i AdMob są walidowane przez `tools/prepare_release.py`. Bez nich i własnego klucza upload nie powstaje podpisany wariant produkcyjny. Nie przesyłaj klucza ani hasła w czacie.

W 1.3.1: **NEON LAB / PLASMA** (trzy dobrowolne reklamy albo 240 monet) i **jednorazowe podwojenie monet z rozgrywki**. Reklamy testowe korzystają z prawdziwego SDK. PLASMA pozostaje dostępna także za monety z gry. Nagrody nie wpływają na wynik, postęp nie wygasa. Szczegóły: [docs/REWARDED-DESIGN.md](docs/REWARDED-DESIGN.md). Stare zapisy są zachowywane.

## Android: APK i AAB

Instrukcja odtworzenia i podpisywania: [docs/ANDROID.md](docs/ANDROID.md). Skonfiguruj Android SDK oraz pełny JDK w ustawieniach edytora, zainstaluj szablon Android z menu Projekt i uruchom:

```sh
godot --headless --path . --export-debug "Android APK"
godot --headless --path . --export-debug "Android AAB"
godot --headless --path . --export-release "Android AAB unsigned"
```

AAB debug służy testom przez bundletool, a release unsigned wymaga własnego podpisu upload przed Google Play. Nie dołączamy prywatnego klucza produkcyjnego. Ostateczne identyfikatory reklam, dane wydawcy, publiczny URL polityki, UMP, grupa odbiorców i deklaracje Play wymagają konfiguracji. Nie deklarujemy zatwierdzenia przez Google Play ani potwierdzonego 60 FPS na telefonie.

## Struktura

- `scripts/board.gd` — czysta deterministyczna logika i serializacja sesji.
- `scripts/store.gd` — zapis, waluta, odblokowania i walidacja profilu.
- `scripts/main.gd` — ekrany, obsługa dotyku, cykl aplikacji.
- `scripts/board_view.gd`, `backdrop.gd` — renderowanie; `sound.gd` — audio.
- `scripts/ads.gd` — bramka reklam i przyszłe uprawnienie Billing; `admob_adapter.gd` — rzeczywisty SDK/UMP.
- `addons/admob/`, `third_party/admob/android-source/` — przypięta integracja i natywne źródła.
- `tools/generate_assets.py` — odtwarzanie własnej grafiki i audio (Python + Pillow).
- `tests/`, `store/`, `docs/` — testy, materiały sklepu i dokumentacja.

Repozytorium wykorzystuje istniejący checkout. Nie twórz dodatkowego worktree do zwykłej pracy. Licencje: [docs/LICENSES.md](docs/LICENSES.md).
