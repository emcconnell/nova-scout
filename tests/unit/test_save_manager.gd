## test_save_manager.gd — Unit tests for save/settings corruption safety.
extends GutTest

func before_each() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	SaveManager.high_scores.clear()
	SaveManager.prompt_history.clear()
	SaveManager.settings = {
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

func after_each() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)

func _write_save_text(text: String) -> void:
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string(text)
	file.close()

func test_missing_save_uses_safe_defaults() -> void:
	SaveManager.settings = {}
	SaveManager.load_data()

	assert_eq(SaveManager.high_scores.size(), 0)
	assert_eq(SaveManager.settings.get("music_volume"), 0.8)
	assert_eq(SaveManager.settings.get("sfx_volume"), 1.0)
	assert_eq(SaveManager.settings.get("fullscreen"), false)
	assert_eq(SaveManager.settings.get("screen_shake"), 1.0)
	assert_eq(SaveManager.settings.get("crt_enabled"), true)
	assert_eq(SaveManager.settings.get("flash_intensity"), 1.0)
	assert_eq(SaveManager.settings.get("text_scale"), 1.0)
	assert_eq(SaveManager.settings.get("hold_to_boost"), true)
	assert_eq(SaveManager.settings.get("color_friendly"), false)

func test_corrupted_save_json_does_not_crash_or_clear_defaults() -> void:
	_write_save_text("{ this is not valid json")

	SaveManager.load_data()

	assert_eq(SaveManager.high_scores.size(), 0)
	assert_eq(SaveManager.settings.get("music_volume"), 0.8)
	assert_eq(SaveManager.settings.get("sfx_volume"), 1.0)
	assert_eq(SaveManager.settings.get("fullscreen"), false)
	assert_eq(SaveManager.settings.get("screen_shake"), 1.0)
	assert_eq(SaveManager.settings.get("crt_enabled"), true)
	assert_eq(SaveManager.settings.get("flash_intensity"), 1.0)
	assert_eq(SaveManager.settings.get("text_scale"), 1.0)
	assert_eq(SaveManager.settings.get("hold_to_boost"), true)
	assert_eq(SaveManager.settings.get("color_friendly"), false)

func test_malformed_settings_type_does_not_crash_or_replace_defaults() -> void:
	_write_save_text(JSON.stringify({"settings": ["bad"], "high_scores": []}))

	SaveManager.load_data()

	assert_eq(SaveManager.settings.get("music_volume"), 0.8)
	assert_eq(SaveManager.settings.get("sfx_volume"), 1.0)
	assert_eq(SaveManager.settings.get("fullscreen"), false)
	assert_eq(SaveManager.settings.get("screen_shake"), 1.0)
	assert_eq(SaveManager.settings.get("crt_enabled"), true)
	assert_eq(SaveManager.settings.get("flash_intensity"), 1.0)
	assert_eq(SaveManager.settings.get("text_scale"), 1.0)
	assert_eq(SaveManager.settings.get("hold_to_boost"), true)
	assert_eq(SaveManager.settings.get("color_friendly"), false)

func test_malformed_high_scores_type_does_not_crash() -> void:
	_write_save_text(JSON.stringify({"settings": {"music_volume": 0.25}, "high_scores": "bad"}))

	SaveManager.load_data()

	assert_eq(SaveManager.high_scores.size(), 0)
	assert_eq(SaveManager.settings.get("music_volume"), 0.25)

func test_prompt_history_defaults_to_empty_and_tracks_dismissals() -> void:
	SaveManager.load_data()

	assert_false(SaveManager.has_seen_prompt("move"))
	SaveManager.mark_prompt_seen("move")
	assert_true(SaveManager.has_seen_prompt("move"))

func test_malformed_prompt_history_type_does_not_crash() -> void:
	_write_save_text(JSON.stringify({"settings": {}, "prompt_history": ["bad"]}))

	SaveManager.load_data()

	assert_eq(SaveManager.prompt_history.size(), 0)

func test_set_setting_accepts_known_keys_and_rejects_wrong_types() -> void:
	assert_true(SaveManager.set_setting("screen_shake", 0.5, false))
	assert_eq(SaveManager.get_setting("screen_shake"), 0.5)
	assert_true(SaveManager.set_setting("screen_shake", 1, false))
	assert_eq(SaveManager.get_setting("screen_shake"), 1.0)
	assert_false(SaveManager.set_setting("screen_shake", "loud", false))
	assert_eq(SaveManager.get_setting("screen_shake"), 1.0)
	assert_false(SaveManager.set_setting("unknown_option", true, false))

func test_get_setting_returns_default_when_runtime_dictionary_is_missing_key() -> void:
	SaveManager.settings = {"music_volume": 0.25}

	assert_eq(SaveManager.get_setting("music_volume"), 0.25)
	assert_eq(SaveManager.get_setting("screen_shake"), 1.0)
	assert_eq(SaveManager.get_setting("crt_enabled"), true)
