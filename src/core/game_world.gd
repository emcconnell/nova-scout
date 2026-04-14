## GameWorld — Main gameplay scene. Orchestrates all systems.
## Travel → Star Cluster → Alien Combat → Sector Transition loop.
## GDD Ref: gameplay-mechanics.md §3–5
class_name GameWorld
extends Node2D

# ─── Child nodes ──────────────────────────────────────────────────────────────
@onready var player: Player                   = $Player
@onready var hazards_node: Node2D             = $Hazards
@onready var projectiles_node: Node2D         = $Projectiles
@onready var pickups_node: Node2D             = $Pickups
@onready var enemies_node: Node2D             = $Enemies
@onready var enemy_projectiles_node: Node2D   = $EnemyProjectiles
@onready var stars_node: Node2D               = $Stars
@onready var hud_display                      = $HUD/HUDDisplay
@onready var scan_bar_ui                      = $HUD/ScanBar
@onready var pause_menu_ui                    = $PauseMenu
@onready var death_screen_ui                  = $DeathScreen
@onready var upgrade_screen_ui                = $UpgradeScreen
@onready var sector_transition_ui             = $SectorTransition
@onready var win_screen_ui                    = $WinScreen

# ─── Preloaded scenes ─────────────────────────────────────────────────────────
const LaserBoltScene    = preload("res://scenes/projectiles/laser_bolt.tscn")
const MissileScene      = preload("res://scenes/projectiles/missile.tscn")
const AsteroidScene     = preload("res://scenes/hazards/asteroid.tscn")
const SpaceMineScene    = preload("res://scenes/hazards/space_mine.tscn")
const DebrisCloudScene  = preload("res://scenes/hazards/debris_cloud.tscn")
const DerelictShipScene = preload("res://scenes/hazards/derelict_ship.tscn")
const PickupScene       = preload("res://scenes/pickups/pickup.tscn")
const ScorePopupScene   = preload("res://scenes/ui/score_popup.tscn")
const EnemyScoutScene          = preload("res://scenes/enemies/alien_scout.tscn")
const EnemyWarriorScene        = preload("res://scenes/enemies/alien_warrior.tscn")
const EnemyDestroyerScene      = preload("res://scenes/enemies/alien_destroyer.tscn")
const EnemyEliteInterceptor    = preload("res://scenes/enemies/alien_elite_interceptor.tscn")
const EnemyEliteArtillery      = preload("res://scenes/enemies/alien_elite_artillery.tscn")
const EnemyEliteSwarmCommander = preload("res://scenes/enemies/alien_elite_swarm_commander.tscn")
const EnemyMothershipScene     = preload("res://scenes/enemies/mothership.tscn")

# ─── Object pools ─────────────────────────────────────────────────────────────
var _laser_pool:   ObjectPool
var _missile_pool: ObjectPool

# ─── Sub-systems ──────────────────────────────────────────────────────────────
var _encounter_manager: EncounterManager
var _star_cluster_mgr:  StarClusterManager
var _arena_spawner:     ArenaWaveSpawner

# ─── Travel phase spawning ────────────────────────────────────────────────────
const SCROLL_SPEED        := 40.0
const SPAWN_INTERVAL      := 3.0
const MINE_SPAWN_INTERVAL  := 14.0
const CLOUD_SPAWN_INTERVAL := 22.0
const MAX_HAZARDS          := 14

var _spawn_timer: float = 0.0
var _mine_timer: float  = 8.0
var _cloud_timer: float = 12.0
var _scroll_offset: float = 0.0
var _bg_fill_timer: float = 6.0   # Change 6: dead-zone filler

# ─── Star Cluster state ───────────────────────────────────────────────────────
var _in_star_cluster: bool = false
var _in_arena: bool = false
var _current_arena_wave_path: String = ""
var _cluster_complete_pending: bool = false   # cluster_complete arrived during combat

