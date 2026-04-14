## HUDDisplay — Immediate-mode HUD, CRT phosphor terminal aesthetic.
## Corner-bracket panels, bar polish, weapon icon rows, sector header.
## GDD Ref: gameplay-mechanics.md §8 — HUD
extends Control

# ─── Player reference ─────────────────────────────────────────────────────────
var _player: Player = null

# ─── Cached values ────────────────────────────────────────────────────────────
var _hull: int       = 100
var _max_hull: int   = 100
var _shield: int     = 60
var _fuel: float     = 100.0
var _max_fuel: float = 100.0
var _missiles: int   = 6
var _emp: int        = 2
var _score: int      = 0

# ─── Animation ────────────────────────────────────────────────────────────────
var _wobble: float = 0.0

# ─── Streak state (Change 7c) ─────────────────────────────────────────────────
var _streak: int = 0
var _streak_mult: int = 1
var _streak_flash: float = 0.0

# ─── Score pulse state ───────────────────────────────────────────────────────
var _score_pulse: float = 0.0

# ─── Palette ──────────────────────────────────────────────────────────────────
const COL_HULL    := Color(0.10, 0.90, 0.25)
const COL_SHIELD  := Color(0.00, 0.70, 1.00)
const COL_FUEL    := Color(1.00, 0.70, 0.00)
const COL_CRIT    := Color(1.00, 0.20, 0.10)
const COL_GREEN   := Color(0.22, 1.00, 0.08)
const COL_DIM     := Color(0.05, 0.16, 0.05)
const COL_CORNER  := Color(0.14, 0.52, 0.14, 0.90)
const COL_BG      := Color(0.00, 0.02, 0.00, 0.82)
const COL_HEADER  := Color(0.04, 0.20, 0.06, 0.80)
const COL_HDR_TXT := Color(0.18, 0.72, 0.12, 0.80)
const COL_SCORE   := Color(0.28, 1.00, 0.12)
const COL_MSL     := Color(0.82, 0.84, 0.80)
const COL_EMP     := Color(0.20, 0.60, 1.00)

const BAR_W := 52.0
const BAR_H := 3.0

var _font: Font = null

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_font = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font == null:
		_font = ThemeDB.fallback_font
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	GameManager.score_changed.connect(func(v): _score = v; _score_pulse = 0.8; queue_redraw())
	GameManager.streak_changed.connect(_on_streak_changed)

func _process(delta: float) -> void:
	_wobble += delta * 5.0
	var hull_crit: bool = float(_hull) / maxf(_max_hull, 1) < 0.25
	var fuel_crit: bool = _fuel / maxf(_max_fuel, 1) < 0.15
	if hull_crit or fuel_crit:
		queue_redraw()
	if _streak_flash > 0.0:
		_streak_flash -= delta
		queue_redraw()
	if _score_pulse > 0.0:
		_score_pulse -= delta
		queue_redraw()

func connect_player(p: Player) -> void:
	_player   = p
	_max_hull = GameManager.player_max_hull
	_max_fuel = float(GameManager.player_max_fuel)
	_hull     = p.health.hull
	_shield   = p.health.shield
	_fuel     = p.fuel_sys.fuel
	_missiles = p.weapons.missiles
	_emp      = p.weapons.emp_charges
	_score    = GameManager.score
	p.health.hull_changed.connect(func(v):      _hull    = v; queue_redraw())
	p.health.shield_changed.connect(func(v):    _shield  = v; queue_redraw())
	p.fuel_sys.fuel_changed.connect(func(v):    _fuel    = v; queue_redraw())
	p.weapons.missiles_changed.connect(func(v): _missiles = v; queue_redraw())
	p.weapons.emp_changed.connect(func(v):      _emp     = v; queue_redraw())
	queue_redraw()

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _flicker(col: Color) -> Color:
	var a: float = 0.45 + 0.55 * abs(sin(_wobble * 2.5))
	return Color(col.r, col.g, col.b, a)

