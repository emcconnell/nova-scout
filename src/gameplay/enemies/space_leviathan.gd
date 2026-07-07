## SpaceLeviathan — Organic tentacled space creature.
## Drifts in from screen edge, extends tentacles toward player.
## If tentacles grab player, crushes for continuous damage until shot free.
## Bleeds purple on every hit. Drops generous loot.
class_name SpaceLeviathan
extends EnemyBase

# ─── Stats ───────────────────────────────────────────────────────────────────
const BASE_HP       := 60
const ATTACHED_HP_MULT := 5   # 5x harder to remove once attached (300 HP)
const GRAB_DAMAGE   := 4      # damage per 0.3s while attached
const GRAB_INTERVAL := 0.3
const TENTACLE_REACH := 55.0
const GRAB_RANGE    := 18.0   # distance to start grab (tentacles)
const BODY_SPEED    := 22.0
const PURSUE_SPEED  := 40.0

# ─── Colors ──────────────────────────────────────────────────────────────────
# Tentacle/blood keep their own organic-purple identity (distinct from the
# shared chitin ramp) — the beast bleeds, it doesn't glow like the drones.
const COL_TENTACLE := Color(0.35, 0.12, 0.45)
const COL_TENT_TIP := Color(0.50, 0.20, 0.60)
const COL_BLOOD    := Color(0.55, 0.05, 0.70)
const COL_BLOOD_LT := Color(0.75, 0.15, 0.90)

# ─── State ───────────────────────────────────────────────────────────────────
var _wobble: float = 0.0
var _phase: float = 0.0
var _grabbing: bool = false
var _attached: bool = false    # physically latched onto player hull
var _grab_timer: float = 0.0
var _entry_done: bool = false
var _target_x: float = 160.0
var _attached_player: Node2D = null

# Tentacle positions (relative to body, animated)
var _tentacles: Array[Dictionary] = []
const NUM_TENTACLES := 6

# Blood splatter particles
var _blood_particles: Array[Dictionary] = []
var _flecks: Array[Vector3] = []      # seeded chitin flecks (TURN 4)
var _eye_dots: Array = []             # seeded eye cluster (dead frequency)

func _ready() -> void:
	super()
	hp = BASE_HP
	max_hp = BASE_HP
	contact_damage = 15
	score_value = 300
	drop_table = "leviathan"
	collision_layer = 2
	collision_mask = 5
	_flecks = EnemyRenderer.seed_flecks(get_instance_id(), 30, Vector2(9, 6))
	_eye_dots = [Vector3(0, 0, 2.2)]

	# Initialize tentacles
	for i in NUM_TENTACLES:
		var side := -1.0 if i < NUM_TENTACLES / 2 else 1.0
		var idx := i % (NUM_TENTACLES / 2)
		_tentacles.append({
			"base_angle": side * (0.3 + idx * 0.4) + PI * 0.5,
			"length": randf_range(20.0, 30.0),
			"phase": randf_range(0.0, TAU),
			"grab_extend": 0.0,
		})

## Override contact — attach to player hull instead of just dealing damage.
func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("player") and not _attached:
		_attach_to_hull(body)

func _attach_to_hull(player: Node2D) -> void:
	_attached = true
	_grabbing = true
	_attached_player = player
	_grab_timer = GRAB_INTERVAL
	# Multiply HP — much harder to remove once attached
	hp = hp * ATTACHED_HP_MULT
	max_hp = hp
	AudioManager.play_sfx("hull_hit")
	# Initial contact damage
	player.take_damage(contact_damage, "hull")

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 3.0
	_phase += delta

	var vp := get_viewport_rect()
	var player := _get_player()

	# === ATTACHED MODE — locked onto player hull ===
	if _attached:
		if not is_instance_valid(_attached_player):
			_attached = false
			_grabbing = false
		else:
			# Follow player with slight offset
			global_position = _attached_player.global_position + Vector2(0, -8)
			# Continuous drain
			_grab_timer -= delta
			if _grab_timer <= 0.0:
				_grab_timer = GRAB_INTERVAL
				_attached_player.take_damage(GRAB_DAMAGE, "hull")
			# All tentacles fully extended/wrapping
			for t in _tentacles:
				t["phase"] += delta * 4.0
				t["grab_extend"] = 1.0
		_update_blood(delta)
		return

	# === FREE-FLOATING MODE ===
	# Entry phase
	if not _entry_done:
		global_position.y += BODY_SPEED * 1.5 * delta
		if global_position.y >= 40.0:
			_entry_done = true
		_update_blood(delta)
		return

	# Pursue player slowly
	if is_instance_valid(player):
		_target_x = player.global_position.x
		var dir_to_player := (player.global_position - global_position).normalized()
		global_position += dir_to_player * PURSUE_SPEED * delta

	# Clamp to screen
	global_position.x = clampf(global_position.x, 20, vp.size.x - 20)
	global_position.y = clampf(global_position.y, 20, vp.size.y * 0.6)

	# Body bob
	global_position.y += sin(_wobble) * 8.0 * delta

	# Update tentacles
	_update_tentacles(delta, player)

	# Tentacle grab (proximity, not contact)
	if _grabbing and is_instance_valid(player):
		_grab_timer -= delta
		if _grab_timer <= 0.0:
			_grab_timer = GRAB_INTERVAL
			player.take_damage(GRAB_DAMAGE, "hull")
		var hold_pos := global_position + Vector2(0, 20)
		var pull := (hold_pos - player.global_position).normalized() * 200.0
		if player.has_method("apply_external_force"):
			player.apply_external_force(pull * delta)

	# Despawn if off bottom
	if global_position.y > vp.size.y + 40:
		queue_free()

	_update_blood(delta)