# ─── Parallax starfield ───────────────────────────────────────────────────────
# Each star: Vector4(x, y, layer 0/1/2, brightness_offset)
const LAYER_SPEED := [0.15, 0.40, 1.0]   # fraction of SCROLL_SPEED
var _stars: Array[Vector4] = []
var _vp_size: Vector2 = Vector2.ZERO     # cached viewport size (set in _ready)

# ─── Screen shake ─────────────────────────────────────────────────────────────
var _shake_amount: float = 0.0
var _shake_timer: float = 0.0
var _base_camera_offset: Vector2 = Vector2.ZERO

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("game_world")
	GameManager.game_world = self
	# start_new_game() is called by MainMenu on a true fresh start.
	# On sector-transition reload: advance_sector() already ran; keep the sector.
	# On death retry: restore player stats for this sector only.
	if GameManager.current_state == GameManager.GameState.DEATH:
		GameManager.restart_sector()
	GameManager.change_state(GameManager.GameState.TRAVEL)

	# Object pools
	_laser_pool   = ObjectPool.new(LaserBoltScene, projectiles_node, 24)
	_missile_pool = ObjectPool.new(MissileScene,   projectiles_node, 6)

	# Wire player weapons to pools
	player.weapons.laser_pool           = _laser_pool
	player.weapons.missile_pool         = _missile_pool
	player.weapons.projectile_container = projectiles_node
	player.died.connect(_on_player_died)

	# Cache viewport size (fixed resolution — 320×180)
	_vp_size = get_viewport_rect().size

	# Position player
	player.global_position = Vector2(_vp_size.x * 0.5, _vp_size.y - 28.0)

	# Build parallax starfield
	_build_starfield(Rect2(Vector2.ZERO, _vp_size))

	# Wire HUD
	if hud_display and hud_display.has_method("connect_player"):
		hud_display.connect_player(player)

	# Wire CRT overlay
	var crt := get_node_or_null("CRTOverlay")
	if crt and crt.has_method("connect_player"):
		crt.connect_player(player)

	# Wire UI nodes
	if upgrade_screen_ui:
		upgrade_screen_ui.upgrade_done.connect(_on_upgrade_done)
	if sector_transition_ui:
		sector_transition_ui.transition_complete.connect(_on_sector_transition_complete)

	# Encounter manager
	_encounter_manager = EncounterManager.new()
	add_child(_encounter_manager)
	_encounter_manager.encounter_triggered.connect(_handle_encounter)
	_encounter_manager.sector_complete.connect(_on_sector_scroll_complete)
	_encounter_manager.start(GameManager.current_sector)

	# Music
	AudioManager.play_sector_music(GameManager.current_sector)

	# Seed initial asteroids
	for i in 4:
		_spawn_asteroid(randi_range(0, 1))

func _build_starfield(vp: Rect2) -> void:
	_stars.clear()
	for i in 80:
		var layer := i % 3
		_stars.append(Vector4(
			randf_range(0, vp.size.x),
			randf_range(0, vp.size.y),
			float(layer),
			randf_range(0.0, TAU)))

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# Background scroll
	var state := GameManager.current_state
	var scrolling := state == GameManager.GameState.TRAVEL

	if scrolling:
		_scroll_offset += SCROLL_SPEED * delta
		if _scroll_offset >= get_viewport_rect().size.y:
			_scroll_offset = 0.0
		_update_travel_spawning(delta)

	# Screen shake
	if _shake_timer > 0.0:
		_shake_timer -= delta
		_shake_amount = lerpf(_shake_amount, 0.0, delta * 8.0)
		# Apply shake to all game-world children (simple offset)
		var shake_off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount
		position = shake_off
	else:
		position = Vector2.ZERO

	queue_redraw()

