extends Node
## Classic Google Mobile Ads 24.9.0 / Poing 4.3.1. No mocked impressions.
signal changed
signal visibility(active: bool)
var rewarded: RewardedAd
var interstitial: InterstitialAd
var initialized := false
var consent_ready := false
var consent_busy := false
var generation := 0
var reward_loading := false
var interstitial_loading := false
var retry_reward_at := 0.0
var retry_interstitial_at := 0.0
var retry_consent_at := 0.0
var reward_failures := 0
var interstitial_failures := 0
var consent_failures := 0
var reward_loaded_at := 0.0
var interstitial_loaded_at := 0.0
var initialization_listener := OnInitializationCompleteListener.new()
var initializing := false
var initialization_deadline := 0.0
var retry_initialize_at := 0.0
var reward_deadline := 0.0
var interstitial_deadline := 0.0
var reward_serial := 0
var interstitial_serial := 0
var last_error := ""
var events: Array[String] = []
var webview_plugin: Object
var webview_ready := false
var webview_busy := false
var webview_deadline := 0.0
var webview_info: Dictionary = {}
var webview_logs := ""

func capture_sdk_log() -> void:
	if not OS.is_debug_build() or webview_plugin==null or not webview_plugin.has_method("read_ads_log"): return
	if not webview_plugin.is_connected("ads_log_ready",_sdk_log_ready):
		webview_plugin.connect("ads_log_ready",_sdk_log_ready,CONNECT_DEFERRED)
	webview_plugin.read_ads_log()

func _sdk_log_ready(payload: String) -> void:
	webview_logs = payload.left(16384)
	changed.emit()

func prepare_webview() -> void:
	if webview_busy: return
	if webview_plugin==null and Engine.has_singleton("NeonWebView"):
		webview_plugin = Engine.get_singleton("NeonWebView")
	if webview_plugin==null:
		last_error = "Brak modułu kontroli WebView w APK"
		record(last_error)
		return
	if not webview_plugin.is_connected("webview_ready",_webview_completed):
		webview_plugin.connect("webview_ready",_webview_completed,CONNECT_DEFERRED)
	webview_ready = false
	webview_busy = true
	webview_deadline = now()+20
	record("Przygotowanie systemowego WebView i test JavaScript")
	webview_plugin.prepare()

func _webview_completed(payload: String) -> void:
	if not webview_busy: return
	webview_busy = false
	var parsed = JSON.parse_string(payload)
	webview_info = parsed if parsed is Dictionary else {"ok":false,"message":"Invalid WebView response"}
	webview_ready = webview_info.get("ok",false)==true
	record("WebView: "+str(webview_info.get("provider","unknown"))+" — "+str(webview_info.get("message","")))
	if webview_ready:
		last_error = ""
		initialize()
	else:
		last_error = "WebView: "+str(webview_info.get("message","Nie działa JavaScript"))
		retry_initialize_at = now()+60
		record(last_error)

func record(message: String) -> void:
	events.append("%ds — %s" % [int(now()),message])
	while events.size()>8: events.pop_front()
	changed.emit()

func describe_error(error: Variant) -> String:
	if error == null: return "Brak szczegółów błędu SDK"
	return "%s / %s: %s" % [str(error.domain),str(error.code),str(error.message)]

func bind_native_plugins() -> bool:
	if OS.get_name() != "Android": return true
	var names := ["PoingGodotAdMob","PoingGodotAdMobRewardedAd","PoingGodotAdMobInterstitialAd"]
	if AppConfig.production(): names.append("PoingGodotAdMobConsentInformation")
	for name in names:
		if not Engine.has_singleton(name):
			last_error = "Brak modułu Android: "+name
			record(last_error)
			return false
	# Resolve lazily as well as at script import, after Android has registered its plugins.
	MobileAds._plugin = Engine.get_singleton("PoingGodotAdMob")
	RewardedAdLoader._plugin = Engine.get_singleton("PoingGodotAdMobRewardedAd")
	RewardedAd._plugin = RewardedAdLoader._plugin
	InterstitialAdLoader._plugin = Engine.get_singleton("PoingGodotAdMobInterstitialAd")
	InterstitialAd._plugin = InterstitialAdLoader._plugin
	if AppConfig.production():
		ConsentInformation._plugin = Engine.get_singleton("PoingGodotAdMobConsentInformation")
	return true

func now() -> float:
	return Time.get_ticks_msec()/1000.0

