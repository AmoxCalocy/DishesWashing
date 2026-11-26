extends "res://Tools/verify_dish_placement.gd"
## Import first, then: godot --headless --path . --script Tools/verify_basin_stacking.gd
## Real overlapping placements, ceramic support, top-first pickup and fresh checks.

func check_stack_geometry(dish: DishBody) -> void:
	var item := HandItem.new(dish)
	var pose: Transform3D = dish.global_transform
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var ignored: Array[RID] = [dish.get_rid()]
	var faces: PackedVector3Array = item.get_placement_faces()
	var clear: bool = true
	var gap: float = INF
	for index in range(0, faces.size(), 3):
		for edge in 3:
			var a: Vector3 = pose * faces[index + edge]
			var b: Vector3 = pose * faces[index + (edge + 1) % 3]
			var ray := PhysicsRayQueryParameters3D.create(a, b, MeshSurfaceCollision.QUERY_MASK, ignored)
			if not space.intersect_ray(ray).is_empty():
				clear = false
			if edge == 0:
				ray.from = a + Vector3.UP * 0.0001
				ray.to = a - Vector3.UP * 0.003
				var hit: Dictionary = space.intersect_ray(ray)
				if registry.is_basin_support(hit):
					gap = minf(gap, a.y - (hit.position as Vector3).y)
	check(clear, "Stacked real mesh edges must not intersect ceramic, basin walls or unrelated objects.")
	check(gap >= 0.0002 and gap <= 0.002, "A stacked dish must contact real support with a small clearance, rather than float at a guessed height.")

func aim_exposed(dish: DishBody) -> bool:
	await stand(Vector3(-0.5, 0.03, 0.65))
	var item := HandItem.new(dish)
	var faces: PackedVector3Array = item.get_placement_faces()
	for index in range(0, faces.size(), 3):
		var point: Vector3 = dish.global_transform * ((faces[index] + faces[index + 1] + faces[index + 2]) / 3.0)
		var end: Vector3 = camera.global_position + camera.global_position.direction_to(point) * targeting.interaction_distance
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position, end, MeshSurfaceCollision.QUERY_MASK, targeting.excluded_bodies)
		var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.get("collider") == dish:
			camera.look_at(point)
			await ticks()
			return targeting.current_dish == dish
	return false

func verify_stack_round_trip() -> void:
	await prepare()
	var base: DishBody = await take_initial("TrayPlate01")
	await look_at_basin(Vector2(-0.2, 0.04))
	var base_pose: Transform3D = preview.result.pose
	click()
	var top: DishBody = await take_initial("TrayPlate02")
	# Do one timed query without a running preview, then restore live feedback.
	preview.set_physics_process(false)
	await look_at_basin(Vector2(-0.18, 0.04))
	var start: int = Time.get_ticks_usec()
	var decision: PlacementResult = carry.check_surface_placement(targeting.query_placement_surface())
	print("STACK_QUERY_MS ", (Time.get_ticks_usec() - start) / 1000.0)
	start = Time.get_ticks_usec()
	decision = carry.check_surface_placement(targeting.query_placement_surface())
	print("STACK_QUERY_WARM_MS ", (Time.get_ticks_usec() - start) / 1000.0)
	expect_code(decision, PlacementResult.Code.OK, "An overlapping plate must settle on the first basin plate")
	check(decision.pose.origin.y > base_pose.origin.y + 0.005 and decision.support_dish_ids.has(base.instance_id), "Use the real lower plate as support, retaining its separate identity.")
	preview.set_physics_process(true)
	await ticks()
	expect_preview(PlacementResult.Code.OK, "Live overlapping plate preview")
	check(targeting.current_dish == base and router.target == GameInput.Target.STACKABLE_DISH, "The visible first-hit basin dish is the explicit stacking target, not a hidden basin ray.")
	var top_pose: Transform3D = preview.result.pose
	click()
	expect_world(top, top_pose)
	check(base.global_transform.is_equal_approx(base_pose) and carry.held_count() == 0 and top.support_dish_ids.has(base.instance_id), "Left click stacks the carried dish without picking up or moving its support.")
	await ticks()
	check_stack_geometry(top)
	var mug: DishBody = await take_initial("TrayMug01")
	await look_at_basin(Vector2(-0.17, 0.04))
	expect_preview(PlacementResult.Code.OK, "A mug can overlap and rest on the upper plate")
	var mug_pose: Transform3D = preview.result.pose
	click()
	expect_world(mug, mug_pose)
	await ticks()
	check_stack_geometry(mug)
	check(mug.support_dish_ids.has(top.instance_id), "A multi-level stack records the actual ceramic support.")
	for slot: KitchenSlot in registry.slots.values():
		check(slot.is_empty(), "A basin stack must not acquire tray or rack slot occupancy.")
	check(await aim_exposed(base), "The partial overlap must leave an exposed lower surface for a real pickup attempt.")
	tap(&"game_interact")
	check(carry.held_count() == 0 and base.global_transform.is_equal_approx(base_pose) and top.global_transform.is_equal_approx(top_pose) and mug.global_transform.is_equal_approx(mug_pose), "Picking a supporting lower dish must not leave the upper dishes suspended.")
	check((game.get_node("GameHUD/HandHint") as Label).text == "请先拿走上面的餐具", "Blocked lower pickup must explain the top-first rule.")
	await aim(mug)
	click()
	check(carry.selected_dish == mug and carry.get_selected_dish_item().origin_pose.is_equal_approx(mug_pose) and mug.support_dish_ids.is_empty(), "Top pickup retains its real free source and removes its old support dependency.")
	await aim(top)
	tap(&"game_interact")
	check(carry.hands[1] != null and carry.hands[1].node == top and carry.hands[1].origin_pose.is_equal_approx(top_pose), "E picks the now-uncovered plate while another dish is carried.")
	tap(&"game_tool_none")
	await look_at_basin(Vector2(0.25, 0.08))
	click()
	await look_at_basin(Vector2(0.1, -0.025))
	click()
	check(carry.held_count() == 0, "Upper dishes can be moved elsewhere without changing identities.")
	await aim(base)
	click()
	check(carry.selected_dish == base and carry.get_selected_dish_item().origin_pose.is_equal_approx(base_pose), "The lower dish becomes pickable after its dependants are removed.")

