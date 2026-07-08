# Textured-Body Conversion Spec (art bible v4.0 "Textured Light")

Read this fully before editing. The graphics overhaul replaces every
procedurally-FILLED body with a baked textured sprite (albedo crossfade +
normal map, real 2D lights), while keeping all EMISSIVE/DYNAMIC drawing
procedural (glows, eyes, veins, flames, shields, stun dots, rim strokes).

## The pattern (already applied to player.gd + asteroid.gd — copy it)

1. In `_ready()` (after `super()` for enemies):
   `_body = TextureKit.creature_body(self, "enemies", "<name>")`
   - enemies use `creature_body` (survey/dead/wet crossfade + flood-cone
     reveal in the shader); hazards use `TextureKit.fade_body(self,
     "hazards", "<name>")`; planets `fade_body(self, "world", "<name>")`.
   - Declare `var _body: Sprite2D = null` with the state vars.
   - The sprite is auto-scaled (baked at 12 px/unit; pass `6.0` as the
     4th arg for the mothership which was baked at 6 px/unit).
2. In `_draw()` DELETE ONLY the body-construction layers:
   - `draw_colored_polygon` body fills / `DrawKit.ellipse` body stacks
   - `EnemyRenderer.plate_ridge_arc` / `plate_ridge_line` calls
   - `EnemyRenderer.draw_flecks` + the `_flecks` seeding in `_ready`
   - sheen ellipses, spine/barb/body detail strokes
   KEEP: `under_halo`, `eye_cluster`, `magenta_vein`, `dead_vein_line`,
   `lit_rim_stroke`, engine nacelles/exhaust, weapon-port glows, shield
   arcs, stun indicator, `_draw_hit_flash()`, and any charge/telegraph FX.
3. Hit flash: the old code painted body polys white when
   `_hit_flash_timer > 0`. Now call once per frame (in `_update` or at the
   top of `_draw`):
   `TextureKit.set_flash(_body, 1.0 if _hit_flash_timer > 0.0 else 0.0)`
4. Do NOT touch collision shapes, stats, movement, or signals.
5. Do NOT run godot or import — code edits only. Match existing style
   (tabs, typed GDScript, one-line doc comments on public funcs).

## Baked texture names (assets/textures/)

- enemies/: scout, warrior, destroyer, elite_artillery, elite_interceptor,
  elite_swarm, silence, drone, leviathan, mothership
  (each has _survey/_dead/_wet/_normal)
- hazards/: rock_0..2, mine, derelict (each _survey/_dead/_normal)
- world/: planet_habitable, planet_rocky, planet_gas, planet_gold,
  light_radial, light_cone, starfield_0/1, nebula_0..2

## Lights (use sparingly — GL Compatibility)

- `TextureKit.point_light(parent, radius_px, color, energy) -> PointLight2D`
- Mothership: add a reactor light (ember `Color(1.0, 0.42, 0.2)`,
  radius ~90, energy ~0.9 with a slow pulse in `_update`) — the boss
  lights its own arena.
- Explosion (src/gameplay/effects/explosion.gd): one transient point light,
  energy starts ~1.2 and decays to 0 over the burst lifetime, color
  white -> ember orange. Free it with the effect.
- Missiles (player missile.gd): small warm light (radius 18, energy 0.5).
  Enemy bolts and lasers get NO lights (pool cost).
- Remember `queue_free()`d parents free their lights automatically.

## Special cases

- **the_silence.gd**: body sprite alpha must follow the cloak shimmer —
  set `_body.self_modulate.a` to the same alpha the old body polygon used
  (2–8% cloaked, full on decloak). Keep the shimmer outline + red eye.
- **space_leviathan.gd**: the old body wobbled its polygon verts. Instead
  pulse the sprite: `_body.scale = Vector2.ONE / 12.0 * (1.0 + 0.06 *
  sin(_wobble))` each frame, and keep tentacles/veins procedural.
- **mothership.gd**: pass px_per_unit 6.0. Keep reactor core glow, laser
  sweep, and all telegraphs procedural on top.
- **star_node.gd**: planet balls become fade_body sprites — map the node's
  planet/star type to planet_habitable / planet_rocky / planet_gas
  (final "gold shore" reveal -> planet_gold). The baked ball is 13 units
  radius at 12 px/unit — scale the sprite so it matches the node's radius
  (`_body.scale = Vector2.ONE * (radius / 13.0 / 12.0)`). Keep rings,
  atmosphere glows, scan brackets, labels procedural. Non-planet star
  types (actual stars, anomalies) STAY fully procedural — they are
  emissive.

## Verification

Just ensure the script parses (mental check / consistent typing). The
orchestrator runs the full in-engine screenshot pass afterward.
