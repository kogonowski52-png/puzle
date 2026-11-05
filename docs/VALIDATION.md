# Weryfikacja wydania 1.3.1

**Zgłoszenie po publikacji:** właściciel potwierdził, że 1.3.1 nadal zamyka się przy starcie na Samsungu S25 FE. Poprawki pakowania i kolejności inicjalizacji nie są potwierdzoną naprawą tego zgłoszenia. Testy plików/JVM nie dowodzą uruchomienia na tym telefonie. [Lokalny raport awarii](../tools/android_diagnostics/README.md) pozwala zebrać rzeczywisty wyjątek lub natywny ślad; przyczyna pozostaje nieustalona.


Poprawka pakowania: usunięto pozostawione przez dawny plugin Next-Gen wykluczenia klasycznego SDK. Nowy weryfikator odróżnia definicje klas DEX od odwołań i odrzuca wadliwe APK 1.3.0. [Opis](STARTUP-1.3.1.md).

## Wykonane

- Godot 4.6.3 official: import, uruchomienie sceny i **2731 sprawdzeń, 2731 zaliczonych, 0 błędów**; 60 symulowanych gier i 1256 legalnych ruchów. Testy obejmują logikę, RNG, odzyskanie zapisu, ekonomię, UI PL/EN, dotyk/mysz, timer i powrót z tła.
- **18 testów Python**, wszystkie zaliczone: walidacja konfiguracji, blokowanie niekompletnej publikacji, podpis, generowanie strony. Własny klucz upload nie został utworzony.
- Adapter klasycznego Google Mobile Ads **24.9.0 / Poing 4.3.1 / UMP 4.0.0** kompiluje się. Test serializacji żądania potwierdza child-directed=1, under-age=1, G i npa=1. Brak natywnego SDK na desktopie nie daje fikcyjnych nagród. Testowe identyfikatory Google są celowe, nie generują przychodu.
- Zbudowano debug APK, debug AAB oraz release AAB unsigned. `tools/verify_artifacts.py`: ZIP, `apksigner verify`, `bundletool validate`, `zipalign -c -P 16 4`, wyrównanie segmentów ELF minimum 16 KB — zaliczone. SHA-256 w `artifacts.json` i `SHA256SUMS.txt`.
- Manifest APK: `com.neonblockmaster.puzzle`, version code **5**, version name **1.3.1**, min API 24, target/compile API 36, ARM64. Klasy rzeczywistego Google Mobile Ads obecne; Next-Gen SDK nieobecny. Internet i metadane SDK obecne; AD_ID, telefon i reklamowe uprawnienia Privacy Sandbox usunięte.
- Konfiguracja Android: test, mixed, family_contextual, gma_classic_24.9.0. Prywatna lokalna konfiguracja produkcyjna, testy i klucze nie trafiają do APK/AAB. Skompilowane skrypty gry są identyczne we wszystkich trzech paczkach. Zachowano dotychczasowy certyfikat debugowy, aby można było zainstalować aktualizację.
- Prawdziwy renderer OpenGL przez Xvfb/Mesa llvmpipe: sześć zrzutów 720×1280 w `store/`, odgrywających legalne ruchy. Układ mieści się przy 360×640, 1080×1920 i 720×1600. Pomiar: 180 klatek / 5971 ms, około 38 MiB pamięci raportowanej przez Godot. To programowy renderer chmurowy, nie pomiar 60 FPS ani PSS telefonu.
- Przygotowano stronę, politykę PL/EN dla wersji 1.3 i app-ads.txt z zatwierdzonym kontaktem wydawcy. Sam plik nie uruchamia publicznego hostingu ani weryfikacji AdMob.

## Wymagane przed produkcją

- Instalacja i rozgrywka na fizycznym telefonie: emisja reklam, callback nagrody, brak sieci, powrót po reklamie, dźwięk, wibracje, gesty systemowe, 16 KB, wydajność i ANR. W chmurze nie ma urządzenia; komunikat adb po eksporcie nie jest testem instalacji.
- Aktualna oficjalna lista Families dla dokładnej wersji SDK: dostęp do dokumentacji Google jest blokowany przez sieć środowiska. Ustawienia dla dzieci i przejście kompilacji nie dowodzą certyfikacji ani zatwierdzenia Play. Pipeline produkcyjny wymaga odnotowanej weryfikacji i nie został sztucznie odblokowany.
- Działający publiczny URL polityki, konfiguracja UMP/AdMob, formularze grup odbiorców, IARC i Bezpieczeństwo danych. Gra jest przeznaczona dla dzieci od 3 lat i dorosłych. Nie zamieniono tego na 16+; ocena treści zależy od IARC.
- Własny klucz upload, podpisanie i wysłanie do Google Play. Release AAB pozostaje **unsigned**. Nie testowano reklam zarabiających na własnych jednostkach.
- Publiczny hosting GitHub Pages oraz `app-ads.txt` w katalogu głównym hosta wymagają włączenia/weryfikacji; gałąź z plikami strony nie jest dowodem działającego URL.
- Zapisane instrukcje środowiska nie są dowodem odtworzenia nowego zadania z opublikowanej migawki.

Szczegóły reklam: [ADS-1.3.md](ADS-1.3.md). Procedura na telefonie: [TESTING.md](TESTING.md). Konfiguracja wydania: [ANDROID.md](ANDROID.md).
