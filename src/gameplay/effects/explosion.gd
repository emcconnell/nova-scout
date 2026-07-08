## Explosion — Procedural explosion effect with type-specific visuals.
## Spawned on death/destruction. Self-freeing after animation completes.
class_name Explosion
extends Node2D

# ─── Explosion types ─────────────────────────────────────────────────────────
enum Type {
	PLAYER,          # Big dramatic white/cyan flash, lots of debris, long duration
	SCOUT,           # Small purple/magenta energy pop
	WARRIOR,         # Medium purple burst with armor shards
	DESTROYER,       # Large orange multi-stage detonation
	ELITE,           # Big purple/white with energy rings
	MOTHERSHIP,      # Massive cascading white/orange
	ASTEROID_LARGE,  # Rocky brown debris and dust
	ASTEROID_MEDIUM, # Smaller rocky burst
	ASTEROID_SMALL,  # Tiny pebble scatter
	MINE,            # Orange/red spike burst
	DERELICT,        # Grey/cyan sparking hull fragments
	MISSILE_HIT,     # Small orange flash
	LEVIATHAN,       # Purple blood burst with gore splatter
}

# ─── Particle data ───────────────────────────────────────────────────────────
var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _flash_alpha: float = 0.0
var _time: float = 0.0
var _duration: float = 0.8
var _type: int = Type.SCOUT

# ─── Light (art bible v4.0 "Textured Light") ─────────────────────────────────
const LIGHT_ENERGY_START := 1.2
const LIGHT_COLOR_START := Color(1.0, 1.0, 1.0)   # white-hot flash
const LIGHT_COLOR_END := Color(1.0, 0.42, 0.2)    # cooling toward ember orange
var _light: PointLight2D = null

func setup(type: int) -> void:
	_type = type
	_time = 0.0
	match type:
		Type.PLAYER:      _init_player()
		Type.SCOUT:       _init_small(Color(0.70, 0.10, 0.35), Color(0.95, 0.35, 0.45), 12, 0.7)
		Type.WARRIOR:     _init_medium(Color(0.55, 0.06, 0.40), Color(0.80, 0.25, 0.55), 16, 0.8)
		Type.DESTROYER:   _init_destroyer()
		Type.ELITE:       _init_elite()
		Type.MOTHERSHIP:  _init_mothership()
		Type.ASTEROID_LARGE:  _init_asteroid(14, 1.0, 12.0)
		Type.ASTEROID_MEDIUM: _init_asteroid(8, 0.7, 8.0)
		Type.ASTEROID_SMALL:  _init_asteroid(5, 0.5, 5.0)
		Type.MINE:        _init_mine()
		Type.DERELICT:    _init_medium(Color(0.40, 0.45, 0.50), Color(0.00, 0.70, 0.90), 10, 0.7)
		Type.MISSILE_HIT: _init_small(Color(1.0, 0.50, 0.10), Color(1.0, 0.80, 0.30), 6, 0.35)
		Type.LEVIATHAN:   _init_leviathan()
	# Lingering embers — dying light drifts after the blast (dark-directive.md §4.2)
	match type:
		Type.PLAYER, Type.MOTHERSHIP: _add_embers(9, 1.9)
		Type.DESTROYER, Type.ELITE, Type.MINE: _add_embers(6, 1.5)
		Type.WARRIOR, Type.DERELICT, Type.LEVIATHAN: _add_embers(4, 1.2)
		Type.SCOUT: _add_embers(3, 1.0)
		_: pass
	# Transient burst light — decays to 0 over the full effect lifetime (embers
	# included), cooling white -> ember orange. Freed automatically with self.
	_light = TextureKit.point_light(self, _get_flash_radius() * 2.5, LIGHT_COLOR_START, LIGHT_ENERGY_START)

