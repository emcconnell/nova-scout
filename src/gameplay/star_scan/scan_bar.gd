## ScanBar — Centered arc UI shown during star scanning. TURN 4 thin-line FUI
## restyle: cyan flight-instrument (SURVEY) crossfading to failing red (DEAD).
## Matches star_node.gd's dashed-ring / tick-marked-arc / tracked-caps language.
## GDD Ref: gameplay-mechanics.md §8 — Scan Bar UI; art-bible.md (Turn 4).
extends Control

const ARC_RADIUS := 28.0

var _progress: float = 0.0
var _wobble: float = 0.0
var _target: StarNode = null

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE

## Attach the scan bar to a star and reveal it.
func show_for(star: StarNode) -> void:
	_target = star
	_progress = 0.0
	show()

## Detach and hide the scan bar.
func hide_scan() -> void:
	_target = null
	hide()

func _process(delta: float) -> void:
	_wobble += delta * 6.0
	if _target:
		if _target.is_scanning():
			_progress = _target.get_scan_progress()
		else:
			_progress = 0.0
	queue_redraw()

func _draw() -> void:
	var vp  := get_viewport_rect()
	var cx  := vp.size.x * 0.5
	var cy  := vp.size.y * 0.5
	var center := Vector2(cx, cy + 12.0)
	var font := ThemeDB.fallback_font
	var hud_col := VisualState.pal("hud")
	var accent_col := VisualState.pal("accent")
	var blend := VisualState.blend()
	var dim_col := Color(hud_col.r, hud_col.g, hud_col.b, 0.18)

	# Thin FUI frame — corner ticks instead of a filled panel.
	var fx := cx - 44.0
	var fy := cy - 44.0
	_draw_corner_ticks(Rect2(fx, fy, 88.0, 56.0), Color(hud_col.r, hud_col.g, hud_col.b, 0.5))

	# Dashed background ring — matches the star's rotating range ring language.
	_draw_dashed_arc(center, ARC_RADIUS, PI, TAU, dim_col)

	# Fill arc — thin line, tinted to survey/dead HUD accent color.
	var fill_angle := PI + _progress * PI
	draw_arc(center, ARC_RADIUS, PI, fill_angle, 36, accent_col, 1.0)

	# Tick marks along the half-ring, lit as progress crosses them.
	for i in 10:
		var a := PI + PI * 0.1 * float(i)
		var dir := Vector2(cos(a), sin(a))
		var lit := a <= fill_angle
		var tick_col := accent_col if lit else Color(hud_col.r, hud_col.g, hud_col.b, 0.25)
		draw_line(center + dir * (ARC_RADIUS - 1.5), center + dir * (ARC_RADIUS + 1.5), tick_col, 0.6)

	# Soft glow underlay (kept subtle — thin-line look, not phosphor-thick)
	var ga := 0.12 + 0.08 * sin(_wobble)
	draw_arc(center, ARC_RADIUS - 1, PI, fill_angle, 36,
		Color(hud_col.r, hud_col.g, hud_col.b, ga), 2.0)

	# Percentage text — small, tracking-spaced caps.
	var pct_str := "%d%%" % int(_progress * 100)
	_draw_tracked_label(font, pct_str, Vector2(cx, cy + 15.0), 8, accent_col, blend)

	# Label
	_draw_tracked_label(font, "SCANNING", Vector2(cx, cy - 36.0), 5, hud_col, blend)

## Thin corner-bracket frame (FUI style) instead of a filled rect panel.
func _draw_corner_ticks(rect: Rect2, col: Color) -> void:
	var tick := 6.0
	var corners := [rect.position, rect.position + Vector2(rect.size.x, 0.0),
		rect.position + Vector2(0.0, rect.size.y), rect.position + rect.size]
	for i in corners.size():
		var p: Vector2 = corners[i]
		var dx := -1.0 if i in [1, 3] else 1.0
		var dy := -1.0 if i in [2, 3] else 1.0
		draw_line(p, p + Vector2(tick * dx, 0.0), col, 0.8)
		draw_line(p, p + Vector2(0.0, tick * dy), col, 0.8)

## Rotating-ring-style dashed arc (short segments, static here since the bar
## itself doesn't rotate — dashes still read as techy FUI rather than a solid line).
func _draw_dashed_arc(center: Vector2, radius: float, start: float, end: float, col: Color) -> void:
	var segments := 20
	for i in segments:
		if i % 2 == 0:
			continue
		var a0 := start + (end - start) * float(i) / float(segments)
		var a1 := start + (end - start) * float(i + 1) / float(segments)
		draw_line(center + Vector2(cos(a0), sin(a0)) * radius,
			center + Vector2(cos(a1), sin(a1)) * radius, col, 0.7)

## Small tracking-spaced caps label centered under `anchor`, ghost-offset at high blend.
func _draw_tracked_label(font: Font, text: String, anchor: Vector2, font_size: int,
		col: Color, blend: float) -> void:
	var tracked := _tracked_caps(text)
	var width := font.get_string_size(tracked, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := anchor + Vector2(-width * 0.5, 0.0)
	if blend > 0.5:
		var ghost_a := (blend - 0.5) * 0.6
		draw_string(font, pos + Vector2(1.4, 0.6), tracked,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(col.r, col.g, col.b, col.a * ghost_a))
	draw_string(font, pos, tracked, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

## Insert a thin space between letters for a tracking-spaced caps FUI feel.
func _tracked_caps(text: String) -> String:
	var out := ""
	for i in text.length():
		out += text[i]
		if i < text.length() - 1:
			out += " "
	return out
