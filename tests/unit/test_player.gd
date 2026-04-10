## test_player.gd — Unit tests for PlayerHealth, PlayerFuel, PlayerWeapons.
## Run via GUT addon in editor.
extends GutTest

# ─── PlayerHealth ─────────────────────────────────────────────────────────────

var _health: PlayerHealth

func before_each() -> void:
	_health = PlayerHealth.new()
	add_child_autofree(_health)
	_health._ready()  # Initialize from GameManager stats

func test_health_starts_at_max_hull() -> void:
	assert_eq(_health.hull, GameManager.player_max_hull,
		"Hull should start at max")

func test_take_damage_reduces_hull() -> void:
	var before := _health.hull
	_health.take_damage(10)
	assert_eq(_health.hull, before - 10)

func test_take_damage_clamps_at_zero() -> void:
	_health.hull = 5
	_health.take_damage(100)
	assert_eq(_health.hull, 0, "Hull should not go below 0")

func test_shield_absorbs_before_hull() -> void:
	_health.shield = 30
	_health.hull = 100
	_health.take_damage(20)
	# Shield should take the hit first
	assert_eq(_health.shield, 10, "Shield should absorb damage first")
	assert_eq(_health.hull, 100, "Hull should be untouched while shield holds")

func test_shield_overflow_damages_hull() -> void:
	_health.shield = 10
	_health.hull = 100
	_health.take_damage(25)
	assert_eq(_health.shield, 0)
	assert_eq(_health.hull, 85, "Overflow damage (15) should hit hull")

func test_died_signal_emits_at_zero_hull() -> void:
	watch_signals(_health)
	_health.shield = 0
	_health.hull = 1
	_health.take_damage(10)
	assert_signal_emitted(_health, "died")

func test_died_signal_only_emits_once() -> void:
	watch_signals(_health)
	_health.shield = 0
	_health.hull = 1
	_health.take_damage(10)
	_health.take_damage(10)  # Second hit on dead player
	assert_signal_emit_count(_health, "died", 1,
		"Died signal should emit exactly once")

func test_reset_restores_full_health() -> void:
	_health.take_damage(50)
	_health.reset()
	assert_eq(_health.hull, GameManager.player_max_hull)

# ─── PlayerFuel ──────────────────────────────────────────────────────────────

var _fuel: PlayerFuel

func before_each_fuel() -> void:
	_fuel = PlayerFuel.new()
	add_child_autofree(_fuel)
	_fuel._ready()

func test_fuel_starts_at_max() -> void:
	var pf := PlayerFuel.new()
	add_child_autofree(pf)
	pf._ready()
	assert_almost_eq(pf.fuel, float(GameManager.player_max_fuel), 0.1)

func test_drain_reduces_fuel() -> void:
	var pf := PlayerFuel.new()
	add_child_autofree(pf)
	pf._ready()
	pf.fuel = 80.0
	pf.drain(20.0)
	assert_almost_eq(pf.fuel, 60.0, 0.01)

func test_drain_clamps_at_zero() -> void:
	var pf := PlayerFuel.new()
	add_child_autofree(pf)
	pf._ready()
	pf.fuel = 5.0
	pf.drain(100.0)
	assert_almost_eq(pf.fuel, 0.0, 0.01)

func test_fuel_empty_signal_emits() -> void:
	var pf := PlayerFuel.new()
	add_child_autofree(pf)
	pf._ready()
	watch_signals(pf)
	pf.fuel = 1.0
	pf.drain(10.0)
	assert_signal_emitted(pf, "fuel_empty")

func test_refuel_increases_fuel() -> void:
	var pf := PlayerFuel.new()
	add_child_autofree(pf)
	pf._ready()
	pf.fuel = 20.0
	pf.refuel(30.0)
	assert_almost_eq(pf.fuel, 50.0, 0.01)

func test_refuel_clamps_at_max() -> void:
	var pf := PlayerFuel.new()
	add_child_autofree(pf)
	pf._ready()
	var max_fuel := float(GameManager.player_max_fuel)
	pf.fuel = max_fuel - 5.0
	pf.refuel(100.0)
	assert_almost_eq(pf.fuel, max_fuel, 0.01, "Fuel should not exceed max")

# ─── PlayerWeapons ───────────────────────────────────────────────────────────

func test_missiles_start_at_player_stat() -> void:
	var pw := PlayerWeapons.new()
	add_child_autofree(pw)
	pw._ready()
	assert_eq(pw.missiles, GameManager.player_missiles)

func test_emp_starts_at_player_stat() -> void:
	var pw := PlayerWeapons.new()
	add_child_autofree(pw)
	pw._ready()
	assert_eq(pw.emp_charges, GameManager.player_emp)

func test_reset_restores_weapons() -> void:
	var pw := PlayerWeapons.new()
	add_child_autofree(pw)
	pw._ready()
	pw.missiles = 0
	pw.emp_charges = 0
	pw.reset()
	assert_eq(pw.missiles, GameManager.player_missiles)
	assert_eq(pw.emp_charges, GameManager.player_emp)
