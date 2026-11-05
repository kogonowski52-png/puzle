# Wydanie 1.3.0 — reklamy dla wskazanej grupy odbiorców

Cel: gra dla dzieci od 3 lat i dorosłych **z reklamami**. Poprzedni wariant 1.2 bez reklam nie jest docelową realizacją tego celu.

## Co zmieniono

Zastąpiono Google Next-Gen Ads 1.4.0 klasycznym **Google Mobile Ads SDK 24.9.0**, przez oficjalną integrację **Poing Studios 4.3.1** i oficjalne binaria dla **Godot 4.6.3**. Kod źródłowy i licencje znajdują się w projekcie. Nie są to atrapowe reklamy ani edytorowe mocki; aplikacja uruchamia adapter tylko po wykryciu natywnego singletonu Android.

Wszystkich graczy traktujemy jednakowo, z restrykcyjnym profilem:

- `tag_for_child_directed_treatment = TRUE` przed `MobileAds.initialize`.
- `tag_for_under_age_of_consent = TRUE`.
- `max_ad_content_rating = G`.
- `npa=1` na każdym żądaniu (niepersonalizowane reklamy).
- Usunięte uprawnienia AD_ID, Privacy Sandbox advertising/topics/attribution i uprawnienia stanu telefonu; opóźniona inicjalizacja pomiaru aplikacji.
- Nie pytamy o datę urodzenia i nie można otrzymać bardziej liberalnych reklam przez wybór starszej grupy.
- Rewarded: monety, PLASMA, podwojenie monet z rozgrywki i jedna dodatkowa szansa. Nagroda wyłącznie z SDK earned-reward; nie za kliknięcie reklamy. Gra nadal działa bez internetu/reklamy.
- Interstitial: tylko pomiędzy zakończonymi rozgrywkami, co trzeci restart i nie częściej niż co 180 sekund. Nigdy podczas przeciągania.

## Jak testować APK

APK z gałęzi `apk-download` ma **oficjalne jednostki testowe Google**, nie jednostki zarabiające. Jest to celowe, aby właściciel nie generował nieprawidłowego ruchu na własnych reklamach. App ID i ad units z konta użytkownika są zapisane osobno dla przyszłego wydania produkcyjnego.

1. Zainstaluj aktualizację 1.3.0 na Androidzie i połącz telefon z internetem.
2. Otwórz Ustawienia → **Reklamy testowe — status**. Na komputerze moduł Android nie jest dostępny.
3. Poczekaj na załadowanie reklamy, wejdź w sklep/NEON LAB i wybierz przycisk z nagrodą. Zamknięcie przed earned event nie powinno przyznawać nagrody; pełne potwierdzenie SDK przyznaje ją raz.
4. Sprawdź powrót do gry, dźwięk, brak blokowania przy braku sieci i ponawianie po połączeniu. Nie klikaj własnych reklam produkcyjnych.

Testowe żądania używają restrykcyjnego profilu bez formularza zgody dorosłego. W ścieżce produkcyjnej UMP otrzymuje under-age i błąd/nierozwiązany wymóg zgody pozostawia reklamy niezaładowane. Nie traktujemy formularza dorosłego jako zgody trzylatka. Nie ma przełącznika personalizacji.

## Czego nie potwierdzono

Nie wykonano emisji reklamy na fizycznym telefonie w tej maszynie, więc kompilacja/parametry SDK nie są dowodem wypełnienia reklam. Sprawdzenie to musi wykonać właściciel na urządzeniu.

Dostęp do aktualnej oficjalnej listy **Families Self-Certified Ads SDKs** nadal jest blokowany przez sieć środowiska. Wybrano klasyczny SDK Google i ustawienia dla dzieci, ale nie deklarujemy aktualnej certyfikacji tej konkretnej wersji ani zatwierdzenia aplikacji przez Google Play. Zmiana biblioteki i flag nie zastępuje tej weryfikacji. Do produkcyjnego pipeline dla mixed/children wymagany jest zapis sprawdzenia dokładnej wersji, ze źródłem oficjalnym; nie uzupełniono go fikcyjnie.

Dodatkowo potrzebne są działający publiczny URL polityki, prawdziwe deklaracje grup odbiorców i IARC, konfiguracja UMP/AdMob, własny klucz upload i testy urządzenia. Ocena 3+ jest oceną treści ustalaną przez IARC, nie podmieniamy docelowej grupy na 16+.

## Integracja i licencje

- Poing 4.3.1: commit `a20aec0e9a4b323161a842dded6e76702d783ee1`.
- Oficjalny plik `poing-godot-admob-android-v4.6.3.zip` z wydania v4.3.1.
- Google dependency: `com.google.android.gms:play-services-ads:24.9.0`.
- UMP: `com.google.android.ump:user-messaging-platform:4.0.0`.
- Brak mediacji innych sieci.
- Niektóre nieużywane fonty upstream w katalogu edytorowych zasobów zostały zastąpione licencjonowanym DejaVu Sans; gra używa własnego dołączonego fontu DejaVu.
