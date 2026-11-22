extends SceneTree
var main
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png("res://store/"+name+".png")!=OK:
		quit(1)
	print("SHOP SCREENSHOT ",name," ",image.get_size())
func run() -> void:
	root.size = Vector2i(720,1280)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.6).timeout
	var store = root.get_node("Store")
	store.data = store.defaults()
	main.shop()
	await capture("screenshot-08-shop-1.5-pl")
	main.premium_shop()
	await capture("screenshot-09-premium-1.5-pl")
	store.data.theme="cyber_galaxy"
	store.data.themes.append("cyber_galaxy")
	store.data.effect="nova"
	store.data.effects.append("nova")
	main.new_game("classic")
	await capture("screenshot-10-galaxy-1.5-pl")
	for resolution in [Vector2i(360,640),Vector2i(1080,1920),Vector2i(720,1600)]:
		root.size = resolution
		main.premium_shop()
		await create_timer(.3).timeout
		var area: Vector2 = root.get_visible_rect().size
		var end: Vector2 = main.stage.position+Vector2(720,1280)*main.stage.scale
		if main.stage.position.x<0 or main.stage.position.y<0 or end.x>area.x+.1 or end.y>area.y+.1: quit(1)
		print("SHOP LAYOUT FIT ",resolution)
	main.queue_free()
	root.get_node("Sound").shutdown()
	await create_timer(.15).timeout
	quit()
