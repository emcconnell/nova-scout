## WinScreen — True ending (defeated Mothership) or standard ending (escaped).
## GDD Ref: level-design.md — Sector 5 endings
extends Control

const COL_BG      := Color(0.00, 0.00, 0.02, 0.96)
const COL_GOLD    := Color(1.00, 0.88, 0.20)
const COL_LABEL   := Color(0.22, 1.00, 0.08)
const COL_DIM     := Color(0.30, 0.50, 0.30)
const COL_BLINK   := Color(0.00, 0.80, 1.00)

var _is_true_ending: bool = false
var _anim: float = 0.0
var _show_timer: float = 0.0
var _credit_scroll: float = 0.0

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
		_credit_scroll += 10.0 * delta
	queue_redraw()

	if _show_timer > 5.0:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("fire_laser"):
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _draw() -> void:
	var vp  := get_viewport_rect()
	var cx  := vp.size.x * 0.5
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	# Stars
	var t := _anim
	for i in 40:
		var sx := fmod(float(i) * 37.3, vp.size.x)
		var sy := fmod(float(i) * 53.7, vp.size.y)
		var b  := 0.4 + 0.4 * sin(t * 1.2 + i)
		draw_circle(Vector2(sx, sy), 0.7, Color(b, b, b * 1.1))

	# Title
	var title := "MISSION COMPLETE" if _is_true_ending else "PROBE SEVEN — RETURNING"
	draw_string(font, Vector2(cx - 52, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_GOLD)

	# Score
	draw_string(font, Vector2(cx - 36, 38),
		"FINAL SCORE: %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_LABEL)
	draw_string(font, Vector2(cx - 36, 50),
		"BEACONS:  %d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)

	# Mission log scrolling
	var log_lines := TRUE_LOG if _is_true_ending else STD_LOG
	var log_y := 75.0 - _credit_scroll
	for line in log_lines:
		if log_y > 60.0 and log_y < vp.size.y - 10.0:
			draw_string(font, Vector2(cx - 68, log_y), line,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)
		log_y += 14.0

	# Prompt
	if _show_timer > 5.0 and sin(_anim * 3.5) > 0.0:
		draw_string(font, Vector2(cx - 38, vp.size.y - 8), "[SPACE] MAIN MENU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_BLINK)
