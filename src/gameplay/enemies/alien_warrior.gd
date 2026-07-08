## AlienWarrior — Deliberate diagonal sweeper. Front-shield reduces damage from below.
## 3-shot burst every 2s. Tries to position above player.
## GDD Ref: enemies.md — Tier 2 Alien Warrior
class_name AlienWarrior
extends EnemyBase

# ─── Stats (from enemies.md) ─────────────────────────────────────────────────
const BASE_SPEED      := 140.0
const FIRE_INTERVAL   := 2.0
const BURST_COUNT     := 3
const BURST_DELAY     := 0.12
const BOLT_DAMAGE     := 10
const BOLT_SPEED      := 200.0
const FRONT_SHIELD_REDUCTION := 0.5   # 50% damage from front

# ─── Colors (art bible — TURN 4 biomech, see EnemyRenderer for shared ramps) ──
const COL_ENGINE := Color(0.60, 0.00, 0.90, 0.7)
const COL_SHIELD_INDICATOR := Color(0.00, 0.80, 1.00, 0.45)

# ─── State ───────────────────────────────────────────────────────────────────
enum Phase { ENTRY, SWEEP_RIGHT, SWEEP_LEFT, REPOSITION }
var _phase: Phase = Phase.ENTRY
var _fire_timer: float = 1.2
var _burst_queue: int = 0
var _burst_timer: float = 0.0
var _sweep_dir: float = 1.0   # +1 = right, -1 = left
var _wobble: float = 0.0
var _eye_dots: Array = []             # seeded head eye cluster (dead frequency)

# ─── Textured body (art bible v4.0 "Textured Light") ────────────────────────
var _body: Sprite2D = null

func _ready() -> void:
	super()
	hp = 60
	max_hp = 60
	contact_damage = 20
	score_value = 300
	drop_table = "warrior"
	_sweep_dir = 1.0 if randf() > 0.5 else -1.0
	_body = TextureKit.creature_body(self, "enemies", "warrior")
	_eye_dots = [
		Vector3(-5, -13, 1.1), Vector3(5, -13, 1.1), Vector3(-8, -10, 0.8),
		Vector3(8, -10, 0.8), Vector3(-2.5, -15, 0.85), Vector3(2.5, -15, 0.85),
		Vector3(0, -11, 1.55),
	]

