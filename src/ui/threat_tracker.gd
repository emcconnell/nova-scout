## ThreatTracker — Diegetic motion-tracker HUD (bottom-right).
## Sweeps for enemies and mines: on-screen and up to lookahead_px above the
## viewport, so threats announce themselves before they arrive.
## The Silence appears only as an intermittent ghost blip.
## Retints to VisualState.pal("hud") — thin flight-FUI line weights (Turn 4).
## GDD Ref: dark-directive.md §4.1 Threat Tracker; art-bible.md Turn 4
class_name ThreatTracker
extends Control

const COL_GHOST  := Color(0.80, 0.90, 0.80)

const RADIUS := 14.5
const MARGIN := 4.0
const TRAIL_LEN := 3   # Blip fade-trail frames (Turn 4.1 compact rebuild)

var _sweep_angle: float = 0.0
var _ping_timer: float = 1.0
var _blip_count_prev: int = 0
var _ghost_jitter: float = 0.0
var _font: Font = null
var _threat_cache: Array[Dictionary] = []   # Collected once per frame in _process
var _blip_trail: Array[Array] = []          # Ring buffer of prior frames' blip screen-positions

func _ready() -> void:
	_font = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font == null:
		_font = ThemeDB.fallback_font
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not _is_active_state():
		queue_redraw()
		return
	_sweep_angle = fmod(_sweep_angle + delta * 2.4, TAU)
	_ghost_jitter += delta

	_threat_cache = _collect_threats()
	var threats := _threat_cache
	# New contact — one-shot ping tiered by count jump
	if threats.size() > _blip_count_prev:
		AudioManager.play_sfx("tracker_ping", 0.75)
		_ping_timer = minf(_ping_timer, 0.4)
	_blip_count_prev = threats.size()

	# Push this frame's blip positions onto the trail ring buffer (fade trail).
	var frame_positions: Array = []
	for t in threats:
		frame_positions.append(t["pos"])
	_blip_trail.push_front(frame_positions)
	while _blip_trail.size() > TRAIL_LEN:
		_blip_trail.pop_back()

	# Periodic ping — interval tightens as the nearest threat closes
	if not threats.is_empty():
		_ping_timer -= delta
		if _ping_timer <= 0.0:
			var nearest: float = 1.0
			for t in threats:
				nearest = minf(nearest, float(t["norm_dist"]))
			var far: float = float(GameManager.dread_value("tracker", "ping_interval_far", 1.4))
			var near: float = float(GameManager.dread_value("tracker", "ping_interval_near", 0.45))
			_ping_timer = lerpf(near, far, nearest)
			AudioManager.play_sfx("tracker_ping", lerpf(0.85, 0.45, nearest))
	queue_redraw()

func _is_active_state() -> bool:
	return GameManager.current_state in [
		GameManager.GameState.TRAVEL,
		GameManager.GameState.STAR_CLUSTER,
		GameManager.GameState.SCANNING,
		GameManager.GameState.ALIEN_COMBAT,
	]

## Gather tracked contacts: enemies + armed mines, on-screen or approaching.
## Returns [{pos: Vector2 (viewport space), norm_dist: 0..1, ghost: bool}]
func _collect_threats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var vp := get_viewport_rect().size
	var lookahead: float = float(GameManager.dread_value("tracker", "lookahead_px", 100.0))
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var ppos: Vector2 = player.global_position if player else vp * 0.5

	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node2D
		if n == null or not is_instance_valid(n):
			continue
		if n.global_position.y < -lookahead:
			continue
		var ghost: bool = n.is_in_group("silence")
		if ghost and fmod(_ghost_jitter, 1.7) > 0.55:
			continue   # The Silence only registers in flickers
		var jitter := Vector2.ZERO
		if ghost:
			jitter = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		out.append({
			"pos": n.global_position + jitter,
			"norm_dist": clampf(ppos.distance_to(n.global_position) / (vp.y * 1.2), 0.0, 1.0),
			"ghost": ghost,
		})

	for m in get_tree().get_nodes_in_group("mines"):
		var n := m as Node2D
		if n == null or not is_instance_valid(n) or n.global_position.y < -lookahead:
			continue
		out.append({
			"pos": n.global_position,
			"norm_dist": clampf(ppos.distance_to(n.global_position) / (vp.y * 1.2), 0.0, 1.0),
			"ghost": false,
		})
	return out

