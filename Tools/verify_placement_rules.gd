extends "res://Tools/verify_dual_wield.gd"
## Import first, then: godot --headless --path . --script Tools/verify_placement_rules.gd
## Step 11 only: shared authorization and explicit hand selection, no actual placement.

func make_state(dish: DishBody, remaining: float = 50.0) -> DishState:
	var config := DishConfig.new()
	config.dish_type = dish.dish_type
	var region := StainRegionConfig.new()
	region.region_id = &"known_stain"
	region.initial_amount = 1000.0
	config.stain_regions.append(region)
	var state := DishState.new(dish.instance_id, config, &"")
	state.stain_regions[&"known_stain"].remaining_amount = remaining
	state.is_held = true
	return state

func slot_point(slot: KitchenSlot) -> Vector3:
	var surface := slot.marker.get_node_or_null("SelectionSurface") as Node3D
	return surface.global_position if surface != null else slot.get_pose().origin

func view_slot(slot: KitchenSlot) -> void:
	var point: Vector3 = slot_point(slot)
	camera.global_position = Vector3(point.x, 1.62, 0.63)
	camera.look_at(point)

func evaluate(item: HandItem, slot: KitchenSlot, state: DishState = null) -> PlacementResult:
	return PlacementRules.evaluate(item, slot, registry, camera, state)

func expect_code(result: PlacementResult, code: PlacementResult.Code, context: String) -> void:
	check(result.code == code, "%s: expected %s, got %s (%s)." % [context, code, result.code, result.get_reason()])
	check(result.is_valid == (code == PlacementResult.Code.OK) and not result.get_reason().is_empty(), "Every placement decision needs a consistent result and reason.")

