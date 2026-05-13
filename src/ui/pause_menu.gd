## PauseMenu — Full-screen ship systems console with space-tech fonts.
extends CanvasLayer

const C_BG       := Color(0.015, 0.020, 0.038)
const C_HULL     := Color(0.050, 0.060, 0.085)
const C_SEAM     := Color(0.030, 0.035, 0.055)
const C_RIVET    := Color(0.065, 0.075, 0.100)
const C_GREEN    := Color(0.25, 1.00, 0.20)
const C_GREEN_DM := Color(0.10, 0.40, 0.08)
const C_CYAN     := Color(0.10, 0.85, 1.00)
const C_AMBER    := Color(1.00, 0.78, 0.15)
const C_DIM      := Color(0.22, 0.32, 0.45)
const C_WHITE    := Color(0.85, 0.88, 0.92)
const C_SEL      := Color(0.10, 0.85, 1.00)
const C_RED      := Color(0.70, 0.10, 0.08)

var _visible_flag: bool = false
var _selection: int = 0
var _anim: float = 0.0
var _font_title: Font = null
var _font_body: Font = null

const ITEMS := [
	{"label": "RESUME MISSION",  "desc": "Return to active flight", "kind": "action"},
	{"label": "TEXT SCALE", "desc": "Adjust HUD and menu readability", "kind": "float", "key": "text_scale", "step": 0.25, "min": 0.75, "max": 1.5},
	{"label": "COLOR FRIENDLY", "desc": "Use colorblind-safer combat and pickup colors", "kind": "bool", "key": "color_friendly"},
	{"label": "CRT OVERLAY", "desc": "Toggle CRT shader treatment", "kind": "bool", "key": "crt_enabled"},
	{"label": "FLASH INTENSITY", "desc": "Reduce screen flash strength", "kind": "float", "key": "flash_intensity", "step": 0.25, "min": 0.0, "max": 1.0},
	{"label": "BOOST MODE", "desc": "Switch between hold and toggle boost", "kind": "bool_label", "key": "hold_to_boost", "true_label": "HOLD", "false_label": "TOGGLE"},
	{"label": "RESTART SECTOR",  "desc": "Reset current sector from checkpoint", "kind": "action"},
	{"label": "ABORT TO MENU",   "desc": "Return to command center", "kind": "action"},
]

var _draw_node: Control = null

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font_title = load("res://assets/fonts/Orbitron.ttf") as Font
	_font_body = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font_title == null:
		_font_title = ThemeDB.fallback_font
	if _font_body == null:
		_font_body = ThemeDB.fallback_font
	_draw_node = Control.new()
	_draw_node.anchor_right  = 1.0
	_draw_node.anchor_bottom = 1.0
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw_node)
	_draw_node.draw.connect(_on_draw)
	hide()

func _text_scale() -> float:
	return clampf(float(SaveManager.get_setting("text_scale")), 0.75, 1.5)

func _fs(base_size: int) -> int:
	return maxi(1, int(round(float(base_size) * _text_scale())))

func _setting_value_text(item: Dictionary) -> String:
	var kind := String(item.get("kind", "action"))
	if kind == "bool" or kind == "bool_label":
		var enabled := bool(SaveManager.get_setting(String(item.get("key", ""))))
		if kind == "bool_label":
			return String(item.get("true_label", "ON")) if enabled else String(item.get("false_label", "OFF"))
		return "ON" if enabled else "OFF"
	if kind == "float":
		return "%.2f" % float(SaveManager.get_setting(String(item.get("key", ""))))
	return ""

