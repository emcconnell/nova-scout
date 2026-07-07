## StarNode — A scannable star in a Star Cluster.
## Approach within range: scan starts automatically after a short grace beat.
## [E] aborts a scan in progress. Result determined by sector + type.
## GDD Ref: gameplay-mechanics.md §4
class_name StarNode
extends Area2D

signal scan_completed(result: String, star_data: Dictionary)
signal scan_aborted()
signal player_in_range(in_range: bool)
signal scan_pressure_pulse(pulse: Dictionary, star_data: Dictionary)

# ─── Config ───────────────────────────────────────────────────────────────────
const APPROACH_RADIUS := 35.0
const COL_STAR     := Color(1.00, 0.95, 0.80)
const COL_VIABLE   := Color(0.40, 0.90, 1.00)
const COL_ALIEN    := Color(0.80, 0.00, 1.00)
const COL_ANOMALY  := Color(0.00, 1.00, 0.60)
const COL_UNKNOWN  := Color(0.75, 0.82, 1.00)
const COL_WARNING  := Color(1.00, 0.65, 0.20)
const COL_RING     := Color(1.00, 0.95, 0.80, 0.30)

# ─── Result types (gameplay-mechanics.md probabilities) ───────────────────────
const RESULT_BARREN   := "barren"
const RESULT_VIABLE   := "human_viable"
const RESULT_ALIEN    := "alien_territory"
const RESULT_ANOMALY  := "anomaly"

# ─── Scan state machine ────────────────────────────────────────────────────────
## IDLE -> GRACE (enter range) -> SCANNING (grace elapses) -> SCANNED (progress 1.0)
## GRACE -> IDLE (player leaves range early) | SCANNING -> IDLE ([E] abort)
enum ScanState { IDLE, GRACE, SCANNING, SCANNED }

# ─── State ────────────────────────────────────────────────────────────────────
var star_data: Dictionary = {}  # {type, result, sector, scan_duration}
var _player_nearby: bool = false
var _state: ScanState = ScanState.IDLE
var _grace_remaining: float = 0.0
var _grace_flash_remaining: float = 0.0
var _scan_progress: float = 0.0
var _scan_stability: float = 1.0
var _scan_duration: float = 25.0
var _scan_pressure: Dictionary = {}
var _scan_pulses: Array = []
var _fired_scan_pulses: Dictionary = {}
var _wobble: float = 0.0
var _detail_seed: int = 0

func _ready() -> void:
	add_to_group("star_nodes")
	monitoring = true
	collision_layer = 0
	collision_mask = 1   # player
	body_entered.connect(func(body): if body.is_in_group("player"): _set_nearby(true))
	body_exited.connect(func(body): if body.is_in_group("player"): _set_nearby(false))
	_detail_seed = hash(String(name))

func setup(data: Dictionary) -> void:
	star_data = data
	_scan_duration = float(data.get("scan_duration", 25.0))
	_scan_pressure = data.get("scan_pressure", {}).duplicate(true)
	_scan_pulses = _scan_pressure.get("pulses", [])
	_fired_scan_pulses.clear()
	_detail_seed = hash(String(data.get("id", name)))

func _set_nearby(val: bool) -> void:
	_player_nearby = val
	player_in_range.emit(val)
	if _state == ScanState.SCANNED:
		return
	if val and _state == ScanState.IDLE:
		_begin_grace()
	elif not val and _state == ScanState.GRACE:
		_state = ScanState.IDLE

func _process(delta: float) -> void:
	_wobble += delta * 2.5
	match _state:
		ScanState.GRACE:
			_grace_flash_remaining = maxf(0.0, _grace_flash_remaining - delta)
			_grace_remaining -= delta
			if _grace_remaining <= 0.0:
				_start_scan()
		ScanState.SCANNING:
			if Input.is_action_just_pressed("interact"):
				_abort_scan()
			else:
				_advance_scan(delta)
	queue_redraw()

func _begin_grace() -> void:
	_state = ScanState.GRACE
	var delay := float(VisualState.value("scan", "auto_start_delay", 0.5))
	_grace_remaining = delay
	_grace_flash_remaining = float(VisualState.value("scan", "grace_flash_duration", 0.15))

func _start_scan() -> void:
	_state = ScanState.SCANNING
	_scan_progress = 0.0
	_scan_stability = 1.0
	_fired_scan_pulses.clear()
	var player := _get_player()
	if player and player.has_method("enter_orbit"):
		player.enter_orbit(self, APPROACH_RADIUS * 0.8)
	AudioManager.play_sfx("scan_start")