## Corner-bracket panel — sci-fi terminal style. Fills background, marks corners.
func _panel(x: float, y: float, w: float, h: float, cs: float = 6.0) -> void:
	draw_rect(Rect2(x, y, w, h), COL_BG)
	# Scanline pattern overlay
	var scanline_col := Color(0.0, 0.08, 0.0, 0.12)
	var sy := y
	while sy < y + h:
		draw_line(Vector2(x, sy), Vector2(x + w, sy), scanline_col)
		sy += 2.0
	var c := COL_CORNER
	var ci := Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, c.a * 0.5)  # inner bracket color
	var ics := cs * 0.6  # inner bracket size
	# Top-left double bracket
	draw_line(Vector2(x,     y),     Vector2(x + cs, y),     c)
	draw_line(Vector2(x,     y),     Vector2(x,     y + cs), c)
	draw_line(Vector2(x + 2, y + 2), Vector2(x + ics + 2, y + 2), ci)
	draw_line(Vector2(x + 2, y + 2), Vector2(x + 2, y + ics + 2), ci)
	# Top-right double bracket
	draw_line(Vector2(x + w, y),     Vector2(x + w - cs, y), c)
	draw_line(Vector2(x + w, y),     Vector2(x + w, y + cs), c)
	draw_line(Vector2(x + w - 2, y + 2), Vector2(x + w - ics - 2, y + 2), ci)
	draw_line(Vector2(x + w - 2, y + 2), Vector2(x + w - 2, y + ics + 2), ci)
	# Bottom-left double bracket
	draw_line(Vector2(x,     y + h), Vector2(x + cs, y + h), c)
	draw_line(Vector2(x,     y + h), Vector2(x,     y + h - cs), c)
	draw_line(Vector2(x + 2, y + h - 2), Vector2(x + ics + 2, y + h - 2), ci)
	draw_line(Vector2(x + 2, y + h - 2), Vector2(x + 2, y + h - ics - 2), ci)
	# Bottom-right double bracket
	draw_line(Vector2(x + w, y + h), Vector2(x + w - cs, y + h), c)
	draw_line(Vector2(x + w, y + h), Vector2(x + w, y + h - cs), c)
	draw_line(Vector2(x + w - 2, y + h - 2), Vector2(x + w - ics - 2, y + h - 2), ci)
	draw_line(Vector2(x + w - 2, y + h - 2), Vector2(x + w - 2, y + h - ics - 2), ci)

# ─── Main draw ────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Hide HUD during overlay screens (sector transition, upgrade, death, win)
	var state := GameManager.current_state
	if state == GameManager.GameState.MENU or \
	   state == GameManager.GameState.DEATH or \
	   state == GameManager.GameState.WIN or \
	   state == GameManager.GameState.SECTOR_TRANSITION or \
	   state == GameManager.GameState.UPGRADE_SCREEN:
		return
	var font := _font
	_draw_status_panel(font)
	_draw_weapons_panel(font)
	_draw_score_display(font)
	_draw_sector_display(font)
	_draw_streak_display(font)
	_draw_context_hint(font)

# ─── Status panel — top-left ──────────────────────────────────────────────────

