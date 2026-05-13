extends GutTest

const UPGRADE_SCREEN_PATH := "res://src/ui/upgrade_screen.gd"

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected %s to be readable" % path)
	if file == null:
		return ""
	return file.get_as_text()

func test_upgrade_screen_shows_current_to_next_comparison() -> void:
	var text := _read_text(UPGRADE_SCREEN_PATH)
	assert_true(text.contains("_upgrade_comparison_text"), "Upgrade screen should expose current-to-next comparison helper")
	assert_true(text.contains("→"), "Upgrade screen should show current → next values")
	assert_true(text.contains("CURRENT → NEXT"), "Upgrade screen should label comparison intent")

func test_upgrade_screen_uses_controller_friendly_hints() -> void:
	var text := _read_text(UPGRADE_SCREEN_PATH)
	assert_true(text.contains("STICK SELECT"), "Upgrade screen should advertise controller navigation")
	assert_true(text.contains("A / SPACE INSTALL"), "Upgrade screen should advertise gamepad A and keyboard install")
