extends GutTest

func test_pickup_feedback_labels_explain_reward() -> void:
	var pickup := PickupBase.new()
	pickup.setup("crystal")
	assert_eq(pickup.get_feedback_text(), "+1 DATA")
	pickup.setup("fuel_cell")
	assert_eq(pickup.get_feedback_text(), "+25 FUEL")
	pickup.setup("survey_beacon")
	assert_eq(pickup.get_feedback_text(), "+3000 BEACON")
	pickup.free()

func test_pickup_score_values_match_feedback_scale() -> void:
	var pickup := PickupBase.new()
	assert_eq(pickup.get_score_value_for_type("fuel_cell"), 10)
	assert_eq(pickup.get_score_value_for_type("crystal"), 25)
	assert_eq(pickup.get_score_value_for_type("survey_beacon"), 3000)
	pickup.free()
