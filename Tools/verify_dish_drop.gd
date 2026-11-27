extends "res://Tools/verify_placement_rules.gd"
## godot --headless --path . --script Tools/verify_dish_drop.gd
## G releases the original dish into gravity; no return or visual preview.

func take_initial(name: String) -> DishBody:
	var dish := game.get_node("PlayableDishes/" + name) as DishBody
	await stand(Vector3(0, 0.03, 0.8))
	await aim(dish)
	tap(&"game_interact")
	check(carry.selected_dish == dish, "Prepare an actual world pickup.")
	return dish

func view_point(point: Vector3, at: Vector3) -> void:
	await stand(at)
	camera.look_at(point)
	await ticks(5)

func expect_no_preview() -> void:
	check(game.get_node_or_null("PlacementPreview") == null and game.get_node_or_null("GameHUD/Crosshair/PlacementHint") == null, "Gameplay must contain neither a ghost preview nor its green/red label.")

func verify_free_drop() -> void:
	for name: String in ["TrayPlate01", "TrayMug01"]:
		for area: String in ["basin", "tray", "counter", "floor"]:
			await load_game()
			var dish: DishBody = await take_initial(name)
			var rid: RID = dish.get_rid()
			var item: HandItem = carry.get_selected_dish_item()
			var state: DishState = make_state(dish, 800.0)
			carry.dish_states[dish.instance_id] = state
			match area:
				"basin": await view_point(Vector3(-0.18, 0.65, 0.04), Vector3(-0.18, 0.03, 0.65))
				"tray": await view_point(item.origin_pose.origin, Vector3(-0.9, 0.03, 0.8))
				"counter": await view_point(Vector3(-0.7, 0.9, 0.43), Vector3(-0.7, 0.03, 0.95))
				"floor": await view_point(Vector3(0, 0, 1.3), Vector3(0, 0.03, 2.0))
			expect_no_preview()
			var held: Transform3D = dish.global_transform
			tap(&"game_return")
			check(carry.get_selected_dish_item() == item and dish.global_transform.is_equal_approx(held), "Ordinary Q must not return or place the dish.")
			tap(&"game_drop")
			check(carry.held_count() == 0 and dish.location == DishBody.Location.WORLD and not dish.motion_body.freeze and dish.get_parent() == game.get_node("PlayableDishes"), "G releases the original dish for real physics in " + area)
			check(not state.is_held and state.current_slot_id.is_empty() and state.stain_regions[&"known_stain"].remaining_amount == 800.0, "A free drop clears held/location flags without changing dirt.")
			var release: Transform3D = dish.global_transform
			await ticks(8)
			check(dish.global_position.y < release.origin.y - 0.01, "Gravity must move the released dish down, rather than snap it to a solved final pose.")
			await ticks(220)
			print("DROP_POSE ", name, " ", area, " ", dish.global_position, " speed=", dish.motion_body.linear_velocity.length())
			check(dish.global_position.y > -0.05 and dish.global_position.distance_to(release.origin) < 1.6, "The physical dish must land on real kitchen/floor collision instead of falling through.")
			if area == "basin":
				check(dish.global_position.y > 0.58 and absf(dish.global_position.x) < 0.52 and absf(dish.global_position.z) < 0.3, "A basin drop must remain in the real basin.")
			if area == "tray":
				check(dish.global_position.y > 0.88, "A tray drop must be supported by the actual tray/counter geometry.")
			if area == "floor":
				check(dish.global_position.y < 0.2, "A floor drop must actually reach the floor.")
			await aim(dish)
			tap(&"game_interact")
			check(carry.selected_dish == dish and dish.get_rid() == rid and dish.motion_body.freeze and dish.motion_body.collision_layer == 0, "Any landed dish can be repicked with its original identity and frozen physical body.")
			check(registry.find_occupied_slot(dish.instance_id) == null and carry.get_selected_dish_item() != null, "Free drops and repicks must not invent fixed slot occupancy.")

