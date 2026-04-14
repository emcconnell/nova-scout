## SectorTransition — Hangar door blast-shield aesthetic between sectors.
## GDD Ref: gameplay-mechanics.md §9
extends Control

signal transition_complete()

const COL_BG      := Color(0.03, 0.04, 0.07)
const COL_METAL   := Color(0.06, 0.08, 0.12)
const COL_DARK    := Color(0.02, 0.03, 0.05)
const COL_RIVET   := Color(0.08, 0.10, 0.14)
const COL_LABEL   := Color(0.22, 1.00, 0.08)
const COL_DIM     := Color(0.08, 0.25, 0.08)
const COL_CYAN    := Color(0.00, 0.80, 1.00)
const COL_BORDER  := Color(0.08, 0.22, 0.12)
const COL_WARN    := Color(1.00, 0.60, 0.00)

const PHASE_WARP  := 0
const PHASE_STATS := 1
const PHASE_LOG   := 2

const SECTOR_LOG := [
	"",
	"Inner Rim cleared. Entering uncharted space.",
	"Beta sector traversed. Alien presence confirmed.",
	"Survey Beacon secured. Nova Prima data locked.",
	"2 of 3 beacons secured. Deep Blue locked.",
	"Approaching final coordinates. Stay sharp.",
]

var _phase: int = PHASE_WARP
var _phase_timer: float = 0.0
var _anim: float = 0.0
var _sector_from: int = 1
var _door_progress: float = 0.0   # 0=closed, 1=open
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

func begin(sector_from: int) -> void:
	_sector_from = sector_from
	_phase = PHASE_WARP
	_phase_timer = 0.0
	_anim = 0.0
	_door_progress = 0.0
	GameManager.change_state(GameManager.GameState.SECTOR_TRANSITION)
	get_tree().paused = true
	show()

func _process(delta: float) -> void:
	if not visible:
		return
	_anim += delta
	_phase_timer += delta

	match _phase:
		PHASE_WARP:
			# Door closes then opens
			if _phase_timer < 1.0:
				_door_progress = _phase_timer / 1.0   # closing
			elif _phase_timer < 2.0:
				_door_progress = 1.0
			else:
				_phase = PHASE_STATS
				_phase_timer = 0.0
		PHASE_STATS:
			_door_progress = 1.0
			if _phase_timer >= 2.5 or Input.is_action_just_pressed("ui_accept"):
				_phase = PHASE_LOG
				_phase_timer = 0.0
		PHASE_LOG:
			_door_progress = 1.0
			if _phase_timer >= 2.5 or Input.is_action_just_pressed("ui_accept"):
				_finish()
	queue_redraw()

func _finish() -> void:
	get_tree().paused = false
	GameManager.advance_sector()
	hide()
	transition_complete.emit()

func _draw() -> void:
	var vp := get_viewport_rect()
	var w  := vp.size.x
	var h  := vp.size.y
	var cx := w * 0.5
	var cy := h * 0.5
	# === Fully opaque background ===
	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	# === Blast door panels ===
	var door_h := h * 0.5 * _door_progress
	# Top door sliding down
	_draw_door_panel(0, 0, w, door_h, true)
	# Bottom door sliding up
	_draw_door_panel(0, h - door_h, w, door_h, false)

	# === Center seam line (where doors meet) ===
	if _door_progress > 0.5:
		var seam_y := cy
		draw_line(Vector2(0, seam_y - 1), Vector2(w, seam_y - 1), COL_DARK, 2.0)
		draw_line(Vector2(0, seam_y + 1), Vector2(w, seam_y + 1), COL_DARK, 2.0)
		# Warning stripe at seam
		var sx := 0.0
		while sx < w:
			draw_line(Vector2(sx, seam_y - 3), Vector2(sx + 4, seam_y + 3),
				Color(COL_WARN.r, COL_WARN.g, COL_WARN.b, 0.15))
			sx += 10.0

	# === Content (only when door is mostly closed) ===
	if _door_progress < 0.8:
		return

	var content_a := minf((_door_progress - 0.8) / 0.2, 1.0)

	# Central display panel
	var px := 36.0
	var pw := w - 72.0
	var py := cy - 45.0
	var ph := 90.0
	draw_rect(Rect2(px, py, pw, ph), Color(0.01, 0.02, 0.04, 0.85 * content_a))
	draw_rect(Rect2(px, py, pw, ph), Color(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, content_a), false, 1.0)

	match _phase:
		PHASE_WARP:
			draw_string(_font_title, Vector2(cx - 38, cy - 8),
				"WARP TRANSIT",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(COL_WARN.r, COL_WARN.g, COL_WARN.b, content_a))
		PHASE_STATS:
			_draw_stats(cx, cy, font, content_a)
		PHASE_LOG:
			_draw_log(cx, cy, font, content_a)

