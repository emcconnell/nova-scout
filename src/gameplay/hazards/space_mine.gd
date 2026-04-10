## SpaceMine — Three variants: STANDARD, CLUSTER, RAPID.
## STANDARD / RAPID: erratic sine-drift + lurch + periodic 6-spike bolt burst.
## CLUSTER: drifts only, splits into 3 STANDARD children on death.
## GDD Ref: GAMEPLAY-IMPROVEMENTS-PROPOSAL.md §Change 2
class_name SpaceMine
extends Area2D

enum MineType { STANDARD = 0, CLUSTER = 1, RAPID = 2 }

# ─── Tuning tables (indexed by MineType) ─────────────────────────────────────
const HP_TABLE          := [3,    2,    1   ]
const SCORE_TABLE       := [150,  100,  80  ]
const DRIFT_SPEED_TABLE := [20.0, 18.0, 24.0]
const CHASE_SPEED_TABLE := [95.0, 75.0, 110.0]

const DETECT_RADIUS  := 65.0
const CONTACT_DAMAGE := 35
const BOLT_DAMAGE    := 6
const BOLT_SPEED     := 140.0
const FIRE_BASE      := 3.0    # standard fire interval (seconds)
const FIRE_RAND      := 1.5    # random offset added to interval
const CHARGE_DUR     := 0.4    # pre-shot charge visual duration

# ─── Colors ───────────────────────────────────────────────────────────────────
const COLOR_STANDARD := Color(0.75, 0.18, 0.08)
const COLOR_CLUSTER  := Color(0.40, 0.05, 0.65)
const COLOR_RAPID    := Color(0.85, 0.35, 0.00)
const COLOR_METAL    := Color(0.55, 0.55, 0.60)
const COLOR_LIGHT    := Color(1.0,  0.05, 0.05)
const COLOR_CHARGE   := Color(1.0,  0.50, 0.00)

# ─── State ────────────────────────────────────────────────────────────────────
var mine_type: int = MineType.STANDARD
var _hp: int = 3
var _chasing: bool = false
var _dead: bool = false
var _blink_timer: float = 0.0
var _player_ref: Node2D = null

# Movement
var _sine_phase: float = 0.0
var _sine_freq: float = 3.0
var _sine_amp: float = 25.0
var _lurch_timer: float = 0.0
var _lurch_interval: float = 3.0
var _lurch_vel: Vector2 = Vector2.ZERO

# Shooting (STANDARD and RAPID only)
var _fire_timer: float = 1.0
var _fire_interval: float = 3.5
var _charging: bool = false
var _charge_timer: float = 0.0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hazards")
	# monitoring/monitorable default true — skip explicit set to avoid physics errors
	collision_layer = 16
	collision_mask = 5   # 1=player + 4=player bullets
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

## Call after instantiation to configure mine variant and stagger firing.
func setup(p_type: int = MineType.STANDARD, stagger: int = 0) -> void:
	mine_type       = p_type
	_hp             = HP_TABLE[p_type]
	_sine_freq      = randf_range(2.0, 4.5)
	_sine_amp       = randf_range(18.0, 32.0)
	_sine_phase     = randf_range(0.0, TAU)
	_lurch_interval = randf_range(2.0, 4.0)
	var base: float = FIRE_BASE if p_type != MineType.RAPID else FIRE_BASE * 0.6
	_fire_interval  = base + randf_range(0.0, FIRE_RAND)
	_fire_timer     = _fire_interval * 0.3 + float(stagger) * 0.8

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _dead:
		return
	_blink_timer += delta

	# Entry phase — drop straight in
	if global_position.y < 15.0:
		global_position.y += DRIFT_SPEED_TABLE[mine_type] * 1.5 * delta
		queue_redraw()
		return

	# Off-bottom despawn
	if global_position.y > get_viewport_rect().size.y + 32.0:
		queue_free()
		return

	if _chasing:
		_update_chase(delta)
	else:
		_update_drift(delta)
		_check_detect()

	# Firing (non-cluster)
	if mine_type != MineType.CLUSTER:
		_update_fire(delta)

	queue_redraw()

func _update_drift(delta: float) -> void:
	_sine_phase += _sine_freq * delta
	var lateral: float = cos(_sine_phase) * _sine_amp

	_lurch_timer += delta
	if _lurch_timer >= _lurch_interval:
		_lurch_timer = 0.0
		_lurch_interval = randf_range(2.0, 4.0)
		var a: float = randf_range(0.0, TAU)
		_lurch_vel = Vector2(cos(a), sin(a) * 0.5) * randf_range(55.0, 110.0)
	_lurch_vel = _lurch_vel.lerp(Vector2.ZERO, delta * 3.5)

	var vp := get_viewport_rect()
	global_position.x += lateral * delta + _lurch_vel.x * delta
	global_position.y += DRIFT_SPEED_TABLE[mine_type] * delta + _lurch_vel.y * delta
	global_position.x = clampf(global_position.x, 6.0, vp.size.x - 6.0)

