# Przygotowanie do pierwszego wydania Google Play

Właściciel ma konto Play Console; ta gra nie była jeszcze wysyłana. Identyfikator pakietu to `com.neonblockmaster.puzzle`, wersja 1.4.1, code 8, Android 7+/ARM64, target API 36. Nie wysłano nic do Play Console ani do weryfikacji Google.

## Dlaczego reklama ma napis „testowa”

Dotychczasowe APK 1.4.1 używa oficjalnych demonstracyjnych jednostek Google. Napis pochodzi z reklamy testowej; samo usunięcie tekstu w grze nie zmienia jej w reklamę zarabiającą. Aplikacja produkcyjna musi korzystać z jednostek właściciela. Konto i aplikacja AdMob muszą też być gotowe do emisji. Google może ograniczać emisję przed sprawdzeniem aplikacji. Nie testuj działania przez klikanie własnych reklam produkcyjnych; do testów używaj jednostek demo lub urządzenia testowego AdMob.

Przygotowana konfiguracja `config/publishing.family.example.json` zawiera zatwierdzone dane Krystian Development, kontakt i trzy ID właściciela: aplikacji, rewarded i interstitial. Jedna jednostka rewarded obsługuje różne jawnie opisane nagrody, w tym 1 Młotek + 2 Zmiany. Nie trzeba tworzyć jednostki dla każdej nagrody.

## Przygotowany AAB z prawdziwymi ID

`neon-block-master-production-candidate-unsigned.aab` jest **niepodpisanym kandydatem do przeglądu, a nie plikiem gotowym do wgrania do Play**. Ma `mode=production` i ID właściciela. Nie zawiera klucza ani podpisu debugowego. Testowy APK pozostaje osobnym plikiem. Raport kontroli paczki jest w `production-artifact-validation.json`; `production-readiness.json` opisuje brakujące kroki. Kontrola artefaktu nie potwierdza publicznego hostingu, emisji reklam ani zatwierdzenia Play.

Polecenie odtwarzające kandydata po przygotowaniu środowiska Android:

```sh
python3 tools/prepare_release.py --config config/publishing.json --export-candidate
python3 tools/verify_production.py --bundle builds/neon-block-master-production-candidate-unsigned.aab --config config/publishing.json --candidate --report builds/production-artifact-validation.json
```

Kandydat dopuszcza przegląd pliku przed zakończeniem weryfikacji Families. Nadal odrzuca testowe/niepoprawne ID, pomieszanych wydawców i nieprawidłowe ustawienia. Zwykłe `--check` oraz podpisany `--build` nadal wymagają rzeczywistej weryfikacji Families. Nie wpisano fikcyjnego `status=verified`.

## Podpisanie na Windows

Dostępna jest [paczka podpisywania na własnym komputerze](WINDOWS-PLAY.md). Zawiera AAB i skrypty, ale nie klucz ani hasło. Umożliwia przygotowanie podpisu przed zakończeniem pozostałych sprawdzeń; nie zastępuje ich ani nie wysyła wydania do Play.

## Co pozostaje przed uploadem

1. **Własny klucz upload.** Nie ma go w środowisku ani w GitHubie. Na pierwsze wydanie można stworzyć nowy, zachować jego kopię i użyć Play App Signing. Skrypt `tools/create_upload_key.sh` tworzy klucz lokalnie, nie nadpisuje istniejącego i nie wypisuje hasła. Klucz/hasło nie powinny trafić do czatu, repozytorium ani publicznych artefaktów.
2. **Strona i polityka dostępne publicznie.** W konfiguracji wpisano oczekiwane adresy `https://kogonowski52-png.github.io/puzle/` oraz `/puzle/privacy.html`; ich działania nie potwierdzono, bo proxy środowiska odrzuca ten host. Samo wpisanie URL nie uruchamia hostingu. W GitHub → Settings → Pages wybierz `gh-pages` / root. Plik `app-ads.txt` musi być pod `https://kogonowski52-png.github.io/app-ads.txt`, co wymaga strony głównej tego hosta lub własnej domeny; plik pod `/puzle/` nie wystarcza. Alternatywnie użyj własnego publicznego hostingu i zaktualizuj URL.
3. **Families oraz ustawienia AdMob/UMP.** Odbiorcy pozostają dziećmi od 3 lat i dorosłymi; wszyscy mają child-directed/under-age/G/npa=1. Sprawdzenie aktualnej oficjalnej listy dla dokładnej wersji Google Mobile Ads 24.9.0 jest zablokowane przez sieć środowiska. W AdMob należy sprawdzić aplikację, jej powiązanie z Play, weryfikację gotowości/app-ads.txt i Privacy & messaging. Nie zmieniono odbiorców na 16+ ani ustawień na reklamy dla dorosłych.

Po weryfikacji SDK zapisz prawdziwy przegląd w `families_review`: `sdk` = `com.google.android.gms:play-services-ads:24.9.0`, `status` = `verified`, `source` = dokładny aktualny URL oficjalnej listy `https://support.google.com/...`. Ta adnotacja ma dokumentować wykonane sprawdzenie, nie je zastępować.

## Podpisanie i finalny build

Na bezpiecznym komputerze lub CI ustaw ścieżkę klucza, alias oraz hasło w zmiennych `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Nie zapisuj hasła w publicznym JSON. Po uzupełnieniu powyższych kroków:

```sh
python3 tools/prepare_release.py --config config/publishing.json --check
python3 tools/prepare_release.py --config config/publishing.json --build
```

Wynik podpisanego procesu to `builds/neon-block-master-production.aab`. Zwykły release-unsigned z wcześniejszych wydań zawiera jednostki demo — samo jego podpisanie nie zmieni reklam na produkcyjne. Gotowy AAB sprawdź przez `tools/verify_production.py` bez flagi `--candidate`.

## Pierwsza wysyłka

Materiały do wklejenia i grafiki są w `neon-block-master-play-console.zip`. Pola formularzy: [PLAY-CONSOLE.md](../store/PLAY-CONSOLE.md). Zacznij od toru testów wewnętrznych, sprawdź reklamę/nagrodę, UMP, brak sieci i raport Pre-launch. Uzupełnij rzeczywiste grupy odbiorców, deklarację reklam, IARC i Bezpieczeństwo danych. Wymagania zamkniętych testów zależą od konta i aktualnych reguł widocznych w panelu. Konta, tożsamości i akceptacji warunków nie zastępuje AAB; nic nie zostało automatycznie zatwierdzone przez Google.
