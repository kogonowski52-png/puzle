# 1.4.1 — WebView i błąd silnika reklam

Z telefonu otrzymano `com.google.android.gms.ads / 0: Unable to obtain a JavascriptEngine.`. Log potwierdza ukończenie inicjalizacji SDK oraz odrzucenie przygotowania silnika reklamy. Sam komunikat nie rozstrzyga, czy zawiodło utworzenie WebView, wykonanie JS, czy ładowanie kodu reklamy. Nie uznajemy go za dowód konkretnej przyczyny sieciowej lub błędnego ID.

## Zmiana

Natywny moduł `NeonWebView` przygotowuje rzeczywisty systemowy WebView na wątku UI Androida, przed wywołaniem AdMob. Wykonuje lokalny kod `6 * 7` i wymaga wyniku 42. Dopiero po powodzeniu tej kontroli uruchamiana jest inicjalizacja/ładowanie SDK. Samo utworzenie widoku nie jest uznawane za gotowość JavaScript.

Testowy dokument nie ma zewnętrznych zasobów; jego ustawienie `blockNetworkLoads=true` blokuje sieć tylko w tym pomocniczym widoku. Nie zmieniamy ustawień sieciowych widoków SDK. Po zakończeniu widok jest usuwany i niszczony, bez globalnego `pauseTimers`, które mogłoby zatrzymać WebView reklamy. Limit testu wynosi 15 s, a adapter ma dodatkowy bezpiecznik odpowiedzi mostka.

Na Androidzie 9+ moduł próbuje wybrać prywatny katalog WebView zależny od nazwy procesu, aby procesy aplikacji nie współdzieliły blokady katalogu. Gdy provider został już zainicjalizowany, używa istniejącego profilu. Nie usuwa zapisów gry, monet ani pomocników.

Status zawiera nazwę i wersję providera, wynik testu JS oraz oryginalny błąd SDK. Jeżeli lokalny JavaScript działa, a SDK nadal odrzuca silnik reklamy, nie opisujemy tego jako naprawionej emisji: dalszy powód może dotyczyć zasobów reklamy lub konkretnego providera/połączenia. Jest przycisk **Kopiuj szczegóły**.

Tylko w debug APK po błędzie JavascriptEngine moduł próbuje odczytać dodatkowe wpisy SDK/WebView z logcat własnego procesu: wybrane tagi, ostatnie 160 wpisów, maksymalnie 16 KB, limit 1,5 s w osobnym wątku. Nie żąda READ_LOGS i nie odczytuje logów innych aplikacji. Dane pozostają lokalne i nie są automatycznie wysyłane. Log może zawierać dokładniejszy wyjątek; jego dostępność nie jest gwarantowana. Release nie uruchamia tego odczytu.

## Interfejs

Na ekranie POMOCNIKI pokazywany jest krótki komunikat. Pełne komunikaty techniczne trafiają do przewijanego ekranu statusu. Powiadomienie znajduje się nad kartami, a nie na dolnym przycisku. Zawijanie i przycinanie tekstu ograniczają jego obszar. Trwające pobieranie ma pierwszeństwo przed komunikatem poprzedniej nieudanej próby.

## Weryfikacja

- **2769 sprawdzeń Godot i 18 testów Python zaliczonych.** Testy obejmują oczekiwanie na gotowość WebView, sukces/błąd natywnego mostka, brak uruchamiania SDK po błędzie, zachowanie szczegółów SDK i granice powiadomienia.
- **11 testów Android/Robolectric zaliczonych**: cztery dotychczasowego raportu, cztery przygotowania WebView oraz trzy ograniczonego odczytu logu SDK. Sprawdzono wątek UI, wykonanie przygotowania z kontrolowanym callbackiem JS, brak sieci/pliku/content access w widoku testowym, sprzątanie, timeout, rzeczywisty komunikat błędu i rozdzielenie nazw profili. Sprawdzono też filtr bieżącego PID/tagów, ograniczenie rozmiaru logu i odrzucenie nieprawidłowego PID.
- Renderowane scenariusze błędu w Xvfb pokazują poprawiony układ. Są to jawne dane testowe interfejsu, nie dowód emisji reklamy.
- APK/AAB: definicje natywnych klas mostka i SDK, metadane pluginu, podpis, ZIP, bundletool i wyrównanie ELF/ZIP 16 KB.

Nie wykonano potwierdzonej emisji 1.4.1 na fizycznym Samsungu. Przygotowanie WebView i przejście testów nie gwarantuje, że serwer dostarczy reklamę. Nadal używamy oficjalnych testowych jednostek Google i restrykcyjnego profilu dla dzieci; nagroda pochodzi wyłącznie z earned-reward. Nie wyłączono TLS ani nie dopuszczono globalnie HTTP.
