extends SceneTree
const Board = preload("res://scripts/board.gd")
var checks := 0
var failures := 0

class NativeInitializationProbe extends RefCounted:
	signal on_initialization_complete(status: Dictionary)
	var completed := false
	var calls: Array[String] = []
	var complete_immediately := false
	func set_request_configuration(_config, _devices): calls.append("configuration")
	func initialize():
		calls.append("initialize")
		if complete_immediately:
			completed = true
			on_initialization_complete.emit({})
	func set_app_muted(_muted): calls.append("mute" if completed else "INVALID_PREINIT_MUTE")

class NativeRewardFailureProbe extends RefCounted:
	signal on_rewarded_ad_loaded(uid: int)
	signal on_rewarded_ad_failed_to_load(uid: int, error: Dictionary)
	var next_uid := 0
	var last_uid := -1
	var fail_immediately := true
	func create():
		var uid := next_uid
		next_uid += 1
		return uid
	func load(_id,_request,_keywords,uid):
		last_uid = uid
		if fail_immediately: fail(uid)
	func fail(uid):
		on_rewarded_ad_failed_to_load.emit(uid,{"code":2,"domain":"com.google.android.gms.ads","message":"NETWORK_TEST_FAILURE","cause":{},"response_info":{}})

class NativeConsentProbe extends RefCounted:
	signal on_consent_info_updated_success
	signal on_consent_info_updated_failure(error: Dictionary)
	var mode := "success"
	var status := 1
	var parameters: Dictionary = {}
	func update(request: Dictionary):
		parameters = request
		if mode=="success": on_consent_info_updated_success.emit()
		elif mode=="failure": on_consent_info_updated_failure.emit({"error_code":2,"message":"CONSENT_FIXTURE_FAILURE"})
	func get_consent_status(): return status

class NativeRewardPlaybackProbe extends RefCounted:
	signal on_rewarded_ad_clicked(uid:int)
	signal on_rewarded_ad_dismissed_full_screen_content(uid:int)
	signal on_rewarded_ad_failed_to_show_full_screen_content(uid:int,error:Dictionary)
	signal on_rewarded_ad_impression(uid:int)
	signal on_rewarded_ad_showed_full_screen_content(uid:int)
	signal on_rewarded_ad_user_earned_reward(uid:int,item:Dictionary)
	var mode := "reward"
	var destroyed: Array[int] = []
	func show(uid):
		if mode=="failure":
			on_rewarded_ad_failed_to_show_full_screen_content.emit(uid,{"code":2,"domain":"native-test","message":"SHOW_FIXTURE_FAILURE","cause":{}})
			return
		on_rewarded_ad_showed_full_screen_content.emit(uid)
		if mode=="reward":
			on_rewarded_ad_user_earned_reward.emit(uid,{"amount":1,"type":"pack"})
			on_rewarded_ad_user_earned_reward.emit(uid,{"amount":1,"type":"pack"})
		on_rewarded_ad_dismissed_full_screen_content.emit(uid)
	func destroy(uid): destroyed.append(uid)

class EarnedRewardProbe extends Node:
	var rewarded = RefCounted.new()
	var pending: Callable
	func show_reward(callback: Callable): pending = callback