func _update_travel_spawning(delta: float) -> void:
	var hc := hazards_node.get_child_count()
	var intensity: float = GameManager.get_sector_intensity()  # Change 4
	var effective_interval: float = SPAWN_INTERVAL / intensity
	var effective_max: int = int(float(MAX_HAZARDS) * minf(intensity, 2.0))

	_spawn_timer += delta
	if _spawn_timer >= effective_interval and hc < effective_max:
		_spawn_timer = 0.0
		_spawn_asteroid(randi_range(0, 1))

	_mine_timer += delta
	if _mine_timer >= MINE_SPAWN_INTERVAL / intensity:
		_mine_timer = 0.0
		_spawn_mine()

	_cloud_timer += delta
	if _cloud_timer >= CLOUD_SPAWN_INTERVAL / intensity:
		_cloud_timer = 0.0
		_spawn_debris_cloud()

	# Change 6: Background filler — prevent dead screen time
	_bg_fill_timer -= delta
	if _bg_fill_timer <= 0.0 and hc < 3:
		_bg_fill_timer = maxf(8.0 / intensity, 3.0)
		_spawn_background_filler()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var h := _vp_size.y
	var w := _vp_size.x

	# ── Nebula glow based on current sector ──
	var sector := clampi(GameManager.current_sector, 1, 5)
	var nebula_color: Color
	match sector:
		1: nebula_color = Color(0.08, 0.12, 0.28, 0.25)   # blue
		2: nebula_color = Color(0.18, 0.06, 0.25, 0.22)   # purple
		3: nebula_color = Color(0.04, 0.18, 0.20, 0.22)   # teal
		4: nebula_color = Color(0.22, 0.08, 0.04, 0.20)   # red-orange
		_: nebula_color = Color(0.22, 0.18, 0.06, 0.20)   # gold

	# Two soft nebula blobs — slow drift
	var neb_x1 := w * 0.3 + sin(t * 0.07) * 30.0
	var neb_y1 := h * 0.35 + cos(t * 0.05) * 20.0
	var neb_x2 := w * 0.72 + cos(t * 0.06) * 25.0
	var neb_y2 := h * 0.6 + sin(t * 0.04) * 18.0
	for ring in range(5, 0, -1):
		var r_frac := float(ring) / 5.0
		var r_size := 50.0 * r_frac
		var a := nebula_color.a * r_frac * (0.8 + 0.2 * sin(t * 0.3))
		var nc := Color(nebula_color.r, nebula_color.g, nebula_color.b, a)
		draw_circle(Vector2(neb_x1, neb_y1), r_size, nc)
		draw_circle(Vector2(neb_x2, neb_y2), r_size * 0.8, nc)

	# ── Distant galaxy smudges (2 static, seeded by sector) ──
	var gal_seed := sector * 137
	for gi in 2:
		var gx := fmod(float(gal_seed + gi * 97) * 1.618, w)
		var gy := fmod(float(gal_seed + gi * 53) * 2.317, h)
		var ga := 0.06 + 0.02 * sin(t * 0.15 + float(gi))
		for gr in range(3, 0, -1):
			var gs := 3.0 * float(gr)
			draw_circle(Vector2(gx, gy), gs, Color(0.9, 0.85, 0.7, ga * float(gr) / 3.0))
		# Tiny bright core
		draw_circle(Vector2(gx, gy), 0.8, Color(1.0, 0.95, 0.8, ga * 2.5))

	# ── Star colors per layer ──
	# Layer 0 (far): dim warm yellow / red — distant giants
	# Layer 1 (mid): white / blue-white mix
	# Layer 2 (near): bright white / blue, occasional red giant
	for s in _stars:
		var layer   := int(s.z)
		var y_off   := fmod(s.y + _scroll_offset * LAYER_SPEED[layer], h)

		# Twinkle — more pronounced, varies per star
		var twinkle := sin(t * (1.8 + s.w * 0.5) + s.w) * 0.5 + 0.5  # 0..1 range
		var bright  := 0.25 + 0.30 * float(layer) + 0.35 * twinkle
		var radius  := 0.4 + 0.35 * float(layer)

		# Choose star color based on layer + per-star seed
		var star_hue := fmod(s.w * 10.0, TAU) / TAU  # 0..1 pseudo-random from offset
		var col: Color
		match layer:
			0:
				# Far layer: warm yellow, occasional red
				if star_hue < 0.15:
					col = Color(bright * 1.0, bright * 0.45, bright * 0.3)  # red giant
				else:
					col = Color(bright * 1.0, bright * 0.92, bright * 0.7)  # warm yellow
			1:
				# Mid layer: blue-white, white
				if star_hue < 0.3:
					col = Color(bright * 0.75, bright * 0.85, bright * 1.1)  # blue-white
				else:
					col = Color(bright, bright, bright * 1.05)  # white
			_:
				# Near layer: bright white dominant, occasional blue or red
				if star_hue < 0.1:
					col = Color(bright * 1.0, bright * 0.4, bright * 0.35)  # rare red giant
				elif star_hue < 0.3:
					col = Color(bright * 0.7, bright * 0.85, bright * 1.15)  # blue
				else:
					col = Color(bright, bright, bright)  # white

		# Bloom for brighter stars — extra soft circle
		if bright > 0.7 and layer >= 1:
			var bloom_a := (bright - 0.7) * 0.4
			draw_circle(Vector2(s.x, y_off), radius * 2.5, Color(col.r, col.g, col.b, bloom_a))

		draw_circle(Vector2(s.x, y_off), radius, col)

		# Cross-flare on the brightest near stars during peak twinkle
		if layer == 2 and twinkle > 0.85:
			var flare_a := (twinkle - 0.85) * 3.0 * 0.3  # 0..0.3
			var fc := Color(col.r, col.g, col.b, flare_a)
			draw_line(Vector2(s.x - 3.0, y_off), Vector2(s.x + 3.0, y_off), fc, 0.5)
			draw_line(Vector2(s.x, y_off - 3.0), Vector2(s.x, y_off + 3.0), fc, 0.5)

		# Wrap: also draw star one screen-height above
		if y_off < 6.0:
			draw_circle(Vector2(s.x, y_off + h), radius, col)

