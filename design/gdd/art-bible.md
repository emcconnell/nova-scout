# NOVA SCOUT — Art Bible

**Version:** 1.0  
**Art Director:** Star-Finder Studio  

---

## Visual Identity Statement

NOVA SCOUT is a love letter to the science fiction of the 1950s–70s: the earnest wonder of pulp magazine covers, the warm glow of early NASA instrumentation, and the stylized alien menace of Forbidden Planet and Them! posters. We are **not** ironic about this. We are sincere, affectionate, and precise.

The visual language is: **retrofuturist pixel art with CRT soul.**

---

## Core Visual Pillars

1. **Warm Against Cold** — The player's craft is warm silver-white and cyan; space is deep cold blue-black. The contrast creates instant visual clarity and emotional warmth toward the player character.
2. **Analog Everything** — All UI, gauges, and readouts should feel like they were designed in 1962. Phosphor glow, analog dials, scan lines, monospace type.
3. **Bioluminescent Alien** — Enemies use organic, glowing magenta/purple — the visual opposite of the player. They feel alive and wrong in a way machines shouldn't be.
4. **Resolution Discipline** — Native resolution: **320×180** (16:9), scaled up 4× to 1280×720 or 6× to 1920×1080. Every sprite must be beautiful at 320×180 native resolution.

---

## Color Palette

### Primary Colors
| Name | Hex | Use |
|------|-----|-----|
| Void Black | `#080B14` | Background, space |
| Star White | `#E8EEFF` | Player craft, UI highlights, stars |
| Probe Cyan | `#00E5FF` | Laser fire, player energy, scan beam |
| Phosphor Green | `#39FF14` | Primary UI text, readouts |
| Amber Warning | `#FFB000` | Fuel gauge, secondary UI, warning states |

### Secondary Colors
| Name | Hex | Use |
|------|-----|-----|
| Alien Magenta | `#CC00FF` | Alien ship primary color |
| Alien Deep | `#4A0066` | Alien ship shadow/hull |
| Alien Pulse | `#FF00AA` | Alien weapon fire, glow effects |
| Rock Brown | `#5C4A2A` | Asteroids |
| Rock Highlight | `#8C7850` | Asteroid surface light |
| Warning Red | `#FF3300` | Hull damage, critical states, mines |
| Human Blue-Green | `#00CC88` | Human viable planet reveal |
| Gold Shore | `#FFD700` | Final planet, special rewards |
| Nebula Purple | `#6B0F8E` | Sector 3 background |
| Nebula Pink | `#CC44AA` | Sector 3 particle effects |

### UI Palette
- **Background:** `#0A0D1A` (slightly lighter than void)
- **UI Panel:** `#0F1428` with `#1A2040` border
- **Active Text:** `#39FF14` (phosphor green)
- **Inactive Text:** `#1A6608` (dim phosphor)
- **Warning Text:** `#FFB000` (amber)
- **Critical Text:** `#FF3300` (red)

---

## Sprite Specifications

### Resolution & Style
- **Native canvas:** 320×180 pixels
- **Sprite style:** Clean pixel art — no dithering on the player craft, subtle dithering allowed on asteroids and backgrounds
- **Outline style:** Dark outlines (1px) on all interactive sprites; no outline on background elements
- **Animation:** All animations at 8–12fps — the slight choppiness is intentional (retro feel)

### Player Craft — Survey Probe Seven
- **Size:** 16×22px (upright, nose-up orientation)
- **Design concept:** An elegant retrofuturist rocket — narrow fuselage, swept delta wings, prominent engine bell, small cockpit bubble at top. Think the Spaceship from the 1950s cardboard models. Add subtle NASA-style markings: "SP-7" on the hull in tiny monospace.
- **Sprite states:**
  - Idle (1 frame)
  - Thrust (3-frame loop — engine glow pulses)
  - Left bank (1 frame — craft tilts ~15°)
  - Right bank (1 frame)
  - Hit flash (1 frame — white fill)
  - Explosion (8-frame sequence — debris burst outward)
- **Engine glow:** Orange-red animated light cone behind engine; increases with boost
- **Shield visual:** Subtle hexagonal outline around craft when shield active; shimmers on hit

### Enemy Sprites

**Alien Scout:** 12×10px. Flat saucer. Magenta ring on underside. Blinking red eye-lights.  
**Alien Warrior:** 18×14px. Elongated fin shape. Purple body, glowing stripe.  
**Alien Destroyer:** 32×28px. Beetle carapace. Multiple weapon ports visible.  
**Alien Elite (3 variants):** 24×22px each. Distinct silhouettes per variant.  
**Mothership:** 160×80px (half the screen width). Multi-part sprite with animated reactor core, blast doors, rotating weapon arrays.

