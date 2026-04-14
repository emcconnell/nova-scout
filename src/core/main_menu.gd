## MainMenu — Cockpit command console with space-tech typography.
extends Node2D

var _stars: Array[Vector4] = []
var _anim: float = 0.0
var _blink: float = 0.0
var _shooting_stars: Array[Dictionary] = []
var _next_shoot: float = 1.0
var _typewriter_pos: int = 0
var _typewriter_timer: float = 0.0

# Fonts
var _font_title: Font = null    # Orbitron — bold techy title
var _font_body: Font = null     # Share Tech Mono — techy monospace body
var _font_small: Font = null    # Fallback for tiny text

# Colors — brighter palette for visibility
const C_VOID     := Color(0.008, 0.012, 0.028)
const C_HULL     := Color(0.050, 0.060, 0.085)
const C_HULL_LIT := Color(0.080, 0.095, 0.130)
const C_SEAM     := Color(0.030, 0.035, 0.055)
const C_RIVET    := Color(0.065, 0.075, 0.100)
const C_GREEN    := Color(0.25, 1.00, 0.20)
const C_GREEN_DM := Color(0.10, 0.40, 0.08)
const C_CYAN     := Color(0.10, 0.85, 1.00)
const C_AMBER    := Color(1.00, 0.78, 0.15)
const C_DIM      := Color(0.22, 0.32, 0.45)
const C_WHITE    := Color(0.85, 0.88, 0.92)
const C_RED      := Color(0.80, 0.12, 0.08)

const TAGLINE := "SURVEY PROBE SEVEN  —  DEEP SPACE RECON"

func _ready() -> void:
	# Load fonts
	_font_title = load("res://assets/fonts/Orbitron.ttf") as Font
	_font_body = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	_font_small = _font_body if _font_body else ThemeDB.fallback_font
	if _font_title == null:
		_font_title = ThemeDB.fallback_font
	if _font_body == null:
		_font_body = ThemeDB.fallback_font

	var vp := get_viewport_rect()
	for i in 120:
		var layer := i % 3
		_stars.append(Vector4(
			randf_range(0, vp.size.x),
			randf_range(0, vp.size.y),
			randf_range(0.0, TAU),
			0.25 + float(layer) * 0.25 + randf_range(0.0, 0.15)))
	AudioManager.play_music("mission_log")

func _process(delta: float) -> void:
	_anim  += delta
	_blink += delta
	_typewriter_timer += delta
	if _typewriter_timer > 0.05:
		_typewriter_timer = 0.0
		if _typewriter_pos < TAGLINE.length():
			_typewriter_pos += 1
	_next_shoot -= delta
	if _next_shoot <= 0.0:
		_next_shoot = randf_range(2.5, 6.0)
		var vp := get_viewport_rect()
		_shooting_stars.append({
			"x": randf_range(0, vp.size.x * 0.8),
			"y": randf_range(10, vp.size.y * 0.35),
			"vx": randf_range(100, 200), "vy": randf_range(15, 40),
			"life": 0.0, "max_life": randf_range(0.25, 0.55)
		})
	var i := _shooting_stars.size() - 1
	while i >= 0:
		_shooting_stars[i]["life"] += delta
		_shooting_stars[i]["x"] += _shooting_stars[i]["vx"] * delta
		_shooting_stars[i]["y"] += _shooting_stars[i]["vy"] * delta
		if _shooting_stars[i]["life"] >= _shooting_stars[i]["max_life"]:
			_shooting_stars.remove_at(i)
		i -= 1
	queue_redraw()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("fire_laser"):
		if _show_scores:
			_show_scores = false
		else:
			_start_game()
	if Input.is_action_just_pressed("pause"):
		if _show_scores:
			_show_scores = false
		else:
			get_tree().quit()
	if Input.is_key_pressed(KEY_H):
		_show_scores = true
	for key_i in 5:
		if Input.is_key_pressed(KEY_1 + key_i):
			_start_at_sector(key_i + 1)
			return

var _show_scores: bool = false

