# Android i publikacja — 1.3.1

Aktualny wariant: dzieci od 3 lat i dorośli, z klasycznym Google Mobile Ads i oficjalnymi reklamami testowymi. [Instrukcja wydawcy](PUBLIKACJA-KROK-PO-KROKU.md), [stan reklam](ADS-1.3.md).

Identyfikatory i tryb są w `assets/app_config.json`; produkcyjny plik tworzy `tools/prepare_release.py` z lokalnego `config/publishing.json` i przywraca testowy po eksporcie.

## Narzędzia i eksport

Zweryfikowany silnik: Godot 4.6.3 official (`7d41c59c4`). Zainstaluj oficjalne szablony eksportu 4.6.3. SHA-512 archiwum użytego w chmurze zweryfikowano względem `SHA512-SUMS.txt` z oficjalnego wydania Godot.

Wymagany pełny JDK (z `javac`, nie samo JRE); w tej maszynie JDK 21.0.12.1. Ustaw jego katalog w **Editor Settings → Export → Android → Java SDK Path**. Oficjalny szablon Godot 4.6.3 używa Gradle 8.11.1, Android Gradle Plugin 8.6.1, compile/target SDK **36**, build-tools **36.1.0**. Starsza strona dokumentacji gałęzi 4.6 podawała API 35 — do budowy używamy wartości z faktycznie pobranego szablonu 4.6.3.

Android SDK:

```sh
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.1.0"
```

Wskaż SDK w ustawieniach edytora. Zainstaluj szablon: **Project → Install Android Build Template**. Katalog `android/build/` jest generowany i ignorowany przez Git. Zaznaczone `Use Gradle Build` jest konieczne dla natywnych reklam. Nie trzeba kompilować silnika ani bibliotek C++/NDK: używamy oficjalnych gotowych bibliotek ARM64.

Presety w `export_presets.cfg`:

- **Android APK** → podpisany debug APK do instalacji.
- **Android AAB** → debug AAB do testowania bundletool.
- **Android AAB unsigned** → release AAB bez podpisu; wymaga podpisania własnym kluczem przed uploadem.

Buduj z katalogu projektu poleceniami z README. Przy własnym wydaniu skopiuj preset release, włącz `package/signed`, ustaw keystore bez dodawania go ani hasła do Git. Godot obsługuje `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`; dostarczaj je lokalnie lub przez bezpieczny system CI. Nie stosuj klucza debugowego jako upload key.

Min SDK 24, ARM64, tryb pionowy, OpenGL ES 3.0 Compatibility. Uprawnienia: Internet, stan sieci, wibracje; dodatkowe uprawnienia zadeklarowane przez SDK trzeba ocenić w scalonym manifeście. `allowBackup=false`. Nie ma kont ani serwerów gry.

## Reklamy

Dołączono Poing Studios **4.3.1**, commit `a20aec0e9a4b323161a842dded6e76702d783ee1`, oficjalne AAR dla Godot 4.6.3, natywne źródła Kotlin i klasyczny Google Mobile Ads **24.9.0**, UMP **4.0.0**. Nie używamy Next-Gen SDK ani mediacji innych sieci.

Własny eksporter `addons/neon_ads/` dodaje AAR, zależności i App ID oraz usuwa uprawnienia AD_ID, telefonu i reklamowe Privacy Sandbox. Desktop nie ładuje natywnego adaptera i nie generuje fikcyjnych nagród.

Oficjalne testowe ID Google używane przez APK:

- App: `ca-app-pub-3940256099942544~3347511713`.
- Rewarded: `ca-app-pub-3940256099942544/5224354917`.
- Interstitial: `ca-app-pub-3940256099942544/1033173712`.

Przed inicjalizacją: child-directed TRUE, under-age TRUE, G; na każdym żądaniu npa=1. Wszyscy mają ten sam profil, bez wyboru starszego wieku. Testowe ID nie zarabiają. W produkcji UMP under-age jest aktualizowane przed inicjalizacją; błąd lub nierozwiązany wymóg zgody nie pozwala ładować reklam. Nie pokazujemy dziecku formularza zgody dorosłego. Nie ma przełącznika personalizacji.

Rewarded przyznaje bonus tylko z earned-reward SDK, raz. Interstitial: co trzeci restart po zakończonej grze i minimum 180 sekund; nigdy podczas przeciągania. Nie ma zakupów; Neon Coins są lokalną walutą bez wartości pieniężnej.

## Przed Google Play — rzeczywiste ograniczenia

**To nie jest deklaracja bieżącej zgodności ani akceptacji sklepu.** 2 listopada 2026 r. próba dostępu do aktualnej strony wymagań docelowego API zakończyła się HTTP 403 w polityce sieci środowiska. Sprawdź aktualne wymagania bezpośrednio w Play Console oraz na oficjalnych stronach:

- https://support.google.com/googleplay/android-developer/answer/11926878 — docelowy poziom API.
- https://developer.android.com/guide/practices/page-sizes — rozmiar stron pamięci 16 KB.
- https://support.google.com/googleplay/android-developer/answer/10787469 — Bezpieczeństwo danych.
- https://developers.google.com/admob/android/privacy — zgody i UMP.

Target 36 jest faktyczną konfiguracją projektu; sam target nie potwierdza pozostałych zasad. Przed wysyłką:

1. Wybierz ostateczny unikalny package ID (obecnie `com.neonblockmaster.puzzle`) i zwiększ version code przy kolejnych wydaniach.
2. Podpisz AAB własnym upload key i skonfiguruj Play App Signing.
3. Sprawdź wymóg target API, 64-bit, 16 KB (także wszystkie natywne biblioteki SDK), ostrzeżenia Android Vitals i raport testów wstępnych na bieżącym Play Console.
4. Dane wydawcy są w `store/privacy-family.html` i `release-site/privacy.html`; opublikuj politykę pod publicznym HTTPS i wpisz URL w Play oraz UMP.
5. Ustaw produkcyjne AdMob ID, wiadomości zgód, grupę wiekową i deklarację reklam. Wypełnij Data safety zgodnie z faktycznie dołączonym SDK — nie zaznaczaj „brak zbierania danych” dla wersji z AdMob bez analizy dokumentacji Google.
6. Uzupełnij IARC/content rating, dostępność krajów, nazwę wydawcy oraz kontakt sklepu. Opisy i grafiki są w `store/`.
7. Wykonaj testy na urządzeniach według `TESTING.md`, w tym UMP w EOG, brak sieci, reklamy nagradzane i 16 KB. W razie obowiązku przeprowadź wymagane testy zamknięte dla konta deweloperskiego.

Gra nie zawiera płatności. Waluta jest wirtualna, offline, bez wymiany pieniężnej. Lokalny zegar i zapis nie są mechanizmem anty-cheat ani ochroną kryptograficzną.
