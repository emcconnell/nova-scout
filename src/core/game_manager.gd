## GameManager — Central state machine and game data hub.
## Autoloaded singleton. All systems reference this for shared state.
extends Node

# ─── Signals ─────────────────────────────────────────────────────────────────
signal state_changed(new_state: GameState)
signal sector_changed(sector: int)
signal beacon_collected(total: int)
signal score_changed(score: int)
signal crystals_changed(crystals: int)
signal streak_changed(streak: int, multiplier: int)
signal danger_pay_changed(active: bool)

# ─── Enums ───────────────────────────────────────────────────────────────────
enum GameState {
	MENU,
	TRAVEL,
	ENCOUNTER,
	STAR_CLUSTER,
	SCANNING,
	ALIEN_COMBAT,
	SECTOR_TRANSITION,
	UPGRADE_SCREEN,
	DEATH,
	WIN
}

# ─── Constants ────────────────────────────────────────────────────────────────
const MAX_SECTORS := 5
const BEACONS_TO_WIN := 3
const VIEWPORT_W := 320
const VIEWPORT_H := 180

# ─── State ───────────────────────────────────────────────────────────────────
var current_state: GameState = GameState.MENU
var current_sector: int = 1
var survey_beacons: int = 0
var mothership_defeated: bool = false
var score: int = 0
var score_multiplier: int = 1
var data_crystals: int = 0

# Player persistent stats (survive sector transitions)
var player_hull: int = 100
var player_shield: int = 60
var player_fuel: int = 100
var player_missiles: int = 6
var player_emp: int = 2
var player_max_hull: int = 100
var player_max_fuel: int = 100
var player_max_missiles: int = 12
var player_max_emp: int = 4
var player_shield_regen: float = 5.0
var player_laser_damage: int = 8
var player_laser_energy: float = 100.0
var player_max_laser_energy: float = 100.0

# Session stats
var enemies_destroyed: int = 0
var stars_scanned: int = 0
var sector_start_time: float = 0.0

# Kill streak (Change 7c)
var kill_streak: int = 0
var streak_multiplier: int = 1
var streak_fuse: float = 0.0        # Seconds left before streak decays (Dark Directive)

# ─── Dark Directive state (see design/gdd/dark-directive.md) ────────────────
var dread: Dictionary = {}          # Balance data loaded from assets/data/dread.json
var danger_pay_active: bool = false # Hull-critical score bonus state
var _threat_sources: Dictionary = {}  # source name -> 0..1 threat level
var log_fragment_index: int = 0     # Cursor into LogFragments.FRAGMENTS (per run)

# ─── References ──────────────────────────────────────────────────────────────
var game_world: Node = null  # Set by GameWorld when it loads

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_dread_config()

func _process(delta: float) -> void:
	# Streak decay fuse — aggression pressure (Dark Directive §4.1)
	if kill_streak > 0 and current_state in [GameState.TRAVEL, GameState.STAR_CLUSTER, GameState.ALIEN_COMBAT]:
		streak_fuse -= delta
		if streak_fuse <= 0.0:
			reset_streak()

## Load Dark Directive balance data; keeps {} on failure (callers use dread_value fallbacks).
func _load_dread_config() -> void:
	var path := "res://assets/data/dread.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		dread = data

## Fetch a nested dread balance value with a safe default, e.g. dread_value("graze", "radius", 6.0).
func dread_value(section: String, key: String, default: Variant) -> Variant:
	var sec: Variant = dread.get(section, {})
	if sec is Dictionary:
		var v: Variant = (sec as Dictionary).get(key, default)
		# JSON numbers arrive as floats; coerce to the default's type
		if typeof(default) == TYPE_INT and typeof(v) == TYPE_FLOAT:
			return int(v)
		if typeof(v) == typeof(default) or default == null:
			return v
	return default

# ─── State Machine ───────────────────────────────────────────────────────────
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)

func is_state(state: GameState) -> bool:
	return current_state == state

# ─── Game Start / Reset ──────────────────────────────────────────────────────
func start_new_game() -> void:
	current_sector = 1
	survey_beacons = 0
	mothership_defeated = false
	score = 0
	score_multiplier = 1
	data_crystals = 0
	enemies_destroyed = 0
	stars_scanned = 0
	kill_streak = 0
	streak_multiplier = 1
	streak_fuse = 0.0
	danger_pay_active = false
	log_fragment_index = 0
	clear_threats()
	_reset_player_stats()
	sector_start_time = Time.get_ticks_msec() / 1000.0

func _reset_player_stats() -> void:
	player_hull = 100
	player_shield = 60
	player_fuel = 100
	player_missiles = 6
	player_emp = 2
	player_max_hull = 100
	player_max_fuel = 100
	player_max_missiles = 12
	player_max_emp = 4
	player_shield_regen = 5.0
	player_laser_damage = 8
	player_laser_energy = 100.0
	player_max_laser_energy = 100.0

func restart_sector() -> void:
	# Reset to sector start stats (partial reset — sector/score preserved)
	player_hull = player_max_hull
	player_shield = 60
	player_fuel = player_max_fuel
	player_missiles = 6
	player_emp = 2
	player_laser_energy = player_max_laser_energy
	score_multiplier = 1
	kill_streak = 0
	streak_multiplier = 1
	streak_fuse = 0.0
	danger_pay_active = false
	clear_threats()

# ─── Score ───────────────────────────────────────────────────────────────────
## Add score with streak multiplier; danger pay (hull-critical bonus) applies
## unless exempt (beacons are exempt — see dark-directive.md §6 Edge Cases).
func add_score(amount: int, danger_exempt: bool = false) -> void:
	var total := amount * score_multiplier
	refresh_danger_pay()
	if danger_pay_active and not danger_exempt:
		total = int(round(total * float(dread_value("danger_pay", "score_multiplier", 1.5))))
	score += total
	score_changed.emit(score)

