## test_star_node.gd — Unit tests for scan pressure pulse behavior.
extends GutTest

func before_each() -> void:
	GameManager.start_new_game()

func test_setup_uses_empty_pressure_defaults() -> void:
	var star := StarNode.new()
	add_child_autofree(star)
	star.setup({"id":"T1", "result":"barren", "scan_duration":10})

	assert_eq(star.get_scan_pressure(), {})

func test_scan_pressure_pulses_fire_once_at_thresholds() -> void:
	var star := StarNode.new()
	add_child_autofree(star)
	var events: Array = []
	star.scan_pressure_pulse.connect(func(pulse, star_data): events.append({"pulse": pulse, "star_data": star_data}))
	star.setup({
		"id":"T2",
		"result":"barren",
		"scan_duration":10,
		"scan_pressure": {
			"pulses": [
				{"at":0.25, "type":"asteroid", "count":2},
				{"at":0.50, "type":"scout", "count":1}
			]
		}
	})

	star._start_scan()
	star._advance_scan(2.6)
	star._advance_scan(0.1)
	assert_eq(events.size(), 1, "First threshold should fire once")
	assert_eq(events[0]["pulse"].get("type", ""), "asteroid")
	assert_eq(events[0]["star_data"].get("id", ""), "T2")

	star._advance_scan(2.4)
	assert_eq(events.size(), 2, "Second threshold should fire when crossed")
	assert_eq(events[1]["pulse"].get("type", ""), "scout")
