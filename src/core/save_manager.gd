## SaveManager — Persists high scores and settings.
## Autoloaded singleton.
extends Node

const SAVE_PATH := "user://nova_scout_save.json"
const MAX_HIGH_SCORES := 10

var high_scores: Array[Dictionary] = []
var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"fullscreen": false,
}

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

func save_settings() -> void:
	save_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		return
	var data_dict := data as Dictionary
	if data_dict.has("high_scores"):
		high_scores.clear()
		for entry: Variant in data_dict["high_scores"]:
			if entry is Dictionary:
				high_scores.append(entry as Dictionary)
	if data_dict.has("settings"):
		settings.merge(data_dict["settings"] as Dictionary, true)

func save_data() -> void:
	var data := {
		"high_scores": high_scores,
		"settings": settings
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
