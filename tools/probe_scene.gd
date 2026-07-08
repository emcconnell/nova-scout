## Screenshot probe scene — boots the real game_world in PROBE_SECTOR, waits
## PROBE_WAIT seconds, saves PROBE_NAME.png into .probe_out/, quits.
## Run: PROBE_SECTOR=5 PROBE_WAIT=3 PROBE_NAME=dead godot --path . res://tools/probe_scene.tscn
extends Node

func _ready() -> void:
	var sector := maxi(int(OS.get_environment("PROBE_SECTOR").to_int()), 1)
	var wait_s := maxf(OS.get_environment("PROBE_WAIT").to_float(), 0.5)
	var shot_name := OS.get_environment("PROBE_NAME")
	if shot_name.is_empty():
		shot_name = "world_s%d" % sector

	GameManager.start_new_game()
	GameManager.current_sector = sector
	var world: Node = load("res://scenes/game_world.tscn").instantiate()
	get_parent().add_child.call_deferred(world)

	# PROBE_SPAWN="scout:60:60,warrior:120:70,rock0:160:90..." — showcase
	# placement. rockN = asteroid tier N (0-2), held static for lighting shots.
	var spawn_spec := OS.get_environment("PROBE_SPAWN")
	if not spawn_spec.is_empty():
		await get_tree().create_timer(0.3).timeout
		for entry in spawn_spec.split(","):
			var parts := entry.split(":")
			if parts.size() != 3:
				continue
			var pos := Vector2(parts[1].to_float(), parts[2].to_float())
			if parts[0].begins_with("rock"):
				var rock: Node2D = load("res://scenes/hazards/asteroid.tscn").instantiate()
				world.get_node("Hazards").add_child(rock)
				rock.global_position = pos
				rock.setup(parts[0].trim_prefix("rock").to_int(), Vector2.ZERO)
			elif world.has_method("spawn_enemy_at"):
				world.spawn_enemy_at(parts[0], pos)

	await get_tree().create_timer(wait_s).timeout
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://.probe_out"))
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://.probe_out/%s.png" % shot_name))
	print("probe: saved ", shot_name, " blend=", VisualState.blend())
	if OS.get_environment("PROBE_DEBUG_VEIL") == "1":
		for child in world.get_children():
			if child is DarknessVeil:
				print("veil: visible=", child.visible, " alpha=", child.get("_current_alpha"),
					" dread=", SaveManager.get_setting("dread_intensity"),
					" size=", (child as Control).size, " state=", GameManager.current_state)
	get_tree().quit()
