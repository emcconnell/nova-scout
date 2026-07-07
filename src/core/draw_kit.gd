## DrawKit — shared CanvasItem drawing helpers for the TURN 4 art pass.
## Fakes the gradient/glow vocabulary of the concept sheets with cheap
## layered primitives (no shaders, no textures — GL Compatibility safe).
## All functions are static; call from any _draw() as DrawKit.glow(self, ...).
class_name DrawKit
extends Object

## Soft radial glow: concentric circles with falling alpha (≈ radial gradient).
## Step count auto-scales with radius so large glows never show ring banding;
## `steps` is a floor hint for callers that want extra smoothness.
static func glow(ci: CanvasItem, pos: Vector2, radius: float, color: Color, steps: int = 4) -> void:
	var n := clampi(maxi(steps, int(radius * 0.3) + 3), 4, 14)
	# Largest ring first; eased radii cluster rings toward the hot center and
	# thin the faint outer bands, so the falloff reads as a smooth gradient.
	var ring_alpha := color.a * 1.2 / float(n)
	for i in n:
		var t := pow(float(n - i) / float(n), 1.3)      # 1.0 → largest ring
		ci.draw_circle(pos, radius * t, Color(color.r, color.g, color.b, ring_alpha))

## Vertical gradient rect via horizontal strips.
static func vgrad_rect(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color, steps: int = 6) -> void:
	var strip_h := rect.size.y / float(steps)
	for i in steps:
		var t := float(i) / maxf(float(steps - 1), 1.0)
		ci.draw_rect(Rect2(rect.position.x, rect.position.y + strip_h * float(i),
			rect.size.x, strip_h + 0.5), top.lerp(bottom, t))

## Horizontal gradient rect via vertical strips.
static func hgrad_rect(ci: CanvasItem, rect: Rect2, left: Color, right: Color, steps: int = 6) -> void:
	var strip_w := rect.size.x / float(steps)
	for i in steps:
		var t := float(i) / maxf(float(steps - 1), 1.0)
		ci.draw_rect(Rect2(rect.position.x + strip_w * float(i), rect.position.y,
			strip_w + 0.5, rect.size.y), left.lerp(right, t))

## Deterministic RNG for stable per-instance surface noise (rivets, flecks).
static func rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r

## Points of an ellipse (or elliptical arc) — Godot 2D has no draw_ellipse.
static func ellipse_points(center: Vector2, radii: Vector2, n: int = 24,
		start: float = 0.0, end: float = TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := start + (end - start) * float(i) / float(n)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return pts

## Filled ellipse.
static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, n: int = 24) -> void:
	ci.draw_colored_polygon(ellipse_points(center, radii, n), color)

## Same polygon offset toward a light direction — stepped form shading
## (the concept sheet's rock technique: re-fill the silhouette displaced
## toward the sun with successively brighter tones).
static func poly_offset(pts: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + offset)
	return out

## Irregular rock silhouette — two sine harmonics + jitter, seeded.
static func rock_points(center: Vector2, radius: float, seed_value: int, n: int = 16) -> PackedVector2Array:
	var r := rng(seed_value)
	var k1 := 2 + r.randi_range(0, 1)
	var k2 := 5 + r.randi_range(0, 2)
	var p1 := r.randf() * TAU
	var p2 := r.randf() * TAU
	var pts := PackedVector2Array()
	for i in n:
		var a := float(i) / float(n) * TAU
		var f := 0.84 + 0.13 * sin(float(k1) * a + p1) + 0.07 * sin(float(k2) * a + p2) \
			+ (r.randf() - 0.5) * 0.07
		pts.append(center + Vector2(cos(a), sin(a)) * radius * f)
	return pts

## Stroke only the silhouette edges whose outward normal faces `light_dir`
## (the lit-limb highlight from the concept sheets).
static func lit_limb(ci: CanvasItem, pts: PackedVector2Array, center: Vector2,
		radius: float, light_dir: Vector2, color: Color, width: float = 1.2,
		threshold: float = 0.3) -> void:
	var run := PackedVector2Array()
	var count := pts.size()
	for i in count + 1:
		var p := pts[i % count]
		var n := (p - center) / maxf(radius, 0.001)
		if n.dot(light_dir) > threshold:
			run.append(p)
		else:
			if run.size() >= 2:
				ci.draw_polyline(run, color, width)
			run.clear()
	if run.size() >= 2:
		ci.draw_polyline(run, color, width)
