## SceneRenderer — TURN 4 shared background composition: milky-way dust lane,
## sun/anamorphic flare/lens ghosts (SURVEY) crossfading to ember star + derelict
## hulk (DEAD FREQUENCY). Shared by game_world.gd and main_menu.gd so the title
## screen and the flight scene read as the same universe.
## GDD Ref: art-bible.md (Turn 4) — Scene / starfield recipe.
class_name SceneRenderer
extends Object

const DUST_COLOR := Color(0.776, 0.824, 0.933, 0.045)
const DUST_BLOB_COLOR := Color(0.012, 0.016, 0.031, 0.6)
const AMBIENT_RED := Color(0.431, 0.071, 0.047, 0.045)
const EMBER_DISC := Color("170504")
const EMBER_LIMB := Color(1.0, 0.353, 0.196, 0.85)
const EMBER_HALO := Color(1.0, 0.275, 0.157, 0.5)
const EMBER_HALO_WIDE := Color(0.706, 0.118, 0.078, 0.11)

## Precomputed static seeded scene detail — build once (in _ready / _build_starfield),
## never regenerate inside _draw. `w`/`h` are the viewport size the recipe targets.
static func precompute(seed_value: int, w: float, h: float) -> Dictionary:
	var r := DrawKit.rng(seed_value)
	var detail: Dictionary = {}

	# Milky-way dust lane: diagonal band lower-left -> upper-right, ~14 soft glows.
	var dust_glows: Array[Vector3] = []   # x, y, radius
	for i in 14:
		var t := float(i) / 13.0
		dust_glows.append(Vector3(
			w * 0.08 + t * w * 0.875 + (r.randf() - 0.5) * w * 0.086,
			h * 0.917 - t * h * 0.806 + (r.randf() - 0.5) * h * 0.125,
			w * 0.031 + r.randf() * w * 0.047))
	detail["dust_glows"] = dust_glows

	# Dark dust blobs punched into the lane.
	var dust_blobs: Array[Vector3] = []
	for i in 10:
		var t := r.randf()
		dust_blobs.append(Vector3(
			w * 0.125 + t * w * 0.781,
			h * 0.875 - t * h * 0.736,
			w * 0.025 + r.randf() * w * 0.041))
	detail["dust_blobs"] = dust_blobs

	# Lens ghost chain — 5 stops spaced sun -> screen center: [t, radius, alpha, color].
	detail["ghost_chain"] = [
		{"t": 0.30, "r": 1.25, "a": 0.10, "col": Color(0.627, 0.804, 1.0)},
		{"t": 0.55, "r": 0.70, "a": 0.16, "col": Color(1.0, 0.784, 0.706)},
		{"t": 0.86, "r": 2.35, "a": 0.06, "col": Color(0.627, 0.804, 1.0)},
		{"t": 1.16, "r": 1.02, "a": 0.10, "col": Color(0.784, 1.0, 0.863)},
		{"t": 1.45, "r": 3.44, "a": 0.045, "col": Color(0.627, 0.804, 1.0)},
	]

	# 4-5 vast dark-red ambient glows (DEAD), scattered.
	var ambient_glows: Array[Vector3] = []
	for i in 9:
		ambient_glows.append(Vector3(r.randf() * w, r.randf() * h, w * 0.094 + r.randf() * w * 0.141))
	detail["ambient_glows"] = ambient_glows

	# Derelict hulk — jagged black silhouette, top-right, screen-space static.
	# Scaled from the concept sheet's 640x360 canvas (halved to our 320x180).
	var hulk_pts := PackedVector2Array([
		Vector2(190.0, 22.0), Vector2(280.0, 11.0), Vector2(304.0, 17.0),
		Vector2(300.0, 27.0), Vector2(260.0, 30.0), Vector2(254.0, 39.0),
		Vector2(235.0, 37.0), Vector2(226.0, 28.0), Vector2(198.0, 29.0),
	])
	detail["hulk_pts"] = hulk_pts
	detail["hulk_antenna"] = [
		[Vector2(226.0, 28.0), Vector2(210.0, 46.0)],
		[Vector2(280.0, 11.0), Vector2(292.0, 4.0)],
	]
	detail["hulk_lit_edge"] = PackedVector2Array([
		Vector2(198.0, 29.0), Vector2(226.0, 28.0), Vector2(235.0, 37.0),
	])
	detail["hulk_window"] = Vector2(270.0, 20.0)

	return detail