func _update_tentacles(delta: float, player: Node2D) -> void:
	var player_local := Vector2.ZERO
	var player_dist := 999.0
	if is_instance_valid(player):
		player_local = player.global_position - global_position
		player_dist = player_local.length()

	for t in _tentacles:
		t["phase"] += delta * 2.5

		if _grabbing:
			# Tentacles wrap toward player
			t["grab_extend"] = minf(t["grab_extend"] + delta * 3.0, 1.0)
		elif player_dist < TENTACLE_REACH * 1.5:
			# Reach toward player
			t["grab_extend"] = minf(t["grab_extend"] + delta * 2.0, 0.7)
		else:
			t["grab_extend"] = maxf(t["grab_extend"] - delta * 2.0, 0.0)

	# Check for grab initiation
	if not _grabbing and is_instance_valid(player) and player_dist < GRAB_RANGE:
		_grabbing = true
		_grab_timer = GRAB_INTERVAL
		AudioManager.play_sfx("hull_hit")

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	# Spawn blood splatter on every hit — extra blood when attached
	var blood_count := randi_range(6, 12) if _attached else randi_range(4, 8)
	_spawn_blood_count(from_position if from_position != Vector2.ZERO else global_position, blood_count)
	# Release tentacle grab (not attachment) if free-floating
	if _grabbing and not _attached and randf() < 0.35:
		_grabbing = false
	super(amount, from_position)

func _spawn_blood_count(hit_pos: Vector2, count: int) -> void:
	var local_hit := hit_pos - global_position
	for i in count:
		var angle := randf_range(0, TAU)
		var speed := randf_range(20, 60)
		_blood_particles.append({
			"x": local_hit.x + randf_range(-3, 3),
			"y": local_hit.y + randf_range(-3, 3),
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"life": 0.0,
			"max_life": randf_range(0.4, 0.9),
			"size": randf_range(1.0, 3.0),
			"color": COL_BLOOD.lerp(COL_BLOOD_LT, randf()),
		})

