## PickupVisualsRenderer — machined survey-equipment icon draw pass (TURN 4 polish).
## Every pickup reads as a small metal casing (hull-ramp shaded, dark outline,
## soft attract-glow ring) with a per-type inset that identifies its contents.
## Replaces the old "loose bullet" look, most notably missile_pack + crystal.
class_name PickupVisualsRenderer
extends Object

## Shared metal casing: hull-ramp shading + thin dark outline + attract glow ring.
## `rect` is the casing footprint in local space; `glow_col` drives the ring.
static func draw_casing(ci: CanvasItem, rect: Rect2, glow_col: Color, alpha: float, wobble: float) -> void:
	var ring_r: float = maxf(rect.size.x, rect.size.y) * 0.9 + 3.0 + 1.2 * sin(wobble * 1.6)
	var ring_a: float = (0.10 + 0.06 * sin(wobble * 1.4)) * alpha
	DrawKit.glow(ci, rect.get_center(), ring_r, Color(glow_col.r, glow_col.g, glow_col.b, ring_a), 3)

	var dark := Color(0.08, 0.09, 0.10, alpha)
	var mid := Color(0.42, 0.45, 0.49, alpha)
	var light := Color(0.72, 0.75, 0.79, alpha)
	DrawKit.vgrad_rect(ci, rect, light, dark, 5)
	# Thin center highlight band + dark outline read as a machined metal casing.
	ci.draw_rect(Rect2(rect.position.x + rect.size.x * 0.15, rect.position.y,
		rect.size.x * 0.2, rect.size.y), Color(mid.r, mid.g, mid.b, 0.35 * alpha))
	ci.draw_rect(rect, Color(0, 0, 0, 0), false, 0.0)
	_stroke_rect(ci, rect, Color(0, 0, 0, 0.55 * alpha), 0.8)

## fuel_cell — canister with amber liquid window + level line.
static func draw_fuel_cell(ci: CanvasItem, col: Color, alpha: float, wobble: float) -> void:
	var rect := Rect2(-3.5, -6.5, 7.0, 13.0)
	draw_casing(ci, rect, col, alpha, wobble)
	# Liquid window — amber fill with a level line that gently breathes.
	var window := Rect2(-2.0, -4.5, 4.0, 9.0)
	ci.draw_rect(window, Color(0.05, 0.03, 0.0, 0.6 * alpha))
	var level: float = 0.35 + 0.08 * sin(wobble * 1.5)
	var fill_h: float = window.size.y * level
	ci.draw_rect(Rect2(window.position.x, window.position.y + window.size.y - fill_h,
		window.size.x, fill_h), Color(col.r, col.g, col.b, 0.75 * alpha))
	ci.draw_line(Vector2(window.position.x, window.position.y + window.size.y - fill_h),
		Vector2(window.position.x + window.size.x, window.position.y + window.size.y - fill_h),
		Color(1, 0.95, 0.7, 0.6 * alpha), 0.6)
	# Cap
	ci.draw_rect(Rect2(-1.2, -7.2, 2.4, 1.2), Color(0.6, 0.62, 0.66, alpha))

## repair_kit — plate with white cross inset, soft red glow behind it.
static func draw_repair_kit(ci: CanvasItem, col: Color, alpha: float, wobble: float) -> void:
	var rect := Rect2(-5.5, -5.5, 11.0, 11.0)
	draw_casing(ci, rect, col, alpha, wobble)
	var rpa: float = 0.22 + 0.14 * sin(wobble * 2.2)
	ci.draw_rect(Rect2(-2.4, -6.5, 4.8, 13.0), Color(1, 0.4, 0.4, rpa * alpha))
	ci.draw_rect(Rect2(-6.5, -2.4, 13.0, 4.8), Color(1, 0.4, 0.4, rpa * alpha))
	ci.draw_rect(Rect2(-1.8, -4.5, 3.6, 9.0), Color(1, 1, 1, alpha))
	ci.draw_rect(Rect2(-4.5, -1.8, 9.0, 3.6), Color(1, 1, 1, alpha))

