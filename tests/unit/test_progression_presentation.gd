extends GutTest

const UPGRADE_SCREEN_PATH := "res://src/ui/upgrade_screen.gd"
const SECTOR_TRANSITION_PATH := "res://src/ui/sector_transition.gd"

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected %s to be readable" % path)
	if file == null:
		return ""
	return file.get_as_text()

func test_upgrade_screen_labels_basic_branch_identity() -> void:
	var text := _read_text(UPGRADE_SCREEN_PATH)
	assert_true(text.contains("SURVIVOR"), "Upgrade screen should label defensive/sustain branch identity")
	assert_true(text.contains("EXPLORER"), "Upgrade screen should label range/resource branch identity")
	assert_true(text.contains("FIGHTER"), "Upgrade screen should label combat branch identity")

func test_sector_transition_shows_bonus_breakdown() -> void:
	var text := _read_text(SECTOR_TRANSITION_PATH)
	assert_true(text.contains("_sector_bonus_lines"), "Sector transition should expose sector bonus breakdown helper")
	assert_true(text.contains("FUEL RESERVE"), "Sector transition should show fuel-reserve bonus")
	assert_true(text.contains("BEACON DATA"), "Sector transition should show beacon/data bonus")
