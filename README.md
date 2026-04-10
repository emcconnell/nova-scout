# NOVA SCOUT

> *Survey Probe Seven. Five sectors. Three habitable worlds. One hour to save humanity.*

A top-down arcade space shooter built in **Godot 4** (GDScript), set in the visual and tonal language of 1950s–70s retrofuturist science fiction.

---

## Story

Earth's biosphere is in terminal decline. You are the pilot of Survey Probe Seven — one of twelve probes sent on a one-way mission deep into the Milky Way. Your mission: scan star systems, find planets that can sustain human life, and transmit the data home before your fuel runs out.

Five sectors. Unknown alien contact. A dwindling fuel gauge. And humanity's future riding on every jump.

---

## Gameplay

- **Top-down arcade shooter** with exploration mechanics
- **5 procedurally-scribed sectors**, each with a unique encounter sequence
- **Star Cluster phases** — scan stars to find habitable worlds, triggering alien combat arenas
- **Upgrade system** — spend Data Crystals between sectors on hull, fuel, shield regen, missiles, and laser damage
- **Mothership boss fight** — 3-phase adaptive battle at the end of Sector 5
- **Dual endings** — True Ending (all 3 beacons found) vs Standard Ending (mission complete)

### Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD / Arrow Keys | Left Stick |
| Boost | Shift | LB |
| Fire Laser | Space | Right Trigger |
| Fire Missile | X | RB |
| Fire EMP | Z | Select |
| Interact / Scan | E | Left Trigger |
| Pause | Escape | Start |

---

## Running the Game

### From Source (Godot Editor)

1. Install [Godot 4.6](https://godotengine.org/download) or later
2. Clone this repository
3. Open Godot → **Import** → select `project.godot`
4. Press **F5** (or Run ▶) to play

### Exported Builds

After exporting (see below), find platform builds in the `builds/` directory:

| Platform | Path |
|----------|------|
| Windows | `builds/windows/nova-scout.exe` |
| macOS | `builds/macos/nova-scout.zip` |
| Linux | `builds/linux/nova-scout.x86_64` |
| Web | `builds/web/index.html` |

---

## Building / Exporting

Export presets for Windows, macOS, Linux, and Web are configured in `export_presets.cfg`.

1. Open the project in Godot Editor
2. **Project → Export**
3. Select your platform preset
4. Click **Export Project**

> You must have Godot export templates installed for your target platform. Download them via **Editor → Manage Export Templates**.

---

## Project Structure

```
nova-scout/
├── assets/
│   ├── audio/          # Music (OGG) + SFX (WAV) — see AUDIO_MANIFEST.md
│   ├── data/           # Encounter wave JSON and star cluster data
│   ├── shaders/        # CRT overlay GLSL shader
│   └── sprites/        # Sprite assets
├── design/gdd/         # Full Game Design Documents
├── production/         # Sprint plans, epics, milestones
├── scenes/             # Godot scene files (.tscn)
├── src/
│   ├── core/           # Singletons: GameManager, AudioManager, SaveManager
│   ├── gameplay/       # Player, enemies, hazards, pickups, projectiles, star scan
│   ├── systems/        # Drop tables, encounter generation
│   └── ui/             # HUD, menus, overlays, transitions
└── tests/unit/         # GUT test suite
```

---

## Audio

Audio assets are **not yet included** in this repository (they require sourcing or composition). The game runs silently without them — all audio paths fail gracefully.

See `assets/audio/AUDIO_MANIFEST.md` for the complete list of required files, their exact filenames, and sourcing recommendations.

**Style:** 1957-era retrofuturist electronic — theremin, Moog synthesizer, analog percussion. Reference: Louis and Bebe Barron (*Forbidden Planet*, 1956).

---

## Technical Details

| Property | Value |
|----------|-------|
| Engine | Godot 4.6 |
| Language | GDScript |
| Renderer | GL Compatibility (broad hardware support) |
| Resolution | 320×180 (pixel-art, scaled to 1280×720) |
| Target FPS | 60 |
| Platform | Windows, macOS, Linux, Web |

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

*Developed with [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) — 49-agent AI development studio.*
