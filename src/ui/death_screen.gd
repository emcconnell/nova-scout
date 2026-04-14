## DeathScreen — Fully opaque blast door + signal lost aesthetic.
## GDD Ref: gameplay-mechanics.md §10 — Death & Retry
extends Control

const COL_BG      := Color(0.02, 0.01, 0.01)
const COL_METAL   := Color(0.06, 0.05, 0.05)
const COL_DARK    := Color(0.03, 0.02, 0.02)
const COL_RED     := Color(0.90, 0.10, 0.10)
const COL_DIM_RED := Color(0.40, 0.06, 0.06)
const COL_LABEL   := Color(0.60, 0.60, 0.60)
const COL_CYAN    := Color(0.00, 0.80, 1.00)
const COL_RIVET   := Color(0.10, 0.06, 0.06)

var _show_timer: float = 0.0
var _blink: float = 0.0
var _ready_to_input: bool = false
var _font_title: Font = null
var _font_body: Font = null

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	process_mode  = Node.PROCESS_MODE_ALWAYS
	_font_title = load("res://assets/fonts/Orbitron.ttf") as Font
	_font_body = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font_title == null: _font_title = ThemeDB.fallback_font
	if _font_body == null: _font_body = ThemeDB.fallback_font

func show_death() -> void:
	show()
	_show_timer = 0.0
	_ready_to_input = false
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_show_timer += delta
	_blink += delta
	if _show_timer > 2.0:
		_ready_to_input = true
	queue_redraw()

	if _ready_to_input:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("fire_laser"):
			_retry()
		if Input.is_action_just_pressed("pause"):
			_quit_menu()

func _retry() -> void:
	get_tree().reload_current_scene()

func _quit_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _draw() -> void:
	var vp  := get_viewport_rect()
	var w   := vp.size.x
	var h   := vp.size.y
	var cx  := w * 0.5
	var cy  := h * 0.5
	var font := _font_body

	# === Fully opaque background ===
	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	# === Emergency blast doors — red-tinted metal ===
	draw_rect(Rect2(0, 0, w, 18), COL_METAL)
	draw_rect(Rect2(0, 16, w, 2), COL_DARK)
	draw_rect(Rect2(0, h - 18, w, 18), COL_METAL)
	draw_rect(Rect2(0, h - 18, w, 2), COL_DARK)
	draw_rect(Rect2(0, 18, 6, h - 36), COL_METAL)
	draw_rect(Rect2(w - 6, 18, 6, h - 36), COL_METAL)
	for ri in 14:
		var rx := 16.0 + ri * 22.0
		if rx > w - 16:
			break
		draw_circle(Vector2(rx, 8), 1.2, COL_RIVET)
		draw_circle(Vector2(rx, h - 8), 1.2, COL_RIVET)

	# === Warning stripes on door edges ===
	var warn_a := 0.12 + 0.06 * sin(_blink * 4.0)
	var sx := 0.0
	while sx < w:
		draw_line(Vector2(sx, 0), Vector2(sx + 6, 16), Color(COL_RED.r, COL_RED.g, COL_RED.b, warn_a))
		draw_line(Vector2(sx, h), Vector2(sx + 6, h - 16), Color(COL_RED.r, COL_RED.g, COL_RED.b, warn_a))
		sx += 12.0

	# === Static noise (fades over 2s) ===
	var noise_a := clampf(1.0 - _show_timer * 0.5, 0.0, 1.0) * 0.4
	if noise_a > 0.01:
		var seed_val := int(_blink * 12.0)
		for ni in 80:
			var hv := (ni * 7919 + seed_val * 104729) % 57793
			var nx := fmod(float(hv), w)
			var ny := fmod(float((hv * 31) % 57793), h)
			draw_rect(Rect2(nx, ny, 1, 1), Color(0.5, 0.1, 0.1, noise_a))

	# === Pulsing red border warning ===
	var border_a := 0.15 + 0.10 * sin(_blink * 3.5)
	draw_rect(Rect2(6, 18, w - 12, h - 36),
		Color(COL_RED.r, COL_RED.g, COL_RED.b, border_a), false, 1.0)

	# === Content ===
	var fade_in := clampf(_show_timer * 1.5, 0.0, 1.0)

	# Log header
	draw_string(font, Vector2(14, 30), "// MISSION LOG — TRANSMISSION ENDS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(COL_DIM_RED.r, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.8))
	draw_line(Vector2(14, 34), Vector2(w - 14, 34),
		Color(COL_DIM_RED.r, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.5), 1.0)

	# Main message
	draw_string(_font_title, Vector2(cx - 62, cy - 16), "SIGNAL LOST",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(COL_RED.r, COL_RED.g, COL_RED.b, fade_in))

	draw_line(Vector2(cx - 60, cy - 6), Vector2(cx + 60, cy - 6),
		Color(COL_DIM_RED.r, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.5), 1.0)

	# Stats
	var sy := cy + 10.0
	draw_string(font, Vector2(cx - 52, sy),
		"SECTOR:  %s" % GameManager.get_sector_name(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in))
	draw_string(font, Vector2(cx - 52, sy + 12),
		"SCORE:   %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in))
	draw_string(font, Vector2(cx - 52, sy + 24),
		"BEACONS: %d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in))

	# Retry prompt
	if _ready_to_input:
		var pa := 0.5 + 0.5 * sin(_blink * 3.0)
		draw_string(font, Vector2(cx - 60, h - 28),
			"[SPACE] RETRY     [ESC] MAIN MENU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, pa))
