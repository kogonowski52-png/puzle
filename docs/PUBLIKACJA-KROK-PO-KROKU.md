# Publikacja i prawdziwe reklamy — co zrobić po kolei

**Aktualizacja 1.2.0:** wybrano dzieci i dorosłych. Używaj `audience=mixed`, `ads_enabled=false`; produkcja tej wersji nie korzysta z reklamowego SDK. Dane wydawcy zostały już zapisane. [Aktualny stan i włączenie strony](FAMILY-EDITION.md). Poniższy opis uruchamiania reklam wymaga najpierw sprawdzonego SDK zgodnego z Families.


Kod i paczki testowe nie zakładają za Ciebie konta Google Play ani AdMob. Nie znamy jeszcze nazwy publicznego wydawcy, kontaktu, grupy odbiorców i Twoich identyfikatorów reklam. Nie wpisuj tu haseł, numerów dokumentów, danych płatniczych ani prywatnego klucza.

## 1. Konta i nazwa aplikacji

Załóż/otwórz Google Play Console i Google AdMob na własnym koncie. Dokończ wymagane przez Google potwierdzenie tożsamości i profil płatniczy. Ewentualną opłatę za rejestrację Play opłaca właściciel konta. Przygotowany package ID to `com.neonblockmaster.puzzle`; przed pierwszym uploadem upewnij się, że chcesz go zachować, ponieważ późniejsza zmiana tworzy inną aplikację. Tytuł sklepu: **Neon Block Master – Puzzle**.

Określ rzeczywistą grupę odbiorców. Obecny pipeline produkcyjny obsługuje **16+ albo 18+**. To wybór kierowania aplikacji, nie przyznana ocena IARC. Jeżeli gra ma być kierowana do młodszych albo mieszanych grup, nie zaznaczaj nieprawdziwego wieku: najpierw trzeba wdrożyć właściwe rozwiązanie wieku/zgód i przeanalizować zasady Families. Do czasu wyboru produkcja jest blokowana; testowa gra działa dalej.

## 2. Trzy identyfikatory AdMob

W AdMob dodaj aplikację Android z właściwym package ID. Jeżeli nie ma jej jeszcze w sklepie, wybierz odpowiednią opcję aplikacji nieopublikowanej, a po publikacji połącz z listingiem. Utwórz dwie jednostki:

- **Rewarded** — jedna jednostka obsługuje nagrody w sklepie, Neon Lab, podwojenie monet i dodatkową szansę.
- **Interstitial** — naturalne przerwy po ukończeniu gry.

Potrzebne dane są publicznymi identyfikatorami, nie hasłami:

- App ID, np. format `ca-app-pub-…~…`.
- Rewarded Ad Unit ID, format `ca-app-pub-…/…`.
- Interstitial Ad Unit ID, format `ca-app-pub-…/…`.

Nie wybieraj reklam bez nagrody ani rewarded interstitial zamiast zwykłego Rewarded. Obecna integracja używa zwykłego, dobrowolnego Rewarded i nie nagradza kliknięcia reklamy. Sama konfiguracja identyfikatorów nie gwarantuje emisji ani zarobku: konto/aplikacja może wymagać weryfikacji, a wypełnienie reklam zależy od Google.

## 3. Prywatność i strona

Skopiuj `config/publishing.example.json` do `config/publishing.json`. Uzupełnij publiczną nazwę wydawcy, kontaktowy e-mail, docelową grupę, publiczny URL polityki HTTPS, URL strony dewelopera i identyfikatory z kroku 2.

```sh
python3 tools/prepare_release.py --config config/publishing.json --check
python3 tools/prepare_release.py --config config/publishing.json --website release-site
```

Po poprawnej walidacji powstanie katalog `release-site/` z `index.html`, `privacy.html`, `app-ads.txt`. Sprawdź tekst polityki: to dokument dostosowany do konfiguracji, nie automatyczne potwierdzenie zgodności prawnej. Opublikuj go na swojej stronie HTTPS bez logowania. Następnie otwórz URL na telefonie w trybie prywatnym.

**app-ads.txt musi być w katalogu głównym hosta strony dewelopera**, np. `https://twoja-domena.pl/app-ads.txt`, a nie w podfolderze `/puzle/app-ads.txt`. Repozytorium lub surowy plik GitHub nie oznacza działającej strony GitHub Pages. Strona projektu `uzytkownik.github.io/puzle/` zwykle wymaga dodatkowego pliku na stronie głównej `uzytkownik.github.io/app-ads.txt`. W Play wpisz właściwą stronę dewelopera; w AdMob sprawdź status wykrywania app-ads.txt. Nie wpisuj testowego publisher ID.

