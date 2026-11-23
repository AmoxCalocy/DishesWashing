extends SceneTree
## Import scripts/resources first, then run:
## godot --headless --path . --script Tools/verify_cleanliness.gd

var failures: int = 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_dish(initial_amounts: Array[float]) -> DishState:
	var config := DishConfig.new()
	config.dish_type = &"plate"
	for index in range(initial_amounts.size()):
		var region := StainRegionConfig.new()
		region.region_id = StringName("region_%d" % index)
		region.initial_amount = initial_amounts[index]
		if index % 2 == 1:
			region.stain_type = StainRegionConfig.Kind.OIL
		config.stain_regions.append(region)
	return DishState.new(&"cleanliness_test", config, &"test_slot")

func check_progress(dish: DishState, expected: float, percent: int, qualifies: bool, context: String) -> void:
	check(absf(dish.get_cleanliness() - expected) <= 0.000000000001, "%s: actual cleanliness is incorrect." % context)
	check(dish.get_cleanliness_percent() == percent, "%s: display percentage is incorrect." % context)
	check(dish.meets_cleanliness_requirement() == qualifies, "%s: cleanliness qualification is incorrect." % context)

func verify() -> void:
	var weighted := make_dish([6.0, 3.0, 1.0])
	check_progress(weighted, 0.0, 0, false, "Initially dirty")
	weighted.stain_regions[&"region_0"].remaining_amount = 0.0
	check_progress(weighted, 0.6, 60, false, "Unequal initial amounts, food region cleaned")
	weighted.stain_regions[&"region_1"].remaining_amount = 1.0
	check_progress(weighted, 0.8, 80, false, "Partially cleaned oil region")
	for region: StainRegionState in weighted.stain_regions.values():
		region.foam_amount = 1.0
		region.foam_weight = 99.0
	weighted.detergent_applied = true
	weighted.is_held = true
	weighted.current_slot_id = &""
	check_progress(weighted, 0.8, 80, false, "Foam, foam weights and handling do not change cleanliness")
	for region: StainRegionState in weighted.stain_regions.values():
		region.remaining_amount = 0.0
	check_progress(weighted, 1.0, 100, true, "Completely clean with foam still present")
	for region: StainRegionState in weighted.stain_regions.values():
		region.foam_amount = 0.0
	check_progress(weighted, 1.0, 100, true, "Rinsing foam leaves cleanliness unchanged")

	var boundary := make_dish([1000.0])
	var boundary_region: StainRegionState = boundary.stain_regions[&"region_0"]
	boundary_region.remaining_amount = 51.0
	check_progress(boundary, 0.949, 95, false, "94.9 percent must not qualify despite displaying 95")
	boundary_region.remaining_amount = 50.0
	check_progress(boundary, 0.95, 95, true, "Exactly 95 percent qualifies")
	boundary_region.remaining_amount = 49.0
	check_progress(boundary, 0.951, 95, true, "95.1 percent qualifies")
	boundary_region.remaining_amount = 50.000001
	check(not boundary.meets_cleanliness_requirement(), "A value just below 95 percent must not qualify via approximate equality.")
	boundary_region.remaining_amount = 49.999999
	check(boundary.meets_cleanliness_requirement(), "A value just above 95 percent must qualify.")
	boundary_region.remaining_amount = 0.0
	check_progress(boundary, 1.0, 100, true, "Qualification follows the current remaining amount")
	boundary_region.remaining_amount = 1000.0
	check_progress(boundary, 0.0, 0, false, "Reverting to dirty must revoke qualification")

	var bounded := make_dish([6.0, 3.0, 1.0])
	bounded.stain_regions[&"region_0"].remaining_amount = -4.0
	bounded.stain_regions[&"region_1"].remaining_amount = 5.0
	check_progress(bounded, 0.6, 60, false, "Clamp each region so overshoot cannot cancel another region's dirt")
	check(bounded.stain_regions[&"region_0"].remaining_amount == -4.0, "Reading cleanliness must not mutate negative remaining data.")
	check(bounded.stain_regions[&"region_1"].remaining_amount == 5.0, "Reading cleanliness must not mutate excess remaining data.")
	for region: StainRegionState in bounded.stain_regions.values():
		region.remaining_amount = region.initial_amount + 10.0
	check_progress(bounded, 0.0, 0, false, "Lower bound")
	for region: StainRegionState in bounded.stain_regions.values():
		region.remaining_amount = -10.0
	check_progress(bounded, 1.0, 100, true, "Upper bound")

	check_progress(make_dish([]), 1.0, 100, true, "No stain regions")
	var zero := make_dish([0.0, 0.0])
	zero.stain_regions[&"region_0"].remaining_amount = 7.0
	zero.stain_regions[&"region_0"].foam_amount = 1.0
	check_progress(zero, 1.0, 100, true, "No initial dirt even if an initially clean region has residual data")
	var mixed := make_dish([0.0, 10.0])
	mixed.stain_regions[&"region_0"].remaining_amount = 7.0
	mixed.stain_regions[&"region_1"].remaining_amount = 5.0
	check_progress(mixed, 0.5, 50, false, "An initially clean region contributes no dirt")
	check_progress(make_dish([0.000000000001]), 0.0, 0, false, "A small positive initial amount is not zero")

	if failures == 0:
		print("CLEANLINESS_OK: weighted dirt, zero dirt, bounds, foam independence and actual 95 percent threshold.")
		quit(0)
	else:
		push_error("CLEANLINESS_FAILED: %d check(s) failed." % failures)
		quit(1)