func initialize() -> void:
	if consent_busy or initializing or webview_busy or not AppConfig.ads_allowed(): return
	if not bind_native_plugins(): return
	if OS.get_name()=="Android" and not webview_ready:
		prepare_webview()
		return
	if initialized:
		load_rewarded()
		load_interstitial()
		return
	consent_busy = true
	retry_consent_at = 0
	# Demo units are for testing SDK delivery on the owner's device, not revenue.
	if not AppConfig.production():
		consent_busy = false
		_enable_restricted_ads()
		return
	if ConsentInformation._plugin==null:
		consent_busy = false
		last_error = "Brak modułu zgód UMP"
		record(last_error)
		return
	var params := ConsentRequestParameters.new()
	params.tag_for_under_age_of_consent = true
	record("Sprawdzanie ustawień UMP")
	UserMessagingPlatform.consent_information.update(params,_consent_updated,func(error):
		consent_busy = false
		last_error = "UMP: "+str(error.message)
		record(last_error)
		consent_failures += 1
		retry_consent_at = now()+minf(300,60*pow(2,mini(3,consent_failures-1)))
		changed.emit())

func _consent_updated() -> void:
	consent_busy = false
	consent_failures = 0
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	# Never show an adult consent form to a young child. Production fails closed
	# if UMP indicates any unresolved consent requirement.
	if status in [ConsentInformation.ConsentStatus.NOT_REQUIRED,ConsentInformation.ConsentStatus.OBTAINED]:
		_enable_restricted_ads()
	else:
		last_error = "UMP: nierozwiązany wymóg zgody; reklamy pozostają wyłączone"
		record(last_error)

func _enable_restricted_ads() -> void:
	consent_ready = true
	var request := restricted_configuration()
	MobileAds.set_request_configuration(request)
	if initialized:
		MobileAds.set_app_muted(not Store.data.settings.sound)
		load_rewarded()
		load_interstitial()
		return
	if initializing: return
	initializing = true
	initialization_deadline = now()+45
	retry_initialize_at = 0
	record("Inicjalizacja Google Mobile Ads")
	initialization_listener.on_initialization_complete = func(_status):
		initialized = true
		initializing = false
		initialization_deadline = 0
		retry_initialize_at = 0
		last_error = ""
		record("SDK gotowe — pobieranie reklam")
		# Classic GMA throws IllegalStateException if mute is set before initialize.
		MobileAds.set_app_muted(not Store.data.settings.sound)
		if consent_ready:
			load_rewarded()
			load_interstitial()
	MobileAds.initialize(initialization_listener)

func restricted_configuration() -> RequestConfiguration:
	var request := RequestConfiguration.new()
	request.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	request.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.TRUE
	request.tag_for_under_age_of_consent = RequestConfiguration.TagForUnderAgeOfConsent.TRUE
	return request

func restricted_request() -> AdRequest:
	var request := AdRequest.new()
	request.extras = {"npa":"1"}
	return request

func load_rewarded() -> void:
	if not initialized or not consent_ready or reward_loading or rewarded != null: return
	if OS.get_name()=="Android" and not webview_ready:
		prepare_webview()
		return
	reward_loading = true
	reward_serial += 1
	var request_id := reward_serial
	reward_deadline = now()+75
	var epoch := generation
	var callback := RewardedAdLoadCallback.new()
	record("Pobieranie reklamy z nagrodą")
	callback.on_ad_failed_to_load = func(error):
		if epoch != generation or request_id != reward_serial: return
		reward_loading = false
		reward_deadline = 0
		last_error = describe_error(error)
		if last_error.to_lower().contains("javascriptengine"):
			webview_ready = false
			capture_sdk_log()
		record("Reklama z nagrodą: "+last_error)
		reward_failures += 1
		retry_reward_at = now()+minf(300,15*pow(2,mini(5,reward_failures-1)))
		changed.emit()
	callback.on_ad_loaded = func(ad):
		if epoch != generation or request_id != reward_serial or not consent_ready:
			ad.destroy()
			return
		reward_loading = false
		reward_deadline = 0
		reward_failures = 0
		retry_reward_at = 0
		rewarded = ad
		reward_loaded_at = now()
		last_error = ""
		record("Reklama z nagrodą jest gotowa")
	RewardedAdLoader.new().load(AppConfig.ad_id("rewarded"),restricted_request(),callback)