## 4. Google UMP

W AdMob otwórz **Privacy & messaging** i skonfiguruj/publikuj wiadomości odpowiednie dla docelowych regionów i dostawców. Dodaj URL polityki. Wybory personalizacji i dostępność formularza są obsługiwane przez Google UMP, a nie przez własny przycisk „akceptuj wszystko”. Zmiana zgód jest dostępna w ustawieniach gry; istniejące reklamy są unieważniane przy zmianie preferencji.

Najpierw przetestuj na swoim urządzeniu z testowymi jednostkami i ustawieniami testowymi UMP z dokumentacji właściwej wersji SDK. Nie klikaj własnych reklam produkcyjnych i nie proś graczy o klikanie. Nagrody dotyczą obejrzenia reklamy zgodnie z callbackiem SDK, a nie kliknięcia, instalacji czy udzielenia zgody. Testuj odmowę, brak sieci, zamknięcie przed nagrodą, pełne obejrzenie i powrót z tła.

## 5. Klucz upload i AAB

Klucz należy do Ciebie. Nie wysyłaj pliku ani hasła w czacie i nie dodawaj do Git. Jeżeli masz już klucz tej aplikacji, użyj go. Nowy klucz można utworzyć lokalnie:

```sh
mkdir -p "$HOME/.local/share/neon-signing"
./tools/create_upload_key.sh "$HOME/.local/share/neon-signing/neon-upload.p12"
```

Skrypt pyta o hasło bez wyświetlania, nie nadpisuje istniejącego pliku i tworzy alias `upload`. Zachowaj kopię w bezpiecznym miejscu. W swoim lokalnym terminalu/CI ustaw bezpiecznie trzy zmienne:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` — ścieżka do pliku klucza.
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER` — alias, zwykle `upload`.
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` — hasło jako sekret lokalny/CI, nie tekst w repo.

Następnie, z przygotowanym Godot i SDK:

```sh
python3 tools/prepare_release.py --config config/publishing.json --build
```

Pipeline odmawia użycia testowych ID, nieustawionej grupy i znanego klucza debugowego. Ustawia jedną konfigurację reklam dla kodu i manifestu, eksportuje preset **Android Production**, sprawdza obecność podpisu i przywraca konfigurację testową w checkout. Plik docelowy: `builds/neon-block-master-production.aab`. Włącz Play App Signing. Debug APK i unsigned AAB nie zastępują produkcyjnego podpisanego AAB.

## 6. Listing i deklaracje Play

Gotowe materiały: `store/listing-pl.md`, `listing-en.md`, ikona 512×512, feature graphic 1024×500 i rzeczywiste zrzuty ekranów. Uzupełnij kontakt, politykę i stronę dewelopera. Zaznacz **zawiera reklamy** dla wariantu z SDK. Wypełnij zgodnie z prawdą grupę odbiorców, IARC, dostęp do aplikacji (bez konta/logowania) oraz **Data safety** — szkic w `docs/DATA-SAFETY.md`.

Weryfikacja bieżących wymagań w oficjalnych panelach pozostaje obowiązkowa. Target/compile API tej wersji to 36, min API 24; biblioteki sprawdzono statycznie pod kątem 16 KB, ale nie zastępuje to uruchomienia na urządzeniu. W tej sesji oficjalne strony Google były blokowane polityką sieci. Nie deklarujemy, że wszystkie aktualne zasady Play zostały potwierdzone.

Zacznij od testów wewnętrznych. Wykonaj `docs/TESTING.md` na telefonie, sprawdź raport Pre-launch i Android Vitals. Dla danego konta Play może wymagać testów zamkniętych przed dostępem do produkcji — dokładna liczba testerów i czas zależą od aktualnych zasad i konta. Dopiero potem składaj finalne wydanie do weryfikacji.

## Co pozostaje po stronie właściciela

Weryfikacja kont/rozliczeń, prawdziwe identyfikatory, publikacja strony i UMP, bezpieczny klucz, testy fizycznego telefonu, prawdziwe deklaracje oraz akceptacja warunków i wysyłka w Play Console. Nie zostały wykonane automatycznie i nie są zastąpione testami desktopowymi.
