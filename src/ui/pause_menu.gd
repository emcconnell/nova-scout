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
	{"label": "RESUME MISSION",  "desc": "Return to active flight"},
	{"label": "RESTART SECTOR",  "desc": "Reset current sector from checkpoint"},
	{"label": "ABORT TO MENU",   "desc": "Return to command center"},
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
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_AMBER)
	d.draw_line(Vector2(22, 36), Vector2(W - 22, 36),
		Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.4), 1.0)

	# ═══ Left panel — Ship status ═══
	var stat_x := 24.0
	var stat_y := 46.0
	d.draw_string(_font_body, Vector2(stat_x, stat_y), "SHIP STATUS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, C_GREEN_DM)

	var hull_pct: float = float(GameManager.player_hull) / maxf(float(GameManager.player_max_hull), 1)
	_draw_stat_bar(d, stat_x, stat_y + 12, "HULL", hull_pct, C_GREEN if hull_pct > 0.25 else C_RED)
	var fuel_pct: float = float(GameManager.player_fuel) / maxf(float(GameManager.player_max_fuel), 1)
	_draw_stat_bar(d, stat_x, stat_y + 24, "FUEL", fuel_pct, C_AMBER if fuel_pct > 0.15 else C_RED)

	d.draw_string(_font_body, Vector2(stat_x, stat_y + 42), "SCORE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_GREEN_DM)
	d.draw_string(_font_body, Vector2(stat_x + 32, stat_y + 42), "%07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, C_CYAN)

	d.draw_string(_font_body, Vector2(stat_x, stat_y + 54), "SECTOR",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_GREEN_DM)
	d.draw_string(_font_body, Vector2(stat_x + 32, stat_y + 54), GameManager.get_sector_name(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_CYAN)

	d.draw_string(_font_body, Vector2(stat_x, stat_y + 66), "BEACONS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_GREEN_DM)
	d.draw_string(_font_body, Vector2(stat_x + 38, stat_y + 66), "%d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, C_CYAN)

	# ═══ Divider ═══
	d.draw_line(Vector2(cx + 4, 42), Vector2(cx + 4, H - 22), C_SEAM, 1.0)

	# ═══ Right panel — Menu options ═══
	var menu_x := cx + 14.0
	var menu_y := 46.0
	d.draw_string(_font_body, Vector2(menu_x, menu_y), "OPTIONS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, C_GREEN_DM)

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
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(C_SEL.r, C_SEL.g, C_SEL.b, arrow_a))

		var lbl_col := C_WHITE if is_sel else C_GREEN
		d.draw_string(_font_body, Vector2(menu_x + 12, iy + 7), item["label"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, lbl_col)

		if is_sel:
			d.draw_string(_font_body, Vector2(menu_x + 12, iy + 17), item["desc"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, C_DIM)

	# ═══ Footer ═══
	d.draw_line(Vector2(22, H - 24), Vector2(W - 22, H - 24), C_SEAM, 1.0)
	var hint_a := 0.5 + 0.3 * sin(_anim * 3.0)
	d.draw_string(_font_body, Vector2(cx - 56, H - 12),
		"W/S SELECT    SPACE CONFIRM",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(C_DIM.r, C_DIM.g, C_DIM.b, hint_a))

	# Paused indicator
	if sin(_anim * 3.0) > 0.0:
		d.draw_circle(Vector2(W - 36, H - 9), 2.0, C_AMBER)
		d.draw_circle(Vector2(W - 36, H - 9), 3.5, Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.15))
	d.draw_string(_font_body, Vector2(W - 30, H - 6), "HOLD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.5))

func _draw_stat_bar(d: Control, x: float, y: float, label: String, pct: float, col: Color) -> void:
	d.draw_string(_font_body, Vector2(x, y + 4), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_GREEN_DM)
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
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(col.r, col.g, col.b, 0.6))

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

func _activate() -> void:
	AudioManager.play_sfx("ui_confirm")
	match _selection:
		0: toggle()
		1:
			get_tree().paused = false
			get_tree().reload_current_scene()
		2:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
