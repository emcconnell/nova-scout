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
const EnemyLeviathanScene      = preload("res://scenes/enemies/space_leviathan.tscn")
const EnemySilenceScene        = preload("res://scenes/enemies/the_silence.tscn")
const ExplosionScene           = preload("res://scenes/effects/explosion.tscn")
const MissionPromptScript      = preload("res://src/ui/mission_prompt.gd")

# ─── Object pools ─────────────────────────────────────────────────────────────
var _laser_pool:   ObjectPool
var _missile_pool: ObjectPool

# ─── Sub-systems ──────────────────────────────────────────────────────────────
var _encounter_manager: EncounterManager
var _star_cluster_mgr:  StarClusterManager
var _arena_spawner:     ArenaWaveSpawner
var _mission_prompt:    Node
var _dread_director:    DreadDirector
var _threat_tracker:    ThreatTracker

# ─── Hitstop (dark-directive.md §4.2 kill feedback) ──────────────────────────
var _hitstop_recover_at_msec: int = 0

# ─── Stalker spawning (dark-directive.md §4.1 The Silence) ───────────────────
var _stalker_timer: float = 0.0
var _stalker_rolled: bool = false

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
var _wrong_star_idx: int = -1            # The star that moves. It's nothing.

# ─── TURN 4 scene detail (seeded once, never randf() in _draw) ───────────────
var _scene_detail: Dictionary = {}

# ─── v4.0 Textured Light — sun rig + deep background layers ──────────────────
var _sun: DirectionalLight2D = null
var _bg_tiles: Array[Sprite2D] = []       # tiling photographic star layers
var _nebula_sprites: Array[Sprite2D] = [] # baked wisps, sector-tinted
const BG_TILE_SPEED := [0.35, 0.65]       # parallax factor per tile layer

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
	_build_bg_layers()

	# THE SUN as a real light — hard key light (SURVEY) that the fade swings
	# into an ember red; every normal-mapped body in the world shades by it.
	_sun = TextureKit.sun_light(self)

	# Wire HUD
	if hud_display and hud_display.has_method("connect_player"):
		hud_display.connect_player(player)
	_setup_mission_prompts()

	# Dread layer — atmosphere director + motion tracker (dark-directive.md)
	_dread_director = DreadDirector.new()
	add_child(_dread_director)
	_dread_director.connect_player(player)
	_threat_tracker = ThreatTracker.new()
	$HUD.add_child(_threat_tracker)
	_stalker_timer = randf_range(18.0, 30.0)

	# Darkness veil — sectors 3+ visibility falloff. Enemy projectiles render
	# above the veil so incoming fire is never hidden (dark-directive.md §6).
	var veil := DarknessVeil.new()
	add_child(veil)
	veil.connect_player(player)
	enemy_projectiles_node.z_index = 35
	projectiles_node.z_index = 35

	# v5.0 "Wet Black" — volumetric dust in the beam + the cinematic pass
	# (bloom / filmic tonemap / fade grade). The post pass lives on its own
	# CanvasLayer (1, under the FilmLayer at 2): a screen-texture read inside
	# the world canvas gets a stale backbuffer copy in GL Compatibility that
	# is missing the projectile layer (z 35) — bolts vanished (Turn 6.1).
	add_child(DustField.new())
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	post_layer.add_child(PostStack.new())

	# Wire CRT overlay
	var crt := get_node_or_null("FilmLayer/CRTOverlay")
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
	_request_mission_prompt("move")
	# Mission Control decays — by Delta, nobody is answering (dark-directive.md §4.4)
	if GameManager.current_sector == 4:
		_request_mission_prompt("control_lost")

## Create and connect the one-time mission-control onboarding prompt system.
func _setup_mission_prompts() -> void:
	_mission_prompt = MissionPromptScript.new()
	add_child(_mission_prompt)
	_mission_prompt.prompt_shown.connect(func(_prompt_id: String, text: String):
		if hud_display and hud_display.has_method("show_mission_prompt"):
			hud_display.show_mission_prompt(text))
	_mission_prompt.prompt_dismissed.connect(func(_prompt_id: String):
		if hud_display and hud_display.has_method("clear_mission_prompt"):
			hud_display.clear_mission_prompt())

func request_mission_prompt(prompt_id: String) -> void:
	_request_mission_prompt(prompt_id)

func show_scan_reveal(pos: Vector2, label: String, reward: String = "") -> void:
	var text := label
	if not reward.is_empty():
		text += " +" + reward.to_upper()
	spawn_score_popup(pos, text)
	_request_mission_prompt("first_discovery")

