class_name PuzzleBoard
extends RefCounted
## Pure deterministic rules. Cell values are palette indices (0 means empty).
const SIZE := 8
const SHAPES := [
	[[0,0]], [[0,0],[1,0]], [[0,0],[1,0],[2,0]],
	[[0,0],[1,0],[2,0],[3,0]], [[0,0],[1,0],[2,0],[3,0],[4,0]],
	[[0,0],[1,0],[0,1],[1,1]], [[0,0],[0,1],[1,1]],
	[[0,0],[0,1],[0,2],[1,2]], [[0,0],[1,0],[2,0],[1,1]],
	[[1,0],[2,0],[0,1],[1,1]], [[0,0],[1,0],[1,1],[2,1]],
	[[0,0],[1,0],[2,0],[0,1],[1,1],[2,1]],
	[[0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2]]]
var cells: Array = []
var hand: Array = []
var score := 0
var combo := 0
var moves := 0
var lines := 0
var mode := "classic"
var remaining := 180.0
var day := ""
var target := 1600
var ended := false
var revived := false
var rng := RandomNumberGenerator.new()

func _init() -> void:
	cells.resize(64)
	cells.fill(0)

func begin(game_mode: String, date: String = "") -> void:
	mode = game_mode
	day = date
	if mode == "daily":
		rng.seed = date.hash()
		target = 1400 + (date.hash() % 5) * 200
	else:
		rng.randomize()
	deal()

static func shape_size(shape: Array) -> Vector2i:
	var size := Vector2i.ONE
	for p in shape:
		size.x = maxi(size.x, int(p[0]) + 1)
		size.y = maxi(size.y, int(p[1]) + 1)
	return size

func can_place(shape: Array, at: Vector2i) -> bool:
	if shape.is_empty(): return false
	for p in shape:
		var x := at.x + int(p[0])
		var y := at.y + int(p[1])
		if x < 0 or y < 0 or x >= SIZE or y >= SIZE: return false
		if cells[y * SIZE + x] != 0: return false
	return true

func fits(shape: Array) -> bool:
	for y in SIZE:
		for x in SIZE:
			if can_place(shape, Vector2i(x,y)): return true
	return false

func has_moves() -> bool:
	for piece in hand:
		if not piece.is_empty() and fits(piece.shape): return true
	return false

func deal() -> void:
	hand.clear()
	for i in 3:
		var shape: Array = SHAPES[rng.randi_range(0, SHAPES.size()-1)].duplicate(true)
		for rotation in rng.randi_range(0,3):
			var rotated: Array = []
			var h := shape_size(shape).y
			for p in shape: rotated.append([h-1-int(p[1]), int(p[0])])
			shape = rotated
		hand.append({"shape":shape, "color":rng.randi_range(1,5)})
	# At least one playable piece at a refill, if any shape can fit.
	# Existing pieces are never replaced after individual placements.
	if not has_moves():
		var candidates: Array = []
		for shape in SHAPES:
			if fits(shape): candidates.append(shape)
		if not candidates.is_empty():
			hand[0].shape = candidates[rng.randi_range(0,candidates.size()-1)].duplicate(true)

func place(index: int, at: Vector2i) -> Dictionary:
	if ended or index < 0 or index >= hand.size() or hand[index].is_empty(): return {}
	var piece: Dictionary = hand[index]
	if not can_place(piece.shape, at): return {}
	var placed: Array = []
	for p in piece.shape:
		var x := at.x+int(p[0])
		var y := at.y+int(p[1])
		cells[y*SIZE+x] = piece.color
		placed.append({"x":x,"y":y,"color":piece.color})
	var rows: Array = []
	var columns: Array = []
	for y in SIZE:
		var full := true
		for x in SIZE:
			if cells[y*SIZE+x] == 0: full = false
		if full: rows.append(y)
	for x in SIZE:
		var full := true
		for y in SIZE:
			if cells[y*SIZE+x] == 0: full = false
		if full: columns.append(x)
	var cleared: Array = []
	for y in SIZE:
		for x in SIZE:
			if y in rows or x in columns:
				cleared.append({"x":x,"y":y,"color":cells[y*SIZE+x]})
	for c in cleared: cells[c.y*SIZE+c.x] = 0
	var count := rows.size() + columns.size()
	combo = combo + 1 if count > 0 else 0
	var points: int = piece.shape.size()*10 + count*100 + maxi(0,count-1)*75 + maxi(0,combo-1)*50
	score += points
	moves += 1
	lines += count
	var seconds := 0
	if mode == "time" and count >= 2:
		seconds = mini(15, count*3)
		remaining += seconds
	hand[index] = {}
	if hand.all(func(p): return p.is_empty()): deal()
	return {"points":points,"lines":count,"cleared":cleared,"seconds":seconds,"placed":placed,"rows":rows,"columns":columns}

