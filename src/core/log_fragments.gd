## LogFragments — Recovered transmissions from the eleven silent probes.
## Derelict ships are graves; salvaging one yields the next fragment in a
## fixed escalation order (mundane → wrong → static). Restraint rule: the
## worst things are described, never shown.
## GDD Ref: dark-directive.md §4.4 Story
class_name LogFragments
extends RefCounted

## Fixed order — escalation is authored, not random.
const FRAGMENTS := [
	{
		"id": "p01",
		"title": "RECOVERED LOG — PROBE 01",
		"text": "Day 12. Fuel mixture runs rich. Dust in everything. Tell Mara the porch light still works — she'll know what I mean.",
	},
	{
		"id": "p03",
		"title": "RECOVERED LOG — PROBE 03",
		"text": "Survey quota met. Two candidates flagged. Coming home the long way, past the Pillars. Always wanted to see them up close.",
	},
	{
		"id": "p02",
		"title": "RECOVERED LOG — PROBE 02",
		"text": "Control cut our ration allowance again. Quota first, they said. The quota is fine. We are not.",
	},
	{
		"id": "p05",
		"title": "RECOVERED LOG — PROBE 05",
		"text": "Tracker says something keeps pace with us, two thousand klicks off the beam. Every burn, it matches. Cutting engines tonight to listen.",
	},
	{
		"id": "p04",
		"title": "RECOVERED LOG — PROBE 04",
		"text": "Found P-02's beacon cold. Hull opened along the weld lines. Neat. Like it was curious.",
	},
	{
		"id": "p08",
		"title": "RECOVERED LOG — PROBE 08",
		"text": "Stopped broadcasting the survey ping. The ping is how it finds us. If you're reading this: scan fast, scan once, go dark.",
	},
	{
		"id": "p09",
		"title": "RECOVERED LOG — PROBE 09",
		"text": "It doesn't hunt. It follows. There's a difference. Hunting ends.",
	},
	{
		"id": "p10",
		"title": "RECOVERED LOG — PROBE 10",
		"text": "Control, if you receive: the habitable worlds are real. They're real. That's why it waits here. A watering hole.",
	},
	{
		"id": "p11",
		"title": "RECOVERED LOG — PROBE 11",
		"text": "[STATIC] —not open the— [STATIC] —it was already inside the— [SIGNAL ENDS]",
	},
]

## Return the next unread fragment, or {} when the pool is exhausted.
## The cursor lives in GameManager so it survives sector scene reloads.
static func next_fragment() -> Dictionary:
	if GameManager.log_fragment_index >= FRAGMENTS.size():
		return {}
	var frag: Dictionary = FRAGMENTS[GameManager.log_fragment_index]
	GameManager.log_fragment_index += 1
	return frag

## Number of fragments recovered so far this run.
static func recovered_count() -> int:
	return GameManager.log_fragment_index

## Total fragments in the pool.
static func total_count() -> int:
	return FRAGMENTS.size()
