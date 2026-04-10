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
	_pause_timer = PATTERN_PAUSE
	_burst_count = 0

func _advance_pattern() -> void:
	_pattern_index = (_pattern_index + 1) % 5
	_pattern_timer = 3.0
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
	var hull  := Color(1,1,1) if flash else COL_HULL
	var armor := COL_ARMOR if not flash else Color(1,1,1)

	# Carapace — beetle shape
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -16), Vector2(10, -16),
		Vector2(14, 0), Vector2(10, 12),
		Vector2(-10, 12), Vector2(-14, 0)
	]), hull)
	# Armor plates
	draw_line(Vector2(-10, -8), Vector2(10, -8), armor, 2.0)
	draw_line(Vector2(-12, 0), Vector2(12, 0), armor, 2.0)
	# Weapon ports
	for i in 4:
		var px := -9.0 + i * 6.0
		draw_circle(Vector2(px, -14), 2.0, COL_GLOW)
	# Glowing underbelly (ventral energy)
	var belly_a := 0.5 + 0.3 * sin(_wobble)
	draw_arc(Vector2(0, 8), 8.0, 0, PI, 12,
		Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, belly_a), 2.0)
	# Exposed core (double damage window)
	if _exposed:
		var pulse: float = 0.6 + 0.4 * abs(sin(_wobble * 2.0))
		draw_circle(Vector2(0, 0), 5.0, Color(COL_EXPOSED.r, COL_EXPOSED.g, COL_EXPOSED.b, pulse))
	# Shield pulse visual
	if _invincible_pulse:
		var sa := 0.3 + 0.2 * sin(_wobble * 4.0)
		draw_circle(Vector2.ZERO, 18.0, Color(COL_SHIELD.r, COL_SHIELD.g, COL_SHIELD.b, sa))
	if _stunned:
		draw_circle(Vector2(0, -18), 2.5, Color(0, 1, 1, 0.9))