func load_interstitial() -> void:
	if not initialized or not consent_ready or interstitial_loading or interstitial != null: return
	if OS.get_name()=="Android" and not webview_ready: return
	interstitial_loading = true
	interstitial_serial += 1
	var request_id := interstitial_serial
	interstitial_deadline = now()+75
	var epoch := generation
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_failed_to_load = func(_error):
		if epoch != generation or request_id != interstitial_serial: return
		interstitial_loading = false
		interstitial_deadline = 0
		interstitial_failures += 1
		retry_interstitial_at = now()+minf(300,15*pow(2,mini(5,interstitial_failures-1)))
		changed.emit()
	callback.on_ad_loaded = func(ad):
		if epoch != generation or request_id != interstitial_serial or not consent_ready:
			ad.destroy()
			return
		interstitial_loading = false
		interstitial_deadline = 0
		interstitial_failures = 0
		retry_interstitial_at = 0
		interstitial = ad
		interstitial_loaded_at = now()
		changed.emit()
	InterstitialAdLoader.new().load(AppConfig.ad_id("interstitial"),restricted_request(),callback)

func show_reward(callback: Callable) -> void:
	if rewarded == null or not consent_ready: return
	MobileAds.set_app_muted(not Store.data.settings.sound)
	var ad := rewarded
	rewarded = null
	var state := {"earned":false,"closed":false}
	var full := FullScreenContentCallback.new()
	var cleanup := func():
		if state.closed: return
		state.closed = true
		ad.full_screen_content_callback = FullScreenContentCallback.new()
		ad.destroy()
		visibility.emit(false)
		load_rewarded()
	full.on_ad_dismissed_full_screen_content = cleanup
	full.on_ad_failed_to_show_full_screen_content = func(error):
		last_error = describe_error(error)
		record("Nie udało się wyświetlić reklamy: "+last_error)
		cleanup.call()
	ad.full_screen_content_callback = full
	var earned := OnUserEarnedRewardListener.new()
	earned.on_user_earned_reward = func(_item):
		if state.earned: return
		state.earned = true
		if callback.is_valid(): callback.call()
	visibility.emit(true)
	ad.show(earned)
	changed.emit()

func retry() -> void:
	if initializing or consent_busy or webview_busy: return
	if OS.get_name()=="Android" and not webview_ready:
		prepare_webview()
		return
	if not initialized:
		initialize()
		return
	if not reward_loading:
		retry_reward_at = 0
		load_rewarded()
	if not interstitial_loading:
		retry_interstitial_at = 0
		load_interstitial()

func show_interstitial() -> void:
	if interstitial == null or not consent_ready: return
	MobileAds.set_app_muted(not Store.data.settings.sound)
	var ad := interstitial
	interstitial = null
	var state := {"closed":false}
	var full := FullScreenContentCallback.new()
	var cleanup := func():
		if state.closed: return
		state.closed = true
		ad.full_screen_content_callback = FullScreenContentCallback.new()
		ad.destroy()
		visibility.emit(false)
		load_interstitial()
	full.on_ad_dismissed_full_screen_content = cleanup
	full.on_ad_failed_to_show_full_screen_content = func(_error): cleanup.call()
	ad.full_screen_content_callback = full
	visibility.emit(true)
	ad.show()

func privacy() -> void:
	# All audiences use the restrictive child-directed configuration. There is
	# no switch here to opt into personalised advertising or adult consent.
	pass

func _process(_delta: float) -> void:
	var time := now()
	if webview_busy and time>=webview_deadline:
		webview_busy = false
		last_error = "WebView: test JavaScript nie odpowiedział"
		record(last_error)
		retry_initialize_at = time+60
	if initializing and time>=initialization_deadline:
		initializing = false
		last_error = "SDK nie odpowiedziało przez 45 s — ponawiam inicjalizację"
		record(last_error)
		retry_initialize_at = time+15
	if retry_initialize_at>0 and time>=retry_initialize_at:
		retry_initialize_at = 0
		initialize()
	if retry_consent_at > 0 and time >= retry_consent_at: initialize()
	if not consent_ready: return
	if reward_loading and time>=reward_deadline:
		reward_loading = false
		reward_serial += 1
		last_error = "Upłynął czas pobierania reklamy (75 s). Sprawdź połączenie lub blokowanie reklam."
		record(last_error)
		retry_reward_at = time+15
	if interstitial_loading and time>=interstitial_deadline:
		interstitial_loading = false
		interstitial_serial += 1
		retry_interstitial_at = time+30
	# Google ads expire after one hour. Refresh before that deadline.
	if rewarded != null and time-reward_loaded_at >= 3000:
		rewarded.destroy()
		rewarded = null
		retry_reward_at = time
		changed.emit()
	if interstitial != null and time-interstitial_loaded_at >= 3000:
		interstitial.destroy()
		interstitial = null
		retry_interstitial_at = time
	if retry_reward_at > 0 and time >= retry_reward_at:
		retry_reward_at = 0
		load_rewarded()
	if retry_interstitial_at > 0 and time >= retry_interstitial_at:
		retry_interstitial_at = 0
		load_interstitial()
