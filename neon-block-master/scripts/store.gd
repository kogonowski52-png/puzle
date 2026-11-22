extends Node
## Recoverable atomic JSON saves, no external services.
const Board = preload("res://scripts/board.gd")
const PATH := "user://progress.json"
var data: Dictionary
var save_ok := true

func defaults() -> Dictionary:
	return {"version":1,"coins":0,"themes":["neon"],"theme":"neon","effects":["spark"],"effect":"spark",
		"settings":{"sound":true,"music":true,"vibration":true,"language":"pl"},
		"best":{"classic":0,"time":0,"daily":0},"stats":{"games":0,"moves":0,"lines":0,"points":0},
		"daily":{},"login":"","session":{},"ad_free":false,"lab_charges":0,"result_bonus":{},"age_band":"unknown","age_choice_made":false,
		"boosts":{"hammer":1,"shuffle":2},"boost_receipts":[]}

func _ready() -> void:
	load_data()

func validate(value: Variant) -> bool:
	if not value is Dictionary or value.get("version",0) != 1: return false
	if not value.get("coins") is float and not value.get("coins") is int: return false
	if value.coins < 0 or value.coins > 1000000000: return false
	for k in ["themes","effects"]:
		if not value.get(k) is Array or value[k].size() > 20: return false
		for entry in value[k]:
			if not entry is String: return false
	if not value.get("theme") in ["neon","aurora","sunset","plasma"] or not value.get("effect") in ["spark","orbit"]: return false
	if not value.theme in value.themes or not value.effect in value.effects: return false
	for k in ["settings","best","stats","daily","session"]:
		if not value.get(k) is Dictionary: return false
	for k in ["sound","music","vibration"]:
		if not value.settings.get(k) is bool: return false
	if not value.settings.get("language") in ["pl","en"]: return false
	for k in ["classic","time","daily"]:
		if not _number(value.best.get(k)): return false
	for k in ["games","moves","lines","points"]:
		if not _number(value.stats.get(k)): return false
	for k in value.daily:
		if not k is String or not value.daily[k] is bool: return false
	if not value.get("login") is String or not value.get("ad_free") is bool: return false
	if not value.get("age_band","unknown") in ["unknown","under_13","13_15","16_17","18_plus"]: return false
	if not value.get("age_choice_made",false) is bool: return false
	var boosts = value.get("boosts",{"hammer":1,"shuffle":2})
	if not boosts is Dictionary or boosts.size()!=2: return false
	for key in ["hammer","shuffle"]:
		if not _number(boosts.get(key)) or int(boosts[key])!=boosts[key] or boosts[key]>999: return false
	var receipts = value.get("boost_receipts",[])
	if not receipts is Array or receipts.size()>128: return false
	for receipt in receipts:
		if not receipt is String or receipt.is_empty() or receipt.length()>128: return false
	var charges = value.get("lab_charges",0)
	if not _number(charges) or int(charges) != charges or charges > 3: return false
	var bonus = value.get("result_bonus",{})
	if not bonus is Dictionary: return false
	if not bonus.is_empty():
		if not bonus.get("id") is String or bonus.id.is_empty(): return false
		if not _number(bonus.get("amount")) or bonus.amount < 1 or int(bonus.amount) != bonus.amount: return false
		if not bonus.get("claimed") is bool: return false
	if not value.session.is_empty() and Board.restore(value.session) == null: return false
	return true

func _number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v >= 0 and v <= 1000000000

func load_data() -> void:
	data = defaults()
	for file in [PATH, PATH+".bak"]:
		if not FileAccess.file_exists(file): continue
		var parsed = read_json(file)
		if validate(parsed):
			data = defaults()
			data.merge(parsed,true)
			return

func save() -> bool:
	var file := FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if file == null:
		save_ok = false
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var temp = read_json(PATH+".tmp")
	if not validate(temp):
		save_ok = false
		return false
	# Preserve the last valid backup even when recovering a corrupt primary.
	if FileAccess.file_exists(PATH):
		var old = read_json(PATH)
		if validate(old):
			if DirAccess.copy_absolute(PATH,PATH+".bak") != OK:
				save_ok = false
				return false
	save_ok = DirAccess.rename_absolute(PATH+".tmp",PATH) == OK
	return save_ok

func today() -> String:
	return Time.get_date_string_from_system()

func login_reward() -> int:
	# Local clock only: no claim of server-backed anti-cheat.
	if data.login >= today(): return 0
	data.login = today()
	data.coins += 15
	save()
	return 15

func daily_reward(date: String) -> int:
	if data.daily.get(date,false): return 0
	data.daily[date] = true
	data.coins += 80
	return 80

func purchase(id: String, price: int, effect := false) -> bool:
	var catalog := {"spark":0,"orbit":90} if effect else {"neon":0,"aurora":120,"sunset":180,"plasma":240}
	if not catalog.has(id) or int(catalog[id]) != price: return false
	var before := data.duplicate(true)
	var key := "effects" if effect else "themes"
	var active := "effect" if effect else "theme"
	if id in data[key]:
		data[active] = id
		if save(): return true
		data = before
		return false
	if data.coins < price: return false
	data.coins -= price
	data[key].append(id)
	data[active] = id
	if save(): return true
	data = before
	return false

func read_json(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return parser.data

func add_plasma_charge() -> bool:
	if "plasma" in data.themes: return false
	var before := data.duplicate(true)
	data.lab_charges = mini(3,int(data.lab_charges)+1)
	if data.lab_charges == 3:
		data.themes.append("plasma")
		data.theme = "plasma"
	if save(): return true
	data = before
	return false

func prepare_result_bonus(amount: int) -> void:
	data.result_bonus = {} if amount <= 0 else {"id":Crypto.new().generate_random_bytes(16).hex_encode(),"amount":amount,"claimed":false}

func claim_result_bonus(id: String) -> bool:
	var bonus: Dictionary = data.result_bonus
	if bonus.is_empty() or bonus.id != id or bonus.claimed: return false
	var before := data.duplicate(true)
	data.coins += int(bonus.amount)
	bonus.claimed = true
	if save(): return true
	data = before
	return false

func set_age_band(band: String) -> bool:
	if not band in ["unknown","under_13","13_15","16_17","18_plus"]: return false
	data.age_band = band
	data.age_choice_made = true
	return save()

func can_add_rescue_pack() -> bool:
	return int(data.boosts.hammer)<999 and int(data.boosts.shuffle)<=997

func grant_rescue_pack(receipt: String) -> bool:
	if receipt.is_empty() or receipt.length()>128 or receipt in data.boost_receipts or not can_add_rescue_pack(): return false
	var before := data.duplicate(true)
	data.boosts.hammer += 1
	data.boosts.shuffle += 2
	data.boost_receipts.append(receipt)
	while data.boost_receipts.size()>128: data.boost_receipts.pop_front()
	if save(): return true
	data = before
	return false

func buy_rescue_pack() -> bool:
	if data.coins<90 or not can_add_rescue_pack(): return false
	var before := data.duplicate(true)
	data.coins -= 90
	data.boosts.hammer += 1
	data.boosts.shuffle += 2
	if save(): return true
	data = before
	return false

func spend_boost(id: String, session: Dictionary) -> bool:
	if not id in ["hammer","shuffle"] or int(data.boosts.get(id,0))<1: return false
	var board = Board.restore(session)
	if board==null or board.mode=="daily" or board.ended: return false
	var before := data.duplicate(true)
	data.boosts[id] -= 1
	data.session = session
	if save(): return true
	data = before
	return false