## Request a one-time mission-control prompt if the prompt system is available.
func _request_mission_prompt(prompt_id: String) -> void:
	if _mission_prompt:
		_mission_prompt.request_prompt(prompt_id)

## Deep photographic background: two tiling baked star layers under the
## procedural twinkle field, plus sector-tinted nebula wisps (art bible v4.0).
func _build_bg_layers() -> void:
	for i in 2:
		var s := Sprite2D.new()
		s.texture = TextureKit.tex("world", "starfield_%d" % i)
		s.centered = false
		s.z_index = -10 + i
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, 640, 360)
		s.scale = Vector2(0.5, 0.5)
		# v5.0: stars are light-years away — no in-scene light may brighten
		# them, and no occluder may shadow them.
		s.light_mask = 0
		add_child(s)
		_bg_tiles.append(s)
	var wisp_rng := DrawKit.rng(917 + GameManager.current_sector)
	for i in 3:
		var n := Sprite2D.new()
		n.texture = TextureKit.tex("world", "nebula_%d" % i)
		n.z_index = -8
		n.position = Vector2(wisp_rng.randf() * _vp_size.x,
			wisp_rng.randf() * _vp_size.y)
		n.scale = Vector2.ONE * (0.5 + wisp_rng.randf() * 0.7)
		n.rotation = wisp_rng.randf() * TAU
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		n.material = mat
		n.light_mask = 0   # nebulae are self-lit gas, not surfaces
		add_child(n)
		_nebula_sprites.append(n)

## Sun light + background layers track the fade and the scroll each frame.
func _update_light_rig() -> void:
	var blend := VisualState.blend()
	if _sun:
		var sun_pos := VisualState.sun_screen_pos()
		var from_dir := sun_pos - _vp_size * 0.5
		if from_dir.length_squared() > 1.0:
			TextureKit.aim_sun(_sun, from_dir)
		_sun.color = Color(0.95, 0.97, 1.0).lerp(Color(1.0, 0.30, 0.18), blend)
		_sun.energy = lerpf(0.85, 0.50, blend)
	for i in _bg_tiles.size():
		var tile := _bg_tiles[i]
		# region scrolls in texture px (tile is drawn at 0.5 scale)
		tile.region_rect.position.y = -_scroll_offset * float(BG_TILE_SPEED[i]) * 2.0
		tile.modulate.a = lerpf(1.0, 0.35, blend)
	var sector := clampi(GameManager.current_sector, 1, 5)
	var wisp_col: Color = [
		Color(0.30, 0.42, 0.75), Color(0.45, 0.26, 0.60), Color(0.22, 0.52, 0.42),
		Color(0.55, 0.22, 0.14), Color(0.34, 0.18, 0.44),
	][sector - 1]
	for n in _nebula_sprites:
		# wisps dim and redden as the frequency dies; kept glass-thin so
		# anything moving reads through the gas (they sit at z -8 regardless)
		n.modulate = wisp_col.lerp(Color(0.35, 0.06, 0.04), blend)
		n.modulate.a = lerpf(0.20, 0.11, blend)

## Build the parallax starfield and precompute all seeded TURN 4 scene detail
## (dust lane, ambient glows, derelict hulk, ghost chain) once — never randf()
## inside _draw().
func _build_starfield(vp: Rect2) -> void:
	_stars.clear()
	for i in 64:   # Sparser field — the void should feel empty
		var layer := i % 3
		_stars.append(Vector4(
			randf_range(0, vp.size.x),
			randf_range(0, vp.size.y),
			float(layer),
			randf_range(0.0, TAU)))
	# The wrong star — one background star that drifts against the parallax.
	# It's nothing. Probably. (dark-directive.md §4.2)
	_wrong_star_idx = randi_range(0, _stars.size() - 1) \
		if GameManager.current_sector >= 2 and randf() < 0.4 else -1
	_scene_detail = SceneRenderer.precompute(4013 + GameManager.current_sector * 71, vp.size.x, vp.size.y)

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# Background scroll
	var state := GameManager.current_state
	var scrolling := state == GameManager.GameState.TRAVEL

	if scrolling:
		var scroll_dist := SCROLL_SPEED * delta
		_scroll_offset += scroll_dist
		if _scroll_offset >= get_viewport_rect().size.y:
			_scroll_offset = 0.0
		# Grant energy based on travel distance
		if is_instance_valid(player) and player.weapons:
			player.weapons.add_travel_distance(scroll_dist)
		_update_travel_spawning(delta)

	# Screen shake — translation + slight rotation; rotation reads as force,
	# not glitch (Vlambeer / dark-directive.md §4.2)
	if _shake_timer > 0.0:
		_shake_timer -= delta
		_shake_amount = lerpf(_shake_amount, 0.0, delta * 8.0)
		var shake_off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount
		position = shake_off
		rotation = deg_to_rad(randf_range(-0.4, 0.4)) * clampf(_shake_amount / 4.0, 0.0, 1.0)
	else:
		position = Vector2.ZERO
		rotation = 0.0

	_update_light_rig()
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

	_update_stalker_spawning(delta)

