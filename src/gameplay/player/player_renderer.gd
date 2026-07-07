## PlayerRenderer — SP-7 survey probe draw pass (TURN 4 "probe4" recipe).
## One geometry, every color crossfaded SURVEY -> DEAD FREQUENCY via VisualState.
## Extracted from player.gd to respect the 300-line budget (art-bible.md Turn 4).
class_name PlayerRenderer
extends Object

const HULL_HALF_W := 3.4      # main bus half-width, px
const HULL_TOP_Y := -12.0     # nose tip
const HULL_BOT_Y := 7.0       # tail / engine mount
const WING_INNER_X := 3.4
const WING_OUTER_X := 10.0
const WING_TOP_Y := -6.0
const WING_BOT_Y := 8.0
const CELL_COLS := 3
const CELL_ROWS := 4

## Everything the draw pass needs for one frame — built fresh in player.gd's _draw().
class DrawState:
	var tilt: float = 0.0
	var bank_abs: float = 0.0
	var t: float = 0.0                 # engine animation phase
	var flash: bool = false
	var is_boosting: bool = false
	var hull_pct: float = 1.0
	var shield: int = 0
	var muzzle_flash_timer: float = 0.0
	var graze_flash_timer: float = 0.0
	var cell_pattern: Array[bool] = []      # seeded solar cell hi/lo, left+right wings
	var kapton_wrinkles: Array[Vector4] = []  # x0,y0,x1,y1 in unit band space
	var canopy_specks: Array[Vector2] = []  # unit-space offsets within canopy box

## Draws the full SP-7 probe at local origin (nose at -Y), crossfaded by VisualState.blend().
static func draw(ci: CanvasItem, ds: DrawState) -> void:
	var blend := VisualState.blend()
	_draw_engine_plume(ci, ds, blend)
	_draw_wing_shadow(ci, ds)
	_draw_whip_antenna(ci, ds)
	_draw_solar_wings(ci, ds, blend)
	_draw_dish(ci, ds)
	_draw_main_bus(ci, ds, blend)
	_draw_kapton_band(ci, ds, blend)
	_draw_radiator(ci, ds)
	_draw_hazard_chevrons(ci, ds)
	_draw_rcs_quads(ci, ds)
	_draw_canopy(ci, ds, blend)
	_draw_beacon(ci, ds, blend)
	_draw_engine_bell(ci, ds)
	_draw_low_hull_bleed(ci, ds)
	_draw_muzzle_flash(ci, ds)
	_draw_graze_ring(ci, ds)
	_draw_shield(ci, ds)

