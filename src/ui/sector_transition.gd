## SectorTransition — Warp animation + stat summary between sectors.
## GDD Ref: gameplay-mechanics.md §9
extends Control

signal transition_complete()

const COL_BG    := Color(0.00, 0.00, 0.04)
const COL_LABEL := Color(0.22, 1.00, 0.08)
const COL_DIM   := Color(0.08, 0.25, 0.08)
const COL_WHITE := Color(1.0, 1.0, 1.0)

const PHASE_WARP  := 0
const PHASE_STATS := 1
const PHASE_LOG   := 2

const SECTOR_LOG := [
	"",
	"Inner Rim cleared. Entering uncharted space. Fuel nominal. Hull intact.",
	"Beta sector traversed. Alien presence confirmed. They are watching.",
	"Survey Beacon 1 of 3 secured. Nova Prima data locked. Entering alien space.",
	"2 of 3 survey beacons secured. Deep Blue telemetry locked. One sector remains.",
	"Approaching final coordinates. All systems nominal. Stay sharp.",
]

var _phase: int = PHASE_WARP
var _phase_timer: float = 0.0
var _stars: Array[Vector4] = []   # x, y, angle, speed (for warp streaks)
var _anim: float = 0.0
var _sector_from: int = 1

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	process_mode  = Node.PROCESS_MODE_ALWAYS

func begin(sector_from: int) -> void:
	_sector_from = sector_from
	_phase = PHASE_WARP
	_phase_timer = 0.0
	_anim = 0.0
	_build_warp_stars()
	get_tree().paused = true
	show()

func _build_warp_stars() -> void:
	_stars.clear()
	var vp := get_viewport_rect()
	var cx := vp.size.x * 0.5
	var cy := vp.size.y * 0.5
	for i in 60:
		var angle := randf_range(0, TAU)
		var dist  := randf_range(5.0, 30.0)
		_stars.append(Vector4(cx + cos(angle) * dist, cy + sin(angle) * dist, angle, randf_range(0.6, 1.4)))

func _process(delta: float) -> void:
	if not visible:
		return
	_anim += delta
	_phase_timer += delta

	match _phase:
		PHASE_WARP:
			if _phase_timer >= 2.5:
				_phase = PHASE_STATS
				_phase_timer = 0.0
		PHASE_STATS:
			if _phase_timer >= 2.0 or Input.is_action_just_pressed("ui_accept"):
				_phase = PHASE_LOG
				_phase_timer = 0.0
		PHASE_LOG:
			if _phase_timer >= 2.0 or Input.is_action_just_pressed("ui_accept"):
				_finish()
	queue_redraw()

func _finish() -> void:
	get_tree().paused = false
	GameManager.advance_sector()
	hide()
	transition_complete.emit()

func _draw() -> void:
	var vp  := get_viewport_rect()
	var cx  := vp.size.x * 0.5
	var cy  := vp.size.y * 0.5
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	match _phase:
		PHASE_WARP:
			_draw_warp(cx, cy)
		PHASE_STATS:
			_draw_stats(cx, cy, font)
		PHASE_LOG:
			_draw_log(cx, cy, font)

func _draw_warp(cx: float, cy: float) -> void:
	var t := _phase_timer / 2.5
	for s in _stars:
		var streak_len := t * s.w * 120.0
		var start := Vector2(s.x, s.y)
		var end   := Vector2(s.x + cos(s.z) * streak_len, s.y + sin(s.z) * streak_len)
		var a := minf(t * 3.0, 1.0)
		draw_line(start, end, Color(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, a * 0.8), 0.7)

func _draw_stats(cx: float, cy: float, font: Font) -> void:
	draw_string(font, Vector2(cx - 28, cy - 28), "SECTOR CLEAR",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_LABEL)
	draw_string(font, Vector2(cx - 44, cy - 10),
		"SCORE:    %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)
	draw_string(font, Vector2(cx - 44, cy),
		"ENEMIES:  %d" % GameManager.enemies_destroyed,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)
	draw_string(font, Vector2(cx - 44, cy + 10),
		"CRYSTALS: %d" % GameManager.data_crystals,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)

func _draw_log(cx: float, cy: float, font: Font) -> void:
	var log_idx := clampi(_sector_from, 1, SECTOR_LOG.size() - 1)
	var log_text: String = SECTOR_LOG[log_idx]
	# Word-wrap manually by splitting into 2 lines
	var half: int = log_text.length() / 2
	var line1: String = log_text.substr(0, half)
	var line2: String = log_text.substr(half)
	draw_string(font, Vector2(cx - 68, cy - 8), line1,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)
	draw_string(font, Vector2(cx - 68, cy + 4), line2,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_DIM)
	if sin(_anim * 3.0) > 0.0:
		draw_string(font, Vector2(cx - 30, cy + 22), "[SPACE] CONTINUE",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_LABEL)