# ─── Travel hazard spawning ───────────────────────────────────────────────────

func _spawn_asteroid(tier: int) -> void:
	var a := AsteroidScene.instantiate() as Asteroid
	hazards_node.add_child(a)
	var vp  := get_viewport_rect()
	var vel := Vector2(randf_range(-28.0, 28.0), randf_range(22.0, 60.0))
	a.global_position = Vector2(randf_range(16.0, vp.size.x - 16.0), -18.0)
	a.setup(tier, vel)
	a.destroyed.connect(_on_asteroid_destroyed)

func _on_asteroid_destroyed(pos: Vector2, tier: int) -> void:
	if tier >= Asteroid.SizeTier.SMALL:
		_maybe_drop_loot(pos, "asteroid")
		return
	for i in 2:
		var child := AsteroidScene.instantiate() as Asteroid
		var angle  := PI * i + randf_range(-0.6, 0.6)
		var speed  := randf_range(35.0, 65.0)
		var offset := Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		child.position = pos + offset   # set before add_child
		child.setup(tier + 1, Vector2(cos(angle), sin(angle)) * speed)
		child.destroyed.connect(_on_asteroid_destroyed)
		hazards_node.call_deferred("add_child", child)  # defer: called from physics signal

func _spawn_mine() -> void:
	var m := SpaceMineScene.instantiate() as SpaceMine
	hazards_node.add_child(m)
	var vp := get_viewport_rect()
	m.global_position = Vector2(randf_range(16.0, vp.size.x - 16.0), -18.0)
	m.setup(SpaceMine.MineType.STANDARD, 0)

func _spawn_background_filler() -> void:
	var sector := GameManager.current_sector
	match randi() % 4:
		0: _spawn_asteroid(0)
		1: _spawn_asteroid(randi_range(0, 1))
		2:
			if sector >= 2:
				_spawn_debris_cloud()
			else:
				_spawn_asteroid(0)
		3:
			if sector >= 3:
				_spawn_mine()
			else:
				_spawn_asteroid(randi_range(0, 1))