## Slow, long-lived embers that outlast the flash and cool from orange to red.
func _add_embers(count: int, life: float) -> void:
	_duration = maxf(_duration, life + 0.1)
	for i in count:
		var a := randf_range(0, TAU)
		var spd := randf_range(4, 18)
		_particles.append({"x": randf_range(-3, 3), "y": randf_range(-3, 3),
			"vx": cos(a) * spd, "vy": sin(a) * spd + 6.0,
			"life": 0.0, "max_life": randf_range(life * 0.6, life),
			"color": Color(1.0, randf_range(0.25, 0.45), 0.06), "size": randf_range(0.5, 1.1),
			"shape": "ember", "angle": randf_range(0.0, 10.0)})

func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		queue_free()
		return
	# Update particles
	for p in _particles:
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vx"] *= 0.96
		p["vy"] *= 0.96
		p["life"] += delta
	# Update rings
	for r in _rings:
		r["radius"] += r["speed"] * delta
		r["life"] += delta
	# Burst light — decays to 0 and cools from white to ember orange over the burst.
	if _light:
		var lt: float = clampf(_time / _duration, 0.0, 1.0)
		_light.energy = LIGHT_ENERGY_START * (1.0 - lt)
		_light.color = LIGHT_COLOR_START.lerp(LIGHT_COLOR_END, lt)
	queue_redraw()

## White-hot/orange survey bursts blend toward dimmer red dead-frequency bursts.
func _draw() -> void:
	var t := _time / _duration   # 0 to 1 normalized
	var dead := VisualState.blend()

	# Initial flash — white-hot (survey) fades toward a dimmer red flash (dead)
	if _flash_alpha > 0.0:
		var fa := _flash_alpha * (1.0 - minf(t * 4.0, 1.0))
		if fa > 0.01:
			var flash_r := _get_flash_radius()
			var flash_col := Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.35, 0.28), dead)
			draw_circle(Vector2.ZERO, flash_r, Color(flash_col.r, flash_col.g, flash_col.b, fa * lerpf(1.0, 0.6, dead)))
			draw_circle(Vector2.ZERO, flash_r * 0.6, Color(flash_col.r, flash_col.g, flash_col.b * 0.9, fa * 0.5))

	# Rings
	for r in _rings:
		var rp: float = float(r["life"]) / float(r["max_life"])
		if rp >= 1.0:
			continue
		var ra: float = (1.0 - rp) * float(r["alpha"])
		var col: Color = _fade_tint(Color(r["color"]), dead)
		draw_arc(Vector2.ZERO, float(r["radius"]), 0, TAU, 24,
			Color(col.r, col.g, col.b, ra), float(r["width"]) * (1.0 - rp * 0.5))

	# Particles
	for p in _particles:
		var pp: float = float(p["life"]) / float(p["max_life"])
		if pp >= 1.0:
			continue
		var pa: float = (1.0 - pp)
		var col: Color = _fade_tint(Color(p["color"]), dead)
		# Fade from bright to dim
		var size: float = float(p["size"]) * (1.0 - pp * 0.6)
		var pc := Color(col.r, col.g, col.b, pa)

		match p.get("shape", "circle"):
			"circle":
				draw_circle(Vector2(p["x"], p["y"]), size, pc)
				# Hot core for larger particles
				if size > 1.5:
					draw_circle(Vector2(p["x"], p["y"]), size * 0.4,
						Color(1.0, 1.0, 1.0, pa * 0.5))
			"shard":
				_draw_shard(Vector2(p["x"], p["y"]), size, p["angle"], pc)
			"rock":
				_draw_rock(Vector2(p["x"], p["y"]), size, p["angle"], pc)
			"spark":
				var tail := Vector2(p["x"] - p["vx"] * 0.03, p["y"] - p["vy"] * 0.03)
				draw_line(Vector2(p["x"], p["y"]), tail,
					Color(col.r, col.g, col.b, pa * 0.8), 1.0)
				draw_circle(Vector2(p["x"], p["y"]), 0.8, Color(1.0, 1.0, 1.0, pa))
			"ember":
				# Flickering dying light, cooling toward deep red (further toward dead)
				var flick := 0.55 + 0.45 * sin(_time * 11.0 + float(p["angle"]))
				var cool := col.lerp(Color(0.45, 0.03, 0.02), pp + dead * 0.3)
				draw_circle(Vector2(p["x"], p["y"]), size,
					Color(cool.r, cool.g, cool.b, pa * flick))

	# Smoke (for larger explosions) — dead frequency: darker, redder haze
	if _type in [Type.PLAYER, Type.DESTROYER, Type.MOTHERSHIP, Type.MINE]:
		var smoke_a := 0.15 * (1.0 - t) * lerpf(1.0, 0.7, dead)
		var smoke_r := _get_flash_radius() * (0.5 + t * 1.5)
		var smoke_col := Color(0.15, 0.12, 0.10).lerp(Color(0.10, 0.04, 0.04), dead)
		draw_circle(Vector2.ZERO, smoke_r, Color(smoke_col.r, smoke_col.g, smoke_col.b, smoke_a))

