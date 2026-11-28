extends Control
var time := 0.0
var motion := true
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	if motion:
		time += delta
		queue_redraw()
func _draw() -> void:
	draw_texture_rect(preload("res://assets/backdrop.png"),Rect2(Vector2.ZERO,size if size.x>0 else Vector2(720,1280)),false)
	if Store.data.theme=="cyber_galaxy":
		draw_rect(Rect2(Vector2.ZERO,size if size.x>0 else Vector2(720,1280)),Color(.025,.02,.09,.9))
		for layer in 6:
			draw_circle(Vector2(575,215),float(220-layer*28),Color(.4,.18,.8,.025))
			draw_circle(Vector2(90,1010),float(210-layer*27),Color(.08,.6,.8,.025))
		draw_arc(Vector2(595,220),92,0,TAU,64,Color(.7,.55,1,.2),2,true)
		draw_arc(Vector2(595,220),114,.2,PI+1,48,Color(.3,.85,1,.16),2,true)
		for star in 36:
			var point := Vector2(fmod(star*173.3+17,720),fmod(star*117.7+time*2,1280))
			draw_circle(point,1.6,Color(.8,.73,1,.2+.12*sin(time+star)))
	for i in 22:
		var p := Vector2(fmod(i*137.1+29,720),fmod(i*91.7+time*(3+i%3),1280))
		draw_circle(p,1 if i%3 else 2,Color(.45,.75,1,.13+.08*sin(time+i)))
