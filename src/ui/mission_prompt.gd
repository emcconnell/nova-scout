## MissionPrompt — one-at-a-time, persistent mission-control tutorial prompts.
class_name MissionPrompt
extends Node

signal prompt_shown(prompt_id: String, text: String)
signal prompt_dismissed(prompt_id: String)

const PROMPTS := {
	"move": "Survey Probe Seven online. WASD / Stick to navigate.",
	"fire": "Break debris with the laser.",
	"boost": "Boost burns fuel. Use it to escape pressure.",
	"pickup": "Crystals fund upgrades. Fuel keeps the probe alive.",
	"scan": "Approach the star and press Scan.",
	"first_discovery": "Signal resolved. Even quiet stars can hide resources, hazards, or a way home.",
	"abort": "Scan locks orbit. Press Scan again to abort.",
	"alien": "Signal spike. Weapons free.",
	"upgrade": "Spend crystals between sectors to shape the run.",
}

var default_duration: float = 4.5
var _current_prompt_id: String = ""
var _current_text: String = ""
var _remaining: float = 0.0
var _queue: Array[String] = []

func _process(delta: float) -> void:
	if _current_prompt_id.is_empty():
		return
	_remaining -= delta
	if _remaining <= 0.0:
		dismiss_current()

## Request a prompt by id; returns false if unknown, already seen, or already active/queued.
func request_prompt(prompt_id: String) -> bool:
	if not PROMPTS.has(prompt_id):
		return false
	if SaveManager.has_seen_prompt(prompt_id):
		return false
	if _current_prompt_id == prompt_id or _queue.has(prompt_id):
		return false
	if _current_prompt_id.is_empty():
		_show_prompt(prompt_id)
	else:
		_queue.append(prompt_id)
	return true

## Dismiss the active prompt and show the next queued prompt, if any.
func dismiss_current() -> void:
	if _current_prompt_id.is_empty():
		return
	var dismissed_id := _current_prompt_id
	SaveManager.mark_prompt_seen(dismissed_id)
	_current_prompt_id = ""
	_current_text = ""
	_remaining = 0.0
	prompt_dismissed.emit(dismissed_id)
	_show_next_queued_prompt()

## Return the active prompt id, or empty string when no prompt is visible.
func get_current_prompt_id() -> String:
	return _current_prompt_id

## Return the active prompt text, or empty string when no prompt is visible.
func get_current_text() -> String:
	return _current_text

## Return the number of prompts waiting behind the active prompt.
func get_queued_count() -> int:
	return _queue.size()

func _show_prompt(prompt_id: String) -> void:
	_current_prompt_id = prompt_id
	_current_text = String(PROMPTS[prompt_id])
	_remaining = default_duration
	prompt_shown.emit(_current_prompt_id, _current_text)

func _show_next_queued_prompt() -> void:
	while not _queue.is_empty():
		var next_id := String(_queue.pop_front())
		if not SaveManager.has_seen_prompt(next_id):
			_show_prompt(next_id)
			return
