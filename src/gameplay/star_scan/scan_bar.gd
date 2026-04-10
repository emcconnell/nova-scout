## ScanBar — Centered arc UI shown during star scanning. CRT phosphor aesthetic.
## GDD Ref: gameplay-mechanics.md §8 — Scan Bar UI
extends Control

const COL_BG    := Color(0.00, 0.10, 0.05, 0.70)
const COL_FILL  := Color(0.00, 0.90, 0.30)
const COL_GLOW  := Color(0.00, 1.00, 0.40, 0.35)
const COL_LABEL := Color(0.20, 1.00, 0.08)
const ARC_RADIUS := 28.0

var _progress: float = 0.0
var _wobble: float = 0.0
var _target: StarNode = null

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE

func show_for(star: StarNode) -> void:
	_target = star
	_progress = 0.0
	show()

func hide_scan() -> void:
	_target = null
	hide()

func _process(delta: float) -> void:
	_wobble += delta * 6.0
	if _target and _target.is_scanning():
		_progress = _target.get_scan_progress()
	queue_redraw()

func _draw() -> void:
	var vp  := get_viewport_rect()
	var cx  := vp.size.x * 0.5
	var cy  := vp.size.y * 0.5
	var font := ThemeDB.fallback_font

	# Background panel
	draw_rect(Rect2(cx - 44, cy - 44, 88, 56), COL_BG)

	# Background arc
	draw_arc(Vector2(cx, cy + 12), ARC_RADIUS, PI, TAU, 36, Color(0.08, 0.20, 0.08), 3.0)

	# Fill arc
	var fill_angle := PI + _progress * PI
	draw_arc(Vector2(cx, cy + 12), ARC_RADIUS, PI, fill_angle, 36, COL_FILL, 3.0)

	# Glow
	var ga := 0.3 + 0.2 * sin(_wobble)
	draw_arc(Vector2(cx, cy + 12), ARC_RADIUS - 1, PI, fill_angle, 36,
		Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, ga), 5.0)

	# Percentage text
	var pct_str := "%d%%" % int(_progress * 100)
	draw_string(font, Vector2(cx - 10, cy + 15), pct_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_LABEL)

	# Label
	draw_string(font, Vector2(cx - 22, cy - 36), "SCANNING",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, COL_LABEL)
