# Poprawka uruchamiania 1.3.1

Zgłoszenie: aplikacja otwiera się na sekundę i zamyka na Samsungu S25 FE.

## Znaleziony błąd

W generowanym `android/build/build.gradle` pozostał blok dopisany przez wcześniej używany plugin Next-Gen. Wykluczał `com.google.android.gms:play-services-ads` i `play-services-ads-lite`, potrzebne po migracji na klasyczny SDK. Gradle kompilował gotowy wrapper AAR, ale pomijał jego bibliotekę wykonawczą. W APK 1.3.0 brakowało definicji MobileAds, AdRequest, RewardedAd i InterstitialAd. Natywny plugin odnosi się do nich przy ładowaniu/startowaniu aplikacji.

Poprzedni weryfikator błędnie uznawał nazwy występujące w odwołaniach DEX za dowód obecności SDK. Dlatego kontrola plików przeszła mimo wadliwej paczki. To był błąd pakowania i walidacji, nie zbyt słaby telefon.

Dodatkowo adapter wywoływał `MobileAds.set_app_muted` przed inicjalizacją. Klasyczny SDK sprawdza tę kolejność i rzuca `IllegalStateException` z komunikatem „MobileAds.initialize() must be called prior to setting app muted state”. Wywołanie przeniesiono za callback inicjalizacji; ustawienia prywatności nadal są przekazywane przed initialize. Test adaptera sprawdza brak wyciszania i ładowania przed callbackiem oraz oba wywołania po nim.

## Zmiana

- Plugin eksportu usuwa dokładnie rozpoznany dawny blok Next-Gen z wygenerowanego szablonu; pozostawia inne ustawienia.
- Weryfikator odczytuje tabelę class_defs DEX i wymaga rzeczywistych definicji głównych klas SDK/UMP/wrappera. Dodatkowo kontroluje provider inicjalizacji i AdActivity w manifeście.
- Pełny build kończy się weryfikacją artefaktów. Błędna paczka zatrzymuje pipeline.
- Cztery testy Python DEX oraz cztery sprawdzenia kolejności inicjalizacji Godot odróżniają referencję od definicji i sprawdzają uszkodzone wejście. Wadliwy poprzedni APK rzeczywiście został odrzucony przez nową kontrolę.
- Wersja 1.3.1 / code 5, ten sam package i certyfikat debugowy. Nie trzeba usuwać postępu gry.

Reklamy pozostają aktywne, z jednostkami testowymi Google i profilem dla dzieci. Nie rozwiązano problemu przez wyłączenie reklam. Stan testu uruchomienia i ograniczenia opisuje [VALIDATION.md](VALIDATION.md); nie traktuj emulatora jako potwierdzenia na Samsungu S25 FE.
