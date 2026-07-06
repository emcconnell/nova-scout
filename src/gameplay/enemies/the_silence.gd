## TheSilence — Cloaked stalker. Sectors 3–5, travel phase.
## Nearly invisible while cruising; telegraphs through the threat tracker,
## CRT interference, and a bass drone. Decloaks for a strafing dive, then
## recloaks. Flees after its attack cycles are spent.
## Balance data: assets/data/dread.json §stalker.
## GDD Ref: dark-directive.md §4.1 The Silence
class_name TheSilence
extends EnemyBase

enum Phase { STALK, TELEGRAPH, ATTACK, RECLOAK, FLEE }

const COL_SHIMMER := Color(0.62, 0.70, 0.78)
const COL_EDGE    := Color(0.55, 0.20, 0.65)
const COL_EYE     := Color(0.95, 0.12, 0.12)
const TELEGRAPH_TIME := 0.85

var _phase: int = Phase.STALK
var _phase_timer: float = 0.0
var _attacks_left: int = 2
var _cloak: float = 1.0          # 1 = fully cloaked, 0 = fully visible
var _drift_target_x: float = 0.0
var _attack_dir: Vector2 = Vector2.DOWN
var _fired_shots: int = 0
var _shimmer: float = 0.0

func _ready() -> void:
	super()
	add_to_group("silence")
	hp = int(GameManager.dread_value("stalker", "hp", 45))
	max_hp = hp
	contact_damage = int(GameManager.dread_value("stalker", "contact_damage", 14))
	score_value = int(GameManager.dread_value("stalker", "score", 600))
	drop_table = "elite"
	_attacks_left = int(GameManager.dread_value("stalker", "attack_cycles", 2))
	_phase_timer = _roll_attack_interval()
	_drift_target_x = randf_range(40.0, GameManager.VIEWPORT_W - 40.0)
	AudioManager.play_sfx("stalker_drone", 0.55)

func _exit_tree() -> void:
	GameManager.set_threat("stalker", 0.0)

func _roll_attack_interval() -> float:
	return randf_range(
		float(GameManager.dread_value("stalker", "attack_interval_min", 7.0)),
		float(GameManager.dread_value("stalker", "attack_interval_max", 10.0)))

func _update(delta: float) -> void:
	if _stunned:
		return
	_shimmer += delta
	match _phase:
		Phase.STALK:     _update_stalk(delta)
		Phase.TELEGRAPH: _update_telegraph(delta)
		Phase.ATTACK:    _update_attack(delta)
		Phase.RECLOAK:   _update_recloak(delta)
		Phase.FLEE:      _update_flee(delta)

func _update_stalk(delta: float) -> void:
	_cloak = minf(_cloak + delta * 1.5, 1.0)
	var cruise: float = float(GameManager.dread_value("stalker", "cruise_speed", 55.0))
	# Loiter in the top third, sliding toward a drift target
	global_position.x = move_toward(global_position.x, _drift_target_x, cruise * delta)
	global_position.y = move_toward(global_position.y, 34.0, cruise * 0.6 * delta)
	if absf(global_position.x - _drift_target_x) < 4.0:
		_drift_target_x = randf_range(30.0, GameManager.VIEWPORT_W - 30.0)

	_phase_timer -= delta
	# Threat swells as the attack approaches — the room gets colder
	var interval_max: float = float(GameManager.dread_value("stalker", "attack_interval_max", 10.0))
	GameManager.set_threat("stalker", clampf(1.0 - _phase_timer / interval_max, 0.15, 0.85))
	if _phase_timer <= 0.0:
		_phase = Phase.TELEGRAPH
		_phase_timer = TELEGRAPH_TIME
		# The mix drops out just before contact — silence is the alarm
		AudioManager.duck_music(3.5)
		AudioManager.play_sfx("stalker_decloak", 0.85)
		GameManager.set_threat("stalker", 1.0)
		get_tree().call_group("crt_overlay", "pulse_signal_roll", 0.9)

func _update_telegraph(delta: float) -> void:
	_cloak = maxf(_cloak - delta / TELEGRAPH_TIME, 0.15)
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.ATTACK
		_phase_timer = float(GameManager.dread_value("stalker", "attack_window", 2.2))
		_attack_dir = _aim_at_player()
		_fired_shots = 0

