extends SceneTree
var checks := 0
var failures := 0

class NativeProbe extends RefCounted:
	var buys: Array = []
	var finished: Array = []
	var restores := 0
	func buy(id): buys.append(id)
	func finish(id): finished.append(id)
	func restore(): restores += 1

class AdProbe extends Node:
	var interstitial = RefCounted.new()
	var rewarded = RefCounted.new()
	var shown := 0
	func show_interstitial(): shown += 1

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+description)

func event(value: Dictionary) -> void:
	root.get_node("Billing")._native_event(JSON.stringify(value))

func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var store = root.get_node("Store")
	var billing = root.get_node("Billing")
	var ads = root.get_node("Ads")
	var previous = store.data.duplicate(true)
	store.data = store.defaults()
	check(store.validate(store.data),"new defaults are valid")
	var old = store.defaults()
	old.erase("neon_plus")
	old.erase("billing_receipts")
	check(store.validate(old),"code 9 progress remains loadable without new fields")
	check(billing.native==null and billing.state=="android_only","desktop never simulates real billing")
	check(billing.price(billing.PLUS).is_empty(),"no hard-coded estimated checkout prices")
	var native = NativeProbe.new()
	billing.native = native
	billing.state = "ready"
	event({"type":"catalog","products":[{"id":billing.PLUS,"price":"14,99 zł"},{"id":billing.PACK,"price":"6,99 zł"}]})
	check(billing.available(billing.PLUS) and billing.price(billing.PACK)=="6,99 zł","catalog uses Play formatted prices")
	var Gate = load("res://scripts/parent_gate.gd")
	var gate = Gate.new()
	check(not billing.purchase(billing.PACK,gate,"wrong") and native.buys.is_empty(),"wrong parental answer never starts checkout")
	check(not billing.purchase(billing.PACK,gate,str(gate.left*gate.right)),"failed challenge cannot be reused")
	gate = Gate.new()
	gate.expires_at = -1
	check(not billing.purchase(billing.PACK,gate,str(gate.left*gate.right)),"expired parental action cannot buy")
	gate = Gate.new()
	check(billing.purchase(billing.PACK,gate,str(gate.left*gate.right)) and native.buys==[billing.PACK],"fresh correct challenge starts exactly one Play checkout")
	check(not billing.purchase(billing.PACK,gate,str(gate.left*gate.right)),"busy/repeated checkout cannot start another purchase")
	var inventory = store.data.boosts.duplicate(true)
	event({"type":"cancelled"})
	check(not billing.busy and store.data.boosts==inventory,"cancelled payment delivers nothing")
	event({"type":"pending"})
	check(billing.pending and store.data.boosts==inventory and native.finished.is_empty(),"pending payment neither grants nor consumes")
	var receipt := "a".repeat(64)
	event({"type":"verified","id":billing.PACK,"receipt":receipt})
	check(store.data.boosts.hammer==11 and store.data.boosts.shuffle==22,"verified pack grants the exact advertised quantities")
	check(native.finished==[receipt] and store.data.billing_receipts==[receipt],"durable delivery precedes native consume")
	store.load_data()
	event({"type":"verified","id":billing.PACK,"receipt":receipt})
	check(store.data.boosts.hammer==11 and store.data.boosts.shuffle==22,"replayed callback after disk reload never doubles inventory")
	event({"type":"settled"})
	check(not billing.busy and not billing.pending,"settled payment unlocks further purchases")
	var before = store.data.duplicate(true)
	event({"type":"verified","id":"unknown","receipt":"b".repeat(64)})
	event({"type":"verified","id":billing.PACK,"receipt":"not-a-receipt"})
	check(store.data==before and native.finished.size()==2,"invalid product/receipt never consumes or grants")
	var failed = load("res://tests/billing_failed_store.gd").new()
	failed.data = failed.defaults()
	var unchanged = failed.data.duplicate(true)
	check(not failed.apply_verified_purchase(billing.PACK,"c".repeat(64)) and failed.data==unchanged,"disk failure rolls back inventory and receipt atomically")
	failed.free()
	store.data.boosts = {"hammer":999,"shuffle":999}
	check(store.apply_verified_purchase(billing.PACK,"d".repeat(64)),"paid inventory is not silently lost at the free pack cap")
	check(store.data.boosts=={"hammer":1009,"shuffle":1019} and store.validate(store.data),"full paid pack remains valid and persistent beyond free cap")
	store.load_data()
	check(store.data.boosts.hammer==1009,"paid inventory survives reload")
	check(not store.purchase("cyber_galaxy",-1),"exclusive theme cannot be bought with negative coins")
	event({"type":"verified","id":billing.PLUS,"receipt":"e".repeat(64)})
	check(store.data.neon_plus and store.data.ad_free and "cyber_galaxy" in store.data.themes and "nova" in store.data.effects,"Neon Plus grants automatic ad removal and permanent cosmetics")
	check(store.purchase("cyber_galaxy",-1) and store.purchase("nova",-1,true),"owned premium cosmetics can be selected")
	check(store.validate(store.data),"premium theme and effect serialize correctly")
	var ad_probe = AdProbe.new()
	var previous_adapter = ads.adapter
	ads.adapter = ad_probe
	ads.completed_games = 2
	ads.between_games()
	check(ad_probe.shown==0 and ads.reward_available(),"Neon Plus stops automatic ads while leaving rewarded ads voluntary")
	ads.adapter = previous_adapter
	ad_probe.free()
	event({"type":"error","code":"restore_failed"})
	check(store.data.neon_plus,"network/restore failure never revokes cached ownership")
	billing.restore()
	check(native.restores==1,"restore explicitly queries Play ownership")
	event({"type":"ownership","plus":false,"pending":false})
	check(not store.data.neon_plus and not store.data.ad_free and store.data.theme=="neon" and store.data.effect=="spark","authoritative missing/refunded ownership removes permanent entitlement safely")
	event({"type":"verified","id":billing.PLUS,"receipt":"e".repeat(64)})
	check(store.data.neon_plus,"same owned purchase restores on a later successful query")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	for lang in ["pl","en"]:
		store.data.settings.language = lang
		main.premium_shop()
		await process_frame
		check(main.screen=="premium" and main.ui.get_children().any(func(node):return node is Button and node.text.contains("6,99 zł")),"premium screen exposes catalog price in "+lang)
		for node in main.ui.get_children():
			if node is Label: check(Rect2(Vector2.ZERO,Vector2(720,1280)).encloses(node.get_rect()),"premium labels fit portrait viewport in "+lang)
		var buttons = main.ui.get_children().filter(func(node):return node is Button)
		for i in buttons.size():
			check(Rect2(Vector2.ZERO,Vector2(720,1280)).encloses(buttons[i].get_rect()),"shop buttons fit portrait viewport")
			for j in range(i+1,buttons.size()): check(not buttons[i].get_rect().intersects(buttons[j].get_rect()),"shop buttons do not overlap")
		main.parent_purchase(billing.PACK)
		check(main.screen=="parent_gate","real purchase UI routes through parent challenge")
		main.back()
		check(main.screen=="shop","system back cancels parent access without checkout")
	main.queue_free()
	await process_frame
	await process_frame
	store.data = previous
	store.save()
	billing.native = null
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	print("BILLING CHECKS: %d passed; %d failures" % [checks-failures,failures])
	quit(0 if failures==0 else 1)
