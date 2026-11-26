extends "res://Tools/verify_placement_preview.gd"
## Import first, then: godot --headless --path . --script Tools/verify_dish_placement.gd
## Real clicks commit fresh poses; free dishes remain identifiable and pickable.

func take_initial(name: String) -> DishBody:
	var dish := game.get_node("PlayableDishes/" + name) as DishBody
	await stand(Vector3(0, 0.03, 0.8))
	await aim(dish)
	click()
	check(carry.hands.any(func(item: HandItem) -> bool: return item != null and item.node == dish), "Initial pickup must succeed before placement verification.")
	return dish

func expect_world(dish: DishBody, pose: Transform3D, slot: KitchenSlot = null) -> void:
	check(dish.get_parent() == game.get_node("PlayableDishes") and dish.global_transform.is_equal_approx(pose), "Commit must snap the original body and collision to the newly authorized complete pose.")
	check(dish.location == (DishBody.Location.REGISTERED if slot != null else DishBody.Location.BASIN), "A free pose must be recorded as a basin location, not an invented slot.")
	var occupants: int = 0
	for registered: KitchenSlot in registry.slots.values():
		if registered.state.occupant_id == dish.instance_id:
			occupants += 1
	check(occupants == (1 if slot != null else 0), "A dish can own exactly one registered slot, or a free world pose without slot occupancy.")
	if slot != null:
		check(slot.state.occupant_id == dish.instance_id, "Only the confirmed target slot may acquire the dish.")
	check(not targeting.excluded_bodies.has(dish.get_rid()), "The released dish must immediately rejoin real surface queries.")
	var dishes: Array[Node] = game.find_children("*", "StaticBody3D", true, false).filter(func(node: Node) -> bool: return node is DishBody)
	check(dishes.size() == 3, "Placement must preserve the original three dishes without copies or losses.")

func expect_rejected(dish: DishBody, before: Transform3D, item: HandItem, context: String) -> void:
	check(carry.selected_dish == dish and carry.get_selected_dish_item() == item and dish.global_transform.is_equal_approx(before) and dish.location == DishBody.Location.HELD, context + ": preserve the original held instance, pose, source and selection.")

func verify_free_round_trip() -> void:
	await prepare()
	var dish: DishBody = await take_initial("TrayPlate01")
	var identity: StringName = dish.instance_id
	var rid: RID = dish.get_rid()
	var source: HandItem = carry.get_selected_dish_item()
	check(source.origin_kind == DishBody.Location.REGISTERED and source.origin_slot_id == &"Dirty_Plate_01" and source.origin_pose.is_equal_approx(registry.slots[&"Dirty_Plate_01"].get_pose()), "Record the actual registered origin before carrying.")
	for at: Vector2 in [Vector2(-0.18, 0.04), Vector2(0.18, 0.04), Vector2(-0.22, 0.025)]:
		await look_at_basin(at)
		expect_preview(PlacementResult.Code.OK, "A real free preview before confirmation")
		check_free_geometry()
		var pose: Transform3D = preview.result.pose
		var held_pose: Transform3D = dish.global_transform
		tap(&"game_return")
		check(dish.global_transform.is_equal_approx(held_pose), "Q return remains step 14.")
		click()
		expect_world(dish, pose)
		check(carry.held_count() == 0 and carry.selected_dish == null and not preview.visible and not hint.visible, "Successful release clears the hand and preview immediately.")
		router.command_requested.emit(&"place_dish", true)
		expect_world(dish, pose)
		await ticks()
		await aim(dish)
		check(targeting.current_dish == dish, "The freely placed real dish must remain the first-hit pickup target.")
		click()
		var item: HandItem = carry.get_selected_dish_item()
		check(item != null and item.node == dish and item.origin_kind == DishBody.Location.BASIN and item.origin_slot_id.is_empty() and item.origin_pose.is_equal_approx(pose), "Repick must store this free pose and source kind, without using initial_slot_id.")
		check(dish.instance_id == identity and dish.get_rid() == rid and dish.initial_slot_id == &"Dirty_Plate_01" and registry.find_occupied_slot(identity) == null, "Repeated free moves preserve identity, collision and initialization data without stale occupancy.")

func verify_selected_hands() -> void:
	await prepare()
	var plate: DishBody = await take_initial("TrayPlate01")
	var mug: DishBody = await take_initial("TrayMug01")
	tap(&"game_tool_sponge")
	await look_at_basin(Vector2(-0.18, 0.04))
	var left: HandItem = carry.hands[0]
	var left_pose: Transform3D = plate.global_transform
	var pose: Transform3D = preview.result.pose
	click()
	expect_world(mug, pose)
	check(carry.hands[0] == left and carry.hands[1] == null and plate.get_parent() == carry.anchor and plate.global_transform.is_equal_approx(left_pose) and carry.selected_dish == plate, "Placing the selected right mug leaves the left dish and its hand unchanged.")
	router.command_requested.emit(&"place_dish", true)
	check(carry.hands[0] == left, "A repeated placement command must not release the remaining item onto the first dish.")
	await aim(mug)
	tap(&"game_interact")
	check(carry.hands[1] != null and carry.hands[1].node == mug and carry.hands[0] == left, "A repick fills the empty right hand without swapping the other item.")
	tap(&"game_tool_none")
	await look_at_basin(Vector2(0.18, 0.04))
	var right: HandItem = carry.hands[1]
	var right_pose: Transform3D = mug.global_transform
	pose = preview.result.pose
	click()
	expect_world(plate, pose)
	check(carry.hands[0] == null and carry.hands[1] == right and mug.global_transform.is_equal_approx(right_pose) and carry.selected_dish_hand == 1, "Placing the left dish keeps the right hand stable and selects its remaining dish.")