func _spawn_debris_cloud() -> void:
	var d := DebrisCloudScene.instantiate() as DebrisCloud
	hazards_node.add_child(d)
	var vp := get_viewport_rect()
	d.global_position = Vector2(randf_range(40.0, vp.size.x - 40.0), -20.0)
	d.velocity = Vector2(randf_range(-8.0, 8.0), randf_range(18.0, 30.0))

# ─── Encounter dispatch ───────────────────────────────────────────────────────

func _handle_encounter(enc: Dictionary) -> void:
	var type: String = enc.get("type", "")
	var params: Dictionary = enc.get("params", {})
	match type:
		"asteroid_field": _encounter_asteroid_field(params)
		"mine_field":     _encounter_mine_field(params)
		"debris_cloud":   _encounter_debris(params)
		"scout_wave":     _encounter_enemy_wave("scout", params)
		"warrior_wave":   _encounter_enemy_wave("warrior", params)
		"destroyer_wave": _encounter_enemy_wave("destroyer", params)
		"elite_wave":     _encounter_elite_wave(params)
		"fuel_cache":     _encounter_fuel_cache()
		"derelict_ship":  _encounter_derelict()
		"star_cluster":   _start_star_cluster()
		"mixed_field":    _encounter_mixed_field(params)   # Change 5
		"ambush_wave":    _encounter_ambush_wave(params)   # Change 5

func _encounter_asteroid_field(params: Dictionary) -> void:
	var count: int = params.get("count", 4)
	var tier: int  = params.get("tier", 0)
	var mix: bool  = params.get("mix", false)
	for i in count:
		var t := tier
		if mix:
			t = randi_range(tier, mini(tier + 1, 2))
		_spawn_asteroid(t)

func _mine_type_from_string(s: String) -> int:
	match s:
		"cluster": return SpaceMine.MineType.CLUSTER
		"rapid":   return SpaceMine.MineType.RAPID
		_:         return SpaceMine.MineType.STANDARD

func _encounter_mine_field(params: Dictionary) -> void:
	var count: int       = params.get("count", 3)
	var type_str: String = params.get("mine_type", "standard")
	var stagger: bool    = params.get("stagger", false)
	var mine_type: int   = _mine_type_from_string(type_str)
	var vp := get_viewport_rect()
	for i in count:
		var m := SpaceMineScene.instantiate() as SpaceMine
		hazards_node.add_child(m)
		var spacing := vp.size.x / (count + 1.0)
		m.global_position = Vector2(spacing * (i + 1), -18.0)
		m.setup(mine_type, i if stagger else 0)

func _encounter_debris(params: Dictionary) -> void:
	var count: int = params.get("count", 1)
	for i in count:
		_spawn_debris_cloud()

func _encounter_enemy_wave(type: String, params: Dictionary) -> void:
	var count: int = params.get("count", 3)
	var vp := get_viewport_rect()
	for i in count:
		spawn_enemy_at(type,
			Vector2((vp.size.x / (count + 1.0)) * (i + 1), -25.0))

func _encounter_elite_wave(params: Dictionary) -> void:
	var variants: Array = params.get("variants", ["interceptor"])
	var hp_scale: float = params.get("hp_scale", 1.0)
	var vp := get_viewport_rect()
	for i in variants.size():
		var type := "elite_" + str(variants[i]).replace("-", "_")
		var pos := Vector2((vp.size.x / (variants.size() + 1.0)) * (i + 1), -25.0)
		var enemy := _spawn_enemy_node(type, pos)
		if enemy and enemy.has_method("get") and "hp_scale" in enemy:
			enemy.hp_scale = hp_scale

func _encounter_fuel_cache() -> void:
	# Spawn a fuel cell pickup in a reachable position
	var vp := get_viewport_rect()
	spawn_pickup(Vector2(vp.size.x * 0.5, 60.0), "fuel_cell")
	spawn_pickup(Vector2(vp.size.x * 0.3, 80.0), "crystal")

