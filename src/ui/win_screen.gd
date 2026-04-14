## WinScreen — Victory screen. Fully opaque hangar celebration.
## GDD Ref: level-design.md — Sector 5 endings
extends Control

const COL_BG      := Color(0.02, 0.02, 0.04)
const COL_METAL   := Color(0.06, 0.07, 0.10)
const COL_DARK    := Color(0.03, 0.03, 0.05)
const COL_GOLD    := Color(1.00, 0.88, 0.20)
const COL_LABEL   := Color(0.22, 1.00, 0.08)
const COL_DIM     := Color(0.30, 0.50, 0.30)
const COL_CYAN    := Color(0.00, 0.80, 1.00)
const COL_BORDER  := Color(0.12, 0.25, 0.10)
const COL_RIVET   := Color(0.08, 0.09, 0.12)

var _is_true_ending: bool = false
var _anim: float = 0.0
var _show_timer: float = 0.0
var _credit_scroll: float = 0.0
var _font_title: Font = null
var _font_body: Font = null

const TRUE_LOG := [
	"Survey Probe Seven returning.",
	"Three habitable worlds confirmed.",
	"Golden Shore. Deep Blue. Nova Prima.",
	"The colony fleet launches in eight days.",
	"You did it. Rest now.",
]

const STD_LOG := [
	"Probe Seven returning with beacon data.",
	"The mission is complete.",
	"They'll have questions about the Mothership.",
	"But you're alive. That counts for everything.",
]

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

func show_win(true_ending: bool) -> void:
	_is_true_ending = true_ending
	_anim = 0.0
	_show_timer = 0.0
	_credit_scroll = 0.0
	show()
	AudioManager.play_music("golden_shore")
	GameManager.change_state(GameManager.GameState.WIN)
	GameManager.save_data_on_death()

func _process(delta: float) -> void:
	if not visible:
		return
	_anim += delta
	_show_timer += delta
	if _show_timer > 3.0:
		_credit_scroll += 8.0 * delta
	queue_redraw()

	if _show_timer > 5.0:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("fire_laser"):
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

	# === Stars ===
	for i in 40:
		var sx := fmod(float(i) * 37.3, w)
		var sy := fmod(float(i) * 53.7, h)
		var b  := 0.3 + 0.3 * sin(_anim * 1.2 + i)
		draw_circle(Vector2(sx, sy), 0.6, Color(b, b, b * 1.1))

	# === Hangar frame ===
	draw_rect(Rect2(0, 0, w, 14), COL_METAL)
	draw_rect(Rect2(0, 12, w, 2), COL_DARK)
	draw_rect(Rect2(0, h - 14, w, 14), COL_METAL)
	draw_rect(Rect2(0, h - 14, w, 2), COL_DARK)
	draw_rect(Rect2(0, 14, 5, h - 28), COL_METAL)
	draw_rect(Rect2(w - 5, 14, 5, h - 28), COL_METAL)
	for ri in 14:
		var rx := 14.0 + ri * 22.0
		if rx > w - 14:
			break
		draw_circle(Vector2(rx, 6), 1.0, COL_RIVET)
		draw_circle(Vector2(rx, h - 6), 1.0, COL_RIVET)

	# === Celebration glow (true ending = gold, standard = green) ===
	var glow_col := COL_GOLD if _is_true_ending else COL_LABEL
	var glow_a := 0.03 + 0.02 * sin(_anim * 1.5)
	draw_rect(Rect2(5, 14, w - 10, h - 28), Color(glow_col.r, glow_col.g, glow_col.b, glow_a))

	# Starburst rays
	var burst_count := 12 if _is_true_ending else 6
	for ri in burst_count:
		var ray_angle := TAU / float(burst_count) * float(ri) + _anim * 0.12
		var ray_len := 30.0 + 20.0 * sin(_anim * 0.8 + ri * 0.5)
		var ray_a := 0.04 + 0.02 * sin(_anim * 1.5 + ri)
		var ray_start := Vector2(cx + cos(ray_angle) * 8.0, 30.0 + sin(ray_angle) * 4.0)
		var ray_end := Vector2(cx + cos(ray_angle) * ray_len, 30.0 + sin(ray_angle) * ray_len * 0.4)
		draw_line(ray_start, ray_end, Color(glow_col.r, glow_col.g, glow_col.b, ray_a), 0.5)

	# === Content ===
	var fade := clampf(_show_timer * 1.0, 0.0, 1.0)

	# Title
	var title := "MISSION COMPLETE" if _is_true_ending else "PROBE SEVEN — RETURNING"
	var title_col := Color(glow_col.r, glow_col.g, glow_col.b, fade)
	draw_string(_font_title, Vector2(cx - 56, 32), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, title_col)

	draw_line(Vector2(14, 38), Vector2(w - 14, 38),
		Color(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, fade), 1.0)

	# Score
	draw_string(font, Vector2(cx - 40, 52),
		"FINAL SCORE:  %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade))
	draw_string(font, Vector2(cx - 40, 66),
		"BEACONS:  %d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade))

	draw_line(Vector2(cx - 50, 74), Vector2(cx + 50, 74),
		Color(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, fade * 0.5), 1.0)

	# Mission log
	var log_lines := TRUE_LOG if _is_true_ending else STD_LOG
	var log_y := 88.0 - _credit_scroll
	for line in log_lines:
		if log_y > 76.0 and log_y < h - 24.0:
			draw_string(font, Vector2(cx - 68, log_y), line,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_DIM.r, COL_DIM.g, COL_DIM.b, fade))
		log_y += 14.0

	# Prompt
	if _show_timer > 5.0:
		var pa := 0.5 + 0.5 * sin(_anim * 3.0)
		draw_string(font, Vector2(cx - 32, h - 20), "[SPACE] MAIN MENU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, pa))