## Engine exhaust plume — shock diamonds (SURVEY) crossfading to a cold pilot glow (DEAD).
static func _draw_engine_plume(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	var t := ds.t
	var flame_len := 4.0 + sin(t * 1.3) * 1.5
	var flame_width := 2.0 + sin(t) * 0.5
	if ds.is_boosting:
		flame_len *= 2.5
		flame_width *= 1.6
	var plume_alpha := 1.0 - blend   # DEAD: plume dies entirely

	if plume_alpha > 0.01:
		var outer_flame := PackedVector2Array([
			Vector2(-flame_width, 7), Vector2(flame_width, 7),
			Vector2(sin(t * 2.7) * 0.8, 7 + flame_len + 2.0),
		])
		ci.draw_colored_polygon(outer_flame,
			Color(1.0, 0.3, 0.05, (0.6 + sin(t) * 0.2) * plume_alpha))

		var inner_flame := PackedVector2Array([
			Vector2(-flame_width * 0.5, 7), Vector2(flame_width * 0.5, 7),
			Vector2(sin(t * 3.1) * 0.4, 7 + flame_len * 0.7),
		])
		ci.draw_colored_polygon(inner_flame,
			Color(1.0, 0.85, 0.5, (0.8 + sin(t * 1.5) * 0.2) * plume_alpha))

		var spark_count := (3 if not ds.is_boosting else 6)
		for i in spark_count:
			var fi := float(i)
			var spark_y := 9.0 + fi * 2.5 + sin(t * (3.0 + fi)) * 1.5
			var spark_x := sin(t * (2.0 + fi * 1.7)) * (1.5 + fi * 0.5)
			var spark_alpha := clampf(0.7 - fi * 0.15, 0.1, 0.8)
			var spark_size := clampf(0.8 - fi * 0.1, 0.3, 1.0)
			if ds.is_boosting:
				spark_y += fi * 1.5
				spark_alpha = clampf(spark_alpha + 0.1, 0.0, 0.9)
			ci.draw_circle(Vector2(spark_x, spark_y), spark_size,
				Color(1.0, 0.6 + fi * 0.08, 0.2, spark_alpha * plume_alpha))

		# Shock diamonds — three bright rhombi, falling alpha, 8fps flicker.
		var flicker := 1.0 + 0.12 * sin(floor(t * 8.0))
		var diamonds := [[7.0, 0.8], [13.0, 0.55], [19.0, 0.32]]
		for d in diamonds:
			var oy: float = d[0] * flicker
			var a: float = d[1]
			var dw := 2.2
			var pts := PackedVector2Array([
				Vector2(-dw, 7 + oy), Vector2(0, 7 + oy + 2.4),
				Vector2(dw, 7 + oy), Vector2(0, 7 + oy - 2.4),
			])
			ci.draw_colored_polygon(pts, Color(0.92, 0.97, 1.0, a * plume_alpha))

		var glow_size := (3.0 + sin(t) * 0.8) * (1.8 if ds.is_boosting else 1.0)
		DrawKit.glow(ci, Vector2(0, 11), glow_size * 1.6,
			Color(0.75, 0.88, 1.0, 0.5 * plume_alpha), 3)

	# DEAD: only a faint amber pilot glow remains at the bell.
	if blend > 0.01:
		DrawKit.glow(ci, Vector2(0, 8), 3.0, Color(1.0, 0.47, 0.24, 0.30 * blend), 3)

## Banking wing shadow — a soft dark wedge on the leeward wing.
static func _draw_wing_shadow(ci: CanvasItem, ds: DrawState) -> void:
	if ds.bank_abs <= 0.1:
		return
	var shadow_alpha := ds.bank_abs * 0.25
	var shadow_col := Color(0.0, 0.0, 0.1, shadow_alpha)
	if ds.tilt < 0.0:
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(3, 3), Vector2(9, 8), Vector2(5, 8), Vector2(3, 5),
		]), shadow_col)
	else:
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(-3, 3), Vector2(-9, 8), Vector2(-5, 8), Vector2(-3, 5),
		]), shadow_col)

## Whip antenna trailing off the nose-left, tipped with a small dot.
static func _draw_whip_antenna(ci: CanvasItem, ds: DrawState) -> void:
	var line_col := VisualState.col(Color("7E8894"), Color("343A42"))
	var tip := Vector2(-6.5, HULL_TOP_Y - 4.5)
	ci.draw_line(Vector2(-2.5, HULL_TOP_Y + 3.0), tip, line_col, 0.8)
	var dot_col := VisualState.col(Color("EAF2FA"), Color("4E565F"))
	ci.draw_circle(tip, 0.6, dot_col)

