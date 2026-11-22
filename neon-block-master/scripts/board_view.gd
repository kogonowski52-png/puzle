extends Control
## Draw-only canvas: input is managed by the screen controller in logical units.
const Board = preload("res://scripts/board.gd")
const ORIGIN := Vector2(56,344)
const CELL := 76.0
var model: PuzzleBoard
var active := false
var drag := -1
var pointer := Vector2.ZERO
var anchor := Vector2i.ZERO
var particles: Array = []
var flash := 0.0
var age := 0.0
var styles: Dictionary = {}
var hammer_preview := Vector2i(-1,-1)
const PALETTES := {
	"neon":[Color("51d9ff"),Color("b18aff"),Color("ff73b9"),Color("38e4d0"),Color("9be76b")],
	"aurora":[Color("74f8d2"),Color("66c2ff"),Color("a7f58d"),Color("d1bbff"),Color("67e5b8")],
	"sunset":[Color("ffb26f"),Color("ff768f"),Color("d896ff"),Color("ffe392"),Color("fe83cf")],
	"plasma":[Color("ffe176"),Color("88aaff"),Color("ff77dd"),Color("6dfff1"),Color("c1ff85")],
	"cyber_galaxy":[Color("b59bff"),Color("52eeff"),Color("ff88dc"),Color("8bafff"),Color("d8c0ff")]}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func palette() -> Array:
	return PALETTES.get(Store.data.theme, PALETTES.neon)

func block(rect: Rect2, color: Color, filled := true) -> void:
	var key := color.to_html()+str(filled)
	if not styles.has(key):
		var cached: Array = []
		if filled:
			var glow := StyleBoxFlat.new()
			glow.bg_color = Color(color,0.055)
			glow.set_corner_radius_all(13)
			cached.append(glow)
		var face := StyleBoxFlat.new()
		face.bg_color = color.darkened(0.65) if filled else Color("101b32")
		face.border_color = Color(color,0.85) if filled else Color("1a2943")
		face.set_border_width_all(2 if filled else 1)
		face.set_corner_radius_all(9)
		cached.append(face)
		styles[key] = cached
	var items: Array = styles[key]
	if filled: draw_style_box(items[0],rect.grow(4))
	draw_style_box(items[-1],rect)
	if filled:
		draw_line(rect.position+Vector2(10,6),rect.position+Vector2(rect.size.x-10,6),Color(color,0.7),2,true)

func tray_rect(index: int) -> Rect2:
	return Rect2(44+index*214,1020,204,150)

func piece_origin(index: int) -> Vector2:
	var s := Board.shape_size(model.hand[index].shape)
	return tray_rect(index).get_center()-Vector2(s)*19

func drag_origin() -> Vector2:
	var shape: Array = model.hand[drag].shape
	return pointer-Vector2(Board.shape_size(shape))*CELL/2-Vector2(0,100)

func update_anchor() -> void:
	anchor = Vector2i(((drag_origin()-ORIGIN)/CELL+Vector2(0.5,0.5)).floor())

func _process(delta: float) -> void:
	age += delta
	flash = maxf(0,flash-delta)
	var had_particles := not particles.is_empty()
	for p in particles:
		p.life -= delta
		p.pos += p.vel*delta
		p.vel.y += 100*delta
	particles = particles.filter(func(p): return p.life > 0)
	if active and (drag >= 0 or had_particles): queue_redraw()

func burst(cleared: Array) -> void:
	flash = 0.35
	for c in cleared:
		for i in 5:
			var a := randf()*TAU
			particles.append({"pos":ORIGIN+Vector2(c.x+0.5,c.y+0.5)*CELL,"vel":Vector2(cos(a),sin(a))*randf_range(40,200),"life":randf_range(.3,.8),"color":palette()[maxi(0,int(c.color)-1)]})

func _draw() -> void:
	if not active or model == null: return
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("0b1326")
	panel.border_color = Color("2a3d5b")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(20)
	panel.shadow_color = Color(0,0,0,.3)
	panel.shadow_size = 18
	draw_style_box(panel,Rect2(ORIGIN-Vector2(10,10),Vector2(628,628)))
	for y in 8:
		for x in 8:
			var value := int(model.cells[y*8+x])
			block(Rect2(ORIGIN+Vector2(x,y)*CELL+Vector2(4,4),Vector2.ONE*(CELL-8)),palette()[maxi(0,value-1)],value>0)
	if hammer_preview.x>=0 and hammer_preview.y>=0:
		for y in range(maxi(0,hammer_preview.y-1),mini(8,hammer_preview.y+2)):
			for x in range(maxi(0,hammer_preview.x-1),mini(8,hammer_preview.x+2)):
				draw_rect(Rect2(ORIGIN+Vector2(x,y)*CELL+Vector2(2,2),Vector2.ONE*(CELL-4)),Color(1,.7,.25,.28))
	if drag >= 0:
		var valid := model.can_place(model.hand[drag].shape,anchor)
		var color := Color("71f6a1") if valid else Color("ff5c86")
		for p in model.hand[drag].shape:
			var cell := anchor+Vector2i(int(p[0]),int(p[1]))
			if cell.x >= 0 and cell.y >= 0 and cell.x < 8 and cell.y < 8:
				block(Rect2(ORIGIN+Vector2(cell)*CELL+Vector2(4,4),Vector2.ONE*(CELL-8)),color)
	for i in 3:
		var slot := StyleBoxFlat.new()
		slot.bg_color = Color("0e172c")
		slot.border_color = Color("1d2b47")
		slot.set_border_width_all(1)
		slot.set_corner_radius_all(18)
		draw_style_box(slot,tray_rect(i))
		if i >= model.hand.size() or model.hand[i].is_empty() or drag == i: continue
		var piece: Dictionary = model.hand[i]
		for p in piece.shape:
			block(Rect2(piece_origin(i)+Vector2(p[0],p[1])*38+Vector2(2,2),Vector2(34,34)),palette()[int(piece.color)-1])
	if drag >= 0:
		for p in model.hand[drag].shape:
			block(Rect2(drag_origin()+Vector2(p[0],p[1])*CELL+Vector2(4,4),Vector2.ONE*(CELL-8)),palette()[int(model.hand[drag].color)-1])
	for p in particles:
		var c: Color = p.color
		c.a = minf(1,p.life*2)
		if Store.data.effect == "nova":
			draw_line(p.pos-Vector2(7,0),p.pos+Vector2(7,0),c,2,true)
			draw_line(p.pos-Vector2(0,7),p.pos+Vector2(0,7),c,2,true)
			draw_circle(p.pos,2,c,true,-1,true)
		elif Store.data.effect == "orbit": draw_arc(p.pos,5,0,TAU,10,c,2,true)
		else: draw_circle(p.pos,3.5,c,true,-1,true)
