## Unit tests — VisualState v5.0 "Wet Black" post-stack hooks (bloom / tonemap
## grade) and shadow/dust tuning data. GDD Ref: art-bible.md §0 (v5.0).
extends GutTest

func test_post_exposure_reads_data() -> void:
	var e: float = VisualState.post_exposure()
	assert_between(e, 0.25, 2.0, "exposure should sit in the shader's sane range")

func test_bloom_strength_lerps_with_blend() -> void:
	# Blend is state-driven (menu pulls it toward menu_blend) — assert the
	# lerp against whatever the current blend actually is.
	var survey := float(VisualState.value("post", "bloom_survey", 0.35))
	var dead := float(VisualState.value("post", "bloom_dead", 0.75))
	var expected := lerpf(survey, dead, VisualState.blend())
	assert_almost_eq(VisualState.bloom_strength(), expected, 0.0001,
		"bloom gain must lerp survey->dead by the live blend")

func test_bloom_threshold_positive() -> void:
	assert_gt(VisualState.bloom_threshold(), 0.0)

func test_grade_amount_tracks_blend() -> void:
	var strength := float(VisualState.value("post", "grade_strength", 0.85))
	assert_almost_eq(VisualState.grade_amount(), VisualState.blend() * strength,
		0.0001, "grade must be the fade scaled by grade_strength — nothing else")

func test_shadow_tuning_present() -> void:
	assert_true(bool(VisualState.value("shadows", "enabled", false)),
		"v5.0 ships with 2D shadows enabled")
	var alpha := float(VisualState.value("shadows", "color_alpha", 0.0))
	assert_between(alpha, 0.3, 1.0, "shadows must block meaningfully but never fully")

func test_dust_tuning_sane() -> void:
	assert_gt(int(VisualState.value("dust", "count", 0)), 0)
	var base := float(VisualState.value("dust", "base_alpha", 1.0))
	var beam := float(VisualState.value("dust", "beam_alpha", 0.0))
	assert_lt(base, 0.1, "dust must be near-invisible outside the beam")
	assert_gt(beam, base, "the beam must ignite the dust")