## Blends a bright survey particle color toward the dimmer red dead-frequency family.
func _fade_tint(col: Color, dead: float) -> Color:
	if dead <= 0.0:
		return col
	var dead_col := Color(0.7, 0.12, 0.08).lerp(col, 0.25)   # keep a hint of the original hue
	var tinted := col.lerp(dead_col, dead)
	return tinted.darkened(dead * 0.25)   # dimmer overall in dead frequency, fewer sparks read as bright

func _draw_shard(pos: Vector2, sz: float, angle: float, col: Color) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(cos(angle), sin(angle)) * sz,
		pos + Vector2(cos(angle + 2.2), sin(angle + 2.2)) * sz * 0.5,
		pos + Vector2(cos(angle + 4.0), sin(angle + 4.0)) * sz * 0.4,
	])
	draw_colored_polygon(pts, col)

func _draw_rock(pos: Vector2, sz: float, angle: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 5:
		var a := angle + TAU / 5.0 * i
		var r := sz * (0.6 + 0.4 * sin(float(i) * 3.7))
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)

func _get_flash_radius() -> float:
	match _type:
		Type.PLAYER: return 20.0
		Type.MOTHERSHIP: return 30.0
		Type.DESTROYER: return 16.0
		Type.ELITE: return 14.0
		Type.MINE: return 12.0
		Type.WARRIOR: return 10.0
		Type.ASTEROID_LARGE: return 10.0
		_: return 6.0

# ─── Initializers per type ───────────────────────────────────────────────────

func _init_player() -> void:
	_duration = 1.5
	_flash_alpha = 0.9
	# Expanding rings
	_rings.append({"radius": 4.0, "speed": 50.0, "life": 0.0, "max_life": 0.8,
		"color": Color(0.0, 0.9, 1.0), "alpha": 0.7, "width": 2.0})
	_rings.append({"radius": 2.0, "speed": 35.0, "life": 0.0, "max_life": 1.0,
		"color": Color(1.0, 0.6, 0.2), "alpha": 0.5, "width": 1.5})
	_rings.append({"radius": 6.0, "speed": 65.0, "life": 0.0, "max_life": 0.6,
		"color": Color(1.0, 1.0, 1.0), "alpha": 0.4, "width": 1.0})
	# Hull debris (shards)
	for i in 8:
		var a := TAU / 8.0 * i + randf_range(-0.3, 0.3)
		var spd := randf_range(30, 80)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.8, 1.4),
			"color": Color(0.85, 0.87, 0.92), "size": randf_range(2.0, 4.0),
			"shape": "shard", "angle": a})
	# Fire particles
	for i in 14:
		var a := randf_range(0, TAU)
		var spd := randf_range(20, 60)
		_particles.append({"x": randf_range(-3, 3), "y": randf_range(-3, 3),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.5, 1.2),
			"color": Color(1.0, randf_range(0.3, 0.7), 0.1), "size": randf_range(1.5, 3.5),
			"shape": "circle", "angle": 0.0})
	# Sparks
	for i in 10:
		var a := randf_range(0, TAU)
		var spd := randf_range(60, 140)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.3, 0.7),
			"color": Color(0.0, 0.9, 1.0), "size": 1.0,
			"shape": "spark", "angle": 0.0})