## The Silence — cloaked stalker rolls once per timer window in sectors 3+.
## Never more than one concurrent; travel phase only (dark-directive.md §6).
func _update_stalker_spawning(delta: float) -> void:
	var sector := GameManager.current_sector
	if sector < int(GameManager.dread_value("stalker", "min_sector", 3)):
		return
	if not get_tree().get_nodes_in_group("silence").is_empty():
		return
	_stalker_timer -= delta
	if _stalker_timer > 0.0:
		return
	_stalker_timer = randf_range(25.0, 40.0)
	if _stalker_rolled:
		return   # One stalker visit per sector keeps it an event, not a chore
	var chances: Variant = GameManager.dread_value("stalker", "spawn_chance_per_sector", {})
	var chance: float = float((chances as Dictionary).get(str(sector), 0.0)) if chances is Dictionary else 0.0
	if randf() < chance:
		_stalker_rolled = true
		_request_mission_prompt("silence")
		var vp := get_viewport_rect()
		spawn_enemy_at("silence", Vector2(randf_range(40.0, vp.size.x - 40.0), -30.0))

## TURN 4 background — photographic starfield + milky-way dust lane + THE SUN,
## crossfading via VisualState.blend() toward the dead frequency: collapsed
## star count, ember star, ambient dark-red glows, derelict hulk silhouette.
## GDD Ref: art-bible.md (Turn 4) — Scene / starfield recipe (scene4a/scene4c).
func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var h := _vp_size.y
	var w := _vp_size.x
	var blend := VisualState.blend()

	# ── Sector-tinted ambient glow — subtle SURVEY nebula fading to vast DEAD
	# red glows. Dread palette kept per-sector, alpha capped low (art-bible Turn 4).
	var sector := clampi(GameManager.current_sector, 1, 5)
	var nebula_color: Color
	match sector:
		1: nebula_color = Color(0.07, 0.10, 0.20, 0.10)   # cold blue-grey — last safe light
		2: nebula_color = Color(0.11, 0.06, 0.15, 0.09)   # bruise violet
		3: nebula_color = Color(0.05, 0.13, 0.10, 0.10)   # sickly phosphor murk
		4: nebula_color = Color(0.13, 0.05, 0.03, 0.09)   # rust / dried blood
		_: nebula_color = Color(0.08, 0.04, 0.10, 0.08)   # near-black violet
	SceneRenderer.draw_sector_glows(self, _scene_detail, nebula_color, blend, w, h, t)

	# ── Static seeded milky-way dust lane — behind the parallax stars ──
	SceneRenderer.draw_dust_lane(self, _scene_detail)

	# ── Parallax starfield — photographic restyle, count collapses toward DEAD ──
	# Layer-agnostic warm/cool split per spec: 28% warm, rest split blue-white/white.
	for si in _stars.size():
		var s := _stars[si]
		var layer   := int(s.z)
		var y_off   := fmod(s.y + _scroll_offset * LAYER_SPEED[layer], h)
		var x_pos   := s.x

		# The wrong star drifts sideways against the parallax and half-ignores
		# the scroll. Nobody said anything about it in the briefing.
		if si == _wrong_star_idx:
			x_pos = fmod(s.x + t * 1.1, w)
			y_off = fmod(s.y + _scroll_offset * LAYER_SPEED[layer] * 0.4, h)

		# Twinkle — dimmer overall; the void is not friendly (dark-directive.md)
		var twinkle := sin(t * (1.8 + s.w * 0.5) + s.w) * 0.5 + 0.5  # 0..1 range
		var bright  := 0.16 + 0.24 * float(layer) + 0.28 * twinkle
		var star_hue := fmod(s.w * 10.0, TAU) / TAU  # 0..1 pseudo-random from offset
		var warm := star_hue < 0.28

		# Brightness-weighted size (art-bible: >0.94 -> 1.8px, >0.7 -> 1.2px, else 0.9px).
		var radius := (1.8 if bright > 0.94 else (1.2 if bright > 0.7 else 0.9)) * 0.5

		var col: Color
		if warm:
			col = Color(bright, bright * 0.910, bright * 0.784)   # 255,232,200
		elif star_hue < 0.64:
			col = Color(bright * 0.769, bright * 0.839, bright)   # 196,214,255
		else:
			col = Color(bright * 0.933, bright * 0.957, bright)  # 238,244,255

		# Star count collapses in DEAD FREQUENCY: cold pinpricks only, warm stars
		# fade out progressively; overall alpha drops toward 0.3.
		var alpha := lerpf(1.0, 0.3, blend)
		if warm:
			alpha *= (1.0 - blend)
		if alpha <= 0.01:
			continue
		var dc := Color(col.r, col.g, col.b, alpha)

		if bright > 0.7 and layer >= 1:
			var bloom_a := (bright - 0.7) * 0.4 * alpha
			draw_circle(Vector2(x_pos, y_off), radius * 2.5, Color(col.r, col.g, col.b, bloom_a))

		draw_circle(Vector2(x_pos, y_off), radius, dc)

		if layer == 2 and twinkle > 0.85:
			var flare_a := (twinkle - 0.85) * 3.0 * 0.3 * alpha
			var fc := Color(col.r, col.g, col.b, flare_a)
			draw_line(Vector2(x_pos - 3.0, y_off), Vector2(x_pos + 3.0, y_off), fc, 0.5)
			draw_line(Vector2(x_pos, y_off - 3.0), Vector2(x_pos, y_off + 3.0), fc, 0.5)

		if y_off < 6.0:
			draw_circle(Vector2(x_pos, y_off + h), radius, dc)

	# ── THE SUN / EMBER STAR — one draw pass, position crossfades via VisualState ──
	SceneRenderer.draw_sun(self, _scene_detail, VisualState.sun_screen_pos(), blend, w, h)

	# ── DERELICT HULK top-right — DEAD FREQUENCY only ──
	SceneRenderer.draw_derelict_hulk(self, _scene_detail, blend)

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
	# Explosion per tier
	match tier:
		Asteroid.SizeTier.LARGE:  spawn_explosion(pos, Explosion.Type.ASTEROID_LARGE)
		Asteroid.SizeTier.MEDIUM: spawn_explosion(pos, Explosion.Type.ASTEROID_MEDIUM)
		_:                        spawn_explosion(pos, Explosion.Type.ASTEROID_SMALL)
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
		"asteroid_field":
			_request_mission_prompt("fire")
			_encounter_asteroid_field(params)
		"mine_field":     _encounter_mine_field(params)
		"debris_cloud":   _encounter_debris(params)
		"scout_wave":
			_request_mission_prompt("fire")
			_encounter_enemy_wave("scout", params)
		"warrior_wave":   _encounter_enemy_wave("warrior", params)
		"destroyer_wave": _encounter_enemy_wave("destroyer", params)
		"elite_wave":     _encounter_elite_wave(params)
		"fuel_cache":
			_request_mission_prompt("pickup")
			_encounter_fuel_cache()
		"derelict_ship":  _encounter_derelict()
		"star_cluster":   _start_star_cluster()
		"mixed_field":    _encounter_mixed_field(params)   # Change 5
		"ambush_wave":    _encounter_ambush_wave(params)   # Change 5
		"leviathan":      _encounter_leviathan(params)

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
	# Silence before contact — the mix drops out as elites arrive
	AudioManager.duck_music(4.5)
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

