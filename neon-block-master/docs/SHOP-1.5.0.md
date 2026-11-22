# Sklep 1.5.0 / kod 10

Nowy sklep ma zakładki Motywy, Pomocnicy i Premium, z animowanym podglądem motywu Cyber Galaxy i efektu Nova. Dotychczasowe monety i dobrowolne reklamy pozostają dostępne. Zapis wersji 1.4.2 jest migrowany bez kasowania postępu.

## Produkty do utworzenia na koncie Google Play

| Identyfikator | Nazwa | Typ obsługi w grze | Proponowana cena PL |
|---|---|---|---|
| `neon_plus` | Neon Plus | Jednorazowy trwały zakup, acknowledge; bez consume | 14,99 zł |
| `rescue_pack_10_20` | Duży pakiet ratunkowy | Jednorazowy produkt zużywalny, consume; można kupić ponownie | 6,99 zł |

Oba to produkty jednorazowe INAPP, nie subskrypcje. Utwórz jedną zwykłą opcję zakupu każdego produktu; bez wynajmu i dodatkowych ofert. Wyłącz opcję zakupu wielu sztuk jednocześnie (multi-quantity); gra obsługuje ilość 1 na transakcję. Ostateczną cenę i walutę wyświetla Google Play. Interfejs nie wstawia sztywnej ceny, gdy nie otrzymał działającej oferty.

Neon Plus usuwa reklamy automatyczne i odblokowuje Cyber Galaxy oraz Nova. Nie obiecuje nieograniczonych pomocników. Reklamy nagradzane pozostają dobrowolne. Pakiet zużywalny daje dokładnie 10 Młotków i 20 Zmian; działa poza Daily. Nie ma płatnych losowań ani automatycznie odnawianej opłaty.

## Stan dostarczonego podglądu

**Publiczny klucz licencyjny właściciela został sprawdzony i dodany do gry. SHA-256 klucza: `59a5f20c093aa4c1d364c6b3b06a8bcd0e2dd55c59cd9aee3ffdfdbe948c2d20`.** Właściciel potwierdził, że nie utworzył jeszcze produktów. Do czasu ich aktywacji oferty nie będą dostępne. Produkty i konto płatności nie zostały utworzone przez Codexa. Nie wykonano prawdziwej ani testowej transakcji na koncie Play. Ten etap jest podglądem kolejnej aktualizacji; nie zastępuje gotowego wydania 1.4.2 będącego w weryfikacji Google.

## Uruchomienie zakupów

Kroki 1–2 są wykonane w tej paczce. Zacznij od produktów/kroku 3; instrukcja dodania publicznego klucza pozostaje do odtworzenia w przyszłości.

1. Play Console → Zarabianie → Konfiguracja zarabiania → Licencjonowanie: skopiuj **publiczny** klucz RSA Base64 dla `com.neonblockmaster.puzzle`. To nie certyfikat upload, hasło ani plik P12. Nie wpisuj prywatnych danych do konfiguracji.
2. Zapisz sam tekst klucza w lokalnym pliku, np. `publiczny-klucz-play.txt`. Z katalogu projektu wykonaj `python tools/configure_billing.py --public-key-file publiczny-klucz-play.txt`. Narzędzie sprawdza format RSA i aktualizuje `assets/billing_config.json`; ten klucz jest publiczny.
3. Play Console → Zarabianie → Produkty → Produkty jednorazowe: utwórz powyższe ID, nazwę/opis, zwykłą opcję zakupu, cenę i dostępność. Aktywuj oba produkty. Jeśli panel wymaga najpierw pakietu z uprawnieniem BILLING, użyj wydania bootstrap na ścieżce wewnętrznej. Każdy już przesłany kod wersji wymaga następnie wyższego kodu przy kolejnym uploadzie.
4. Przygotuj nowy AAB z uzupełnionym kluczem i produkcyjną konfiguracją reklam. Polecenie `python tools/prepare_release.py --config config/publishing.json --export-candidate` eksportuje niepodpisany pakiet. `--build` wymaga także ukończonych sprawdzeń produkcyjnych i własnego podpisu; nie wpisuj fikcyjnej weryfikacji Families, aby przejść kontrolę.
5. Zweryfikuj AAB przez `tools/verify_production.py` z właściwym `BUNDLETOOL`. Raport sprawdza Billing 8.0.0, uprawnienie BILLING, rejestrację natywnego modułu, faktyczne definicje klas DEX, konfigurację, brak AD_ID/telefonu, API 24/36, biblioteki ELF 16 KB oraz opcjonalne `android.hardware.screen.portrait`.
6. Podpisz dotychczasowym prywatnym kluczem upload z komputera właściciela. Stare `podpisz.ps1` i metadane 1.4.2 nie mogą być użyte do innego AAB bez aktualizacji oczekiwanego hasha i wersji. Nie usuwaj ani nie nadpisuj klucza.
7. Najpierw opublikuj nowe wydanie w testach wewnętrznych. Dodaj konta do testerów ścieżki i do **testerów licencji** Google Play. Zainstaluj grę przez link testowy, używaj testowych metod płatności Google. Sam APK z GitHuba nie potwierdza gotowości płatności.
8. Wykonaj poniższe testy na telefonie. Dopiero po ich potwierdzeniu przygotuj aktualizację produkcyjną, opisy sklepu i politykę. Nie wycofuj wersji 1.4.2 ze sprawdzania tylko po to, żeby wstawić nieukończony sklep.