func revive() -> bool:
	if revived or mode == "daily" or (mode == "time" and remaining <= 0): return false
	revived = true
	ended = false
	# Explicit reward: clear the central four rows, then deal a new hand.
	for y in range(2,6):
		for x in SIZE: cells[y*SIZE+x] = 0
	deal()
	return true

func shuffle_hand() -> bool:
	if ended or mode == "daily" or cells.all(func(v): return v != 0): return false
	deal()
	return true

func hammer(at: Vector2i) -> Array:
	if ended or mode == "daily" or at.x < 0 or at.y < 0 or at.x >= SIZE or at.y >= SIZE: return []
	var cleared: Array = []
	for y in range(maxi(0,at.y-1),mini(SIZE,at.y+2)):
		for x in range(maxi(0,at.x-1),mini(SIZE,at.x+2)):
			if cells[y*SIZE+x] != 0:
				cleared.append({"x":x,"y":y,"color":cells[y*SIZE+x]})
				cells[y*SIZE+x] = 0
	return cleared

func snapshot() -> Dictionary:
	return {"cells":cells.duplicate(),"hand":hand.duplicate(true),"score":score,"combo":combo,
		"moves":moves,"lines":lines,"mode":mode,"remaining":remaining,"day":day,"target":target,
		"ended":ended,"revived":revived,"rng_state":str(rng.state),"rng_seed":str(rng.seed)}

static func restore(data: Dictionary) -> PuzzleBoard:
	if not data.get("cells") is Array or data.cells.size() != 64: return null
	for v in data.cells:
		if not (v is float or v is int) or v < 0 or v > 5 or int(v) != v: return null
	if not data.get("hand") is Array or data.hand.size() != 3: return null
	for piece in data.hand:
		if not piece is Dictionary: return null
		if piece.is_empty(): continue
		if not piece.get("shape") is Array or piece.shape.is_empty() or piece.shape.size() > 9: return null
		var color_value = piece.get("color")
		if not (color_value is int or color_value is float): return null
		if color_value < 1 or color_value > 5 or int(color_value) != color_value: return null
		var seen: Array = []
		for p in piece.shape:
			if not p is Array or p.size() != 2: return null
			for v in p:
				if not (v is float or v is int) or v < 0 or v > 4 or int(v) != v: return null
			if p in seen: return null
			seen.append(p)
	if not data.get("mode","") in ["classic","time","daily"]: return null
	for key in ["score","combo","moves","lines","target","remaining"]:
		var v = data.get(key)
		if not (v is int or v is float) or not is_finite(float(v)) or v < 0 or v > 1000000000: return null
	if not data.get("day","") is String: return null
	if not data.get("rng_seed","") is String or not data.get("rng_state","") is String: return null
	if not data.rng_seed.is_valid_int() or not data.rng_state.is_valid_int(): return null
	if not data.get("ended") is bool or not data.get("revived") is bool: return null
	var b := PuzzleBoard.new()
	b.cells = data.cells.duplicate()
	b.hand = data.hand.duplicate(true)
	# JSON numbers are floats. Restore the same canonical integer grid/figures.
	for index in b.cells.size(): b.cells[index] = int(b.cells[index])
	for piece in b.hand:
		if piece.is_empty(): continue
		piece.color = int(piece.color)
		for point in piece.shape:
			point[0] = int(point[0])
			point[1] = int(point[1])
	for key in ["score","combo","moves","lines","target"]: b.set(key, int(data[key]))
	b.mode = data.mode
	b.remaining = float(data.remaining)
	b.day = data.day
	b.ended = data.ended
	b.revived = data.revived
	b.rng.seed = int(data.rng_seed)
	b.rng.state = int(data.rng_state)
	return b