func _draw_door_panel(x: float, y: float, w: float, dh: float, is_top: bool) -> void:
	if dh < 1:
		return
	# Metal fill
	draw_rect(Rect2(x, y, w, dh), COL_METAL)

	# Horizontal plate lines
	var plate_spacing := 14.0
	var ly := y + 6.0 if is_top else y + dh - 6.0
	var step := plate_spacing if is_top else -plate_spacing
	var count := 0
	while count < 12:
		if ly >= y and ly <= y + dh:
			draw_line(Vector2(x + 4, ly), Vector2(x + w - 4, ly), COL_DARK, 1.0)
		ly += step
		count += 1

	# Rivets along edges
	var rivet_y := y + 5.0 if is_top else y + dh - 5.0
	for ri in 16:
		var rx := 12.0 + ri * 20.0
		if rx > w - 12:
			break
		draw_circle(Vector2(rx, rivet_y), 1.2, COL_RIVET)

	# Side rail
	draw_rect(Rect2(x, y, 4, dh), COL_DARK)
	draw_rect(Rect2(x + w - 4, y, 4, dh), COL_DARK)

func _draw_stats(cx: float, cy: float, _font_unused: Font, a: float) -> void:
	var label_col := Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, a)
	var cyan_col  := Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, a)
	var dim_col   := Color(COL_DIM.r, COL_DIM.g, COL_DIM.b, a)

	draw_string(_font_title, Vector2(cx - 38, cy - 28), "SECTOR CLEAR",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_col)
	draw_line(Vector2(cx - 60, cy - 20), Vector2(cx + 60, cy - 20),
		Color(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, a), 1.0)

	draw_string(_font_body, Vector2(cx - 50, cy - 6),
		"SCORE     %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, cyan_col)
	draw_string(_font_body, Vector2(cx - 50, cy + 8),
		"ENEMIES   %d" % GameManager.enemies_destroyed,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, cyan_col)
	draw_string(_font_body, Vector2(cx - 50, cy + 22),
		"CRYSTALS  %d" % GameManager.data_crystals,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, cyan_col)

	if sin(_anim * 3.0) > 0.0:
		draw_string(_font_body, Vector2(cx - 30, cy + 40), "[SPACE] CONTINUE",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, dim_col)

func _draw_log(cx: float, cy: float, _font_unused: Font, a: float) -> void:
	var dim_col := Color(COL_DIM.r, COL_DIM.g, COL_DIM.b, a)
	var log_idx := clampi(_sector_from, 1, SECTOR_LOG.size() - 1)
	var log_text: String = SECTOR_LOG[log_idx]

	draw_string(_font_title, Vector2(cx - 38, cy - 24), "MISSION LOG",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, a))
	draw_line(Vector2(cx - 60, cy - 16), Vector2(cx + 60, cy - 16),
		Color(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, a), 1.0)

	# Word wrap at ~40 chars
	if log_text.length() > 40:
		var split := log_text.find(" ", 35)
		if split == -1:
			split = 40
		draw_string(_font_body, Vector2(cx - 68, cy + 2), log_text.substr(0, split),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, dim_col)
		draw_string(_font_body, Vector2(cx - 68, cy + 14), log_text.substr(split + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, dim_col)
	else:
		draw_string(_font_body, Vector2(cx - 68, cy + 2), log_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, dim_col)

	if sin(_anim * 3.0) > 0.0:
		draw_string(_font_body, Vector2(cx - 30, cy + 38), "[SPACE] CONTINUE",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, dim_col)
