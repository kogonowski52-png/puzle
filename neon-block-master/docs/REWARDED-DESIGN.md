# Nagrody 1.4.0

Główna nagroda: **1 Młotek 3×3 + 2 Zmiany zestawu za jedną ukończoną reklamę**. Ten sam pakiet kosztuje 90 monet z gry; pakiet startowy gratis. Bez losowania, wymiany na pieniądze i obowiązku oglądania reklam. [Pełny opis i testy](BOOSTERS-1.4.md).

Poniżej historia oferty kosmetycznej.

# Nagrody reklamowe w 1.1.0

- **NEON LAB / PLASMA**: trzy ukończone rewarded ads = trzy zapisane ładunki i konkretny motyw. Postęp nie wygasa. Alternatywa bez reklam: 240 monet zdobytych przez grę. Brak losowania, limitu czasowego i płatności.
- **Podwójna nagroda po grze**: jedna reklama dodaje dokładnie tyle monet, ile zdobyto za rekord/wyzwanie w tej rozgrywce. Nie podwaja wyniku ani całego portfela. Dla zera monet nie pokazujemy oferty. Zapisany identyfikator nagrody chroni przed podwójnym przyznaniem/starym callbackiem.
- Zachowano **25 monet** w sklepie i **jedną dodatkową szansę** po przegranej. Żadna nagroda nie wymaga kliknięcia reklamy ani zgody na personalizację.
- Rewarded nie częściej niż raz na 60 sekund w sesji; SDK musi mieć faktycznie załadowaną reklamę. Wyłączony przycisk opisuje brak reklamy/przerwę. Brak SDK/internetu nie przyznaje fikcyjnej nagrody i nie blokuje gry.
- Callback earned-reward jest jedynym wejściem z SDK do przyznania nagrody. Stany przyznawania są oddzielone od zamknięcia reklamy. Reklamy nie są oferowane podczas przeciągania.
- Interstitial: tylko naturalna przerwa przy ponownej grze po wyniku, co trzeci restart i co najmniej 180 s między pokazami. `ad_free` pozostaje przyszłym punktem integracji Billing, bez fikcyjnego zakupu.

Rekomendowane sprawdzenia na prawdziwym Androidzie: przerwij reklamę przed końcem; ukończ do earned event; spróbuj duplikatu/starego callbacku w testowym środowisku; przejdź w tło; wycofaj zgodę; wróć po utracie sieci. Desktopowe testy walidują ekonomię i stan, nie emisję prawdziwych reklam. Nie deklarujemy ani nie gwarantujemy wzrostu oglądalności czy przychodów.
