## SpaceMine — Stationary hazard. Detects proximity and chases player.
class_name SpaceMine
extends Area2D

const DETECT_RADIUS := 60.0
const CHASE_SPEED   := 80.0
const DAMAGE        := 35
const SCORE_VALUE   := 75
const HP            := 2
const COLOR_BODY    := Color(0.75, 0.18, 0.08)
const COLOR_METAL   := Color(0.55, 0.55, 0.60)
const COLOR_LIGHT   := Color(1.0, 0.05, 0.05)

var _hp: int = HP
var _chasing: bool = false
var _dead: bool = false
var _blink_timer: float = 0.0
var _player_ref: Node2D = null
var _drift_vel: Vector2 = Vector2(0, 18)   # Drifts into play area

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hazards")
	monitoring = true
	monitorable = true
	collision_layer = 16
	collision_mask = 5   # 1=player + 4=player bullets
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _dead:
		return
	_blink_timer += delta

	# Drift until in play area, then hold position
	if not _chasing and global_position.y < 30.0:
		global_position += _drift_vel * delta

	# Despawn if completely off the bottom
	if global_position.y > get_viewport_rect().size.y + 30:
		queue_free()
		return

	if not _chasing:
		var player := _find_player()
		if player and global_position.distance_to(player.global_position) < DETECT_RADIUS:
			_chasing = true
			_player_ref = player
			AudioManager.play_sfx("mine_armed")
	else:
		if is_instance_valid(_player_ref):
			var dir := (_player_ref.global_position - global_position).normalized()
			global_position += dir * CHASE_SPEED * delta
			if global_position.distance_to(_player_ref.global_position) < 6.0:
				_explode()
		else:
			_chasing = false
			_player_ref = null

	queue_redraw()

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _draw() -> void:
	var blink := sin(_blink_timer * (8.0 if _chasing else 3.0)) > 0.0
	# Spikes (6 directions)
	for i in 6:
		var angle := TAU / 6.0 * i
		var tip := Vector2(cos(angle), sin(angle))
		draw_line(tip * 5.0, tip * 9.0, COLOR_METAL, 1.5)
	# Body
	draw_circle(Vector2.ZERO, 5.5, COLOR_BODY)
	draw_circle(Vector2.ZERO, 3.0, Color(0.4, 0.1, 0.05))
	# Warning light
	if blink or _chasing:
		draw_circle(Vector2(0, -5.5), 1.5, COLOR_LIGHT)
	else:
		draw_circle(Vector2(0, -5.5), 1.0, Color(0.4, 0.05, 0.05))

# ─── Damage & Destruction ─────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _dead:
		return
	_hp -= amount
	if _hp <= 0:
		_explode()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullets"):
		pass  # laser_bolt calls take_damage directly

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_explode()

func _explode() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_score(SCORE_VALUE)
	GameManager.enemies_destroyed += 1
	# AoE damage to nearby player
	var player := _find_player()
	if player and global_position.distance_to(player.global_position) < 32.0:
		player.take_damage(DAMAGE, "hull")
	AudioManager.play_sfx("mine_explode")
	queue_free()
