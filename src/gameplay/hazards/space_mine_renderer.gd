## SpaceMineRenderer — menacing warhead draw pass (TURN 4 polish).
## Sharper contact spikes, a red core-lens "eye" with specular, hairline panel
## seams, and an arm-blink telegraph rendered as a crisp core flash + expanding
## ring (same timing/period as the legacy blinking dots). Extracted from
## SpaceMine to respect the 300-line budget.
class_name SpaceMineRenderer
extends Object

const COLOR_CHARGE := Color(1.0, 0.50, 0.00)

## Everything the draw pass needs for one frame — built fresh in SpaceMine._draw().
class DrawState:
	var mine_type: int = 0
	var metal: Color = Color.WHITE
	var running_light: Color = Color.RED
	var chasing: bool = false
	var charging: bool = false
	var charge_timer: float = 0.0
	var charge_dur: float = 0.4
	var blink_timer: float = 0.0
	var blink_rate: float = 3.0

## Draws one mine at local origin, crossfaded by VisualState where noted.
static func draw(ci: CanvasItem, ds: DrawState) -> void:
	var bt := ds.blink_timer
	var blink: bool = sin(bt * ds.blink_rate) > 0.0

	_draw_charge_aura(ci, ds, bt)
	_draw_chase_glow(ci, ds, bt)
	_draw_contact_spikes(ci, ds)
	_draw_body_and_lens(ci, ds)
	_draw_arm_telegraph(ci, ds, bt, blink)
	_draw_sensor_bulbs(ci, ds, bt)
	_draw_type_accents(ci, ds, bt)

## Charging glow aura (expands as charge builds) + pulsing charge ring.
static func _draw_charge_aura(ci: CanvasItem, ds: DrawState, bt: float) -> void:
	if not ds.charging:
		return
	var ct: float = ds.charge_timer / ds.charge_dur
	var glow_r := 8.0 + ct * 6.0
	ci.draw_circle(Vector2.ZERO, glow_r, Color(COLOR_CHARGE.r, COLOR_CHARGE.g, COLOR_CHARGE.b, ct * 0.25))
	ci.draw_arc(Vector2.ZERO, glow_r, bt * 4.0, bt * 4.0 + TAU, 16,
		Color(COLOR_CHARGE.r, COLOR_CHARGE.g, COLOR_CHARGE.b, ct * 0.5), 1.0)

## Soft proximity glow while chasing the player.
static func _draw_chase_glow(ci: CanvasItem, ds: DrawState, bt: float) -> void:
	if not ds.chasing:
		return
	var chase_a := 0.15 + 0.1 * sin(bt * 8.0)
	var rl := ds.running_light
	ci.draw_circle(Vector2.ZERO, 10.0, Color(rl.r, rl.g, rl.b, chase_a))

## Contact spikes (6 directions) — thin tapered triangle shaft to a hairline tip (no ball tip).
static func _draw_contact_spikes(ci: CanvasItem, ds: DrawState) -> void:
	for i in 6:
		var a: float = TAU / 6.0 * float(i)
		var tip := Vector2(cos(a), sin(a))
		var perp := Vector2(-tip.y, tip.x)
		var spike_col: Color = ds.metal
		if ds.charging:
			var t: float = ds.charge_timer / ds.charge_dur
			spike_col = ds.metal.lerp(COLOR_CHARGE, t)

		var base_a := tip * 4.2 + perp * 0.9
		var base_b := tip * 4.2 - perp * 0.9
		var spike_tip := tip * 10.0
		ci.draw_colored_polygon(PackedVector2Array([base_a, base_b, spike_tip]), spike_col)
		ci.draw_polyline(PackedVector2Array([base_a, spike_tip, base_b]), spike_col.darkened(0.35), 0.4)

		if ds.charging:
			var ct2: float = ds.charge_timer / ds.charge_dur
			DrawKit.glow(ci, spike_tip, ct2 * 2.0, Color(COLOR_CHARGE.r, COLOR_CHARGE.g, COLOR_CHARGE.b, ct2 * 0.6), 3)

