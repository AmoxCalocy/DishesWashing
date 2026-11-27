extends "res://Tools/verify_dish_drop.gd"
## G retains the fixed rack rule; all other releases use gravity.

func view_slot_for_drop(slot: KitchenSlot) -> void:
	await view_point(slot.get_pose().origin, Vector3(slot.get_pose().origin.x, 0.03, 0.9))

func verify() -> void:
	await load_game()
	var rack_ids: Array[StringName] = []
	for slot: KitchenSlot in registry.slots.values():
		if slot.config.slot_kind == SlotConfig.Kind.DRAINING_RACK:
			rack_ids.append(slot.config.slot_id)
	for slot_id in rack_ids:
		await load_game()
		var slot: KitchenSlot = registry.slots[slot_id]
		var dish: DishBody = await take_initial("TrayMug01" if slot.accepts(&"mug") else "TrayPlate01")
		carry.dish_states[dish.instance_id] = make_state(dish)
		await view_slot_for_drop(slot)
		expect_no_preview()
		click()
		check(carry.selected_dish == dish and slot.is_empty(), "Left click no longer confirms rack placement.")
		tap(&"game_drop")
		check(slot.state.occupant_id == dish.instance_id and dish.location == DishBody.Location.REGISTERED and dish.global_transform.is_equal_approx(slot.get_pose()) and dish.motion_body.freeze and carry.held_count() == 0, "G places one original dish at its valid rack pose, preserving the exact full orientation.")
		await ticks()
		await aim(dish)
		tap(&"game_interact")
		check(carry.selected_dish == dish and slot.is_empty(), "Rack repick releases only its current slot.")
	await load_game()
	var dish: DishBody = await take_initial("TrayPlate01")
	var slot: KitchenSlot = registry.slots[&"Rack_Slot_01"]
	await view_slot_for_drop(slot)
	tap(&"game_drop")
	check(carry.selected_dish == dish and slot.is_empty(), "Unknown cleanliness cannot authorize fixed rack occupancy.")
	carry.dish_states[dish.instance_id] = make_state(dish, 51.0)
	tap(&"game_drop")
	check(carry.selected_dish == dish and slot.is_empty(), "Rounded 95% cannot authorize a dirty dish in a fixed rack slot.")
	game.free()
	if failures == 0:
		print("DISH_PLACEMENT_OK: G commits all 8 clean rack poses, same identity and occupancy/repick, no left-click placement or preview, unknown/dirty refusal.")
		quit(0)
	else:
		quit(1)