func _init_small(col1: Color, col2: Color, count: int, dur: float) -> void:
	_duration = dur
	_flash_alpha = 0.6
	_rings.append({"radius": 2.0, "speed": 30.0, "life": 0.0, "max_life": dur * 0.7,
		"color": col1, "alpha": 0.5, "width": 1.5})
	for i in count:
		var a := randf_range(0, TAU)
		var spd := randf_range(15, 50)
		var col := col1.lerp(col2, randf())
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.3, dur),
			"color": col, "size": randf_range(1.0, 2.5),
			"shape": "circle", "angle": 0.0})
	# A few sparks
	for i in 4:
		var a := randf_range(0, TAU)
		var spd := randf_range(40, 80)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, 0.5),
			"color": Color(1.0, 1.0, 1.0), "size": 0.8,
			"shape": "spark", "angle": 0.0})

func _init_medium(col1: Color, col2: Color, count: int, dur: float) -> void:
	_duration = dur
	_flash_alpha = 0.7
	_rings.append({"radius": 3.0, "speed": 40.0, "life": 0.0, "max_life": dur * 0.6,
		"color": col1, "alpha": 0.6, "width": 1.5})
	# Shards
	for i in 5:
		var a := TAU / 5.0 * i + randf_range(-0.3, 0.3)
		var spd := randf_range(20, 55)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.4, dur),
			"color": col2, "size": randf_range(2.0, 3.5),
			"shape": "shard", "angle": a})
	# Fire
	for i in count:
		var a := randf_range(0, TAU)
		var spd := randf_range(15, 50)
		_particles.append({"x": randf_range(-2, 2), "y": randf_range(-2, 2),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.3, dur),
			"color": col1.lerp(col2, randf()), "size": randf_range(1.2, 2.8),
			"shape": "circle", "angle": 0.0})
	for i in 6:
		var a := randf_range(0, TAU)
		var spd := randf_range(50, 100)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, 0.5),
			"color": Color(1.0, 1.0, 1.0), "size": 0.8,
			"shape": "spark", "angle": 0.0})

func _init_destroyer() -> void:
	_duration = 1.2
	_flash_alpha = 0.8
	# Multiple rings (staged detonation feel)
	_rings.append({"radius": 3.0, "speed": 45.0, "life": 0.0, "max_life": 0.8,
		"color": Color(1.0, 0.5, 0.0), "alpha": 0.7, "width": 2.0})
	_rings.append({"radius": 6.0, "speed": 30.0, "life": 0.0, "max_life": 1.0,
		"color": Color(1.0, 0.3, 0.0), "alpha": 0.4, "width": 1.5})
	# Heavy armor shards
	for i in 8:
		var a := TAU / 8.0 * i + randf_range(-0.2, 0.2)
		var spd := randf_range(15, 45)
		_particles.append({"x": randf_range(-4, 4), "y": randf_range(-3, 3),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.6, 1.1),
			"color": Color(0.25, 0.0, 0.40), "size": randf_range(3.0, 5.0),
			"shape": "shard", "angle": a})
	# Core explosion fire
	for i in 18:
		var a := randf_range(0, TAU)
		var spd := randf_range(20, 65)
		_particles.append({"x": randf_range(-3, 3), "y": randf_range(-3, 3),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.4, 1.0),
			"color": Color(1.0, randf_range(0.2, 0.6), 0.0), "size": randf_range(1.5, 3.5),
			"shape": "circle", "angle": 0.0})
	# Sparks
	for i in 8:
		var a := randf_range(0, TAU)
		var spd := randf_range(60, 120)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, 0.6),
			"color": Color(1.0, 0.8, 0.3), "size": 1.0,
			"shape": "spark", "angle": 0.0})

