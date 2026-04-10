## test_game_manager.gd — Unit tests for GameManager state machine and economy.
## Run with: gdscript --no-window tests/unit/test_game_manager.gd
## Or via GUT addon: autorun in editor.
extends GutTest

# ─── Setup ───────────────────────────────────────────────────────────────────

func before_each() -> void:
	# Reset GameManager to a clean state before each test
	GameManager.start_new_game()

# ─── State Machine ───────────────────────────────────────────────────────────

func test_initial_state_is_menu() -> void:
	# GameManager starts in MENU when freshly loaded
	assert_eq(GameManager.current_state, GameManager.GameState.MENU,
		"Initial state should be MENU")

func test_change_state_emits_signal() -> void:
	watch_signals(GameManager)
	GameManager.change_state(GameManager.GameState.TRAVEL)
	assert_signal_emitted_with_parameters(GameManager, "state_changed",
		[GameManager.GameState.TRAVEL])

func test_change_state_no_duplicate_emit() -> void:
	GameManager.change_state(GameManager.GameState.TRAVEL)
	watch_signals(GameManager)
	GameManager.change_state(GameManager.GameState.TRAVEL)  # same state
	assert_signal_not_emitted(GameManager, "state_changed",
		"Should not emit when state unchanged")

func test_is_state_helper() -> void:
	GameManager.change_state(GameManager.GameState.SCANNING)
	assert_true(GameManager.is_state(GameManager.GameState.SCANNING))
	assert_false(GameManager.is_state(GameManager.GameState.TRAVEL))

# ─── Score & Economy ─────────────────────────────────────────────────────────

func test_add_score_increments_correctly() -> void:
	GameManager.score = 0
	GameManager.score_multiplier = 1
	GameManager.add_score(100)
	assert_eq(GameManager.score, 100)

func test_score_multiplier_applies() -> void:
	GameManager.score = 0
	GameManager.set_multiplier(3)
	GameManager.add_score(100)
	assert_eq(GameManager.score, 300)

func test_set_multiplier_clamps_to_max() -> void:
	GameManager.set_multiplier(99)
	assert_eq(GameManager.score_multiplier, 8, "Multiplier should clamp at 8")

func test_set_multiplier_clamps_to_min() -> void:
	GameManager.set_multiplier(0)
	assert_eq(GameManager.score_multiplier, 1, "Multiplier should clamp at 1")

func test_add_crystal() -> void:
	GameManager.data_crystals = 0
	GameManager.add_crystal(3)
	assert_eq(GameManager.data_crystals, 3)

func test_spend_crystals_success() -> void:
	GameManager.data_crystals = 10
	var result := GameManager.spend_crystals(5)
	assert_true(result, "Should succeed with enough crystals")
	assert_eq(GameManager.data_crystals, 5)

func test_spend_crystals_insufficient() -> void:
	GameManager.data_crystals = 2
	var result := GameManager.spend_crystals(5)
	assert_false(result, "Should fail with insufficient crystals")
	assert_eq(GameManager.data_crystals, 2, "Crystals should be unchanged")

# ─── Beacons & Win Condition ─────────────────────────────────────────────────

func test_has_won_false_at_start() -> void:
	assert_false(GameManager.has_won())

func test_has_won_after_three_beacons() -> void:
	GameManager.collect_beacon()
	GameManager.collect_beacon()
	assert_false(GameManager.has_won(), "2 beacons should not win yet")
	GameManager.collect_beacon()
	assert_true(GameManager.has_won(), "3 beacons should trigger win")

func test_beacon_gives_score() -> void:
	GameManager.score = 0
	GameManager.score_multiplier = 1
	GameManager.collect_beacon()
	assert_eq(GameManager.score, 3000)

# ─── Sector Progression ──────────────────────────────────────────────────────

func test_start_new_game_resets_sector() -> void:
	GameManager.current_sector = 4
	GameManager.start_new_game()
	assert_eq(GameManager.current_sector, 1)

func test_advance_sector_increments() -> void:
	GameManager.start_new_game()
	assert_eq(GameManager.current_sector, 1)
	GameManager.advance_sector()
	assert_eq(GameManager.current_sector, 2)

func test_is_final_sector_at_five() -> void:
	GameManager.start_new_game()
	for i in 4:
		GameManager.advance_sector()
	assert_true(GameManager.is_final_sector(), "Sector 5 should be final")

func test_is_not_final_sector_early() -> void:
	GameManager.start_new_game()
	assert_false(GameManager.is_final_sector())

# ─── Upgrades ────────────────────────────────────────────────────────────────

func test_apply_upgrade_hull_costs_crystals() -> void:
	GameManager.data_crystals = 5
	var result := GameManager.apply_upgrade("hull")
	assert_true(result)
	assert_eq(GameManager.data_crystals, 0)

func test_apply_upgrade_fails_without_crystals() -> void:
	GameManager.data_crystals = 0
	var result := GameManager.apply_upgrade("hull")
	assert_false(result)

func test_apply_upgrade_hull_increases_max() -> void:
	GameManager.start_new_game()
	GameManager.data_crystals = 5
	var old_max := GameManager.player_max_hull
	GameManager.apply_upgrade("hull")
	assert_eq(GameManager.player_max_hull, old_max + 20)

func test_get_sector_name_returns_string() -> void:
	GameManager.start_new_game()
	var name := GameManager.get_sector_name()
	assert_false(name.is_empty(), "Sector name should not be empty")
	assert_true(name.contains("ALPHA"), "Sector 1 should be ALPHA")
