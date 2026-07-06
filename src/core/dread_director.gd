## DreadDirector — Orchestrates the fear layer: heartbeat, hull groans,
## danger-pay state, and aggregate threat level for CRT interference.
## Created by GameWorld. Balance data: assets/data/dread.json.
## GDD Ref: dark-directive.md §4.1, §4.3
class_name DreadDirector
extends Node

var _player: Player = null
var _heartbeat_timer: float = 0.0
var _groan_timer: float = 0.0
var _scan_check_timer: float = 0.0

func _ready() -> void:
	_groan_timer = randf_range(8.0, 16.0)
	GameManager.danger_pay_changed.connect(_on_danger_pay_changed)

func _exit_tree() -> void:
	if GameManager.danger_pay_changed.is_connected(_on_danger_pay_changed):
		GameManager.danger_pay_changed.disconnect(_on_danger_pay_changed)

func _on_danger_pay_changed(active: bool) -> void:
	if active:
		AudioManager.play_sfx("alarm_danger", 0.65)

## Wire the player whose hull drives the heartbeat and danger pay.
func connect_player(p: Player) -> void:
	_player = p
	p.health.hull_changed.connect(_on_hull_changed)
	_on_hull_changed(p.health.hull)

func _on_hull_changed(_v: int) -> void:
	GameManager.refresh_danger_pay()
	_update_hull_threat()

func _update_hull_threat() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var pct := float(_player.health.hull) / maxf(float(GameManager.player_max_hull), 1.0)
	# Threat rises as hull drops below 40%; max contribution 0.55
	var threat := clampf((0.40 - pct) / 0.40, 0.0, 1.0) * 0.55
	GameManager.set_threat("hull", threat)

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var state := GameManager.current_state
	if state in [GameManager.GameState.MENU, GameManager.GameState.DEATH, GameManager.GameState.WIN]:
		return

	_update_heartbeat(delta)
	_update_groans(delta)
	_update_scan_threat(delta)

## Heartbeat loop while hull-critical; tempo rises as hull falls.
func _update_heartbeat(delta: float) -> void:
	var hull_pct := float(_player.health.hull) / maxf(float(GameManager.player_max_hull), 1.0)
	var threshold: float = float(GameManager.dread_value("heartbeat", "hull_threshold", 0.25))
	if hull_pct >= threshold:
		return
	_heartbeat_timer -= delta
	if _heartbeat_timer <= 0.0:
		var calm: float = float(GameManager.dread_value("heartbeat", "interval_calm", 1.1))
		var panic: float = float(GameManager.dread_value("heartbeat", "interval_panic", 0.62))
		# 0 at threshold → 1 near death
		var panic_t := clampf(1.0 - hull_pct / maxf(threshold, 0.01), 0.0, 1.0)
		_heartbeat_timer = lerpf(calm, panic, panic_t)
		AudioManager.play_sfx("heartbeat", 0.9)

## Random hull stress groans below 40% hull — the ship complains.
func _update_groans(delta: float) -> void:
	var hull_pct := float(_player.health.hull) / maxf(float(GameManager.player_max_hull), 1.0)
	if hull_pct >= 0.40:
		return
	_groan_timer -= delta
	if _groan_timer <= 0.0:
		_groan_timer = randf_range(9.0, 20.0)
		AudioManager.play_sfx("hull_groan", randf_range(0.5, 0.8))

## While any star is being scanned, broadcasting raises the threat floor.
func _update_scan_threat(delta: float) -> void:
	_scan_check_timer -= delta
	if _scan_check_timer > 0.0:
		return
	_scan_check_timer = 0.2
	var scanning_progress := -1.0
	for star in get_tree().get_nodes_in_group("star_nodes"):
		if star is StarNode and (star as StarNode).is_scanning():
			scanning_progress = maxf(scanning_progress, (star as StarNode).get_scan_progress())
	if scanning_progress >= 0.0:
		GameManager.set_threat("scan", 0.25 + scanning_progress * 0.45)
	else:
		GameManager.set_threat("scan", 0.0)