func _encounter_derelict() -> void:
	var vp := get_viewport_rect()
	var ship := DerelictShipScene.instantiate() as DerelictShip
	hazards_node.add_child(ship)
	ship.global_position = Vector2(vp.size.x * randf_range(0.3, 0.7), -20.0)
	ship.destroyed.connect(_on_derelict_destroyed)

## Change 5: Asteroids and mines simultaneously.
func _encounter_mixed_field(params: Dictionary) -> void:
	var asteroids: int   = params.get("asteroids", 3)
	var mines: int       = params.get("mines", 2)
	var type_str: String = params.get("mine_type", "standard")
	var mine_type: int   = _mine_type_from_string(type_str)
	var vp := get_viewport_rect()
	for _i in asteroids:
		_spawn_asteroid(randi_range(0, 1))
	for i in mines:
		var m := SpaceMineScene.instantiate() as SpaceMine
		hazards_node.add_child(m)
		var spacing := vp.size.x / (mines + 1.0)
		m.global_position = Vector2(spacing * (i + 1) + randf_range(-15.0, 15.0), -18.0)
		m.setup(mine_type, i)

## Change 5: Enemies from both screen edges simultaneously.
func _encounter_ambush_wave(params: Dictionary) -> void:
	var type: String    = params.get("type", "scout")
	var count_left: int = params.get("count_left", 2)
	var count_right: int = params.get("count_right", 2)
	var vp := get_viewport_rect()
	# Left group — spawn near left edge
	for i in count_left:
		var x := randf_range(8.0, vp.size.x * 0.2)
		spawn_enemy_at(type, Vector2(x, -25.0))
	# Right group — spawn near right edge
	for i in count_right:
		var x := randf_range(vp.size.x * 0.8, vp.size.x - 8.0)
		spawn_enemy_at(type, Vector2(x, -25.0))

# ─── Star Cluster ─────────────────────────────────────────────────────────────

func _start_star_cluster() -> void:
	if _in_star_cluster:
		return   # Guard: encounter + sector_complete both fire this; run once only
	_in_star_cluster = true
	GameManager.change_state(GameManager.GameState.STAR_CLUSTER)
	_encounter_manager.stop()

	_star_cluster_mgr = StarClusterManager.new()
	add_child(_star_cluster_mgr)
	_star_cluster_mgr.stars_container             = stars_node
	_star_cluster_mgr.enemy_container             = enemies_node
	_star_cluster_mgr.enemy_projectile_container  = enemy_projectiles_node
	_star_cluster_mgr.cluster_complete.connect(_on_cluster_complete)
	_star_cluster_mgr.alien_combat_triggered.connect(_enter_arena)
	_star_cluster_mgr.human_viable_found.connect(_on_viable_found)
	_star_cluster_mgr.setup(GameManager.current_sector)
	_star_cluster_mgr.spawn_stars()

	# Wire scan bar to ALL star nodes
	if scan_bar_ui:
		for star in stars_node.get_children():
			if star is StarNode:
				var s := star  # capture loop var
				s.player_in_range.connect(func(in_range):
					if in_range:
						scan_bar_ui.show_for(s)
					else:
						scan_bar_ui.hide_scan())
				s.scan_completed.connect(func(_r, _d): scan_bar_ui.hide_scan())

	AudioManager.play_sfx("star_cluster_arrive")

func _on_viable_found(sector: int) -> void:
	if GameManager.has_won():
		_trigger_win(false)
		return
	# Continue — player can keep scanning other stars

func _on_cluster_complete() -> void:
	# If combat is active, defer until arena clears
	if _in_arena:
		_cluster_complete_pending = true
		return
	if GameManager.has_won():
		_trigger_win(false)
		return
	_begin_sector_transition()

# ─── Arena (Alien Combat) ─────────────────────────────────────────────────────

