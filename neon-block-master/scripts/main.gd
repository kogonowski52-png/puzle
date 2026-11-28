extends Control
const Board = preload("res://scripts/board.gd")
const View = preload("res://scripts/board_view.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const WHITE := Color("eff3ff")
const MUTED := Color("889ab9")
const CYAN := Color("63e8e0")
const PURPLE := Color("b79aff")
var stage: Control
var background: Control
var ui: Control
var overlay: Control
var view: Control
var model: PuzzleBoard
var screen := "splash"
var score_label: Label
var sub_label: Label
var notice: Label
var toast_time := 0.0
var save_clock := 0.0
var touch_id := -1
var result_reward := 0
var regular := preload("res://assets/regular.ttf")
var bold := preload("res://assets/bold.ttf")
var captures := false
var hammer_aim := false
var hammer_touch := false
var boost_return_game := false
var ad_state_label: Label
var ad_detail_label: Label
var ad_ui_clock := 0.0
var hammer_button: Button
var game_instruction: Label
var premium_status: Label
var rescue_ad_button: Button
var suppress_mouse_until := 0
var drag_has_motion := false

func t(pl: String, en: String) -> String:
	return pl if Store.data.settings.language == "pl" else en

func _ready() -> void:
	get_tree().auto_accept_quit = false
	background = Backdrop.new()
	add_child(background)
	stage = Control.new()
	add_child(stage)
	view = View.new()
	stage.add_child(view)
	ui = Control.new()
	stage.add_child(ui)
	overlay = Control.new()
	stage.add_child(overlay)
	notice = Label.new()
	notice.position = Vector2(44,1190)
	notice.size = Vector2(632,55)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.clip_text = true
	notice.add_theme_font_override("font",bold)
	notice.add_theme_font_size_override("font_size",18)
	notice.add_theme_color_override("font_color",CYAN)
	stage.add_child(notice)
	get_viewport().size_changed.connect(resize_stage)
	resize_stage()
	Ads.availability_changed.connect(_ads_changed)
	Billing.changed.connect(_billing_changed)
	Billing.message.connect(_billing_message)
	Ads.fullscreen_changed.connect(func(active):
		if active and screen == "game": pause_game()
		elif screen == "result": result_screen())
	label(ui,"NEON",64,Vector2(40,440),Vector2(640,100),CYAN,true)
	label(ui,"BLOCK MASTER",36,Vector2(40,535),Vector2(640,65),WHITE,true)
	label(ui,t("ZNAJDŹ SWÓJ RYTM","FIND YOUR FLOW"),16,Vector2(40,628),Vector2(640,40),MUTED)
	var tween := create_tween()
	ui.modulate.a = 0
	tween.tween_property(ui,"modulate:a",1.0,.65)
	tween.tween_interval(.5)
	tween.tween_callback(func():
		launch_menu())

func resize_stage() -> void:
	var area := get_viewport_rect().size
	background.size = area
	background.queue_redraw()
	var inset := Vector2.ZERO
	if OS.get_name() == "Android":
		var safe := DisplayServer.get_display_safe_area()
		var ratio := area/Vector2(DisplayServer.window_get_size())
		inset = Vector2(safe.position)*ratio
		area = Vector2(safe.size)*ratio
	var factor := minf(area.x/720.0,area.y/1280.0)
	stage.scale = Vector2.ONE*factor
	stage.position = inset+(area-Vector2(720,1280)*factor)/2

func style(bg: Color, border: Color, radius := 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 24
	s.content_margin_right = 24
	return s

func label(parent: Node, text: String, font_size: int, pos: Vector2, dims: Vector2, color := WHITE, heavy := false, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.clip_text = true
	l.text = text
	l.position = pos
	l.size = dims
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font",bold if heavy else regular)
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(parent: Node, text: String, rect: Rect2, action: Callable, primary := false, disabled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_override("font",bold)
	b.add_theme_font_size_override("font_size",22)
	b.add_theme_color_override("font_color",Color("081a28") if primary else WHITE)
	b.add_theme_color_override("font_disabled_color",MUTED)
	b.add_theme_color_override("font_hover_color",Color("081a28") if primary else CYAN)
	b.add_theme_stylebox_override("normal",style(CYAN if primary else Color("14283e"),CYAN if primary else Color("2d4761"),mini(28,int(rect.size.y/2))))
	b.add_theme_stylebox_override("hover",style(CYAN.lightened(.1) if primary else Color("203b55"),CYAN,mini(28,int(rect.size.y/2))))
	b.add_theme_stylebox_override("pressed",style(Color("43b9bd") if primary else Color("233959"),PURPLE,mini(28,int(rect.size.y/2))))
	b.add_theme_stylebox_override("disabled",style(Color("101c2d"),Color("263a4e"),mini(28,int(rect.size.y/2))))
	b.add_theme_stylebox_override("focus",style(Color(0,0,0,0),PURPLE))
	b.disabled = disabled
	b.pressed.connect(func():
		Sound.play("click")
		action.call())
	parent.add_child(b)
	return b

func panel(parent: Node, rect: Rect2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel",style(Color("101a30"),Color("273550")))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func clear_nodes(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func change(next: String) -> void:
	screen = next
	cancel_drag()
	view.active = next == "game"
	view.queue_redraw()
	clear_nodes(ui)
	clear_nodes(overlay)
	notice.text = ""
	notice.position = Vector2(44,1190)
	notice.size = Vector2(632,55)
	hammer_aim = false
	hammer_touch = false
	view.hammer_preview = Vector2i(-1,-1)
	toast_time = 0.0
	ui.modulate.a = 0
	create_tween().tween_property(ui,"modulate:a",1.0,.18)

func header(title: String, subtitle := "") -> void:
	button(ui,"‹",Rect2(44,60,68,68),menu)
	label(ui,title,30,Vector2(130,60),Vector2(460,68),WHITE,true)
	if not subtitle.is_empty(): label(ui,subtitle,17,Vector2(44,142),Vector2(632,42),MUTED)

func can_resume() -> bool:
	var saved: Dictionary = Store.data.session
	return not saved.is_empty() and not saved.get("ended",true)

func menu() -> void:
	change("menu")
	label(ui,"NEON BLOCK MASTER",17,Vector2(38,35),Vector2(440,32),CYAN,true,HORIZONTAL_ALIGNMENT_LEFT)
	label(ui,"◈ "+str(int(Store.data.coins)),21,Vector2(488,35),Vector2(190,32),WHITE,true,HORIZONTAL_ALIGNMENT_RIGHT)
	var icon := Sprite2D.new()
	icon.texture = preload("res://assets/icon.svg")
	icon.position = Vector2(270,125)
	icon.centered = false
	icon.scale = Vector2.ONE*(180.0/512.0)
	ui.add_child(icon)
	var tw := create_tween().set_loops().bind_node(icon)
	tw.tween_property(icon,"position:y",115.0,1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(icon,"position:y",125.0,1.8).set_trans(Tween.TRANS_SINE)
	label(ui,"NEON",66,Vector2(40,326),Vector2(640,82),WHITE,true)
	label(ui,"BLOCK MASTER",30,Vector2(40,406),Vector2(640,46),CYAN,true)
	label(ui,t("Układaj. Łącz. Bij rekordy.","Place. Clear. Beat your best."),19,Vector2(40,465),Vector2(640,38),MUTED)
	button(ui,t("GRAJ  →","PLAY  →"),Rect2(48,538,624,92),modes,true).add_theme_font_size_override("font_size",27)
	if can_resume(): button(ui,t("Wznów zapisane klocki","Continue your saved game"),Rect2(48,650,624,70),resume_game)
	else: label(ui,t("Classic • Time Attack • Daily","Classic • Time Attack • Daily"),17,Vector2(48,650),Vector2(624,48),MUTED)
	button(ui,t("Wyzwanie dnia","Daily challenge"),Rect2(48,756,300,88),daily_screen)
	button(ui,t("Sklep","Shop"),Rect2(372,756,300,88),shop)
	button(ui,t("Pomocnicy  •  %d / %d","Boosters  •  %d / %d") % [Store.data.boosts.hammer,Store.data.boosts.shuffle],Rect2(48,870,624,82),func(): boosters(false))
	button(ui,t("Statystyki","Statistics"),Rect2(48,978,300,72),stats)
	button(ui,t("Ustawienia","Settings"),Rect2(372,978,300,72),settings)
	button(ui,t("Jak grać • Prywatność","How to play • Privacy"),Rect2(48,1100,624,58),info)
	if OS.has_feature("ads_test"): label(ui,t("TEST 2.0 • reklamy demonstracyjne Google","TEST 2.0 • Google demo advertisements"),15,Vector2(36,1200),Vector2(648,30),MUTED)

func modes() -> void:
	change("modes")
	header(t("Twój rytm gry","Your way to play"),t("Wybierz wyzwanie. Ułóż swój rekord.","Pick a challenge. Build your best."))
	var names := ["CLASSIC","TIME ATTACK","DAILY CHALLENGE"]
	var details := [t("Bez pośpiechu. Bez końca. Tylko Ty i plansza.","No rush. No end. Just you and the board."),t("3 minuty. Wiele linii = dodatkowe sekundy.","3 minutes. Clear multiple lines for extra time."),t("Ta sama data. Ten sam układ. Nowy cel.","Same date. Same sequence. A fresh goal.")]
	for i in 3:
		var y := 235+i*253
		panel(ui,Rect2(44,y,632,218))
		label(ui,"0"+str(i+1)+" / "+names[i],25,Vector2(70,y+22),Vector2(580,40),CYAN if i==0 else PURPLE,true,HORIZONTAL_ALIGNMENT_LEFT)
		label(ui,details[i],17,Vector2(70,y+74),Vector2(580,40),MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		var mode: String = ["classic","time","daily"][i]
		button(ui,t("Rozpocznij  →","Start  →"),Rect2(70,y+132,580,62),func(): request_start(mode),i==0)
	if can_resume(): label(ui,t("Nowa gra zastąpi zapisany postęp — potwierdzisz wybór.","Starting a new game replaces your save — confirmation follows."),15,Vector2(44,1060),Vector2(632,60),MUTED)

func request_start(mode: String) -> void:
	if can_resume():
		modal(t("Rozpocząć nową grę?","Start a new game?"),t("Obecny zapis rozgrywki zostanie zastąpiony.","Your current saved run will be replaced."),[
			[t("Nowa gra","New game"),func(): new_game(mode)],
			[t("Wznów zapis","Resume saved run"),resume_game],
			[t("Anuluj","Cancel"),func(): clear_nodes(overlay)]])
	else: new_game(mode)

func new_game(mode: String) -> void:
	Store.data.result_bonus = {}
	model = Board.new()
	model.begin(mode,Store.today())
	checkpoint()
	game_screen()

func resume_game() -> void:
	model = Board.restore(Store.data.session)
	if model == null:
		Store.data.session = {}
		Store.save()
		menu()
		return
	game_screen()
	if model.remaining <= 0 and model.mode == "time": finish()
	elif not model.has_moves(): no_moves()

func game_screen() -> void:
	change("game")
	if view.model!=model: view.reset_effects()
	view.model = model
	view.active = true
	label(ui,"NEON / "+model.mode.to_upper(),16,Vector2(38,28),Vector2(470,28),CYAN,true,HORIZONTAL_ALIGNMENT_LEFT)
	button(ui,"Ⅱ",Rect2(614,34,68,68),pause_game).tooltip_text = t("Pauza","Pause")
	label(ui,t("WYNIK","SCORE"),13,Vector2(38,70),Vector2(300,25),MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	score_label = label(ui,str(model.score),48,Vector2(34,91),Vector2(340,59),WHITE,true,HORIZONTAL_ALIGNMENT_LEFT)
	label(ui,t("REKORD","BEST"),13,Vector2(408,69),Vector2(164,25),MUTED)
	label(ui,str(int(Store.data.best[model.mode])),27,Vector2(408,98),Vector2(164,43),PURPLE,true)
	sub_label = label(ui,"",16,Vector2(36,151),Vector2(648,27),CYAN)
	game_instruction = label(ui,t("Przeciągnij figurę. Puść na podświetlonych polach.","Drag a block. Release on the highlighted cells."),17,Vector2(36,855),Vector2(648,64),MUTED)
	game_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_instruction.visible = not Store.data.tutorial_done
	notice.position = Vector2(36,855)
	notice.size = Vector2(648,64)
	if model.mode!="daily":
		hammer_button = boost_button(preload("res://assets/ui/hammer.svg"),int(Store.data.boosts.hammer),Rect2(42,1150,190,64),select_hammer,Store.data.boosts.hammer<1,t("Młotek 3×3","3×3 Hammer"))
		boost_button(preload("res://assets/ui/shuffle.svg"),int(Store.data.boosts.shuffle),Rect2(265,1150,190,64),use_shuffle,Store.data.boosts.shuffle<1,t("Zmiana figur","Shuffle pieces"))
		button(ui,t("+ Pakiet","+ Pack"),Rect2(488,1150,190,64),func(): boosters(true),true).add_theme_font_size_override("font_size",19)
		label(ui,t("Młotek","Hammer"),14,Vector2(42,1220),Vector2(190,28),MUTED)
		label(ui,t("Zmiana","Shuffle"),14,Vector2(265,1220),Vector2(190,28),MUTED)
	else:
		label(ui,t("Daily • te same zasady dla wszystkich","Daily • the same rules for everyone"),16,Vector2(36,1160),Vector2(648,48),MUTED)
	update_hud()

func boost_button(texture: Texture2D, count: int, rect: Rect2, action: Callable, disabled: bool, hint: String) -> Button:
	var control := button(ui,"×"+str(count),rect,action,false,disabled)
	control.add_theme_font_size_override("font_size",25)
	control.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	control.tooltip_text = hint
	var icon := TextureRect.new()
	icon.texture = texture
	icon.position = Vector2(18,10)
	icon.size = Vector2(44,44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(44,44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(icon)
	return control

func update_hud() -> void:
	if screen != "game" or not is_instance_valid(score_label): return
	score_label.text = str(model.score)
	if model.mode == "time":
		var seconds := ceili(model.remaining)
		sub_label.text = "%02d:%02d" % [seconds/60,seconds%60]+("  •  COMBO ×"+str(model.combo) if model.combo>1 else "")
		sub_label.modulate = Color("ff738e") if seconds < 30 else WHITE
	elif model.mode == "daily": sub_label.text = model.day+"   /   "+str(model.score)+" / "+str(model.target)
	else: sub_label.text = "COMBO ×"+str(model.combo) if model.combo>1 else ""

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()
		return
	if screen != "game" or Ads.fullscreen: return
	var pos := Vector2.ZERO
	var pressed := false
	var released := false
	if event is InputEventScreenTouch:
		if touch_id >= 0 and event.index != touch_id:
			get_viewport().set_input_as_handled()
			return
		if event.canceled and touch_id==event.index:
			cancel_drag()
			get_viewport().set_input_as_handled()
			return
		pos = stage.get_global_transform().affine_inverse()*event.position
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventScreenDrag:
		if event.index != touch_id: return
		pos = stage.get_global_transform().affine_inverse()*event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if touch_id >= 0 or Time.get_ticks_msec()<suppress_mouse_until:
			get_viewport().set_input_as_handled()
			return
		pos = stage.get_global_transform().affine_inverse()*event.position
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventMouseMotion:
		if touch_id >= 0 or Time.get_ticks_msec()<suppress_mouse_until:
			get_viewport().set_input_as_handled()
			return
		pos = stage.get_global_transform().affine_inverse()*event.position
	else: return
	if hammer_aim:
		var cell := Vector2i(((pos-View.ORIGIN)/View.CELL).floor())
		var inside := cell.x>=0 and cell.x<8 and cell.y>=0 and cell.y<8
		if pressed and inside:
			hammer_touch = true
			if event is InputEventScreenTouch: touch_id = event.index
		if hammer_touch:
			view.hammer_preview = cell if inside else Vector2i(-1,-1)
			view.queue_redraw()
			if released:
				hammer_touch = false
				touch_id = -1
				if inside: use_hammer(cell)
			get_viewport().set_input_as_handled()
		return
	if pressed:
		for i in 3:
			if not model.hand[i].is_empty() and view.tray_rect(i).has_point(pos):
				view.drag = i
				drag_has_motion = false
				notice.text = ""
				toast_time = 0
				if is_instance_valid(game_instruction): game_instruction.hide()
				if event is InputEventScreenTouch: touch_id = event.index
				Ads.dragging = true
				break
	if view.drag < 0: return
	get_viewport().set_input_as_handled()
	if touch_id>=0: suppress_mouse_until = Time.get_ticks_msec()+250
	# Keep the preview target on release, even when touch-up coordinates jitter.
	if not released or not drag_has_motion:
		view.pointer = pos
		view.update_anchor()
	if event is InputEventScreenDrag or event is InputEventMouseMotion: drag_has_motion = true
	if released:
		var at: Vector2i = view.anchor
		var index: int = view.drag
		var inside: bool = view.anchor_inside_board()
		cancel_drag()
		var over_tray := false
		for slot in 3: over_tray = over_tray or view.tray_rect(slot).has_point(pos)
		var drop_area := Rect2(View.ORIGIN,Vector2(View.CELL*8,View.TRAY_Y-View.ORIGIN.y))
		if inside and not over_tray and drop_area.has_point(pos): apply_move(index,at)
		get_viewport().set_input_as_handled()

func cancel_drag() -> void:
	if touch_id>=0: suppress_mouse_until = Time.get_ticks_msec()+250
	if view != null:
		view.drag = -1
		view.queue_redraw()
	touch_id = -1
	Ads.dragging = false
	drag_has_motion = false
	if screen=="game" and is_instance_valid(game_instruction): game_instruction.visible = hammer_aim or not Store.data.tutorial_done

func apply_move(index: int, at: Vector2i) -> void:
	var result := model.place(index,at)
	if result.is_empty():
		toast(t("Ta figura tutaj nie pasuje","This block doesn't fit here"))
		return
	Store.data.stats.moves += 1
	Store.data.stats.lines += result.lines
	Store.data.stats.points += result.points
	Store.data.tutorial_done = true
	if is_instance_valid(game_instruction): game_instruction.hide()
	Sound.haptic()
	Sound.play("combo" if model.combo > 1 or result.lines>1 else ("clear" if result.lines>0 else "place"))
	view.land(result.placed)
	view.burst(result.cleared,result.rows,result.columns)
	view.queue_redraw()
	if result.lines > 0:
		toast("+"+str(result.points)+t(" • Linie: %d"," • Lines: %d") % result.lines+(" • COMBO ×"+str(model.combo) if model.combo>1 else "")+("  +"+str(result.seconds)+"s" if result.seconds>0 else ""))
	update_hud()
	checkpoint()
	if model.mode == "daily" and model.score >= model.target: finish(true)
	elif not model.has_moves(): no_moves()

func checkpoint() -> void:
	if model != null: Store.data.session = model.snapshot()
	Store.save()
	if not Store.save_ok and notice != null: toast(t("Nie udało się zapisać. Sprawdź wolne miejsce.","Save failed. Check your free storage."))

func _process(delta: float) -> void:
	ad_ui_clock += delta
	if ad_ui_clock>=1:
		ad_ui_clock = 0
		if is_instance_valid(ad_state_label): ad_state_label.text = Ads.status_text()
		if is_instance_valid(ad_detail_label): ad_detail_label.text = Ads.details_text()
		if screen=="boosters" and is_instance_valid(rescue_ad_button): update_rescue_ad_button()
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0:
			notice.text = ""
			if screen=="game" and is_instance_valid(game_instruction): game_instruction.visible = hammer_aim or not Store.data.tutorial_done
	if screen != "game" or model == null or Ads.fullscreen: return
	if model.mode == "time":
		model.remaining = maxf(0,model.remaining-delta)
		update_hud()
		if model.remaining <= 0: finish()
	save_clock += delta
	if save_clock > 5:
		save_clock = 0
		checkpoint()

func pause_game() -> void:
	if screen != "game": return
	cancel_drag()
	checkpoint()
	screen = "pause"
	view.active = false
	modal(t("Chwila oddechu","Take a breath"),t("Twój postęp jest zapisany.","Your progress is saved."),[
		[t("Wznów","Resume"),game_screen],
		[t("Menu główne","Main menu"),menu]])

func modal(title: String, body: String, actions: Array) -> void:
	clear_nodes(overlay)
	var shade := ColorRect.new()
	shade.size = Vector2(720,1280)
	shade.color = Color(0.015,.025,.06,.93)
	overlay.add_child(shade)
	var height := 220+actions.size()*92
	var y := (1280-height)/2
	panel(overlay,Rect2(44,y,632,height))
	label(overlay,title,29,Vector2(66,y+25),Vector2(588,60),WHITE,true)
	label(overlay,body,17,Vector2(66,y+97),Vector2(588,60),MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in actions.size(): button(overlay,actions[i][0],Rect2(76,y+182+i*92,568,70),actions[i][1],i==0)

func finish(success := false) -> void:
	if model.ended: return
	cancel_drag()
	model.ended = true
	Store.data.stats.games += 1
	result_reward = 0
	if model.score > Store.data.best[model.mode]:
		Store.data.best[model.mode] = model.score
		if not model.revived:
			Store.data.coins += 10
			result_reward += 10
	if success: result_reward += Store.daily_reward(model.day)
	Store.prepare_result_bonus(result_reward)
	checkpoint()
	Sound.play("combo" if success else "end")
	result_screen()

func result_screen() -> void:
	change("result")
	var success := model.mode=="daily" and model.score>=model.target
	label(ui,t("WYZWANIE UKOŃCZONE","CHALLENGE COMPLETE") if success else t("TWÓJ WYNIK","YOUR SCORE"),20,Vector2(44,155),Vector2(632,50),CYAN,true)
	label(ui,str(model.score),96,Vector2(44,252),Vector2(632,135),WHITE,true)
	label(ui,t("punktów","points"),22,Vector2(44,391),Vector2(632,44),MUTED)
	label(ui,t("Rekord: ","Best: ")+str(int(Store.data.best[model.mode])),26,Vector2(44,466),Vector2(632,48),PURPLE,true)
	label(ui,"+"+str(result_reward)+" NEON COINS",20,Vector2(44,544),Vector2(632,44),CYAN)
	label(ui,t("Ruchy: %d  •  Linie: %d","Moves: %d  •  Lines: %d") % [model.moves,model.lines],18,Vector2(48,590),Vector2(624,36),MUTED)
	button(ui,t("Jeszcze raz","Play again"),Rect2(48,655,624,84),func():
		Ads.between_games()
		new_game(model.mode),true)
	var can_revive := AppConfig.advertising_enabled() and not model.revived and model.mode!="daily" and not (model.mode=="time" and model.remaining<=0)
	if can_revive:
		button(ui,t("Reklama: druga szansa","Watch ad: second chance"),Rect2(60,761,600,78),revive_with_ad,false,not Ads.reward_available())
		label(ui,t("Usuwa środkowe 4 rzędy. Raz na rozgrywkę.","Clears the middle 4 rows. Once per run."),16,Vector2(44,849),Vector2(632,44),MUTED)
		if not Ads.reward_available(): label(ui,t("Reklama jest teraz niedostępna.","No ad is available right now."),16,Vector2(44,893),Vector2(632,36),MUTED)
	button(ui,t("Menu główne","Main menu"),Rect2(48,984,624,78),menu)
	var bonus: Dictionary = Store.data.result_bonus
	if AppConfig.advertising_enabled() and not bonus.is_empty():
		var text := t("Podwojono nagrodę ✓","Reward doubled ✓") if bonus.claimed else t("Reklama: +%d monet (nagroda ×2)","Watch ad: +%d coins (reward ×2)") % int(bonus.amount)
		button(ui,text,Rect2(60,1082,600,76),double_reward,false,bonus.claimed or not Ads.reward_available())

func revive_with_ad() -> void:
	Ads.reward(func():
		if model.revive():
			Store.data.stats.games = maxi(0,int(Store.data.stats.games)-1)
			checkpoint()
			game_screen())

func daily_screen() -> void:
	change("daily")
	header(t("Wyzwanie dnia","Daily challenge"),Store.today())
	var daily := Board.new()
	daily.begin("daily",Store.today())
	panel(ui,Rect2(44,216,632,220))
	label(ui,t("DZISIEJSZY CEL","TODAY'S GOAL"),16,Vector2(70,240),Vector2(580,40),CYAN,true)
	label(ui,str(daily.target)+t(" punktów"," points"),40,Vector2(70,293),Vector2(580,62),WHITE,true)
	label(ui,t("Nagroda: 80 Neon Coins • raz dziennie","Reward: 80 Neon Coins • once per day"),18,Vector2(70,365),Vector2(580,44),MUTED)
	button(ui,t("Ukończono ✓ — zagraj ponownie","Completed ✓ — play again") if Store.data.daily.get(Store.today(),false) else t("Podejmij wyzwanie","Accept challenge"),Rect2(44,470,632,80),func(): request_start("daily"),true)
	var date := Time.get_date_dict_from_system()
	label(ui,"%04d / %02d" % [date.year,date.month],26,Vector2(44,608),Vector2(632,50),WHITE,true)
	var first := Time.get_datetime_dict_from_datetime_string("%04d-%02d-01T00:00:00" % [date.year,date.month],true)
	var offset := (int(first.weekday)+6)%7
	var days := 31
	if int(date.month) in [4,6,9,11]: days = 30
	elif int(date.month)==2: days = 29 if int(date.year)%4==0 and (int(date.year)%100!=0 or int(date.year)%400==0) else 28
	var weekdays := ["P","W","Ś","C","P","S","N"] if Store.data.settings.language=="pl" else ["M","T","W","T","F","S","S"]
	for i in 7: label(ui,weekdays[i],16,Vector2(50+i*89,675),Vector2(82,38),MUTED)
	for d in range(1,days+1):
		var index := offset+d-1
		var x := 50+(index%7)*89
		var y := 722+(index/7)*65
		var completed: bool = Store.data.daily.get("%04d-%02d-%02d" % [date.year,date.month,d],false)
		var p := panel(ui,Rect2(x,y,80,55))
		if completed: p.add_theme_stylebox_override("panel",style(Color("16413c"),CYAN,12))
		label(ui,str(d)+( " ✓" if completed else ""),18,Vector2(x,y),Vector2(80,55),CYAN if d==int(date.day) or completed else WHITE)
	label(ui,t("Zadanie zależy od lokalnej daty urządzenia.","The challenge uses your device's local date."),16,Vector2(44,1140),Vector2(632,40),MUTED)

func stats() -> void:
	change("stats")
	header(t("Twoje rekordy","Your personal bests"),t("Liczy się każdy kolejny ruch.","Every next move counts."))
	for i in 3:
		var mode: String = ["classic","time","daily"][i]
		var y := 230+i*160
		panel(ui,Rect2(44,y,632,130))
		label(ui,mode.to_upper(),18,Vector2(70,y+16),Vector2(400,38),MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		label(ui,str(int(Store.data.best[mode])),36,Vector2(70,y+57),Vector2(580,55),CYAN,true,HORIZONTAL_ALIGNMENT_LEFT)
	var s: Dictionary = Store.data.stats
	var values := [t("Ukończone gry","Completed games")+": "+str(int(s.games)),t("Ułożone figury","Blocks placed")+": "+str(int(s.moves)),t("Usunięte linie","Lines cleared")+": "+str(int(s.lines)),t("Łączne punkty","Lifetime points")+": "+str(int(s.points))]
	for i in values.size(): label(ui,values[i],22,Vector2(70,780+i*76),Vector2(580,52),WHITE,false,HORIZONTAL_ALIGNMENT_LEFT)

func shop() -> void:
	change("shop")
	header(t("Twój neonowy styl","Make it yours"))
	shop_tabs("themes")
	var items := [["neon","NEON ORIGINAL",0,false,CYAN],["aurora","AURORA",120,false,Color("9df6c4")],["sunset","SUNSET",180,false,Color("ffb280")],["spark",t("Efekt: Iskry","Effect: Sparks"),0,true,PURPLE],["orbit",t("Efekt: Orbity","Effect: Orbits"),90,true,PURPLE]]
	for i in items.size():
		var item: Array = items[i]
		var y := 210+i*155
		panel(ui,Rect2(44,y,632,133))
		label(ui,"◆  "+item[1],22,Vector2(70,y+16),Vector2(550,43),item[4],true,HORIZONTAL_ALIGNMENT_LEFT)
		var owned: bool = item[0] in Store.data["effects" if item[3] else "themes"]
		var selected: bool = Store.data["effect" if item[3] else "theme"] == item[0]
		var text := t("Aktywny ✓","Active ✓") if selected else (t("Wybierz","Select") if owned else str(item[2])+" ◈")
		button(ui,text,Rect2(410,y+68,240,50),func():
			if not Store.purchase(item[0],item[2],item[3]): toast(t("Za mało monet lub błąd zapisu","Not enough coins or save error"))
			shop(),false,selected)
	label(ui,"◈ "+str(int(Store.data.coins))+" NEON COINS",16,Vector2(44,974),Vector2(632,30),MUTED)
	button(ui,t("NEON PLUS  /  Galaxy + Nova","NEON PLUS  /  Galaxy + Nova"),Rect2(44,1010,632,76),premium_shop,true)
	button(ui,t("PLASMA  /  dodatkowy motyw","PLASMA  /  extra theme"),Rect2(44,1110,632,64),lab)

func shop_tabs(selected: String) -> void:
	var tabs := [["themes",t("Motywy","Themes"),shop],["boosters",t("Pomocnicy","Boosters"),func(): boosters(false)],["premium","Premium",premium_shop]]
	for i in tabs.size():
		button(ui,tabs[i][1],Rect2(44+i*216,145,200,48),tabs[i][2],selected==tabs[i][0]).add_theme_font_size_override("font_size",18)

func premium_shop() -> void:
	change("premium")
	notice.position = Vector2(44,1210)
	notice.size = Vector2(632,55)
	header(t("Sklep • Premium","Shop • Premium"))
	shop_tabs("premium")
	panel(ui,Rect2(44,218,632,510))
	label(ui,"NEON PLUS",32,Vector2(70,235),Vector2(580,50),CYAN,true,HORIZONTAL_ALIGNMENT_LEFT)
	label(ui,t("Jednorazowy zakup • na stałe","One-time purchase • permanent"),18,Vector2(70,289),Vector2(580,36),MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	var preview = preload("res://scripts/cosmetic_preview.gd").new()
	preview.position = Vector2(70,337)
	preview.size = Vector2(580,88)
	ui.add_child(preview)
	label(ui,"CYBER GALAXY  +  NOVA ✦",21,Vector2(70,440),Vector2(580,40),PURPLE,true)
	label(ui,t("Wyłącza reklamy automatyczne. Odblokowuje motyw Galaxy i efekt Nova. Reklamy z nagrodą pozostają dobrowolne.","Removes automatic ads. Unlocks the Galaxy theme and Nova effect. Rewarded ads remain optional."),20,Vector2(70,492),Vector2(580,104),WHITE,false,HORIZONTAL_ALIGNMENT_LEFT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var plus_text := t("Wybierz Galaxy + Nova ✓","Select Galaxy + Nova ✓") if Store.data.neon_plus else purchase_caption(Billing.PLUS)
	button(ui,plus_text,Rect2(64,625,592,76),func():
		if Store.data.neon_plus:
			if Store.purchase("cyber_galaxy",-1) and Store.purchase("nova",-1,true):
				toast(t("Galaxy i Nova aktywne.","Galaxy and Nova selected."))
		else: parent_purchase(Billing.PLUS),true,not Store.data.neon_plus and not Billing.available(Billing.PLUS)).add_theme_font_size_override("font_size",21)
	panel(ui,Rect2(44,750,632,225))
	label(ui,t("DUŻY PAKIET RATUNKOWY","LARGE RESCUE PACK"),23,Vector2(64,768),Vector2(592,44),WHITE,true)
	label(ui,t("10 Młotków + 20 Zmian","10 Hammers + 20 Shuffles"),24,Vector2(64,818),Vector2(592,44),CYAN,true)
	button(ui,purchase_caption(Billing.PACK),Rect2(64,883,592,66),func(): parent_purchase(Billing.PACK),true,not Billing.available(Billing.PACK)).add_theme_font_size_override("font_size",21)
	premium_status = label(ui,billing_status(),16,Vector2(44,990),Vector2(632,58),MUTED)
	premium_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(ui,t("Przywróć zakup Neon Plus","Restore Neon Plus purchase"),Rect2(44,1060,632,60),func(): Billing.restore()).add_theme_font_size_override("font_size",19)
	label(ui,t("Zakupy przez Google Play • dostęp dla rodzica\nZużytych pomocników nie można przywrócić po usunięciu danych gry.","Google Play purchases • parent access\nConsumed boosters cannot be restored after deleting game data."),16,Vector2(44,1140),Vector2(632,65),MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func purchase_caption(product: String) -> String:
	if Billing.busy: return t("Trwa obsługa zakupu…","Processing purchase…")
	var price: String = Billing.price(product)
	if price.is_empty(): return t("Zakup obecnie niedostępny","Purchase currently unavailable")
	return t("Kup za ","Buy for ")+price

func billing_status() -> String:
	if Billing.pending: return t("Płatność oczekuje na potwierdzenie Google Play.","Payment is pending Google Play confirmation.")
	if OS.get_name()!="Android": return t("Zakupy są dostępne w wersji Android z Google Play.","Purchases are available in the Android version from Google Play.")
	if Billing.state=="configuration_required": return t("Zakupy nie zostały jeszcze uruchomione.","Purchases have not been activated yet.")
	if Billing.products.is_empty(): return t("Nie udało się pobrać ofert. Sprawdź internet i spróbuj ponownie.","Offers could not load. Check your connection and try again.")
	return t("Ceny i płatność obsługuje Google Play.","Prices and payment are handled by Google Play.")

func parent_purchase(product: String) -> void:
	if not Billing.available(product): return
	change("parent_gate")
	header(t("Dostęp dla rodzica","Parent access"))
	label(ui,t("Ten ekran jest dla rodzica lub opiekuna.","This screen is for a parent or guardian."),24,Vector2(60,248),Vector2(600,90),WHITE,true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(ui,t("Po potwierdzeniu otworzy się płatność Google Play. Możesz ją anulować.","After confirmation, Google Play payment will open. You can cancel it."),21,Vector2(60,365),Vector2(600,100),MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var gate = preload("res://scripts/parent_gate.gd").new()
	label(ui,"%d × %d = ?" % [gate.left,gate.right],40,Vector2(60,500),Vector2(600,80),CYAN,true)
	var answer := LineEdit.new()
	answer.position = Vector2(180,615)
	answer.size = Vector2(360,78)
	answer.max_length = 5
	answer.placeholder_text = t("Wpisz wynik","Enter the answer")
	answer.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	answer.add_theme_font_size_override("font_size",25)
	ui.add_child(answer)
	var confirm := func():
		if Billing.purchase(product,gate,answer.text):
			premium_shop()
		else:
			premium_shop()
			toast(t("Nie potwierdzono dostępu. Spróbuj ponownie.","Access not confirmed. Please try again."))
	button(ui,t("Przejdź do płatności — ","Continue to payment — ")+Billing.price(product),Rect2(44,775,632,80),confirm,true).add_theme_font_size_override("font_size",20)
	answer.text_submitted.connect(func(_text): confirm.call())
	button(ui,t("Anuluj i wróć do sklepu","Cancel and return to shop"),Rect2(44,885,632,76),premium_shop)

func _billing_changed() -> void:
	if screen=="premium": premium_shop()

func _billing_message(code: String) -> void:
	var texts := {
		"delivered":["Zakup zapisany. Dziękujemy!","Purchase saved. Thank you!"],
		"restored":["Sprawdzono zakupy konta Google Play.","Google Play account purchases checked."],
		"pending":["Płatność oczekuje. Nagroda pojawi się po potwierdzeniu.","Payment pending. Items arrive after confirmation."],
		"cancelled":["Zakup anulowany.","Purchase cancelled."],
		"save_failed":["Nie zapisano zakupu. Nie usuwaj danych gry; spróbuj przywrócić zakup.","Purchase could not be saved. Keep game data and try restoring."],
		"verification_failed":["Nie udało się potwierdzić zakupu.","Purchase verification failed."],
		"settlement_pending":["Zakup zapisany. Potwierdzenie Google Play zostanie ponowione.","Purchase saved. Google Play confirmation will retry."]}
	if screen=="premium": premium_shop()
	var text: Array = texts.get(code,["Zakup niedostępny. Spróbuj ponownie w Google Play.","Purchase unavailable. Please try again in Google Play."])
	call_deferred("toast",t(text[0],text[1]))

func settings() -> void:
	change("settings")
	header(t("Ustawienia","Settings"))
	var keys := ["sound","music","vibration"]
	var names := [t("Efekty dźwiękowe","Sound effects"),t("Muzyka","Music"),t("Wibracje","Vibration")]
	for i in 3:
		var key: String = keys[i]
		button(ui,names[i]+": "+(t("WŁ.","ON") if Store.data.settings[key] else t("WYŁ.","OFF")),Rect2(44,230+i*123,632,92),func():
			Store.data.settings[key] = not Store.data.settings[key]
			Store.save()
			Sound.apply()
			settings())
	button(ui,"Język / Language: "+Store.data.settings.language.to_upper(),Rect2(44,638,632,92),func():
		Store.data.settings.language = "en" if Store.data.settings.language=="pl" else "pl"
		Store.save()
		settings())
	button(ui,t("Prywatność i dane","Privacy & data"),Rect2(44,788,632,85),func():
		info())
	button(ui,t("Informacje i prywatność","About & privacy"),Rect2(44,900,632,85),info)
	if not AppConfig.production(): button(ui,t("Reklamy testowe — status","Test ads — status"),Rect2(44,1010,632,60),ad_status)
	label(ui,"NEON BLOCK MASTER  /  2.0.0",16,Vector2(44,1090),Vector2(632,45),MUTED)

func info() -> void:
	change("info")
	header(t("Jak grać i informacje","How to play & about"))
	var privacy_url: String = AppConfig.data.get("privacy_url","")
	if privacy_url.begins_with("https://"):
		button(ui,t("Polityka prywatności online ↗","Privacy policy online ↗"),Rect2(44,140,632,50),func(): OS.shell_open(privacy_url))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(44,200)
	scroll.size = Vector2(632,850)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var content := Label.new()
	content.custom_minimum_size.x = 604
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_override("font",regular)
	content.add_theme_font_size_override("font_size",21)
	content.add_theme_color_override("font_color",WHITE)
	content.text = t("JAK GRAĆ\n\nPrzeciągnij jedną z trzech figur na planszę 8 × 8. Figura unosi się nad palcem, aby podgląd był widoczny. Zielony podgląd oznacza poprawne miejsce, czerwony — kolizję. Nie można obracać figur.\n\nWypełnij cały rząd lub kolumnę, aby zwolnić miejsce. Pełne linie znikają jednocześnie. Nowe trzy figury otrzymasz po wykorzystaniu całej ręki. Gra kończy się, gdy żadna figura nie pasuje.\n\nPUNKTY I COMBO\n\n10 punktów za kwadrat, 100 za linię, 75 za każdą dodatkową linię w ruchu. Kolejne ruchy z kasowaniem linii dodają combo: +50 za każdy poziom powyżej pierwszego. Ruch bez linii zeruje combo.\n\nTIME ATTACK\n\n180 sekund aktywnej gry. Co najmniej dwie linie w jednym ruchu dodają po 3 sekundy za linię, maksymalnie 15. Pauza i tło zatrzymują zegar.\n\nNEON COINS\n\n15 monet za pierwszy start dnia, 10 za nowy rekord po grze, 80 za pierwsze ukończenie wyzwania dnia oraz pakiet pomocników za dobrowolną reklamę z nagrodą. Monety nie mają wartości pieniężnej.\n\nPRYWATNOŚĆ\n\nPostęp i ustawienia zapisują się wyłącznie lokalnie. Nie wymagamy konta, lokalizacji, kontaktów ani serwera. Usunięcie danych aplikacji usuwa zapis. Reklamy, jeśli SDK jest dostępne, obsługuje Google AdMob; zgody obsługuje Google UMP. Preferencje zgód zmienisz w Ustawieniach. Brak internetu nie blokuje gry.\n\nZakupy opcjonalne obsługuje Google Play. Neon Plus wyłącza reklamy automatyczne i odblokowuje Galaxy + Nova. Płatny pakiet daje 10 Młotków i 20 Zmian. Polityka HTML, licencje i instrukcje publikacji znajdują się w źródłach projektu.\n\n© 2026 Neon Block Master\nOryginalne grafiki i syntezowane audio.\nGodot Engine — MIT. DejaVu Fonts — licencja Bitstream Vera / Arev. Integracja AdMob — Poing Studios (MIT).",
	"HOW TO PLAY\n\nDrag one of three blocks onto the 8 × 8 board. The block floats above your finger so you can see its preview. Green means a valid placement; red means a collision. Blocks cannot be rotated.\n\nFill an entire row or column to free space. All full lines clear simultaneously. Use all three blocks to get a fresh hand. The game ends when no remaining block fits.\n\nSCORE & COMBO\n\n10 points per square, 100 per line, and 75 per additional line in the same move. Consecutive line-clearing moves build a combo: +50 per level above the first. A move without a clear resets the combo.\n\nTIME ATTACK\n\n180 seconds of active play. Clear at least two lines in one move to gain 3 seconds per line, capped at 15. Pausing or backgrounding stops the clock.\n\nNEON COINS\n\n15 coins for the first launch each day, 10 for a new personal best at game end, 80 for the first daily completion with an optional rewarded-ad rescue pack. Coins have no cash value.\n\nPRIVACY\n\nProgress and settings stay on your device. No accounts, location, contacts or game servers are required. Clearing app data removes progress. Where the ad SDK is available, Google AdMob handles ads and Google UMP handles consent. Manage consent in Settings. Offline play always works.\n\nOptional purchases use Google Play. Neon Plus removes automatic ads and unlocks Galaxy + Nova. A paid pack grants 10 Hammers and 20 Shuffles. The HTML policy, licenses and publishing instructions are included in the project source.\n\n© 2026 Neon Block Master\nOriginal art and synthesized audio.\nGodot Engine — MIT. DejaVu Fonts — Bitstream Vera / Arev license. AdMob integration — Poing Studios (MIT).")
	content.text += t("\n\nNEON LAB\nMotyw PLASMA: 240 monet lub trzy dobrowolne reklamy z nagrodą. Postęp nie wygasa. Po rozgrywce możesz obejrzeć reklamę, aby raz podwoić zdobyte w niej monety. Nowe POMOCNIKI: Młotek usuwa obszar 3×3, a Zmiana wymienia zestaw klocków. Jedna dobrowolna reklama daje 1 Młotek i 2 Zmiany; ten sam pakiet kupisz za 90 monet. Pakiet startowy jest gratis. Pomocniki są wyłączone w Daily.","\n\nNEON LAB\nPLASMA theme: 240 coins or three optional rewarded ads. Progress never expires. After a run, you can watch an ad to double the coins earned in that run once. BOOSTERS: Hammer clears a 3×3 area, Shuffle replaces your hand. One optional rewarded ad gives 1 Hammer and 2 Shuffles; the same pack costs 90 coins. A starter pack is free. Boosters are disabled in Daily.")
	if AppConfig.production():
		content.text = content.text.replace("Ta wersja używa identyfikatorów reklam testowych.","Ta wersja korzysta z Google AdMob.").replace("This build uses test ad IDs","This build uses Google AdMob")
	if not AppConfig.advertising_enabled():
		content.text = content.text.split("NEON COINS")[0]+t("NEON COINS\n\nMonety zdobędziesz za codzienne uruchomienie, rekordy i wyzwania. Motywy są kosmetyczne i nie zmieniają zasad.\n\nPRYWATNOŚĆ\n\nTa wersja działa bez reklam i bez modułu reklamowego Google. Nie ma własnych kont ani serwera gry. Opcjonalne płatności obsługuje Google Play. Nie pytamy o wiek. Wyniki, monety, motywy i ustawienia są zapisywane wyłącznie na urządzeniu. Czyszczenie danych aplikacji usuwa zapis. Nie mamy dostępu do kontaktów, zdjęć ani lokalizacji GPS.\n\nDLA DZIECI I DOROSŁYCH\n\nGra jest przeznaczona dla różnych grup wiekowych. Ocena treści w sklepie zostanie ustalona na podstawie ankiety IARC.\n\nWYDAWCA\n","NEON COINS\n\nEarn coins through daily visits, records and challenges. Themes are cosmetic and do not change the rules.\n\nPRIVACY\n\nThis version has no ads or Google advertising module. There are no game accounts or servers. Optional payments are handled by Google Play. We do not ask your age. Scores, coins, themes and settings stay on your device. Clearing app data removes your save. We do not access contacts, photos or GPS location.\n\nCHILDREN AND ADULTS\n\nThe game is intended for different age groups. The store content rating will be determined through the IARC questionnaire.\n\nPUBLISHER\n")+AppConfig.data.get("publisher_name","")+"\n"+AppConfig.data.get("contact_email","")
	if AppConfig.advertising_enabled():
		content.text = content.text.split("PRYWATNOŚĆ")[0] if Store.data.settings.language=="pl" else content.text.split("PRIVACY")[0]
		content.text += t("\nPRYWATNOŚĆ\n\nReklamy Google AdMob używają ograniczonego profilu dla dzieci dla wszystkich graczy: child-directed, under-age, limit treści G i żądania niepersonalizowane. Nie pytamy o datę urodzenia ani nie przyznajemy korzyści za deklarację starszego wieku. SDK może przetwarzać dane techniczne, np. IP i diagnostykę; nie obiecujemy braku danych po stronie dostawcy. Wyniki i monety pozostają lokalnie.\n\n","\nPRIVACY\n\nGoogle AdMob ads use the restricted child-directed, under-age, G-rated, non-personalised request profile for all players. We do not ask your birth date or reward an older age declaration. The provider may process technical information such as IP and diagnostics; this is not a zero-data claim. Scores and coins remain local.\n\n")
		content.text += t("Tryb: reklamy produkcyjne.\n","Mode: production ads.\n") if AppConfig.production() else t("Tryb: oficjalne reklamy testowe Google, bez przychodu.\n","Mode: official Google test ads, no revenue.\n")
		content.text += AppConfig.data.get("publisher_name","")+"\n"+AppConfig.data.get("contact_email","")
	scroll.add_child(content)
	button(ui,t("Zagrajmy","Let's play"),Rect2(44,1080,306,80),modes,true)
	button(ui,t("Licencje","Licenses"),Rect2(370,1080,306,80),licenses)

func toast(text: String) -> void:
	if screen=="game" and is_instance_valid(game_instruction): game_instruction.hide()
	notice.text = text
	toast_time = 3.2

func _ads_changed() -> void:
	if screen == "shop": shop()
	elif screen == "result": result_screen()
	elif screen == "lab": lab()
	elif screen == "boosters": boosters(boost_return_game)

func back() -> void:
	if hammer_aim:
		select_hammer()
		return
	if screen=="rescue":
		finish()
		return
	if not overlay.get_children().is_empty() and screen != "pause": clear_nodes(overlay)
	elif screen == "game": pause_game()
	elif screen == "pause": game_screen()
	elif screen == "menu":
		modal(t("Zakończyć grę?","Exit game?"),t("Postęp jest zapisany.","Your progress is saved."),[[t("Zakończ","Exit"),func(): get_tree().quit()],[t("Zostań","Stay"),func(): clear_nodes(overlay)]])
	elif screen == "lab": shop()
	elif screen in ["premium","parent_gate"]: shop()
	elif screen == "boosters" and boost_return_game: game_screen()
	else: menu()

func _notification(what: int) -> void:
	if not is_instance_valid(stage): return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if screen == "game": pause_game()
		else: Store.save()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST: back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if model != null: checkpoint()
		get_tree().quit()

func licenses() -> void:
	change("licenses")
	header(t("Licencje","Licenses"))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(44,190)
	scroll.size = Vector2(632,960)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var text := Label.new()
	text.custom_minimum_size.x = 600
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font",regular)
	text.add_theme_font_size_override("font_size",17)
	text.text = "Neon Block Master — MIT\nCopyright (c) 2026 Neon Block Master contributors\n\nPoing Studios AdMob — MIT\nCopyright (c) 2023–2026 Poing Studios\n\n"
	for path in ["res://assets/GODOT-LICENSE.txt","res://assets/FONT-LICENSE.txt","res://assets/GODOT-COPYRIGHT.txt"]:
		text.text += FileAccess.get_file_as_string(path)+"\n\n"
	scroll.add_child(text)

func double_reward() -> void:
	var bonus: Dictionary = Store.data.result_bonus
	if bonus.is_empty() or bonus.claimed: return
	var id: String = bonus.id
	Ads.reward(func():
		if Store.claim_result_bonus(id):
			if screen == "result": result_screen()
			toast(t("Nagroda podwojona!","Reward doubled!")))

func lab() -> void:
	change("lab")
	header("NEON LAB",t("Twój nowy motyw. Twój wybór.","Your next theme. Your choice."))
	panel(ui,Rect2(44,220,632,340))
	label(ui,"P L A S M A",38,Vector2(70,245),Vector2(580,70),Color("ffe176"),true)
	var colors: Array = View.PALETTES.plasma
	for i in 5:
		var p := panel(ui,Rect2(98+i*108,355,92,92))
		p.add_theme_stylebox_override("panel",style(colors[i].darkened(.65),colors[i],18))
	label(ui,t("Kosmetyczny motyw • te same zasady gry","Cosmetic theme • same rules of play"),17,Vector2(60,480),Vector2(600,50),MUTED)
	var owned: bool = "plasma" in Store.data.themes
	if not AppConfig.advertising_enabled():
		label(ui,t("PLASMA ODBLOKOWANA ✓","PLASMA UNLOCKED ✓") if owned else "240 NEON COINS",28,Vector2(44,620),Vector2(632,60),CYAN,true)
		label(ui,t("Monety zdobywasz grając: za wyzwania i rekordy.","Earn coins by playing challenges and setting records."),18,Vector2(44,720),Vector2(632,50),WHITE)
		button(ui,t("Wybierz motyw","Select theme") if owned else t("Odblokuj za 240 monet","Unlock for 240 coins"),Rect2(44,850,632,85),func():
			if Store.purchase("plasma",240): lab()
			else: toast(t("Za mało monet lub błąd zapisu","Not enough coins or a save error")),true,not owned and Store.data.coins<240)
		label(ui,t("Bez reklam. Bez losowych nagród.","No ads. No random rewards."),18,Vector2(44,990),Vector2(632,50),MUTED)
		return
	var charges := int(Store.data.lab_charges)
	label(ui,t("PLASMA ODBLOKOWANA ✓","PLASMA UNLOCKED ✓") if owned else t("ŁADUNKI NEONU  %d / 3","NEON CHARGES  %d / 3") % charges,25,Vector2(44,600),Vector2(632,50),CYAN,true)
	for i in 3:
		var p := panel(ui,Rect2(78+i*194,674,176,22))
		p.add_theme_stylebox_override("panel",style(CYAN if i<charges or owned else Color("17243d"),CYAN if i<charges or owned else Color("30415c"),11))
	label(ui,t("1 obejrzana reklama = 1 ładunek. Bez losowania.","1 rewarded ad = 1 charge. No random rewards."),18,Vector2(44,720),Vector2(632,48),WHITE)
	label(ui,t("Postęp nie wygasa. Możesz wrócić w dowolnej chwili.","Progress never expires. Come back whenever you like."),16,Vector2(44,768),Vector2(632,42),MUTED)
	button(ui,t("Reklama: +1 ładunek do PLASMA","Watch ad: +1 PLASMA charge"),Rect2(44,852,632,82),lab_reward,true,owned or not Ads.reward_available())
	button(ui,t("Wybierz odblokowany motyw","Select unlocked theme") if owned else t("Albo odblokuj za 240 Neon Coins","Or unlock for 240 Neon Coins"),Rect2(44,956,632,82),func():
		if Store.purchase("plasma",240): lab()
		else: toast(t("Za mało monet lub błąd zapisu","Not enough coins or a save error")),false,not owned and Store.data.coins<240)
	label(ui,t("Monety zdobędziesz też grając, bez reklam.","You can also earn coins by playing without ads."),18,Vector2(44,1064),Vector2(632,44),MUTED)
	if not owned and not Ads.reward_available():
		label(ui,t("Brak reklamy lub trwa przerwa między reklamami.","No ad available, or ad cooldown in progress."),16,Vector2(44,1120),Vector2(632,44),MUTED)

func lab_reward() -> void:
	if "plasma" in Store.data.themes: return
	Ads.reward(func():
		if Store.add_plasma_charge():
			if screen == "lab": lab()
			toast(t("PLASMA odblokowana!","PLASMA unlocked!") if "plasma" in Store.data.themes else t("+1 ładunek neonu","+1 neon charge")))

func launch_menu() -> void:
	if AppConfig.age_choice_required():
		age_screen()
		return
	menu()
	var reward := Store.login_reward()
	if reward > 0: toast(t("Codzienny bonus: +15 Neon Coins","Daily bonus: +15 Neon Coins"))

func age_screen() -> void:
	# Only used by a future advertising-enabled package. The ad-free family
	# package skips this screen and does not collect unnecessary age information.
	change("age")
	label(ui,t("Twoja grupa wiekowa","Your age group"),32,Vector2(44,170),Vector2(632,60),WHITE,true)
	label(ui,t("Wybierz swój przedział wiekowy.","Choose your age group."),20,Vector2(44,270),Vector2(632,55),MUTED)
	var bands := ["under_13","13_15","16_17","18_plus","unknown"]
	var labels := [t("Poniżej 13 lat","Under 13"),"13–15","16–17",t("18 lat lub więcej","18 or older"),t("Nie chcę podawać","Prefer not to say")]
	for i in bands.size():
		var band: String = bands[i]
		button(ui,labels[i],Rect2(70,390+i*125,580,85),func():
			Store.set_age_band(band)
			Ads.start_if_allowed()
			launch_menu())

func ad_status() -> void:
	change("ad_status")
	header(t("Reklamy — status","Ads — status"))
	notice.position = Vector2(44,145)
	notice.size = Vector2(632,60)
	ad_state_label = label(ui,Ads.status_text(),21,Vector2(44,220),Vector2(632,180),CYAN)
	ad_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(44,430)
	scroll.size = Vector2(632,520)
	ui.add_child(scroll)
	var details := Label.new()
	details.custom_minimum_size = Vector2(600,0)
	details.add_theme_font_override("font",regular)
	details.add_theme_font_size_override("font_size",17)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = Ads.details_text()
	ad_detail_label = details
	scroll.add_child(details)
	button(ui,t("Ponów pobieranie","Retry loading"),Rect2(44,990,632,76),func(): Ads.retry(); ad_status())
	button(ui,t("Pakiet ratunkowy →","Rescue pack →"),Rect2(44,1090,632,76),func(): boosters(false),true)
	button(ui,t("Kopiuj szczegóły","Copy details"),Rect2(44,1185,632,54),func():
		DisplayServer.clipboard_set(Ads.details_text())
		toast(t("Skopiowano szczegóły reklamy.","Ad details copied."))).add_theme_font_size_override("font_size",17)

func select_hammer() -> void:
	if screen!="game" or model.mode=="daily" or Store.data.boosts.hammer<1: return
	cancel_drag()
	hammer_aim = not hammer_aim
	if is_instance_valid(hammer_button):
		hammer_button.text = "×" if hammer_aim else "×"+str(int(Store.data.boosts.hammer))
	if is_instance_valid(game_instruction):
		game_instruction.text = t("MŁOTEK: WSKAŻ OBSZAR 3×3 NA PLANSZY","HAMMER: CHOOSE A 3×3 AREA ON THE BOARD") if hammer_aim else t("PRZECIĄGNIJ FIGURĘ NA PLANSZĘ","DRAG A BLOCK ONTO THE BOARD")
		game_instruction.visible = hammer_aim or not Store.data.tutorial_done
	view.hammer_preview = Vector2i(-1,-1)
	view.queue_redraw()
	notice.text = ""
	toast_time = 0

func use_hammer(cell: Vector2i) -> void:
	if screen!="game" or model.mode=="daily" or Store.data.boosts.hammer<1: return
	var before := model.snapshot()
	var cleared := model.hammer(cell)
	if cleared.is_empty():
		toast(t("Wybierz obszar z klockami — nie zużyto Młotka.","Pick an occupied area — no Hammer spent."))
		return
	if not Store.spend_boost("hammer",model.snapshot()):
		model = Board.restore(before)
		view.model = model
		toast(t("Nie udało się zapisać. Młotek nie został zużyty.","Save failed. Hammer was not spent."))
		return
	game_screen()
	view.burst(cleared)
	Sound.play("clear")
	toast(t("Młotek: usunięto %d pól!","Hammer: cleared %d cells!") % cleared.size())

func use_shuffle() -> void:
	if screen!="game" or model.mode=="daily" or Store.data.boosts.shuffle<1: return
	var before := model.snapshot()
	if not model.shuffle_hand(): return
	if not Store.spend_boost("shuffle",model.snapshot()):
		model = Board.restore(before)
		view.model = model
		toast(t("Błąd zapisu — Zmiana nie została zużyta.","Save failed — Shuffle was not spent."))
		return
	game_screen()
	Sound.play("place")
	toast(t("Nowy zestaw klocków. Plansza zostaje!","Fresh blocks. Your board stays!"))

func boosters(in_game := false) -> void:
	if in_game and model!=null: checkpoint()
	boost_return_game = in_game
	change("boosters")
	notice.position = Vector2(36,196)
	notice.size = Vector2(648,28)
	button(ui,"‹",Rect2(36,38,64,64),func():
		if boost_return_game: game_screen()
		else: menu())
	label(ui,t("Pomocnicy","Boosters"),31,Vector2(120,38),Vector2(480,64),WHITE,true)
	if in_game: label(ui,"◈ "+str(int(Store.data.coins))+" NEON COINS",17,Vector2(36,136),Vector2(648,38),CYAN)
	else: shop_tabs("boosters")
	var names := [t("Młotek 3×3","3×3 Hammer"),t("Zmiana figur","Shuffle pieces")]
	var descriptions := [t("Usuń do 9 pól. Wybierz miejsce na planszy.","Clear up to 9 cells. Choose the area."),t("Nowe 3 figury. Plansza i wynik zostają.","3 new pieces. Keep your board and score.")]
	var textures := [preload("res://assets/ui/hammer.svg"),preload("res://assets/ui/shuffle.svg")]
	for i in 2:
		var x := 36+i*336
		panel(ui,Rect2(x,238,312,234))
		var icon := TextureRect.new()
		icon.texture = textures[i]
		icon.position = Vector2(x+24,258)
		icon.size = Vector2(58,58)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(58,58)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(icon)
		label(ui,"×"+str(int(Store.data.boosts["hammer" if i==0 else "shuffle"])),38,Vector2(x+116,258),Vector2(170,58),WHITE,true,HORIZONTAL_ALIGNMENT_RIGHT)
		label(ui,names[i],23,Vector2(x+22,334),Vector2(270,38),CYAN if i==0 else PURPLE,true,HORIZONTAL_ALIGNMENT_LEFT)
		var description := label(ui,descriptions[i],17,Vector2(x+22,382),Vector2(270,70),MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel(ui,Rect2(36,506,648,282))
	label(ui,t("Pakiet ratunkowy","Rescue pack"),26,Vector2(56,526),Vector2(608,46),WHITE,true)
	label(ui,t("1 Młotek + 2 Zmiany","1 Hammer + 2 Shuffles"),26,Vector2(56,584),Vector2(608,48),CYAN,true)
	label(ui,t("Jedna ukończona reklama • nagroda do plecaka","One completed ad • reward added to inventory"),16,Vector2(56,644),Vector2(608,32),MUTED)
	rescue_ad_button = button(ui,"",Rect2(56,696,608,68),reward_rescue_pack,true)
	rescue_ad_button.add_theme_font_size_override("font_size",20)
	update_rescue_ad_button()
	ad_state_label = label(ui,Ads.status_text(),17,Vector2(36,806),Vector2(648,82),MUTED)
	ad_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(ui,t("Ten sam pakiet • 90 monet","The same pack • 90 coins"),Rect2(36,914,648,70),func():
		if Store.buy_rescue_pack():
			boosters(boost_return_game)
			toast(t("+1 Młotek i +2 Zmiany","+1 Hammer and +2 Shuffles"))
		else: toast(t("Potrzebujesz 90 monet lub miejsca w plecaku.","You need 90 coins and inventory space.")),false,Store.data.coins<90 or not Store.can_add_rescue_pack())
	label(ui,t("Classic i Time Attack • w Daily bez pomocników","Classic and Time Attack • Daily has no boosters"),16,Vector2(36,1006),Vector2(648,40),MUTED)
	button(ui,t("Wróć do gry","Back to game") if in_game else t("Zagraj","Play"),Rect2(36,1080,648,72),func():
		if boost_return_game: game_screen()
		else: modes())
	button(ui,t("Status reklam • kopiuj szczegóły","Ad status • copy details"),Rect2(36,1180,648,52),ad_status).add_theme_font_size_override("font_size",17)

func update_rescue_ad_button() -> void:
	if not Store.can_add_rescue_pack():
		rescue_ad_button.text = t("Plecak jest pełny","Inventory is full")
		rescue_ad_button.disabled = true
	elif Ads.reward_available():
		rescue_ad_button.text = t("Obejrzyj reklamę — odbierz pakiet","Watch an ad — get the pack")
		rescue_ad_button.disabled = false
	elif Ads.reward_cooldown_seconds()>0:
		rescue_ad_button.text = t("Kolejna reklama za %d s","Next ad in %d s") % Ads.reward_cooldown_seconds()
		rescue_ad_button.disabled = true
	elif Ads.reward_is_loading():
		rescue_ad_button.text = t("Ładowanie reklamy…","Loading an ad…")
		rescue_ad_button.disabled = true
	else:
		rescue_ad_button.text = t("Ponów pobieranie reklamy","Retry loading an ad")
		rescue_ad_button.disabled = false

func reward_rescue_pack() -> void:
	if not Store.can_add_rescue_pack(): return
	if not Ads.reward_available():
		Ads.retry()
		toast(t("Stan ładowania jest pod nagrodą.","Loading status is shown below the pack."))
		return
	var receipt := Crypto.new().generate_random_bytes(16).hex_encode()
	Ads.reward(func():
		if Store.grant_rescue_pack(receipt):
			if screen=="boosters": boosters(boost_return_game)
			toast(t("Nagroda: +1 Młotek i +2 Zmiany!","Reward: +1 Hammer and +2 Shuffles!"))
		else: toast(t("Nie udało się zapisać nagrody. Sprawdź miejsce w pamięci.","Could not save reward. Check available storage.")))

func no_moves() -> void:
	if model.mode=="daily" or (model.mode=="time" and model.remaining<=0):
		finish()
		return
	cancel_drag()
	checkpoint()
	screen = "rescue"
	var actions: Array = []
	if Store.data.boosts.hammer>0:
		actions.append([t("Użyj Młotka 3×3","Use a 3×3 Hammer"),func(): game_screen(); select_hammer()])
	if Store.data.boosts.shuffle>0:
		actions.append([t("Zmień zestaw klocków","Shuffle your blocks"),func(): game_screen(); use_shuffle()])
	actions.append([t("Zobacz pakiet ratunkowy","View the rescue pack"),func(): boosters(true)])
	actions.append([t("Zakończ rozgrywkę","Finish this run"),func(): finish()])
	modal(t("Brak miejsca? Możesz się uratować.","No room? You can still recover."),t("Młotek usuwa obszar 3×3. Zmiana daje nowy zestaw figur.","Hammer clears a 3×3 area. Shuffle gives you fresh blocks."),actions)