func verify_changed_support() -> void:
	await prepare()
	var base: DishBody = await take_initial("TrayPlate01")
	await look_at_basin(Vector2(-0.18, 0.04))
	click()
	var top: DishBody = await take_initial("TrayPlate02")
	await look_at_basin(Vector2(-0.18, 0.04))
	expect_preview(PlacementResult.Code.OK, "Green stack before the support changes")
	var old_pose: Transform3D = preview.result.pose
	preview.set_physics_process(false)
	targeting.set_physics_process(false)
	base.global_position.x = 0.18
	await ticks()
	var latest: PlacementResult = carry.check_surface_placement(targeting.query_placement_surface())
	check(latest.is_valid and latest.pose.origin.y < old_pose.origin.y - 0.005, "A fresh query must see the changed support height.")
	click()
	expect_world(top, latest.pose)
	check(top.support_dish_ids.is_empty(), "Confirmation must not retain a dependency on a moved-away support.")
	preview.set_physics_process(true)
	targeting.set_physics_process(true)
	await ticks()
	check_stack_geometry(top)

func verify_tool_priority() -> void:
	await prepare()
	await take_initial("TrayPlate01")
	await look_at_basin(Vector2(-0.2, 0.04))
	click()
	var top: DishBody = await take_initial("TrayPlate02")
	await look_at_basin(Vector2(-0.18, 0.04))
	click()
	await take_initial("TrayMug01")
	var tool := game.find_child("SpongeTool", true, false) as CleaningTool
	await aim(tool)
	tap(&"game_interact")
	await stand(Vector3(-0.18, 0.03, 0.65))
	await aim(top)
	check(router.target == GameInput.Target.DISH and not preview.visible, "Holding a tool keeps use priority on a stacked dish, without a misleading placement preview.")
	button(MOUSE_BUTTON_LEFT, true)
	await ticks(4)
	check(carry.contact_active and carry.contact_dish == top and carry.held_count() == 2, "Ordinary tool contact must still reach the upper dish while the other hand carries a mug.")
	button(MOUSE_BUTTON_LEFT, false)

func verify() -> void:
	await verify_stack_round_trip()
	await verify_changed_support()
	await verify_tool_priority()
	game.free()
	if failures == 0:
		print("BASIN_STACKING_OK: real overlapping plates/mug, support and no intersections, explicit click/E routing, top-first pickup, identities and fresh confirmation.")
		quit(0)
	else:
		push_error("BASIN_STACKING_FAILED: %d check(s) failed." % failures)
		quit(1)