func make_blocker(position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = MeshSurfaceCollision.ENVIRONMENT_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	game.add_child(body)
	body.global_position = position
	return body

func verify() -> void:
	await load_game()
	player.set_physics_process(false)
	carry.set_physics_process(false)
	targeting.set_physics_process(false)
	for child in game.get_node("PlayableDishes").get_children():
		child.free()
	for slot: KitchenSlot in registry.slots.values():
		slot.state.occupant_id = &""
	var dishes: Dictionary[StringName, DishBody] = {}
	var items: Dictionary[StringName, HandItem] = {}
	for kind: StringName in [&"plate", &"mug"]:
		var dish := (load("res://Scenes/Dishes/%s.tscn" % kind) as PackedScene).instantiate() as DishBody
		dish.instance_id = StringName("placement_" + str(kind))
		game.add_child(dish)
		dish.global_position = Vector3(-2, 3, 1)
		dishes[kind] = dish
		items[kind] = HandItem.new(dish)
	await ticks()
	# Every calibrated complete pose must accept its formal, clean dish.
	for slot: KitchenSlot in registry.slots.values():
		var kind: StringName = slot.config.accepted_dish_types[0]
		var state: DishState = make_state(dishes[kind])
		view_slot(slot)
		var original_pose: Transform3D = dishes[kind].global_transform
		var original_parent: Node = dishes[kind].get_parent()
		var result: PlacementResult = evaluate(items[kind], slot, state)
		expect_code(result, PlacementResult.Code.OK, "Formal pose " + str(slot.config.slot_id))
		check(result.pose.is_equal_approx(slot.get_pose()) and result.dish_id == state.instance_id and result.slot_id == slot.config.slot_id, "Use the complete marker pose and matching identities, without a half-height offset.")
		check(slot.is_empty() and state.current_slot_id.is_empty() and state.is_held and dishes[kind].global_transform.is_equal_approx(original_pose) and dishes[kind].get_parent() == original_parent, "A placement check must not reserve occupancy, place a node or change its runtime state.")
	var rack: KitchenSlot = registry.slots[&"Rack_Slot_01"]
	var temp: KitchenSlot = registry.slots[&"Sink_Plate_01"]
	var tray: KitchenSlot = registry.slots[&"Dirty_Plate_01"]
	var plate: DishBody = dishes[&"plate"]
	var item: HandItem = items[&"plate"]
	var state: DishState = make_state(plate)
	view_slot(rack)
	for pair in [[51.0, PlacementResult.Code.DIRTY], [50.0, PlacementResult.Code.OK], [49.0, PlacementResult.Code.OK], [50.000001, PlacementResult.Code.DIRTY]]:
		state.stain_regions[&"known_stain"].remaining_amount = pair[0]
		expect_code(evaluate(item, rack, state), pair[1], "Actual 95 percent gate with remaining=" + str(pair[0]))
	state.stain_regions[&"known_stain"].remaining_amount = 51.0
	check(state.get_cleanliness_percent() == 95 and not evaluate(item, rack, state).is_valid, "Rounded 95 percent must never authorize rack placement.")
	state.stain_regions[&"known_stain"].remaining_amount = 50.0
	state.stain_regions[&"known_stain"].foam_amount = 1.0
	expect_code(evaluate(item, rack, state), PlacementResult.Code.OK, "A clean-enough dish with foam still enters the rack")
	expect_code(evaluate(item, rack), PlacementResult.Code.MISSING_STATE, "Unknown runtime cleanliness must not authorize rack placement")
	var wrong_state: DishState = make_state(dishes[&"mug"])
	expect_code(evaluate(item, rack, wrong_state), PlacementResult.Code.STATE_MISMATCH, "State must belong to this dish instance")
	for slot in [temp, tray]:
		view_slot(slot)
		state.stain_regions[&"known_stain"].remaining_amount = 1000.0
		expect_code(evaluate(item, slot, state), PlacementResult.Code.OK, "Dirty dish can use temporary/tray slots")
		expect_code(evaluate(item, slot), PlacementResult.Code.OK, "Only the rack needs known cleanliness")
	view_slot(temp)
	expect_code(evaluate(null, temp), PlacementResult.Code.NO_DISH, "No selected dish")
	expect_code(evaluate(item, null), PlacementResult.Code.INVALID_SLOT, "No slot")
	var impostor := KitchenSlot.new(temp.config, temp.marker)
	expect_code(evaluate(item, impostor), PlacementResult.Code.INVALID_SLOT, "A duplicate ID does not make an unregistered slot authoritative")
	expect_code(evaluate(items[&"mug"], temp), PlacementResult.Code.INCOMPATIBLE, "Mug cannot use a plate slot")
	temp.state.occupant_id = &"other_dish"
	expect_code(evaluate(item, temp), PlacementResult.Code.OCCUPIED, "Occupied target")
	temp.state.occupant_id = plate.instance_id
	expect_code(evaluate(item, temp), PlacementResult.Code.OCCUPIED, "Own stale occupancy cannot authorize placement")
	temp.state.occupant_id = &""
	tray.state.occupant_id = plate.instance_id
	expect_code(evaluate(item, temp), PlacementResult.Code.SOURCE_OCCUPIED, "Source occupancy must already be released")
	tray.state.occupant_id = &""
	var model := plate.get_node("Model") as Node3D
	var scale_before: Vector3 = model.scale
	model.scale *= 1.2
	expect_code(evaluate(HandItem.new(plate), temp), PlacementResult.Code.TOO_LARGE, "Correct type but physically enlarged geometry")
	model.scale = scale_before
	var point: Vector3 = slot_point(temp)
	camera.global_position = point + Vector3(0, 0, 1.5)
	camera.look_at(point)
	check(evaluate(item, temp).code != PlacementResult.Code.OUT_OF_RANGE, "Exactly 1.5 m is within range.")
	camera.global_position.z += 0.001
	expect_code(evaluate(item, temp), PlacementResult.Code.OUT_OF_RANGE, "Beyond 1.5 m")
	view_slot(temp)
	camera.look_at(camera.global_position + (camera.global_position - point))
	expect_code(evaluate(item, temp), PlacementResult.Code.NOT_VISIBLE, "A slot behind the camera cannot be used")
	view_slot(temp)
	var wall: StaticBody3D = make_blocker(camera.global_position.lerp(point, 0.5), Vector3.ONE * 0.2)
	await ticks()
	expect_code(evaluate(item, temp), PlacementResult.Code.NOT_VISIBLE, "A real foreground obstruction blocks the slot")
	wall.free()
	await ticks()
	# This obstacle is off the selection ray but intersects the candidate plate.
	var obstruction: StaticBody3D = make_blocker(temp.get_pose().origin + Vector3(0.065, 0.005, 0), Vector3.ONE * 0.02)
	await ticks()
	expect_code(evaluate(item, temp), PlacementResult.Code.NO_SPACE, "Visible and empty slot with obstructed final geometry")
	obstruction.free()
	await ticks()
	expect_code(evaluate(item, temp), PlacementResult.Code.OK, "Removing obstruction restores placement eligibility")
	# A tiny obstacle in a triangle's interior must not slip between edge rays.
	var faces: PackedVector3Array = item.get_placement_faces()
	var interior: Vector3
	for index in range(0, faces.size(), 3):
		var a: Vector3 = faces[index]
		var b: Vector3 = faces[index + 1]
		var c: Vector3 = faces[index + 2]
		var center: Vector3 = (a + b + c) / 3.0
		if (b - a).cross(c - a).normalized().y > 0.99 and center.x > 0.04 and absf(center.z) < 0.03:
			interior = center
			break
	check(interior != Vector3.ZERO, "The real plate needs a suitable triangle-interior probe.")
	obstruction = make_blocker(temp.get_pose() * interior, Vector3.ONE * 0.0002)
	await ticks()
	expect_code(evaluate(item, temp), PlacementResult.Code.NO_SPACE, "A blocker wholly between triangle edges still intersects the dish surface")
	obstruction.free()
	var cup_slot: KitchenSlot = registry.slots[&"Sink_Mug_01"]
	view_slot(cup_slot)
	obstruction = make_blocker(cup_slot.get_pose() * Vector3(0.06, 0.0015, 0), Vector3.ONE * 0.006)
	await ticks()
	expect_code(evaluate(items[&"mug"], cup_slot), PlacementResult.Code.OK, "An obstacle entirely in the open handle hole must not be treated as intersecting ceramic")
	obstruction.free()
	await ticks()
	view_slot(temp)
	# Changes after a successful query must be caught by the same fresh entry point.
	var old_result: PlacementResult = evaluate(item, temp)
	temp.state.occupant_id = &"late_occupant"
	expect_code(evaluate(item, temp), PlacementResult.Code.OCCUPIED, "Recheck after target occupancy changed")
	check(old_result.pose.is_equal_approx(temp.get_pose()) and temp.state.occupant_id == &"late_occupant", "Checks neither mutate previous results nor overwrite occupancy.")
	temp.state.occupant_id = &""
	# Real pickup and physical 1/2 events select stable hands without placing.
	await load_game()
	var first := game.get_node("PlayableDishes/TrayPlate01") as DishBody
	var second := game.get_node("PlayableDishes/TrayMug01") as DishBody
	await aim(first)
	click()
	check(carry.selected_dish == first and carry.selected_dish_hand == 0, "A lone dish is selected automatically.")
	tap(&"game_tool_sponge")
	check(carry.selected_dish == first and (game.get_node("GameHUD/HandHint") as Label).text == "该手没有餐具", "Selecting an empty hand must keep the original dish selected and explain why.")
	await aim(second)
	click()
	check(carry.selected_dish == first, "Adding a second dish must preserve the explicit current hand.")
	tap(&"game_tool_sponge")
	check(carry.selected_dish == second and carry.selected_dish_hand == 1 and carry.get_selected_dish_item().origin_slot_id == &"Dirty_Mug_01", "Key 2 selects the right dish and its own pickup source.")
	expect_code(carry.check_placement(registry.slots[&"Sink_Plate_01"]), PlacementResult.Code.INCOMPATIBLE, "The shared entry must use the selected right mug rather than the first-dish compatibility getter")
	var hud_label := game.get_node("GameHUD/HandStatus") as Label
	check(hud_label.text.contains(second.display_name + "（当前）"), "HUD must identify the selected dish.")
	tap(&"game_tool_none")
	check(carry.selected_dish == first and carry.hands[1].node == second, "Key 1 selects left without moving the right item.")
	var held_poses: Array[Transform3D] = [first.global_transform, second.global_transform]
	tap(&"game_return")
	click()
	check(first.global_transform.is_equal_approx(held_poses[0]) and second.global_transform.is_equal_approx(held_poses[1]) and carry.held_count() == 2, "Step 11 does not implement Q return or confirmed placement.")
	router.set_interface_open(true)
	expect_code(carry.check_placement(registry.slots[&"Sink_Plate_01"]), PlacementResult.Code.INPUT_BLOCKED, "UI blocks the shared placement entry")
	tap(&"game_tool_sponge")
	check(carry.selected_dish == first, "UI must consume hand selection input.")
	router.set_interface_open(false)
	game.free()
	if failures == 0:
		print("PLACEMENT_RULES_OK: complete poses, shared read-only decisions, actual 95 percent gate, space/visibility and explicit hand selection.")
		quit(0)
	else:
		push_error("PLACEMENT_RULES_FAILED: %d check(s) failed." % failures)
		quit(1)