## Compact instrument-style radar: hairline concentric rings inside a thin
## bracket frame, a rotating sweep whose wake briefly brightens blips, and
## diamond-shaped contacts with a short fade trail (Turn 4.1 restyle).
func _draw() -> void:
	if not _is_active_state():
		return
	var vp := get_viewport_rect().size
	var lookahead: float = float(GameManager.dread_value("tracker", "lookahead_px", 100.0))
	var center := Vector2(vp.x - RADIUS - MARGIN, vp.y - MARGIN - 5.0)
	var hud_col := VisualState.pal("hud")
	var frame_col := Color(hud_col.r, hud_col.g, hud_col.b, 0.6)
	var sweep_col := Color(hud_col.r, hud_col.g, hud_col.b, 0.28)
	var blip_col := VisualState.pal("accent")
	var text_col := Color(hud_col.r, hud_col.g, hud_col.b, 0.6)

	# Range rings — 3 hairline rings, alpha falling outward.
	var ring_fracs := [0.42, 0.7, 1.0]
	for i in ring_fracs.size():
		var r: float = RADIUS * float(ring_fracs[i])
		var a: float = 0.32 - float(i) * 0.09
		draw_arc(center, r, PI, TAU, 20, Color(hud_col.r, hud_col.g, hud_col.b, a), 0.5)
	# Bearing lines
	for i in 3:
		var a := PI + PI * 0.25 * float(i + 1)
		draw_line(center, center + Vector2(cos(a), sin(a)) * RADIUS,
			Color(hud_col.r, hud_col.g, hud_col.b, 0.16), 0.5)
	# Hairline bracket frame (thin, not a filled ring).
	draw_arc(center, RADIUS + 1.0, PI, TAU, 24, frame_col, 0.6)
	draw_line(center + Vector2(-RADIUS - 1, 0), center + Vector2(RADIUS + 1, 0), frame_col, 0.6)
	draw_line(center + Vector2(-RADIUS - 1, 0), center + Vector2(-RADIUS - 1, -2.5), frame_col, 0.6)
	draw_line(center + Vector2(RADIUS + 1, 0), center + Vector2(RADIUS + 1, -2.5), frame_col, 0.6)

	# Sweep blade (upper half only) — slow rotation, thin line.
	var sweep := PI + fmod(_sweep_angle, PI)
	draw_line(center, center + Vector2(cos(sweep), sin(sweep)) * RADIUS, sweep_col, 0.7)

	# Fade trail — older frames first (dimmest), current frame drawn last (brightest).
	for age in range(_blip_trail.size() - 1, -1, -1):
		var positions: Array = _blip_trail[age]
		if age == 0:
			continue   # current-frame contacts drawn below with full detail
		var trail_a: float = 1.0 - float(age) / float(TRAIL_LEN)
		for wpos_v in positions:
			var wpos: Vector2 = wpos_v
			var bp := _world_to_scope(wpos, vp, lookahead, center)
			_draw_diamond(bp, 1.0, Color(blip_col.r, blip_col.g, blip_col.b, 0.25 * trail_a))

	# Current contacts — diamonds, brightened if under the sweep's wake.
	for t in _threat_cache:
		var wpos: Vector2 = t["pos"]
		var bp := _world_to_scope(wpos, vp, lookahead, center)
		var under_sweep: bool = _angle_near_sweep(bp, center, sweep)
		if t["ghost"]:
			draw_circle(bp, 1.1, Color(COL_GHOST.r, COL_GHOST.g, COL_GHOST.b, randf_range(0.25, 0.7)))
		else:
			var urgency: float = 1.0 - float(t["norm_dist"])
			var boost: float = 1.35 if under_sweep else 1.0
			var sz: float = (1.0 + urgency * 0.4) * boost
			_draw_diamond(bp, sz, Color(blip_col.r, blip_col.g, blip_col.b, minf(1.0, 0.85 * boost)))

	draw_string(_font, center + Vector2(-RADIUS, 6.0), "TRACKER",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, text_col)

## Map a world position onto the scope's screen-space radius (shared by the
## live blips and the fade trail so both use identical projection math).
func _world_to_scope(wpos: Vector2, vp: Vector2, lookahead: float, center: Vector2) -> Vector2:
	var nx := clampf(wpos.x / vp.x, 0.0, 1.0) * 2.0 - 1.0            # -1..1
	var ny := clampf((wpos.y + lookahead) / (vp.y + lookahead), 0.0, 1.0)  # 0 top .. 1 bottom
	return center + Vector2(nx * RADIUS * 0.85, -RADIUS * 0.92 * (1.0 - ny) - 1.0)

## True if a blip screen-position sits within the sweep blade's brightening wake.
func _angle_near_sweep(bp: Vector2, center: Vector2, sweep: float) -> bool:
	var rel := bp - center
	if rel.length() < 0.01:
		return false
	var ang := rel.angle()
	var diff := fmod(absf(ang - sweep), TAU)
	if diff > PI:
		diff = TAU - diff
	return diff < 0.35

## Small 1.5px diamond contact marker.
func _draw_diamond(pos: Vector2, scale: float, color: Color) -> void:
	var s := 1.5 * scale
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -s), pos + Vector2(s, 0), pos + Vector2(0, s), pos + Vector2(-s, 0)
	]), color)
