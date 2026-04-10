## ShieldDrone — Orbits Mothership, blocks all damage while alive.
## GDD Ref: enemies.md — Mothership Phase 2
class_name ShieldDrone
extends EnemyBase

const ORBIT_SPEED  := 2.2   # radians/sec
const ORBIT_RADIUS := 45.0
const COL_HULL     := Color(0.20, 0.60, 1.00)
const COL_GLOW     := Color(0.40, 0.80, 1.00, 0.6)

var _parent: Node2D = null
var _angle: float = 0.0
var _wobble: float = 0.0

func _ready() -> void:
	super()
	hp = 80
	max_hp = 80
	contact_damage = 15
	score_value = 200
	drop_table = "shield_drone"
	collision_layer = 2
	collision_mask = 4   # only player bullets

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
	var hull  := Color(1,1,1) if flash else COL_HULL
	draw_circle(Vector2.ZERO, 6.0, hull)
	var ga := 0.4 + 0.4 * sin(_wobble)
	draw_circle(Vector2.ZERO, 9.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, ga))
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 20, Color(COL_HULL.r, COL_HULL.g, COL_HULL.b, 0.4), 1.5)