func _update_chase(delta: float) -> void:
	if is_instance_valid(_player_ref):
		var dir := (_player_ref.global_position - global_position).normalized()
		global_position += dir * CHASE_SPEED_TABLE[mine_type] * delta
		if global_position.distance_to(_player_ref.global_position) < 6.0:
			_explode()
	else:
		_chasing = false
		_player_ref = null

func _check_detect() -> void:
	var player := _find_player()
	if player and global_position.distance_to(player.global_position) < DETECT_RADIUS:
		_chasing = true
		_player_ref = player
		AudioManager.play_sfx("mine_armed")

func _update_fire(delta: float) -> void:
	if _charging:
		_charge_timer += delta
		if _charge_timer >= CHARGE_DUR:
			_charging = false
			_charge_timer = 0.0
			_shoot_spikes()
			_fire_timer = _fire_interval
	else:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_charging = true
			_charge_timer = 0.0
			AudioManager.play_sfx("mine_armed")

func _shoot_spikes() -> void:
	var player := _find_player()
	var aim := Vector2.DOWN
	if player:
		aim = (player.global_position - global_position).normalized()
	for i in 6:
		var a: float = TAU / 6.0 * float(i)
		var spike_dir := Vector2(cos(a), sin(a))
		var final_dir := (spike_dir + aim * 0.4).normalized()
		get_tree().call_group("game_world", "spawn_mine_bolt",
			global_position, final_dir, BOLT_DAMAGE)

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

# ─── Draw ──────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var blink_rate: float = 10.0 if (_chasing or _charging) else 3.0
	var blink: bool = sin(_blink_timer * blink_rate) > 0.0

	var body_col: Color = COLOR_STANDARD
	match mine_type:
		MineType.CLUSTER: body_col = COLOR_CLUSTER
		MineType.RAPID:   body_col = COLOR_RAPID

	# Spikes (6 directions) — tip glows orange while charging
	for i in 6:
		var a: float = TAU / 6.0 * float(i)
		var tip := Vector2(cos(a), sin(a))
		var spike_col: Color = COLOR_METAL
		if _charging:
			var t: float = _charge_timer / CHARGE_DUR
			spike_col = COLOR_METAL.lerp(COLOR_CHARGE, t)
		draw_line(tip * 5.0, tip * 9.5, spike_col, 1.5)
		if _charging:
			var ct: float = _charge_timer / CHARGE_DUR
			draw_circle(tip * 9.5, ct * 2.0, COLOR_CHARGE)

	# Body
	draw_circle(Vector2.ZERO, 5.5, body_col)
	draw_circle(Vector2.ZERO, 3.0, Color(body_col.r * 0.5, body_col.g * 0.3, body_col.b * 0.3))

	# Warning light
	if blink:
		draw_circle(Vector2(0.0, -5.5), 1.5, COLOR_LIGHT)
	else:
		draw_circle(Vector2(0.0, -5.5), 1.0, Color(0.4, 0.05, 0.05))

	# Cluster: three small purple dots hinting at split
	if mine_type == MineType.CLUSTER:
		for i in 3:
			var a: float = TAU / 3.0 * float(i) + PI / 6.0
			draw_circle(Vector2(cos(a) * 3.0, sin(a) * 3.0), 1.0, Color(0.8, 0.2, 1.0, 0.7))

# ─── Damage & Destruction ─────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _dead:
		return
	_hp -= amount
	if _hp <= 0:
		_explode()

func _on_area_entered(_area: Area2D) -> void:
	pass  # Laser bolts call take_damage directly

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		call_deferred("_explode")  # Defer: physics callback can't spawn nodes directly

func _explode() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_score(SCORE_TABLE[mine_type])
	GameManager.enemies_destroyed += 1
	GameManager.on_enemy_killed()

	if mine_type == MineType.CLUSTER:
		_spawn_cluster_children()
	else:
		# AoE contact damage
		var player := _find_player()
		if player and global_position.distance_to(player.global_position) < 28.0:
			player.take_damage(CONTACT_DAMAGE, "hull")

	# 40% crystal reward for destroying (Change 7b)
	if randf() < 0.40:
		get_tree().call_group("game_world", "spawn_pickup", global_position, "crystal")

	AudioManager.play_sfx("mine_explode")
	queue_free()

func _spawn_cluster_children() -> void:
	var scene: PackedScene = load("res://scenes/hazards/space_mine.tscn")
	if scene == null:
		return
	var parent := get_parent()
	for i in 3:
		var child := scene.instantiate() as SpaceMine
		var a: float = TAU / 3.0 * float(i) + randf_range(-0.3, 0.3)
		child.position = global_position + Vector2(cos(a), sin(a)) * 8.0
		child.setup(MineType.STANDARD, i)
		child._lurch_vel = Vector2(cos(a), sin(a)) * 30.0
		parent.call_deferred("add_child", child)  # Defer: avoid monitoring-during-physics error
