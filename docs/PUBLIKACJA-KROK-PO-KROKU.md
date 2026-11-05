# Publikacja i reklamy — wydanie 1.3.1

## Co już przygotowano

Gra dla dzieci od 3 lat i dorosłych, klasyczny Google Mobile Ads 24.9.0 / Poing 4.3.1, jednolity profil child-directed/under-age/G/npa. APK do testowania korzysta z oficjalnych jednostek Google i nie zarabia. Szczegóły: [ADS-1.3.md](ADS-1.3.md).

Dane zapisano: **Krystian Development**, **kogonowski52@gmail.com**, `audience=mixed`, `ads_enabled=true`, `ad_profile=family_contextual`, `ad_sdk=gma_classic_24.9.0`. Wszystkie trzy produkcyjne ID AdMob od właściciela są w lokalnym `config/publishing.json` i jawnym szablonie `config/publishing.family.example.json`. Nie trzeba zakładać kolejnych jednostek dla każdej nagrody.

## 1. Sprawdź APK na telefonie

Pobierz `neon-block-master-debug.apk` z gałęzi `apk-download`, wybierając **Download raw**. Telefon musi mieć Android 7+/ARM64. Zainstaluj aktualizację, włącz internet, otwórz Ustawienia → **Reklamy testowe — status**, potem sklep/NEON LAB. Sprawdź ukończenie reklamy, wcześniejsze zamknięcie i ponowne uruchomienie. Pełna procedura: [TESTING.md](TESTING.md). Nie klikaj własnych reklam produkcyjnych.

## 2. Włącz publiczną stronę i politykę

Pliki są przygotowane w gałęzi `gh-pages`: index.html, privacy.html, app-ads.txt i .nojekyll. Nazwa i e-mail zostały zatwierdzone do publikacji. W GitHub otwórz:

https://github.com/kogonowski52-png/puzle/settings/pages

Wybierz **Deploy from a branch → gh-pages → /(root) → Save**. Jeżeli plan/widoczność repozytorium nie pozwala na Pages, potrzebny jest obsługiwany plan lub publiczny hosting. Sam push gałęzi nie potwierdza działającej strony. Sprawdź anonimowo na telefonie oczekiwane adresy:

- https://kogonowski52-png.github.io/puzle/
- https://kogonowski52-png.github.io/puzle/privacy.html

Dopiero po sprawdzeniu wpisz je w `website_url` i `privacy_url`. Polityka opisuje wersję testową 1.3.1; przed produkcją wygeneruj ją ponownie z produkcyjnej konfiguracji.

**app-ads.txt musi znajdować się w katalogu głównym hosta**, czyli dla tego hosta https://kogonowski52-png.github.io/app-ads.txt, nie tylko `/puzle/app-ads.txt`. Potrzebna będzie strona użytkownika w repozytorium `kogonowski52-png.github.io` lub własna domena. Tego hostingu nie potwierdzono. Przygotowana linia zawiera prawdziwe `pub-5988667220268461`; sprawdź wykrycie pliku w AdMob.

## 3. Potwierdź Families, UMP i konto AdMob

Zweryfikuj aktualną oficjalną listę Families Self-Certified Ads SDKs dla dokładnej wersji Google Mobile Ads 24.9.0. Środowisko blokuje dokumentację Google; nie oznaczono weryfikacji fikcyjnie. Ustawienia dla dzieci nie są certyfikatem ani zatwierdzeniem Play. Pipeline wymaga `families_review` zgodnego ze schematem w `tools/prepare_release.py` i oficjalnym źródłem.

W AdMob sprawdź powiązanie aplikacji, stan konta/aplikacji, płatności i **Privacy & messaging**. Skonfiguruj wymagane wiadomości, regiony i politykę odpowiednio do faktycznych odbiorców. Kod produkcyjny używa UMP under-age; nie wymusza zgody dorosłego na dziecku. Przetestuj tę ścieżkę na urządzeniu przed dystrybucją. Weryfikacja konta i dostępność reklam zależą od Google; samo wpisanie ID nie gwarantuje emisji.

## 4. Własny klucz upload i produkcyjny AAB

Klucz i hasło muszą zostać u właściciela, poza czatem i Git. Jeżeli aplikacja ma klucz, użyj istniejącego. Nowy można utworzyć lokalnie:

```sh
./tools/create_upload_key.sh /bezpieczna/sciezka/neon-upload.p12
```

Skrypt pyta o hasło, nie nadpisuje pliku i tworzy alias `upload`. Zrób bezpieczną kopię. Ustaw lokalnie/CI:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` — ścieżka do klucza.
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER` — alias, zwykle `upload`.
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` — bezpieczny sekret.

Po uzupełnieniu URL i rzeczywistej weryfikacji Families:

```sh
python3 tools/prepare_release.py --config config/publishing.json --check
python3 tools/prepare_release.py --config config/publishing.json --website release-site
python3 tools/prepare_release.py --config config/publishing.json --build
```

Pipeline odrzuca niekompletną konfigurację, testowe ID i znany klucz debugowy, eksportuje **Android Production**, sprawdza podpis i przywraca konfigurację testową. Wynik: `builds/neon-block-master-production.aab`. Obecny plik release-unsigned.aab wymaga podpisania i nadal ma testową konfigurację; samo podpisanie go nie uruchomi zarabiania.

## 5. Google Play

Konto Play, potwierdzenie tożsamości, opłaty i akceptacja warunków należą do właściciela. Package: `com.neonblockmaster.puzzle`; przed pierwszym uploadem potwierdź, że chcesz go zachować. Aktualny version code 5, wersja 1.3.1, target API 36, min API 24, ARM64. Włącz Play App Signing i sprawdź aktualne wymagania panelu.

Materiały w `store/`: opisy PL/EN, ikona 512×512, feature graphic 1024×500, sześć rzeczywistych zrzutów. Usuń z opisu sklepu notę roboczą dla wydawcy. Wpisz kontakt i działającą politykę, zaznacz **zawiera reklamy**, wybierz prawdziwe grupy wieku obejmujące dzieci i dorosłych. Ocena **3+** jest ustalana przez IARC, nie zastępuje deklaracji odbiorców. Nie zmieniaj grupy na 16+ w celu obejścia wymagań.

Uzupełnij IARC, dostęp do aplikacji (bez logowania), kraje i Bezpieczeństwo danych według [DATA-SAFETY.md](DATA-SAFETY.md) oraz aktualnych danych SDK. Nie deklaruj braku zbierania danych tylko dlatego, że zapis gry jest lokalny.

Zacznij od testów wewnętrznych, sprawdź raport Pre-launch i Android Vitals. Jeżeli konto wymaga testów zamkniętych, spełnij aktualne warunki widoczne w panelu. Dopiero potem wyślij wydanie do weryfikacji Google. Żaden lokalny test nie zastępuje jej zatwierdzenia.