## Both solar wings — cell grid, bus lines, sweeping sun glint (SURVEY only), spars.
static func _draw_solar_wings(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	var spar_col := VisualState.col(Color("7E8894"), Color("343A42"))
	var backing_col := VisualState.col(Color("0A0D12"), Color("07090C"))
	var hi_col := VisualState.col(Color("1B3B73"), Color("0E141C"))
	var lo_col := VisualState.col(Color("0C1F42"), Color("070B10"))
	var bus_col := VisualState.col(Color(0.91, 0.73, 0.29, 0.55), Color(0.47, 0.51, 0.56, 0.35))

	for side in [-1, 1]:
		var ax := (WING_INNER_X if side > 0 else -WING_OUTER_X)
		var pw := WING_OUTER_X - WING_INNER_X
		var ph := WING_BOT_Y - WING_TOP_Y
		var hull_x := (HULL_HALF_W if side > 0 else -HULL_HALF_W)

		# Spars — two thin lines from hull to wingtip, plus a diagonal brace.
		ci.draw_line(Vector2(hull_x, -1.5), Vector2(ax + (pw if side < 0 else 0.0), -1.5), spar_col, 0.8)
		ci.draw_line(Vector2(hull_x, 3.0), Vector2(ax + (pw if side < 0 else 0.0), 3.0), spar_col, 0.8)

		# Backing panel.
		var wing_rect := Rect2(Vector2(ax, WING_TOP_Y), Vector2(pw, ph))
		ci.draw_rect(wing_rect.grow(0.4), backing_col)

		# Cell grid (seeded, precomputed — no randf in _draw).
		var cw := pw / float(CELL_COLS)
		var ch := ph / float(CELL_ROWS)
		var wing_idx := 0 if side < 0 else 1
		for ci_col in CELL_COLS:
			for ri in CELL_ROWS:
				var idx := wing_idx * CELL_COLS * CELL_ROWS + ci_col * CELL_ROWS + ri
				var hi := ds.cell_pattern[idx] if idx < ds.cell_pattern.size() else true
				var cell_col := hi_col if hi else lo_col
				ci.draw_rect(Rect2(ax + ci_col * cw + 0.15, WING_TOP_Y + ri * ch + 0.15,
					cw - 0.3, ch - 0.3), cell_col)

		# Gold bus lines every 2nd column.
		var col_i := 2
		while col_i < CELL_COLS:
			var lx := ax + col_i * cw
			ci.draw_line(Vector2(lx, WING_TOP_Y), Vector2(lx, WING_TOP_Y + ph), bus_col, 0.6)
			col_i += 2

		# SURVEY: sweeping sun glint on the right wing, static sheen on the left.
		if side > 0:
			var phase := fmod(ds.t * 0.024, 1.0)  # ~0.15 Hz sweep independent of engine phase
			var band_x := ax + pw * (phase * 1.6 - 0.3)
			var glint_a := (1.0 - blend) * 0.5
			if glint_a > 0.01:
				var band := PackedVector2Array([
					Vector2(band_x, WING_TOP_Y), Vector2(band_x + pw * 0.18, WING_TOP_Y),
					Vector2(band_x + pw * 0.08, WING_TOP_Y + ph), Vector2(band_x - pw * 0.1, WING_TOP_Y + ph),
				])
				ci.draw_colored_polygon(band, Color(0.86, 0.94, 1.0, glint_a))
		else:
			var sheen_a := (1.0 - blend) * 0.07
			if sheen_a > 0.01:
				var sheen := PackedVector2Array([
					Vector2(ax, WING_TOP_Y), Vector2(ax + pw * 0.45, WING_TOP_Y),
					Vector2(ax + pw * 0.15, WING_TOP_Y + ph), Vector2(ax, WING_TOP_Y + ph),
				])
				ci.draw_colored_polygon(sheen, Color(0.78, 0.9, 1.0, sheen_a))

## High-gain dish on a strut, up-right of the hull. Same geometry both states, just darkens.
static func _draw_dish(ci: CanvasItem, ds: DrawState) -> void:
	var dxx := HULL_HALF_W + 6.5
	var dyy := HULL_TOP_Y + 3.0
	var strut_col := VisualState.col(Color("7E8894"), Color("343A42"))
	ci.draw_line(Vector2(HULL_HALF_W + 1.0, HULL_TOP_Y + 6.0), Vector2(dxx - 0.8, dyy + 1.2), strut_col, 0.8)

	var white := VisualState.col(Color("F4F7FA"), Color("101216"))
	var gray := VisualState.col(Color("AEB7C2"), Color("343A42"))
	var dark := VisualState.col(Color("232830"), Color("0A0C10"))
	var radii := Vector2(2.6, 1.7)
	# Radial ramp faked with 3 stacked ellipses, brightest first.
	DrawKit.ellipse(ci, Vector2(dxx, dyy), radii, white.lerp(dark, 0.15))
	DrawKit.ellipse(ci, Vector2(dxx, dyy) + Vector2(0.3, 0.2), radii * 0.66, gray.lerp(dark, 0.2))
	DrawKit.ellipse(ci, Vector2(dxx, dyy) + Vector2(0.5, 0.35), radii * 0.33, dark)

	var ring_col := Color(0.0, 0.0, 0.03, 0.45)
	for f in [1.0, 0.66, 0.33]:
		ci.draw_polyline(DrawKit.ellipse_points(Vector2(dxx, dyy), radii * f, 16), ring_col, 0.5)
	for i in 5:
		var a := float(i) / 5.0 * TAU
		ci.draw_line(Vector2(dxx, dyy), Vector2(dxx, dyy) + Vector2(cos(a), sin(a)) * radii * 0.95, ring_col, 0.4)

	ci.draw_circle(Vector2(dxx + 0.6, dyy - 0.9), 0.45, strut_col)
	ci.draw_line(Vector2(dxx - 0.9, dyy + 0.6), Vector2(dxx + 0.6, dyy - 0.9), strut_col, 0.5)
	ci.draw_line(Vector2(dxx + 1.8, dyy + 0.3), Vector2(dxx + 0.6, dyy - 0.9), strut_col, 0.5)

## Main fuselage capsule — 5-stop hull ramp, panel seams + rivets, ID stripe, cylinder AO.
static func _draw_main_bus(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	var bw := HULL_HALF_W * 2.0
	var bh := HULL_BOT_Y - HULL_TOP_Y
	var bx := -HULL_HALF_W
	var by := HULL_TOP_Y

	if ds.flash:
		var fuselage := PackedVector2Array([
			Vector2(bx, by + 1.5), Vector2(bx + bw * 0.5, by), Vector2(bx + bw, by + 1.5),
			Vector2(bx + bw, by + bh), Vector2(bx, by + bh),
		])
		ci.draw_colored_polygon(fuselage, Color(1.0, 1.0, 1.0))
		return

	var ramp := [Color("2E333B"), Color("AEB7C2"), Color("F4F7FA"), Color("7E8894"), Color("232830")]
	var dead_ramp := [Color("101216"), Color("343A42"), Color("4E565F"), Color("242930"), Color("0A0C10")]
	var stops := [0.0, 0.3, 0.5, 0.7, 1.0]

	# Hull silhouette — rounded capsule polygon.
	var fuselage := PackedVector2Array([
		Vector2(bx + bw * 0.5, by), Vector2(bx + bw, by + bh * 0.12),
		Vector2(bx + bw, by + bh), Vector2(bx, by + bh),
		Vector2(bx, by + bh * 0.12),
	])
	ci.draw_colored_polygon(fuselage, VisualState.col(ramp[2], dead_ramp[2]))

	# Horizontal hull ramp via vertical strips (hgrad, clipped to silhouette by strip count).
	for i in 10:
		var t01 := float(i) / 9.0
		var seg_col := _ramp_lerp(ramp, stops, t01).lerp(_ramp_lerp(dead_ramp, stops, t01), blend)
		var strip_x := bx + bw * t01
		var strip_w := bw / 9.0 + 0.4
		ci.draw_rect(Rect2(strip_x, by + bh * 0.1, strip_w, bh * 0.9), seg_col)

	# Panel-tone bands + seams + rivets.
	var seams := [0.16, 0.30, 0.46, 0.60, 0.78]
	var prev := 0.0
	var all_stops := seams + [1.0]
	for i in all_stops.size():
		var f: float = all_stops[i]
		var tone := Color(1, 1, 1, 0.035) if i % 2 == 1 else Color(0, 0, 0.04, 0.05)
		ci.draw_rect(Rect2(bx, by + bh * prev, bw, bh * (f - prev)), tone)
		prev = f
	for f: float in seams:
		var yy := by + bh * f
		ci.draw_line(Vector2(bx, yy), Vector2(bx + bw, yy), Color(0.06, 0.08, 0.1, 0.55), 0.5)
		for i in 5:
			var rx := bx + 0.3 + i * (bw - 0.6) / 4.0
			ci.draw_rect(Rect2(rx, yy - 0.9, 0.5, 0.3), Color(1, 1, 1, 0.25))
			ci.draw_rect(Rect2(rx, yy - 0.65, 0.5, 0.5), Color(0.05, 0.06, 0.08, 0.6))

	# ID stripe near the nose.
	var stripe_col := VisualState.col(Color(0.0, 0.835, 1.0, 0.75), Color(0.47, 0.51, 0.56, 0.35))
	ci.draw_rect(Rect2(bx, by + bh * 0.13, bw, 0.7), stripe_col)

	# Wing-attach AO band.
	var ao := Color(0, 0, 0.03, 0.28)
	ci.draw_rect(Rect2(bx, -1.2, bw, 2.4), ao)

	# Cylinder AO — right-edge darkening.
	ci.draw_rect(Rect2(bx + bw * 0.72, by, bw * 0.28, bh), Color(0, 0, 0.04, 0.22))

	_draw_damage_overlay(ci, ds, blend, bx, by, bw, bh)

## Interpolates a 5-stop color ramp at parameter t (0..1).
static func _ramp_lerp(ramp: Array, stops: Array, t: float) -> Color:
	for i in range(stops.size() - 1):
		var a: float = stops[i]
		var b: float = stops[i + 1]
		if t >= a and t <= b:
			var local_t := (t - a) / maxf(b - a, 0.0001)
			return (ramp[i] as Color).lerp(ramp[i + 1] as Color, local_t)
	return ramp[ramp.size() - 1]

## DEAD-only damage overlay — torn panel, amber wire, scorch streaks, paint chips. Fades in with blend.
static func _draw_damage_overlay(ci: CanvasItem, ds: DrawState, blend: float, bx: float, by: float, bw: float, bh: float) -> void:
	if blend <= 0.01:
		return
	var hx := 1.0
	var hy := by + bh * 0.32

	var torn := PackedVector2Array([
		Vector2(hx - 1.8, hy), Vector2(hx + 0.4, hy - 1.5), Vector2(hx + 2.1, hy - 0.4),
		Vector2(hx + 1.4, hy + 1.5), Vector2(hx - 0.7, hy + 1.8),
	])
	ci.draw_colored_polygon(torn, Color(0, 0, 0, 0.75 * blend))

	var flap := PackedVector2Array([
		Vector2(hx + 1.4, hy + 1.5), Vector2(hx + 2.6, hy + 2.1), Vector2(hx + 0.7, hy + 2.3),
	])
	ci.draw_colored_polygon(flap, Color(0.85, 0.87, 0.9, 0.28 * blend))

	var wire_col := Color("FFB264")
	DrawKit.glow(ci, Vector2(hx, hy + 0.4), 1.6, Color(wire_col.r, wire_col.g, wire_col.b, 0.5 * blend), 3)
	var wire_pts := PackedVector2Array([
		Vector2(hx - 1.0, hy + 0.3), Vector2(hx, hy + 1.0), Vector2(hx + 0.7, hy + 0.3),
	])
	ci.draw_polyline(wire_pts, Color(wire_col.r, wire_col.g, wire_col.b, blend), 0.6)
	ci.draw_circle(Vector2(hx - 0.4, hy + 0.6), 0.35, Color(wire_col.r, wire_col.g, wire_col.b, blend))

	# Scorch streaks running down the hull (seeded via kapton_wrinkles reused as generic jitter source).
	var streak_count := mini(ds.kapton_wrinkles.size(), 8)
	for i in streak_count:
		var w: Vector4 = ds.kapton_wrinkles[i]
		var sxx := bx + bw * 0.5 + w.x * bw * 0.5
		var syy := by + bh * 0.15 + absf(w.y) * bh * 0.5
		ci.draw_line(Vector2(sxx, syy), Vector2(sxx + w.z * 3.0, syy + 6.0 + absf(w.w) * 8.0),
			Color(0, 0, 0, 0.5 * blend), 0.9)

	for i in 6:
		var f := float(i) / 6.0
		ci.draw_rect(Rect2(bx + 0.3 + f * (bw - 0.6), by + 0.3 + fmod(f * 2.7, 1.0) * bh * 0.15, 0.5, 0.5),
			Color(0.89, 0.93, 0.97, 0.25 * blend))

## Kapton foil band — gradient + wrinkle strokes + SURVEY foil glint curve.
static func _draw_kapton_band(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	var bx := -HULL_HALF_W
	var bw := HULL_HALF_W * 2.0
	var band_y := 1.5
	var band_h := 4.5
	var top := VisualState.col(Color("E8BB4A"), Color("4A360C"))
	var bottom := VisualState.col(Color("6E5210"), Color("1A1204"))
	DrawKit.vgrad_rect(ci, Rect2(bx, band_y, bw, band_h), top, bottom, 4)

	for w in ds.kapton_wrinkles:
		var wv: Vector4 = w
		var wrinkle_col := Color(1.0, 0.9, 0.59, 0.30) if wv.z > 0.0 else Color(0.16, 0.1, 0.0, 0.38)
		wrinkle_col = wrinkle_col.lerp(Color(wrinkle_col.r, wrinkle_col.g, wrinkle_col.b, wrinkle_col.a * 0.5), blend)
		var y0 := band_y + (wv.y * 0.5 + 0.5) * band_h
		ci.draw_line(Vector2(bx + wv.x * bw * 0.5, y0), Vector2(bx + bw * 0.5 + wv.x * bw * 0.5, y0 + wv.w), wrinkle_col, 0.5)

	var glint_a := (1.0 - blend) * 0.55
	if glint_a > 0.01:
		var pts := PackedVector2Array()
		for i in 9:
			var t01 := float(i) / 8.0
			var yy := band_y + band_h * 0.5 + sin(t01 * PI) * 1.2
			pts.append(Vector2(bx + bw * t01, yy))
		ci.draw_polyline(pts, Color(1.0, 0.93, 0.75, glint_a), 0.6)

## Radiator strip — near-white panel with dark fin lines, above the kapton band.
static func _draw_radiator(ci: CanvasItem, ds: DrawState) -> void:
	var bx := -HULL_HALF_W + 0.3
	var bw := HULL_HALF_W * 2.0 - 0.6
	var y := -3.0
	var h := 2.0
	var rad_col := VisualState.col(Color(0.93, 0.96, 0.98, 0.9), Color(0.38, 0.42, 0.47, 0.5))
	ci.draw_rect(Rect2(bx, y, bw, h), rad_col)
	var fin_col := Color(0.12, 0.14, 0.17, 0.6)
	for i in 6:
		var fx := bx + i * bw / 5.0
		ci.draw_line(Vector2(fx, y), Vector2(fx, y + h), fin_col, 0.4)

## Hazard chevron band near the tail — alternating gold/dark diagonal parallelograms.
static func _draw_hazard_chevrons(ci: CanvasItem, ds: DrawState) -> void:
	var bx := -HULL_HALF_W
	var bw := HULL_HALF_W * 2.0
	var hz := HULL_BOT_Y - 2.5
	var hi := VisualState.col(Color("C9921E"), Color("4A3A14"))
	var lo := VisualState.col(Color("14161C"), Color("0C0E12"))
	for i in range(-1, 5):
		var col := lo if i % 2 == 0 else hi
		var x0 := bx + i * 1.6
		var pts := PackedVector2Array([
			Vector2(x0, hz), Vector2(x0 + 1.6, hz), Vector2(x0 + 0.5, hz + 1.6), Vector2(x0 - 1.1, hz + 1.6),
		])
		ci.draw_colored_polygon(pts, col)

## RCS thruster quads at the four hull/wing-root corners, with dark nozzle notches.
static func _draw_rcs_quads(ci: CanvasItem, ds: DrawState) -> void:
	var quad_col := VisualState.col(Color("7E8894"), Color("343A42"))
	var nozzle_col := VisualState.col(Color("0A0C10"), Color("07090C"))
	var offsets := [
		Vector2(-HULL_HALF_W - 0.8, -5.0), Vector2(HULL_HALF_W, -5.0),
		Vector2(-HULL_HALF_W - 0.8, 4.0), Vector2(HULL_HALF_W, 4.0),
	]
	for o in offsets:
		var ov: Vector2 = o
		ci.draw_rect(Rect2(ov, Vector2(0.8, 1.2)), quad_col)
		var nx := ov.x - 0.3 if ov.x < 0.0 else ov.x + 0.8
		ci.draw_rect(Rect2(Vector2(nx, ov.y + 0.4), Vector2(0.45, 0.5)), nozzle_col)

## Glass canopy — radial ramp, rim arc, star specks, SURVEY specular flare, DEAD frost stipple.
static func _draw_canopy(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	var cx := 0.0
	var cy := HULL_TOP_Y + 3.0
	var rx := 2.6
	var ry := 2.3
	if ds.flash:
		ci.draw_colored_polygon(DrawKit.ellipse_points(Vector2(cx, cy), Vector2(rx, ry), 16, PI, TAU),
			Color(1, 1, 1))
		return

	var top := VisualState.col(Color("EAF2FA"), Color("22262C"))
	var mid := VisualState.col(Color("9FB4C8"), Color("343A42"))  # note: DEAD dome ramp reuses hull mid-tone
	var dark := VisualState.col(Color("22303E"), Color("0A0C10"))
	var canopy_pts := DrawKit.ellipse_points(Vector2(cx, cy), Vector2(rx, ry), 16, PI, TAU)
	ci.draw_colored_polygon(canopy_pts, top.lerp(mid, 0.4))
	var inner_pts := DrawKit.ellipse_points(Vector2(cx, cy + 0.3), Vector2(rx * 0.6, ry * 0.6), 12, PI, TAU)
	ci.draw_colored_polygon(inner_pts, mid.lerp(dark, 0.5))

	var rim_col := Color(1, 1, 1, 0.30 * (1.0 - blend * 0.4))
	ci.draw_polyline(DrawKit.ellipse_points(Vector2(cx, cy), Vector2(rx, ry), 10, PI * 1.08, PI * 1.5), rim_col, 0.5)

	var speck_a := lerpf(0.4, 0.15, blend)
	for s in ds.canopy_specks:
		var sv: Vector2 = s
		ci.draw_rect(Rect2(cx + sv.x * rx, cy - ry * 0.6 + sv.y * ry * 0.6, 0.4, 0.4),
			Color(0.9, 0.95, 1.0, speck_a))

	if blend < 0.99:
		var flare_a := 1.0 - blend
		ci.draw_circle(Vector2(cx - 0.9, cy - 0.5), 0.5, Color(1, 1, 1, 0.95 * flare_a))
		var fx := cx - 0.9
		var fy := cy - 0.5
		ci.draw_line(Vector2(fx - 1.2, fy), Vector2(fx + 1.2, fy), Color(1, 1, 1, 0.5 * flare_a), 0.4)
		ci.draw_line(Vector2(fx, fy - 1.2), Vector2(fx, fy + 1.2), Color(1, 1, 1, 0.5 * flare_a), 0.4)

	# DEAD: frost stippling ring around the canopy edge.
	if blend > 0.01:
		for i in 10:
			var a := float(i) / 10.0 * PI + PI
			var fp := Vector2(cx + cos(a) * rx * 1.05, cy + sin(a) * ry * 1.05)
			ci.draw_rect(Rect2(fp, Vector2(0.4, 0.4)), Color(0.86, 0.92, 1.0, 0.14 * blend))

## Red nav beacon above the nose — DEAD only, pulsing glow + bright core dot.
static func _draw_beacon(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	if blend <= 0.01:
		return
	var pos := Vector2(0, HULL_TOP_Y - 1.0)
	var pulse := 0.6 + 0.4 * sin(ds.t * 1.6)
	DrawKit.glow(ci, pos, 3.2, Color(1.0, 0.165, 0.114, 0.55 * blend * pulse), 4)
	DrawKit.glow(ci, pos, 1.3, Color(1.0, 0.35, 0.24, 0.7 * blend * pulse), 3)
	ci.draw_circle(pos, 0.6, Color(1.0, 0.165, 0.114, blend))

## Engine bell — trapezoid vgrad + 2 faint ribs. Same geometry both lighting states.
static func _draw_engine_bell(ci: CanvasItem, ds: DrawState) -> void:
	var bell := PackedVector2Array([
		Vector2(-2.5, 5), Vector2(2.5, 5), Vector2(2, 7), Vector2(-2, 7),
	])
	if ds.flash:
		ci.draw_colored_polygon(bell, Color(1, 1, 1))
		return
	var top := Color("30353E")
	var bottom := Color("0C0E12")
	ci.draw_colored_polygon(bell, top.lerp(bottom, 0.5))
	var rib_col := Color(1, 1, 1, 0.10)
	ci.draw_line(Vector2(-2.2, 5.7), Vector2(2.2, 5.7), rib_col, 0.4)
	ci.draw_line(Vector2(-2.1, 6.4), Vector2(2.1, 6.4), rib_col, 0.4)

## Emergency cabin bleed — red glow under 40% hull, plus damage sparks when critical.
static func _draw_low_hull_bleed(ci: CanvasItem, ds: DrawState) -> void:
	if ds.hull_pct >= 0.4 or ds.flash:
		return
	var urgency := clampf((0.4 - ds.hull_pct) / 0.4, 0.0, 1.0)
	var blink := 0.5 + 0.5 * sin(ds.t * (2.0 + urgency * 4.0))
	ci.draw_circle(Vector2(0, -3), 4.5, Color(0.9, 0.08, 0.05, 0.10 + 0.22 * urgency * blink))
	if ds.hull_pct < 0.25 and fmod(ds.t, 0.9) < 0.12:
		var sx := sin(ds.t * 31.7) * 4.0
		ci.draw_circle(Vector2(sx, 1.0 + cos(ds.t * 17.3) * 3.0), 0.7, Color(1.0, 0.85, 0.4, 0.8))

## Muzzle flash — bright capacitor snap at the nose.
static func _draw_muzzle_flash(ci: CanvasItem, ds: DrawState) -> void:
	if ds.muzzle_flash_timer <= 0.0:
		return
	var ma := ds.muzzle_flash_timer / 0.05
	var pos := Vector2(ds.tilt * 0.5, HULL_TOP_Y - 1.5)
	ci.draw_circle(pos, 2.4, Color(1.0, 1.0, 0.95, ma * 0.85))
	ci.draw_circle(pos, 4.0, Color(0.6, 0.9, 1.0, ma * 0.3))

## Graze spark ring — a razor pass acknowledged.
static func _draw_graze_ring(ci: CanvasItem, ds: DrawState) -> void:
	if ds.graze_flash_timer <= 0.0:
		return
	var ga := ds.graze_flash_timer / 0.22
	var gr := 8.0 + (1.0 - ga) * 6.0
	ci.draw_arc(Vector2.ZERO, gr, 0, TAU, 20, Color(0.9, 0.95, 1.0, ga * 0.6), 1.0)

## Shield energy arc — ripple ring, main arc, inner glow, pulsing nodes. Tinted with pal("accent").
static func _draw_shield(ci: CanvasItem, ds: DrawState) -> void:
	if ds.shield <= 0 or ds.flash:
		return
	var shield_col := VisualState.pal("accent")
	var shield_strength := float(ds.shield) / 100.0
	var base_alpha := shield_strength * 0.3
	var t := ds.t

	var ripple_phase := fmod(t * 0.6, 1.0)
	var ripple_radius := 12.0 + ripple_phase * 4.0
	var ripple_alpha := base_alpha * (1.0 - ripple_phase) * 0.5
	if ripple_alpha > 0.01:
		ci.draw_arc(Vector2.ZERO, ripple_radius, -PI * 0.8, PI * 0.8, 24,
			Color(shield_col.r, shield_col.g, shield_col.b, ripple_alpha), 1.0)

	var arc_alpha := base_alpha + sin(t * 2.0) * 0.06
	ci.draw_arc(Vector2.ZERO, 13.0, -PI * 0.75, PI * 0.75, 28,
		Color(shield_col.r, shield_col.g, shield_col.b, arc_alpha), 1.5)
	ci.draw_arc(Vector2.ZERO, 11.0, -PI * 0.6, PI * 0.6, 20,
		Color(shield_col.r, shield_col.g, shield_col.b, arc_alpha * 0.4), 1.0)

	for i in range(5):
		var angle := -PI * 0.6 + (PI * 1.2) * (float(i) / 4.0)
		var node_pulse := sin(t * 3.0 + float(i) * 1.2) * 0.5 + 0.5
		var node_pos := Vector2(cos(angle), sin(angle)) * 13.0
		ci.draw_circle(node_pos, 0.8,
			Color(shield_col.r, shield_col.g, shield_col.b, base_alpha + node_pulse * 0.3))