func _abort_scan() -> void:
	_state = ScanState.IDLE if not _player_nearby else ScanState.GRACE
	if _state == ScanState.GRACE:
		_begin_grace()
	_scan_progress = 0.0
	var player := _get_player()
	if player and player.has_method("exit_orbit"):
		player.exit_orbit()
	scan_aborted.emit()
	AudioManager.play_sfx("scan_abort")

func _advance_scan(delta: float) -> void:
	_scan_progress += delta / maxf(_scan_duration, 0.001)
	_emit_due_pressure_pulses()
	# Auto-abort only if nearly dead (hull <= 5) to avoid frustrating cancels
	var player := _get_player()
	if player and player.health.hull <= 5:
		_abort_scan()
		return
	if _scan_progress >= 1.0:
		_complete_scan()

func _emit_due_pressure_pulses() -> void:
	for i in _scan_pulses.size():
		if _fired_scan_pulses.has(i):
			continue
		var pulse: Dictionary = _scan_pulses[i]
		var threshold := clampf(float(pulse.get("at", 1.0)), 0.0, 1.0)
		if _scan_progress >= threshold:
			_fired_scan_pulses[i] = true
			_apply_scan_pressure_cost(pulse)
			scan_pressure_pulse.emit(pulse, star_data)

func _apply_scan_pressure_cost(pulse: Dictionary) -> void:
	var stability_loss := clampf(float(pulse.get("stability_loss", 0.12)), 0.0, 0.45)
	var progress_loss := clampf(float(pulse.get("progress_loss", stability_loss * 0.25)), 0.0, 0.20)
	_scan_stability = clampf(_scan_stability - stability_loss, 0.0, 1.0)
	_scan_progress = maxf(0.0, _scan_progress - progress_loss)
	if _scan_stability <= 0.0:
		_abort_scan()

func _complete_scan() -> void:
	_state = ScanState.SCANNED
	var player := _get_player()
	if player and player.has_method("exit_orbit"):
		player.exit_orbit()
	var result: String = star_data.get("result", RESULT_BARREN)
	GameManager.stars_scanned += 1
	get_tree().call_group("game_world", "show_scan_reveal", global_position, get_signal_label(), String(star_data.get("reward", "")))
	scan_completed.emit(result, star_data)
	# Sector 5: the familiar chime plays a semitone flat — the ship knows
	# something is wrong (dark-directive.md "imperfect familiarity")
	if GameManager.current_sector >= 5:
		AudioManager.play_sfx("scan_complete", 1.0, 0.9439)
	else:
		AudioManager.play_sfx("scan_complete")

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func get_scan_progress() -> float:
	return _scan_progress

func get_scan_stability() -> float:
	return _scan_stability

func get_display_star_color() -> Color:
	if _state == ScanState.SCANNED:
		return _get_star_color(String(star_data.get("result", RESULT_BARREN)))
	return _get_unscanned_star_color()

func get_signal_label() -> String:
	var risk := _get_signal_risk()
	match risk:
		"high": return "HOSTILE NOISE"
		"anomaly": return "ANOMALOUS STATIC"
		"bio": return "BIO-SIGNATURE?"
		"reward": return "TRACE MINERALS"
		_: return "QUIET SIGNAL"

func get_scan_pressure() -> Dictionary:
	return _scan_pressure

## True only while the scan is actively progressing (post-grace).
func is_scanning() -> bool:
	return _state == ScanState.SCANNING

## True during the brief pre-scan grace beat ("SIGNAL ACQUIRED" -> auto-start countdown).
func is_scan_pending() -> bool:
	return _state == ScanState.GRACE

## Seconds remaining before an auto-start scan begins (0 when not in grace).
func get_grace_remaining() -> float:
	return _grace_remaining if _state == ScanState.GRACE else 0.0

## TURN 4 physical star render — smooth white-hot core (SURVEY) crossfades to an
## ember-red dying star (DEAD FREQUENCY) via VisualState; nested corona glows read
## as a real star rather than a flat ring. Scan FUI (dashed range ring / progress
## arc / scan beam) reads in VisualState.pal("hud")/"accent" thin-line techy style.
func _draw() -> void:
	_draw_star()
	if _state != ScanState.SCANNED:
		_draw_scan_fui()
	else:
		_draw_scanned_indicator()

