## DeathScreen — Shows on player death. Log entry aesthetic + retry.
## GDD Ref: gameplay-mechanics.md §10 — Death & Retry
extends Control

const COL_BG    := Color(0.00, 0.00, 0.02, 0.92)
const COL_RED   := Color(0.90, 0.10, 0.10)
const COL_DIM   := Color(0.50, 0.08, 0.08)
const COL_LABEL := Color(0.70, 0.70, 0.70)
const COL_BLINK := Color(0.00, 0.80, 1.00)

var _show_timer: float = 0.0
var _blink: float = 0.0
var _ready_to_input: bool = false

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	process_mode  = Node.PROCESS_MODE_ALWAYS

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
	var cx  := vp.size.x * 0.5
	var cy  := vp.size.y * 0.5
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	# Log header
	draw_string(font, Vector2(8, 12), "// MISSION LOG — TRANSMISSION ENDS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)
	draw_line(Vector2(8, 16), Vector2(vp.size.x - 8, 16), COL_DIM, 0.5)

	# Main message
	draw_string(font, Vector2(cx - 42, cy - 20), "PROBE SEVEN — SIGNAL LOST",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_RED)

	# Stats
	var stats_y := cy + 2.0
	draw_string(font, Vector2(cx - 52, stats_y),
		"SECTOR: %s" % GameManager.get_sector_name(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)
	draw_string(font, Vector2(cx - 52, stats_y + 10),
		"SCORE:  %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)
	draw_string(font, Vector2(cx - 52, stats_y + 20),
		"BEACONS:%d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)

	# Retry prompt
	if _ready_to_input and sin(_blink * 3.5) > 0.0:
		draw_string(font, Vector2(cx - 54, cy + 44),
			"[SPACE] RETRY SECTOR   [ESC] MAIN MENU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_BLINK)
