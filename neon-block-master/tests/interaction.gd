extends SceneTree
const Board = preload("res://scripts/board.gd")
var checks := 0
var failures := 0

class AdProbe extends Node:
	var rewarded: RefCounted
	var initializing := false
	var consent_busy := false
	var webview_busy := false
	var reward_loading := false
	var last_error := "NETWORK_FIXTURE"
	var retries := 0
	func retry(): retries += 1

class InterstitialFailureProbe extends RefCounted:
	signal on_interstitial_ad_loaded(uid: int)
	signal on_interstitial_ad_failed_to_load(uid: int,error: Dictionary)
	func create(): return 667
	func load(_unit,_request,_keywords,uid):
		on_interstitial_ad_failed_to_load.emit(uid,{"code":2,"domain":"com.google.android.gms.ads","message":"INTERSTITIAL_CALLBACK_FIXTURE","cause":{},"response_info":{}})

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.new_game("classic")
	for original in Board.SHAPES:
		var shape: Array = original.duplicate(true)
		for rotation in 4:
			main.model.hand = [{"shape":shape,"color":1},{"shape":shape,"color":2},{"shape":shape,"color":3}]
			for slot in 3:
				var cell: float = main.view.tray_cell_size(slot) if main.view.has_method("tray_cell_size") else 38.0
				var visual := Rect2(main.view.piece_origin(slot),Vector2(Board.shape_size(shape))*cell)
				check(main.view.tray_rect(slot).grow(-12).encloses(visual),"every rotated piece fits its tray with a safe margin")
			var next: Array = []
			var height := Board.shape_size(shape).y
			for point in shape: next.append([height-1-int(point[1]),int(point[0])])
			shape = next
	main.model.hand = [{"shape":[[0,0]],"color":1},{},{}]
	main.model.cells.fill(0)
	main.toast("OLD_INVALID_PLACEMENT")
	var event := InputEventScreenTouch.new()
	event.index = 14
	event.pressed = true
	event.position = main.stage.get_global_transform()*main.view.tray_rect(0).get_center()
	main._input(event)
	check(main.notice.text.is_empty(),"starting another drag clears an obsolete placement warning")
	event.pressed = false
	event.position = main.stage.get_global_transform()*Vector2(360,1250)
	main._input(event)
	check(main.model.score==0 and main.model.cells.count(0)==64 and not main.model.hand[0].is_empty(),"dropping outside the board cancels without spending or placing the piece")
	check(main.notice.text.is_empty(),"dropping back outside does not report a false collision")
	var ads = root.get_node("Ads")
	var previous_adapter = ads.adapter
	var previous_reward = ads.last_reward
	var probe := AdProbe.new()
	ads.adapter = probe
	ads.last_reward = -10000
	main.boosters(false)
	var buttons: Array = [main.rescue_ad_button]
	check(buttons.size()==1 and not buttons[0].text.contains("Obejrzyj"),"unavailable ads are offered as retry, not watch-and-claim")
	probe.reward_loading = true
	main.boosters(false)
	buttons = [main.rescue_ad_button]
	check(buttons.size()==1 and buttons[0].disabled,"a loading ad cannot be tapped as an available reward")
	probe.reward_loading = false
	probe.rewarded = RefCounted.new()
	main.boosters(false)
	buttons = [main.rescue_ad_button]
	check(buttons.size()==1 and not buttons[0].disabled and buttons[0].text.contains("Obejrzyj"),"watch-and-claim is offered only after an ad is really ready")
	ads.adapter = previous_adapter
	ads.last_reward = previous_reward
	probe.free()
	var previous_interstitial_plugin = InterstitialAdLoader._plugin
	InterstitialAdLoader._plugin = InterstitialFailureProbe.new()
	var adapter = load("res://scripts/admob_adapter.gd").new()
	adapter.initialized = true
	adapter.consent_ready = true
	adapter.last_error = "REWARDED_ERROR_TO_PRESERVE"
	adapter.load_interstitial()
	for frame in 4: await process_frame
	check(adapter.interstitial_error.contains("INTERSTITIAL_CALLBACK_FIXTURE"),"actual interstitial failure callback keeps its SDK error")
	check(adapter.events.any(func(line): return line.contains("INTERSTITIAL_CALLBACK_FIXTURE")),"interstitial failure is visible in the copied diagnostic events")
	check(adapter.last_error=="REWARDED_ERROR_TO_PRESERVE","interstitial diagnostics do not overwrite rewarded-ad error")
	var nested_error := AdError.new(0,"com.google.android.gms.ads","Top error",AdError.new(2,"network","INNER_NETWORK_REASON",null))
	check(adapter.describe_error(nested_error).contains("INNER_NETWORK_REASON"),"SDK nested causes are preserved instead of hidden behind a generic error")
	adapter.free()
	InterstitialAdLoader._plugin = previous_interstitial_plugin
	main.queue_free()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	print("INTERACTION CHECKS: %d passed; %d failed" % [checks-failures,failures])
	quit(0 if failures==0 else 1)