func _enter_arena(wave_data_path: String) -> void:
	_in_arena = true
	_current_arena_wave_path = wave_data_path
	GameManager.change_state(GameManager.GameState.ALIEN_COMBAT)
	AudioManager.play_music("alien_combat")

	_arena_spawner = ArenaWaveSpawner.new()
	add_child(_arena_spawner)
	_arena_spawner.enemy_container            = enemies_node
	_arena_spawner.enemy_projectile_container = enemy_projectiles_node
	_arena_spawner.all_waves_cleared.connect(_on_arena_cleared)
	_arena_spawner.start(wave_data_path)

func _on_arena_cleared() -> void:
	_in_arena = false
	GameManager.change_state(GameManager.GameState.STAR_CLUSTER)
	if _arena_spawner:
		_arena_spawner.queue_free()
		_arena_spawner = null
	# Refuel 15%
	player.fuel_sys.refuel(player.fuel_sys._max_fuel * 0.15)
	AudioManager.play_sfx("arena_clear")
	AudioManager.play_sector_music(GameManager.current_sector)
	# If cluster finished while we were fighting, progress now
	if _cluster_complete_pending:
		_cluster_complete_pending = false
		_on_cluster_complete()

func exit_arena_escape() -> void:
	_on_arena_cleared()

# ─── Sector Transition ────────────────────────────────────────────────────────

func _on_sector_scroll_complete() -> void:
	_start_star_cluster()

func _begin_sector_transition() -> void:
	if sector_transition_ui:
		sector_transition_ui.begin(GameManager.current_sector)
	else:
		_on_sector_transition_complete()

func _on_sector_transition_complete() -> void:
	# Check if final sector complete
	if GameManager.is_final_sector() and GameManager.has_won():
		_trigger_win(true)
		return

	# Show upgrade screen
	if upgrade_screen_ui:
		upgrade_screen_ui.show_upgrades()
	else:
		_on_upgrade_done()

func _on_upgrade_done() -> void:
	# Reload the scene to start the new sector
	get_tree().reload_current_scene()

# ─── Win ──────────────────────────────────────────────────────────────────────

func _trigger_win(true_ending: bool) -> void:
	if win_screen_ui:
		win_screen_ui.show_win(true_ending)

# ─── Spawning helpers (called by group) ──────────────────────────────────────

func spawn_enemy_at(type: String, pos: Vector2) -> void:
	_spawn_enemy_node(type, pos)

func _spawn_enemy_node(type: String, pos: Vector2) -> EnemyBase:
	var scene_map: Dictionary = {
		"scout":                 EnemyScoutScene,
		"warrior":               EnemyWarriorScene,
		"destroyer":             EnemyDestroyerScene,
		"elite_interceptor":     EnemyEliteInterceptor,
		"elite_artillery":       EnemyEliteArtillery,
		"elite_swarm_commander": EnemyEliteSwarmCommander,
		"mothership":            EnemyMothershipScene,
	}
	var scene: PackedScene = scene_map.get(type, null)
	if scene == null:
		push_warning("GameWorld: unknown enemy type '%s'" % type)
		return null
	var enemy := scene.instantiate() as EnemyBase
	enemies_node.add_child(enemy)
	enemy.global_position = pos
	enemy.enemy_projectile_container = enemy_projectiles_node
	enemy.died.connect(_on_enemy_died.bind(enemy))
	return enemy

func _on_derelict_destroyed(pos: Vector2) -> void:
	spawn_pickup(pos + Vector2(-10, 0), "missile_pack")
	spawn_pickup(pos + Vector2(10, 0), "crystal")
	spawn_pickup(pos + Vector2(0, -8), "crystal")
	screen_shake(3.0, 0.2)

func _on_enemy_died(pos: Vector2, drop_table: String, _enemy: EnemyBase) -> void:
	_maybe_drop_loot(pos, drop_table)
	screen_shake(2.5, 0.15)

func spawn_mine_at(pos: Vector2) -> void:
	var m := SpaceMineScene.instantiate() as SpaceMine
	hazards_node.add_child(m)
	m.global_position = pos
	m.setup(SpaceMine.MineType.STANDARD, 0)

