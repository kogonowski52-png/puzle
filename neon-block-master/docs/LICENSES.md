# Licencje

- Własny kod gry, SVG/PNG, dźwięki i muzyka: MIT, `LICENSE`. Zasoby generowane przez `tools/generate_assets.py` z własnych równań i kształtów, bez sampli lub grafik z Internetu. Można wykorzystywać komercyjnie.
- Fonty DejaVu Sans Regular/Bold: Bitstream Vera oraz Arev; pełny tekst `assets/FONT-LICENSE.txt`. Oryginalne pliki fontów z pakietu DejaVu; nie zmieniano nazw ani glifów.
- Godot Engine i oficjalne szablony: MIT oraz licencje zależności silnika: https://godotengine.org/license/ i https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt . Informacja MIT jest też w zakładce Informacje gry. Przed dystrybucją uwzględnij wykaz zależności silnika z oficjalnego wydania, jeżeli dystrybuujesz jego pliki osobno.
- Poing Studios Godot AdMob Plugin 4.3.1: MIT; `addons/admob/LICENSE`, `third_party/admob/LICENSE`. Natywne źródła Kotlin w `third_party/admob/android-source/`, przypięty commit w `REVISION`. AAR pochodzą z oficjalnego wydania dla Godot 4.6.3.
- Google Mobile Ads, UMP i AndroidX: zależności pobierane przez Gradle, obowiązują warunki i licencje ich dostawców. Biblioteki te nie są naszymi własnymi zasobami MIT. Google AdMob wymaga konta i zgodności z jego warunkami.

Przykładowe media Poing w `addons/admob/assets` należą do dystrybucji upstream; nie są używane przez grę i są wyłączone z eksportu. Nie są reklamowane jako własna grafika lub muzyka gry. Folder `third_party` jest wyłączony ze skanowania i eksportu Godot.

W 1.3.0 używana jest klasyczna biblioteka Google Mobile Ads 24.9.0 i UMP 4.0.0, na warunkach Google. Nieużywane upstream fonty Arial/Orange Juice w addonach zastąpiono DejaVu Sans; nazwy plików zachowano dla zgodności odwołań mocków, ale ich zawartość to licencjonowany DejaVu.
