## MainMenu — Retro title screen. Press ENTER or SPACE to start.
extends Node2D

var _stars: Array[Vector3] = []   # x, y, twinkle_offset
var _anim: float = 0.0
var _blink: float = 0.0

const COL_BG    := Color(0.031, 0.043, 0.078)
const COL_TITLE := Color(0.22, 1.00, 0.08)
const COL_SUB   := Color(1.00, 0.70, 0.00)
const COL_BLINK := Color(0.00, 0.80, 1.00)
const COL_DIM   := Color(0.12, 0.18, 0.28)

func _ready() -> void:
	var vp := get_viewport_rect()
	for i in 90:
		_stars.append(Vector3(
			randf_range(0, vp.size.x),
			randf_range(0, vp.size.y),
			randf_range(0.0, TAU)))
	AudioManager.play_music("mission_log")

func _process(delta: float) -> void:
	_anim  += delta
	_blink += delta
	queue_redraw()
	# Input
	if Input.is_action_just_pressed("ui_accept") or \
	   Input.is_action_just_pressed("fire_laser"):
		_start_game()
	if Input.is_action_just_pressed("pause"):
		if _show_scores:
			_show_scores = false
		else:
			get_tree().quit()
	if Input.is_key_pressed(KEY_H):
		_show_scores = true
		queue_redraw()

var _show_scores: bool = false

func _draw() -> void:
	var vp   := get_viewport_rect()
	var cx   := vp.size.x * 0.5
	var font := ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	if _show_scores:
		_draw_high_scores(vp, cx, font)
		return

	# Stars
	for s in _stars:
		var b := 0.45 + 0.35 * sin(_anim * 1.2 + s.z)
		draw_circle(Vector2(s.x, s.y), 0.8, Color(b, b, b * 1.15))

	# Decorative horizontal lines
	draw_line(Vector2(20, 30), Vector2(vp.size.x - 20, 30), COL_DIM, 0.5)
	draw_line(Vector2(20, vp.size.y - 30), Vector2(vp.size.x - 20, vp.size.y - 30), COL_DIM, 0.5)

	# NOVA SCOUT title
	draw_string(font, Vector2(cx - 34, 55), "NOVA SCOUT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_TITLE)

	# Tagline
	draw_string(font, Vector2(cx - 60, 72), "SURVEY PROBE SEVEN",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, COL_SUB)

	# Flavour text
	draw_string(font, Vector2(cx - 68, 88),
		"FIVE SECTORS.  THREE WORLDS.  ONE HOUR.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)

	# Blinking prompt
	if sin(_blink * 3.5) > 0.0:
		draw_string(font, Vector2(cx - 44, 112),
			"PRESS SPACE TO LAUNCH",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_BLINK)

	# High scores prompt
	draw_string(font, Vector2(cx - 42, 128),
		"[H] HIGH SCORES",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)

	# Controls hint
	draw_string(font, Vector2(cx - 68, 140),
		"WASD/ARROWS: MOVE   SHIFT: BOOST   SPACE: LASER",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_DIM)
	draw_string(font, Vector2(cx - 52, 148),
		"X: MISSILE   Z: EMP   ESC: QUIT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_DIM)

	# Version
	draw_string(font, Vector2(4, vp.size.y - 4),
		"BUILD 0.2  —  FULL BUILD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_DIM)

func _draw_high_scores(vp: Rect2, cx: float, font: Font) -> void:
	var scores := SaveManager.get_high_scores()
	draw_string(font, Vector2(cx - 28, 20), "HIGH SCORES",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COL_TITLE)
	draw_line(Vector2(20, 28), Vector2(vp.size.x - 20, 28), COL_DIM, 0.5)
	for i in mini(scores.size(), 10):
		var s: Dictionary = scores[i]
		var y := 38.0 + i * 13.0
		draw_string(font, Vector2(20, y),
			"%02d.  %07d  SEC:%d  BCN:%d" % [i+1, s.score, s.sector, s.beacons],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_TITLE)
	if scores.is_empty():
		draw_string(font, Vector2(cx - 24, 60), "NO SCORES YET",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_DIM)
	draw_string(font, Vector2(cx - 22, vp.size.y - 8), "[ESC] BACK",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)

func _start_game() -> void:
	GameManager.start_new_game()   # Fresh game — reset everything before loading
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")
