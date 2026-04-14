## AlienDestroyer — Slow heavy ship with 5 rotating attack patterns.
## Exposed core during 2s pause between patterns = double damage window.
## GDD Ref: enemies.md — Tier 3 Alien Destroyer
class_name AlienDestroyer
extends EnemyBase

# ─── Stats ───────────────────────────────────────────────────────────────────
const BASE_SPEED       := 60.0
const PATTERN_PAUSE    := 2.0    # seconds between patterns (double-damage window)
const SHIELD_PULSE_DUR := 2.0    # seconds of invincibility on pattern 5

# ─── Colors ──────────────────────────────────────────────────────────────────
const COL_HULL    := Color(0.22, 0.00, 0.38)
const COL_ARMOR   := Color(0.35, 0.00, 0.55)
const COL_GLOW    := Color(0.70, 0.00, 0.90, 0.7)
const COL_EXPOSED := Color(0.00, 0.90, 1.00, 0.9)
const COL_SHIELD  := Color(0.30, 0.50, 1.00, 0.35)

# ─── Pattern system ──────────────────────────────────────────────────────────
enum Pattern { PAUSE, SPIRAL, TWIN_BEAM, HOMING, MINE_DROP, SHIELD_PULSE }
var _current_pattern: Pattern = Pattern.PAUSE
var _pattern_index: int = 0
var _pattern_timer: float = 0.0
var _pause_timer: float = PATTERN_PAUSE
var _exposed: bool = true
var _invincible_pulse: bool = false
var _wobble: float = 0.0

# Sub-timers
var _burst_shot_timer: float = 0.0
var _burst_count: int = 0
var _beam_timer: float = 0.0

func _ready() -> void:
	super()
	hp = 200
	max_hp = 200
	contact_damage = 35
	score_value = 800
	drop_table = "destroyer"

func _modify_damage(amount: int, _from: Vector2) -> int:
	if _invincible_pulse:
		return 0
	return amount * 2 if _exposed else amount

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 3.0

	# Slow horizontal drift + entry
	var vp := get_viewport_rect()
	if global_position.y < 55.0:
		global_position.y += BASE_SPEED * delta
	else:
		# Slow sweep
		global_position.x += sin(_wobble * 0.4) * BASE_SPEED * 0.5 * delta
		global_position.x = clampf(global_position.x, 20, vp.size.x - 20)

	match _current_pattern:
		Pattern.PAUSE:
			_exposed = true
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_advance_pattern()

		Pattern.SPIRAL:
			_exposed = false
			_pattern_timer -= delta
			_burst_shot_timer -= delta
			if _burst_shot_timer <= 0.0:
				_burst_shot_timer = 0.06
				_burst_count += 1
				var angle := _burst_count * (TAU / 8.0)
				_fire_bolt(Vector2(cos(angle), sin(angle)), 12, 160, "destroyer")
			if _pattern_timer <= 0.0:
				_start_pause()

		Pattern.TWIN_BEAM:
			_exposed = false
			_pattern_timer -= delta
			_beam_timer -= delta
			if _beam_timer <= 0.0:
				_beam_timer = 0.4
				_fire_bolt(Vector2(-0.15, 1).normalized(), 15, 130, "destroyer")
				_fire_bolt(Vector2(0.15, 1).normalized(), 15, 130, "destroyer")
			if _pattern_timer <= 0.0:
				_start_pause()

		Pattern.HOMING:
			_exposed = false
			_pattern_timer -= delta
			if _pattern_timer <= 0.0:
				# Fire one fast homing bolt via missile-like behavior
				_fire_aimed_homing()
				_start_pause()

		Pattern.MINE_DROP:
			_exposed = false
			_pattern_timer -= delta
			if _pattern_timer <= 0.0:
				_drop_mines()
				_start_pause()

		Pattern.SHIELD_PULSE:
			_exposed = false
			_invincible_pulse = true
			_pattern_timer -= delta
			if _pattern_timer <= 0.0:
				_invincible_pulse = false
				_start_pause()

func _start_pause() -> void:
	_current_pattern = Pattern.PAUSE
	_pause_timer = _scaled_interval(PATTERN_PAUSE)
	_burst_count = 0

func _advance_pattern() -> void:
	_pattern_index = (_pattern_index + 1) % 5
	_pattern_timer = _scaled_interval(3.0)
	_burst_shot_timer = 0.0
	_beam_timer = 0.0
	match _pattern_index:
		0: _current_pattern = Pattern.SPIRAL
		1: _current_pattern = Pattern.TWIN_BEAM
		2: _current_pattern = Pattern.HOMING
		3: _current_pattern = Pattern.MINE_DROP
		4:
			_current_pattern = Pattern.SHIELD_PULSE
			_pattern_timer = SHIELD_PULSE_DUR

func _fire_aimed_homing() -> void:
	# Uses a regular bolt that's fired directly at player with high speed
	var dir := _aim_at_player()
	_fire_bolt(dir, 20, 280, "destroyer")