## Change 2: Fired by SpaceMine spike shots via call_group.
func spawn_mine_bolt(pos: Vector2, direction: Vector2, damage: int) -> void:
	var bolt := preload("res://scenes/projectiles/enemy_bolt.tscn").instantiate() as EnemyBolt
	enemy_projectiles_node.add_child(bolt)
	bolt.global_position = pos
	bolt.setup(damage, direction, 140.0, "scout")

func spawn_missile_from(pos: Vector2, target: Node2D, damage: int) -> void:
	var scene := load("res://scenes/projectiles/enemy_missile.tscn") as PackedScene
	if scene == null:
		return
	var m := scene.instantiate() as Node2D
	enemy_projectiles_node.add_child(m)
	m.global_position = pos
	if m.has_method("setup"):
		m.setup(damage, target, 160.0)

func spawn_pickup(pos: Vector2, type: String) -> void:
	if type == "nothing":
		return
	if not is_instance_valid(player):
		return
	# Fast path: immediate effect for common types during travel
	if GameManager.current_state == GameManager.GameState.TRAVEL \
	   and (type == "fuel_cell" or type == "crystal"):
		match type:
			"fuel_cell": player.fuel_sys.refuel(25.0)
			"crystal":   GameManager.add_crystal(1)
		GameManager.add_score(15)
		return
	# Spawn a physical pickup entity — deferred add_child avoids
	# "can't change monitoring state" errors from physics callbacks.
	var scene := PickupScene as PackedScene
	if scene == null:
		return
	var pickup := scene.instantiate() as PickupVisuals
	pickup.position = pos
	pickup.setup(type)
	pickups_node.call_deferred("add_child", pickup)

func spawn_loot_wave(loot_list: Array, center: Vector2) -> void:
	var types := DropTable.from_loot_list(loot_list)
	for i in types.size():
		var offset := Vector2(randf_range(-30, 30), randf_range(-20, 20))
		spawn_pickup(center + offset, types[i])

func spawn_scan_reward(reward: String) -> void:
	var vp := get_viewport_rect()
	var center := Vector2(vp.size.x * 0.5, vp.size.y * 0.5)
	var rewards := reward.split("+")
	for r in rewards:
		if r.begins_with("crystal"):
			var count := int(r.substr(7)) if r.length() > 7 else 1
			for _i in count:
				spawn_pickup(center + Vector2(randf_range(-30, 30), randf_range(-20, 20)), "crystal")
		else:
			spawn_pickup(center + Vector2(randf_range(-20, 20), randf_range(-10, 10)), r)

func spawn_anomaly_loot(_id: String) -> void:
	var vp := get_viewport_rect()
	var center := vp.size * 0.5
	for t in ["missile_pack", "crystal", "crystal", "crystal"]:
		spawn_pickup(center + Vector2(randf_range(-40, 40), randf_range(-25, 25)), t)

func _maybe_drop_loot(pos: Vector2, table_key: String) -> void:
	var type := DropTable.roll(table_key)
	spawn_pickup(pos, type)

func spawn_score_popup(pos: Vector2, text: String) -> void:
	var popup := ScorePopupScene.instantiate() as ScorePopup
	add_child(popup)
	popup.global_position = pos
	popup.setup(text)

# ─── Screen Shake ─────────────────────────────────────────────────────────────

func screen_shake(amount: float, duration: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)
	_shake_timer  = maxf(_shake_timer, duration)

# ─── Player death ─────────────────────────────────────────────────────────────

func _on_player_died() -> void:
	GameManager.change_state(GameManager.GameState.DEATH)
	GameManager.save_data_on_death()
	screen_shake(6.0, 0.4)
	if death_screen_ui:
		await get_tree().create_timer(2.0).timeout
		death_screen_ui.show_death()
	else:
		await get_tree().create_timer(2.5).timeout
		get_tree().reload_current_scene()
