# NOVA SCOUT — Game Concept Document

**Version:** 1.0  
**Studio:** Star-Finder Interactive  
**Engine:** Godot 4 (GDScript)  
**Target Playtime:** ~60 minutes (first clear), ~40 minutes (repeat)  
**Difficulty:** Medium  

---

## Logline

*A lone survey pilot steers their retrofuturist rocket through five uncharted sectors of deep space, scanning star systems for human-habitable worlds — fighting aliens, dodging asteroids, and racing against a dwindling fuel gauge to bring humanity's future home.*

---

## High Concept

**NOVA SCOUT** is a top-down arcade space shooter with exploration mechanics, built in the visual and tonal language of 1950s–70s science fiction cinema. Think *Forbidden Planet*, *Flash Gordon*, *2001: A Space Odyssey* title cards, and the warm analog glow of early NASA mission control.

The player pilots the **Survey Probe Seven** — a small, manned deep-space craft — on humanity's most important mission: find planets that can support human life. Every star system holds a secret. Most are barren rock and radiation. A few shimmer with possibility. And some are *already occupied*.

---

## Core Fantasy

> "I am the last explorer. The galaxy stretches infinite ahead of me. Every new star could be the one that saves humanity — or the one that ends my mission."

The game delivers three interlocking feelings:
1. **Wonder** — the satisfaction of scanning an unknown star and seeing it bloom into a habitable world
2. **Tension** — realizing alien ships are inbound and you have four seconds to choose fight or flight
3. **Momentum** — threading the needle through asteroid fields with fuel almost gone, laser blazing

---

## Setting

**Year: 2157**  
Earth's biosphere is in terminal decline. A global coalition has launched 12 Survey Probes on a one-way mission deep into the Milky Way. The probes carry a crew of one — a Survey Pilot — and enough fuel and supplies for a 90-day mission. If a suitable planet is found and survey data transmitted, a colony fleet will follow within a decade.

Eleven probes have gone silent.

You are **Survey Probe Seven**. You are the last chance.

---

## Core Game Loop

```
[TRAVEL] → [ENCOUNTER] → [SCAN STAR] → [RESULT: Barren / Human / Alien]
                ↓                              ↓              ↓
          [Shoot / Dodge /             [COLLECT DATA]   [COMBAT: Fight
           Collect]                    [Mark & Move]     or Escape]
                                              ↓
                                    [Collect 3 Survey
                                     Beacons → Return
                                     to Earth → WIN]
```

---

## Sector Structure (Campaign)

The game is divided into **5 Sectors**, each 10–15 minutes long. Sectors are traversed in order; there is no branching map. Within each sector the player travels through a scrolling field toward a **Star Cluster** containing 3–6 stars to investigate.

| Sector | Name | Theme | Hazard Level | Notes |
|--------|------|--------|--------------|-------|
| 1 | **Alpha — The Inner Rim** | Tutorial zone, familiar space | ★☆☆ | Teaches all mechanics, one guaranteed barren star, no aliens |
| 2 | **Beta — The Asteroid Fields** | Dense rock fields, first contact | ★★☆ | Heavy asteroids, first alien scouts appear |
| 3 | **Gamma — The Nebula Crossing** | Reduced visibility, eerie atmosphere | ★★☆ | Sensor interference, **first habitable planet** guaranteed |
| 4 | **Delta — Alien Territory** | Deep alien space, heavy combat | ★★★ | Multiple alien systems, **second habitable planet** |
| 5 | **Epsilon — The Frontier** | Endgame, maximum intensity | ★★★ | Alien Mothership boss, **third and final habitable planet** |

---

## Win / Loss Conditions

**Win:** Collect Survey Data from **3 human-habitable planets** (one per sector 3–5) and survive to sector end with hull intact.

**Loss:**
- Hull reaches 0% (craft destroyed)  
- Fuel reaches 0% outside a star system (adrift in void)
- Failed escape from alien system (cornered and destroyed)

**Score** is calculated from: Stars scanned × Data collected × Enemies destroyed × Fuel remaining × Hull condition × Time

---

## Tone & Visual Reference

| Reference | What We Take |
|-----------|-------------|
| *Forbidden Planet* (1956) | Retrofuturist design, warm Technicolor palette against black void |
| *The Day the Earth Stood Still* (1951) | Urgency, lonely protagonist, alien menace |
| *2001: A Space Odyssey* (1968) | Clinical UI, monospace type, sense of scale |
| *Flash Gordon* (1936–50s serial) | Bright energy blasts, pulpy excitement |
| *Asteroids* (Atari 1979) | Core feel of rotating in void, rocks splitting |
| *Galaga* (1981) | Wave-based alien attack patterns |
| *Star Fox* SNES (1993) | Cockpit urgency, memorable SFX |

**Color Palette:**
- Background: Near-black `#080B14` with subtle blue-violet star scatter
- UI: Phosphor green `#39FF14` / amber `#FFB000` on dark glass
- Player craft: Warm silver-white with red/orange engine glow
- Human habitable stars: Warm yellow-white pulse
- Alien territory: Cold magenta-purple warning aura
- Laser fire: Cyan `#00FFFF` (player), Red-orange `#FF4500` (alien)

---

## Unique Selling Points

1. **Star Scanning System** — orbit a star while hazards close in; the scan bar fills with beautiful retro animation; the result reveal is a genuine moment of discovery
2. **Tonal Authenticity** — not ironic retro, but *sincere* retro; the game treats its 50s–70s aesthetic with love and craft
3. **Two-Mode Combat** — asteroid fields play like Asteroids; alien systems play like a classic shmup — variety within one game
4. **Meaningful Progression** — each sector escalates cleanly; each new mechanic has one sector of breathing room before it gets hard
5. **60-Minute Arc** — designed as a complete experience; not a roguelike, not infinite; a story with a beginning, middle, and end
