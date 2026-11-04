# Wydanie rodzinne 1.2.0 — aktualny stan

Użytkownik wybrał odbiorców **dzieci i dorośli**, wydawcę **Krystian Development** i publiczny kontakt **kogonowski52@gmail.com**. „3+” jest propozycją oceny treści; właściwą ocenę wyznacza ankieta IARC. Nie jest to odpowiedź na pytanie o docelowe grupy wieku.

## Co działa teraz

- Gra 1.2.0 działa offline bez reklam i zakupów. Nie pyta o wiek, ponieważ w tym wariancie byłoby to zbędne.
- Natywny Google Ads/Poing SDK jest wyłączony w eksporcie, a nie tylko ukryty w interfejsie. APK nie ma Internet/AD_ID; jedynym zadeklarowanym uprawnieniem jest wibracja. Sprawdzono brak klas reklamowych w DEX i metadanych reklam w manifeście.
- Motywy kupuje się za monety z wyzwań, rekordów i codziennych uruchomień. Starszy postęp, monety i odblokowania są zachowane. Oferty oglądania reklam są ukryte.
- Przygotowano neutralny ekran wieku dla ewentualnej późniejszej ścieżki reklamowej: równe przyciski, bez korzyści za wybór starszej grupy; nieznany i młodszy wiek nie uruchamia SDK. W obecnym wydaniu ekran jest pomijany.
- Konfiguracja `mixed`/`children` nie może włączyć dotychczasowego SDK przez samą zmianę flagi. Jego zgodności z aktualnymi wymaganiami Families nie zweryfikowano; nie twierdzimy, że SDK jest certyfikowane albo niecertyfikowane.

## Strona

Gotowe pliki są w `release-site/` oraz na gałęzi `gh-pages` repozytorium `kogonowski52-png/puzle`. Zawierają publiczną nazwę i kontakt za wyraźną zgodą użytkownika.

Aby włączyć stronę projektu, otwórz:

https://github.com/kogonowski52-png/puzle/settings/pages

Wybierz **Deploy from a branch → gh-pages → /(root) → Save**. Poczekaj na status wdrożenia i otwórz link pokazany przez GitHuba. Przewidywany adres to `https://kogonowski52-png.github.io/puzle/`, a polityka `https://kogonowski52-png.github.io/puzle/privacy.html`. Są to adresy oczekiwane, nie potwierdzenie, że hosting już działa. Dopiero po sprawdzeniu publicznego dostępu wpisz je do `config/publishing.json`. Jeśli odtwarzasz projekt ze źródeł, skopiuj najpierw `config/publishing.family.example.json` do `config/publishing.json` — zawiera zatwierdzone publiczne dane wydawcy i AdMob, bez klucza podpisu.

Plik `app-ads.txt` jest przygotowany z prawdziwym publisher ID. Dla przyszłego wariantu z reklamami Google szuka go pod głównym hostem, czyli `https://kogonowski52-png.github.io/app-ads.txt`, a nie tylko `/puzle/app-ads.txt`. To może wymagać strony użytkownika w repozytorium `kogonowski52-png.github.io` lub własnej domeny. W obecnej grze bez reklam ten krok nie służy do uruchamiania emisji.

## Co blokuje prawdziwe reklamy

W środowisku zablokowany jest dostęp do aktualnych stron `support.google.com`, `developers.google.com`, `developer.android.com` oraz API GitHuba. W szkicu konfiguracji zapisano potrzebne domeny, ale nie zastosowano ich do działającej maszyny. Potrzebne jest przejrzenie/zapisanie zmian w ustawieniach środowiska i publikacja konfiguracji. Nie obchodzimy tej blokady alternatywną trasą.

Po przywróceniu dostępu należy sprawdzić aktualną listę **Families Self-Certified Ads SDKs** i wspierane wersje, dobrać zgodną integrację Godot (w razie potrzeby wymienić obecną), wdrożyć właściwe flagi child-directed/under-age, maksymalną klasyfikację reklam i wymagania dla reklam kierowanych do dzieci/osób o nieustalonym wieku. Nie należy traktować zwykłego formularza zgody dorosłego jako zgody dziecka ani wymuszać personalizacji za nagrodę. Dalsze reguły dotyczące formatu i prezentacji reklam trzeba sprawdzić w aktualnej polityce.

Do tego potrzebne są testy na prawdziwym Androidzie, skonfigurowane UMP/AdMob i prawdziwe deklaracje Play Console. Obecna publikacja plików lub brak SDK nie oznacza automatycznego zatwierdzenia przez Google Play.

## Publikacja wariantu bez reklam

Można przygotować podpisany AAB dla wersji bez reklam po uzupełnieniu działających publicznych URL i dostarczeniu własnego klucza upload przez bezpieczne zmienne lokalne/CI. Klucz i hasło nie mogą trafić do czatu ani repozytorium. W formularzach Play opisuj faktyczne wydanie 1.2.0: bez reklam/zakupów i bez reklamowego SDK, z lokalnym postępem. Wypełnij zgodnie z prawdą grupy wieku, IARC i Data safety; nadal potrzebne są testy urządzenia i bieżące wymagania Play.
