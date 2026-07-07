## EnemyRenderer — TURN 4 shared biomech draw vocabulary for all alien enemies.
## One geometry, three lighting states crossfaded by VisualState: violet-black
## chitin (SURVEY) -> pitch-black + red eyes (DEAD) -> wet chitin (beam-lit).
## GDD Ref: art-bible.md (Turn 4) — Alien body ramps + beam-reveal rule.
class_name EnemyRenderer
extends Object

# ─── Shared palette stops (hex from turn4 spec) ─────────────────────────────
const SURVEY_HI := Color("3E2F50")
const SURVEY_MID := Color("171122")
const SURVEY_LO := Color("05040A")
const DEAD_HI := Color("161014")
const DEAD_MID := Color("070406")
const DEAD_LO := Color("010101")
const LIT_HI := Color("8A7458")
const LIT_MID := Color("4A3A28")
const LIT_LO := Color("140E08")

const MAGENTA := Color("B03BFF")
const MAGENTA_BRIGHT := Color("E14FFF")
const VEIN_DEAD := Color("7A0E12")
const EYE_DEAD := Color("FF2A3C")
const EYE_LIT := Color("FF6A70")
const RIM_LIT := Color(1.0, 0.886, 0.745)   # rgba(255,226,190,*)

## Body ramp stop (hi/mid/lo index 0/1/2), crossfaded survey->dead, then lerped
## toward the wet-chitin ramp by `lit` (0..1, already scaled by beam_lit*blend).
static func body_stop(index: int, lit: float) -> Color:
	var survey: Color = [SURVEY_HI, SURVEY_MID, SURVEY_LO][index]
	var dead: Color = [DEAD_HI, DEAD_MID, DEAD_LO][index]
	var wet: Color = [LIT_HI, LIT_MID, LIT_LO][index]
	return VisualState.col(survey, dead).lerp(wet, lit)

## Full lit factor for a world position: beam reveal scaled by how "dead" the
## world already is (SURVEY has no flood cone to speak of).
static func lit_factor(world_pos: Vector2, cap: float = 1.0) -> float:
	return minf(VisualState.beam_lit(world_pos), cap) * VisualState.blend()

## Seeded fleck field — precompute in _ready, pass the array to draw each frame.
## Returns Array[Vector3] (x, y, is_light ? 1 : 0).
static func seed_flecks(seed_value: int, count: int, radius: Vector2) -> Array[Vector3]:
	var r := DrawKit.rng(seed_value)
	var out: Array[Vector3] = []
	for i in count:
		var a := r.randf() * TAU
		var rr := r.randf()
		var is_light := 1.0 if r.randf() > 0.5 else 0.0
		out.append(Vector3(cos(a) * radius.x * rr, sin(a) * radius.y * rr, is_light))
	return out

## Draw a precomputed fleck field. `lit` warms light flecks toward RIM_LIT tint.
static func draw_flecks(ci: CanvasItem, flecks: Array[Vector3], lit: float) -> void:
	var light_col := Color(1.0, 0.902, 0.784, 0.08).lerp(Color(1.0, 0.902, 0.784, 0.14), lit)
	var dark_col := Color(0.0, 0.0, 0.0, 0.3)
	for f in flecks:
		var col := light_col if f.z > 0.5 else dark_col
		ci.draw_rect(Rect2(f.x - 0.6, f.y - 0.6, 1.2, 1.2), col)

## Plate ridge: dark stroke arc + one-pixel lighter echo above it (warms when lit).
static func plate_ridge_arc(ci: CanvasItem, center: Vector2, radii: Vector2,
		start: float, end: float, lit: float, width: float = 1.3) -> void:
	var pts := DrawKit.ellipse_points(center, radii, 16, start, end)
	ci.draw_polyline(pts, Color(0, 0, 0, 0.55), width)
	var echo_survey := Color(1, 1, 1, 0.06)
	var echo_dead := Color(1, 1, 1, 0.06)
	var echo := echo_survey.lerp(echo_dead, VisualState.blend()).lerp(Color(RIM_LIT.r, RIM_LIT.g, RIM_LIT.b, 0.25), lit)
	var echo_pts := DrawKit.ellipse_points(center + Vector2(-1, 0), radii, 16, start, end)
	ci.draw_polyline(echo_pts, echo, 1.0)