func _init_elite() -> void:
	_duration = 1.0
	_flash_alpha = 0.8
	_rings.append({"radius": 3.0, "speed": 50.0, "life": 0.0, "max_life": 0.6,
		"color": Color(0.80, 0.20, 1.0), "alpha": 0.7, "width": 2.0})
	_rings.append({"radius": 5.0, "speed": 35.0, "life": 0.0, "max_life": 0.8,
		"color": Color(1.0, 1.0, 1.0), "alpha": 0.3, "width": 1.0})
	for i in 12:
		var a := randf_range(0, TAU)
		var spd := randf_range(25, 65)
		_particles.append({"x": randf_range(-2, 2), "y": randf_range(-2, 2),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.4, 0.9),
			"color": Color(0.7, 0.1, 1.0).lerp(Color(1.0, 0.5, 1.0), randf()),
			"size": randf_range(1.5, 3.0), "shape": "circle", "angle": 0.0})
	for i in 8:
		var a := randf_range(0, TAU)
		var spd := randf_range(50, 110)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, 0.5),
			"color": Color(1.0, 1.0, 1.0), "size": 0.8,
			"shape": "spark", "angle": 0.0})

func _init_mothership() -> void:
	_duration = 2.0
	_flash_alpha = 1.0
	# Three expanding rings
	_rings.append({"radius": 5.0, "speed": 55.0, "life": 0.0, "max_life": 1.2,
		"color": Color(1.0, 0.6, 0.0), "alpha": 0.8, "width": 2.5})
	_rings.append({"radius": 8.0, "speed": 40.0, "life": 0.0, "max_life": 1.5,
		"color": Color(1.0, 0.3, 0.0), "alpha": 0.5, "width": 2.0})
	_rings.append({"radius": 3.0, "speed": 70.0, "life": 0.0, "max_life": 0.8,
		"color": Color(1.0, 1.0, 1.0), "alpha": 0.6, "width": 1.5})
	# Massive debris
	for i in 12:
		var a := TAU / 12.0 * i + randf_range(-0.2, 0.2)
		var spd := randf_range(10, 35)
		_particles.append({"x": randf_range(-8, 8), "y": randf_range(-5, 5),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(1.0, 1.8),
			"color": Color(0.10, 0.0, 0.18), "size": randf_range(4.0, 7.0),
			"shape": "shard", "angle": a})
	# Fire
	for i in 25:
		var a := randf_range(0, TAU)
		var spd := randf_range(15, 50)
		_particles.append({"x": randf_range(-6, 6), "y": randf_range(-4, 4),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": randf_range(0, 0.3), "max_life": randf_range(0.5, 1.5),
			"color": Color(1.0, randf_range(0.2, 0.7), 0.0), "size": randf_range(2.0, 4.0),
			"shape": "circle", "angle": 0.0})
	# Sparks
	for i in 16:
		var a := randf_range(0, TAU)
		var spd := randf_range(50, 150)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.3, 0.8),
			"color": Color(1.0, 0.9, 0.5), "size": 1.0,
			"shape": "spark", "angle": 0.0})

