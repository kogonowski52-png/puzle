extends Node
## SDK adapter is loaded only on Android with the actual native singletons.
## No simulated impressions or rewards. Entitlement can later be set by verified Billing.
signal availability_changed
signal fullscreen_changed(active: bool)
var adapter: Node
var dragging := false
var fullscreen := false
var last_interstitial := -10000
var last_reward := -10000
var completed_games := 0
var was_available := false
var start_after := 0.0
var startup_error := ""
var previous_reward_time := -10000.0

func _ready() -> void:
	# Let the first game frame and Android activity startup complete first.
	start_after = Time.get_ticks_msec()/1000.0+1.5

func start_if_allowed() -> void:
	if adapter != null: return
	if not AppConfig.ads_allowed():
		startup_error = "Ads disabled by app configuration"
		return
	if OS.get_name() != "Android": return
	if not Engine.has_singleton("PoingGodotAdMob"):
		startup_error = "Missing Android plugin: PoingGodotAdMob"
		return
	var sdk = load("res://scripts/admob_adapter.gd")
	if sdk == null: return
	adapter = sdk.new()
	add_child(adapter)
	adapter.changed.connect(func(): availability_changed.emit())
	adapter.reward_failed.connect(func():
		last_reward = previous_reward_time
		availability_changed.emit())
	adapter.visibility.connect(func(active):
		fullscreen = active
		fullscreen_changed.emit(active))
	adapter.initialize()
	availability_changed.emit()

func retry() -> void:
	if adapter == null: start_if_allowed()
	elif not fullscreen: adapter.retry()

func status_text() -> String:
	var pl: bool = Store.data.settings.language=="pl"
	if OS.get_name()!="Android": return "Reklamy są dostępne na Androidzie." if pl else "Ads are available on Android."
	return device_status(pl)

func device_status(pl: bool) -> String:
	if adapter==null:
		if not startup_error.is_empty(): return "Moduł reklam jest niedostępny w tej wersji." if pl else "The ad module is unavailable in this build."
		return "Uruchamianie modułu reklam…" if pl else "Starting the ad module…"
	if fullscreen: return "Reklama jest wyświetlana." if pl else "Ad is being shown."
	if adapter.rewarded!=null:
		var wait := maxi(0,ceili(60-(Time.get_ticks_msec()/1000.0-last_reward)))
		if wait>0: return ("Następna reklama za %d s." if pl else "Next ad in %d s.") % wait
		return "Reklama gotowa — pakiet czeka na odbiór." if pl else "Ad ready — claim your rescue pack."
	if adapter.webview_busy: return "Przygotowywanie WebView…" if pl else "Preparing WebView…"
	if adapter.consent_busy: return "Sprawdzanie ustawień reklam…" if pl else "Checking ad settings…"
	if adapter.initializing: return "Inicjalizacja Google Ads…" if pl else "Initializing Google Ads…"
	if adapter.reward_loading: return "Pobieranie reklamy…" if pl else "Loading an ad…"
	if not adapter.last_error.is_empty():
		if adapter.last_error.to_lower().contains("javascriptengine"):
			return "Nie udało się załadować silnika reklamy. Otwórz Status reklam." if pl else "The ad engine could not load. Open Ad status."
		if adapter.last_error.begins_with("WebView"):
			return "WebView nie wykonał testu JavaScript. Szczegóły w Statusie reklam." if pl else "WebView did not complete the JavaScript test. See Ad status."
		if adapter.reward_error_domain=="com.google.android.gms.ads":
			if adapter.reward_error_code==3: return "Google nie ma teraz dostępnej reklamy. Spróbuj później." if pl else "Google has no ad available right now. Try later."
			if adapter.reward_error_code==2: return "Nie udało się połączyć z reklamą. Sprawdź internet i ponów." if pl else "Could not connect to the ad service. Check your connection and retry."
			if adapter.reward_error_code==1: return "Reklamy wymagają sprawdzenia konfiguracji." if pl else "The ad configuration needs checking."
		return "Reklama niedostępna. Szczegóły w Statusie reklam." if pl else "Ad unavailable. See Ad status for details."
	return "Reklama niedostępna. Dotknij „Ponów”." if pl else "Ad unavailable. Tap Retry."

func details_text() -> String:
	var result := "Neon Block Master / "+str(ProjectSettings.get_setting("application/config/version","unknown"))+"\n"
	result += "Google Mobile Ads / production units\n" if AppConfig.production() else "Google Mobile Ads / test units\n"
	if adapter==null:
		return result+"Native SDK: "+str(Engine.has_singleton("PoingGodotAdMob"))+"\nWebView bridge: "+str(Engine.has_singleton("NeonWebView"))+"\nUMP bridge: "+str(Engine.has_singleton("NeonConsent"))+"\n"+startup_error
	result += "Stage: "+adapter.stage+"\n"
	if not adapter.webview_info.is_empty():
		result += "\nWebView: "+str(adapter.webview_info.get("provider","unknown"))
		result += "\nJavaScript: "+str(adapter.webview_info.get("ok",false))
		result += "\n"+str(adapter.webview_info.get("message",""))+"\n\n"
	if not adapter.last_error.is_empty(): result += adapter.last_error+"\n\n"
	if not adapter.interstitial_error.is_empty(): result += "Interstitial:\n"+adapter.interstitial_error+"\n\n"
	result += "State: WebView=%s, consent_busy=%s, consent_ready=%s, initialized=%s\n\n" % [adapter.webview_ready,adapter.consent_busy,adapter.consent_ready,adapter.initialized]
	result += "\n".join(adapter.events)
	if not adapter.webview_logs.is_empty(): result += "\n\nSDK log (this app only):\n"+adapter.webview_logs
	return result

func reward_available() -> bool:
	return AppConfig.ads_allowed() and adapter != null and adapter.rewarded != null and not dragging and not fullscreen and Time.get_ticks_msec()/1000-last_reward >= 60

func reward_is_loading() -> bool:
	if adapter!=null and adapter.rewarded!=null: return false
	return adapter!=null and (adapter.webview_busy or adapter.consent_busy or adapter.initializing or adapter.reward_loading)

func reward_cooldown_seconds() -> int:
	return maxi(0,ceili(60-(Time.get_ticks_msec()/1000.0-last_reward)))

func reward(callback: Callable) -> bool:
	if not reward_available(): return false
	previous_reward_time = last_reward
	last_reward = Time.get_ticks_msec()/1000
	adapter.show_reward(callback)
	return true

func between_games() -> void:
	completed_games += 1
	if not AppConfig.ads_allowed() or Store.data.ad_free or dragging or fullscreen or adapter == null: return
	if completed_games % 3 != 0 or Time.get_ticks_msec()/1000-last_interstitial < 180: return
	if adapter.interstitial == null: return
	last_interstitial = Time.get_ticks_msec()/1000
	adapter.show_interstitial()

func privacy() -> void:
	if adapter != null: adapter.privacy()

func _process(_delta: float) -> void:
	if adapter==null and OS.get_name()=="Android" and Time.get_ticks_msec()/1000.0>=start_after:
		start_after = Time.get_ticks_msec()/1000.0+5
		start_if_allowed()
	if adapter == null: return
	var available := reward_available()
	if available != was_available:
		was_available = available
		availability_changed.emit()