func _draw_status_panel(font: Font) -> void:
	var px := 3.0; var py := 3.0; var pw := 88.0; var ph := 38.0
	_panel(px, py, pw, ph)

	# Header strip
	draw_rect(Rect2(px + 1, py + 1, pw - 2, 9), COL_HEADER)
	draw_string(font, Vector2(px + 5, py + 7.5), "SHIP STATUS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_HDR_TXT)

	# Bars
	var hull_pct: float = float(_hull) / maxf(_max_hull, 1)
	var fuel_pct: float = _fuel / maxf(_max_fuel, 1)
	_draw_bar(font, px + 3, py + 13,
		"HULL", float(_hull), float(_max_hull),
		COL_HULL if hull_pct > 0.25 else _flicker(COL_CRIT))
	_draw_bar(font, px + 3, py + 22,
		"SHLD", float(_shield), 100.0, COL_SHIELD)
	_draw_bar(font, px + 3, py + 31,
		"FUEL", _fuel, _max_fuel,
		COL_FUEL if fuel_pct > 0.15 else _flicker(COL_CRIT))

func _draw_bar(font: Font, x: float, y: float,
			   lbl: String, val: float, max_val: float, col: Color) -> void:
	draw_string(font, Vector2(x, y + BAR_H), lbl,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_GREEN)

	var bx := x + 22.0
	# Track background
	draw_rect(Rect2(bx, y, BAR_W, BAR_H), COL_DIM)
	# Fill with gradient (darker at bottom, brighter at top)
	var pct: float = clampf(val / maxf(max_val, 1), 0.0, 1.0)
	var fill: float = pct * BAR_W
	if fill > 0.5:
		# Bottom row: darker
		var dark_col := Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, col.a)
		draw_rect(Rect2(bx, y + 2, fill, 1), dark_col)
		# Middle row: normal
		draw_rect(Rect2(bx, y + 1, fill, 1), col)
		# Top row: brighter
		var bright_top := Color(minf(col.r * 1.3, 1.0), minf(col.g * 1.3, 1.0),
								minf(col.b * 1.3, 1.0), col.a)
		draw_rect(Rect2(bx, y, fill, 1), bright_top)
		# Bright leading edge with subtle glow
		var edge := Color(minf(col.r * 1.8, 1.0), minf(col.g * 1.8, 1.0),
							minf(col.b * 1.8, 1.0), 1.0)
		draw_rect(Rect2(bx + fill - 1.0, y, 1.0, BAR_H), edge)
		# Glow halo on leading edge
		var glow_a := 0.2 + 0.15 * sin(_wobble * 3.0)
		var glow_col := Color(col.r, col.g, col.b, glow_a)
		draw_rect(Rect2(bx + fill - 2.0, y - 1, 3.0, BAR_H + 2), glow_col)
	# Tick marks every 25%
	for tick_i in 3:
		var tx := bx + BAR_W * (float(tick_i + 1) / 4.0)
		draw_line(Vector2(tx, y - 0.5), Vector2(tx, y + BAR_H + 0.5),
			Color(0.2, 0.4, 0.2, 0.35))
	# Track border
	draw_rect(Rect2(bx, y - 0.5, BAR_W, BAR_H + 1),
		Color(col.r, col.g, col.b, 0.18), false)
	# Percentage label
	draw_string(font, Vector2(bx + BAR_W + 3, y + BAR_H), "%d%%" % int(pct * 100),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(col.r, col.g, col.b, 0.58))

# ─── Weapons panel — bottom-left ──────────────────────────────────────────────

