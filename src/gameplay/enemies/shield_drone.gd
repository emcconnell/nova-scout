## ShieldDrone — Orbits Mothership, blocks all damage while alive.
## GDD Ref: enemies.md — Mothership Phase 2
class_name ShieldDrone
extends EnemyBase

const ORBIT_SPEED  := 2.2   # radians/sec
const ORBIT_RADIUS := 45.0
const COL_SHIELD_GLOW := Color(0.40, 0.80, 1.00, 0.6)   # shield-tech tell, not biomech

var _parent: Node2D = null
var _angle: float = 0.0
var _wobble: float = 0.0
var _eye_dots: Array = []   # seeded eye cluster (dead frequency)

func _ready() -> void:
	super()
	hp = 80
	max_hp = 80
	contact_damage = 15
	score_value = 200
	drop_table = "shield_drone"
	collision_layer = 2
	collision_mask = 4   # only player bullets
	_eye_dots = [Vector3(0, -1, 1.4)]

func attach_to(parent: Node2D) -> void:
	_parent = parent
	_angle = randf_range(0, TAU)

func _update(delta: float) -> void:
	_wobble += delta * 6.0
	if is_instance_valid(_parent):
		_angle += ORBIT_SPEED * delta
		global_position = _parent.global_position + \
			Vector2(cos(_angle), sin(_angle)) * ORBIT_RADIUS
	else:
		queue_free()

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var lit := _lit_factor()
	var hull := EnemyRenderer.body_stop(0, lit)
	if flash:
		hull = Color(1, 1, 1)
	draw_circle(Vector2.ZERO, 6.0, hull)
	# Shield-tech glow ring — a Mothership system, kept blue (not biomech)
	var ga := 0.4 + 0.4 * sin(_wobble)
	draw_circle(Vector2.ZERO, 9.0, Color(COL_SHIELD_GLOW.r, COL_SHIELD_GLOW.g, COL_SHIELD_GLOW.b, ga))
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 20, Color(COL_SHIELD_GLOW.r, COL_SHIELD_GLOW.g, COL_SHIELD_GLOW.b, 0.4), 1.5)
	# Single eye wakes in dead frequency (combat readability)
	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [0])
	_draw_hit_flash()
