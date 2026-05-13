## test_mission_prompt.gd — Unit tests for one-time mission-control tutorial prompts.
extends GutTest

const MissionPromptScript := preload("res://src/ui/mission_prompt.gd")

func before_each() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	SaveManager.prompt_history.clear()

func after_each() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)

func test_prompt_shows_once_and_persists_dismissal() -> void:
	var prompt = MissionPromptScript.new()
	add_child_autofree(prompt)
	var shown: Array = []
	prompt.prompt_shown.connect(func(prompt_id, text): shown.append({"id": prompt_id, "text": text}))

	assert_true(prompt.request_prompt("move"))
	assert_eq(prompt.get_current_prompt_id(), "move")
	assert_eq(shown.size(), 1)
	assert_true(String(shown[0]["text"]).contains("navigate"))

	prompt.dismiss_current()
	assert_true(SaveManager.has_seen_prompt("move"))
	assert_false(prompt.request_prompt("move"), "Dismissed prompt should not show again")

func test_prompt_queue_only_displays_one_at_a_time() -> void:
	var prompt = MissionPromptScript.new()
	add_child_autofree(prompt)

	assert_true(prompt.request_prompt("move"))
	assert_true(prompt.request_prompt("fire"))
	assert_eq(prompt.get_current_prompt_id(), "move")
	assert_eq(prompt.get_queued_count(), 1)

	prompt.dismiss_current()
	assert_eq(prompt.get_current_prompt_id(), "fire")
	assert_eq(prompt.get_queued_count(), 0)

func test_prompt_auto_dismisses_after_duration() -> void:
	var prompt = MissionPromptScript.new()
	add_child_autofree(prompt)
	prompt.default_duration = 0.5

	assert_true(prompt.request_prompt("pickup"))
	prompt._process(0.6)

	assert_eq(prompt.get_current_prompt_id(), "")
	assert_true(SaveManager.has_seen_prompt("pickup"))
