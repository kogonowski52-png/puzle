extends Control
## Drawn preview uses the same palette and Nova shape as the actual game.
var age := 0.0
const COLORS = preload("res://scripts/board_view.gd").PALETTES.cyber_galaxy
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	age += delta
	queue_redraw()
func _draw() -> void:
	for x in 12:
		for y in 2:
			var color: Color = COLORS[(x+y)%5]
			var box := StyleBoxFlat.new()
			box.bg_color = color.darkened(.65)
			box.border_color = Color(color,.85)
			box.set_border_width_all(2)
			box.set_corner_radius_all(7)
			draw_style_box(box,Rect2(4+x*48,2+y*44,42,38))
	for i in 6:
		var center := Vector2(fmod(age*45+i*93,570)+5,44+sin(age+i)*30)
		var tint := Color(COLORS[i%5],.65)
		draw_line(center-Vector2(5,0),center+Vector2(5,0),tint,2,true)
		draw_line(center-Vector2(0,5),center+Vector2(0,5),tint,2,true)
