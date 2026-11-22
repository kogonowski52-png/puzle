# app-ads.txt dla Krystian Development

Treść pliku potwierdzona na zrzucie właściciela z AdMob:

```text
google.com, pub-5988667220268461, DIRECT, f08c47fec0942fa0
```

Dla witryny `https://kogonowski52-png.github.io/puzle/` Google szuka pliku pod:

**https://kogonowski52-png.github.io/app-ads.txt**

Sam plik na gałęzi gh-pages projektu puzle publikuje się pod `/puzle/app-ads.txt`, co nie wystarcza do głównego adresu hosta. Plik jest przygotowany; jego publicznej dostępności nie potwierdzono.

## Gotowa paczka całej strony

`neon-block-master-github-site.zip` zawiera folder `do-wgrania` z plikiem app-ads.txt w głównym katalogu oraz stroną gry i polityką pod `/puzle/`. Rozpakuj ZIP, a w repozytorium strony głównej wybierz **Add file → Upload files** i wgraj zawartość tego folderu (nie sam ZIP). Następnie włącz Pages jak w punkcie 3 poniżej. Dzięki temu zachowane są oba adresy wpisane w aplikacji; nie trzeba zmieniać jej konfiguracji. Wgrywając do istniejącego repozytorium, sprawdź ewentualne zastępowane pliki.

## W panelu GitHuba

1. Otwórz repozytorium **kogonowski52-png.github.io** na koncie **kogonowski52-png**. Jeśli go nie ma, utwórz publiczne repozytorium o dokładnie tej nazwie; możesz dodać README, aby od razu utworzyć główną gałąź.
2. Wybierz **Add file → Create new file**, nazwij plik **app-ads.txt**, wklej powyższą jedną linię i zatwierdź commit.
3. W **Settings → Pages** wybierz **Deploy from a branch**, główną gałąź z tym plikiem (zwykle main), **/(root)** i zapisz.
4. Po wdrożeniu otwórz główny adres app-ads.txt bez logowania. Powinna być widoczna ta jedna linia, nie strona GitHuba ani podgląd repozytorium.
5. W danych kontaktowych karty aplikacji Google Play ustaw pole **Witryna** na `https://kogonowski52-png.github.io/puzle/`. To pole nie jest automatycznie uzupełniane przez konfigurację AAB. Polityka prywatności ma osobny adres `/puzle/privacy.html`.
6. Wróć do AdMob i sprawdź stan pliku. Google zaznacza, że indeksowanie może potrwać co najmniej 24 godziny; nie gwarantujemy zatwierdzenia o konkretnej godzinie. Działający plik i zgodna domena nie zastępują pozostałych kontroli konta/aplikacji.

## Ograniczenia środowiska

Odczyt repozytorium `kogonowski52-png/kogonowski52-png.github.io` przez dostępne połączenie Git zwrócił `Repository not found`. Nie ustalono, czy repozytorium nie istnieje, czy brakuje dostępu. Bieżąca sieć blokuje również hosta GitHub Pages i API GitHuba. Nie opublikowano ani nie zweryfikowano tego pliku w głównym katalogu hosta z tego środowiska. Użytkownik może wykonać powyższe kroki w swoim panelu; istniejących plików nie trzeba usuwać.