func _drop_mines() -> void:
	# Signal to game_world to spawn 2 mines
	get_tree().call_group("game_world", "spawn_mine_at", global_position + Vector2(-20, 20))
	get_tree().call_group("game_world", "spawn_mine_at", global_position + Vector2(20, 20))

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull  := Color(1, 1, 1) if flash else COL_HULL
	var armor := COL_ARMOR if not flash else Color(1, 1, 1)
	var dark  := Color(hull.r * 0.5, hull.g * 0.3, hull.b * 0.55)
	var w := _wobble

	# Shield pulse visual (behind everything)
	if _invincible_pulse:
		var sa := 0.15 + 0.1 * sin(w * 4.0)
		draw_circle(Vector2.ZERO, 22.0, Color(COL_SHIELD.r, COL_SHIELD.g, COL_SHIELD.b, sa))
		var sa2 := 0.25 + 0.15 * sin(w * 5.0)
		draw_arc(Vector2.ZERO, 20.0, w * 0.5, w * 0.5 + TAU, 24,
			Color(COL_SHIELD.r, COL_SHIELD.g, COL_SHIELD.b, sa2), 1.5)

	# Rear engine bank glow
	var eng_a := 0.3 + 0.2 * sin(w * 3.0)
	draw_circle(Vector2(0, 14), 10.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, eng_a * 0.3))

	# Main carapace — larger beetle hull with layered segments
	# Segment 1: forward hull (top)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -18), Vector2(8, -18),
		Vector2(12, -8), Vector2(-12, -8)
	]), hull)
	# Segment 2: mid hull (widest)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -8), Vector2(12, -8),
		Vector2(16, 2), Vector2(14, 8),
		Vector2(-14, 8), Vector2(-16, 2)
	]), hull)
	# Segment 3: rear hull
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, 8), Vector2(14, 8),
		Vector2(10, 16), Vector2(-10, 16)
	]), Color(hull.r * 0.8, hull.g * 0.7, hull.b * 0.85))

	# Armor plate lines — segmented panels
	draw_line(Vector2(-11, -8), Vector2(11, -8), armor, 2.0)
	draw_line(Vector2(-15, 2), Vector2(15, 2), armor, 1.5)
	draw_line(Vector2(-13, 8), Vector2(13, 8), armor, 1.5)
	# Vertical panel seams
	for sx in [-6.0, 0.0, 6.0]:
		draw_line(Vector2(sx, -16), Vector2(sx, 14), dark, 1.0)

	# Side hull reinforcement ridges
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 12, -8), Vector2(side * 16, 2),
			Color(armor.r, armor.g, armor.b, 0.6), 1.5)
		draw_line(Vector2(side * 16, 2), Vector2(side * 14, 8),
			Color(armor.r, armor.g, armor.b, 0.6), 1.5)

	# Rotating turret elements (4 turrets, each a small rotating detail)
	for i in 4:
		var tx := -9.0 + float(i) * 6.0
		var ty := -15.0
		var turret_angle := w * 2.0 + float(i) * PI * 0.5
		# Turret base
		draw_circle(Vector2(tx, ty), 2.5, armor)
		# Turret barrel (rotating)
		var bx := cos(turret_angle) * 3.0
		var by := sin(turret_angle) * 3.0
		draw_line(Vector2(tx, ty), Vector2(tx + bx, ty + by), COL_GLOW, 1.5)
		# Turret muzzle glow
		var muzzle_a := 0.4 + 0.3 * sin(w * 3.0 + float(i))
		draw_circle(Vector2(tx + bx, ty + by), 1.2,
			Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, muzzle_a))

	# Side weapon bays — glowing slits
	for side in [-1.0, 1.0]:
		var bay_a := 0.5 + 0.3 * sin(w * 2.0 + side)
		draw_line(Vector2(side * 14, -2), Vector2(side * 14, 5),
			Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, bay_a), 2.0)

	# Glowing underbelly (ventral energy) — wider, layered
	var belly_a := 0.5 + 0.3 * sin(w)
	draw_arc(Vector2(0, 10), 10.0, 0, PI, 16,
		Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, belly_a), 2.0)
	draw_arc(Vector2(0, 10), 12.0, 0.2, PI - 0.2, 12,
		Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, belly_a * 0.4), 1.0)

	# Engine exhausts (3 rear ports)
	for ex in [-6.0, 0.0, 6.0]:
		var flicker := 0.6 + 0.4 * sin(w * 5.0 + ex)
		draw_circle(Vector2(ex, 16), 2.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, flicker))
		var trail := 1.5 + sin(w * 6.0 + ex) * 1.0
		draw_line(Vector2(ex, 16), Vector2(ex, 16 + trail),
			Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, flicker * 0.5), 1.5)

	# Exposed core (double damage window) — pulsing with rings
	if _exposed:
		var pulse: float = 0.6 + 0.4 * abs(sin(w * 2.0))
		# Core outer glow
		draw_circle(Vector2(0, -2), 7.0,
			Color(COL_EXPOSED.r, COL_EXPOSED.g, COL_EXPOSED.b, pulse * 0.25))
		# Core body
		draw_circle(Vector2(0, -2), 5.0,
			Color(COL_EXPOSED.r, COL_EXPOSED.g, COL_EXPOSED.b, pulse))
		# Core hot center
		draw_circle(Vector2(0, -2), 2.5,
			Color(1, 1, 1, pulse * 0.6))
		# Pulsing rings around core
		var ring_a := 0.3 + 0.2 * sin(w * 3.0)
		draw_arc(Vector2(0, -2), 6.0 + sin(w * 2.0) * 1.0, 0, TAU, 16,
			Color(COL_EXPOSED.r, COL_EXPOSED.g, COL_EXPOSED.b, ring_a), 1.0)
		draw_arc(Vector2(0, -2), 8.0 + sin(w * 1.5) * 1.5, 0, TAU, 16,
			Color(COL_EXPOSED.r, COL_EXPOSED.g, COL_EXPOSED.b, ring_a * 0.5), 1.0)

	if _stunned:
		draw_circle(Vector2(0, -20), 2.5, Color(0, 1, 1, 0.9))
