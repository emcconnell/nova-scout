## StarNode — A scannable star in a Star Cluster.
## Approach within range + press E to scan. Result determined by sector + type.
## GDD Ref: gameplay-mechanics.md §4
class_name StarNode
extends Area2D

signal scan_completed(result: String, star_data: Dictionary)
signal scan_aborted()
signal player_in_range(in_range: bool)

# ─── Config ───────────────────────────────────────────────────────────────────
const APPROACH_RADIUS := 35.0
const COL_STAR     := Color(1.00, 0.95, 0.80)
const COL_VIABLE   := Color(0.40, 0.90, 1.00)
const COL_ALIEN    := Color(0.80, 0.00, 1.00)
const COL_ANOMALY  := Color(0.00, 1.00, 0.60)
const COL_RING     := Color(1.00, 0.95, 0.80, 0.30)

# ─── Result types (gameplay-mechanics.md probabilities) ───────────────────────
const RESULT_BARREN   := "barren"
const RESULT_VIABLE   := "human_viable"
const RESULT_ALIEN    := "alien_territory"
const RESULT_ANOMALY  := "anomaly"

# ─── State ────────────────────────────────────────────────────────────────────
var star_data: Dictionary = {}  # {type, result, sector, scan_duration}
var _player_nearby: bool = false
var _scanning: bool = false
var _scan_progress: float = 0.0
var _scan_duration: float = 25.0
var _wobble: float = 0.0
var _scanned: bool = false

func _ready() -> void:
	add_to_group("star_nodes")
	monitoring = true
	collision_layer = 0
	collision_mask = 1   # player
	body_entered.connect(func(body): if body.is_in_group("player"): _set_nearby(true))
	body_exited.connect(func(body): if body.is_in_group("player"): _set_nearby(false))

func setup(data: Dictionary) -> void:
	star_data = data
	_scan_duration = float(data.get("scan_duration", 25.0))

func _set_nearby(val: bool) -> void:
	_player_nearby = val
	player_in_range.emit(val)

func _process(delta: float) -> void:
	_wobble += delta * 2.5
	if _scanned:
		return

	# E key to start/abort
	if _player_nearby and not _scanning:
		if Input.is_action_just_pressed("interact"):
			_start_scan()
	elif _scanning:
		if Input.is_action_just_pressed("interact"):
			_abort_scan()
		else:
			_advance_scan(delta)
	queue_redraw()

func _start_scan() -> void:
	_scanning = true
	_scan_progress = 0.0
	var player := _get_player()
	if player and player.has_method("enter_orbit"):
		player.enter_orbit(self, APPROACH_RADIUS * 0.8)
	AudioManager.play_sfx("scan_start")

func _abort_scan() -> void:
	_scanning = false
	_scan_progress = 0.0
	var player := _get_player()
	if player and player.has_method("exit_orbit"):
		player.exit_orbit()
	scan_aborted.emit()
	AudioManager.play_sfx("scan_abort")

func _advance_scan(delta: float) -> void:
	_scan_progress += delta / _scan_duration
	# Auto-abort if hull critical
	var player := _get_player()
	if player and player.health.hull < 20:
		_abort_scan()
		return
	if _scan_progress >= 1.0:
		_complete_scan()

func _complete_scan() -> void:
	_scanning = false
	_scanned = true
	var player := _get_player()
	if player and player.has_method("exit_orbit"):
		player.exit_orbit()
	var result: String = star_data.get("result", RESULT_BARREN)
	GameManager.stars_scanned += 1
	scan_completed.emit(result, star_data)
	AudioManager.play_sfx("scan_complete")

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func get_scan_progress() -> float:
	return _scan_progress

func is_scanning() -> bool:
	return _scanning

func _draw() -> void:
	var result_type: String = star_data.get("result", "barren")
	var star_col: Color = _get_star_color(result_type)
	var pulse := 0.8 + 0.2 * sin(_wobble)
	# Star glow
	draw_circle(Vector2.ZERO, 8.0 * pulse, Color(star_col.r, star_col.g, star_col.b, 0.25))
	draw_circle(Vector2.ZERO, 5.0, Color(star_col.r, star_col.g, star_col.b, pulse))
	draw_circle(Vector2.ZERO, 3.0, COL_STAR)
	# Approach ring + prompt when nearby
	if _player_nearby and not _scanned:
		draw_arc(Vector2.ZERO, APPROACH_RADIUS, 0, TAU, 32, COL_RING, 0.5)
		var font := ThemeDB.fallback_font
		if not _scanning:
			draw_string(font, Vector2(-16.0, -APPROACH_RADIUS - 4.0), "[E] SCAN",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.22, 1.0, 0.08, 0.9))
		else:
			draw_string(font, Vector2(-16.0, -APPROACH_RADIUS - 4.0), "[E] ABORT",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1.0, 0.5, 0.0, 0.8))
	# Scanned indicator
	if _scanned:
		draw_arc(Vector2.ZERO, 7.0, 0, TAU, 24, Color(0.5, 0.5, 0.5, 0.4), 1.0)

func _get_star_color(result: String) -> Color:
	match result:
		RESULT_VIABLE: return COL_VIABLE
		RESULT_ALIEN:  return COL_ALIEN
		RESULT_ANOMALY: return COL_ANOMALY
		_: return COL_STAR
