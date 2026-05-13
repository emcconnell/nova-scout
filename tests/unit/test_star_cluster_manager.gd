## test_star_cluster_manager.gd — Unit tests for campaign star cluster reveal flow.
extends GutTest

var manager: StarClusterManager
var stars_container: Node2D

func before_each() -> void:
	GameManager.start_new_game()
	manager = StarClusterManager.new()
	stars_container = Node2D.new()
	add_child_autofree(stars_container)
	add_child_autofree(manager)
	manager.stars_container = stars_container
	manager.setup(5)

func _star_ids() -> Array[String]:
	var ids: Array[String] = []
	for child in stars_container.get_children():
		if child is StarNode:
			ids.append(child.star_data.get("id", ""))
	return ids

func test_sector_5_mothership_is_not_spawned_initially() -> void:
	manager.spawn_stars()
	var ids := _star_ids()
	assert_true(ids.has("E1"))
	assert_true(ids.has("E2"))
	assert_true(ids.has("E3"))
	assert_false(ids.has("E4"), "Mothership star should stay hidden until E3 clears")
	assert_eq(manager._required_cleared, 3)

func test_reveal_mandatory_after_e3_spawns_mothership_once() -> void:
	manager.spawn_stars()
	manager.reveal_mandatory_after("E3")
	manager.reveal_mandatory_after("E3")
	var ids := _star_ids()
	assert_eq(ids.count("E4"), 1)
	assert_eq(manager._required_cleared, 4)

	var mothership_star: StarNode = null
	for child in stars_container.get_children():
		if child is StarNode and child.star_data.get("id", "") == "E4":
			mothership_star = child
	assert_not_null(mothership_star)
	assert_eq(mothership_star.star_data.get("wave_path", ""), "res://assets/data/waves/sector_5_mothership.json")

func test_sector_5_cluster_not_complete_after_e3_reveals_mothership() -> void:
	watch_signals(manager)
	manager.spawn_stars()
	manager._on_scan_completed("alien_territory", {"id":"E1", "wave_path":""}, null, {"id":"E1"})
	manager._on_scan_completed("barren", {"id":"E2"}, null, {"id":"E2"})
	manager.reveal_mandatory_after("E3")
	manager._on_scan_completed("human_viable", {"id":"E3"}, null, {"id":"E3"})
	assert_false(manager.is_complete(), "Cluster should wait for revealed mandatory Mothership")
	assert_signal_not_emitted(manager, "cluster_complete")
