# Kontrola reklam i poprawka 1.4.2 / code 9

Kontrola dotyczy oryginalnego AAB 1.4.1 / code 8 podpisanego przez właściciela na Windows, oraz poprawki 1.4.2 / code 9. Właściciel poinformował, że nie instalował jeszcze wersji z Google Play. Nie potwierdzono emisji reklam produkcyjnych ani przychodu w AdMob.

## Znalezione i poprawione

- **Metadane pluginu nie trafiały do AAB.** Uruchomienie testów na skompilowanych zasobach code 8 wypisywało `AdMob: Failed to load plugin.cfg`. Żądanie używało zastępczej wersji 4.0.0 zamiast 4.3.1. Plik `addons/admob/plugin.cfg` jest teraz dołączany do eksportu, a weryfikator sprawdza go w rzeczywistym AAB. Ten błąd metadanych nie dowodzi przyczyny wszystkich wcześniejszych problemów z emisją.
- **Natychmiastowa odpowiedź UMP mogła zginąć.** W odtworzonym przypadku przed poprawką odebrano 0 callbacków. Nasłuchiwano dopiero po natywnym `update()`. Podłączono oba sygnały przed żądaniem oraz ponownie rozwiązywany jest natywny singleton zgód przy starcie produkcji. Testy obejmują NOT_REQUIRED, OBTAINED, REQUIRED, UNKNOWN oraz błąd. Nierozwiązane zgody pozostawiają reklamy wyłączone.
- **Nasłuch nagrody był podłączany po `show()`.** Natychmiastowy earned-reward w kontrolowanej próbie również ginął. Sygnał jest teraz podłączany przed pokazaniem. Testy prawdziwych klas mostka GDScript z natywnym kontraktem sprawdzają podwójny earned, zamknięcie bez nagrody i błąd pokazania. Nie są to prawdziwe wyświetlenia Google.

Nie wymieniono SDK, nie usunięto ograniczeń dla dzieci, nie ustawiono fikcyjnej weryfikacji Families. Pozostają Google Mobile Ads 24.9.0 / Poing 4.3.1 / UMP 4.0.0, child-directed, under-age, G, npa=1 i ID właściciela.

## Wyniki

- **2798 sprawdzeń źródeł Godot i 21 testów Python zaliczonych.** Dwa wcześniejsze testy negatywne otrzymały jawne dane wejściowe (nieuzupełnieni odbiorcy / testowe ID), aby nie polegały na tym, czy cały projekt ma konfigurację demo czy produkcyjną.
- **2798 sprawdzeń ponownie zaliczonych na skompilowanych zasobach wyciągniętych z finalnego AAB code 9.** Gra używała rzeczywistej produkcyjnej konfiguracji z paczki. Testy dodano z zewnątrz; skompilowanych plików gry nie podmieniano. Brak wcześniejszego błędu plugin.cfg. To test logiki na Godot 4.6.3 w Linuksie, nie test urządzenia Android ani emisji.
- Bundletool, ZIP, manifest, rzeczywiste ID, definicje klas Google/UMP/mostków, brak debugowego launchera i uprawnień reklamowego identyfikatora, wyrównanie ELF 16 KB — zaliczone.
- **12 testów lokalnego podpisywania PowerShell/JDK na Linuksie zaliczonych.** Obejmują również przypisanie aktualizacji do istniejącego certyfikatu upload. Prywatne klucze testowe usunięto. Wcześniejsze podpisanie 1.4.1 na Windows potwierdził właściciel; nie otrzymaliśmy jego klucza. Automatycznego testu tej poprawki na Windows nie wykonano.

## Plik dla właściciela

Pobierz `neon-block-master-1.4.2-windows-signing.zip`, rozpakuj i uruchom `podpisz.cmd`. Hasło wpisujesz lokalnie. Paczka oczekuje poprzedniego klucza `%USERPROFILE%\NeonBlockMaster-Signing\neon-upload.p12` i publicznego odcisku:

`813efb0ae5ebf0cba2c270a7492d623a94053b46417bc00053c541c567fee467`

Brak właściwego klucza zatrzyma podpisywanie. Nie twórz zastępczego klucza dla tej aktualizacji. Wynik: `wynik/neon-block-master-1.4.2-play-signed.aab`. Dodaj go do istniejącej aplikacji `com.neonblockmaster.puzzle` na używanej ścieżce testowej jako nową wersję z code 9. Code 8 i jego raporty są historią poprzedniego wydania.

## Czego jeszcze nie potwierdzono

AAB ma produkcyjne jednostki właściciela; przychód z prawidłowych reklam produkcyjnych jest naliczany przez AdMob dla ich wydawcy. To nie gwarancja emisji, stawki ani wypłaty. Reklamy demo/testowe nie generują przychodu. Stan aplikacji i konta AdMob, gotowość do emisji, powiązanie ze sklepem, app-ads.txt i ustawienia płatności nie są widoczne z pliku gry.

Przed publicznym wydaniem pozostają: aktualne sprawdzenie Families dla dokładnej wersji SDK, publiczna polityka i app-ads.txt w katalogu głównym hosta, ustawienia AdMob/UMP, test aplikacji z Google Play i weryfikacja nagrody. Środowisko nadal blokuje strony Google oraz hosta GitHub Pages; zapisany szkic sieci nie stanowi potwierdzenia dostępu. Zrzut z AdMob pokazuje instrukcję app-ads.txt, nie potwierdzenie jego weryfikacji.

Instrukcja app-ads.txt: [APP-ADS.md](APP-ADS.md). Nadal nie deklarujemy, że ta aplikacja już zarabia.
