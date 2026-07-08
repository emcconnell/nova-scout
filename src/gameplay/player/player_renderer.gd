## PlayerRenderer — SP-7 procedural FX pass (art bible v4.0 "Textured Light").
## The hull/wings/dish body is a baked textured sprite (TextureKit.fade_body,
## assets/textures/player/sp7_*) lit by real 2D lights; this pass keeps only
## the living, emissive layers drawn above it: plume, beacon, shield, muzzle,
## graze ring, hull-bleed and the DEAD-state damage overlay.
class_name PlayerRenderer
extends Object

const HULL_HALF_W := 3.4      # main bus half-width, px (FX anchors)
const HULL_TOP_Y := -12.0     # nose tip
const HULL_BOT_Y := 7.0       # tail / engine mount

## Everything the FX pass needs for one frame — built fresh in player.gd's _draw().
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
	var kapton_wrinkles: Array[Vector4] = []  # seeded jitter for scorch streaks

## Draws the SP-7 FX layers at local origin, crossfaded by VisualState.blend().
static func draw(ci: CanvasItem, ds: DrawState) -> void:
	var blend := VisualState.blend()
	_draw_beam_shaft(ci)
	_draw_engine_plume(ci, ds, blend)
	_draw_wing_shadow(ci, ds)
	_draw_damage_overlay(ci, ds, blend)
	_draw_beacon(ci, ds, blend)
	_draw_low_hull_bleed(ci, ds)
	_draw_muzzle_flash(ci, ds)
	_draw_graze_ring(ci, ds)
	_draw_shield(ci, ds)

## v5.0 "Wet Black" — the flood cone as a visible volume: a faint warm shaft
## from the nose, nested wedges fading with reach so the beam reads over the
## black void even when nothing is inside it (the dust motes swim in it).
static func _draw_beam_shaft(ci: CanvasItem) -> void:
	var strength := VisualState.beam_strength()
	if strength <= 0.01:
		return
	var beam_range := float(VisualState.value("beam", "range", 130.0))
	var half := deg_to_rad(float(VisualState.value("beam", "half_angle_deg", 17.0)))
	var apex := Vector2(0, HULL_TOP_Y)
	var warm := Color(1.0, 0.93, 0.82)
	# Nested wedges with per-vertex alpha: bright at the apex, zero at the far
	# edge — the shaft dissolves into the murk instead of ending on a line.
	for w in [Vector2(0.38, 0.10), Vector2(0.72, 0.055), Vector2(1.0, 0.032)]:
		var spread: float = tan(half) * beam_range * w.x
		var reach: float = beam_range * (0.6 + 0.52 * w.x)
		var a: float = w.y * strength
		ci.draw_polygon(PackedVector2Array([
			apex + Vector2(-spread * 0.12, 0.0),
			apex + Vector2(spread * 0.12, 0.0),
			apex + Vector2(spread, -reach),
			apex + Vector2(-spread, -reach),
		]), PackedColorArray([
			Color(warm.r, warm.g, warm.b, a),
			Color(warm.r, warm.g, warm.b, a),
			Color(warm.r, warm.g, warm.b, 0.0),
			Color(warm.r, warm.g, warm.b, 0.0),
		]))

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

## DEAD-only damage overlay — torn panel, amber wire, scorch streaks, paint chips.
static func _draw_damage_overlay(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	if blend <= 0.01 or ds.flash:
		return
	var bx := -HULL_HALF_W
	var bw := HULL_HALF_W * 2.0
	var by := HULL_TOP_Y
	var bh := HULL_BOT_Y - HULL_TOP_Y
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

	# Scorch streaks running down the hull (seeded via kapton_wrinkles jitter).
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

## Red nav beacon above the nose — DEAD only, pulsing glow + bright core dot.
static func _draw_beacon(ci: CanvasItem, ds: DrawState, blend: float) -> void:
	if blend <= 0.01:
		return
	var pos := Vector2(0, HULL_TOP_Y - 1.0)
	var pulse := 0.6 + 0.4 * sin(ds.t * 1.6)
	DrawKit.glow(ci, pos, 3.2, Color(1.0, 0.165, 0.114, 0.55 * blend * pulse), 4)
	DrawKit.glow(ci, pos, 1.3, Color(1.0, 0.35, 0.24, 0.7 * blend * pulse), 3)
	ci.draw_circle(pos, 0.6, Color(1.0, 0.165, 0.114, blend))

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