func verify_hands_and_blocking() -> void:
	await load_game()
	var left: DishBody = await take_initial("TrayPlate01")
	var right := game.get_node("PlayableDishes/TrayMug01") as DishBody
	await aim(right)
	tap(&"game_interact")
	tap(&"game_tool_sponge")
	await view_point(Vector3(-0.18, 0.65, 0.04), Vector3(-0.18, 0.03, 0.65))
	var retained: HandItem = carry.hands[0]
	var left_pose: Transform3D = left.global_transform
	for mode in [GameInput.HandMode.TRANSITION, GameInput.HandMode.CLOSE_UP]:
		router.set_context(mode, GameInput.Target.NONE)
		router.command_requested.emit(&"drop_dish", true)
		check(carry.held_count() == 2 and right.location == DishBody.Location.HELD, "World drop is blocked during immersion/transition.")
	router.set_context(GameInput.HandMode.CARRYING, GameInput.Target.NONE)
	router.set_interface_open(true)
	router.command_requested.emit(&"drop_dish", true)
	check(carry.held_count() == 2, "GUI blocks even a directly emitted drop intention.")
	router.set_interface_open(false)
	tap(&"game_drop")
	check(carry.hands[0] == retained and carry.hands[1] == null and left.global_transform.is_equal_approx(left_pose) and right.location == DishBody.Location.WORLD, "G drops selected right-hand dish while retaining the left hand.")
	router.command_requested.emit(&"drop_dish", true)
	check(carry.hands[0] == retained, "Repeated drop in the same physics tick cannot release the other dish.")

func verify_physical_openings() -> void:
	await load_game()
	var mug := game.get_node("PlayableDishes/TrayMug01") as DishBody
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(mug.to_global(Vector3(0, 0.2, 0)), mug.to_global(Vector3(0, -0.1, 0)), DishBody.PHYSICS_LAYER)
	var hit: Dictionary = space.intersect_ray(ray)
	check(hit.get("collider") == mug.motion_body and mug.to_local(hit.get("position", Vector3.INF)).y < -0.025, "Physical convex pieces must preserve the open cup instead of capping it with one hull.")
	ray.from = mug.to_global(Vector3(0.06, 0, 0.1))
	ray.to = mug.to_global(Vector3(0.06, 0, -0.1))
	check(space.intersect_ray(ray).is_empty(), "The physical handle aperture must remain open too.")

func verify_tool_and_immersion() -> void:
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for tool_first: bool in [false, true]:
			await load_game()
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
			var retained: HandItem = carry.hands[side]
			await view_point(Vector3(-0.18, 0.65, 0.04), Vector3(-0.18, 0.03, 0.65))
			tap(&"game_drop")
			check(carry.hands[side] == retained and carry.held_count() == 1 and carry.held_tool() == tool and dish.location == DishBody.Location.WORLD, "G drops only the selected dish and retains either physical tool in the same hand.")
			await ticks(150)
			await aim(dish)
			button(MOUSE_BUTTON_LEFT, true)
			await ticks(5)
			check(carry.contact_active and carry.contact_dish == dish, "Ordinary tools must still contact a dish after its real physical landing.")
			button(MOUSE_BUTTON_LEFT, false)
			tap(&"game_interact")
			check(carry.selected_dish == dish and dish.motion_body.freeze, "E repicks the original simulated dish beside a held tool.")
			await stand(Vector3(0, 0.03, 0.9))
			tap(&"game_toggle_close")
			await ticks(18)
			check(router.hand_mode == GameInput.HandMode.CLOSE_UP, "F still enters immersion after a drop/repick.")
			tap(&"game_drop")
			var rotation: Basis = dish.global_basis
			action(&"game_return", true)
			await ticks(6)
			action(&"game_return", false)
			check(carry.held_count() == 2 and router.hand_mode == GameInput.HandMode.CLOSE_UP and not dish.global_basis.is_equal_approx(rotation), "Immersive G is ignored and Q continues to rotate rather than return.")

func verify() -> void:
	await verify_free_drop()
	await verify_hands_and_blocking()
	await verify_physical_openings()
	await verify_tool_and_immersion()
	game.free()
	if failures == 0:
		print("DISH_DROP_OK: G release, gravity, basin/counter/floor, real collisions, original identity/repick, selected hands, no Q return or preview, blocked contexts and flags.")
		quit(0)
	else:
		push_error("DISH_DROP_FAILED: %d check(s) failed." % failures)
		quit(1)
