## test_dread_systems.gd — Unit tests for Dark Directive systems:
## danger pay, streak decay fuse, threat aggregation, dread config, log fragments.
## GDD Ref: design/gdd/dark-directive.md §8 Acceptance Criteria
extends GutTest

func before_each() -> void:
	GameManager.start_new_game()
	GameManager.change_state(GameManager.GameState.TRAVEL)

func after_each() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager.clear_threats()

# ─── Danger pay (hull-critical score bonus) ──────────────────────────────────

func test_danger_pay_inactive_at_full_hull() -> void:
	GameManager.player_hull = 100
	GameManager.player_max_hull = 100
	GameManager.score = 0
	GameManager.add_score(100)
	assert_eq(GameManager.score, 100, "Full hull earns base score")
	assert_false(GameManager.danger_pay_active)

func test_danger_pay_applies_below_threshold() -> void:
	GameManager.player_hull = 20   # 20% < 25% threshold
	GameManager.player_max_hull = 100
	GameManager.score = 0
	GameManager.add_score(100)
	assert_eq(GameManager.score, 150, "Hull-critical score gains x1.5")
	assert_true(GameManager.danger_pay_active)

func test_danger_pay_signal_on_flip() -> void:
	GameManager.player_hull = 100
	GameManager.refresh_danger_pay()
	watch_signals(GameManager)
	GameManager.player_hull = 10
	GameManager.refresh_danger_pay()
	assert_signal_emitted_with_parameters(GameManager, "danger_pay_changed", [true])

func test_beacon_score_exempt_from_danger_pay() -> void:
	GameManager.player_hull = 10
	GameManager.player_max_hull = 100
	GameManager.score = 0
	GameManager.collect_beacon()
	assert_eq(GameManager.score, 3000, "Beacon base value is exempt from danger pay")

func test_danger_pay_stacks_with_streak_multiplier() -> void:
	GameManager.player_hull = 10
	GameManager.player_max_hull = 100
	GameManager.set_multiplier(2)
	GameManager.score = 0
	GameManager.add_score(100)
	assert_eq(GameManager.score, 300, "100 x2 streak x1.5 danger pay = 300")

# ─── Streak decay fuse ───────────────────────────────────────────────────────

func test_kill_sets_streak_fuse() -> void:
	GameManager.on_enemy_killed()
	assert_gt(GameManager.streak_fuse, 0.0, "Kill arms the decay fuse")

func test_streak_decays_after_fuse_expires() -> void:
	GameManager.on_enemy_killed()
	GameManager.on_enemy_killed()
	assert_eq(GameManager.kill_streak, 2)
	GameManager._process(7.0)   # Past the 6s decay window
	assert_eq(GameManager.kill_streak, 0, "Streak resets after fuse expires")
	assert_eq(GameManager.streak_multiplier, 1)

func test_streak_survives_within_fuse_window() -> void:
	GameManager.on_enemy_killed()
	GameManager._process(2.0)
	assert_eq(GameManager.kill_streak, 1, "Streak persists inside the window")

func test_streak_fuse_not_ticking_in_menu() -> void:
	GameManager.on_enemy_killed()
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager._process(10.0)
	assert_eq(GameManager.kill_streak, 1, "Fuse pauses outside gameplay states")

# ─── Threat aggregation ──────────────────────────────────────────────────────

func test_threat_defaults_to_zero() -> void:
	assert_eq(GameManager.get_threat(), 0.0)

func test_threat_takes_maximum_of_sources() -> void:
	GameManager.set_threat("hull", 0.3)
	GameManager.set_threat("stalker", 0.8)
	assert_almost_eq(GameManager.get_threat(), 0.8, 0.001)

func test_threat_source_clears_at_zero() -> void:
	GameManager.set_threat("stalker", 0.8)
	GameManager.set_threat("stalker", 0.0)
	assert_eq(GameManager.get_threat(), 0.0)

func test_threat_clamped_to_unit_range() -> void:
	GameManager.set_threat("hull", 4.0)
	assert_almost_eq(GameManager.get_threat(), 1.0, 0.001)

# ─── Dread config ────────────────────────────────────────────────────────────

func test_dread_config_loaded() -> void:
	assert_false(GameManager.dread.is_empty(), "dread.json should load at startup")

func test_dread_value_reads_config() -> void:
	assert_almost_eq(float(GameManager.dread_value("danger_pay", "score_multiplier", 0.0)), 1.5, 0.001)

func test_dread_value_falls_back_on_missing_key() -> void:
	assert_eq(int(GameManager.dread_value("nonexistent", "key", 42)), 42)

func test_dread_value_coerces_int_defaults() -> void:
	var v: Variant = GameManager.dread_value("stalker", "hp", 0)
	assert_typeof(v, TYPE_INT, "JSON floats coerce to int when default is int")

# ─── Log fragments ───────────────────────────────────────────────────────────

func test_log_fragments_serve_in_fixed_order() -> void:
	var first := LogFragments.next_fragment()
	var second := LogFragments.next_fragment()
	assert_eq(String(first["id"]), "p01", "Escalation is authored: P-01 first")
	assert_eq(String(second["id"]), "p03")

func test_log_fragments_exhaust_cleanly() -> void:
	for i in LogFragments.total_count():
		assert_false(LogFragments.next_fragment().is_empty())
	assert_true(LogFragments.next_fragment().is_empty(), "Pool exhausts to empty dict")

func test_log_fragments_reset_on_new_game() -> void:
	LogFragments.next_fragment()
	assert_eq(LogFragments.recovered_count(), 1)
	GameManager.start_new_game()
	assert_eq(LogFragments.recovered_count(), 0, "New run rewinds the log pool")