func _draw() -> void:
	var vp := get_viewport_rect()
	var W  := vp.size.x
	var H  := vp.size.y
	var cx := W * 0.5

	# ═══ Deep space ═══
	draw_rect(Rect2(Vector2.ZERO, vp.size), C_VOID)
	for s in _stars:
		var twinkle := 0.5 + 0.5 * sin(_anim * (0.8 + s.w) + s.z)
		var bright := s.w * twinkle
		var r := 0.4 + s.w * 0.4
		var sc := Color(bright, bright, bright * 1.08)
		if s.w > 0.6:
			sc = Color(bright * 0.9, bright * 0.95, bright)
		draw_circle(Vector2(s.x, s.y), r, sc)
	for ss in _shooting_stars:
		var pct: float = ss["life"] / ss["max_life"]
		var alpha := (1.0 - pct) * 0.9
		var tail := 6.0 + 14.0 * pct
		var px: float = ss["x"]
		var py: float = ss["y"]
		var vx: float = ss["vx"]
		var vy: float = ss["vy"]
		var norm := sqrt(vx * vx + vy * vy)
		draw_line(Vector2(px, py),
			Vector2(px - vx / norm * tail, py - vy / norm * tail),
			Color(0.7, 0.8, 1.0, alpha * 0.4), 1.0)
		draw_circle(Vector2(px, py), 0.7, Color(1.0, 1.0, 1.0, alpha))
	# Nebula
	var neb_a := 0.015 + 0.005 * sin(_anim * 0.3)
	draw_circle(Vector2(W * 0.3, H * 0.35), 60.0, Color(0.15, 0.10, 0.35, neb_a))
	draw_circle(Vector2(W * 0.7, H * 0.25), 45.0, Color(0.08, 0.20, 0.35, neb_a))

	if _show_scores:
		_draw_scores_overlay(vp, cx)
		return

	# ═══ Cockpit frame ═══
	_draw_cockpit_frame(W, H)

	# ═══ TITLE — properly centered ═══
	var title_text := "NOVA SCOUT"
	var title_size := 17
	var title_w := _font_title.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var title_x := cx - title_w * 0.5
	var title_y := 42.0
	# Glow rect behind title
	var tg := 0.06 + 0.03 * sin(_anim * 1.2)
	draw_rect(Rect2(title_x - 6, title_y - 18, title_w + 12, 22),
		Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, tg))
	# Title text (single draw, no doubling)
	draw_string(_font_title, Vector2(title_x, title_y), title_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, C_GREEN)
	# Divider — matched to title width
	draw_line(Vector2(title_x - 4, title_y + 5), Vector2(title_x + title_w + 4, title_y + 5),
		Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.4), 1.0)

	# Tagline — centered via measurement
	var tag_text := TAGLINE.substr(0, _typewriter_pos)
	var tag_size := 5
	var full_tag_w := _font_body.get_string_size(TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size).x
	var tag_x := cx - full_tag_w * 0.5
	draw_string(_font_body, Vector2(tag_x, 57), tag_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size, C_AMBER)
	# Cursor
	if _typewriter_pos < TAGLINE.length() and sin(_blink * 8.0) > 0.0:
		var partial_w := _font_body.get_string_size(tag_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size).x
		draw_rect(Rect2(tag_x + partial_w + 1, 52, 2, 6), C_AMBER)

	# ═══ LAUNCH BUTTON — centered via measurement ═══
	var pulse := 0.5 + 0.5 * sin(_blink * 2.8)
	var launch_text := "SPACE  LAUNCH"
	var launch_size := 11
	var launch_w := _font_title.get_string_size(launch_text, HORIZONTAL_ALIGNMENT_LEFT, -1, launch_size).x
	var btn_pad := 14.0
	var bw := launch_w + btn_pad * 2
	var bh := 18.0
	var bx := cx - bw * 0.5
	var by := 68.0
	# Outer glow
	draw_rect(Rect2(bx - 3, by - 3, bw + 6, bh + 6),
		Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.04 + 0.04 * pulse))
	# Box fill
	draw_rect(Rect2(bx, by, bw, bh), Color(0.01, 0.04, 0.06, 0.85))
	# Border
	draw_rect(Rect2(bx, by, bw, bh),
		Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.35 + 0.35 * pulse), false, 1.0)
	# Text — centered in box
	var launch_x := cx - launch_w * 0.5
	draw_string(_font_title, Vector2(launch_x, by + 14), launch_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, launch_size,
		Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.7 + 0.3 * pulse))

	# ═══ Controls — two columns ═══
	var sys_y := 96.0
	draw_line(Vector2(28, sys_y), Vector2(W - 28, sys_y), C_SEAM, 1.0)
	var lx := 32.0
	draw_string(_font_body, Vector2(lx, sys_y + 10), "FLIGHT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_GREEN_DM)
	_draw_key_pair(lx, sys_y + 20, "WASD", "MOVE")
	_draw_key_pair(lx, sys_y + 29, "SHIFT", "BOOST")
	_draw_key_pair(lx, sys_y + 38, "E", "SCAN")
	var rx2 := cx + 20.0
	draw_string(_font_body, Vector2(rx2, sys_y + 10), "WEAPONS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_GREEN_DM)
	_draw_key_pair(rx2, sys_y + 20, "SPACE", "LASER")
	_draw_key_pair(rx2, sys_y + 29, "X", "MISSILE")
	_draw_key_pair(rx2, sys_y + 38, "Z", "EMP")

	# ═══ Footer — three items evenly spaced ═══
	var fy := H - 18.0
	draw_rect(Rect2(24, fy, W - 48, 14), Color(C_HULL.r, C_HULL.g, C_HULL.b, 0.85))
	draw_line(Vector2(24, fy), Vector2(W - 24, fy), C_SEAM, 1.0)
	_draw_centered_text(_font_body, "H SCORES", W * 0.22, fy + 10, 5, C_DIM)
	_draw_centered_text(_font_body, "1-5 SECTOR", cx, fy + 10, 5, C_DIM)
	_draw_centered_text(_font_body, "ESC QUIT", W * 0.78, fy + 10, 5, C_DIM)

	# Status indicators
	_draw_indicator(Vector2(30, 22), "SYS", true)
	_draw_indicator(Vector2(56, 22), "NAV", true)
	_draw_indicator(Vector2(82, 22), "COM", sin(_anim * 2.0) > 0.0)
	# Clock
	var secs := int(_anim) % 3600
	var clock := "%02d:%02d" % [secs / 60, secs % 60]
	var clock_w := _font_body.get_string_size(clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	draw_string(_font_body, Vector2(W - 26 - clock_w, 24), clock,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.6))

## Draw text centered at x position.
func _draw_centered_text(f: Font, text: String, center_x: float, y: float, sz: int, col: Color) -> void:
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(center_x - tw * 0.5, y), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _draw_key_pair(x: float, y: float, key: String, action: String) -> void:
	draw_string(_font_body, Vector2(x, y), key,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_WHITE)
	draw_string(_font_body, Vector2(x + 34, y), action,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, C_DIM)

func _draw_indicator(pos: Vector2, label: String, on: bool) -> void:
	var col := C_GREEN if on else C_RED
	var bright := 0.9 if on else 0.3
	draw_circle(pos + Vector2(0, 2), 2.0, Color(col.r * bright, col.g * bright, col.b * bright))
	if on:
		draw_circle(pos + Vector2(0, 2), 3.5, Color(col.r, col.g, col.b, 0.18))
	draw_string(_font_body, pos + Vector2(5, 5), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(col.r, col.g, col.b, 0.7))

func _draw_cockpit_frame(W: float, H: float) -> void:
	draw_rect(Rect2(0, 0, W, 14), C_HULL)
	draw_line(Vector2(0, 14), Vector2(W, 14), C_SEAM, 1.0)
	var cut := 20.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 14), Vector2(cut, 14), Vector2(0, 14 + cut * 0.5)
	]), C_HULL)
	draw_colored_polygon(PackedVector2Array([
		Vector2(W, 14), Vector2(W - cut, 14), Vector2(W, 14 + cut * 0.5)
	]), C_HULL)
	draw_rect(Rect2(0, H - 20, W, 20), C_HULL)
	draw_line(Vector2(0, H - 20), Vector2(W, H - 20), C_SEAM, 1.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, H - 20), Vector2(cut, H - 20), Vector2(0, H - 20 - cut * 0.4)
	]), C_HULL)
	draw_colored_polygon(PackedVector2Array([
		Vector2(W, H - 20), Vector2(W - cut, H - 20), Vector2(W, H - 20 - cut * 0.4)
	]), C_HULL)
	draw_rect(Rect2(0, 14, 24, H - 34), C_HULL)
	draw_line(Vector2(24, 14), Vector2(24, H - 20), C_SEAM, 1.0)
	draw_rect(Rect2(W - 24, 14, 24, H - 34), C_HULL)
	draw_line(Vector2(W - 24, 14), Vector2(W - 24, H - 20), C_SEAM, 1.0)
	for ri in 12:
		var rvx := 30.0 + ri * 22.0
		if rvx > W - 30:
			break
		draw_circle(Vector2(rvx, 6), 1.0, C_RIVET)
		draw_circle(Vector2(rvx, H - 8), 1.0, C_RIVET)
	for ri in 5:
		var rvy := 24.0 + ri * 28.0
		if rvy > H - 30:
			break
		draw_circle(Vector2(10, rvy), 1.0, C_RIVET)
		draw_circle(Vector2(W - 10, rvy), 1.0, C_RIVET)
	draw_line(Vector2(24, 15), Vector2(W - 24, 15),
		Color(C_HULL_LIT.r, C_HULL_LIT.g, C_HULL_LIT.b, 0.5), 1.0)

