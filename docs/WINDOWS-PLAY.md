# Windows: pierwszy podpis i dalsze kroki w Play

Właściciel potwierdził, że ma komputer z Windows i konto Play Console; tej gry jeszcze nie wysyłał. Nowy klucz upload utwórz na własnym komputerze. Paczka nie przesyła go do Codexa, GitHuba ani Google. Do Play dodaje się podpisany AAB; klucz pozostaje prywatny.

## Podpisanie na komputerze właściciela

1. Pobierz [neon-block-master-windows-signing.zip](https://github.com/kogonowski52-png/puzle/blob/apk-download/neon-block-master-windows-signing.zip) → **Download raw**.
2. Jeżeli Windows blokuje skrypty pobranej paczki: we Właściwościach ZIP zaznacz **Odblokuj**, zatwierdź, a potem użyj **Wyodrębnij wszystkie**. Uruchamiaj pliki z rozpakowanego folderu.
3. Jeżeli nie masz JDK/Android Studio, w PowerShell uruchom `winget install --id Microsoft.OpenJDK.21 -e`. Przejdź przez instalator na swoim komputerze. Skrypt szuka JDK w JAVA_HOME, Android Studio, Microsoft/Eclipse Adoptium/Java i PATH.
4. Kliknij **podpisz.cmd**. Ustal i powtórz hasło (minimum 12 znaków); nie jest wyświetlane ani zapisywane w raporcie. Zachowaj je w menedżerze haseł.
5. W folderze **wynik** powstaną `neon-block-master-1.4.1-play-signed.aab` i `raport-podpisu.json`. Komunikat sukcesu to **PODPIS POTWIERDZONY**. Jeżeli pojawi się błąd, nie używaj częściowego pliku.
6. Klucz: `%USERPROFILE%\NeonBlockMaster-Signing\neon-upload.p12`. Zrób jego prywatną kopię. Skrypt nie nadpisuje istniejącego klucza; następne uruchomienie używa tego samego pliku i hasła. Klucza ani hasła nie publikuj i nie przesyłaj na czat.

Paczka zawiera dokładny, wcześniej sprawdzony AAB z ID reklam właściciela. SHA-256 kandydata jest sprawdzane przed tworzeniem klucza. Podpis jest sprawdzany przez jarsigner, a certyfikat AAB musi pasować do klucza upload. Nie korzystamy z klucza debugowego.

## Sprawdzenie narzędzia

Dziewięć testów rzeczywistego podpisywania zaliczono w **PowerShell 7.4.6 + JDK 21 na Linuksie**: zmieniony plik, utworzenie klucza, podpis, zachowanie oryginalnej zawartości AAB, raport, ponowne użycie klucza, błędne hasło, odrzucenie certyfikatu Android Debug oraz bezpieczne wprowadzanie/potwierdzanie hasła z rozróżnieniem wielkości liter. Szczegóły: `windows-signing-tests.json` w paczce. Klucze testowe zostały usunięte. Nie wykonano natywnego testu na Windows; nie deklarujemy go jako wykonanego. Skrypt używa konstrukcji zgodnych z Windows PowerShell 5.1, a jego pierwsze uruchomienie na komputerze właściciela pozostaje do potwierdzenia.

## Po utworzeniu podpisanego pliku

Sam podpis nie potwierdza Families, hostingu, konta AdMob ani zatwierdzenia Play. Przed dystrybucją dokończ [PRODUCTION-PREP.md](PRODUCTION-PREP.md): publiczna polityka i root app-ads.txt, aktualna lista dla Google Mobile Ads 24.9.0, AdMob/UMP i formularze Play. Sieć Codexa nadal blokuje potrzebne strony; zapisany szkic dopuszczonych domen nie został zastosowany w bieżącym środowisku. Nie wpisano fikcyjnej weryfikacji SDK.

W Play Console utwórz **Neon Block Master – Puzzle**, polski, gra, bezpłatna. Po sprawdzeniach rozpocznij od **Testy → Testy wewnętrzne → Utwórz nowe wydanie**. Włącz Play App Signing i wybierz zarządzany przez Google klucz podpisywania aplikacji; lokalny klucz z paczki służy jako klucz upload. Dodaj plik z `wynik`, uzupełnij informacje i postępuj według rzeczywistych komunikatów panelu. Skrypt niczego nie wysyła i nie akceptuje warunków za właściciela.

Wymagania testów zamkniętych i dostępu do produkcji zależą od konta. Nie obiecujemy publicznej dostępności tego samego dnia ani konkretnego czasu sprawdzenia przez Google.

Wersja z Google Play będzie podpisana innym certyfikatem niż dotychczasowy debug APK. Instalacja na telefonie z debug APK może wymagać jego odinstalowania; postęp jest lokalny i odinstalowanie go usuwa. Nie traktuj debugowego APK jako produkcyjnej aktualizacji z tym samym podpisem.