func _init_asteroid(count: int, dur: float, spread: float) -> void:
	_duration = dur
	_flash_alpha = 0.3
	# Dust ring
	_rings.append({"radius": 2.0, "speed": 20.0, "life": 0.0, "max_life": dur * 0.8,
		"color": Color(0.55, 0.50, 0.42), "alpha": 0.3, "width": 1.5})
	# Rock chunks
	for i in int(count * 0.5):
		var a := randf_range(0, TAU)
		var spd := randf_range(10, 35)
		_particles.append({"x": randf_range(-2, 2), "y": randf_range(-2, 2),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.3, dur),
			"color": Color(0.55, 0.53, 0.48).lerp(Color(0.38, 0.35, 0.30), randf()),
			"size": randf_range(1.5, spread * 0.4), "shape": "rock", "angle": randf_range(0, TAU)})
	# Dust particles
	for i in count:
		var a := randf_range(0, TAU)
		var spd := randf_range(8, 30)
		_particles.append({"x": randf_range(-2, 2), "y": randf_range(-2, 2),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, dur * 0.8),
			"color": Color(0.50, 0.45, 0.38, 0.7), "size": randf_range(0.8, 2.0),
			"shape": "circle", "angle": 0.0})

func _init_mine() -> void:
	_duration = 0.9
	_flash_alpha = 0.8
	_rings.append({"radius": 3.0, "speed": 50.0, "life": 0.0, "max_life": 0.6,
		"color": Color(1.0, 0.3, 0.0), "alpha": 0.7, "width": 2.0})
	# Spike fragments (6 directions matching mine spikes)
	for i in 6:
		var a := TAU / 6.0 * i + randf_range(-0.2, 0.2)
		var spd := randf_range(35, 70)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.4, 0.8),
			"color": Color(0.55, 0.55, 0.60), "size": randf_range(2.0, 3.0),
			"shape": "shard", "angle": a})
	# Fire
	for i in 12:
		var a := randf_range(0, TAU)
		var spd := randf_range(15, 45)
		_particles.append({"x": randf_range(-2, 2), "y": randf_range(-2, 2),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.3, 0.7),
			"color": Color(1.0, randf_range(0.2, 0.5), 0.0), "size": randf_range(1.2, 2.5),
			"shape": "circle", "angle": 0.0})
	# Sparks
	for i in 6:
		var a := randf_range(0, TAU)
		var spd := randf_range(50, 100)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, 0.4),
			"color": Color(1.0, 0.8, 0.3), "size": 0.8,
			"shape": "spark", "angle": 0.0})

func _init_leviathan() -> void:
	_duration = 1.4
	_flash_alpha = 0.5
	# Purple blood ring
	_rings.append({"radius": 4.0, "speed": 35.0, "life": 0.0, "max_life": 1.0,
		"color": Color(0.55, 0.05, 0.70), "alpha": 0.6, "width": 2.5})
	_rings.append({"radius": 6.0, "speed": 25.0, "life": 0.0, "max_life": 1.2,
		"color": Color(0.75, 0.15, 0.90), "alpha": 0.3, "width": 1.5})
	# Blood splatter globs — large, slow, messy
	for i in 16:
		var a := randf_range(0, TAU)
		var spd := randf_range(12, 45)
		_particles.append({"x": randf_range(-4, 4), "y": randf_range(-4, 4),
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.6, 1.3),
			"color": Color(0.55, 0.05, 0.70).lerp(Color(0.75, 0.15, 0.90), randf()),
			"size": randf_range(2.0, 4.5), "shape": "circle", "angle": 0.0})
	# Tentacle fragments
	for i in 6:
		var a := TAU / 6.0 * i + randf_range(-0.3, 0.3)
		var spd := randf_range(20, 50)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.5, 1.0),
			"color": Color(0.35, 0.12, 0.45), "size": randf_range(2.5, 4.0),
			"shape": "shard", "angle": a})
	# Bright purple sparks
	for i in 8:
		var a := randf_range(0, TAU)
		var spd := randf_range(40, 90)
		_particles.append({"x": 0.0, "y": 0.0,
			"vx": cos(a) * spd, "vy": sin(a) * spd,
			"life": 0.0, "max_life": randf_range(0.2, 0.5),
			"color": Color(0.90, 0.40, 1.00), "size": 1.0,
			"shape": "spark", "angle": 0.0})