func _encounter_leviathan(_params: Dictionary) -> void:
	var vp := get_viewport_rect()
	var pos := Vector2(randf_range(40, vp.size.x - 40), -25.0)
	spawn_enemy_at("leviathan", pos)

# ─── Star Cluster ─────────────────────────────────────────────────────────────

func _start_star_cluster() -> void:
	if _in_star_cluster:
		return   # Guard: encounter + sector_complete both fire this; run once only
	_request_mission_prompt("scan")
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
	_star_cluster_mgr.star_revealed.connect(_wire_scan_bar_to_star)
	_star_cluster_mgr.scan_pressure_pulse.connect(_on_scan_pressure_pulse)
	_star_cluster_mgr.setup(GameManager.current_sector)
	_star_cluster_mgr.spawn_stars()

	# Wire scan bar to ALL star nodes
	if scan_bar_ui:
		for star in stars_node.get_children():
			if star is StarNode:
				_wire_scan_bar_to_star(star)

	AudioManager.play_sfx("star_cluster_arrive")
	get_tree().call_group("crt_overlay", "pulse_signal_roll", 0.5)

func _wire_scan_bar_to_star(star: StarNode) -> void:
	if scan_bar_ui == null or star.has_meta("scan_bar_wired"):
		return
	star.set_meta("scan_bar_wired", true)
	var s := star  # capture loop var
	s.player_in_range.connect(func(in_range):
		if in_range:
			_request_mission_prompt("abort")
			scan_bar_ui.show_for(s)
		else:
			scan_bar_ui.hide_scan())
	s.scan_completed.connect(func(_r, _d): scan_bar_ui.hide_scan())

