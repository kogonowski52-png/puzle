# Testy na Androidzie

Testy automatyczne uruchamiaj przed eksportem (`./tools/test.sh`). Poniższych testów nie opisuj jako wykonanych, dopóki nie przeprowadzisz ich na urządzeniu. Wersja debug używa wyłącznie reklam testowych.

## Instalacja

Włącz debugowanie USB i zatwierdź komputer na telefonie:

```sh
adb devices
adb install -r builds/neon-block-master-debug.apk
adb shell monkey -p com.neonblockmaster.puzzle 1
```

`adb install` innego podpisu dla istniejącego package ID wymaga odinstalowania poprzedniej aplikacji, co może usunąć jej dane. Nie odinstalowuj jej bez zabezpieczenia potrzebnego postępu.

## Rozgrywka i cykl aplikacji

1. Wybierz Classic. Chwyć figurę w dowolnym miejscu jej pola, przesuń nad planszę. Podgląd powinien być zielony dla wolnych pól i czerwony przy kolizji. Puść poza planszą — figura wraca do ręki, wynik się nie zmienia. Drugim palcem nie wolno przejąć aktywnej figury.
2. Wypełnij rząd, kolumnę i obie linie jednocześnie. Punkt przecięcia znika raz, premia uwzględnia obie linie. Dwa ruchy z linią pod rząd zwiększają combo; ruch bez linii je resetuje.
3. Zużyj trzy figury. Pojawia się nowa ręka. Przy końcu sprawdź, że żadna pozostała figura nie pasuje w żadne miejsce.
4. Sprawdź pauzę i przycisk Wstecz Android, powrót do menu i wznowienie. Przerwij przeciąganie przez przejście w tło — nie może pozostać „przyklejona” figura.
5. W Time Attack sprawdź 180 sekund, zatrzymanie czasu w pauzie i w tle, bonus 3 s/linię za ≥2 linie (max 15 s), koniec przy zerze. Zmiana ekranu nie może kontynuować aktywnego timera w tle.
6. Po kilku ruchach zamknij proces, otwórz ponownie i wznów. Plansza, figury, wynik i RNG pozostają zachowane. Timer jest zapisywany co 5 sekund aktywnej gry i przy ruchu/pauzie; nagłe zabicie procesu może cofnąć najwyżej ostatni interwał timera.
7. Daily: tego samego dnia początkowe figury i cel są takie same. Pierwsze ukończenie daje 80 monet, kolejne nie. Kalendarz oznacza ukończony dzień. Data oparta na urządzeniu, bez odporności na przestawianie zegara.
8. Sprawdź 15 monet za pierwszy start dnia, 10 za nowy rekord, zakup konkretnego motywu/efektu i ponowny darmowy wybór posiadanego. Brak środków nie może zmniejszyć salda.
9. Przełącz PL/EN, muzykę, efekty i wibracje; uruchom grę ponownie. Muzyka nie powinna grać po przejściu aplikacji w tło.

## Sieć, UMP i reklamy

- W trybie samolotowym uruchom świeżą instalację, zagraj i zapisz postęp. Nie może być blokującego spinnera ani nagrody za niedostępną reklamę.
- APK testowy: Ustawienia → Reklamy testowe — status pokazuje dostępność natywnego modułu, ładowanie i gotowość. Profil dla dzieci jest stały, bez formularza personalizacji. Oddzielnie przed produkcją sprawdź UMP under-age na własnej konfiguracji AdMob: błąd lub nierozwiązana zgoda nie pozwalają ładować reklam; nie pokazuj dziecku formularza dorosłego.
- Przycisk z nagrodą aktywuje się dopiero po rzeczywistym załadowaniu SDK. Zamknij reklamę wcześniej — brak nagrody. Obejrzyj do momentu earned-reward — dokładnie 25 monet albo jedna dodatkowa szansa.
- Druga szansa czyści środkowe cztery rzędy i losuje nową rękę; nie jest oferowana w Daily ani po upływie czasu. Nie może być użyta dwa razy w jednej grze.
- Reklamy nagradzane: min 60 s między próbami. Interstitial: przy restarcie po wyniku co trzeci raz i min 180 s, nigdy podczas przeciągania ani w trakcie gry. Brak załadowanej reklamy pomija wyświetlenie.
- Testuj powrót po reklamie i po otwarciu systemowego okna; gra powinna pozostawać bezpiecznie w pauzie, jeżeli utraciła fokus.

## Urządzenia i wydajność

Sprawdź co najmniej mały telefon 360×640 dp, ekran 20:9 z wycięciem oraz tablet. Pionowy układ mieści się w bezpiecznym obszarze, figury nie są pod paskiem nawigacyjnym. Wykonaj test na fizycznym ARM64 ze stronami pamięci 4 KB oraz 16 KB lub odpowiednim emulatorem.

Mierz **na telefonie**, bez debugera: 10 minut gry, przeciąganie, 16 linii na raz i intensywne combo. Cel 60 FPS (budżet ~16,7 ms); obserwuj `adb shell dumpsys gfxinfo com.neonblockmaster.puzzle`, profiler Godot i Android Studio (pamięć/PSS). `gfxinfo` może nie obejmować całej pracy renderera Godot, dlatego korzystaj też z profilera silnika. Pamięć nie powinna rosnąć po 100 przejściach menu–gra. Sprawdź brak ANR, nieprawidłowych procesów w tle i wycieków AudioStream po zamknięciu.

## AAB

Użyj oficjalnego bundletool: `validate --bundle=...`, utwórz zestaw APK z debug lub własnym podpisem i zainstaluj zestaw na urządzeniu. Sprawdź raport Pre-launch w Play Console dla finalnego podpisanego wydania. Debug AAB i unsigned release AAB nie są gotowym podpisanym wydaniem produkcyjnym.


## Nagrody 1.1.0

W NEON LAB upewnij się, że każdy pełny earned-reward daje jeden z trzech ładunków, stan jest zachowany po restarcie, trzecia reklama odblokowuje PLASMA, a czwarta nie jest oferowana. Zamknięcie przed earned event nie przyznaje ładunku. Motyw można odblokować także za 240 monet bez reklam.

Po ukończeniu wyzwania lub pobiciu rekordu oferta podwojenia musi pokazywać konkretną dodatkową liczbę monet. Jedna reklama wypłaca je raz; zduplikowany lub stary callback nie może przyznać drugiej nagrody. Wynik punktowy pozostaje bez zmian. Sprawdź powrót sieci i ponowne ładowanie oraz odświeżanie reklam przed godziną od załadowania.


Wszyscy gracze używają tego samego profilu child-directed/under-age/G/npa, z audience=mixed. Zmiana wieku nie może poluzować flag. Wariant testowy i produkcyjny UMP sprawdzaj zgodnie z [ADS-1.3.md](ADS-1.3.md).
