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

# Session stats
var enemies_destroyed: int = 0
var stars_scanned: int = 0
var sector_start_time: float = 0.0

# Kill streak (Change 7c)
var kill_streak: int = 0
var streak_multiplier: int = 1

# ─── References ──────────────────────────────────────────────────────────────
var game_world: Node = null  # Set by GameWorld when it loads

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
	score = 0
	score_multiplier = 1
	data_crystals = 0
	enemies_destroyed = 0
	stars_scanned = 0
	kill_streak = 0
	streak_multiplier = 1
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

func restart_sector() -> void:
	# Reset to sector start stats (partial reset — sector/score preserved)
	player_hull = player_max_hull
	player_shield = 60
	player_fuel = player_max_fuel
	player_missiles = 6
	player_emp = 2
	score_multiplier = 1
	kill_streak = 0
	streak_multiplier = 1

# ─── Score ───────────────────────────────────────────────────────────────────
func add_score(amount: int) -> void:
	score += amount * score_multiplier
	score_changed.emit(score)

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
	add_score(3000)
	if survey_beacons >= BEACONS_TO_WIN:
		# Win triggered by level_design after final escape/boss
		pass

func has_won() -> bool:
	return survey_beacons >= BEACONS_TO_WIN

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
	var new_mult: int = 1
	if kill_streak >= 6:
		new_mult = 3
	elif kill_streak >= 3:
		new_mult = 2
	if new_mult != streak_multiplier:
		streak_multiplier = new_mult
		set_multiplier(streak_multiplier)
	streak_changed.emit(kill_streak, streak_multiplier)

func reset_streak() -> void:
	if kill_streak == 0:
		return
	kill_streak = 0
	streak_multiplier = 1
	set_multiplier(1)
	streak_changed.emit(0, 1)

# ─── Helpers ─────────────────────────────────────────────────────────────────
func get_sector_name() -> String:
	match current_sector:
		1: return "ALPHA — INNER RIM"
		2: return "BETA — ASTEROID FIELDS"
		3: return "GAMMA — NEBULA CROSSING"
		4: return "DELTA — ALIEN TERRITORY"
		5: return "EPSILON — THE FRONTIER"
	return "UNKNOWN"
