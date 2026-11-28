extends SceneTree
var main
var output := ""
func _initialize() -> void: call_deferred("run")
func shot(name: String, delay := .35) -> void:
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png(output+"/"+name+".png")!=OK: quit(1)
	print("V2 SCREENSHOT ",name," ",image.get_size())
func hand(shape: Array, color := 1) -> void:
	main.model.hand=[{"shape":shape,"color":color},{"shape":[[0,0],[1,0]],"color":2},{"shape":[[0,0],[0,1],[0,2],[0,3],[0,4]],"color":4}]
func run() -> void:
	output = OS.get_environment("NEON_CAPTURE_OUTPUT")
	if output.is_empty(): output="/workspace/artifacts/neon-block-master-2.0-screenshots"
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(720,1280)
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.6).timeout
	main.background.motion=false
	main.background.queue_redraw()
	var store=root.get_node("Store")
	store.data=store.defaults()
	main.menu()
	await shot("05-menu")
	main.new_game("classic")
	main.model.cells.fill(0)
	for placement in [[[[0,0],[1,0],[0,1],[1,1]],Vector2i(0,5),1],[[[0,0],[1,0],[2,0]],Vector2i(0,3),3],[[[0,0],[1,0],[1,1]],Vector2i(3,5),2],[[[0,0],[0,1],[1,1]],Vector2i(2,0),4],[[[0,0],[1,0],[2,0],[2,1]],Vector2i(4,1),5],[[[0,0],[0,1],[1,1]],Vector2i(4,3),3]]:
		hand(placement[0],placement[2])
		main.apply_move(0,placement[1])
	hand([[0,0],[1,0],[2,0],[3,0]],2)
	main.view.queue_redraw()
	await shot("01-gameplay",.8)
	var touch:=InputEventScreenTouch.new()
	touch.index=7
	touch.pressed=true
	touch.position=main.stage.get_global_transform()*main.view.tray_rect(2).get_center()
	main._input(touch)
	var motion:=InputEventScreenDrag.new()
	motion.index=7
	motion.position=main.stage.get_global_transform()*(main.view.ORIGIN+Vector2(7.5,8)*main.view.CELL+Vector2(0,main.view.DRAG_LIFT))
	main._input(motion)
	if main.view.anchor!=Vector2i(7,3):
		printerr("Unexpected bottom-edge preview: ",main.view.anchor)
		quit(1)
	await shot("02-long-drag-bottom")
	touch.pressed=false
	touch.position=motion.position
	main._input(touch)
	main.new_game("classic")
	main.model.cells.fill(0)
	for at in [Vector2i(1,1),Vector2i(3,3),Vector2i(0,5)]:
		hand([[0,0],[1,0],[0,1]],int(at.x)%5+1)
		main.apply_move(0,at)
	for column in 7:
		hand([[0,0]],column%5+1)
		main.apply_move(0,Vector2i(column,7))
	for row in 7:
		hand([[0,0]],row%5+1)
		main.apply_move(0,Vector2i(7,row))
	await create_timer(.8).timeout
	hand([[0,0]],4)
	main.apply_move(0,Vector2i(7,7))
	await shot("03-line-clear",.07)
	main.boosters(false)
	await shot("04-boosters")
	main.new_game("classic")
	main.model.score=1250
	main.finish()
	await shot("06-result")
	for item in [["phone-20-9",Vector2i(1080,2400)],["tablet-7",Vector2i(800,1280)],["tablet-10",Vector2i(1600,2560)]]:
		root.size=item[1]
		main.new_game("classic")
		hand([[0,0],[0,1],[0,2],[0,3],[0,4]],1)
		await shot("layout-"+item[0])
		var area:Vector2=root.get_visible_rect().size
		var end:Vector2=main.stage.position+Vector2(720,1280)*main.stage.scale
		if main.stage.position.x<-.1 or main.stage.position.y<-.1 or end.x>area.x+.1 or end.y>area.y+.1: quit(1)
		print("V2 LAYOUT FIT ",item[0]," ",area)
	root.size=Vector2i(720,1280)
	store.data.settings.language="en"
	main.boosters(false)
	await shot("layout-en-boosters")
	main.menu()
	await shot("layout-en-menu")
	main.queue_free()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	quit()
