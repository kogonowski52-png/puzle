extends Control
var time := 0.0
var motion := true
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	if motion:
		time += delta
		queue_redraw()
func _draw() -> void:
	draw_texture_rect(preload("res://assets/backdrop.png"),Rect2(0,0,720,1280),false)
	for i in 22:
		var p := Vector2(fmod(i*137.1+29,720),fmod(i*91.7+time*(3+i%3),1280))
		draw_circle(p,1 if i%3 else 2,Color(.45,.75,1,.13+.08*sin(time+i)))
