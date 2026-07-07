## DerelictShipRenderer — wrecked survey-probe hulk draw pass (TURN 4 polish).
## The hazard reads as a dead sibling of the player's SP-7: elongated hull with
## the SP-7 5-stop metal ramp, a snapped solar-wing stub, a torn-open end, panel
## seams + rivets, scorch streaks, a bent whip antenna, and one ember window.
## Key light is fixed upper-left (no rotation — lighting is baked into the hulk).
class_name DerelictShipRenderer
extends Object

const LIGHT_DIR := Vector2(-0.66, -0.75)

## SP-7 hull ramp stops, dark -> light -> dark across the fuselage (SURVEY).
const RAMP_SURVEY := [
	Color("2E333B"), Color("AEB7C2"), Color("F4F7FA"), Color("7E8894"), Color("232830"),
]
## Same ramp, scorched cold (DEAD).
const RAMP_DEAD := [
	Color("101216"), Color("343A42"), Color("4E565F"), Color("242930"), Color("0A0C10"),
]
const CELL_HI_SURVEY := Color("1B3B73")
const CELL_LO_SURVEY := Color("0C1F42")
const CELL_HI_DEAD := Color("0E141C")
const CELL_LO_DEAD := Color("070B10")
const RIVET_SURVEY := Color(0.671, 0.694, 0.733)
const RIVET_DEAD := Color(0.176, 0.192, 0.212)
const RIM_DEAD := Color(1.0, 0.165, 0.114)
const EMBER := Color(1.0, 0.275, 0.176)

## Precomputed per-instance seeded detail — build once in _ready, never in _draw.
class HulkData:
	var hull_pts: PackedVector2Array = PackedVector2Array()
	var ramp_bands: Array[PackedVector2Array] = []   # 5 hull-ramp fill bands
	var seam_fracs: Array[float] = [0.16, 0.30, 0.46, 0.60, 0.78]
	var rivets: Array[Vector2] = []                  # seam rivet specks
	var cell_grid: Array[bool] = []                  # wing stub 2x2/3 hi/lo pattern
	var torn_pts: PackedVector2Array = PackedVector2Array()
	var torn_flecks: Array[Vector2] = []
	var scorch_lines: Array[PackedVector2Array] = []
	var antenna_pts: PackedVector2Array = PackedVector2Array()
	var window_pos: Vector2 = Vector2(4.0, 1.0)

## Builds seeded hulk geometry — call once from DerelictShip._ready().
static func build(seed_value: int) -> HulkData:
	var data := HulkData.new()
	var rng := DrawKit.rng(seed_value)

	# Elongated broken fuselage — long axis roughly horizontal, nose-to-stern silhouette.
	data.hull_pts = PackedVector2Array([
		Vector2(-15, -6), Vector2(-4, -8), Vector2(9, -6), Vector2(14, -2),
		Vector2(13, 4), Vector2(6, 7), Vector2(-6, 6), Vector2(-13, 3),
	])

	# 5-stop hull ramp bands as thin vertical slabs across the fuselage rect.
	var min_x := -15.0
	var max_x := 14.0
	var span := max_x - min_x
	var prev_x := min_x
	for i in 5:
		var next_x: float = min_x + span * (float(i + 1) / 5.0)
		data.ramp_bands.append(PackedVector2Array([
			Vector2(prev_x, -9), Vector2(next_x, -9),
			Vector2(next_x, 8), Vector2(prev_x, 8),
		]))
		prev_x = next_x

	# Panel seam rivets — 4-6 per seam fraction, seeded.
	for frac in data.seam_fracs:
		var seam_x: float = min_x + span * frac
		var rivet_n := rng.randi_range(4, 6)
		for i in rivet_n:
			var ry: float = rng.randf_range(-7.5, 6.5)
			data.rivets.append(Vector2(seam_x + rng.randf_range(-0.6, 0.6), ry))

	# Snapped solar-wing stub: 2x2 dark cell grid, seeded hi/lo.
	for i in 6:
		data.cell_grid.append(rng.randf() > 0.5)

	# Torn-open end — irregular dark polygon at the stern with ripped-metal flecks.
	var torn_base := Vector2(11, 1)
	var torn_n := 7
	var tpts := PackedVector2Array()
	for i in torn_n:
		var a: float = float(i) / float(torn_n) * TAU
		var rr: float = 3.2 + rng.randf_range(-0.8, 1.1)
		tpts.append(torn_base + Vector2(cos(a) * rr * 0.85, sin(a) * rr))
	data.torn_pts = tpts
	var fleck_n := rng.randi_range(2, 3)
	for i in fleck_n:
		var fa: float = rng.randf() * TAU
		data.torn_flecks.append(torn_base + Vector2(cos(fa), sin(fa)) * rng.randf_range(2.0, 3.6))

	# Directional scorch streaks running down the hull (seeded start x + length).
	var streak_n := rng.randi_range(6, 8)
	for i in streak_n:
		var sx: float = rng.randf_range(-12.0, 10.0)
		var sy0: float = rng.randf_range(-7.0, -1.0)
		var len_v: float = rng.randf_range(4.0, 9.0)
		var drift: float = rng.randf_range(-1.0, 1.5)
		data.scorch_lines.append(PackedVector2Array([
			Vector2(sx, sy0), Vector2(sx + drift, sy0 + len_v),
		]))

	# Bent whip antenna — two-segment line kinked partway, seeded bend.
	var bend: float = rng.randf_range(-3.0, 3.0)
	data.antenna_pts = PackedVector2Array([
		Vector2(-13, -5), Vector2(-18 + bend * 0.3, -2 + bend), Vector2(-22, 1 + bend * 0.6),
	])

	data.window_pos = Vector2(rng.randf_range(-2.0, 6.0), rng.randf_range(-3.0, 3.0))
	return data