## missile_pack — closed launch crate with 3 tiny fin tips peeking from an open top.
## Reads as sealed ordnance, not loose bullets: casing is a squat rounded box.
static func draw_missile_pack(ci: CanvasItem, col: Color, alpha: float, wobble: float) -> void:
	var rect := Rect2(-6.0, -4.0, 12.0, 8.5)
	draw_casing(ci, rect, col, alpha, wobble)
	# Open top lip — a thin darker band marking the hatch line.
	ci.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1.4),
		Color(0.05, 0.05, 0.06, 0.6 * alpha))
	# 3 fin tips peeking out — small triangles, not full missile bodies.
	var flame := VisualState.proj("flame")
	for i in 3:
		var ox: float = (float(i) - 1.0) * 3.4
		var bob: float = 0.3 * sin(wobble * 2.2 + float(i) * 1.1)
		var tip := Vector2(ox, rect.position.y - 1.6 + bob)
		var tri := PackedVector2Array([
			tip, tip + Vector2(-1.1, 2.2), tip + Vector2(1.1, 2.2),
		])
		ci.draw_colored_polygon(tri, Color(col.r, col.g, col.b, alpha))
		ci.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]),
			Color(0, 0, 0, 0.4 * alpha), 0.5)
		var exa: float = (0.18 + 0.12 * sin(wobble * 3.0 + float(i))) * alpha
		DrawKit.glow(ci, tip + Vector2(0, 0.6), 1.4, Color(flame.r, flame.g, flame.b, exa), 3)
	# Stenciled hazard tick on the crate face — reads as ordnance, not a canister.
	ci.draw_line(Vector2(-3.0, 2.5), Vector2(3.0, 2.5), Color(0.15, 0.14, 0.12, 0.5 * alpha), 0.7)

## emp_cartridge — coil ring device with a cyan arc, not a plain blue ball.
static func draw_emp_cartridge(ci: CanvasItem, col: Color, alpha: float, wobble: float) -> void:
	var rect := Rect2(-3.5, -3.5, 7.0, 7.0)
	var ring_glow := VisualState.proj("ring")
	DrawKit.glow(ci, Vector2.ZERO, 6.5, Color(ring_glow.r, ring_glow.g, ring_glow.b, 0.28 * alpha), 3)
	# Coil housing — a squat casing behind the ring.
	ci.draw_rect(rect, Color(0.30, 0.32, 0.35, alpha))
	_stroke_rect(ci, rect, Color(0, 0, 0, 0.55 * alpha), 0.7)
	draw_arc(ci, Vector2.ZERO, 5.0, 0.0, TAU, 20, col, 1.6)
	draw_arc(ci, Vector2.ZERO, 3.2, 0.0, TAU, 16, col.darkened(0.2), 1.0)
	var epr: float = 7.2 + 1.3 * sin(wobble * 3.0)
	draw_arc(ci, Vector2.ZERO, epr, 0.0, TAU, 16, Color(ring_glow.r, ring_glow.g, ring_glow.b, 0.22 * alpha), 0.5)
	for arc_i in 4:
		var arc_a: float = TAU / 4.0 * float(arc_i) + wobble * 2.0
		var arc_start := Vector2(cos(arc_a), sin(arc_a)) * 5.0
		var arc_mid := Vector2(cos(arc_a + 0.3), sin(arc_a + 0.3)) * 7.0
		var arc_end := Vector2(cos(arc_a + 0.6), sin(arc_a + 0.6)) * 5.5
		var arc_alpha: float = (0.3 + 0.3 * sin(wobble * 4.0 + float(arc_i))) * alpha
		ci.draw_line(arc_start, arc_mid, Color(0.6, 0.85, 1.0, arc_alpha), 0.5)
		ci.draw_line(arc_mid, arc_end, Color(0.6, 0.85, 1.0, arc_alpha), 0.5)

## energy_cell — cell casing with a bright vertical charge bar.
static func draw_energy_cell(ci: CanvasItem, col: Color, alpha: float, wobble: float) -> void:
	var rect := Rect2(-3.0, -6.0, 6.0, 12.0)
	draw_casing(ci, rect, col, alpha, wobble)
	var bar_rect := Rect2(-1.0, -4.5, 2.0, 9.0)
	ci.draw_rect(bar_rect, Color(0.04, 0.06, 0.03, 0.6 * alpha))
	var charge: float = 0.55 + 0.35 * absf(sin(wobble * 2.2))
	var fill_h: float = bar_rect.size.y * charge
	ci.draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y + bar_rect.size.y - fill_h,
		bar_rect.size.x, fill_h), Color(col.r, col.g, col.b, alpha))
	ci.draw_circle(Vector2(0, -5.5), 1.0, Color(1, 1, 1, 0.4 * alpha))

