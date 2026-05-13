## test_arena_wave_spawner.gd — Unit tests for arena wave and boss wiring.
extends GutTest

class DummyGameWorld:
	extends Node
	var mothership_defeat_calls: int = 0

	func _ready() -> void:
		add_to_group("game_world")

	func on_mothership_defeated() -> void:
		mothership_defeat_calls += 1

var spawner: ArenaWaveSpawner
var enemy_container: Node2D
var projectile_container: Node2D
var dummy_world: DummyGameWorld

func before_each() -> void:
	GameManager.start_new_game()
	spawner = ArenaWaveSpawner.new()
	enemy_container = Node2D.new()
	projectile_container = Node2D.new()
	dummy_world = DummyGameWorld.new()
	add_child_autofree(dummy_world)
	add_child_autofree(enemy_container)
	add_child_autofree(projectile_container)
	add_child_autofree(spawner)
	spawner.enemy_container = enemy_container
	spawner.enemy_projectile_container = projectile_container

func test_mothership_wave_spawns_boss_and_blocks_escape() -> void:
	spawner.start("res://assets/data/waves/sector_5_mothership.json")

	assert_eq(enemy_container.get_child_count(), 1)
	var boss := enemy_container.get_child(0)
	assert_true(boss is Mothership)
	assert_eq((boss as Mothership).drop_table, "mothership")
	assert_true(spawner._is_boss_wave, "Mothership wave should be marked as boss wave")
	assert_true(spawner._escape_blocked, "Escape should be blocked during the final boss")
	assert_eq(spawner._enemies_alive, 1)

func test_mothership_death_notifies_game_world() -> void:
	spawner.start("res://assets/data/waves/sector_5_mothership.json")

	spawner._on_enemy_died(Vector2.ZERO, "mothership")

	assert_eq(spawner._enemies_alive, 0)
	assert_eq(dummy_world.mothership_defeat_calls, 1)
