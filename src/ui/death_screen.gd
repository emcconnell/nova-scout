## DeathScreen — Fully opaque blast door + signal lost aesthetic.
## Retry/menu prompt tints to VisualState.pal("accent"); title ghosts at high blend.
## GDD Ref: gameplay-mechanics.md §10 — Death & Retry; art-bible.md Turn 4
extends Control

const COL_BG      := Color(0.02, 0.01, 0.01)
const COL_METAL   := Color(0.06, 0.05, 0.05)
const COL_DARK    := Color(0.03, 0.02, 0.02)
const COL_RED     := Color(0.90, 0.10, 0.10)
const COL_DIM_RED := Color(0.40, 0.06, 0.06)
const COL_LABEL   := Color(0.60, 0.60, 0.60)
const COL_RIVET   := Color(0.10, 0.06, 0.06)

var _show_timer: float = 0.0
var _blink: float = 0.0
var _ready_to_input: bool = false
var _font_title: Font = null
var _font_body: Font = null
var _final_words: String = ""

## Last fragments of Probe Seven's transmission — one per death, at random.
## Restraint: implication only (dark-directive.md §4.4).
const FINAL_WORDS := [
	"...hull breach forward of the cabin. it's quiet now...",
	"...tell them the worlds are real. tell them that first...",
	"...the tracker was right. it was always right...",
	"...engines gone. drifting. the stars are wrong here...",
	"...if you find this, don't answer the ping...",
	"...porch light's still on, Mara. i can see it from here...",
]

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	process_mode  = Node.PROCESS_MODE_ALWAYS
	_font_title = load("res://assets/fonts/Orbitron.ttf") as Font
	_font_body = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font_title == null: _font_title = ThemeDB.fallback_font
	if _font_body == null: _font_body = ThemeDB.fallback_font

func show_death() -> void:
	show()
	_show_timer = 0.0
	_ready_to_input = false
	_final_words = FINAL_WORDS[randi() % FINAL_WORDS.size()]
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_show_timer += delta
	_blink += delta
	if _show_timer > 2.0:
		_ready_to_input = true
	queue_redraw()

	if _ready_to_input:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("fire_laser"):
			_retry()
		if Input.is_action_just_pressed("pause"):
			_quit_menu()

func _retry() -> void:
	get_tree().reload_current_scene()

func _quit_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _draw() -> void:
	var vp  := get_viewport_rect()
	var w   := vp.size.x
	var h   := vp.size.y
	var cx  := w * 0.5
	var cy  := h * 0.5
	var font := _font_body

	# === Fully opaque background ===
	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	# === Emergency blast doors — red-tinted metal ===
	draw_rect(Rect2(0, 0, w, 18), COL_METAL)
	draw_rect(Rect2(0, 16, w, 2), COL_DARK)
	draw_rect(Rect2(0, h - 18, w, 18), COL_METAL)
	draw_rect(Rect2(0, h - 18, w, 2), COL_DARK)
	draw_rect(Rect2(0, 18, 6, h - 36), COL_METAL)
	draw_rect(Rect2(w - 6, 18, 6, h - 36), COL_METAL)
	for ri in 14:
		var rx := 16.0 + ri * 22.0
		if rx > w - 16:
			break
		draw_circle(Vector2(rx, 8), 1.2, COL_RIVET)
		draw_circle(Vector2(rx, h - 8), 1.2, COL_RIVET)

	# === Warning stripes on door edges ===
	var warn_a := 0.12 + 0.06 * sin(_blink * 4.0)
	var sx := 0.0
	while sx < w:
		draw_line(Vector2(sx, 0), Vector2(sx + 6, 16), Color(COL_RED.r, COL_RED.g, COL_RED.b, warn_a))
		draw_line(Vector2(sx, h), Vector2(sx + 6, h - 16), Color(COL_RED.r, COL_RED.g, COL_RED.b, warn_a))
		sx += 12.0

	# === Static noise (fades over 2s) ===
	var noise_a := clampf(1.0 - _show_timer * 0.5, 0.0, 1.0) * 0.4
	if noise_a > 0.01:
		var seed_val := int(_blink * 12.0)
		for ni in 80:
			var hv := (ni * 7919 + seed_val * 104729) % 57793
			var nx := fmod(float(hv), w)
			var ny := fmod(float((hv * 31) % 57793), h)
			draw_rect(Rect2(nx, ny, 1, 1), Color(0.5, 0.1, 0.1, noise_a))

	# === Pulsing red border warning ===
	var border_a := 0.15 + 0.10 * sin(_blink * 3.5)
	draw_rect(Rect2(6, 18, w - 12, h - 36),
		Color(COL_RED.r, COL_RED.g, COL_RED.b, border_a), false, 1.0)

	# === Content ===
	var fade_in := clampf(_show_timer * 1.5, 0.0, 1.0)

	# Log header
	draw_string(font, Vector2(14, 30), "// MISSION LOG — TRANSMISSION ENDS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(COL_DIM_RED.r, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.8))
	draw_line(Vector2(14, 34), Vector2(w - 14, 34),
		Color(COL_DIM_RED.r, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.5), 1.0)

	# Main message — ghosts at high blend (the fade has already claimed the signal)
	var title := "SIGNAL LOST"
	var title_pos := Vector2(cx - 62, cy - 16)
	draw_string(_font_title, title_pos, title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(COL_RED.r, COL_RED.g, COL_RED.b, fade_in))
	var glitch := VisualState.blend()
	if glitch > 0.5:
		draw_string(_font_title, title_pos + Vector2(2.5, 1.0), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(COL_RED.r, COL_RED.g, COL_RED.b, fade_in * 0.3 * glitch))

	draw_line(Vector2(cx - 60, cy - 6), Vector2(cx + 60, cy - 6),
		Color(COL_DIM_RED.r, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.5), 1.0)

	# Final transmission fragment — fades in under the title
	draw_string(font, Vector2(cx - 74, cy + 2), _final_words,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4,
		Color(COL_DIM_RED.r + 0.2, COL_DIM_RED.g, COL_DIM_RED.b, fade_in * 0.85))

	# Stats
	var sy := cy + 14.0
	draw_string(font, Vector2(cx - 52, sy),
		"SECTOR:  %s" % GameManager.get_sector_name(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in))
	draw_string(font, Vector2(cx - 52, sy + 11),
		"SCORE:   %07d" % GameManager.score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in))
	draw_string(font, Vector2(cx - 52, sy + 22),
		"BEACONS: %d / 3" % GameManager.survey_beacons,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in))
	# The sales pitch for the next run: how close was that? (research brief §2)
	var scores := SaveManager.get_high_scores()
	if not scores.is_empty():
		var best := int(scores[0].get("score", 0))
		if best > 0 and GameManager.score >= best:
			var pa2 := 0.6 + 0.4 * sin(_blink * 3.0)
			draw_string(font, Vector2(cx - 52, sy + 33), "NEW RECORD",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1.0, 0.69, 0.0, fade_in * pa2))
		elif best > 0:
			var pct := int(round(float(GameManager.score) / float(best) * 100.0))
			draw_string(font, Vector2(cx - 52, sy + 33),
				"BEST:    %07d  (%d%%)" % [best, pct],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 5,
				Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, fade_in * 0.8))

	# Retry prompt
	if _ready_to_input:
		var pa := 0.5 + 0.5 * sin(_blink * 3.0)
		var accent := VisualState.pal("accent")
		draw_string(font, Vector2(cx - 60, h - 28),
			"[SPACE] RETRY     [ESC] MAIN MENU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(accent.r, accent.g, accent.b, pa))
