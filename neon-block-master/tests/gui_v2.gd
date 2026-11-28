extends SceneTree
var main
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures+=1
		printerr("GUI FAIL: "+message)
	else: print("GUI PASS: "+message)
func mouse_button(point: Vector2, down: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=down
	event.position=main.stage.get_global_transform()*point
	Input.parse_input_event(event)
	await process_frame
func click(point: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=main.stage.get_global_transform()*point
	Input.parse_input_event(motion)
	await process_frame
	await mouse_button(point,true)
	await mouse_button(point,false)
func touch(point: Vector2, index: int, down: bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=index
	event.pressed=down
	event.position=main.stage.get_global_transform()*point
	Input.parse_input_event(event)
	await process_frame
func run() -> void:
	root.size=Vector2i(720,1280)
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.6).timeout
	var store=root.get_node("Store")
	store.data.session={}
	main.menu()
	await click(Vector2(360,584))
	check(main.screen=="modes","real menu button opens mode selection")
	await click(Vector2(360,398))
	check(main.screen=="game" and main.model.mode=="classic","real Classic button starts game")
	main.model.hand=[{"shape":[[0,0]],"color":1},{},{}]
	main.model.cells.fill(0)
	var before=main.model.snapshot()
	await touch(main.view.tray_rect(0).get_center(),0,true)
	check(main.view.drag==0,"engine-delivered touch picks up a piece")
	await touch(Vector2(580,1182),1,true)
	check(main.screen=="game" and main.touch_id==0,"second finger cannot open boosters while dragging")
	await touch(Vector2(580,1182),0,false)
	await touch(Vector2(580,1182),1,false)
	check(main.screen=="game" and main.model.snapshot()==before,"drop on booster bar cancels gesture without opening shop")
	await create_timer(.3).timeout
	await click(Vector2(580,1182))
	check(main.screen=="boosters","independent next tap still opens the correct boosters screen")
	main.queue_free()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	quit(0 if failures==0 else 1)