func _modify_damage(amount: int, from_pos: Vector2) -> int:
	# Half damage if attack comes from below (front shield)
	if from_pos != Vector2.ZERO and from_pos.y > global_position.y:
		return int(amount * FRONT_SHIELD_REDUCTION)
	return amount

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 4.0

	var vp := get_viewport_rect()

	match _phase:
		Phase.ENTRY:
			global_position.y += BASE_SPEED * 0.7 * delta
			if global_position.y >= 45.0:
				_phase = Phase.SWEEP_RIGHT if _sweep_dir > 0 else Phase.SWEEP_LEFT

		Phase.SWEEP_RIGHT:
			global_position.x += BASE_SPEED * delta
			global_position.y += 15.0 * delta   # slight downward drift
			if global_position.x > vp.size.x - 20:
				_sweep_dir = -1.0
				_phase = Phase.SWEEP_LEFT

		Phase.SWEEP_LEFT:
			global_position.x -= BASE_SPEED * delta
			global_position.y += 15.0 * delta
			if global_position.x < 20:
				_sweep_dir = 1.0
				_phase = Phase.SWEEP_RIGHT

	# Despawn off bottom
	if global_position.y > vp.size.y + 30:
		queue_free()
		return

	# Burst firing
	if _burst_queue > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = BURST_DELAY
			_burst_queue -= 1
			var spread := (_burst_queue - 1) * 0.25
			_fire_bolt(_aim_at_player().rotated(spread), BOLT_DAMAGE, BOLT_SPEED, "warrior")
			AudioManager.play_sfx("enemy_laser")
	else:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = _scaled_interval(FIRE_INTERVAL) + randf_range(-0.4, 0.4)
			_burst_queue = BURST_COUNT
			_burst_timer = 0.0

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var w := _wobble
	var lit := _lit_factor()
	var blend := VisualState.blend()
	TextureKit.set_flash(_body, 1.0 if flash else 0.0)

	# Under-halo behind the pod
	EnemyRenderer.under_halo(self, Vector2(0, 10), 22.0)

	# Hull ramp low-stop — feeds the engine nacelle glow tint below
	var lo := EnemyRenderer.body_stop(2, lit)
	if flash:
		lo = Color(1, 1, 1)

	# Warm lit-rim stroke down the left silhouette (beam-lit only)
	if lit > 0.01:
		var rim_pts := PackedVector2Array([
			Vector2(0, 46), Vector2(-16, 22), Vector2(-20, -20), Vector2(0, -46),
		])
		EnemyRenderer.lit_rim_stroke(self, rim_pts, lit)

	# Central vein / node dots — magenta in SURVEY, dies to deep-red in DEAD
	var vein_fade := 1.0 - blend
	if vein_fade > 0.01:
		EnemyRenderer.magenta_vein(self, Vector2(0, -16), Vector2(0, 34))
		var node_col := Color("D46CFF")
		for yy in [-6.0, 8.0, 22.0]:
			draw_circle(Vector2(0, yy), 1.5, Color(node_col.r, node_col.g, node_col.b, vein_fade))
		# Forward eye dots
		var eye_col := Color("FF3DDC")
		for ex in [-4.0, 4.0]:
			DrawKit.glow(self, Vector2(ex, -30), 3.5, Color(eye_col.r, eye_col.g, eye_col.b, 0.3 * vein_fade), 2)
			draw_circle(Vector2(ex, -30), 1.7, Color(eye_col.r, eye_col.g, eye_col.b, vein_fade))
			draw_rect(Rect2(ex - 0.45, -30.8, 0.9, 0.9), Color(1, 1, 1, 0.8 * vein_fade))
	# Deep-red faint vein line + 7-dot red eye cluster (wakes with blend)
	EnemyRenderer.dead_vein_line(self, Vector2(0, -12), Vector2(0, 30))
	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [0, 1, 6])

	# Weapon ports on fin tips (kept from original armored silhouette read)
	for side in [-1.0, 1.0]:
		var port_pos := Vector2(side * 14, 1)
		draw_circle(port_pos, 2.0, Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, 0.35 * (1.0 - blend * 0.5)))

	# Engine nacelles — dual layered with exhaust flicker (kept, tinted by lo ramp)
	for side in [-1.0, 1.0]:
		var eng_pos := Vector2(side * 5.5, 34)
		var eng_a := 0.5 + 0.3 * sin(w * 4.0 + side * 2.0)
		draw_circle(eng_pos, 3.5, Color(lo.r, lo.g, lo.b, eng_a * 0.4))
		draw_circle(eng_pos, 2.5, Color(lo.r * 1.4 + 0.1, lo.g * 1.4 + 0.1, lo.b * 1.4 + 0.1, 0.8))
		var trail_len := 2.0 + 1.5 * sin(w * 6.0 + side)
		draw_line(eng_pos, eng_pos + Vector2(0, trail_len), Color(lo.r, lo.g, lo.b, 0.5), 1.5)

	# Front shield indicator (bottom face) — layered arcs, unchanged (HUD-tint blue)
	draw_arc(Vector2(0, 40), 9.0, 0.0, PI, 16, COL_SHIELD_INDICATOR, 1.0)
	var shield_a := 0.35 + 0.15 * sin(w * 2.0)
	draw_arc(Vector2(0, 40), 11.0, 0.15, PI - 0.15, 16,
		Color(COL_SHIELD_INDICATOR.r, COL_SHIELD_INDICATOR.g, COL_SHIELD_INDICATOR.b, shield_a), 1.0)

	# Stun
	if _stunned:
		draw_circle(Vector2(0, -46), 2.0, Color(0.0, 1.0, 1.0, 0.8))
	_draw_hit_flash()