func _draw_weapons_panel(font: Font) -> void:
	var vp  := get_viewport_rect()
	var pw  := 116.0; var ph := 15.0
	var px  := 3.0;   var py := vp.size.y - ph - 3.0
	_panel(px, py, pw, ph, 4.0)

	# Missiles label
	draw_string(font, Vector2(px + 3, py + 10), "MSL",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_GREEN)
	# Missile icons — small upward triangles with glow
	for i in 8:
		var ix: float = px + 22.0 + i * 5.5
		var iy: float = py + 3.0
		if i < _missiles:
			# Subtle glow behind available missile
			var ga := 0.12 + 0.06 * sin(_wobble * 2.0 + i * 0.4)
			draw_circle(Vector2(ix + 1.5, iy + 2.5), 4.0, Color(COL_MSL.r, COL_MSL.g, COL_MSL.b, ga))
			draw_colored_polygon(PackedVector2Array([
				Vector2(ix + 1.5, iy),
				Vector2(ix + 3.0, iy + 5.0),
				Vector2(ix,       iy + 5.0)
			]), COL_MSL)
		else:
			draw_colored_polygon(PackedVector2Array([
				Vector2(ix + 1.5, iy),
				Vector2(ix + 3.0, iy + 5.0),
				Vector2(ix,       iy + 5.0)
			]), Color(0.18, 0.18, 0.18, 0.45))

	# EMP label
	var ex: float = px + 74.0
	draw_string(font, Vector2(ex, py + 10), "EMP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_GREEN)
	# EMP icons — small squares with glow
	for i in 4:
		var rx: float = ex + 17.0 + i * 7.0
		var ry: float = py + 3.0
		if i < _emp:
			# Subtle glow behind available EMP
			var ga := 0.15 + 0.08 * sin(_wobble * 2.0 + i * 0.6)
			draw_circle(Vector2(rx + 2.5, ry + 2.5), 5.0, Color(COL_EMP.r, COL_EMP.g, COL_EMP.b, ga))
			draw_rect(Rect2(rx, ry, 5, 5), Color(COL_EMP.r, COL_EMP.g, COL_EMP.b, 0.88))
			draw_rect(Rect2(rx, ry, 5, 5), Color(1, 1, 1, 0.18), false)
		else:
			draw_rect(Rect2(rx, ry, 5, 5), Color(0.06, 0.10, 0.22, 0.55))
			draw_rect(Rect2(rx, ry, 5, 5), Color(0.14, 0.24, 0.44, 0.35), false)

# ─── Score display — top-center ───────────────────────────────────────────────

func _draw_score_display(font: Font) -> void:
	var vp  := get_viewport_rect()
	var pw  := 60.0; var ph := 15.0
	var px: float  = vp.size.x * 0.5 - pw * 0.5
	var py  := 3.0
	_panel(px, py, pw, ph, 4.0)

	# Pulsing border when score changes
	if _score_pulse > 0.0:
		var pa := _score_pulse * 0.6
		var pulse_col := Color(COL_SCORE.r, COL_SCORE.g, COL_SCORE.b, pa)
		draw_rect(Rect2(px - 1, py - 1, pw + 2, ph + 2), pulse_col, false, 1.0)

	# "SCORE" subheader
	draw_string(font, Vector2(px + pw * 0.5 - 9, py + 6.5), "SCORE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_HDR_TXT)
	# 7-digit score
	draw_string(font, Vector2(px + pw * 0.5 - 21, py + 13.5), "%07d" % _score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_SCORE)

func _on_streak_changed(streak: int, mult: int) -> void:
	_streak = streak
	_streak_mult = mult
	_streak_flash = 1.5
	queue_redraw()

# ─── Streak display — below score panel (Change 7c) ───────────────────────────

func _draw_streak_display(font: Font) -> void:
	if _streak < 3:
		return
	var vp  := get_viewport_rect()
	var cx: float = vp.size.x * 0.5
	var a: float = minf(_streak_flash / 1.5, 1.0) if _streak_flash > 0.0 else 0.65
	var col := Color(1.0, 0.80, 0.0, a)
	var label: String = "x%d STREAK" % _streak_mult if _streak_mult > 1 else "%d HITS" % _streak
	draw_string(font, Vector2(cx - 18.0, 32.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, col)

# ─── Sector display — top-right ───────────────────────────────────────────────

func _draw_sector_display(font: Font) -> void:
	var vp  := get_viewport_rect()
	var pw  := 90.0; var ph := 15.0
	var px: float  = vp.size.x - pw - 3.0
	var py  := 3.0
	_panel(px, py, pw, ph, 4.0)

	# "SECTOR N" subheader
	draw_string(font, Vector2(px + 4, py + 6.5),
		"SECTOR %d" % GameManager.current_sector,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_HDR_TXT)
	# Sector name
	draw_string(font, Vector2(px + 4, py + 13.5),
		GameManager.get_sector_name(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_GREEN.r, COL_GREEN.g, COL_GREEN.b, 0.88))

# ─── Context hint — bottom-centre state-aware prompt ─────────────────────────

func _draw_context_hint(font: Font) -> void:
	var vp  := get_viewport_rect()
	var cx: float = vp.size.x * 0.5
	var y: float  = vp.size.y - 8.0
	match GameManager.current_state:
		GameManager.GameState.STAR_CLUSTER:
			draw_string(font, Vector2(cx - 54, y),
				"FLY TO STAR  \u25b6  PRESS [E] TO SCAN",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(0.22, 1.0, 0.08, 0.75))
		GameManager.GameState.SCANNING:
			draw_string(font, Vector2(cx - 34, y),
				"SCANNING \u2014 HOLD ORBIT",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(0.00, 0.80, 1.00, 0.85))
		GameManager.GameState.ALIEN_COMBAT:
			draw_string(font, Vector2(cx - 46, y),
				"CLEAR ALL ENEMIES  \u25b6  HOLD [E] TO ESCAPE",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(1.0, 0.27, 0.0, 0.85))
