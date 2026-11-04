# Wyniki weryfikacji

## Wykonane w tej sesji

Aktualizacja 1.1.0: dodatkowo **11 testów Python** pipeline produkcyjnego — wszystkie zaliczone. Sprawdzono migrację starych zapisów bez utraty monet/motywów, trzy trwałe ładunki PLASMA, odblokowanie bez reklam, odrzucenie ujemnej ceny, jednorazowe podwojenie monet i brak wypłaty dla starego identyfikatora. Sprawdzono także stany UI po odebraniu nagrody/odblokowaniu. Adapter kompiluje się; jego natywne zdarzenia, ponawianie i zmiana zgód wciąż wymagają testu na Androidzie.

`prepare_release.py --check` rzeczywiście blokuje pusty szablon i testowe ID. Test z brakującym podpisem potwierdził brak zmian w konfiguracji projektu. Helper klucza sprawdzono z tymczasowym kluczem: uprawnienia 0600 i odmowa nadpisania. Nie utworzono klucza produkcyjnego właściciela. Produkcyjny eksport z prywatnym kluczem i prawdziwymi ID pozostaje niewykonany.

- Godot 4.6.3 official: import projektu i uruchomienie natywnej sceny.
- Automatyczny runner `tests/run.gd`: **2710 sprawdzeń, 2710 zaliczonych, 0 błędów**, w tym 60 symulowanych gier i 1256 legalnych ruchów. Ostatnia pełna kompilacja ponownie uruchamia ten runner; jej log jest dołączony w paczce wynikowej.
- Sprawdzono granice i kolizje, jednoczesne kasowanie przecięcia rzędu i kolumny, wynik, combo, reset combo, bonus czasu, brak możliwych ruchów i uczciwy refill.
- Sprawdzono deterministyczność dnia i całej sekwencji oraz bezstratne odtworzenie stanu RNG przez JSON. Poprawiono wykryty błąd walidacji kolorów (liczby JSON są typu float w Godot).
- Sprawdzono zapis, odtworzenie po uszkodzeniu głównego pliku z poprawnej kopii, walutę, zakup bez ujemnego salda, bezpłatny wybór posiadanego motywu i jednokrotne nagrody dnia.
- Wszystkie ekrany PL/EN, w tym licencje, powstały jako rzeczywiste węzły UI. W testach odtworzono chwytanie, podgląd i upuszczanie przez dotyk oraz mysz, pauzę, tło, powrót do gry, upływ czasu i ukończenie Daily.
- Brak natywnego SDK na desktopie nie przyznaje fikcyjnych reklamowych nagród. Adapter SDK kompiluje się względem dołączonego Poing AdMob 5.1.0. Sprawdzono ustawienie zapętlenia i rzeczywiste odtwarzanie muzyki po upływie pełnej ośmiosekundowej pętli.
- Prawdziwe renderowanie OpenGL przez Xvfb/Mesa llvmpipe; sześć zrzutów 720×1280 w `store/`, odgrywających legalne ruchy. Poprawiono skalowanie logo znalezione podczas oglądania zrzutów.
- Układ mieści się przy 360×640, 1080×1920 i 720×1600. W ostatnim przypadku wirtualny viewport wynosił 720×1600, a scena pozostała wyśrodkowana.
- Pomiar orientacyjny na **programowym rendererze chmurowym**: 180 klatek / 6141–33837 ms, ~37–38 MiB pamięci raportowanej przez `OS.get_static_memory_usage`. Pomiary były współdzielone z kompilacją Android i znacznie zależały od obciążenia CPU. To nie jest pomiar całego PSS ani dowód 60 FPS na telefonie. Usunięto zbędne przerysowania i alokacje StyleBox oraz zastąpiono wielokrotne nakładanie gradientów jedną teksturą.
- Utworzono debug APK, debug AAB oraz release AAB unsigned. Końcowy zestaw przeszedł kontrolę ZIP, `apksigner verify` (APK), `bundletool validate` (oba AAB) i wyrównania ELF 16 KB przez `tools/verify_artifacts.py`; wyniki i SHA-256 znajdują się w `builds/artifacts.json` oraz paczce wynikowej.
- Manifest APK: package `com.neonblockmaster.puzzle`, version 2 / 1.1.0, min API 24, target/compile API 36. Uprawnienia aplikacji oraz odziedziczone z SDK obejmują Internet, stan sieci, wibracje, AD_ID, READ_BASIC_PHONE_STATE, WAKE_LOCK i FOREGROUND_SERVICE. Ostateczna deklaracja prywatności musi uwzględniać faktyczny scalony manifest.
- Natywne biblioteki ARM64 `libgodot_android.so` i `libc++_shared.so`: segmenty ELF LOAD wyrównane do **16384 bajtów**. APK przeszedł `zipalign -c -P 16 4`. To kontrola plików, nie test uruchomienia na urządzeniu ze stronami 16 KB.
- Brak fizycznego urządzenia / działającego adb daemon oznacza komunikat `cannot connect to daemon at tcp:5037` po niektórych eksportach. Nie uniemożliwił utworzenia artefaktów. Nie opisujemy tego jako testu instalacji.

## Niewykonane i wymagane przed produkcją

- Instalacja i długa rozgrywka na fizycznym telefonie, działanie wibracji, realne gesty systemowe, wycięcia ekranów i pomiar 60 FPS/PSS/ANR.
- Wyświetlenie reklam testowych przez natywne Google SDK na Androidzie, sieciowe scenariusze UMP w EOG, błędy sieci na urządzeniu, przyznanie i odmowa nagrody w rzeczywistych callbackach. Kod i binaria SDK są dołączone; nie twierdzimy, że desktopowy fallback waliduje reklamę.
- Podpisanie produkcyjnym kluczem upload i wysyłka do Play Console. Release AAB jest **unsigned**. Nie utworzono konta AdMob/Google Play, płatności, produkcyjnych reklam ani publicznej strony z polityką.
- Sprawdzenie bieżących wymagań Google Play w oficjalnym panelu: próba dostępu do strony target API w środowisku była zablokowana HTTP 403. Target 36 i wyrównanie 16 KB nie są pełną deklaracją zgodności.
- Odtworzenie nowego zadania z opublikowanej migawki. Zapisano draft `install_script` i `start_skill`; publikacja pozostaje działaniem użytkownika w ustawieniach środowiska.

Procedura na telefonie: `docs/TESTING.md`. Konfiguracja produkcyjna: `docs/ANDROID.md`.