func _on_draw() -> void:
	if not _visible_flag:
		return
	var vp := _draw_node.get_viewport_rect()
	var W  := vp.size.x
	var H  := vp.size.y
	var cx := W * 0.5
	var d  := _draw_node

	# ═══ Fully opaque ═══
	d.draw_rect(Rect2(Vector2.ZERO, vp.size), C_BG)

	# ═══ Frame ═══
	d.draw_rect(Rect2(0, 0, W, 14), C_HULL)
	d.draw_line(Vector2(0, 14), Vector2(W, 14), C_SEAM, 1.0)
	d.draw_rect(Rect2(0, H - 16, W, 16), C_HULL)
	d.draw_line(Vector2(0, H - 16), Vector2(W, H - 16), C_SEAM, 1.0)
	d.draw_rect(Rect2(0, 14, 16, H - 30), C_HULL)
	d.draw_line(Vector2(16, 14), Vector2(16, H - 16), C_SEAM, 1.0)
	d.draw_rect(Rect2(W - 16, 14, 16, H - 30), C_HULL)
	d.draw_line(Vector2(W - 16, 14), Vector2(W - 16, H - 16), C_SEAM, 1.0)
	for ri in 12:
		var rvx := 24.0 + ri * 24.0
		if rvx > W - 24: break
		d.draw_circle(Vector2(rvx, 7), 1.0, C_RIVET)
		d.draw_circle(Vector2(rvx, H - 8), 1.0, C_RIVET)

	# ═══ Header ═══
	d.draw_string(_font_title, Vector2(cx - 48, 32), "SYSTEMS PAUSE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(12), C_AMBER)
	d.draw_line(Vector2(22, 36), Vector2(W - 22, 36),
		Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.4), 1.0)

	# ═══ Left panel — Ship status ═══
	var stat_x := 24.0
	var stat_y := 46.0
	d.draw_string(_font_body, Vector2(stat_x, stat_y), "SHIP STATUS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(6), C_GREEN_DM)

	var hull_pct: float = float(GameManager.player_hull) / maxf(float(GameManager.player_max_hull), 1)
	_draw_stat_bar(d, stat_x, stat_y + 12, "HULL", hull_pct, C_GREEN if hull_pct > 0.25 else C_RED)
	var fuel_pct: float = float(GameManager.player_fuel) / maxf(float(GameManager.player_max_fuel), 1)
	_draw_stat_bar(d, stat_x, stat_y + 24, "FUEL", fuel_pct, C_AMBER if fuel_pct > 0.15 else C_RED)

	d.draw_string(_font_body, Vector2(stat_x, stat_y + 42), "SCORE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), C_GREEN_DM)
	d.draw_string(_font_body, Vector2(stat_x + 32, stat_y + 42), "%07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(6), C_CYAN)

	d.draw_string(_font_body, Vector2(stat_x, stat_y + 54), "SECTOR",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), C_GREEN_DM)
	d.draw_string(_font_body, Vector2(stat_x + 32, stat_y + 54), GameManager.get_sector_name(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), C_CYAN)

	d.draw_string(_font_body, Vector2(stat_x, stat_y + 66), "BEACONS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), C_GREEN_DM)
	d.draw_string(_font_body, Vector2(stat_x + 38, stat_y + 66), "%d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(6), C_CYAN)

	# ═══ Divider ═══
	d.draw_line(Vector2(cx + 4, 42), Vector2(cx + 4, H - 22), C_SEAM, 1.0)

	# ═══ Right panel — Menu options ═══
	var menu_x := cx + 14.0
	var menu_y := 46.0
	d.draw_string(_font_body, Vector2(menu_x, menu_y), "OPTIONS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(6), C_GREEN_DM)

	for mi in ITEMS.size():
		var item: Dictionary = ITEMS[mi]
		var iy := menu_y + 14.0 + mi * 28.0
		var is_sel := mi == _selection

		if is_sel:
			var sel_a := 0.08 + 0.04 * sin(_anim * 4.0)
			d.draw_rect(Rect2(menu_x - 4, iy - 4, W - menu_x - 16, 24),
				Color(C_SEL.r, C_SEL.g, C_SEL.b, sel_a))
			d.draw_rect(Rect2(menu_x - 4, iy - 4, W - menu_x - 16, 24),
				Color(C_SEL.r, C_SEL.g, C_SEL.b, 0.2 + 0.1 * sin(_anim * 4.0)), false, 1.0)
			# Arrow
			var arrow_a := 0.6 + 0.4 * sin(_anim * 5.0)
			d.draw_string(_font_body, Vector2(menu_x, iy + 6), ">",
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8), Color(C_SEL.r, C_SEL.g, C_SEL.b, arrow_a))

		var lbl_col := C_WHITE if is_sel else C_GREEN
		var value_text := _setting_value_text(item)
		d.draw_string(_font_body, Vector2(menu_x + 12, iy + 7), item["label"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(7), lbl_col)
		if not value_text.is_empty():
			d.draw_string(_font_body, Vector2(W - 74, iy + 7), value_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(6), C_AMBER if is_sel else C_DIM)

		if is_sel:
			d.draw_string(_font_body, Vector2(menu_x + 12, iy + 17), item["desc"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(4), C_DIM)

	# ═══ Footer ═══
	d.draw_line(Vector2(22, H - 24), Vector2(W - 22, H - 24), C_SEAM, 1.0)
	var hint_a := 0.5 + 0.3 * sin(_anim * 3.0)
	d.draw_string(_font_body, Vector2(cx - 78, H - 12),
		"W/S OR STICK SELECT    A/SPACE CONFIRM    ←/→ ADJUST",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), Color(C_DIM.r, C_DIM.g, C_DIM.b, hint_a))

	# Paused indicator
	if sin(_anim * 3.0) > 0.0:
		d.draw_circle(Vector2(W - 36, H - 9), 2.0, C_AMBER)
		d.draw_circle(Vector2(W - 36, H - 9), 3.5, Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.15))
	d.draw_string(_font_body, Vector2(W - 30, H - 6), "HOLD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(4), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.5))

func _draw_stat_bar(d: Control, x: float, y: float, label: String, pct: float, col: Color) -> void:
	d.draw_string(_font_body, Vector2(x, y + 4), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), C_GREEN_DM)
	var bx := x + 30.0
	var bw := 60.0
	var bh := 4.0
	d.draw_rect(Rect2(bx, y, bw, bh), Color(0.03, 0.05, 0.03))
	var fill := pct * bw
	if fill > 0.5:
		d.draw_rect(Rect2(bx, y, fill, bh), col)
		d.draw_rect(Rect2(bx + fill - 1, y, 1, bh),
			Color(minf(col.r * 1.5, 1), minf(col.g * 1.5, 1), minf(col.b * 1.5, 1)))
	d.draw_rect(Rect2(bx, y, bw, bh), Color(col.r, col.g, col.b, 0.2), false)
	d.draw_string(_font_body, Vector2(bx + bw + 4, y + 4), "%d%%" % int(pct * 100),
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(5), Color(col.r, col.g, col.b, 0.6))

func _process(delta: float) -> void:
	if _visible_flag:
		_anim += delta
		if _draw_node:
			_draw_node.queue_redraw()
	if Input.is_action_just_pressed("pause"):
		toggle()

func toggle() -> void:
	_visible_flag = not _visible_flag
	_anim = 0.0
	if _visible_flag:
		_selection = 0
		get_tree().paused = true
		show()
		if _draw_node:
			_draw_node.queue_redraw()
	else:
		get_tree().paused = false
		hide()

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("move_up"):
		_selection = (_selection - 1 + ITEMS.size()) % ITEMS.size()
		AudioManager.play_sfx("ui_navigate")
		if _draw_node: _draw_node.queue_redraw()
	elif event.is_action("move_down"):
		_selection = (_selection + 1) % ITEMS.size()
		AudioManager.play_sfx("ui_navigate")
		if _draw_node: _draw_node.queue_redraw()
	elif event.is_action("ui_accept"):
		_activate()
	elif event.is_action("move_left"):
		_adjust_selected_setting(-1.0)
	elif event.is_action("move_right"):
		_adjust_selected_setting(1.0)

func _adjust_selected_setting(dir: float) -> void:
	var item: Dictionary = ITEMS[_selection]
	if String(item.get("kind", "action")) == "float":
		AudioManager.play_sfx("ui_navigate")
		_adjust_float_setting(item, dir)

func _activate() -> void:
	AudioManager.play_sfx("ui_confirm")
	var item: Dictionary = ITEMS[_selection]
	var kind := String(item.get("kind", "action"))
	if kind == "bool" or kind == "bool_label":
		var key := String(item.get("key", ""))
		SaveManager.set_setting(key, not bool(SaveManager.get_setting(key)))
		if _draw_node: _draw_node.queue_redraw()
		return
	if kind == "float":
		_adjust_float_setting(item, 1.0)
		return
	match _selection:
		0: toggle()
		6:
			get_tree().paused = false
			get_tree().reload_current_scene()
		7:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _adjust_float_setting(item: Dictionary, dir: float) -> void:
	var key := String(item.get("key", ""))
	var current := float(SaveManager.get_setting(key))
	var step := float(item.get("step", 0.25)) * dir
	var min_v := float(item.get("min", 0.0))
	var max_v := float(item.get("max", 1.0))
	var next := current + step
	if next > max_v + 0.001:
		next = min_v
	elif next < min_v - 0.001:
		next = max_v
	SaveManager.set_setting(key, clampf(next, min_v, max_v))
	if _draw_node: _draw_node.queue_redraw()