func _on_scan_pressure_pulse(pulse: Dictionary, _star_data: Dictionary) -> void:
	var count: int = maxi(int(pulse.get("count", 1)), 1)
	match String(pulse.get("type", "")):
		"asteroid":
			for i in count:
				_spawn_asteroid(Asteroid.SizeTier.SMALL)
		"mine":
			for i in count:
				_spawn_mine()
		"scout", "warrior", "destroyer", "elite_interceptor", "elite_artillery", "elite_swarm_commander":
			var vp := get_viewport_rect()
			for i in count:
				var x := (vp.size.x / float(count + 1)) * float(i + 1)
				spawn_enemy_at(String(pulse.get("type", "scout")), Vector2(x, -25.0))

func _on_viable_found(sector: int) -> void:
	if sector == GameManager.MAX_SECTORS and GameManager.has_required_beacons():
		if _star_cluster_mgr and _star_cluster_mgr.has_method("reveal_mandatory_after"):
			_star_cluster_mgr.reveal_mandatory_after("E3")
		return
	# Continue — player can keep scanning other stars

func _on_cluster_complete() -> void:
	# If combat is active, defer until arena clears
	if _in_arena:
		_cluster_complete_pending = true
		return
	if GameManager.is_campaign_complete():
		_trigger_win(true)
		return
	_begin_sector_transition()

# ─── Arena (Alien Combat) ─────────────────────────────────────────────────────

func _enter_arena(wave_data_path: String) -> void:
	_request_mission_prompt("alien")
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
	if GameManager.current_state == GameManager.GameState.WIN:
		return
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
	if GameManager.is_final_sector() and GameManager.is_campaign_complete():
		_trigger_win(true)
		return

	# Show upgrade screen
	_request_mission_prompt("upgrade")
	if upgrade_screen_ui:
		upgrade_screen_ui.show_upgrades()
	else:
		_on_upgrade_done()

func _on_upgrade_done() -> void:
	# Reload the scene to start the new sector
	get_tree().reload_current_scene()

# ─── Win ──────────────────────────────────────────────────────────────────────

func _trigger_win(true_ending: bool) -> void:
	if GameManager.current_state == GameManager.GameState.WIN:
		return
	GameManager.change_state(GameManager.GameState.WIN)
	if win_screen_ui:
		win_screen_ui.show_win(true_ending)

## Complete the campaign when the final Mothership boss dies.
func on_mothership_defeated() -> void:
	if GameManager.mothership_defeated:
		return
	GameManager.mark_mothership_defeated()
	if GameManager.is_campaign_complete():
		_trigger_win(true)

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
		"leviathan":             EnemyLeviathanScene,
		"silence":               EnemySilenceScene,
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
	# Derelicts are graves — salvaging one recovers a probe log (dark-directive.md §4.4)
	var frag := LogFragments.next_fragment()
	if not frag.is_empty() and hud_display and hud_display.has_method("show_log_fragment"):
		AudioManager.play_sfx("derelict_log", 0.7)
		hud_display.show_log_fragment(String(frag["title"]), String(frag["text"]))

