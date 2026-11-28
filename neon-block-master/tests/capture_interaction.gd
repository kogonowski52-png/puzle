extends SceneTree
var main
func _initialize() -> void: call_deferred("run")
func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	root.size = Vector2i(720,1280)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.6).timeout
	var backdrop = main.background
	backdrop.motion = false
	backdrop.queue_redraw()
	main.new_game("classic")
	main.model.cells.fill(0)
	main.model.cells[0] = 2
	main.model.hand = [{"shape":[[0,0]],"color":1},{"shape":[[0,0],[0,1],[0,2],[0,3],[0,4]],"color":4},{"shape":[[0,0],[1,0],[2,0],[3,0],[4,0]],"color":3}]
	main.view.queue_redraw()
	await create_timer(.3).timeout
	var original: Image = await frame_image()
	var touch := InputEventScreenTouch.new()
	touch.index = 9
	touch.pressed = true
	touch.position = main.stage.get_global_transform()*main.view.tray_rect(0).get_center()
	main._input(touch)
	var move := InputEventScreenDrag.new()
	move.index = 9
	move.position = main.stage.get_global_transform()*(main.view.ORIGIN+Vector2(.5,1)*main.view.CELL+Vector2(0,main.view.DRAG_LIFT))
	main._input(move)
	var dragging: Image = await frame_image()
	touch.pressed = false
	touch.position = move.position
	main._input(touch)
	var after: Image = await frame_image()
	var region := Rect2i(main.view.ORIGIN,Vector2i.ONE*int(main.view.CELL*8))
	var clear := original.get_region(region).get_data()==after.get_region(region).get_data()
	var output := OS.get_environment("NEON_CAPTURE_OUTPUT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		original.save_png(output+"/before-drag.png")
		dragging.save_png(output+"/during-invalid-drag.png")
		after.save_png(output+"/after-invalid-drop.png")
	print("CANCELLED DRAG PIXELS RESTORED: ",clear)
	main.queue_free()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	quit(0 if clear else 1)