## Plate ridge as a curved polyline (for elongated bodies): dark stroke + echo.
static func plate_ridge_line(ci: CanvasItem, pts: PackedVector2Array,
		echo_pts: PackedVector2Array, lit: float, width: float = 1.6) -> void:
	ci.draw_polyline(pts, Color(0, 0, 0, 0.6), width)
	var echo := Color(1, 1, 1, 0.07).lerp(Color(RIM_LIT.r, RIM_LIT.g, RIM_LIT.b, 0.30), lit)
	ci.draw_polyline(echo_pts, echo, 1.0)

## Eye cluster: dots at local offsets (x, y, radius), red in DEAD, softened to
## EYE_LIT when beam-lit; invisible (alpha 0) in SURVEY since tech is alive there.
## `glint_indices` marks which dots get a white specular speck.
static func eye_cluster(ci: CanvasItem, dots: Array, lit: float, glint_indices: Array[int] = []) -> void:
	var reveal := VisualState.blend()   # eyes only wake in DEAD FREQUENCY
	if reveal <= 0.001:
		return
	var eye_col := EYE_DEAD.lerp(EYE_LIT, lit)
	for i in dots.size():
		var d: Vector3 = dots[i]
		var pos := Vector2(d.x, d.y)
		DrawKit.glow(ci, pos, d.z + 1.6, Color(eye_col.r, eye_col.g, eye_col.b, 0.35 * reveal), 3)
		ci.draw_circle(pos, d.z, Color(eye_col.r, eye_col.g, eye_col.b, reveal))
		if i in glint_indices:
			ci.draw_rect(Rect2(pos.x - 0.4, pos.y - 0.8, 0.8, 0.8), Color(1, 1, 1, 0.85 * reveal))

## Deep-red vein underline (DEAD) fading in as the glow dies (SURVEY magenta out).
static func dead_vein_line(ci: CanvasItem, from: Vector2, to: Vector2) -> void:
	var a := 0.75 * VisualState.blend()
	if a <= 0.001:
		return
	ci.draw_line(from, to, Color(VEIN_DEAD.r, VEIN_DEAD.g, VEIN_DEAD.b, a), 1.3)

## Magenta glow line/vein — dies out as blend approaches 1 (the tech goes dead).
static func magenta_vein(ci: CanvasItem, from: Vector2, to: Vector2, width: float = 1.7) -> void:
	var a := 1.0 - VisualState.blend()
	if a <= 0.001:
		return
	DrawKit.glow(ci, (from + to) * 0.5, (from - to).length() * 0.5 + 3.0,
		Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.12 * a), 2)
	ci.draw_line(from, to, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, a), width)

## Warm lit-rim stroke down a silhouette edge — only visible when beam-lit.
static func lit_rim_stroke(ci: CanvasItem, pts: PackedVector2Array, lit: float) -> void:
	if lit <= 0.001:
		return
	ci.draw_polyline(pts, Color(RIM_LIT.r, RIM_LIT.g, RIM_LIT.b, 0.55 * lit), 1.6)

## Soft under-halo / belly glow — magenta in SURVEY, red-embers in DEAD, dies
## toward zero as blend rises past the point the creature goes fully dark.
static func under_halo(ci: CanvasItem, pos: Vector2, radius: float) -> void:
	var col := VisualState.col(Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.22), Color(EYE_DEAD.r, EYE_DEAD.g, EYE_DEAD.b, 0.06))
	DrawKit.glow(ci, pos, radius, col, 3)
