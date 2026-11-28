# Neon Block Master 2.0.0 — aktualizacja istniejącej gry

Pierwszy plik do pobrania: `neon-block-master-2.0-windows-signing.zip`.
Rozpakuj ZIP na Windows, uruchom `podpisz.cmd`, użyj istniejącego klucza
`C:\Users\PC\NeonBlockMaster-Signing\neon-upload.p12` i jego hasła.
Do **testów wewnętrznych tej samej aplikacji** w Play Console prześlij
`wynik/neon-block-master-2.0.0-play-signed.aab`.
Nie przesyłaj pliku z `unsigned` w nazwie. Nie publikowano gry na produkcji.

Pakiet aktualizacji: `com.neonblockmaster.puzzle`, wersja `2.0.0`, versionCode `12`.
Najwyższy kod potwierdzony w dotychczasowym wydaniu to 10 (1.5.0); lokalny szkic
11 nie był publikowany. Kod 12 przewyższa oba. Nie zmieniono nazw zapisów,
identyfikatorów produktów ani publicznego klucza Google Play. Instalacja jako
aktualizacja zachowuje postęp, rekordy, monety, pomocniki i uprawnienia zakupów.
Nie odinstalowuj wersji Play i nie czyść jej danych przed aktualizacją.

## Co zmieniono

- Większa plansza, zwarty wynik/rekord/pauza, jasne klocki, krótkie efekty
  osadzenia i fale na faktycznie usuniętych rzędach/kolumnach. Animacje nie blokują ruchów.
- Dopasowanie miniatur do obu wymiarów tacki. Poprzednia pionowa figura 5×38=190
  wystawała poza tackę o wysokości 150. Nowa mieści się z marginesem.
- Cała podnoszona figura znajduje się nad palcem. Podgląd i osadzenie używają
  tego samego pola; po ruchu palca puszczenie zachowuje ostatni pokazany podgląd.
- Puszczenie nad tacką/pomocnikami, poza obszarem planszy lub na zajętym miejscu
  anuluje ruch. Znikają pozostawione wcześniej „duchy” figur. Drugi palec,
  emulowana mysz i przerwanie gestu nie otwierają sklepu podczas przeciągania.
- Podpowiedź znika po pierwszym udanym ruchu. Dopasowane menu, pomocnicy i wynik.
- Jawne stany reklam: ładowanie, gotowa, błąd, ponowienie; „Obejrzyj” dopiero
  po załadowaniu. Pełne szczegóły SDK i kopiowanie na ekranie statusu.
- Własny most UMP uruchamia aktualizację zgód na wątku UI Androida. Zachowano
  child-directed=true, under-age=true, kategorię G i npa=1. Błąd zgody nie
  jest obchodzony. Zachowano preflight WebView i diagnostykę JavascriptEngine.
- Zamknięcie reklamy bez nagrody, błąd i powtórzony callback nie dopisują
  przedmiotów. Pakiet za ukończenie to dokładnie 1 Młotek i 2 Zmiany.

## Co faktycznie sprawdzono

Kod: Classic, Time Attack, Daily, jednoczesny rząd i kolumna, punktacja,
rekordy, pauza, brak ruchów, zapis/wznowienie, stary zapis 1.5.0, młotek przy
krawędzi, zmiana figur i pakiet za 90 monet. Testy przeciągania obejmują 13
kształtów, cztery obroty i cztery rogi. Testy sterownika reklam używają
kontrolowanych callbacków, w tym utraty sieci, ponowienia, błędów i duplikatów.
To testy logiki, a nie emisja reklamy Google.

Uruchomiono prawdziwy silnik Godot 4.6.3 z rendererem OpenGL/Mesa. Przetestowano
przyciski menu i zdarzenia wejścia dostarczane przez silnik. Wykonano prawdziwe
zrzuty rozgrywki, długiej figury przy dole, kasowania linii i pomocników,
a także menu, wyniku, PL/EN i układów: telefon 1080×2400 (20:9), tablet 7″
800×1280, tablet 10″ 1600×2560. Rozmiary tabletów są profilami rozdzielczości,
nie testem na fizycznym panelu o tej przekątnej.

Android: zbudowano i sprawdzono zawartość APK/AAB, natywne moduły GMA/UMP/Billing,
manifest, podpis APK oraz wyrównanie bibliotek do 16 KB. **Brak dostępnego
urządzenia/emulatora z usługami Google: uruchomienia APK na Androidzie,
wyświetlenia reklamy testowej, emisji produkcyjnej i prawdziwej płatności
nie potwierdzono.** Starego błędu JavascriptEngine nie uznano za diagnozę
obecnego problemu bez aktualnego raportu urządzenia.

## Osobny APK do telefonu

`neon-block-master-2.0-test.apk` jest podpisany kluczem testowym i ma pakiet
`com.neonblockmaster.puzzle.preview`. Instaluje się **obok** gry z Play, ma
osobny pusty zapis, oficjalne jednostki testowe Google i wyłączone płatności.
Nie służy do zarabiania ani do aktualizacji instalacji Play.

Test telefonu: **Pomocnicy → poczekaj na „Obejrzyj reklamę” → obejrzyj ją do
nagrody → zamknij → sprawdź +1 Młotek i +2 Zmiany. W razie błędu: Status reklam
→ Kopiuj szczegóły.** Nie klikaj reklam produkcyjnych w celu testowania.

Produkcyjne AAB używa istniejących identyfikatorów AdMob i produktów
`neon_plus` / `rescue_pack_10_20`. Aktywność konta AdMob, dostępność reklam,
ustawienia Play i rzeczywisty przychód zależą także od usług Google;
kompilacja nie potwierdza ich działania. Zakupy zachowują weryfikację podpisu
Google po stronie klienta; nie dodano serwera weryfikacji ani synchronizacji
portfela. Przed produkcją sprawdź zakup, anulowanie i przywrócenie w wersji
zainstalowanej z wewnętrznego testu Play.

## Odtworzenie kompilacji

`bash tools/test.sh` — logika gry i płatności.
`godot --path . --script tests/gui_v2.gd` — uruchomiony interfejs.
`godot --path . --script tests/capture_v2.gd` — prawdziwe zrzuty (zmienna
`NEON_CAPTURE_OUTPUT` wskazuje katalog wyjściowy).

Godot 4.6.3, JDK 21, Android SDK 36, build-tools 36.1.0; szablony eksportu
4.6.3 i Android Gradle build zainstalowane w projekcie.
Skopiuj publiczną konfigurację produkcyjną z `config/publishing.family.example.json` do
lokalnego `config/publishing.json`, zachowując rzeczywiste dane wydawcy.
`python tools/build_v2.py --target production` eksportuje AAB do podpisania.
`python tools/build_v2.py --target test` eksportuje osobny, jeszcze niepodpisany
APK testowy; dopiero zipalign/apksigner z kluczem testowym czynią go instalowalnym.
Skrypt przywraca konfiguracje po eksporcie; nie uruchamiaj obu eksportów naraz.
Źródła mostu UMP i polecenie odbudowy: `tools/build_ad_runtime.py --help`.
Gotowy AAR jest zawarty w źródłach.
