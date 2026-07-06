## ThreatTracker — Diegetic motion-tracker HUD (bottom-right).
## Sweeps for enemies and mines: on-screen and up to lookahead_px above the
## viewport, so threats announce themselves before they arrive.
## The Silence appears only as an intermittent ghost blip.
## GDD Ref: dark-directive.md §4.1 Threat Tracker
class_name ThreatTracker
extends Control

const COL_FRAME  := Color(0.10, 0.42, 0.12, 0.85)
const COL_GRID   := Color(0.08, 0.30, 0.09, 0.45)
const COL_SWEEP  := Color(0.25, 0.95, 0.25, 0.30)
const COL_BLIP   := Color(0.45, 1.00, 0.35)
const COL_GHOST  := Color(0.80, 0.90, 0.80)
const COL_TEXT   := Color(0.18, 0.62, 0.14, 0.75)

const RADIUS := 17.0
const MARGIN := 4.0

var _sweep_angle: float = 0.0
var _ping_timer: float = 1.0
var _blip_count_prev: int = 0
var _ghost_jitter: float = 0.0
var _font: Font = null
var _threat_cache: Array[Dictionary] = []   # Collected once per frame in _process

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

func _draw() -> void:
	if not _is_active_state():
		return
	var vp := get_viewport_rect().size
	var lookahead: float = float(GameManager.dread_value("tracker", "lookahead_px", 100.0))
	var center := Vector2(vp.x - RADIUS - MARGIN, vp.y - MARGIN - 6.0)

	# Backing glass
	draw_circle_arc_poly(center, RADIUS + 2.0, Color(0.0, 0.03, 0.0, 0.75))
	# Range rings
	for r in [RADIUS * 0.45, RADIUS * 0.75, RADIUS]:
		draw_arc(center, r, PI, TAU, 20, COL_GRID, 0.8)
	# Bearing lines
	for i in 3:
		var a := PI + PI * 0.25 * float(i + 1)
		draw_line(center, center + Vector2(cos(a), sin(a)) * RADIUS, COL_GRID, 0.6)
	# Frame
	draw_arc(center, RADIUS + 1.0, PI, TAU, 24, COL_FRAME, 1.0)
	draw_line(center + Vector2(-RADIUS - 1, 0), center + Vector2(RADIUS + 1, 0), COL_FRAME, 1.0)

	# Sweep blade (upper half only)
	var sweep := PI + fmod(_sweep_angle, PI)
	draw_line(center, center + Vector2(cos(sweep), sin(sweep)) * RADIUS, COL_SWEEP, 1.2)

	# Blips — world y from -lookahead..vp.y maps onto radar radius
	for t in _threat_cache:
		var wpos: Vector2 = t["pos"]
		var nx := clampf(wpos.x / vp.x, 0.0, 1.0) * 2.0 - 1.0            # -1..1
		var ny := clampf((wpos.y + lookahead) / (vp.y + lookahead), 0.0, 1.0)  # 0 top .. 1 bottom
		var bp := center + Vector2(nx * RADIUS * 0.85, -RADIUS * 0.92 * (1.0 - ny) - 1.0)
		if t["ghost"]:
			draw_circle(bp, 1.3, Color(COL_GHOST.r, COL_GHOST.g, COL_GHOST.b, randf_range(0.25, 0.7)))
		else:
			var urgency: float = 1.0 - float(t["norm_dist"])
			draw_circle(bp, 1.0 + urgency * 0.6, COL_BLIP)
			draw_circle(bp, 2.2 + urgency, Color(COL_BLIP.r, COL_BLIP.g, COL_BLIP.b, 0.22))

	draw_string(_font, center + Vector2(-RADIUS, 6.5), "TRACKER",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_TEXT)

## Filled semicircle helper (draw_circle can't clip to the upper half).
func draw_circle_arc_poly(center: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:   # left edge → top arc → right edge; closes flat along the base
		var a := PI + PI * float(i) / 12.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, color)
