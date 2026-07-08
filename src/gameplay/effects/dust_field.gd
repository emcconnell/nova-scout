## DustField — v5.0 "Wet Black" volumetric dust. A sparse field of drifting
## motes, near-invisible against the void, that IGNITE inside the player's
## flood cone (VisualState.beam_lit per mote) — the beam stops being a flat
## wedge and reads as a shaft of light through matter. Explosive brightness
## is not simulated; the beam is the story (art bible §0 v5.0).
## Zero allocations per frame: motes are preallocated dictionaries, redrawn.
## Tuning: assets/data/visuals.json → "dust".
class_name DustField
extends Node2D

const MOTE_COLOR := Color(0.82, 0.86, 0.95)
# Two parallax bands: slow deep motes, faster near motes (fraction of scroll).
const BAND_SPEED := [22.0, 40.0]

var _motes: Array[Dictionary] = []
var _vp: Vector2 = Vector2.ZERO
var _drift_t: float = 0.0

func _ready() -> void:
	z_index = 12   # above bodies (players/enemies ~10), below projectiles (35)
	light_mask = 0 # lit analytically by beam_lit(), not by the 2D light pass
	_vp = get_viewport_rect().size
	var count := int(VisualState.value("dust", "count", 46))
	var rng := DrawKit.rng(7793)
	for i in count:
		_motes.append({
			"x": rng.randf() * _vp.x,
			"y": rng.randf() * _vp.y,
			"band": i % 2,
			"size": 0.4 + rng.randf() * 0.8,
			"phase": rng.randf() * TAU,
		})

func _process(delta: float) -> void:
	_drift_t += delta
	var drift := float(VisualState.value("dust", "drift_speed", 4.0))
	for m in _motes:
		m["y"] = fposmod(float(m["y"]) + BAND_SPEED[m["band"]] * delta, _vp.y)
		m["x"] = fposmod(float(m["x"])
			+ sin(_drift_t * 0.4 + float(m["phase"])) * drift * delta, _vp.x)
	queue_redraw()

func _draw() -> void:
	var base_a := float(VisualState.value("dust", "base_alpha", 0.045))
	var beam_a := float(VisualState.value("dust", "beam_alpha", 0.5))
	var beam_on := VisualState.beam_strength() > 0.0
	for m in _motes:
		var pos := Vector2(float(m["x"]), float(m["y"]))
		var a := base_a
		if beam_on:
			a += VisualState.beam_lit(global_position + pos) * beam_a
		if a < 0.008:
			continue
		var sz: float = m["size"]
		draw_rect(Rect2(pos.x - sz * 0.5, pos.y - sz * 0.5, sz, sz),
			Color(MOTE_COLOR.r, MOTE_COLOR.g, MOTE_COLOR.b, a))
