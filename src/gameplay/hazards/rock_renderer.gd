## RockRenderer — Shared sunlit-rock / ember-rim-rock drawing technique (TURN 4).
## Static: builds a seeded RockData once, then draws it every frame blended by
## VisualState.blend(). All shading layers (stepped form shading, terminator,
## craters, mottling) are clipped to the rock silhouette at build time via
## Geometry2D.intersect_polygons — nothing bleeds outside the rock, and _draw
## stays a flat list of precomputed polygons. Used by Asteroid.
class_name RockRenderer
extends Object

## Precomputed per-instance seeded surface detail — build once in setup/_ready.
class RockData:
	var pts: PackedVector2Array = PackedVector2Array()
	var radius: float = 8.0
	var dead_dir: Vector2 = Vector2(0.72, -0.55)
	var ramp_steps: Array[Dictionary] = []      # {color, polys: Array[PackedVector2Array]}
	var terminator: Array[Dictionary] = []      # {poly, alpha} — graded shadow bands
	var mottles: Array[Dictionary] = []         # {color, polys}
	var craters: Array[Dictionary] = []         # {fills: [{color, polys}], arcs: [{color, lines}]}
	var regolith: Array[Dictionary] = []        # {pos, is_boulder, coin, shadow_ok}
	var flecks: Array[Dictionary] = []          # {pos, dark}
	var dead_steps: Array[Dictionary] = []      # {color, polys}
	var dead_craters: Array[Dictionary] = []    # {fill_polys, arc_lines}

const _LIGHT_DIR := Vector2(-0.66, -0.75)   # sunlit key light, upper-left

## Builds seeded rock geometry + silhouette-clipped shading. Call once per rock.
static func build(center: Vector2, radius: float, seed_value: int) -> RockData:
	var data := RockData.new()
	data.radius = radius
	data.pts = DrawKit.rock_points(center, radius, seed_value, 24)
	var rng := DrawKit.rng(seed_value * 7 + 1)
	var dir_rng := DrawKit.rng(seed_value * 13 + 5)
	var dead_angle := dir_rng.randf() * TAU
	data.dead_dir = Vector2(cos(dead_angle), sin(dead_angle))

	_build_survey_shading(data, center, radius)
	_build_mottles(data, center, radius, rng)
	_build_craters(data, center, radius, rng)
	_build_specks(data, center, radius, rng)
	_build_dead_shading(data, center, radius, rng)
	return data

## Survey stepped form shading + graded terminator, clipped to the silhouette.
## Many thin steps fake the concept sheet's gradients without hard chord edges.
static func _build_survey_shading(data: RockData, center: Vector2, r: float) -> void:
	var ramp := [
		[0.10, Color(0.24, 0.222, 0.196)],
		[0.18, Color(0.348, 0.328, 0.292)],
		[0.27, Color(0.452, 0.430, 0.386)],
		[0.37, Color(0.552, 0.530, 0.482)],
		[0.48, Color(0.648, 0.626, 0.573)],
		[0.62, Color(0.744, 0.722, 0.667)],
		[0.78, Color(0.839, 0.816, 0.761)],
	]
	for step in ramp:
		var offset: Vector2 = _LIGHT_DIR * r * float(step[0])
		data.ramp_steps.append({
			"color": step[1],
			"polys": _clip_poly(DrawKit.poly_offset(data.pts, offset), data.pts),
		})
	# Graded terminator: stacked half-plane bands marching away from the light,
	# alphas accumulating so the shadow deepens smoothly instead of snapping.
	data.terminator = []
	var starts := [0.42, 0.18, -0.06, -0.30]
	var alphas := [0.16, 0.22, 0.28, 0.34]
	for i in starts.size():
		for p in _terminator_band(data.pts, center, r, float(starts[i])):
			data.terminator.append({"poly": p, "alpha": float(alphas[i])})

