extends SceneTree
## Import scripts/resources first, then run:
## godot --headless --path . --script Tools/verify_runtime_state.gd

var failures: int = 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
		quit(1)

func check_initial_state(state: OrderState, config: OrderConfig, layout: KitchenLayoutConfig) -> void:
	check(state.order_id == config.order_id, "Order ID did not reset.")
	check(state.dishes.size() == config.items.size(), "Dish count did not reset.")
	check(state.slots.size() == layout.slots.size(), "Slot count did not reset.")
	check(state.tools.selected_tool == ToolState.Tool.NONE, "Tool selection did not reset.")
	check(not state.tools.sponge_is_wet, "A new order must have a dry sponge.")
	check(not state.tools.faucet_is_on, "A new order must have a closed faucet.")
	check(not state.tools.soap_bottle_is_held, "A new order must have a returned soap bottle.")
	for item in config.items:
		var dish: DishState = state.dishes[item.instance_id]
		check(dish.instance_id == item.instance_id, "Dish identity is incorrect.")
		check(dish.dish_type == item.dish.dish_type, "Dish type is incorrect.")
		check(dish.current_slot_id == item.initial_slot_id, "Dish position did not reset.")
		check(not dish.is_held, "A new dish must start in its slot.")
		check(not dish.detergent_applied, "Detergent state did not reset.")
		check(state.slots[item.initial_slot_id].occupant_id == item.instance_id, "Initial occupancy is incorrect.")
		check(dish.stain_regions.size() == item.dish.stain_regions.size(), "Region count did not reset.")
		for region_config in item.dish.stain_regions:
			var region: StainRegionState = dish.stain_regions[region_config.region_id]
			check(region.stain_type == region_config.stain_type, "Stain type is incorrect.")
			check(is_equal_approx(region.initial_amount, region_config.initial_amount), "Initial amount changed.")
			check(is_equal_approx(region.remaining_amount, region_config.initial_amount), "Remaining amount did not reset.")
			check(is_equal_approx(region.foam_weight, region_config.foam_weight), "Foam weight changed.")
			check(is_zero_approx(region.foam_amount), "Foam did not reset.")
	for slot_config in layout.slots:
		var slot: SlotState = state.slots[slot_config.slot_id]
		check(slot.slot_id == slot_config.slot_id, "Slot identity is incorrect.")
		check(slot.slot_kind == slot_config.slot_kind, "Slot kind is incorrect.")
		var expected_occupant: StringName = &""
		for item in config.items:
			if item.initial_slot_id == slot.slot_id:
				expected_occupant = item.instance_id
		check(slot.occupant_id == expected_occupant, "An unoccupied slot retained an occupant.")

func verify() -> void:
	var config := load("res://Resources/Examples/order-config-example.tres") as OrderConfig
	var layout := load("res://Resources/Examples/layout-config-example.tres") as KitchenLayoutConfig
	if config == null or layout == null:
		push_error("Could not load the verification resources.")
		quit(1)
		return
	check(config.items[0].dish == config.items[1].dish, "The two plates must share a configuration for this check.")
	check(config.items[0].dish.model != null, "The plate model is missing.")
	check(config.items[2].dish.model != null, "The mug model is missing.")
	var first := OrderState.new(config, layout)
	var second := OrderState.new(config, layout)
	check_initial_state(first, config, layout)
	check_initial_state(second, config, layout)
	check(first.tools != second.tools, "Tool state is shared between orders.")
	check(first.dishes[&"plate_01"] != second.dishes[&"plate_01"], "Dish state is shared between orders.")
	check(first.slots[&"Dirty_Plate_01"] != second.slots[&"Dirty_Plate_01"], "Slot state is shared between orders.")
	check(first.dishes[&"plate_01"] != first.dishes[&"plate_02"], "The plates share a runtime state.")
	var changed: DishState = first.dishes[&"plate_01"]
	changed.stain_regions[&"front_food"].remaining_amount = 1.5
	changed.stain_regions[&"front_food"].initial_amount = 99.0
	changed.stain_regions[&"front_food"].foam_amount = 0.5
	changed.stain_regions[&"front_food"].foam_weight = 99.0
	changed.detergent_applied = true
	changed.current_slot_id = &"Rack_Slot_01"
	first.slots[&"Dirty_Plate_01"].occupant_id = &""
	first.slots[&"Rack_Slot_01"].occupant_id = changed.instance_id
	first.tools.sponge_is_wet = true
	first.tools.faucet_is_on = true
	first.tools.soap_bottle_is_held = true
	first.tools.selected_tool = ToolState.Tool.SPONGE
	first.order_id = &"changed_order"
	check(is_equal_approx(first.dishes[&"plate_02"].stain_regions[&"front_food"].remaining_amount, 6.0), "Cleaning one plate changed the other.")
	check(not first.dishes[&"plate_02"].detergent_applied, "Detergent leaked to another plate.")
	check(is_zero_approx(first.dishes[&"plate_02"].stain_regions[&"front_food"].foam_amount), "Foam leaked to another plate.")
	check_initial_state(second, config, layout)
	changed.is_held = true
	changed.current_slot_id = &""
	first.slots[&"Rack_Slot_01"].occupant_id = &""
	changed.stain_regions.erase(&"back_oil")
	first.dishes.erase(&"plate_02")
	first.slots.erase(&"Rack_Cup_Slot_01")
	check_initial_state(second, config, layout)
	var fresh := OrderState.new(config, layout)
	check_initial_state(fresh, config, layout)
	check(fresh.tools != first.tools and fresh.tools != second.tools, "A fresh order reused tool state.")
	var source_region: StainRegionConfig = config.items[0].dish.stain_regions[0]
	check(is_equal_approx(source_region.initial_amount, 6.0), "Runtime edits changed the shared initial stain amount.")
	check(is_equal_approx(source_region.foam_weight, 2.0), "Runtime edits changed the shared region weight.")
	check(config.items[0].dish.stain_regions.size() == 3, "Runtime edits changed the region configuration array.")
	check(config.items.size() == 3 and layout.slots.size() == 5, "Runtime edits changed the configuration collections.")
	check(config.items[0].initial_slot_id == &"Dirty_Plate_01", "Runtime movement changed the initial placement.")
	check(layout.slots[0].accepted_dish_types == [&"plate"], "Runtime edits changed slot compatibility.")
	check(config.base_reward == 100 and config.first_completion_bonus == 25, "Runtime edits changed reward configuration.")
	if failures == 0:
		print("RUNTIME_STATE_OK: independent dishes, regions, slots and tools; fresh defaults; shared configs unchanged.")
		quit(0)
	else:
		push_error("RUNTIME_STATE_FAILED: %d check(s) failed." % failures)
		quit(1)