func verify_fresh_rack_decisions() -> void:
	await prepare()
	var dish: DishBody = await take_initial("TrayPlate01")
	var slot: KitchenSlot = registry.slots[&"Rack_Slot_01"]
	await look_at_slot(slot)
	var item: HandItem = carry.get_selected_dish_item()
	var held_pose: Transform3D = dish.global_transform
	click()
	expect_rejected(dish, held_pose, item, "Production unknown cleanliness")
	check(slot.is_empty(), "Missing cleanliness must never default to a successful rack placement.")
	var state: DishState = make_state(dish)
	state.stain_regions[&"known_stain"].foam_amount = 1.0
	carry.dish_states[dish.instance_id] = state
	await ticks()
	expect_preview(PlacementResult.Code.OK, "Known clean state before a late change", slot)
	slot.state.occupant_id = &"late_other"
	click()
	expect_rejected(dish, held_pose, item, "Late occupancy after a green preview")
	check(slot.state.occupant_id == &"late_other" and state.is_held and state.current_slot_id.is_empty(), "Rejection cannot overwrite occupancy or bound state.")
	slot.state.occupant_id = &""
	await ticks()
	state.stain_regions[&"known_stain"].remaining_amount = 51.0
	click()
	expect_rejected(dish, held_pose, item, "Actual 94.9 percent after a green preview")
	check(slot.is_empty(), "Rounded 95 percent cannot authorize the commit.")
	state.stain_regions[&"known_stain"].remaining_amount = 50.0
	await ticks()
	# The shape must enter physics before confirmation, while feedback stays old.
	preview.set_physics_process(false)
	targeting.set_physics_process(false)
	var obstacle: StaticBody3D = make_blocker(slot.get_pose() * Vector3(0.065, 0.005, 0), Vector3.ONE * 0.02)
	await ticks()
	check(preview.result.is_valid, "Keep an intentionally stale green preview for this regression.")
	click()
	expect_rejected(dish, held_pose, item, "Late off-ray obstruction")
	check(slot.is_empty(), "A new final-space obstruction cannot be bypassed by a cached green result.")
	obstacle.free()
	await ticks()
	var wall: StaticBody3D = make_blocker(camera.global_position.lerp(slot.get_pose().origin, 0.5), Vector3.ONE * 0.2)
	await ticks()
	held_pose = dish.global_transform
	click()
	expect_rejected(dish, held_pose, item, "Late first-hit occlusion")
	wall.free()
	preview.set_physics_process(true)
	targeting.set_physics_process(true)
	await ticks()
	var pose: Transform3D = preview.result.pose
	click()
	expect_world(dish, pose, slot)
	check(not state.is_held and state.current_slot_id == slot.config.slot_id and state.stain_regions[&"known_stain"].foam_amount == 1.0, "A successful commit updates location flags only, preserving cleanliness and foam.")
	await aim(dish)
	click()
	check(carry.selected_dish == dish and slot.is_empty() and state.is_held and state.current_slot_id.is_empty(), "Repicking from the rack releases its one occupancy and matching state.")
	check(carry.get_selected_dish_item().origin_slot_id == slot.config.slot_id and carry.get_selected_dish_item().origin_pose.is_equal_approx(pose), "Rack repick uses its real source, not the initial tray.")
	# All fixed poses must also work as real commits, including inverted mugs.
	for kind: StringName in [&"plate", &"mug"]:
		await prepare()
		dish = await take_initial("TrayPlate01" if kind == &"plate" else "TrayMug01")
		carry.dish_states[dish.instance_id] = make_state(dish)
		for target: KitchenSlot in registry.slots.values():
			if target.config.slot_kind != SlotConfig.Kind.DRAINING_RACK or not target.accepts(kind):
				continue
			await look_at_slot(target)
			click()
			expect_world(dish, target.get_pose(), target)
			await aim(dish)
			click()
			check(carry.selected_dish == dish and target.is_empty(), "Every rack pose permits same-instance repick and occupancy release.")

