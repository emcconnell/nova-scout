## test_game_world.gd — Focused tests for high-level campaign flow guards.
extends GutTest

func before_each() -> void:
	GameManager.start_new_game()

func test_arena_clear_does_not_downgrade_win_state_after_mothership_defeat() -> void:
	var world := preload("res://scenes/game_world.tscn").instantiate() as GameWorld
	add_child_autofree(world)
	world._cluster_complete_pending = true
	world._in_arena = true
	for i in GameManager.BEACONS_TO_WIN:
		GameManager.collect_beacon()
	GameManager.mark_mothership_defeated()
	GameManager.change_state(GameManager.GameState.WIN)

	world._on_arena_cleared()

	assert_eq(GameManager.current_state, GameManager.GameState.WIN)
	assert_true(world._cluster_complete_pending, "WIN guard should leave deferred flow untouched")
	assert_true(world._in_arena, "WIN guard should not resume arena cleanup after campaign completion")

func test_final_beacon_reveals_mothership_star_without_triggering_win() -> void:
	GameManager.current_sector = GameManager.MAX_SECTORS
	GameManager.collect_beacon()
	GameManager.collect_beacon()
	var world := preload("res://scenes/game_world.tscn").instantiate() as GameWorld
	add_child_autofree(world)

	world._start_star_cluster()
	var manager := world._star_cluster_mgr
	manager._on_scan_completed("human_viable", {"id":"E3"}, null, {"id":"E3"})

	assert_eq(GameManager.survey_beacons, GameManager.BEACONS_TO_WIN)
	assert_true(GameManager.has_required_beacons())
	assert_false(GameManager.is_campaign_complete())
	assert_ne(GameManager.current_state, GameManager.GameState.WIN)
	var ids: Array[String] = []
	for child in world.stars_node.get_children():
		if child is StarNode:
			ids.append(child.star_data.get("id", ""))
	assert_true(ids.has("E4"), "Mothership star should be revealed by final beacon")

func test_mothership_star_scan_enters_boss_arena() -> void:
	GameManager.current_sector = GameManager.MAX_SECTORS
	for i in GameManager.BEACONS_TO_WIN:
		GameManager.collect_beacon()
	var world := preload("res://scenes/game_world.tscn").instantiate() as GameWorld
	add_child_autofree(world)

	world._start_star_cluster()
	world._star_cluster_mgr.reveal_mandatory_after("E3")
	world._star_cluster_mgr._on_scan_completed("mothership", {
		"id":"E4",
		"wave_path":"res://assets/data/waves/sector_5_mothership.json"
	}, null, {"id":"E4", "mandatory_after":"E3"})

	assert_eq(GameManager.current_state, GameManager.GameState.ALIEN_COMBAT)
	assert_true(world._in_arena)
	assert_eq(world._current_arena_wave_path, "res://assets/data/waves/sector_5_mothership.json")
	assert_not_null(world._arena_spawner)
	assert_eq(world.enemies_node.get_child_count(), 1)
	assert_true(world.enemies_node.get_child(0) is Mothership)

func test_full_campaign_spine_reaches_true_ending_without_softlock() -> void:
	for sector in range(1, GameManager.MAX_SECTORS + 1):
		GameManager.current_sector = sector
		var world := preload("res://scenes/game_world.tscn").instantiate() as GameWorld
		add_child_autofree(world)
		world._start_star_cluster()
		_complete_required_sector_scans(world, sector)
		if sector < GameManager.MAX_SECTORS:
			assert_eq(GameManager.current_state, GameManager.GameState.SECTOR_TRANSITION, "sector %d should reach sector transition" % sector)
			GameManager.advance_sector()
		else:
			assert_eq(GameManager.current_state, GameManager.GameState.WIN)
			assert_true(GameManager.has_won())
			assert_true(GameManager.mothership_defeated)

func _complete_required_sector_scans(world: GameWorld, sector: int) -> void:
	var configs: Array = StarClusterManager.SECTOR_STARS[sector]
	for cfg_variant in configs:
		var cfg: Dictionary = cfg_variant
		if cfg.get("optional", false) or cfg.get("hidden", false) or cfg.has("mandatory_after"):
			continue
		var scan_data := cfg.duplicate()
		scan_data["reward"] = ""
		world._star_cluster_mgr._on_scan_completed(String(cfg.get("result", "")), scan_data, null, cfg)
		if cfg.get("result", "") == "alien_territory":
			assert_true(world._in_arena, "sector %d alien scan should enter arena" % sector)
			world._on_arena_cleared()
	if sector == GameManager.MAX_SECTORS:
		world._star_cluster_mgr._on_scan_completed("mothership", {
			"id":"E4",
			"wave_path":"res://assets/data/waves/sector_5_mothership.json"
		}, null, {"id":"E4", "mandatory_after":"E3"})
		assert_true(world._in_arena)
		world.on_mothership_defeated()
