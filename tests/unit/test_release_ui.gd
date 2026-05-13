extends GutTest

const MAIN_MENU_PATH := "res://src/core/main_menu.gd"
const PAUSE_MENU_PATH := "res://src/ui/pause_menu.gd"

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected %s to be readable" % path)
	if file == null:
		return ""
	return file.get_as_text()

func test_main_menu_hides_sector_skip_debug_ui() -> void:
	var text := _read_text(MAIN_MENU_PATH)
	assert_false(text.contains("1-5 SECTOR"), "Release main menu should not advertise debug sector skip")
	assert_false(text.contains("_start_at_sector"), "Release main menu should not keep sector-skip entry point")
	assert_false(text.contains("KEY_1 + key_i"), "Release main menu should not process number-key sector skips")

func test_menu_hints_are_controller_friendly() -> void:
	var main_text := _read_text(MAIN_MENU_PATH)
	var pause_text := _read_text(PAUSE_MENU_PATH)
	assert_true(main_text.contains("←/→ SELECT"), "Main menu should advertise controller/stick navigation")
	assert_true(main_text.contains("A / SPACE"), "Main menu should advertise gamepad A and keyboard confirm")
	assert_true(pause_text.contains("STICK SELECT"), "Pause menu should advertise stick/controller navigation")
	assert_true(pause_text.contains("←/→ ADJUST"), "Pause menu should advertise controller setting adjustment")