## Static seeded milky-way dust lane — drawn behind the parallax star field.
static func draw_dust_lane(ci: CanvasItem, detail: Dictionary) -> void:
	for g in (detail.get("dust_glows", []) as Array[Vector3]):
		DrawKit.glow(ci, Vector2(g.x, g.y), g.z, DUST_COLOR)
	for b in (detail.get("dust_blobs", []) as Array[Vector3]):
		DrawKit.glow(ci, Vector2(b.x, b.y), b.z, DUST_BLOB_COLOR)

## Sector-tinted ambient glow — subtle SURVEY nebula fading to vast DEAD red glows.
static func draw_sector_glows(ci: CanvasItem, detail: Dictionary, sector_color: Color,
		blend: float, w: float, h: float, t: float) -> void:
	var survey_a := sector_color.a * (1.0 - blend)
	if survey_a > 0.001:
		var neb_x1 := w * 0.3 + sin(t * 0.07) * 15.0
		var neb_y1 := h * 0.35 + cos(t * 0.05) * 10.0
		var neb_x2 := w * 0.72 + cos(t * 0.06) * 12.0
		var neb_y2 := h * 0.6 + sin(t * 0.04) * 9.0
		var nc := Color(sector_color.r, sector_color.g, sector_color.b, survey_a)
		DrawKit.glow(ci, Vector2(neb_x1, neb_y1), 25.0, nc)
		DrawKit.glow(ci, Vector2(neb_x2, neb_y2), 20.0, nc)
	var dead_a := blend
	if dead_a > 0.001:
		for g in (detail.get("ambient_glows", []) as Array[Vector3]):
			DrawKit.glow(ci, Vector2(g.x, g.y), g.z, Color(AMBIENT_RED.r, AMBIENT_RED.g,
				AMBIENT_RED.b, AMBIENT_RED.a * dead_a))