func _draw_scores_overlay(vp: Rect2, cx: float) -> void:
	var W := vp.size.x
	var H := vp.size.y
	_draw_cockpit_frame(W, H)
	var px := 36.0
	var pw := W - 72.0
	var py := 20.0
	var ph := H - 42.0
	draw_rect(Rect2(px, py, pw, ph), Color(0.01, 0.015, 0.03, 0.94))
	draw_rect(Rect2(px, py, pw, ph), Color(C_GREEN_DM.r, C_GREEN_DM.g, C_GREEN_DM.b, 0.5), false, 1.0)

	_draw_centered_text(_font_title, "HIGH SCORES", cx, py + 16, 10, C_GREEN)
	draw_line(Vector2(px + 6, py + 20), Vector2(px + pw - 6, py + 20),
		Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.3), 1.0)

	var scores := SaveManager.get_high_scores()
	for si in mini(scores.size(), 10):
		var s: Dictionary = scores[si]
		var y := py + 32.0 + si * 12.0
		var rank_col := C_AMBER if si == 0 else C_WHITE
		draw_string(_font_body, Vector2(px + 8, y),
			"%02d" % (si + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, rank_col)
		draw_string(_font_body, Vector2(px + 24, y),
			"%07d" % s.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, C_CYAN)
		draw_string(_font_body, Vector2(px + 66, y),
			"S%d B%d" % [s.sector, s.beacons], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, C_DIM)
	if scores.is_empty():
		_draw_centered_text(_font_body, "NO DATA RECORDED", cx, py + 52, 6, C_DIM)
	_draw_centered_text(_font_body, "SPACE / ESC  BACK", cx, H - 26, 6, C_DIM)

func _start_game() -> void:
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _start_at_sector(sector: int) -> void:
	GameManager.start_new_game()
	GameManager.current_sector = sector
	if sector >= 3:
		GameManager.player_max_hull = 140
		GameManager.player_hull = 140
		GameManager.player_laser_damage = 16
		GameManager.player_max_missiles = 18
		GameManager.player_missiles = 12
		GameManager.data_crystals = 15
		GameManager.survey_beacons = sector - 3
	elif sector == 2:
		GameManager.data_crystals = 5
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")