## Soft mottling blotches as flat clipped ellipses (low alpha reads as tone).
static func _build_mottles(data: RockData, center: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	for i in 8:
		var mpos := center + Vector2((rng.randf() - 0.5), (rng.randf() - 0.5)) * r * 1.5
		var mr := r * (0.2 + rng.randf() * 0.35)
		var dark := rng.randf() > 0.5
		var col := Color(0, 0, 0, 0.14) if dark else Color(0.98, 0.98, 0.933, 0.05)
		data.mottles.append({
			"color": col,
			"polys": _clip_poly(DrawKit.ellipse_points(mpos, Vector2(mr, mr * 0.8), 14), data.pts),
		})

## Craters: fills + rim arcs, every piece clipped to the silhouette.
static func _build_craters(data: RockData, center: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	for i in 9:
		var aa := rng.randf() * TAU
		var dd := rng.randf() * 0.8
		var cpos := center + Vector2(cos(aa), sin(aa)) * r * dd
		var cr := r * (0.07 + rng.randf() * 0.16)
		var sq := 1.0 - dd * 0.5
		var fills: Array[Dictionary] = [
			{"color": Color(0, 0, 0, 0.38),
				"polys": _clip_poly(DrawKit.ellipse_points(cpos, Vector2(cr, cr * sq), 14), data.pts)},
			{"color": Color(0, 0, 0, 0.42),
				"polys": _clip_poly(DrawKit.ellipse_points(cpos + _LIGHT_DIR * cr * 0.28,
					Vector2(cr * 0.72, cr * 0.72 * sq), 12), data.pts)},
			{"color": Color(0.839, 0.808, 0.753, 0.20),
				"polys": _clip_poly(DrawKit.ellipse_points(cpos - _LIGHT_DIR * cr * 0.30,
					Vector2(cr * 0.5, cr * 0.5 * sq), 12), data.pts)},
		]
		var arcs: Array[Dictionary] = [
			{"color": Color(0.941, 0.918, 0.863, 0.35),
				"lines": _clip_line(DrawKit.ellipse_points(cpos, Vector2(cr, cr * sq), 12, PI * 0.85, PI * 1.75), data.pts)},
			{"color": Color(0, 0, 0, 0.4),
				"lines": _clip_line(DrawKit.ellipse_points(cpos, Vector2(cr, cr * sq), 12, PI * -0.15, PI * 0.75), data.pts)},
		]
		data.craters.append({"fills": fills, "arcs": arcs})

## Regolith speckle, boulders, and dead-pass warm flecks — point-filtered inside.
static func _build_specks(data: RockData, center: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	for i in 90:
		var gpos := center + Vector2((rng.randf() - 0.5), (rng.randf() - 0.5)) * r * 1.8
		var is_boulder := rng.randf() > 0.8
		var coin := rng.randf() > 0.5
		if not Geometry2D.is_point_in_polygon(gpos, data.pts):
			continue
		var shadow_ok := Geometry2D.is_point_in_polygon(gpos - _LIGHT_DIR * 1.6, data.pts)
		data.regolith.append({"pos": gpos, "is_boulder": is_boulder, "coin": coin, "shadow_ok": shadow_ok})
	for i in 15:
		var fpos := center + Vector2((rng.randf() - 0.5), (rng.randf() - 0.5)) * r * 1.8
		if not Geometry2D.is_point_in_polygon(fpos, data.pts):
			continue
		data.flecks.append({"pos": fpos, "dark": rng.randf() > 0.5})

## Dead-frequency stepped shading + rim-lit craters, clipped to the silhouette.
static func _build_dead_shading(data: RockData, center: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var d := data.dead_dir
	var steps := [
		[0.16, Color(0.094, 0.047, 0.031)],
		[0.38, Color(0.227, 0.110, 0.078)],
	]
	for step in steps:
		var offset: Vector2 = d * r * float(step[0])
		data.dead_steps.append({
			"color": step[1],
			"polys": _clip_poly(DrawKit.poly_offset(data.pts, offset), data.pts),
		})
	for i in 2:
		var cpos := center + d * r * (0.25 + 0.35 * float(i)) \
			+ Vector2((rng.randf() - 0.5), (rng.randf() - 0.5)) * r * 0.3
		var cr := r * (0.09 + rng.randf() * 0.12)
		data.dead_craters.append({
			"fill_polys": _clip_poly(DrawKit.ellipse_points(cpos, Vector2(cr, cr * 0.8), 12), data.pts),
			"arc_lines": _clip_line(DrawKit.ellipse_points(cpos, Vector2(cr, cr * 0.8), 10, PI * 0.9, PI * 1.8), data.pts),
		})

## Draws one rock: sunlit stepped-shading SURVEY crossfaded to ember-rim DEAD by blend.
static func draw(ci: CanvasItem, data: RockData, center: Vector2) -> void:
	var blend := VisualState.blend()
	_draw_survey(ci, data, center, 1.0 - blend)
	_draw_dead(ci, data, center, blend)
	var outline := Color(0.0, 0.0, 0.012, 0.55).lerp(Color(0.0, 0.0, 0.008, 0.5), blend)
	ci.draw_polyline(_closed(data.pts), outline, 1.3)

## SURVEY pass — sunlit stepped form shading, craters, regolith, hard terminator.
static func _draw_survey(ci: CanvasItem, data: RockData, center: Vector2, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var a := alpha
	ci.draw_colored_polygon(data.pts, Color(0.051, 0.043, 0.035, a))
	for step in data.ramp_steps:
		_fill(ci, step["polys"], step["color"], a)
	for m in data.mottles:
		_fill(ci, m["polys"], m["color"], a)
	for c in data.craters:
		for f in c["fills"]:
			_fill(ci, f["polys"], f["color"], a)
		for arc in c["arcs"]:
			_stroke(ci, arc["lines"], arc["color"], a, 1.0)
	for g in data.regolith:
		var gpos: Vector2 = g["pos"]
		if g["is_boulder"]:
			ci.draw_rect(Rect2(gpos, Vector2(1.2, 1.2)), Color(0.886, 0.863, 0.808, 0.35 * a))
			if g["shadow_ok"]:
				ci.draw_rect(Rect2(gpos - _LIGHT_DIR * 1.6, Vector2(1.6, 1.2)), Color(0, 0, 0, 0.45 * a))
		else:
			var col: Color = Color(0, 0, 0, 0.22 * a) if g["coin"] else Color(1.0, 0.973, 0.910, 0.10 * a)
			ci.draw_rect(Rect2(gpos, Vector2(1.1, 1.1)), col)
	for band in data.terminator:
		ci.draw_colored_polygon(band["poly"], Color(0.008, 0.008, 0.016, band["alpha"] * a))
	DrawKit.lit_limb(ci, data.pts, center, data.radius, _LIGHT_DIR,
		Color(1.0, 0.980, 0.933, 0.5 * a), 1.1, 0.35)

## DEAD pass — near-black body, red halo, warm flecks, ember rim.
static func _draw_dead(ci: CanvasItem, data: RockData, center: Vector2, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var a := alpha
	var d := data.dead_dir
	# Halo intentionally spills past the rim — it's the ember star's light.
	DrawKit.glow(ci, center + d * data.radius * 0.9, data.radius * 1.3,
		Color(1.0, 0.165, 0.114, 0.06 * a), 4)
	ci.draw_colored_polygon(data.pts, Color(0.024, 0.012, 0.008, a))
	for step in data.dead_steps:
		_fill(ci, step["polys"], step["color"], a)
	for f in data.flecks:
		var col: Color = Color(0, 0, 0, 0.3 * a) if f["dark"] else Color(1.0, 0.47, 0.35, 0.05 * a)
		ci.draw_rect(Rect2(f["pos"], Vector2(1.3, 1.3)), col)
	for c in data.dead_craters:
		_fill(ci, c["fill_polys"], Color(0, 0, 0, 0.5), a)
		_stroke(ci, c["arc_lines"], Color(1.0, 0.314, 0.196, 0.13), a, 1.0)
	DrawKit.lit_limb(ci, data.pts, center, data.radius, d,
		Color(1.0, 0.275, 0.176, 0.6 * a), 1.4, 0.25)

# ─── Geometry helpers ────────────────────────────────────────────────────────

## One shadow half-plane band starting `start_frac`·r toward the light, clipped.
static func _terminator_band(silhouette: PackedVector2Array, center: Vector2,
		r: float, start_frac: float) -> Array[PackedVector2Array]:
	var away := -_LIGHT_DIR.normalized()
	var perp := Vector2(-away.y, away.x)
	var half := r * 1.6
	var start := center + _LIGHT_DIR.normalized() * r * start_frac
	var quad := PackedVector2Array([
		start + perp * half, start - perp * half,
		start - perp * half + away * half * 2.5, start + perp * half + away * half * 2.5,
	])
	return _clip_poly(quad, silhouette)

## Intersect a polygon with the silhouette; empty result if fully outside.
static func _clip_poly(poly: PackedVector2Array, silhouette: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for p in Geometry2D.intersect_polygons(poly, silhouette):
		if p.size() >= 3:
			out.append(p)
	return out

## Clip a polyline (arc) to inside the silhouette.
static func _clip_line(line: PackedVector2Array, silhouette: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for l in Geometry2D.intersect_polyline_with_polygon(line, silhouette):
		if l.size() >= 2:
			out.append(l)
	return out

static func _fill(ci: CanvasItem, polys: Variant, color: Color, alpha: float) -> void:
	for p: PackedVector2Array in polys:
		ci.draw_colored_polygon(p, Color(color.r, color.g, color.b, color.a * alpha))

static func _stroke(ci: CanvasItem, lines: Variant, color: Color, alpha: float, width: float) -> void:
	for l: PackedVector2Array in lines:
		ci.draw_polyline(l, Color(color.r, color.g, color.b, color.a * alpha), width)

static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
