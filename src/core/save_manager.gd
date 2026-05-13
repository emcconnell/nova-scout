## SaveManager — Persists high scores and settings.
## Autoloaded singleton.
extends Node

const SAVE_PATH := "user://nova_scout_save.json"
const MAX_HIGH_SCORES := 10
const DEFAULT_SETTINGS := {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"screen_shake": 1.0,
	"crt_enabled": true,
	"flash_intensity": 1.0,
	"text_scale": 1.0,
	"hold_to_boost": true,
	"color_friendly": false,
}

var high_scores: Array[Dictionary] = []
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var prompt_history: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()

func save_high_score(score: int, sector: int, beacons: int, ending: String) -> void:
	var entry := {
		"score": score,
		"sector": sector,
		"beacons": beacons,
		"ending": ending,
		"date": Time.get_date_string_from_system()
	}
	high_scores.append(entry)
	high_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	if high_scores.size() > MAX_HIGH_SCORES:
		high_scores.resize(MAX_HIGH_SCORES)
	save_data()

func get_high_scores() -> Array[Dictionary]:
	return high_scores

## Return a setting value with safe fallback when the key is missing.
func get_setting(key: String) -> Variant:
	if settings.has(key):
		return settings[key]
	return DEFAULT_SETTINGS.get(key)

## Set a known setting only when the value matches the default type.
func set_setting(key: String, value: Variant, persist: bool = true) -> bool:
	if not DEFAULT_SETTINGS.has(key):
		return false
	var default_value: Variant = DEFAULT_SETTINGS[key]
	if typeof(value) != typeof(default_value):
		if typeof(default_value) == TYPE_FLOAT and typeof(value) == TYPE_INT:
			value = float(value)
		else:
			return false
	settings[key] = value
	if persist:
		save_settings()
	return true

func save_settings() -> void:
	save_data()

## Return true when a one-time mission-control prompt has already been dismissed.
func has_seen_prompt(prompt_id: String) -> bool:
	return bool(prompt_history.get(prompt_id, false))

## Persist a one-time mission-control prompt dismissal.
func mark_prompt_seen(prompt_id: String) -> void:
	if prompt_id.is_empty():
		return
	prompt_history[prompt_id] = true
	save_data()

## Clear tutorial prompt history so onboarding can be replayed or QA'd.
func reset_prompt_history() -> void:
	prompt_history.clear()
	save_data()

func load_data() -> void:
	_ensure_default_settings()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return
	var data: Variant = parser.data
	if not data is Dictionary:
		return
	var data_dict := data as Dictionary
	if data_dict.get("high_scores") is Array:
		high_scores.clear()
		for entry: Variant in data_dict["high_scores"]:
			if entry is Dictionary:
				high_scores.append(entry as Dictionary)
	elif data_dict.has("high_scores"):
		high_scores.clear()
	if data_dict.get("settings") is Dictionary:
		_merge_valid_settings(data_dict["settings"] as Dictionary)
	if data_dict.get("prompt_history") is Dictionary:
		prompt_history.clear()
		for key: Variant in data_dict["prompt_history"].keys():
			var seen: Variant = data_dict["prompt_history"][key]
			if key is String and seen is bool:
				prompt_history[key] = seen
	elif data_dict.has("prompt_history"):
		prompt_history.clear()

func _ensure_default_settings() -> void:
	for key in DEFAULT_SETTINGS.keys():
		if not settings.has(key):
			settings[key] = DEFAULT_SETTINGS[key]

func _merge_valid_settings(saved_settings: Dictionary) -> void:
	_ensure_default_settings()
	for key in DEFAULT_SETTINGS.keys():
		if not saved_settings.has(key):
			continue
		var saved_value: Variant = saved_settings[key]
		var default_value: Variant = DEFAULT_SETTINGS[key]
		if typeof(saved_value) == typeof(default_value):
			settings[key] = saved_value
		elif typeof(default_value) == TYPE_FLOAT and typeof(saved_value) == TYPE_INT:
			settings[key] = float(saved_value)

func save_data() -> void:
	var data := {
		"high_scores": high_scores,
		"settings": settings,
		"prompt_history": prompt_history,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