func _on_enemy_died(pos: Vector2, drop_table: String, _enemy: EnemyBase) -> void:
	_maybe_drop_loot(pos, drop_table)
	if drop_table == "mothership":
		on_mothership_defeated()
	# Spawn type-appropriate explosion
	var exp_type: int = Explosion.Type.SCOUT
	match drop_table:
		"scout": exp_type = Explosion.Type.SCOUT
		"warrior": exp_type = Explosion.Type.WARRIOR
		"destroyer": exp_type = Explosion.Type.DESTROYER
		"elite": exp_type = Explosion.Type.ELITE
		"mothership": exp_type = Explosion.Type.MOTHERSHIP
		"shield_drone": exp_type = Explosion.Type.SCOUT
		"leviathan": exp_type = Explosion.Type.LEVIATHAN
	spawn_explosion(pos, exp_type)
	screen_shake(2.5, 0.15)
	# Kill hitstop — elites and bosses freeze longer (dark-directive.md §4.2)
	if drop_table in ["elite", "destroyer", "mothership", "leviathan"]:
		hitstop(int(GameManager.dread_value("hitstop", "elite_kill_ms", 90)))
	else:
		hitstop(int(GameManager.dread_value("hitstop", "kill_ms", 40)))

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
	   and type in ["fuel_cell", "crystal", "energy_cell"]:
		match type:
			"fuel_cell":    player.fuel_sys.refuel(25.0)
			"crystal":      GameManager.add_crystal(1)
			"energy_cell":  player.weapons.add_energy(40.0)
		GameManager.add_score(15)
		spawn_score_popup(pos, _pickup_feedback_text(type), true)
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

func _pickup_feedback_text(type: String) -> String:
	match type:
		"fuel_cell": return "+25 FUEL"
		"repair_kit": return "+20 HULL"
		"missile_pack": return "+3 MSL"
		"emp_cartridge": return "+1 EMP"
		"energy_cell": return "+40 ENERGY"
		"crystal": return "+1 DATA"
		"shield_booster": return "+30 SHIELD"
		"survey_beacon": return "+3000 BEACON"
		_: return "+ITEM"

func spawn_score_popup(pos: Vector2, text: String, is_item: bool = false) -> void:
	var popup := ScorePopupScene.instantiate() as ScorePopup
	add_child(popup)
	popup.global_position = pos
	popup.setup(text, is_item)

# ─── Screen Shake ─────────────────────────────────────────────────────────────

## Spawn an explosion effect at a position.
func spawn_explosion(pos: Vector2, type: int) -> void:
	var exp := ExplosionScene.instantiate() as Explosion
	add_child(exp)
	exp.global_position = pos
	exp.setup(type)

func screen_shake(amount: float, duration: float) -> void:
	var shake_multiplier := clampf(float(SaveManager.get_setting("screen_shake")), 0.0, 1.0)
	_shake_amount = maxf(_shake_amount, amount * shake_multiplier)
	_shake_timer  = maxf(_shake_timer, duration if shake_multiplier > 0.0 else 0.0)

# ─── Hitstop ──────────────────────────────────────────────────────────────────

## Freeze the world for a few milliseconds — the subconscious "thunk" that
## makes kills land (dark-directive.md §4.2). Respects screen_shake=0 as the
## accessibility opt-out for all impact effects.
func hitstop(ms: int) -> void:
	if clampf(float(SaveManager.get_setting("screen_shake")), 0.0, 1.0) <= 0.0:
		return
	var end_msec := Time.get_ticks_msec() + ms
	if end_msec <= _hitstop_recover_at_msec:
		return   # Already stopped at least this long
	_hitstop_recover_at_msec = end_msec
	Engine.time_scale = 0.05
	_schedule_hitstop_recovery(ms)

## Restore time scale once the newest hitstop window has fully elapsed.
## Re-arms itself for the remainder if a longer stop was queued meanwhile,
## so recovery is guaranteed — the world can never stay frozen.
func _schedule_hitstop_recovery(ms: int) -> void:
	var timer := get_tree().create_timer(float(ms) / 1000.0, true, false, true)
	timer.timeout.connect(func() -> void:
		var remaining := _hitstop_recover_at_msec - Time.get_ticks_msec()
		if remaining <= 0:
			Engine.time_scale = 1.0
		else:
			_schedule_hitstop_recovery(remaining))

func _exit_tree() -> void:
	# Scene reloads (sector transition, retry) must never strand a hitstop.
	Engine.time_scale = 1.0

## Player took a hull hit — impact feedback (called by Player via group).
func on_player_hull_hit() -> void:
	hitstop(int(GameManager.dread_value("hitstop", "player_hit_ms", 55)))
	screen_shake(3.2, 0.22)

# ─── Player death ─────────────────────────────────────────────────────────────

func _on_player_died() -> void:
	GameManager.change_state(GameManager.GameState.DEATH)
	GameManager.save_data_on_death()
	spawn_explosion(player.global_position, Explosion.Type.PLAYER)
	screen_shake(6.0, 0.4)
	if death_screen_ui:
		await get_tree().create_timer(2.0).timeout
		death_screen_ui.show_death()
	else:
		await get_tree().create_timer(2.5).timeout
		get_tree().reload_current_scene()