## Re-evaluate hull-critical danger pay state; emits danger_pay_changed on flip.
func refresh_danger_pay() -> void:
	var threshold: float = float(dread_value("danger_pay", "hull_threshold", 0.25))
	var active := current_state != GameState.MENU \
		and float(player_hull) / maxf(float(player_max_hull), 1.0) < threshold
	if active != danger_pay_active:
		danger_pay_active = active
		danger_pay_changed.emit(active)

func set_multiplier(mult: int) -> void:
	score_multiplier = clampi(mult, 1, 8)

func add_crystal(amount: int = 1) -> void:
	data_crystals += amount
	crystals_changed.emit(data_crystals)

func spend_crystals(amount: int) -> bool:
	if data_crystals >= amount:
		data_crystals -= amount
		crystals_changed.emit(data_crystals)
		return true
	return false

# ─── Beacons & Win ───────────────────────────────────────────────────────────
func collect_beacon() -> void:
	survey_beacons += 1
	beacon_collected.emit(survey_beacons)
	add_score(3000, true)   # Beacons exempt from danger pay (no self-damage cheese)
	if survey_beacons >= BEACONS_TO_WIN:
		# Win triggered by level_design after final escape/boss
		pass

func has_won() -> bool:
	return is_campaign_complete()

## Return true once enough survey beacons have been collected to unlock the finale.
func has_required_beacons() -> bool:
	return survey_beacons >= BEACONS_TO_WIN

## Return true only after the beacon requirement and Mothership defeat are complete.
func is_campaign_complete() -> bool:
	return has_required_beacons() and mothership_defeated

## Mark the final Mothership as defeated; safe to call more than once.
func mark_mothership_defeated() -> void:
	mothership_defeated = true

# ─── Sector Progression ──────────────────────────────────────────────────────
func advance_sector() -> void:
	current_sector += 1
	sector_changed.emit(current_sector)

func is_final_sector() -> bool:
	return current_sector >= MAX_SECTORS

# ─── Upgrades ────────────────────────────────────────────────────────────────
func apply_upgrade(upgrade_id: String) -> bool:
	var cost := _get_upgrade_cost(upgrade_id)
	if not spend_crystals(cost):
		return false
	match upgrade_id:
		"hull":
			player_max_hull += 20
			player_hull = mini(player_hull + 20, player_max_hull)
		"fuel":
			player_max_fuel += 25
			player_fuel = mini(player_fuel + 25, player_max_fuel)
		"shield_regen":
			player_shield_regen += 3.0
		"missiles":
			player_max_missiles += 3
			player_missiles = mini(player_missiles + 3, player_max_missiles)
		"laser":
			player_laser_damage += 4
	return true

func _get_upgrade_cost(upgrade_id: String) -> int:
	match upgrade_id:
		"hull": return 5
		"fuel": return 5
		"shield_regen": return 8
		"missiles": return 8
		"laser": return 10
	return 999

func save_data_on_death() -> void:
	SaveManager.save_high_score(score, current_sector, survey_beacons, "death")

# ─── Sector Intensity (Change 4) ───────────────────────────────────────────
func get_sector_intensity() -> float:
	return 1.0 + float(current_sector - 1) * 0.375

# ─── Kill Streak (Change 7c) ───────────────────────────────────────────────
func on_enemy_killed() -> void:
	kill_streak += 1
	streak_fuse = float(dread_value("streak", "decay_time", 6.0))
	var new_mult: int = 1
	if kill_streak >= 6:
		new_mult = 3
	elif kill_streak >= 3:
		new_mult = 2
	if new_mult != streak_multiplier:
		streak_multiplier = new_mult
		set_multiplier(streak_multiplier)
		# Streak thresholds pay in survivability, not just score — cautious
		# play is literally weaker (dark-directive.md §4.1 / Downwell rule)
		if new_mult > 1:
			var player: Node = game_world.player if game_world != null and "player" in game_world else null
			if player != null and is_instance_valid(player) and player.weapons:
				player.weapons.add_energy(10.0 * float(new_mult - 1))
	streak_changed.emit(kill_streak, streak_multiplier)

func reset_streak() -> void:
	if kill_streak == 0:
		return
	kill_streak = 0
	streak_multiplier = 1
	streak_fuse = 0.0
	set_multiplier(1)
	streak_changed.emit(0, 1)

# ─── Threat level (Dark Directive) ───────────────────────────────────────────
## Report a named threat source's intensity (0..1). CRT interference and audio
## dread read the aggregate via get_threat(). Set 0 to clear a source.
func set_threat(source: String, value: float) -> void:
	if value <= 0.0:
		_threat_sources.erase(source)
	else:
		_threat_sources[source] = clampf(value, 0.0, 1.0)

## Aggregate threat level — the maximum across all active sources.
func get_threat() -> float:
	var m := 0.0
	for v in _threat_sources.values():
		m = maxf(m, float(v))
	return m

## Clear all threat sources (scene reload / new game).
func clear_threats() -> void:
	_threat_sources.clear()

# ─── Helpers ─────────────────────────────────────────────────────────────────
func get_sector_name() -> String:
	match current_sector:
		1: return "ALPHA — INNER RIM"
		2: return "BETA — ASTEROID FIELDS"
		3: return "GAMMA — NEBULA CROSSING"
		4: return "DELTA — ALIEN TERRITORY"
		5: return "EPSILON — THE FRONTIER"
	return "UNKNOWN"
