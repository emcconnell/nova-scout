## PlayerFuel — Manages fuel consumption and empty-tank events.
class_name PlayerFuel
extends Node

signal fuel_changed(value: float)
signal fuel_critical()   # Below 10%
signal fuel_empty()

var fuel: float = 100.0
var _max_fuel: float = 100.0
var _alarm_playing: bool = false

func _ready() -> void:
	fuel = GameManager.player_fuel
	_max_fuel = float(GameManager.player_max_fuel)

func drain(amount: float) -> void:
	fuel = maxf(fuel - amount, 0.0)
	GameManager.player_fuel = int(fuel)
	fuel_changed.emit(fuel)

	var pct := fuel / _max_fuel
	if pct <= 0.1 and not _alarm_playing:
		_alarm_playing = true
		fuel_critical.emit()
	elif pct > 0.1 and _alarm_playing:
		_alarm_playing = false

	if fuel <= 0.0:
		fuel_empty.emit()

func refuel(amount: float) -> void:
	fuel = minf(fuel + amount, _max_fuel)
	GameManager.player_fuel = int(fuel)
	fuel_changed.emit(fuel)
	if fuel / _max_fuel > 0.1:
		_alarm_playing = false

func get_percent() -> float:
	return fuel / _max_fuel

func reset() -> void:
	_max_fuel = float(GameManager.player_max_fuel)
	fuel = _max_fuel
	GameManager.player_fuel = int(fuel)
	_alarm_playing = false
	fuel_changed.emit(fuel)