## Red core-lens "eye" + its tiny specular catch-light — the casing itself
## (ramp, socket shading, stud ring, panel seams) is baked into the body sprite.
static func _draw_body_and_lens(ci: CanvasItem, ds: DrawState) -> void:
	ci.draw_circle(Vector2.ZERO, 2.7, VisualState.col(Color(0.55, 0.04, 0.03), Color(0.30, 0.02, 0.02)))
	ci.draw_circle(Vector2(-0.8, -0.9), 0.6, Color(1, 0.7, 0.65, VisualState.f(0.6, 0.4)))

## Arm-blink telegraph — same period as legacy blinking dots, now a crisp core
## flash + a thin expanding ring instead of fat blinking dots.
static func _draw_arm_telegraph(ci: CanvasItem, ds: DrawState, bt: float, blink: bool) -> void:
	var phase: float = fposmod(bt * ds.blink_rate / TAU, 1.0)
	if blink:
		ci.draw_circle(Vector2.ZERO, 1.3, Color(1, 0.95, 0.9, 0.9))
		DrawKit.glow(ci, Vector2.ZERO, 3.0, Color(ds.running_light.r, ds.running_light.g, ds.running_light.b, 0.35), 3)
	var ring_r: float = 4.5 + phase * 6.0
	var ring_a: float = (1.0 - phase) * 0.5
	ci.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 20, Color(ds.running_light.r, ds.running_light.g, ds.running_light.b, ring_a), 0.6)

## Side sensor bulbs (offset blink) — smaller, deep-orange, no longer fat dots.
static func _draw_sensor_bulbs(ci: CanvasItem, ds: DrawState, bt: float) -> void:
	var blink2: bool = sin(bt * ds.blink_rate + 1.5) > 0.0
	var sensor_col := VisualState.col(Color(0.85, 0.42, 0.05), Color(0.75, 0.20, 0.06))
	for side in [-1.0, 1.0]:
		var lpos := Vector2(side * 4.5, 3.0)
		if blink2:
			ci.draw_circle(lpos, 0.7, sensor_col)
			ci.draw_circle(lpos, 1.1, Color(sensor_col.r, sensor_col.g, sensor_col.b, 0.3))
		else:
			ci.draw_circle(lpos, 0.45, sensor_col.darkened(0.75))

## Per-variant accents: cluster split-hint dots, rapid speed-indicator lines.
static func _draw_type_accents(ci: CanvasItem, ds: DrawState, bt: float) -> void:
	if ds.mine_type == SpaceMine.MineType.CLUSTER:
		for i in 3:
			var a: float = TAU / 3.0 * float(i) + PI / 6.0
			var cp := Vector2(cos(a) * 3.0, sin(a) * 3.0)
			var cluster_a := (0.5 + 0.2 * sin(bt * 3.0 + float(i))) * VisualState.f(1.0, 0.35)
			var cluster_col := VisualState.col(Color(0.8, 0.2, 1.0), Color(1.0, 0.165, 0.235))
			ci.draw_circle(cp, 1.3, Color(cluster_col.r, cluster_col.g, cluster_col.b, cluster_a))
			ci.draw_circle(cp, 0.6, Color(1.0, 0.6, 1.0, cluster_a * 0.8))

	if ds.mine_type == SpaceMine.MineType.RAPID:
		var rapid_a := 0.4 + 0.3 * sin(bt * 6.0)
		var rapid_col := VisualState.col(SpaceMine.COLOR_RAPID, SpaceMine.DEAD_RAPID)
		for side in [-1.0, 1.0]:
			ci.draw_line(Vector2(side * 3.0, -3.0), Vector2(side * 3.0, 3.0),
				Color(rapid_col.r, rapid_col.g, rapid_col.b, rapid_a), 1.0)
