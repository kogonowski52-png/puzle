extends SceneTree
## Real renderer screenshots and layout/performance smoke test. Needs X11/desktop.
var main
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png("res://store/"+name+".png")
	if result != OK:
		printerr("SCREENSHOT FAILED: ",name)
		quit(1)
	print("SCREENSHOT ",name," ",image.get_size())
func run() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.6).timeout
	var store := root.get_node("Store")
	store.data=store.defaults()
	main.menu()
	await capture("screenshot-01-menu-pl")
	main.new_game("classic")
	main.model.rng.seed=20261102
	main.model.deal()
	var random := RandomNumberGenerator.new()
	random.seed=722
	for step in 7:
		var moves: Array = []
		for i in 3:
			if main.model.hand[i].is_empty(): continue
			for y in 8:
				for x in 8:
					if main.model.can_place(main.model.hand[i].shape,Vector2i(x,y)): moves.append([i,Vector2i(x,y)])
		if moves.is_empty(): break
		var move: Array = moves[random.randi_range(0,moves.size()-1)]
		main.apply_move(move[0],move[1])
	if main.screen=="game": await capture("screenshot-02-game-pl")
	main.daily_screen()
	await capture("screenshot-03-daily-pl")
	main.shop()
	await capture("screenshot-04-shop-pl")
	main.lab()
	await capture("screenshot-06-neon-lab-pl")
	main.boosters(false)
	await capture("screenshot-07-boosters-pl")
	store.data.settings.language="en"
	main.game_screen()
	await capture("screenshot-05-game-en")
	for resolution in [Vector2i(360,640),Vector2i(1080,1920),Vector2i(720,1600)]:
		root.size=resolution
		await create_timer(.2).timeout
		var area: Vector2 = root.get_visible_rect().size
		var bound: Vector2 = main.stage.position+Vector2(720,1280)*main.stage.scale
		if main.stage.position.x<-.1 or main.stage.position.y<-.1 or bound.x>area.x+.1 or bound.y>area.y+.1:
			printerr("LAYOUT OUTSIDE VIEWPORT ",resolution)
			quit(1)
		print("LAYOUT FIT ",resolution," viewport ",area)
	root.size=Vector2i(720,1280)
	await create_timer(.5).timeout
	var start := Time.get_ticks_msec()
	for i in 180: await process_frame
	var elapsed := Time.get_ticks_msec()-start
	print("RENDER: 180 frames / ",elapsed," ms; process ",Performance.get_monitor(Performance.TIME_PROCESS)*1000," ms; memory ",OS.get_static_memory_usage()/1048576.0," MiB")
	main.queue_free()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	quit()