## Layered corona + white-hot core + diffraction cross — replaces the flat donut.
func _draw_star() -> void:
	var star_col: Color = get_display_star_color()
	var blend := VisualState.blend()
	var corona_pulse := 0.92 + 0.08 * sin(_wobble * 0.35 + float(_detail_seed % 100) * 0.06)
	var core_col := VisualState.col(Color(0.957, 0.969, 0.980), Color(1.0, 0.353, 0.196))

	# Nested corona — 3 soft glows falling off from the hue's outer halo to its
	# hot inner skirt, auto-smoothed by DrawKit.glow (no ring banding).
	DrawKit.glow(self, Vector2.ZERO, 9.0 * corona_pulse, Color(star_col.r, star_col.g, star_col.b, 0.16))
	DrawKit.glow(self, Vector2.ZERO, 5.6 * corona_pulse, Color(star_col.r, star_col.g, star_col.b, 0.30))
	DrawKit.glow(self, Vector2.ZERO, 3.4, Color(star_col.r, star_col.g, star_col.b, 0.55))

	# Smooth white-hot (or ember) core — a real disc, not a stroked ring.
	draw_circle(Vector2.ZERO, 2.4, core_col)

	if blend > 0.01:
		# Ember limb arc — the star is visibly dying even while still scannable.
		draw_arc(Vector2.ZERO, 2.4, PI * 0.85, PI * 1.75, 12,
			Color(1.0, 0.353, 0.196, 0.85 * blend), 1.0)

	# 4-point diffraction cross — subtle, rotated per-instance so stars don't
	# all read identically; brightens slightly with the corona pulse.
	var cross_alpha := 0.22 * corona_pulse
	var cross_len := 7.5 * corona_pulse
	var cross_rot := float(_detail_seed % 360) * 0.0174533 * 0.35
	var cross_col := Color(star_col.r, star_col.g, star_col.b, cross_alpha)
	for i in 4:
		var a := cross_rot + PI * 0.5 * float(i)
		var dir := Vector2(cos(a), sin(a))
		draw_line(dir * 1.6, dir * cross_len, cross_col, 0.7)

func _draw_scanned_indicator() -> void:
	var hud_col := VisualState.pal("hud")
	# Small thin check ring — restyled from the old fat radius-7 badge.
	draw_arc(Vector2.ZERO, 5.0, 0, TAU, 20, Color(hud_col.r, hud_col.g, hud_col.b, 0.4), 0.6)
	# One short tick reads as a "checked" mark without adding a second glyph.
	draw_line(Vector2(-1.6, 0.4), Vector2(-0.2, 2.0), hud_col, 0.7)
	draw_line(Vector2(-0.2, 2.0), Vector2(2.4, -2.2), hud_col, 0.7)

## Thin techy FUI: dashed rotating range ring, tick-marked progress arc, and a
## scan beam line to the player while actively scanning. Labels read in small
## tracking-spaced caps with a one-frame ghost offset at high blend (dead freq).
func _draw_scan_fui() -> void:
	if not _player_nearby:
		return
	var hud_col := VisualState.pal("hud")
	var accent_col := VisualState.pal("accent")
	var blend := VisualState.blend()
	var font := ThemeDB.fallback_font

	_draw_dashed_range_ring(accent_col)

	if _state == ScanState.SCANNING:
		_draw_progress_arc(hud_col, accent_col)
		_draw_scan_beam(hud_col)

	var label := get_signal_label()
	if _state == ScanState.GRACE and _grace_flash_remaining > 0.0:
		label = "SIGNAL ACQUIRED"
	_draw_tracked_label(font, label, Vector2.ZERO, APPROACH_RADIUS + 9.0,
		Color(hud_col.r, hud_col.g, hud_col.b, 0.85), blend)

	var control_text := _get_control_text()
	_draw_tracked_label(font, control_text, Vector2.ZERO, -APPROACH_RADIUS - 4.0,
		Color(accent_col.r, accent_col.g, accent_col.b, 0.9), blend)

func _get_control_text() -> String:
	match _state:
		ScanState.GRACE:
			return "SCAN IN %.1fs · [E] ABORT" % maxf(_grace_remaining, 0.0)
		ScanState.SCANNING:
			return "[E] ABORT SCAN"
		_:
			return ""

## Rotating dashed ring in place of the old solid thin circle — segments are
## short (0.6-0.8px-ish stroke feel via short dash length) and rotate slowly.
func _draw_dashed_range_ring(col: Color) -> void:
	var ring_col := Color(col.r, col.g, col.b, 0.5)
	var segments := 28
	var rot := _wobble * 0.18
	for i in segments:
		if i % 2 == 0:
			continue  # dash gaps — every other segment skipped
		var a0 := rot + TAU * float(i) / float(segments)
		var a1 := rot + TAU * float(i + 1) / float(segments)
		draw_line(
			Vector2(cos(a0), sin(a0)) * APPROACH_RADIUS,
			Vector2(cos(a1), sin(a1)) * APPROACH_RADIUS,
			ring_col, 0.7)

