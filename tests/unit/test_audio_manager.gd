## test_audio_manager.gd — Unit tests for level music rotation behavior.
extends GutTest

func before_each() -> void:
	GameManager.start_new_game()
	GameManager.change_state(GameManager.GameState.TRAVEL)
	AudioManager._audio_enabled = false
	AudioManager._current_track = ""
	AudioManager._level_music_active = false
	AudioManager._level_music_timer = 0.0
	AudioManager._level_music_index = 0

func after_each() -> void:
	AudioManager._current_track = ""
	AudioManager._level_music_active = false
	AudioManager._level_music_timer = 0.0
	AudioManager._level_music_index = 0
	GameManager.current_state = GameManager.GameState.MENU

func test_sector_music_starts_at_sector_theme_and_enables_rotation() -> void:
	AudioManager.play_sector_music(3)
	assert_true(AudioManager._level_music_active)
	assert_eq(AudioManager._current_track, "nebula_crossing")
	assert_eq(AudioManager._level_music_index, 2)

func test_level_music_rotates_to_new_feeling_after_two_minutes() -> void:
	AudioManager.play_sector_music(1)
	AudioManager._process(AudioManager.LEVEL_MUSIC_ROTATION_TIME - 1.0)
	assert_eq(AudioManager._current_track, "inner_rim")
	AudioManager._process(1.0)
	assert_eq(AudioManager._current_track, "asteroid_fields")
	assert_eq(AudioManager._level_music_index, 1)

func test_non_level_music_disables_rotation() -> void:
	AudioManager.play_sector_music(1)
	AudioManager.play_music("alien_combat")
	assert_false(AudioManager._level_music_active)
	assert_eq(AudioManager._current_track, "alien_combat")

func test_rotation_pauses_outside_level_states() -> void:
	AudioManager.play_sector_music(1)
	GameManager.change_state(GameManager.GameState.ALIEN_COMBAT)
	AudioManager._process(AudioManager.LEVEL_MUSIC_ROTATION_TIME)
	assert_eq(AudioManager._current_track, "inner_rim")
	assert_eq(AudioManager._level_music_index, 0)