func verify_current_target_and_modes() -> void:
	await prepare()
	var plate: DishBody = await take_initial("TrayPlate01")
	var mug: DishBody = await take_initial("TrayMug01")
	carry.dish_states[plate.instance_id] = make_state(plate)
	var slot: KitchenSlot = registry.slots[&"Rack_Slot_01"]
	await look_at_slot(slot)
	expect_preview(PlacementResult.Code.OK, "Left plate green before changing hand", slot)
	tap(&"game_tool_sponge")
	var mug_pose: Transform3D = mug.global_transform
	var mug_item: HandItem = carry.get_selected_dish_item()
	click()
	expect_rejected(mug, mug_pose, mug_item, "The current selected mug is incompatible with the old plate preview")
	check(slot.is_empty() and carry.hands[0].node == plate, "A stale left-dish preview cannot release either hand incorrectly.")
	tap(&"game_tool_none")
	await look_at_basin(Vector2(-0.18, 0.04))
	var old_pose: Transform3D = preview.result.pose
	var latest_hit: Dictionary = basin_hit(Vector2(0.18, 0.04))
	camera.look_at(latest_hit.position)
	var latest: PlacementResult = carry.check_surface_placement(targeting.query_placement_surface())
	check(latest.is_valid and not latest.pose.is_equal_approx(old_pose), "The new visible free target must differ before the next feedback frame.")
	click()
	expect_world(plate, latest.pose)
	check(carry.hands[1].node == mug, "Commit uses the latest target without affecting the other hand.")
	await look_at_basin(Vector2(-0.18, 0.04))
	mug_pose = mug.global_transform
	mug_item = carry.get_selected_dish_item()
	preview.set_physics_process(false)
	targeting.set_physics_process(false)
	await stand(Vector3(-0.18, 0.03, 2.2))
	camera.look_at(Vector3(-0.18, 0.65, 0.04))
	mug_pose = mug.global_transform
	click()
	expect_rejected(mug, mug_pose, mug_item, "Moving out of range before confirmation")
	preview.set_physics_process(true)
	targeting.set_physics_process(true)
	await look_at_basin(Vector2(-0.18, 0.04))
	mug_pose = mug.global_transform
	router.set_interface_open(true)
	router.command_requested.emit(&"place_dish", true)
	expect_rejected(mug, mug_pose, mug_item, "UI blocks direct placement intentions")
	router.set_interface_open(false)
	router.set_context(GameInput.HandMode.TRANSITION, GameInput.Target.PLACEMENT_SURFACE)
	router.command_requested.emit(&"place_dish", true)
	expect_rejected(mug, mug_pose, mug_item, "Transition blocks placement")
	router.set_context(GameInput.HandMode.CLOSE_UP, GameInput.Target.PLACEMENT_SURFACE)
	router.command_requested.emit(&"place_dish", true)
	expect_rejected(mug, mug_pose, mug_item, "Immersion blocks world placement")

func verify_tool_pair() -> void:
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for tool_first: bool in [false, true]:
			await verify_tool_pair_case(kind, tool_first)

func verify_tool_pair_case(kind: ToolState.Tool, tool_first: bool) -> void:
	await prepare()
	var dish := game.get_node("PlayableDishes/TrayPlate01") as DishBody
	var tool := game.find_child("SpongeTool" if kind == ToolState.Tool.SPONGE else "SprayerTool", true, false) as CleaningTool
	if tool_first:
		await aim(tool)
		tap(&"game_interact")
	await aim(dish)
	tap(&"game_interact")
	if not tool_first:
		await aim(tool)
		tap(&"game_interact")
	var side: int = 0 if tool_first else 1
	var tool_item: HandItem = carry.hands[side]
	await look_at_basin(Vector2(-0.18, 0.04))
	var tool_pose: Transform3D = tool.global_transform
	var pose: Transform3D = preview.result.pose
	click()
	expect_world(dish, pose)
	check(carry.hands[side] == tool_item and carry.held_tool() == tool and tool.global_transform.is_equal_approx(tool_pose) and carry.held_count() == 1, "Placement keeps the tool in its original hand for either pickup order.")
	await aim(dish)
	button(MOUSE_BUTTON_LEFT, true)
	await ticks(4)
	check(carry.contact_active and carry.contact_dish == dish and carry.held_count() == 1, "A new left hold on the placed dish still operates either tool.")
	button(MOUSE_BUTTON_LEFT, false)
	tap(&"game_interact")
	check(carry.held_dish == dish and carry.get_selected_dish_item().origin_kind == DishBody.Location.BASIN, "With a tool and free hand, E repicks the freely placed dish.")
	await stand(Vector3(0, 0.03, 0.9))
	tap(&"game_toggle_close")
	await ticks(18)
	check(router.hand_mode == GameInput.HandMode.CLOSE_UP, "F immersion remains available after the placement/cleaning/repick loop.")
	tap(&"game_toggle_close")
	await ticks(18)
	check(router.hand_mode == GameInput.HandMode.CARRYING and carry.hands[side] == tool_item, "F restores the same tool hand after free repick.")

func verify() -> void:
	await verify_free_round_trip()
	await verify_selected_hands()
	await verify_fresh_rack_decisions()
	await verify_current_target_and_modes()
	await verify_tool_pair()
	game.free()
	if failures == 0:
		print("DISH_PLACEMENT_OK: fresh confirmation, free/rack poses, original identity and sources, stable hands, rejection atomicity, state/occupancy, tool use and F.")
		quit(0)
	else:
		push_error("DISH_PLACEMENT_FAILED: %d check(s) failed." % failures)
		quit(1)