class NativeWebViewProbe extends RefCounted:
	signal webview_ready(payload: String)
	var calls := 0
	var response := '{"ok":true,"provider":"test-provider","message":"local JS OK"}'
	func prepare():
		calls += 1
		webview_ready.emit(response)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func hand(shape: Array, color := 1) -> Array:
	return [{"shape":shape,"color":color},{},{}]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var b := Board.new()
	b.begin("classic")
	check(b.cells.size()==64 and b.hand.size()==3,"new board dimensions")
	check(b.can_place([[0,0]],Vector2i(7,7)),"last cell valid")
	check(not b.can_place([[0,0],[1,0]],Vector2i(7,7)),"right boundary")
	check(not b.can_place([[0,0]],Vector2i(-1,0)),"negative boundary")
	b.cells[0]=1
	check(not b.can_place([[0,0]],Vector2i.ZERO),"occupied cell")
	b.hand=hand([[0,0]])
	var before := b.snapshot()
	check(b.place(0,Vector2i.ZERO).is_empty(),"collision is rejected")
	check(b.snapshot()==before,"rejected move is side-effect free")
	check(b.place(-1,Vector2i.ONE).is_empty(),"invalid hand index")
	b=Board.new()
	b.mode="time"
	for i in range(1,8):
		b.cells[i]=2
		b.cells[i*8]=3
	b.hand=hand([[0,0]])
	var result := b.place(0,Vector2i.ZERO)
	check(result.lines==2 and result.cleared.size()==15,"row and column clear simultaneously with unique intersection")
	check(b.cells.all(func(v): return v==0),"simultaneous clear empties board")
	check(b.score==285 and b.combo==1,"multi-line scoring")
	check(b.remaining==186,"time combo bonus")
	for i in range(1,8): b.cells[i]=1
	b.hand=hand([[0,0]])
	result=b.place(0,Vector2i.ZERO)
	check(result.points==160 and b.combo==2,"successive clearing move combo")
	b.hand=hand([[0,0]])
	result=b.place(0,Vector2i.ZERO)
	check(b.combo==0 and result.points==10,"non-clearing move resets combo")
	b.cells.fill(1)
	b.cells[0]=0
	b.hand=hand([[0,0],[1,0]])
	check(not b.has_moves(),"no placement ends game")
	b.hand=hand([[0,0]])
	check(b.has_moves(),"last available single-cell placement found")
	b.cells.fill(1)
	b.deal()
	check(not b.has_moves(),"full board cannot be rescued by dealing")
	b.cells[0]=0
	for i in 30:
		b.deal()
		check(b.has_moves(),"refill guarantees one fitting piece when possible")
	var a := Board.new()
	var c := Board.new()
	a.begin("daily","2026-11-02")
	c.begin("daily","2026-11-02")
	check(a.hand==c.hand and a.target==c.target,"daily seed reproducibility")
	for i in 20:
		a.deal()
		c.deal()
		check(a.hand==c.hand,"daily sequence reproducibility")
	var restored := Board.restore(JSON.parse_string(JSON.stringify(a.snapshot())))
	check(restored!=null,"JSON snapshot restore")
	a.deal()
	restored.deal()
	check(a.hand==restored.hand,"RNG state survives save losslessly")
	var broken := a.snapshot()
	broken.cells=[1]
	check(Board.restore(broken)==null,"malformed cells rejected")
	broken=a.snapshot()
	broken.hand[0].shape=[[0,0],[0,0]]
	check(Board.restore(broken)==null,"duplicate shape squares rejected")
	broken=a.snapshot()
	broken.hand[0].shape=[[1.5,0]]
	check(Board.restore(broken)==null,"fractional shape coordinates rejected")
	check(not a.revive(),"daily cannot revive")
	b=Board.new()
	b.begin("classic")
	b.cells.fill(1)
	b.ended=true
	check(b.revive() and not b.ended and b.has_moves(),"earned continue clears space")
	check(not b.revive(),"continue once per run")
	b=Board.new()
	b.begin("time")
	b.remaining=0
	check(not b.revive(),"expired timer cannot revive")
	# Many real games: legal placements preserve board and score invariants.
	var games := 0
	var moves := 0
	var started := Time.get_ticks_msec()
	for seed_value in 60:
		b=Board.new()
		b.rng.seed=seed_value
		b.deal()
		for step in 180:
			var chosen := -1
			var at := Vector2i.ZERO
			for i in 3:
				if b.hand[i].is_empty(): continue
				for y in 8:
					for x in 8:
						if chosen<0 and b.can_place(b.hand[i].shape,Vector2i(x,y)):
							chosen=i
							at=Vector2i(x,y)
			if chosen<0:
				check(not b.has_moves(),"game-over search agrees with placements")
				break
			var old_score := b.score
			result=b.place(chosen,at)
			check(not result.is_empty() and b.score>old_score,"valid simulation move scores")
			check(Board.restore(JSON.parse_string(JSON.stringify(b.snapshot())))!=null,"all simulated saves restore")
			moves+=1
		games+=1
	print("SIMULATION: ",games," games / ",moves," moves / ",Time.get_ticks_msec()-started," ms")
	check(root.get_node("Sound").music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"background music loops")
	var store := root.get_node("Store")
	store.data=store.defaults()
	store.data.coins=120
	check(store.save(),"atomic initial save")
	check(store.purchase("aurora",120),"theme purchase")
	check(store.data.coins==0 and store.data.theme=="aurora","purchase deducts exact price and selects")
	check(not store.purchase("sunset",180),"insufficient funds")
	check(store.purchase("aurora",120) and store.data.coins==0,"owned theme costs nothing")
	store.data.login=""
	check(store.login_reward()==15 and store.login_reward()==0,"daily login claimed once")
	check(store.daily_reward("2026-11-02")==80 and store.daily_reward("2026-11-02")==0,"daily completion claimed once")
	store.save()
	store.save()
	var expected: Dictionary = store.data.duplicate(true)
	var f := FileAccess.open("user://progress.json",FileAccess.WRITE)
	f.store_string("{broken"); f.close()
	store.load_data()
	check(store.data==JSON.parse_string(JSON.stringify(expected)),"corrupt primary recovers valid backup")
	store.data=store.defaults()
	store.save()
	check(load("res://scripts/admob_adapter.gd").can_instantiate(),"AdMob adapter compiles against pinned SDK")
	var ads := root.get_node("Ads")
	var coins: int = store.data.coins
	check(not ads.reward_available(),"desktop never simulates ads")
	check(not ads.reward(func(): store.data.coins+=25),"unavailable rewarded ad rejects request")
	check(store.data.coins==coins,"no SDK means no unearned coins")
	# Old saves migrate without losing earned progress or purchased themes.
	var legacy: Dictionary = store.defaults()
	legacy.erase("lab_charges")
	legacy.erase("result_bonus")
	legacy.coins = 321
	legacy.themes.append("aurora")
	legacy.theme = "aurora"
	f = FileAccess.open("user://progress.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy)); f.close()
	store.load_data()
	check(store.data.coins==321 and store.data.theme=="aurora","v1 save preserves currency and theme")
	check(store.data.lab_charges==0 and store.data.result_bonus.is_empty(),"v1 save receives new reward fields")
	legacy.erase("boosts")
	legacy.erase("boost_receipts")
	f = FileAccess.open("user://progress.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy)); f.close()
	store.load_data()
	check(store.data.boosts=={"hammer":1,"shuffle":2} and store.data.coins==321,"older profiles receive one free starter pack without losing progress")
	check(store.grant_rescue_pack("earned-1") and store.data.boosts=={"hammer":2,"shuffle":4},"one earned ad grants the exact useful rescue pack")
	check(not store.grant_rescue_pack("earned-1") and store.data.boosts.hammer==2,"duplicate earned callback cannot give a second rescue pack")
	store.load_data()
	check(store.data.boosts.shuffle==4 and not store.grant_rescue_pack("earned-1"),"inventory and reward receipt survive restart")
	store.data.coins=90
	check(store.buy_rescue_pack() and store.data.coins==0 and store.data.boosts.shuffle==6,"same pack can be earned without ads for its fixed coin price")
	check(not store.buy_rescue_pack() and store.data.boosts.shuffle==6,"insufficient coins do not mint boosters")
	var invalid_inventory_profile: Dictionary = store.defaults()
	invalid_inventory_profile.boosts.hammer = .5
	check(not store.validate(invalid_inventory_profile),"fractional inventory is rejected")
	store.data=store.defaults()
	check(store.add_plasma_charge() and store.data.lab_charges==1,"earned charge persists first step")
	store.load_data()
	check(store.data.lab_charges==1 and not "plasma" in store.data.themes,"partial lab progress survives restart")
	check(store.add_plasma_charge() and not "plasma" in store.data.themes,"two ads do not prematurely unlock theme")
	check(store.add_plasma_charge() and store.data.theme=="plasma","third earned charge unlocks and selects PLASMA")
	check(not store.add_plasma_charge() and store.data.lab_charges==3,"owned reward cannot be granted again")
	store.data=store.defaults()
	store.data.coins=240
	check(store.purchase("plasma",240) and store.data.coins==0,"PLASMA can be earned entirely without ads")
	check(not store.purchase("invented",-100) and store.data.coins==0,"invalid catalog entry cannot mint currency")
	store.data=store.defaults()
	store.data.coins=10
	store.prepare_result_bonus(90)
	var bonus_id: String = store.data.result_bonus.id
	check(not store.claim_result_bonus("wrong-run") and store.data.coins==10,"stale rewarded callback cannot claim another run")
	check(store.claim_result_bonus(bonus_id) and store.data.coins==100,"double reward adds the exact run award once")
	check(not store.claim_result_bonus(bonus_id) and store.data.coins==100,"duplicate reward event does not pay twice")
	store.load_data()
	check(not store.claim_result_bonus(bonus_id) and store.data.coins==100,"bonus claim persists across restart")
	store.prepare_result_bonus(10)
	check(store.data.result_bonus.id!=bonus_id and not store.claim_result_bonus(bonus_id),"new result replaces the old bonus identity")
	store.prepare_result_bonus(0)
	check(store.data.result_bonus.is_empty(),"zero-earned run offers no misleading double reward")
	var invalid_profile: Dictionary = store.defaults()
	invalid_profile.lab_charges=1.5
	check(not store.validate(invalid_profile),"fractional lab progress is rejected")
	var config := root.get_node("AppConfig")
	var original_config: Dictionary = config.data.duplicate(true)
	config.data.mode="production"
	config.data.audience="unconfigured"
	check(not config.ads_allowed(),"production with unset audience cannot load ads")
	config.data.audience="16+"
	config.data.admob={"app_id":"ca-app-pub-3940256099942544~3347511713","rewarded_id":"ca-app-pub-3940256099942544/5224354917","interstitial_id":"ca-app-pub-3940256099942544/1033173712"}
	check(not config.ads_allowed(),"production refuses Google test ad IDs")
	config.data=original_config
	store.data=store.defaults()
	store.save()

	# Everyone, including unknown/young ages, gets the same restrictive profile.
	var family_config: Dictionary = config.data.duplicate(true)
	check(config.advertising_enabled() and config.child_profile(),"classic family ad integration enabled")
	for band in ["unknown","under_13","13_15","16_17","18_plus"]:
		store.set_age_band(band)
		check(config.ads_allowed(),"test ad eligibility is independent of declared age: "+band)
	check(not config.age_choice_required(),"uniform child-directed profile does not collect an unnecessary age")
	config.data.ad_sdk="nextgen_unreviewed"
	check(not config.advertising_enabled(),"unselected SDK cannot be activated accidentally")
	config.data=family_config
	var adapter = load("res://scripts/admob_adapter.gd").new()
	var sdk_request: Dictionary = adapter.restricted_configuration().convert_to_dictionary()
	check(sdk_request.tag_for_child_directed_treatment==1,"SDK payload enables child-directed treatment")
	check(sdk_request.tag_for_under_age_of_consent==1,"SDK payload enables under-age treatment")
	check(sdk_request.max_ad_content_rating=="G","SDK payload limits creatives to G rating")
	check(adapter.restricted_request().convert_to_dictionary().extras.get("npa")=="1","every ad request explicitly disables personalisation")
	check(adapter.restricted_request().convert_to_dictionary().google_request_agent=="Godot-PoingStudios-4.3.1","exported requests use the packaged plugin version instead of a fallback")
	adapter.free()
	# Classic GMA's setAppMuted throws before initialize completes. Exercise the
	# actual adapter with a contract probe; this does not simulate impressions.
	var previous_bridge = MobileAds._plugin
	var previous_listener = MobileAds._current_on_initialization_complete_listener
	var bridge := NativeInitializationProbe.new()
	var startup = load("res://tests/initialization_adapter_probe.gd").new()
	MobileAds._plugin = bridge
	startup._enable_restricted_ads()
	check(bridge.calls==["configuration","initialize"],"startup configures privacy before init without calling pre-init mute")
	check(startup.loads==0 and not startup.initialized,"no loads before SDK initialization callback")
	bridge.completed = true
	startup.initialization_listener.on_initialization_complete.call(null)
	check(bridge.calls==["configuration","initialize","mute"],"mute is applied only after SDK initialization")
	check(startup.loads==2 and startup.initialized,"both formats load after successful initialization")
	MobileAds._plugin = previous_bridge
	MobileAds._current_on_initialization_complete_listener = previous_listener
	startup.free()
	bridge = NativeInitializationProbe.new()
	bridge.complete_immediately = true
	startup = load("res://tests/initialization_adapter_probe.gd").new()
	MobileAds._plugin = bridge
	startup._enable_restricted_ads()
	await process_frame
	check(startup.initialized and startup.loads==2,"synchronous native initialization callback cannot be lost before listener binding")
	check(not "INVALID_PREINIT_MUTE" in bridge.calls,"fast native callback keeps mute after initialization")
	startup.free()
	MobileAds._plugin = previous_bridge
	MobileAds._current_on_initialization_complete_listener = previous_listener
	var previous_reward_bridge = RewardedAdLoader._plugin
	var failure_bridge := NativeRewardFailureProbe.new()
	RewardedAdLoader._plugin = failure_bridge
	var actual_adapter = load("res://scripts/admob_adapter.gd").new()
	actual_adapter.initialized = true
	actual_adapter.consent_ready = true
	actual_adapter.load_rewarded()
	await process_frame
	check(not actual_adapter.reward_loading and actual_adapter.last_error.contains("NETWORK_TEST_FAILURE"),"native SDK errors leave loading state and preserve domain/code/message")
	check(actual_adapter.retry_reward_at>actual_adapter.now(),"failed SDK requests schedule a real retry")
	failure_bridge.fail_immediately = false
	actual_adapter.load_rewarded()
	actual_adapter.reward_deadline = -1
	actual_adapter._process(0)
	var timeout_message: String = actual_adapter.last_error
	failure_bridge.fail(failure_bridge.last_uid)
	await process_frame
	check(not actual_adapter.reward_loading and timeout_message==actual_adapter.last_error,"late failure cannot overwrite a timed-out request's current status")
	actual_adapter.free()
	RewardedAdLoader._plugin = previous_reward_bridge
	await process_frame
	check(RewardedAdLoader._pending.is_empty(),"completed SDK loaders release their retained GDScript references")
	store.data=store.defaults()
	store.save()

	var web_bridge := NativeWebViewProbe.new()
	var web_adapter = load("res://tests/webview_adapter_probe.gd").new()
	web_adapter.webview_plugin = web_bridge
	web_adapter.prepare_webview()
	check(web_adapter.webview_busy and web_adapter.init_calls==0,"SDK waits until the native JavaScript probe completes")
	await process_frame
	check(web_adapter.webview_ready and web_adapter.init_calls==1,"successful native JavaScript test unlocks SDK initialization")
	web_bridge.response = '{"ok":false,"provider":"test-provider","message":"WebView provider failed"}'
	web_adapter.prepare_webview()
	await process_frame
	check(not web_adapter.webview_ready and web_adapter.init_calls==1,"failed WebView preflight cannot start the ad SDK")
	check(web_adapter.last_error.contains("provider failed"),"WebView failure keeps its actual native diagnostic")
	web_adapter.free()

	var status_probe = load("res://scripts/admob_adapter.gd").new()
	status_probe.last_error = "com.google.android.gms.ads / 0: Unable to obtain a JavascriptEngine."
	var saved_status_adapter = ads.adapter
	ads.adapter = status_probe
	check(not ads.device_status(true).contains("com.google.android"),"technical SDK errors stay out of compact product labels")
	check(ads.details_text().contains("JavascriptEngine"),"full SDK error remains available in diagnostic details")
	var status_config = root.get_node("AppConfig")
	var previous_mode = status_config.data.get("mode","test")
	status_config.data["mode"]="test"
	check(ads.details_text().contains("test units"),"demo units are clearly identified in diagnostics")
	status_config.data["mode"]="production"
	check(ads.details_text().contains("production units") and not ads.details_text().contains("test units"),"production ad diagnostics do not claim Google demo units")
	status_config.data["mode"]=previous_mode
	status_probe.webview_logs="SDK root cause (test fixture)"
	check(ads.details_text().contains("SDK root cause (test fixture)"),"own-process SDK logs are included only in detailed diagnostics")
	status_probe.reward_loading = true
	check(ads.device_status(true).contains("Pobieranie"),"an active retry takes priority over the previous request's error")
	ads.adapter = saved_status_adapter
	status_probe.free()

	# Exercise the production-only UMP path with synchronous native replies.
	var original_consent_plugin = ConsentInformation._plugin
	var consent_probe := NativeConsentProbe.new()
	ConsentInformation._plugin = consent_probe
	var original_ump_config: Dictionary = config.data.duplicate(true)
	config.data.mode="production"
	config.data.admob={"app_id":"ca-app-pub-1234567890123456~1234567890","rewarded_id":"ca-app-pub-1234567890123456/1234567890","interstitial_id":"ca-app-pub-1234567890123456/0987654321"}
	for consent_status in [ConsentInformation.ConsentStatus.NOT_REQUIRED,ConsentInformation.ConsentStatus.OBTAINED,ConsentInformation.ConsentStatus.REQUIRED,ConsentInformation.ConsentStatus.UNKNOWN]:
		consent_probe.status = consent_status
		var consent_bridge := NativeInitializationProbe.new()
		consent_bridge.complete_immediately = true
		MobileAds._plugin = consent_bridge
		var production_adapter = load("res://tests/initialization_adapter_probe.gd").new()
		production_adapter.initialize()
		for frame in 3: await process_frame
		check(not production_adapter.consent_busy,"synchronous production UMP callback is not lost")
		check(consent_probe.parameters.get("tag_for_under_age_of_consent",false)==true,"production UMP request retains under-age restriction")
		if consent_status in [ConsentInformation.ConsentStatus.NOT_REQUIRED,ConsentInformation.ConsentStatus.OBTAINED]:
			check(production_adapter.initialized and production_adapter.loads==2,"resolved production consent starts both ad formats")
			check(consent_bridge.calls==["configuration","initialize","mute"],"production privacy and mute order is preserved")
		else:
			check(not production_adapter.consent_ready and consent_bridge.calls.is_empty(),"unresolved consent leaves real ad SDK unstarted")
		production_adapter.free()
	consent_probe.mode="failure"
	var failed_consent = load("res://tests/initialization_adapter_probe.gd").new()
	failed_consent.initialize()
	for frame in 2: await process_frame
	check(not failed_consent.consent_busy and not failed_consent.consent_ready,"immediate native UMP failure cannot leave loading stuck")
	check(failed_consent.last_error.contains("CONSENT_FIXTURE_FAILURE") and failed_consent.retry_consent_at>failed_consent.now(),"production consent failure keeps its reason and schedules retry")
	failed_consent.free()
	ConsentInformation._plugin = original_consent_plugin
	MobileAds._plugin = previous_bridge
	MobileAds._current_on_initialization_complete_listener = previous_listener
	config.data = original_ump_config
	UserMessagingPlatform.consent_information._on_consent_info_updated_success_callback = null
	UserMessagingPlatform.consent_information._on_consent_info_updated_failure_callback = null

	var previous_playback_plugin = RewardedAd._plugin
	for playback_mode in ["reward","closed","failure"]:
		var playback_native := NativeRewardPlaybackProbe.new()
		playback_native.mode = playback_mode
		RewardedAd._plugin = playback_native
		var playback_adapter = load("res://tests/initialization_adapter_probe.gd").new()
		playback_adapter.consent_ready = true
		playback_adapter.rewarded = RewardedAd.new(73)
		var playback_state = {"earned":0,"visibility":[]}
		playback_adapter.visibility.connect(func(active):playback_state.visibility.append(active))
		playback_adapter.show_reward(func():playback_state.earned+=1)
		for frame in 3: await process_frame
		check(playback_state.earned==(1 if playback_mode=="reward" else 0),"actual SDK reward bridge grants once on earned and never on close/show failure")
		check(playback_state.visibility==[true,false],"native close/show failure restores the game from fullscreen")
		check(playback_native.destroyed==[73] and playback_adapter.loads==1,"finished native ads are destroyed once and followed by one reload")
		if playback_mode=="failure":check(playback_adapter.last_error.contains("SHOW_FIXTURE_FAILURE"),"real show failure preserves native error details")
		playback_adapter.free()
	RewardedAd._plugin = previous_playback_plugin

	# Real scene, all screens, both languages and mouse/touch drag paths.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	check(main.screen=="menu" and not store.data.age_choice_made,"restricted ad startup skips unnecessary age collection")
	main.age_screen()
	var age_buttons: Array = main.ui.get_children().filter(func(n): return n is Button)
	check(age_buttons.size()==5 and age_buttons.all(func(n): return n.get_theme_stylebox("normal").bg_color==age_buttons[0].get_theme_stylebox("normal").bg_color),"neutral age choices use equal styling")
	check(age_buttons.all(func(n): return not "ad" in n.text.to_lower() and not "reward" in n.text.to_lower()),"age screen does not promise advertising benefits for older ages")
	for lang in ["pl","en"]:
		store.data.settings.language=lang
		for method in ["menu","modes","daily_screen","stats","shop","settings","info","licenses","lab","age_screen","boosters","ad_status"]:
			main.call(method)
			await process_frame
			check(main.ui.get_child_count()>0,"functional screen "+lang+" / "+method)
	main.new_game("classic")
	main.model.hand=hand([[0,0]])
	await process_frame
	var press := InputEventScreenTouch.new()
	press.index=0
	press.pressed=true
	press.position=main.stage.get_global_transform()*main.view.tray_rect(0).get_center()
	main._input(press)
	check(main.view.drag==0,"touch picks piece from generous tray hitbox")
	var drag := InputEventScreenDrag.new()
	drag.index=0
	drag.position=main.stage.get_global_transform()*(main.view.ORIGIN+Vector2(.5,1)*main.view.CELL+Vector2(0,main.view.DRAG_LIFT))
	main._input(drag)
	check(main.view.anchor==Vector2i.ZERO,"touch preview accounts for finger offset")
	press.pressed=false
	press.position=drag.position
	main._input(press)
	check(main.model.cells[0]>0 and main.model.score==10,"touch release places piece")
	main.model.hand=hand([[0,0]])
	await create_timer(.4).timeout
	var mouse := InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_LEFT
	mouse.pressed=true
	mouse.position=main.stage.get_global_transform()*main.view.tray_rect(0).get_center()
	main._input(mouse)
	mouse.pressed=false
	mouse.position=main.stage.get_global_transform()*(main.view.ORIGIN+Vector2(1.5,1)*main.view.CELL+Vector2(0,main.view.DRAG_LIFT))
	main._input(mouse)
	check(main.model.cells[1]>0 and main.model.score==20,"mouse drag places piece")
	main.model.cells.fill(0)
	for y in range(2,5):
		for x in range(2,5): main.model.cells[y*8+x]=2
	main.model.cells[0]=3
	store.data.boosts={"hammer":1,"shuffle":2}
	main.select_hammer()
	press.index=11
	press.pressed=true
	press.position=main.stage.get_global_transform()*(main.view.ORIGIN+Vector2(3.5,3.5)*main.view.CELL)
	main._input(press)
	press.pressed=false
	main._input(press)
	check(main.model.cells.count(2)==0 and main.model.cells[0]==3,"touch Hammer clears exactly the chosen 3x3 and preserves outside cells")
	check(store.data.boosts.hammer==0 and main.model.score==20,"Hammer consumes one charge without inventing points")
	store.load_data()
	check(store.data.boosts.hammer==0 and store.data.session.cells[0]==3,"inventory charge and affected board are saved together")
	var preserved_cells: Array = main.model.cells.duplicate()
	main.use_shuffle()
	check(main.model.cells==preserved_cells and main.model.hand.size()==3 and store.data.boosts.shuffle==1,"Shuffle keeps board and score and spends exactly one charge")
	store.data.boosts.hammer=1
	main.use_hammer(Vector2i(7,7))
	check(store.data.boosts.hammer==1 and main.model.cells==preserved_cells,"an empty Hammer target does not waste a charge")
	main.model.cells.fill(1)
	main.model.cells[0]=0
	main.model.hand=hand([[0,0],[1,0]])
	var games_before: int = store.data.stats.games
	main.no_moves()
	check(main.screen=="rescue" and not main.model.ended and store.data.stats.games==games_before,"stuck player gets a rescue choice before the run is counted as over")
	main.game_screen()
	main.use_shuffle()
	check(main.model.has_moves() and store.data.boosts.shuffle==0,"rescue Shuffle produces a playable hand on a crowded board")
	var reward_probe := EarnedRewardProbe.new()
	var previous_ad_adapter = ads.adapter
	var previous_last_reward: float = ads.last_reward
	ads.adapter=reward_probe
	ads.last_reward=-10000
	ads.dragging=false
	ads.fullscreen=false
	main.boosters(false)
	var inventory_before: Dictionary = store.data.boosts.duplicate()
	check(main.notice.get_rect().end.y<=225,"booster notices stay above the cards, clear of the bottom buttons")
	main.reward_rescue_pack()
	check(store.data.boosts==inventory_before,"clicking the ad offer alone never grants its reward")
	reward_probe.pending.call()
	check(store.data.boosts.hammer==inventory_before.hammer+1 and store.data.boosts.shuffle==inventory_before.shuffle+2,"earned event grants the advertised rescue bundle through the real UI flow")
	reward_probe.pending.call()
	check(store.data.boosts.hammer==inventory_before.hammer+1,"repeated earned event does not duplicate a pack")
	ads.adapter=previous_ad_adapter
	ads.last_reward=previous_last_reward
	reward_probe.free()
	main.new_game("time")
	main._process(1.0)
	check(main.model.remaining<180,"active time decreases")
	main.pause_game()
	var paused: float = main.model.remaining
	main._process(2.0)
	check(main.model.remaining==paused,"pause freezes timer")
	main.game_screen()
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(main.screen=="pause","background pauses and saves")
	main.game_screen()
	main.model.remaining=.1
	main._process(.2)
	check(main.screen=="result" and main.model.ended,"timer expiry displays real result screen")
	main.new_game("daily")
	var daily_before: Dictionary = main.model.snapshot()
	check(not main.model.shuffle_hand() and main.model.hammer(Vector2i.ZERO).is_empty() and main.model.snapshot()==daily_before,"Daily challenge cannot be changed by either booster")
	check(not store.spend_boost("hammer",main.model.snapshot()),"inventory transaction rejects using a booster in Daily")
	main.model.score=main.model.target
	main.finish(true)
	check(store.data.daily.get(main.model.day,false),"daily success recorded")
	var shown_bonus: Dictionary = store.data.result_bonus
	if not shown_bonus.is_empty():
		store.claim_result_bonus(shown_bonus.id)
		main.result_screen()
		check(main.ui.get_children().any(func(n): return n is Button and n.text=="Reward doubled ✓" and n.disabled),"earned bonus UI confirms claimed reward without a second ad")
	store.data.coins=240
	store.purchase("plasma",240)
	main.lab()
	check(main.ui.get_children().any(func(n): return n is Label and n.text=="PLASMA UNLOCKED ✓"),"owned PLASMA UI has no misleading remaining-ad requirement")
	main.queue_free()
	await create_timer(8.15).timeout
	check(root.get_node("Sound").music.playing,"music plays beyond the full eight-second loop")
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	print("CHECKS: ",checks,"; PASSED: ",checks-failures,"; FAILED: ",failures)
	quit(0 if failures==0 else 1)
