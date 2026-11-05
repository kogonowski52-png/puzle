NEON BLOCK MASTER — PODPISYWANIE NA WINDOWS

To przygotowanie pliku do pierwszego wydania. Niczego nie wysyła do Play,
nie uruchamia reklam i nie oznacza zatwierdzenia aplikacji przez Google.

1. Pobierz pełną paczkę neon-block-master-windows-signing.zip z GitHuba.
   Jeśli Windows pokazuje blokadę pliku ZIP: prawy przycisk → Właściwości
   → zaznacz Odblokuj → Zastosuj. Rozpakuj całą paczkę, np. na Pulpit.
   Nie uruchamiaj skryptu wewnątrz widoku ZIP.
2. Potrzebny jest JDK, np. Microsoft OpenJDK 21. Jeżeli nie masz JDK ani
   Android Studio, otwórz PowerShell i wykonaj:

   winget install --id Microsoft.OpenJDK.21 -e

   Potwierdzenia instalatora wykonujesz na swoim komputerze. Zamknij okno
   instalacji i ponownie otwórz paczkę. Sam instalator nie podpisuje gry.
3. Kliknij podpisz.cmd. Jeśli hasło jest potrzebne, wpisujesz je lokalnie,
   bez widocznych znaków. Wybierz minimum 12 znaków i zapisz je bezpiecznie.
4. Klucz zostanie utworzony w:
   C:\Users\TWÓJ_LOGIN\NeonBlockMaster-Signing\neon-upload.p12
   Istniejący plik nie jest nadpisywany. Kolejne uruchomienie wymaga tego
   samego hasła i używa tego samego klucza. Nie usuwaj go po wysłaniu gry.
5. Podpisany AAB i raport powstaną w folderze wynik:
   neon-block-master-1.4.1-play-signed.aab
   raport-podpisu.json

Zrób prywatną kopię klucza neon-upload.p12 i zapisz hasło w menedżerze haseł.
Nie wysyłaj klucza/hasła na czat, do repozytorium ani jako publicznego ZIP.
Folder wynik zawiera AAB i publiczny raport, a nie klucz. Do Play dodaje się
plik AAB, nie plik P12, ZIP, raport ani dotychczasowy APK debugowy.

Skrypt sprawdza SHA-256 dokładnego AAB, podpis jarsigner i zgodność
certyfikatu z kluczem. Nie zastępuje sprawdzenia publicznej polityki,
app-ads.txt, aktualnej listy Families, konfiguracji AdMob/UMP i formularzy Play.
Pierwsze uruchomienie podpisanego wydania sprawdź przez tor testów wewnętrznych.
Termin publikacji i wymagania testów zależą od konta i decyzji Google.

Ta paczka dotyczy pierwszej publikacji, package com.neonblockmaster.puzzle,
wersja 1.4.1 / code 8. AAB ma produkcyjne ID właściciela. Na urządzeniu
zarejestrowanym jako testowe w AdMob reklama może nadal mieć oznaczenie testowe.
Nie sprawdzaj reklam produkcyjnych przez klikanie własnych reklam.