### Asteroid Sprites
- 3 sizes: 24×24, 16×16, 8×8 pixels
- 3 visual variants each (9 total) — different shapes and crack patterns
- Slow rotation animation (4 frames)
- Color: Rocky brown-grey with lighter surface highlights

### Projectiles
| Projectile | Size | Color | Animation |
|------------|------|-------|-----------|
| Player laser | 2×8px | Cyan `#00E5FF` | Slight trail |
| Player missile | 4×10px | White body, orange trail | Smoke trail (3 frames) |
| EMP ring | 0 → 300px | Bright cyan, fading | Expanding ring |
| Alien bolt (scout) | 3×3px | Magenta | Pulsing dot |
| Alien burst (warrior) | 4×4px | Alien Pulse pink | Spinning diamond |
| Alien beam (destroyer) | 4×full | Red-orange | Sweeping |
| Mothership laser sweep | 8×full | Deep red with white core | Scroll across |

---

## Background & Environment Art

### Space Background
- **Layer 1 (far):** Near-black void. Static. `#080B14`.
- **Layer 2 (distant stars):** 80–100 tiny 1px star dots. Random white/blue-white. Scroll at 20% player speed (parallax).
- **Layer 3 (mid stars):** 30–40 slightly larger (1–2px) stars. Some with subtle twinkle (2-frame flicker, rare). Scroll at 40% speed.
- **Layer 4 (near features):** Occasional large nebula wisps, distant planet silhouettes. Scroll at 70% speed.

### Sector-Specific Backgrounds

**Sector 1 — Inner Rim:**  
Clean deep navy. Warm distant nebula hint on lower edge. Familiar, reassuring.

**Sector 2 — Asteroid Fields:**  
Similar to S1 but asteroid dust particles drift through mid-layer. Rock-brown tint to nebula wisps.

**Sector 3 — Nebula Crossing:**  
Heavy purple-pink particle overlay. Visibility effect achieved by desaturation + pink fog layer at 50% opacity. Occasional bright white pulsar flash (1-frame, 3× normal star brightness).

**Sector 4 — Alien Territory:**  
Deep purple-black. Alien architectural elements visible in far background (non-interactive silhouettes — towers, arcs, geometric shapes). Unsettling and beautiful. Alien glyphs appear on some asteroid surfaces (texture variant).

**Sector 5 — The Frontier:**  
Overwhelmingly vivid. More stars than any other sector. Brighter. Beautiful. An ancient, undisturbed region of space. The contrast with the terror of the combat should be striking.

---

## UI Design

### Philosophy: Mission Control, 1962
Every UI element should look like it was designed by engineers who took pride in their instruments. Functionality is beautiful. Clarity is paramount. Everything has a border, a label, and a phosphor glow.

### HUD Layout
```
╔══════════════════════════════════════════════════════════════╗
║  [HULL: ████████░░]  [SHIELD: ██████░░░░]    [SECTOR: β▸▸▸] ║
║                                              [SCORE: 024500] ║
║                                                              ║
║                    [GAME AREA 320×140]                       ║
║                                                              ║
║  [FUEL: ◉◉◉◉◉◉◉◉◉○]           [MISSILES: ▲▲▲ ×3]           ║
║                                [EMP:  ⊙ ×1 ]               ║
╚══════════════════════════════════════════════════════════════╝
```

### Fonts
- **Primary display font:** Monospace, pixelated — a custom 6×8 or 5×7 pixel font styled like early computer terminals
- **Body font (story text):** Courier New or equivalent, uppercase only for authenticity
- **Numbers:** Dedicated digit sprites for maximum clarity on gauges

### Scan Bar (during star investigation)
- Large arc gauge centered on screen, semi-transparent
- Fills with phosphor green, glowing brighter at the leading edge
- Ring pulses with soft CRT green
- Star name appears above: "STAR DESIGNATION: G-2 / SCANNING..."
- Progress percentage in large digits: "47%"

### CRT Effects
- Scanline overlay: `#000000` at 15% opacity, alternating lines
- Vignette: radial gradient, dark edges
- Bloom: subtle glow on bright objects (player craft, lasers, UI text)
- Chromatic aberration on hit: single frame, red/blue channel split ±2px

---

## Animation Style

- **Frame rate:** 8fps for enemies and environment; 12fps for player craft; UI at 60fps
- **Explosion:** Debris pixel burst — pieces fly outward and fade over 0.8 seconds
- **Warp sequence:** Stars compress to horizontal streaks over 1.5 seconds; hold 0.5 sec; expand back
- **Planet reveal:** Planet fades in from black, rotates slowly, atmospheric shimmer at edge; 3-second sequence
- **Screen flash on hit:** 1 frame white fill on player sprite; HUD border flickers red for 0.3 sec
- **Alien death:** Distinct per tier — Scouts pop in a burst; Warriors fragment into 3 pieces; Destroyers have delayed secondary explosion