## THE SUN (SURVEY) crossfading to the EMBER STAR (DEAD) — one draw pass, shared
## position via VisualState.sun_screen_pos(). Anamorphic streak + lens ghost chain
## fade out as blend rises; ember disc + limb arc + red halos fade in.
static func draw_sun(ci: CanvasItem, detail: Dictionary, sun_pos: Vector2, blend: float, w: float, h: float) -> void:
	var survey_a := 1.0 - blend
	if survey_a > 0.01:
		# v5.0 photographic star: a tight white-hot point — the post-stack
		# bloom paints the wide bleed. No huge painted glow discs (they band
		# into rings); the compact halo below is all the paint we allow.
		DrawKit.glow(ci, sun_pos, 3.5, Color(1.0, 1.0, 1.0, 1.0 * survey_a))
		DrawKit.glow(ci, sun_pos, 9.0, Color(1.0, 0.97, 0.90, 0.5 * survey_a))
		# Halo feather: overlapping low-alpha steps so no disc edge survives.
		DrawKit.glow(ci, sun_pos, 15.0, Color(0.97, 0.94, 0.88, 0.10 * survey_a))
		DrawKit.glow(ci, sun_pos, 24.0, Color(0.92, 0.91, 0.90, 0.055 * survey_a))
		DrawKit.glow(ci, sun_pos, 36.0, Color(0.84, 0.88, 1.0, 0.035 * survey_a))
		DrawKit.glow(ci, sun_pos, 52.0, Color(0.80, 0.86, 1.0, 0.022 * survey_a))
		# Chromatic fringe — blue edge hugging the clipped core, as in a photo.
		ci.draw_arc(sun_pos, 6.5, 0.0, TAU, 40,
			Color(0.55, 0.70, 1.0, 0.09 * survey_a), 1.2)

		# Anamorphic streak — hairline core over a thin soft under-glow, with
		# alpha falling off along the length so the tips vanish (no bar ends).
		var segs := 8
		for side in [-1.0, 1.0]:
			for i in segs:
				var t0 := float(i) / float(segs)
				var t1 := float(i + 1) / float(segs)
				var fade := pow(1.0 - t0, 1.8)
				var p0 := sun_pos + Vector2(side * 100.0 * t0, 0.0)
				var p1 := sun_pos + Vector2(side * 100.0 * t1, 0.0)
				ci.draw_line(p0, p1, Color(0.72, 0.85, 1.0, 0.09 * fade * survey_a), 2.0)
				ci.draw_line(p0, p1, Color(0.95, 0.98, 1.0, 0.45 * fade * survey_a), 0.7)

		# 6-blade aperture diffraction spikes — the horizontal pair is the
		# anamorphic streak above; four diagonals complete the star, shorter
		# and fainter, segment-faded like the streak.
		for spike_deg in [60.0, 120.0, 240.0, 300.0]:
			var dir := Vector2.from_angle(deg_to_rad(spike_deg))
			for i in 5:
				var t0 := float(i) / 5.0
				var t1 := float(i + 1) / 5.0
				var fade := pow(1.0 - t0, 1.9)
				ci.draw_line(sun_pos + dir * 34.0 * t0, sun_pos + dir * 34.0 * t1,
					Color(0.95, 0.97, 1.0, 0.22 * fade * survey_a), 0.6)

		# Lens ghost chain — sun through screen center: alternating soft discs,
		# thin rings, and two aperture hexagons (real internal reflections).
		var center := Vector2(w * 0.5, h * 0.5)
		var to_center := center - sun_pos
		var stop_i := 0
		for stop in (detail.get("ghost_chain", []) as Array):
			var d: Dictionary = stop
			var gp := sun_pos + to_center * float(d["t"]) * 1.5
			var col: Color = d["col"]
			var a := float(d["a"]) * survey_a * 0.55
			if stop_i % 2 == 1:
				# Aperture ghost: faint 6-sided polygon outline + fill.
				var hex := PackedVector2Array()
				var hr := float(d["r"]) * 2.6
				for k in 6:
					hex.append(gp + Vector2.from_angle(TAU * float(k) / 6.0 + 0.26) * hr)
				ci.draw_colored_polygon(hex, Color(col.r, col.g, col.b, a * 0.55))
				ci.draw_polyline(hex + PackedVector2Array([hex[0]]),
					Color(col.r, col.g, col.b, a * 1.1), 0.5)
			else:
				ci.draw_circle(gp, float(d["r"]), Color(col.r, col.g, col.b, a))
				ci.draw_arc(gp, float(d["r"]) + 1.25, 0.0, TAU, 24,
					Color(col.r, col.g, col.b, a * 1.1), 0.5)
			stop_i += 1

	if blend > 0.01:
		# Ember star: smoothed nested halos (verified against the radius-scaled
		# glow — no ring banding at these radii) + a faint second-limb heat shimmer.
		DrawKit.glow(ci, sun_pos, 9.0, Color(1.0, 0.45, 0.25, 0.35 * blend))
		DrawKit.glow(ci, sun_pos, 28.0, Color(EMBER_HALO.r, EMBER_HALO.g, EMBER_HALO.b, 0.16 * blend))
		DrawKit.glow(ci, sun_pos, 65.0, Color(EMBER_HALO_WIDE.r, EMBER_HALO_WIDE.g, EMBER_HALO_WIDE.b, blend))
		ci.draw_circle(sun_pos, 7.5, Color(EMBER_DISC.r, EMBER_DISC.g, EMBER_DISC.b, blend))
		ci.draw_arc(sun_pos, 7.5, PI * 0.85, PI * 1.75, 16,
			Color(EMBER_LIMB.r, EMBER_LIMB.g, EMBER_LIMB.b, EMBER_LIMB.a * blend), 1.6)
		ci.draw_arc(sun_pos, 5.5, PI * 1.0, PI * 1.6, 16,
			Color(1.0, 0.314, 0.176, 0.30 * blend), 1.0)
		# Heat-shimmer second limb — faint, slightly wider than the ember limb.
		ci.draw_arc(sun_pos, 9.5, PI * 0.9, PI * 1.6, 16,
			Color(1.0, 0.55, 0.30, 0.14 * blend), 0.8)

## Static jagged derelict hulk silhouette, top-right — DEAD FREQUENCY only.
static func draw_derelict_hulk(ci: CanvasItem, detail: Dictionary, blend: float) -> void:
	if blend <= 0.01:
		return
	var pts := detail.get("hulk_pts", PackedVector2Array()) as PackedVector2Array
	if pts.size() < 3:
		return
	ci.draw_colored_polygon(pts, Color(0.02, 0.016, 0.016, blend))
	for stub in (detail.get("hulk_antenna", []) as Array):
		var seg: Array = stub
		ci.draw_line(seg[0], seg[1], Color(0.02, 0.016, 0.016, blend), 1.2)
	var lit_pts := detail.get("hulk_lit_edge", PackedVector2Array()) as PackedVector2Array
	if lit_pts.size() >= 2:
		ci.draw_polyline(lit_pts, Color(1.0, 0.235, 0.149, 0.16 * blend), 1.2)
	var win: Vector2 = detail.get("hulk_window", Vector2.ZERO)
	ci.draw_rect(Rect2(win.x - 1.0, win.y - 0.7, 2.0, 1.4), Color(1.0, 0.314, 0.176, 0.5 * blend))