## Draws the full hulk at local origin. `flash` = hit-flash white-out override.
static func draw(ci: CanvasItem, data: HulkData, flash: bool, wobble: float) -> void:
	var blend := VisualState.blend()

	if flash:
		ci.draw_colored_polygon(data.hull_pts, Color(1, 1, 1))
		return

	_draw_scorch_streaks(ci, data, blend)
	_draw_hull_ramp(ci, data, blend)
	_draw_wing_stub(ci, data, blend)
	_draw_torn_end(ci, data, blend)
	_draw_seams_and_rivets(ci, data, blend)
	_draw_rim_light(ci, data, blend)
	_draw_antenna(ci, data)
	_draw_ember_window(ci, data, blend, wobble)

## Base hull silhouette re-filled with the 5-stop SP-7 ramp (dark->light->dark).
static func _draw_hull_ramp(ci: CanvasItem, data: HulkData, blend: float) -> void:
	for i in 5:
		var col: Color = VisualState.col(RAMP_SURVEY[i], RAMP_DEAD[i])
		var clipped := _clip_to_hull(data.ramp_bands[i], data.hull_pts)
		for p in clipped:
			ci.draw_colored_polygon(p, col)
	ci.draw_polyline(_closed(data.hull_pts), Color(0, 0, 0, 0.5), 1.0)

## Snapped-off solar wing stub — dark backing + 2-3 dark cell squares, aft of the hull.
static func _draw_wing_stub(ci: CanvasItem, data: HulkData, blend: float) -> void:
	var stub_origin := Vector2(-13, -4)
	var backing := PackedVector2Array([
		stub_origin, stub_origin + Vector2(-7, -1),
		stub_origin + Vector2(-7, 6), stub_origin + Vector2(0, 7),
	])
	var back_col := VisualState.col(Color(0.10, 0.11, 0.13), Color(0.04, 0.04, 0.05))
	ci.draw_colored_polygon(backing, back_col)
	ci.draw_polyline(_closed(backing), Color(0, 0, 0, 0.5), 0.8)
	var cell_w := 2.0
	var cell_h := 2.2
	var idx := 0
	for row in 3:
		for col in 2:
			if idx >= data.cell_grid.size():
				break
			var cx: float = stub_origin.x - 6.2 + float(col) * (cell_w + 0.4)
			var cy: float = stub_origin.y + 0.2 + float(row) * (cell_h + 0.3)
			var hi: bool = data.cell_grid[idx]
			var cell_col := VisualState.col(
				CELL_HI_SURVEY if hi else CELL_LO_SURVEY,
				CELL_HI_DEAD if hi else CELL_LO_DEAD)
			ci.draw_rect(Rect2(cx, cy, cell_w, cell_h), cell_col)
			idx += 1
	# Snapped spar stub — a short broken strut line, cut off mid-air.
	ci.draw_line(stub_origin + Vector2(-2, 2), stub_origin + Vector2(-7, 3),
		VisualState.col(Color(0.5, 0.52, 0.56), Color(0.2, 0.21, 0.23)), 1.0)