## crystal — faceted gem with specular glint + inner glow. No longer a spinning diamond bullet.
static func draw_crystal(ci: CanvasItem, col: Color, alpha: float, wobble: float, spin: float) -> void:
	DrawKit.glow(ci, Vector2.ZERO, 6.0, Color(col.r, col.g, col.b, 0.22 * alpha), 4)
	var outer := PackedVector2Array([
		Vector2(0, -7).rotated(spin), Vector2(4.4, -1.8).rotated(spin),
		Vector2(3.0, 5.6).rotated(spin), Vector2(-3.0, 5.6).rotated(spin),
		Vector2(-4.4, -1.8).rotated(spin),
	])
	ci.draw_colored_polygon(outer, Color(col.r, col.g, col.b, alpha))
	# Facet lines from a bright core point — reads as cut gem, not a flat bullet-diamond.
	var core := Vector2(0.4, -1.5).rotated(spin)
	for p in outer:
		ci.draw_line(core, p, Color(1, 1, 1, 0.22 * alpha), 0.5)
	ci.draw_circle(core, 1.1, Color(1, 1, 1, 0.35 * alpha))
	var sp_a: float = 0.4 + 0.5 * sin(wobble * 4.0)
	ci.draw_circle(outer[0], 1.0, Color(1, 1, 1, sp_a * alpha))
	ci.draw_polyline(PackedVector2Array([outer[0], outer[1], outer[2], outer[3], outer[4], outer[0]]),
		Color(0, 0, 0, 0.4 * alpha), 0.5)

## shield_booster — emitter housing with an arc emblem, not a flat hexagon.
static func draw_shield_booster(ci: CanvasItem, col: Color, alpha: float, wobble: float, spin: float) -> void:
	var rect := Rect2(-4.5, -4.5, 9.0, 9.0)
	draw_casing(ci, rect, col, alpha, wobble)
	var hex := PackedVector2Array()
	for i in 6:
		var a: float = TAU / 6.0 * float(i) + spin * 0.3
		hex.append(Vector2(cos(a), sin(a)) * 3.6)
	ci.draw_colored_polygon(hex, Color(col.r, col.g, col.b, 0.35 * alpha))
	ci.draw_polyline(hex + PackedVector2Array([hex[0]]), col, 1.2)
	# Arc emblem — a broken ring across the emitter face reads as "shield" iconography.
	draw_arc(ci, Vector2.ZERO, 2.2, -PI * 0.7, PI * 0.55, 10, Color(1, 1, 1, 0.55 * alpha), 0.7)
	var shr: float = 7.0 + 1.0 * sin(wobble * 2.0)
	var sha: float = 0.2 + 0.15 * sin(wobble * 2.5)
	draw_arc(ci, Vector2.ZERO, shr, 0.0, TAU, 16, Color(0.3, 0.6, 1.0, sha * alpha), 0.5)

## survey_beacon — ringed beacon with slow pulse.
static func draw_survey_beacon(ci: CanvasItem, col: Color, alpha: float, wobble: float) -> void:
	var rect := Rect2(-2.5, 2.0, 5.0, 4.0)
	draw_casing(ci, rect, col, alpha, wobble)
	draw_arc(ci, Vector2(0, -2), 6.0, -PI * 0.8, PI * 1.8, 16, col, 1.6)
	ci.draw_line(Vector2(0, -2), Vector2(0, 4.5), col, 1.2)
	var ba: float = 0.5 + 0.5 * sin(wobble * 1.2)
	DrawKit.glow(ci, Vector2(0, -8), 3.0, Color(1.0, 0.95, 0.0, ba * 0.5 * alpha), 3)
	ci.draw_circle(Vector2(0, -8), 1.8, Color(1.0, 0.95, 0.0, ba * alpha))
	for wi in 3:
		var wr: float = 4.0 + float(wi) * 3.0 + 1.0 * sin(wobble * 1.0 + float(wi))
		var wa: float = (0.3 - float(wi) * 0.08) * alpha
		draw_arc(ci, Vector2(0, -8), wr, -PI * 0.4, PI * 0.4, 8, Color(1.0, 0.9, 0.2, wa), 0.5)

# ─── Helpers ──────────────────────────────────────────────────────────────────

static func draw_arc(ci: CanvasItem, center: Vector2, radius: float, start: float, end: float,
		points: int, color: Color, width: float) -> void:
	ci.draw_arc(center, radius, start, end, points, color, width)

static func _stroke_rect(ci: CanvasItem, rect: Rect2, color: Color, width: float) -> void:
	var pts := PackedVector2Array([
		rect.position, Vector2(rect.position.x + rect.size.x, rect.position.y),
		rect.position + rect.size, Vector2(rect.position.x, rect.position.y + rect.size.y),
		rect.position,
	])
	ci.draw_polyline(pts, color, width)