func _update_blood(delta: float) -> void:
	var i := _blood_particles.size() - 1
	while i >= 0:
		var p: Dictionary = _blood_particles[i]
		p["life"] += delta
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vx"] *= 0.92
		p["vy"] *= 0.92
		if float(p["life"]) >= float(p["max_life"]):
			_blood_particles.remove_at(i)
		i -= 1

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var lit := _lit_factor()
	var eye_col := VisualState.col(Color("B03BFF"), Color("FF2A3C")).lerp(Color("FF6A70"), lit)

	# ─── Blood particles (behind body) — organic, keeps its own purple ──
	for p in _blood_particles:
		var pct: float = float(p["life"]) / float(p["max_life"])
		var alpha := (1.0 - pct)
		var sz: float = float(p["size"]) * (1.0 - pct * 0.5)
		var col: Color = Color(p["color"])
		# Splatter shape — irregular
		draw_circle(Vector2(float(p["x"]), float(p["y"])), sz,
			Color(col.r, col.g, col.b, alpha * 0.8))
		# Bright core
		if sz > 1.5:
			draw_circle(Vector2(float(p["x"]), float(p["y"])), sz * 0.4,
				Color(col.r * 1.3, col.g * 0.5, col.b * 1.3, alpha * 0.5))

	# ─── Tentacles (behind body) ─────────────────────────────────────
	var player := _get_player()
	var player_local := Vector2.ZERO
	if is_instance_valid(player):
		player_local = player.global_position - global_position

	for t in _tentacles:
		var base_a: float = t["base_angle"]
		var length: float = t["length"]
		var phase: float = t["phase"]
		var grab_ext: float = t["grab_extend"]

		# Tentacle as 3-segment bezier-ish chain
		var wave := sin(phase) * 0.3
		var seg1_angle := base_a + wave
		var seg1_end := Vector2(cos(seg1_angle), sin(seg1_angle)) * length * 0.4

		# If extending toward player, bend toward them
		var target_dir := seg1_end.normalized()
		if grab_ext > 0.0 and player_local.length() > 1.0:
			target_dir = target_dir.lerp(player_local.normalized(), grab_ext * 0.6)
		var seg2_end := seg1_end + target_dir * length * 0.35
		var seg3_end := seg2_end + target_dir * length * (0.25 + grab_ext * 0.3)

		# Draw segments with decreasing width
		var tcol := Color(1, 1, 1) if flash else COL_TENTACLE
		draw_line(Vector2.ZERO, seg1_end, tcol, 2.5)
		draw_line(seg1_end, seg2_end, tcol, 1.8)
		var tip_col := Color(1, 1, 1) if flash else COL_TENT_TIP
		draw_line(seg2_end, seg3_end, tip_col, 1.2)

		# Suction cups
		for si in 3:
			var sp := float(si + 1) / 4.0
			var spos := seg1_end.lerp(seg2_end, sp)
			draw_circle(spos, 1.0, Color(COL_TENT_TIP.r, COL_TENT_TIP.g, COL_TENT_TIP.b, 0.5))

		# Grabbing glow at tips
		if _grabbing:
			var ga := 0.3 + 0.3 * sin(_wobble * 5.0)
			draw_circle(seg3_end, 3.0, Color(eye_col.r, eye_col.g, eye_col.b, ga))

	# ─── Main body — organic blob, retextured to the shared chitin ramp ──
	var hi := EnemyRenderer.body_stop(0, lit)
	var mid := EnemyRenderer.body_stop(1, lit)
	var body_col := Color(1, 1, 1) if flash else hi
	var lit_col := Color(1, 1, 1) if flash else mid

	# Body: organic irregular shape
	var body_pts := PackedVector2Array()
	for bi in 12:
		var a := TAU / 12.0 * bi
		var r := 10.0 + 2.0 * sin(_wobble + bi * 1.3)
		body_pts.append(Vector2(cos(a) * r, sin(a) * r * 0.7))
	draw_colored_polygon(body_pts, body_col)

	# Inner membrane
	var inner_pts := PackedVector2Array()
	for bi in 12:
		var a := TAU / 12.0 * bi
		var r := 6.0 + 1.5 * sin(_wobble * 1.5 + bi * 1.1)
		inner_pts.append(Vector2(cos(a) * r, sin(a) * r * 0.65))
	draw_colored_polygon(inner_pts, lit_col)

	# Seeded chitin flecks over the hide
	EnemyRenderer.draw_flecks(self, _flecks, lit)

	# Pulsing veins — magenta bioluminescence, dies with blend
	var vein_a := (0.3 + 0.2 * sin(_wobble * 2.0)) * (1.0 - VisualState.blend() * 0.5)
	for vi in 4:
		var va := TAU / 4.0 * vi + _wobble * 0.2
		var vstart := Vector2(cos(va) * 4.0, sin(va) * 3.0)
		var vend := Vector2(cos(va) * 9.0, sin(va) * 6.0)
		draw_line(vstart, vend, Color(eye_col.r, eye_col.g, eye_col.b, vein_a), 1.0)
	EnemyRenderer.dead_vein_line(self, Vector2(-8, 5), Vector2(8, 5))

	if lit > 0.01:
		EnemyRenderer.lit_rim_stroke(self, body_pts, lit)

	# ─── Eye — central glowing eye, tracks player, always visible ────
	draw_circle(Vector2.ZERO, 4.0, Color(0.15, 0.05, 0.20))
	var eye_offset := Vector2.ZERO
	if is_instance_valid(player):
		eye_offset = player_local.normalized() * 1.5
	draw_circle(eye_offset, 2.5, eye_col)
	draw_circle(eye_offset, 1.2, Color(1.0, 0.9, 0.3))
	# Eye glow
	var eg := 0.3 + 0.2 * sin(_wobble * 3.0)
	DrawKit.glow(self, eye_offset, 5.0, Color(eye_col.r, eye_col.g, eye_col.b, eg * 0.5), 3)

	# ─── Grab warning ────────────────────────────────────────────────
	if _grabbing:
		var warn_a := 0.15 + 0.15 * sin(_wobble * 6.0)
		draw_arc(Vector2.ZERO, 15.0, 0, TAU, 16,
			Color(eye_col.r, eye_col.g, eye_col.b, warn_a), 1.0)

	# ─── Stun indicator ──────────────────────────────────────────────
	if _stunned:
		draw_circle(Vector2(0, -14), 2.5, Color(0.0, 1.0, 1.0, 0.8))
	_draw_hit_flash()