## Wymagane próby w Google Play

- Cena i waluta obu produktów pochodzą z konta Play; anulowanie płatności niczego nie przyznaje.
- Zła odpowiedź, wygaśnięcie lub anulowanie ekranu rodzica nie otwiera płatności. Poprawna odpowiedź pozwala na jedną akcję. Ekran rodzica nie jest odpowiednikiem uwierzytelnienia płatności Google — zachowaj ustawienia zakupów rodzinnych na koncie.
- Płatność PENDING nie przyznaje produktu. Po jej zatwierdzeniu i wznowieniu gry produkt przychodzi raz. Odrzucenie płatności nie daje bonusu.
- Pakiet daje 10/20, utrzymuje się po restarcie, ponowne zapytanie o ten sam zakup nie powiela go. Można kupić następny pakiet po zakończeniu consume.
- Wyłączenie aplikacji po zapisaniu nagrody, ale przed consume/ack, oraz chwilowy brak sieci nie powielają nagrody; następne zapytanie ponawia zakończenie transakcji.
- Neon Plus wyłącza reklamy automatyczne i daje motyw/efekt; gracz nadal sam wybiera reklamy z nagrodą.
- Neon Plus przywraca się po reinstalacji lub na innym urządzeniu z kontem zakupu. Pomyślny query bez tego produktu cofa uprawnienie, np. po zwrocie; błąd sieci nie odbiera zapisanego uprawnienia.
- Sprawdź brak Play Store, brak sieci, niedostępny produkt, błędny klucz i brak możliwości zapisu. Gra i dotychczasowe bezpłatne funkcje nadal działają.

## Implementacja i granice

Natywny most Java `NeonBilling` używa Google Play Billing 8.0.0 oraz Godot 4.6.3. Weryfikuje podpis oryginalnego JSON zakupu publicznym kluczem licencyjnym Play (SHA1withRSA, format podpisu klasycznego Play Billing), pakiet aplikacji, produkt, ilość 1 i stan PURCHASED. Nie udaje zakupu na desktopie i nie przyznaje towaru za samo kliknięcie przycisku lub zamknięcie okna.

Gra zapisuje nagrodę i skrót SHA-256 tokena razem, atomowo. Dopiero po udanym zapisie prosi most o consume lub acknowledge. Surowe tokeny i podpisane JSON nie są wysyłane do logów ani zapisywane w profilu gry. Nie ma limitu 999 przycinającego płatny pakiet; limity dla bezpłatnych pakietów pozostają. Historia do 10 000 skrótów nie jest automatycznie kasowana — po zapełnieniu nowe dostarczenie zatrzyma się zamiast powielać/utracić nagrodę.

Weryfikacja podpisu jest lokalna, bez serwera dewelopera. Nie chroni zmodyfikowanego APK ani zmodyfikowanego zapisu. Nie wdrożono serwerowej weryfikacji tokenów, RTDN ani serwerowego portfela. Zużywalne pomocniki nie są odzyskiwane po usunięciu danych i nie synchronizują się między telefonami; zwroty zużywalnych zakupów nie cofają automatycznie wydanych lokalnych pomocników. Jeśli potrzebna jest taka ekonomia, wymaga osobnego backendu i obsługi powiadomień Google. Nie twierdzimy, że to jest wdrożone.

Źródła zawierają testy logiki transakcji, migracji, awarii zapisu, rodzica, przywracania, rzeczywistych podpisów RSA oraz granic UI. Przebudowano natywny most przeciw prawdziwym API Android/Godot/Billing. Testy z podstawionymi callbackami nie są transakcją Google Play. Zrzuty wykorzystują rzeczywisty renderer desktopowy, nie telefon. Wymagana jest weryfikacja nowych SDK/zasad dla dzieci i aktualizacja deklaracji Play przed publikacją.

## Odtworzenie mostu

Z pełnym JDK i oficjalnymi API:

```text
python tools/build_billing.py --android-jar SCIEZKA/android.jar --godot-aar SCIEZKA/godot-4.6.3.aar --billing-aar SCIEZKA/billing-8.0.0.aar
```

Gotowy AAR jest w `addons/neon_billing/runtime`. Eksporter dodaje zależność Billing 8.0.0 oraz manifest. Pozostałe kroki Android są w `docs/ANDROID.md`; stare ścieżki chmurowe w `tools/cloud_env.sh` trzeba dostosować do swojej maszyny.
