# Star Scanning Signature Mechanic Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Turn star scanning from a mostly passive timer into Nova Scout's signature risk/reward mechanic.

**Architecture:** Add scan pressure in layers: data model first, then hazard pulses, then stability/damage consequences, then optional overcharge, then presentation. Keep all tuning values data-driven or centralized so design iteration does not require script surgery.

**Tech Stack:** Godot 4, GDScript, GUT tests, JSON/Dictionary scan configs.

---

## Design Target

A good scan should ask the player:

- Is this star worth the risk?
- Can I survive the next pressure pulse?
- Should I abort now with hull/fuel low?
- Should I overcharge for bonus rewards?

A scan should not be just “hold still until bar fills.”

---

## Task 1: Document current scan behavior and tuning knobs

**Objective:** Establish exact current behavior before changing it.

**Files:**

- Create: `docs/current-gameplay-state.md` if it does not exist
- Modify: `design/gdd/gameplay-mechanics.md` or create a focused quick spec under `design/quick-specs/`

**Steps:**

1. Read `src/gameplay/star_scan/star_node.gd` and `src/gameplay/star_scan/star_cluster_manager.gd`.
2. Document current scan start, orbit, abort, completion, result, and reward behavior.
3. List tuning knobs that need data support:
   - scan_duration
   - pulse thresholds
   - pulse enemy/hazard type
   - stability loss on damage
   - minimum stability before abort
   - overcharge duration
   - overcharge reward multiplier
4. Commit docs.

**Verification:** Another developer can read the doc and understand the current scan flow without opening code.

---

## Task 2: Add scan pressure config fields

**Objective:** Make star configs able to describe scan pressure without hardcoding per-star behavior.

**Files:**

- Modify: `src/gameplay/star_scan/star_cluster_manager.gd`
- Modify: `src/gameplay/star_scan/star_node.gd`
- Later migration target: `assets/data/star_clusters/sector_*.json`

**Example config:**

```gdscript
{
	"id": "G2",
	"result": "human_viable",
	"scan_duration": 10,
	"guaranteed": true,
	"risk_label": "Stable G-Type",
	"reward_label": "High survey value",
	"scan_pressure": {
		"pulses": [
			{"at": 0.25, "type": "asteroid", "count": 2},
			{"at": 0.50, "type": "mine", "count": 1},
			{"at": 0.75, "type": "scout", "count": 2}
		],
		"stability_loss_on_damage": 0.20,
		"min_stability": 0.15
	}
}
```

**Steps:**

1. Add optional fields without changing behavior yet.
2. Pass pressure config from StarClusterManager into StarNode.
3. Add defensive defaults when fields are missing.
4. Add debug logging only if existing style permits; remove noisy logs before commit.

**Verification:** Existing stars scan exactly as before when no pressure config exists.

---

## Task 3: Add scan progress threshold pulse events

**Objective:** Emit events at configured scan progress thresholds.

**Files:**

- Modify: `src/gameplay/star_scan/star_node.gd`
- Modify: `src/gameplay/star_scan/star_cluster_manager.gd` or `src/core/game_world.gd`

**Steps:**

1. Add signal to StarNode:

```gdscript
signal scan_pressure_pulse(pulse: Dictionary, star_data: Dictionary)
```

2. Track fired pulse indices/thresholds so each fires once.
3. During scan progress, when progress crosses `pulse["at"]`, emit the signal.
4. In StarClusterManager, connect the signal and forward to GameWorld via group call or a typed signal.
5. In GameWorld, implement minimal pulse spawning:
   - asteroid pulse -> small asteroids from top/sides
   - mine pulse -> one mine away from direct collision path
   - scout pulse -> small enemy wave
6. Keep Sector 1 pulses gentle or disabled.

**Verification:** In a debug scan, pulses fire at 25/50/75% once each and do not fire after abort/completion.

---

## Task 4: Add scan stability and damage consequences

**Objective:** Make damage during scan matter without causing unfair instant failure.

**Files:**

- Modify: `src/gameplay/star_scan/star_node.gd`
- Modify: player health signal hookup if needed
- Modify HUD if scan stability needs display

**Rules:**

- Scan starts at stability 1.0.
- Taking hull/shield damage during scan reduces stability by configured amount.
- Low stability slows progress or causes noisy rollback.
- If stability falls below `min_stability`, scan aborts with a clear message/cue.

**Example minimal implementation:**

```gdscript
var scan_stability: float = 1.0

func apply_scan_damage_consequence(amount: float) -> void:
	scan_stability = maxf(0.0, scan_stability - amount)
	if scan_stability <= _min_stability:
		_abort_scan_due_to_instability()
```

**Verification:**

- Damage during scan visibly changes stability/progress.
- Damage outside scan has no scan effect.
- Abort from instability uses existing abort cleanup and does not leave player stuck in orbit.

---

## Task 5: Add optional overcharge

**Objective:** Let players voluntarily extend a completed scan for bonus rewards and more danger.

**Files:**

- Modify: `src/gameplay/star_scan/star_node.gd`
- Modify: `src/gameplay/star_scan/star_cluster_manager.gd`
- Modify: `src/core/game_world.gd` reward handling if needed

**Rules:**

- At 100% scan, player can release/confirm to finish immediately.
- Holding scan enters overcharge for up to configured seconds.
- Overcharge increases reward multiplier or rare anomaly chance.
- Overcharge can trigger one extra pressure pulse.
- Overcharge must not be required for campaign-critical stars.

**Verification:**

- Normal scan completion still works.
- Overcharge can be aborted/finished cleanly.
- Rewards reflect overcharge amount.
- Campaign beacon logic is unaffected.

---

## Task 6: Add star labels and result reveal presentation

**Objective:** Improve readability and wonder.

**Files:**

- Modify: StarNode drawing/UI label code
- Modify: HUD or overlay scene if result reveal belongs there
- Possibly create: `src/ui/scan_result_reveal.gd` and scene

**Features:**

- Vague pre-scan labels:
  - “Faint Yellow”
  - “Magenta Interference”
  - “Stable G-Type”
  - “Unknown Signal”
- Risk/reward hints:
  - Low Risk / High Interference / Alien Signal / Anomaly Suspected
- Result reveal:
  - spectrum bars
  - mission-control line
  - planet silhouette for viable worlds
  - noisy red alert for alien territory

**Verification:**

- Labels are readable at 320x180 internal resolution.
- Reveal does not obscure active danger unless gameplay is intentionally paused.
- Result reveal has a skip/fast-forward path if it interrupts replay flow.

---

## Task 7: Add tests and data validation

**Objective:** Prevent scan regressions.

**Files:**

- Create/modify: `tests/unit/test_star_scan.gd`
- Modify: `scripts/validate_data.py` from the data plan when available

**Test cases:**

- Scan with no pressure config behaves as default.
- Pulse thresholds fire once.
- Abort clears active scan state.
- Completion emits exactly one result.
- Stability loss can abort scan.
- Overcharge bonus does not affect beacon count incorrectly.

**Verification command:**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit
```

---

## Final Manual Playtest Checklist

- [ ] Sector 1 scan teaches the mechanic safely.
- [ ] Sector 3 scan pressure feels tense but fair.
- [ ] Sector 5 scan pressure feels climactic.
- [ ] Optional stars are tempting.
- [ ] Aborting scan is understandable.
- [ ] Overcharge creates a meaningful greed moment.
- [ ] No scan can softlock player movement, arena state, or sector transition.
