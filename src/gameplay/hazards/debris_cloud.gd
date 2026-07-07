## DebrisCloud — Hazard area that slows the player and deals damage over time.
## Reads as a scattered field of rock shards + dust, never a solid disc/planet.
class_name DebrisCloud
extends Area2D

const DAMAGE_PER_SEC := 3.0

const SHARD_COLOR_LIT     := Color(0.62, 0.56, 0.46, 0.95)   # survey: dusty tan-gray, lit side
const SHARD_COLOR_SHADOW  := Color(0.30, 0.27, 0.23, 0.95)   # survey: darker side (away from key light)
const SHARD_COLOR_DEAD    := Color(0.07, 0.05, 0.05, 0.95)   # dead: near-black
const SHARD_RIM_DEAD      := Color(0.62, 0.10, 0.08, 0.55)   # dead: faint red rim on a few shards
const MOTE_COLOR_SURVEY   := Color(0.58, 0.52, 0.42, 0.55)
const MOTE_COLOR_DEAD     := Color(0.22, 0.09, 0.08, 0.45)
const HAZE_COLOR_SURVEY   := Color(0.55, 0.48, 0.38, 0.05)
const HAZE_COLOR_DEAD     := Color(0.30, 0.08, 0.06, 0.05)

const KEY_LIGHT_DIR := Vector2(-0.66, -0.75)   # normalized-ish upper-left key light

var _players_inside: Array[Node] = []
var _damage_tick: float = 0.0
var _radius: float = 30.0
var velocity: Vector2 = Vector2(0, 22)   # Drifts downward by default

var _drift_t: float = 0.0
var _instance_seed: int = 0

# Per-shard precomputed data: local-space polygon points, drift phase/amplitude,
# and whether it carries the faint dead-frequency red rim.
var _shard_polys: Array[PackedVector2Array] = []
var _shard_phase: Array[float] = []
var _shard_amp: Array[float] = []
var _shard_shadowed: Array[bool] = []
var _shard_rimmed: Array[bool] = []

# Per-mote precomputed data: local-space position + size/alpha weight.
var _mote_pos: Array[Vector2] = []
var _mote_size: Array[float] = []
var _mote_weight: Array[float] = []

# 1-2 barely-there depth-haze puffs (alpha <= 0.05 handled at draw time).
var _haze_pos: Array[Vector2] = []
var _haze_radius: Array[float] = []

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hazards")
	monitoring = true
	collision_layer = 16
	collision_mask = 1   # 1=player only
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Read radius from collision shape
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		_radius = (col.shape as CircleShape2D).radius
	_instance_seed = int(get_instance_id()) & 0x7fffffff
	_build_field()

## Precomputes shards, dust motes, and haze puffs once — no randf() in _draw.
func _build_field() -> void:
	var r := DrawKit.rng(_instance_seed)
	var shard_count := r.randi_range(12, 16)
	for i in shard_count:
		# Density falls toward the edge: bias sample distance toward the center.
		var dist := pow(r.randf(), 1.6) * _radius * 0.92
		var ang := r.randf() * TAU
		var center := Vector2(cos(ang), sin(ang)) * dist
		var shard_r := r.randf_range(1.0, 3.0)
		_shard_polys.append(_build_shard_poly(r, center, shard_r))
		_shard_phase.append(r.randf() * TAU)
		_shard_amp.append(r.randf_range(0.6, 2.2))
		# Facing away from the key light reads as the shadowed side.
		var facing := center.normalized() if center.length() > 0.01 else Vector2.ZERO
		_shard_shadowed.append(facing.dot(KEY_LIGHT_DIR) < 0.0)
		_shard_rimmed.append(i % 6 == 0)   # a couple of shards carry the dead-state rim

	var mote_count := 30
	for i in mote_count:
		var dist_m := pow(r.randf(), 1.4) * _radius * 0.98
		var ang_m := r.randf() * TAU
		_mote_pos.append(Vector2(cos(ang_m), sin(ang_m)) * dist_m)
		_mote_size.append(r.randf_range(0.5, 1.0))
		_mote_weight.append(r.randf_range(0.4, 1.0))

	var haze_count := r.randi_range(1, 2)
	for i in haze_count:
		_haze_pos.append(Vector2(r.randf_range(-0.3, 0.3), r.randf_range(-0.3, 0.3)) * _radius)
		_haze_radius.append(_radius * r.randf_range(0.5, 0.75))

## Builds one irregular 3-5 point shard polygon centered at `center`.
func _build_shard_poly(r: RandomNumberGenerator, center: Vector2, shard_r: float) -> PackedVector2Array:
	var pt_count := r.randi_range(3, 5)
	var base_ang := r.randf() * TAU
	var pts := PackedVector2Array()
	for i in pt_count:
		var a := base_ang + float(i) / float(pt_count) * TAU
		var jitter := r.randf_range(0.55, 1.15)
		pts.append(center + Vector2(cos(a), sin(a)) * shard_r * jitter)
	return pts

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	global_position += velocity * delta
	_drift_t += delta
	if global_position.y > get_viewport_rect().size.y + 60:
		_release_all_players()
		queue_free()
		return
	queue_redraw()
	if _players_inside.is_empty():
		return
	_damage_tick += delta
	if _damage_tick >= 1.0:
		_damage_tick = 0.0
		for player in _players_inside:
			if is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(int(DAMAGE_PER_SEC), "debris")

## Scattered rock shards + dust motes — reads as a debris field, never a disc.
func _draw() -> void:
	for i in _haze_pos.size():
		var haze := VisualState.col(HAZE_COLOR_SURVEY, HAZE_COLOR_DEAD)
		DrawKit.glow(self, _haze_pos[i], _haze_radius[i], haze)

	for i in _mote_pos.size():
		var mote_col := VisualState.col(MOTE_COLOR_SURVEY, MOTE_COLOR_DEAD)
		mote_col.a *= _mote_weight[i]
		draw_circle(_mote_pos[i], _mote_size[i], mote_col)

	for i in _shard_polys.size():
		var drift := sin(_drift_t * 0.5 + _shard_phase[i]) * _shard_amp[i]
		var offset := Vector2(drift, drift * 0.6)
		var poly := DrawKit.poly_offset(_shard_polys[i], offset)
		var lit_base := SHARD_COLOR_SHADOW if _shard_shadowed[i] else SHARD_COLOR_LIT
		var shard_col := VisualState.col(lit_base, SHARD_COLOR_DEAD)
		draw_colored_polygon(poly, shard_col)
		if _shard_rimmed[i]:
			var rim := SHARD_RIM_DEAD
			rim.a *= VisualState.blend()
			var closed := poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, rim, 0.6)

# ─── Player Detection ────────────────────────────────────────────────────────

func _release_all_players() -> void:
	for body in _players_inside:
		if is_instance_valid(body) and body.has_method("exit_debris"):
			body.exit_debris()
	_players_inside.clear()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_inside.append(body)
		if body.has_method("enter_debris"):
			body.enter_debris()

func _on_body_exited(body: Node2D) -> void:
	if _players_inside.has(body):
		_players_inside.erase(body)
		if body.has_method("exit_debris"):
			body.exit_debris()
