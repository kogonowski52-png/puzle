extends SceneTree
const Board = preload("res://scripts/board.gd")
var checks := 0
var failures := 0
var main
var store

class ConsentProbe extends RefCounted:
	signal on_consent_info_updated_success
	signal on_consent_info_updated_failure(error: Dictionary)
	var mode := "silent"
	var parameters: Dictionary
	func update(value):
		parameters = value
		if mode=="success": on_consent_info_updated_success.emit()
	func get_consent_status(): return 1

class InitProbe extends RefCounted:
	signal on_initialization_complete(status: Dictionary)
	var configuration: Dictionary
	func set_request_configuration(value,_devices): configuration=value
	func initialize(): on_initialization_complete.emit({})
	func set_app_muted(_value): pass

class RewardProbe extends RefCounted:
	signal on_rewarded_ad_loaded(uid: int)
	signal on_rewarded_ad_failed_to_load(uid: int,error: Dictionary)
	signal on_rewarded_ad_clicked(uid: int)
	signal on_rewarded_ad_dismissed_full_screen_content(uid: int)
	signal on_rewarded_ad_failed_to_show_full_screen_content(uid: int,error: Dictionary)
	signal on_rewarded_ad_impression(uid: int)
	signal on_rewarded_ad_showed_full_screen_content(uid: int)
	signal on_rewarded_ad_user_earned_reward(uid: int,item: Dictionary)
	var mode := "offline"
	var next := 0
	func create():
		next += 1
		return next
	func destroy(_uid): pass
	func load(_unit,_request,_keywords,uid):
		if mode=="offline": on_rewarded_ad_failed_to_load.emit(uid,{"code":2,"domain":"com.google.android.gms.ads","message":"OFFLINE_FIXTURE","cause":{},"response_info":{}})
		else: on_rewarded_ad_loaded.emit(uid)
	func show(uid):
		if mode=="show_failure":
			on_rewarded_ad_failed_to_show_full_screen_content.emit(uid,{"code":0,"domain":"com.google.android.gms.ads","message":"SHOW_FAILURE_FIXTURE","cause":{}})
			on_rewarded_ad_user_earned_reward.emit(uid,{"amount":1,"type":"pack"})
			return
		on_rewarded_ad_showed_full_screen_content.emit(uid)
		if mode=="earned":
			on_rewarded_ad_user_earned_reward.emit(uid,{"amount":1,"type":"pack"})
			on_rewarded_ad_user_earned_reward.emit(uid,{"amount":1,"type":"pack"})
		on_rewarded_ad_dismissed_full_screen_content.emit(uid)

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL V2: "+description)
func _initialize() -> void: call_deferred("run")
func touch(index: int, down: bool, point: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index
	event.pressed=down
	event.canceled=canceled
	event.position=main.stage.get_global_transform()*point
	main._input(event)
func move(index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=index
	event.position=main.stage.get_global_transform()*point
	main._input(event)
func pointer(at: Vector2i, shape: Array) -> Vector2:
	var size := Vector2(Board.shape_size(shape))
	return main.view.ORIGIN+Vector2(at)*main.view.CELL+Vector2(size.x*.5,size.y)*main.view.CELL+Vector2(0,main.view.DRAG_LIFT)
func prepare(shape: Array) -> void:
	main.new_game("classic")
	main.model.cells.fill(0)
	main.model.hand=[{"shape":shape,"color":1},{},{}]
func run() -> void:
	await process_frame
	store=root.get_node("Store")
	var historical=store.defaults()
	historical.erase("tutorial_done")
	historical.coins=245
	historical.stats.moves=42
	historical.best.classic=1680
	historical.boosts={"hammer":7,"shuffle":9}
	historical.neon_plus=true
	historical.ad_free=true
	historical.themes.append("cyber_galaxy")
	historical.effects.append("nova")
	historical.billing_receipts=["c".repeat(64)]
	var saved=FileAccess.open(store.PATH,FileAccess.WRITE)
	saved.store_string(JSON.stringify(historical))
	saved.close()
	store.load_data()
	check(store.data.tutorial_done and store.data.coins==245 and store.data.best.classic==1680 and store.data.boosts.hammer==7 and store.data.boosts.shuffle==9,"1.5 save migration preserves records, coins and inventory")
	check(store.data.neon_plus and store.data.ad_free and store.data.billing_receipts==historical.billing_receipts,"permanent purchases and receipts survive migration")
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	check(main.screen=="menu","startup reaches the real menu")
	for original in Board.SHAPES:
		var shape: Array=original.duplicate(true)
		for rotation in 4:
			var size=Board.shape_size(shape)
			for at in [Vector2i.ZERO,Vector2i(8-size.x,0),Vector2i(0,8-size.y),Vector2i(8-size.x,8-size.y)]:
				prepare(shape)
				touch(3,true,main.view.tray_rect(0).get_center())
				var target=pointer(at,shape)
				move(3,target)
				check(main.view.anchor==at,"all rotations preview the exact corner, including bottom row")
				check(main.view.drag_origin().y+size.y*main.view.CELL<=target.y-main.view.DRAG_LIFT+.01,"the whole held figure is above the finger")
				touch(3,false,target)
				var expected: Array=[]
				for cell in shape: expected.append((at.y+cell[1])*8+at.x+cell[0])
				var correct := true
				for i in 64:
					if (main.model.cells[i]>0)!=(i in expected): correct=false
				check(correct and main.model.score==shape.size()*10,"release matches every highlighted square")
				await process_frame
			var next: Array=[]
			for cell in shape: next.append([size.y-1-cell[1],cell[0]])
			shape=next
	prepare([[0,0]])
	var before=main.model.snapshot()
	var coins=store.data.coins
	touch(1,true,main.view.tray_rect(0).get_center())
	move(1,pointer(Vector2i(2,2),[[0,0]]))
	touch(1,false,pointer(Vector2i(3,2),[[0,0]]))
	check(main.model.cells[18]==1 and main.model.cells[19]==0,"touch-up jitter cannot move the piece away from the last shown preview")
	prepare([[0,0]])
	before=main.model.snapshot()
	touch(1,true,main.view.tray_rect(0).get_center())
	touch(2,true,Vector2(590,1180))
	check(main.touch_id==1 and main.screen=="game","second finger cannot take over the gesture or open boosters")
	touch(1,false,Vector2(590,1180))
	check(main.model.snapshot()==before and store.data.coins==coins and main.screen=="game","drop over toolbar cannot place and open the shop together")
	touch(1,true,main.view.tray_rect(0).get_center())
	move(1,pointer(Vector2i(0,0),[[0,0]]))
	touch(1,false,pointer(Vector2i(0,0),[[0,0]]),true)
	check(main.model.snapshot()==before and main.view.drag==-1,"cancelled touch preserves board and hand")
	main.model.cells[0]=3
	before=main.model.snapshot()
	touch(1,true,main.view.tray_rect(0).get_center())
	touch(1,false,pointer(Vector2i.ZERO,[[0,0]]))
	check(main.model.snapshot()==before,"occupied destination leaves score, hand and board unchanged")
	touch(1,true,main.view.tray_rect(0).get_center())
	main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(main.screen=="pause" and main.view.drag==-1,"leaving the app cancels the drag and pauses")
	store.load_data()
	main.resume_game()
	check(main.model.snapshot()==before,"reloading from the saved file restores the exact run")
	prepare([[0,0]])
	for row in 7: main.model.cells[row*8+7]=2
	for column in 7: main.model.cells[7*8+column]=3
	main.apply_move(0,Vector2i(7,7))
	check(main.model.score==285 and main.model.lines==2 and main.model.cells.count(0)==64,"row and column intersection clears once and awards the exact 285 points")
	check(main.view.line_waves.size()==2 and main.view.line_waves[0].index==7 and main.view.line_waves[1].index==7,"effects follow the actual cleared row and column")
	check(not main.game_instruction.visible,"first-move tutorial is hidden after success")
	main.model.hand=[{"shape":[[0,0]],"color":1},{},{}]
	main.apply_move(0,Vector2i(0,0))
	check(main.model.cells[0]==1 and main.model.moves==2,"next move is accepted while line animation is still running")
	store.data.boosts={"hammer":1,"shuffle":1}
	main.model.cells[0]=1
	main.model.cells[1]=2
	main.model.cells[8]=3
	main.model.cells[9]=4
	main.model.cells[18]=5
	main.use_hammer(Vector2i.ZERO)
	check(main.model.cells[0]==0 and main.model.cells[1]==0 and main.model.cells[8]==0 and main.model.cells[9]==0 and main.model.cells[18]==5,"corner hammer only removes its clipped 2 by 2 area")
	check(store.data.boosts.hammer==0,"edge hammer spends exactly one use")
	var cells=main.model.cells.duplicate()
	main.use_shuffle()
	check(main.model.cells==cells and store.data.boosts.shuffle==0,"shuffle changes hand and keeps board")
	store.data.coins=90
	store.data.boosts={"hammer":0,"shuffle":0}
	main.boosters(false)
	var coin_buttons=main.ui.get_children().filter(func(node):return node is Button and node.text.contains("90"))
	check(coin_buttons.size()==1 and not coin_buttons[0].disabled,"90 coin offer is accessible")
	coin_buttons[0].pressed.emit()
	check(store.data.coins==0 and store.data.boosts=={"hammer":1,"shuffle":2},"real coin purchase UI grants exactly one pack")
	main.new_game("time")
	main._process(2)
	var remaining=main.model.remaining
	main.pause_game()
	main._process(3)
	check(main.model.remaining==remaining,"Time Attack pauses its countdown")
	main.resume_game()
	check(main.model.remaining==remaining,"time run resumes with persisted remaining time")
	main.new_game("daily")
	main.model.score=main.model.target-10
	main.model.hand=[{"shape":[[0,0]],"color":1},{},{}]
	main.apply_move(0,Vector2i.ZERO)
	check(main.screen=="result" and store.data.daily.get(main.model.day,false),"Daily completion passes through the real result screen")
	var paid_coins=store.data.coins
	check(store.daily_reward(main.model.day)==0 and store.data.coins==paid_coins,"daily completion reward cannot repeat")
	main.new_game("classic")
	main.model.cells.fill(1)
	main.model.hand=[{"shape":[[0,0],[1,0]],"color":1},{},{}]
	main.model.score=int(store.data.best.classic)+100
	main.no_moves()
	check(main.screen=="rescue","no-moves flow offers its actual recovery choices")
	main.finish()
	check(main.screen=="result" and store.data.best.classic==main.model.score,"finishing updates the record and opens result screen")
	for resolution in [Vector2i(1080,2400),Vector2i(800,1280),Vector2i(1600,2560),Vector2i(1280,800)]:
		root.size=resolution
		prepare([[0,0]])
		await process_frame
		touch(3,true,main.view.tray_rect(0).get_center())
		move(3,pointer(Vector2i(7,7),[[0,0]]))
		touch(3,false,pointer(Vector2i(7,7),[[0,0]]))
		check(main.model.cells[63]==1,"scaled 20:9/tablet input still reaches the bottom-right cell")
		for language in ["pl","en"]:
			store.data.settings.language=language
			for method in ["menu","modes","game_screen","boosters","result_screen","settings","shop","premium_shop"]:
				main.call(method)
				await process_frame
				var area:Vector2=root.get_visible_rect().size
				var end:Vector2=main.stage.position+Vector2(720,1280)*main.stage.scale
				check(main.stage.position.x>=-.1 and main.stage.position.y>=-.1 and end.x<=area.x+.1 and end.y<=area.y+.1,"20:9 and tablet stage stays inside visible area")
				for node in main.ui.get_children():
					if node is Button: check(Rect2(Vector2.ZERO,Vector2(720,1280)).encloses(node.get_rect()),"PL/EN controls stay inside stage")
	main.queue_free()
	await process_frame
	await consent_tests()
	await reward_tests()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	print("V2 CHECKS: %d passed; %d failures" % [checks-failures,failures])
	quit(0 if failures==0 else 1)

func consent_tests() -> void:
	var config=root.get_node("AppConfig")
	var original=config.data.duplicate(true)
	var old_consent=ConsentInformation._plugin
	var old_mobile=MobileAds._plugin
	var old_listener=MobileAds._current_on_initialization_complete_listener
	var consent=ConsentProbe.new()
	ConsentInformation._plugin=consent
	var mobile=InitProbe.new()
	MobileAds._plugin=mobile
	config.data=original.duplicate(true)
	config.data.mode="production"
	config.data.admob={"app_id":"ca-app-pub-1234567890123456~1234567890","rewarded_id":"ca-app-pub-1234567890123456/1234567890","interstitial_id":"ca-app-pub-1234567890123456/0987654321"}
	var adapter=load("res://tests/initialization_adapter_probe.gd").new()
	adapter.initialize()
	check(adapter.consent_busy,"production waits for UMP instead of bypassing it")
	adapter.consent_deadline=adapter.now()-1
	adapter._process(0)
	check(not adapter.consent_busy and adapter.last_error.contains("timeout") and adapter.retry_consent_at>adapter.now(),"missing UMP callback times out and can retry")
	consent.on_consent_info_updated_success.emit()
	for frame in 3: await process_frame
	check(not adapter.initialized,"late callback from timed-out consent request is ignored")
	consent.mode="success"
	adapter.retry()
	for frame in 4: await process_frame
	check(adapter.initialized and adapter.loads==2,"connection recovery retries consent and initializes without app restart")
	check(consent.parameters.tag_for_under_age_of_consent==true and mobile.configuration.max_ad_content_rating=="G","under-age and G-rated privacy settings are preserved")
	adapter.free()
	ConsentInformation._plugin=old_consent
	MobileAds._plugin=old_mobile
	MobileAds._current_on_initialization_complete_listener=old_listener
	UserMessagingPlatform.consent_information._on_consent_info_updated_success_callback=null
	UserMessagingPlatform.consent_information._on_consent_info_updated_failure_callback=null
	config.data=original

func reward_tests() -> void:
	var ads=root.get_node("Ads")
	var previous_adapter=ads.adapter
	var previous_loader=RewardedAdLoader._plugin
	var previous_reward=RewardedAd._plugin
	var sdk=RewardProbe.new()
	RewardedAdLoader._plugin=sdk
	RewardedAd._plugin=sdk
	for scenario in ["earned","close","show_failure"]:
		var adapter=load("res://tests/reward_retry_probe.gd").new()
		adapter.initialized=true
		adapter.consent_ready=true
		sdk.mode="offline"
		adapter.load_rewarded()
		for frame in 3: await process_frame
		check(adapter.rewarded==null and adapter.last_error.contains("OFFLINE_FIXTURE"),"offline SDK error leaves reward unavailable and preserves its details")
		sdk.mode=scenario
		adapter.retry()
		for frame in 3: await process_frame
		check(adapter.rewarded!=null,"ad load can recover without restarting SDK or game")
		ads.adapter=adapter
		ads.last_reward=-10000
		ads.fullscreen=false
		adapter.visibility.connect(func(active):ads.fullscreen=active)
		adapter.reward_failed.connect(func():ads.last_reward=ads.previous_reward_time)
		var inventory=store.data.boosts.duplicate(true)
		var got= {"events":0}
		ads.reward(func():
			got.events+=1
			store.grant_rescue_pack("v2-"+scenario))
		for frame in 5: await process_frame
		var expected=1 if scenario=="earned" else 0
		check(got.events==expected and store.data.boosts.hammer==inventory.hammer+expected and store.data.boosts.shuffle==inventory.shuffle+expected*2,"only a genuine earned callback grants exactly 1 hammer and 2 shuffles, once")
		check(not ads.fullscreen,"SDK close or show failure releases full-screen state")
		if scenario=="show_failure": check(ads.last_reward<0,"failed show does not impose a fake reward cooldown")
		if adapter.rewarded!=null: adapter.rewarded.destroy();adapter.rewarded=null
		adapter.free()
		for frame in 3: await process_frame
	ads.adapter=previous_adapter
	RewardedAdLoader._plugin=previous_loader
	RewardedAd._plugin=previous_reward
