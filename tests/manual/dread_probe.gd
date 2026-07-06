## dread_probe.gd — Automated live playtest of Dark Directive systems.
## Boots straight into a chosen sector, holds fire, drifts, force-spawns
## The Silence, and self-quits. Run WITH rendering so _draw paths execute:
##   godot --path . -s tests/manual/dread_probe.gd
## Optional: DREAD_PROBE_SECTOR env var (default 3).
## Note: autoloads are resolved via /root at runtime — SceneTree scripts
## cannot reference autoload identifiers at compile time.
extends SceneTree

const RUN_SECONDS := 40.0
const STALKER_AT := 6.0

var _elapsed: float = 0.0
var _started: bool = false
var _stalker_spawned: bool = false
var _drift_dir: float = 1.0
var _gm: Node = null
var _last_state: int = -1

func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_gm = root.get_node("/root/GameManager")
		var sector := 3
		if OS.get_environment("DREAD_PROBE_SECTOR") != "":
			sector = int(OS.get_environment("DREAD_PROBE_SECTOR"))
		print("[dread_probe] starting in sector %d for %.0fs" % [sector, RUN_SECONDS])
		_gm.start_new_game()
		_gm.current_sector = sector
		change_scene_to_file("res://scenes/game_world.tscn")
		return false

	_elapsed += delta

	# Trace state transitions
	if _gm.current_state != _last_state:
		print("[dread_probe] state %d -> %d at t=%.1fs" % [_last_state, _gm.current_state, _elapsed])
		_last_state = _gm.current_state

	# Hold fire the whole run; drift left/right on a slow cycle
	Input.action_press("fire_laser")
	if fmod(_elapsed, 4.0) < 0.05:
		_drift_dir *= -1.0
	Input.action_release("move_left" if _drift_dir > 0 else "move_right")
	Input.action_press("move_right" if _drift_dir > 0 else "move_left")

	# Force The Silence early so its full cycle runs inside the probe window
	if not _stalker_spawned and _elapsed >= STALKER_AT:
		_stalker_spawned = true
		var gw: Node = _gm.game_world
		if gw and gw.has_method("spawn_enemy_at"):
			gw.spawn_enemy_at("silence", Vector2(160, -30))
			print("[dread_probe] stalker spawned")

	# Periodic status
	if fmod(_elapsed, 5.0) < delta:
		print("[dread_probe] t=%.0fs state=%d hull=%d threat=%.2f streak=%d" % [
			_elapsed, _gm.current_state, _gm.player_hull,
			_gm.get_threat(), _gm.kill_streak])

	if _elapsed >= RUN_SECONDS:
		print("[dread_probe] complete: score=%d enemies=%d threat=%.2f" % [
			_gm.score, _gm.enemies_destroyed, _gm.get_threat()])
		quit(0)
		return true
	return false