## Jagged torn-open stern — dark irregular polygon + pale ripped-metal edge flecks.
static func _draw_torn_end(ci: CanvasItem, data: HulkData, blend: float) -> void:
	var dark := VisualState.col(Color(0.11, 0.10, 0.09), Color(0.03, 0.02, 0.016))
	ci.draw_colored_polygon(data.torn_pts, dark)
	ci.draw_polyline(_closed(data.torn_pts), Color(0, 0, 0, 0.6), 0.8)
	var fleck_col := VisualState.col(Color(0.85, 0.87, 0.90, 0.7), Color(0.5, 0.52, 0.55, 0.5))
	for fp in data.torn_flecks:
		ci.draw_rect(Rect2(fp.x - 0.5, fp.y - 0.5, 1.0, 1.0), fleck_col)

## Seam lines at each ramp fraction + rivet specks (bright above, dark below).
static func _draw_seams_and_rivets(ci: CanvasItem, data: HulkData, blend: float) -> void:
	var seam_col := Color(0, 0, 0, 0.30)
	var min_x := -15.0
	var span := 29.0
	for frac in data.seam_fracs:
		var sx: float = min_x + span * frac
		ci.draw_line(Vector2(sx, -8.5), Vector2(sx, 7.5), seam_col, 0.6)
	var rivet_col := VisualState.col(RIVET_SURVEY, RIVET_DEAD)
	for rp in data.rivets:
		if not Geometry2D.is_point_in_polygon(rp, data.hull_pts):
			continue
		ci.draw_circle(rp, 0.45, rivet_col)
		ci.draw_circle(rp + Vector2(0.3, 0.3), 0.28, Color(0, 0, 0, 0.4))

## Directional scorch streaks running down the hull — DEAD only, fades with blend.
static func _draw_scorch_streaks(ci: CanvasItem, data: HulkData, blend: float) -> void:
	if blend <= 0.01:
		return
	var col := Color(0.02, 0.01, 0.008, 0.35 * blend)
	for line in data.scorch_lines:
		ci.draw_polyline(line, col, 1.1)

## Faint red rim light on the sun-facing edge (DEAD only — "dead frequency" tell).
static func _draw_rim_light(ci: CanvasItem, data: HulkData, blend: float) -> void:
	if blend <= 0.01:
		return
	DrawKit.lit_limb(ci, data.hull_pts, Vector2(-1, -1), 14.0, LIGHT_DIR,
		Color(RIM_DEAD.r, RIM_DEAD.g, RIM_DEAD.b, 0.45 * blend), 1.0, 0.25)

## Bent whip antenna line — snapped and drooping, not a clean straight rod.
static func _draw_antenna(ci: CanvasItem, data: HulkData) -> void:
	var col := VisualState.col(Color(0.6, 0.62, 0.66), Color(0.22, 0.23, 0.25))
	ci.draw_polyline(data.antenna_pts, col, 0.8)
	ci.draw_circle(data.antenna_pts[data.antenna_pts.size() - 1], 0.5, col)

## The one ember window — this grave's only sign of warmth, subtle pulse in DEAD.
static func _draw_ember_window(ci: CanvasItem, data: HulkData, blend: float, wobble: float) -> void:
	if blend <= 0.01:
		return
	var window_a: float = (0.30 + 0.18 * absf(sin(wobble * 1.8))) * blend
	DrawKit.glow(ci, data.window_pos, 2.0, Color(EMBER.r, EMBER.g, EMBER.b, window_a), 3)
	ci.draw_circle(data.window_pos, 0.55, Color(1.0, 0.5, 0.35, blend * 0.9))

# ─── Geometry helpers ────────────────────────────────────────────────────────

static func _clip_to_hull(rect_poly: PackedVector2Array, hull: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for p in Geometry2D.intersect_polygons(rect_poly, hull):
		if p.size() >= 3:
			out.append(p)
	return out

static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