## Thin progress arc with small perpendicular tick marks and a percentage readout.
func _draw_progress_arc(hud_col: Color, accent_col: Color) -> void:
	var r := APPROACH_RADIUS - 6.0
	var start := -PI * 0.5
	var end := start + TAU * _scan_progress
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(hud_col.r, hud_col.g, hud_col.b, 0.18), 0.6)
	draw_arc(Vector2.ZERO, r, start, end, 32, accent_col, 1.0)
	# Tick marks every 10% around the full ring.
	for i in 10:
		var a := start + TAU * 0.1 * float(i)
		var dir := Vector2(cos(a), sin(a))
		var lit := (start + TAU * 0.1 * float(i)) <= end
		var tick_col := accent_col if lit else Color(hud_col.r, hud_col.g, hud_col.b, 0.25)
		draw_line(dir * (r - 1.5), dir * (r + 1.5), tick_col, 0.6)
	var font := ThemeDB.fallback_font
	var pct_str := "%d%%" % int(_scan_progress * 100.0)
	draw_string(font, Vector2(-6.0, r + 12.0), pct_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, accent_col)

## Thin scan-beam line from the player to the star while scanning, with a
## subtle glow at the star end — reads as an active signal link, not just a UI ring.
func _draw_scan_beam(hud_col: Color) -> void:
	var player := _get_player()
	if player == null:
		return
	var local_player := to_local(player.global_position)
	var beam_alpha := 0.28 + 0.06 * sin(_wobble * 2.0)
	draw_line(Vector2.ZERO, local_player, Color(hud_col.r, hud_col.g, hud_col.b, beam_alpha), 0.6)
	DrawKit.glow(self, Vector2.ZERO, 3.0, Color(hud_col.r, hud_col.g, hud_col.b, 0.12))

## Small tracking-spaced caps label with a one-frame ghost offset duplicate at
## high blend (dead-frequency glitch language, scaled down for this small UI).
func _draw_tracked_label(font: Font, text: String, anchor: Vector2, y_offset: float,
		col: Color, blend: float) -> void:
	if text.is_empty():
		return
	var tracked := _tracked_caps(text)
	var width := font.get_string_size(tracked, HORIZONTAL_ALIGNMENT_LEFT, -1, 4).x
	var pos := anchor + Vector2(-width * 0.5, y_offset)
	if blend > 0.5:
		var ghost_a := (blend - 0.5) * 0.6
		draw_string(font, pos + Vector2(1.2, 0.5), tracked,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(col.r, col.g, col.b, col.a * ghost_a))
	draw_string(font, pos, tracked, HORIZONTAL_ALIGNMENT_LEFT, -1, 4, col)

## Insert a thin space between letters for a tracking-spaced caps FUI feel.
func _tracked_caps(text: String) -> String:
	var out := ""
	for i in text.length():
		out += text[i]
		if i < text.length() - 1:
			out += " "
	return out

## Gameplay color coding kept, hues pulled toward physical star colors
## (pale blue-white / amber dwarf / red dwarf) per the TURN 4 realism pass.
func _get_unscanned_star_color() -> Color:
	var risk := _get_signal_risk()
	match risk:
		"high": return COL_WARNING
		"anomaly": return Color(0.45, 1.0, 0.75)
		"bio": return Color(0.70, 0.85, 1.0)     # pale blue-white — human-viable candidate
		"reward": return Color(1.0, 0.80, 0.45)  # amber dwarf
		_: return COL_UNKNOWN

func _get_signal_risk() -> String:
	var result: String = star_data.get("result", RESULT_BARREN)
	if result == RESULT_ALIEN or result == "mothership":
		return "high"
	if result == RESULT_ANOMALY:
		return "anomaly"
	if result == RESULT_VIABLE:
		return "bio"
	if String(star_data.get("reward", "")) != "":
		return "reward"
	if not _scan_pulses.is_empty():
		return "high"
	return "quiet"

func _get_star_color(result: String) -> Color:
	match result:
		RESULT_VIABLE: return COL_VIABLE
		RESULT_ALIEN:  return COL_ALIEN
		RESULT_ANOMALY: return COL_ANOMALY
		_: return COL_STAR