func _update_attack(delta: float) -> void:
	_cloak = maxf(_cloak - delta * 4.0, 0.0)
	var speed: float = float(GameManager.dread_value("stalker", "attack_speed", 240.0))
	global_position += _attack_dir * speed * delta
	_phase_timer -= delta
	# Two snapped shots during the dive
	var window: float = float(GameManager.dread_value("stalker", "attack_window", 2.2))
	if _fired_shots == 0 and _phase_timer < window * 0.8:
		_fire_bolt(_aim_at_player(), int(GameManager.dread_value("stalker", "bolt_damage", 12)), 260.0, "warrior")
		_fired_shots = 1
	elif _fired_shots == 1 and _phase_timer < window * 0.45:
		_fire_bolt(_aim_at_player(), int(GameManager.dread_value("stalker", "bolt_damage", 12)), 260.0, "warrior")
		_fired_shots = 2
	# Curve back upward at the end of the window
	if _phase_timer < window * 0.35:
		_attack_dir = _attack_dir.lerp(Vector2.UP, delta * 3.0).normalized()
	if _phase_timer <= 0.0:
		_attacks_left -= 1
		_phase = Phase.FLEE if _attacks_left <= 0 else Phase.RECLOAK
		_phase_timer = _roll_attack_interval()
	# Keep in horizontal bounds during the dive
	global_position.x = clampf(global_position.x, 8.0, GameManager.VIEWPORT_W - 8.0)

func _update_recloak(delta: float) -> void:
	_cloak = minf(_cloak + delta * 2.0, 1.0)
	global_position.y = move_toward(global_position.y, 26.0, 90.0 * delta)
	if _cloak >= 1.0 and global_position.y <= 40.0:
		_phase = Phase.STALK
		GameManager.set_threat("stalker", 0.2)

func _update_flee(delta: float) -> void:
	_cloak = minf(_cloak + delta * 1.2, 1.0)
	global_position.y -= 120.0 * delta
	GameManager.set_threat("stalker", maxf(0.0, _cloak - 0.4))
	if global_position.y < -40.0:
		GameManager.set_threat("stalker", 0.0)
		queue_free()

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super(amount, from_position)
	if not _dead and _phase == Phase.STALK:
		# Getting shot while cloaked provokes it
		_phase_timer = minf(_phase_timer, 1.2)

func _die() -> void:
	GameManager.set_threat("stalker", 0.0)
	super()

func _draw() -> void:
	var vis := 1.0 - _cloak
	var flash := _hit_flash_timer > 0.0
	# Even fully cloaked: a heat-haze shimmer, 2–8% alpha
	var shimmer_a := 0.02 + 0.06 * (0.5 + 0.5 * sin(_shimmer * 7.0)) + vis * 0.75
	if flash:
		shimmer_a = 0.9

	# Jagged asymmetric silhouette — deliberately wrong geometry
	var body := PackedVector2Array([
		Vector2(0, -11), Vector2(7, -3), Vector2(12, 2), Vector2(5, 4),
		Vector2(8, 10), Vector2(0, 6), Vector2(-9, 11), Vector2(-5, 3),
		Vector2(-12, 1), Vector2(-6, -4),
	])
	var hull_col := Color(0.04, 0.03, 0.06, shimmer_a)
	if flash:
		hull_col = Color(1, 1, 1, 0.9)
	draw_colored_polygon(body, hull_col)
	# Violet edge trace — only reads when partially decloaked
	if vis > 0.05 or flash:
		var edge_a := clampf(vis * 0.8 + (0.3 if flash else 0.0), 0.0, 0.9)
		for i in body.size():
			draw_line(body[i], body[(i + 1) % body.size()],
				Color(COL_EDGE.r, COL_EDGE.g, COL_EDGE.b, edge_a), 0.8)
	# Single eye — the last thing to disappear
	var eye_a := clampf(0.12 + vis * 0.9, 0.0, 1.0)
	draw_circle(Vector2(1, -2), 1.4, Color(COL_EYE.r, COL_EYE.g, COL_EYE.b, eye_a * 0.4))
	draw_circle(Vector2(1, -2), 0.8, Color(COL_EYE.r, COL_EYE.g, COL_EYE.b, eye_a))
	_draw_hit_flash()
