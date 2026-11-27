extends "res://Tools/verify_close_transition.gd"
## Import first, then: godot --headless --path . --script Tools/verify_dish_manipulation.gd
## Step 16: selected-hand rotation, type-specific close distances and geometry.

func drag(code: MouseButton, relative: Vector2) -> void:
	button(code, true)
	motion(camera.get_viewport().get_visible_rect().size * 0.5, relative)
	button(code, false)

func wheel(closer: bool, count: int = 1) -> void:
	for index in count:
		# Real wheel pulses deliberately have no release event.
		button(MOUSE_BUTTON_WHEEL_UP if closer else MOUSE_BUTTON_WHEEL_DOWN, true)

func check_near(node: Node3D) -> void:
	var nearest: float = INF
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		for vertex in mesh.mesh.get_faces():
			nearest = minf(nearest, -camera.to_local(mesh.to_global(vertex)).z)
	check(nearest > camera.near + 0.005, "Every actual dish/tool vertex must remain clear of the near plane.")
	check(absf(node.global_basis.determinant() - 1.0) < 0.0001, "Repeated rotations must preserve an orthonormal, unscaled basis.")

func held_surface() -> Dictionary:
	var start: Vector3 = camera.to_global(Vector3(0.009, -0.012, 0))
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * 1.0, MeshSurfaceCollision.DISH_LAYER)
	query.hit_back_faces = false
	return camera.get_world_3d().direct_space_state.intersect_ray(query)

func nearest_surface_cursor(dish: DishBody) -> Vector2:
	var point: Vector3 = dish.global_position
	var nearest: float = INF
	for child in dish.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var faces: PackedVector3Array = mesh.mesh.get_faces()
		for index in range(0, faces.size(), 3):
			var center: Vector3 = mesh.to_global((faces[index] + faces[index + 1] + faces[index + 2]) / 3.0)
			var depth: float = -camera.to_local(center).z
			if depth < nearest:
				nearest = depth
				point = center
	return camera.unproject_position(point)

func verify_ordinary() -> void:
	await load_game()
	var plate := game.get_node("PlayableDishes/TrayPlate01") as DishBody
	var mug := game.get_node("PlayableDishes/TrayMug01") as DishBody
	for dish in [plate, mug]:
		await aim(dish)
		tap(&"game_interact")
		await ticks()
	await pose_at(Vector3(0, 0.03, 1.4), 180, 0)
	check(carry.held_count() == 2, "Ordinary rotation fixtures must hold two original dishes.")
	var view: Transform3D = camera.global_transform
	var fov: float = camera.fov
	for side in [0, 1]:
		tap(&"game_tool_none" if side == 0 else &"game_tool_sponge")
		var selected: DishBody = carry.hands[side].node as DishBody
		var other: DishBody = carry.hands[1 - side].node as DishBody
		var before: Basis = selected.global_basis
		var other_pose: Transform3D = other.global_transform
		drag(MOUSE_BUTTON_MIDDLE, Vector2(32, -23))
		await ticks()
		check(not selected.global_basis.is_equal_approx(before) and other.global_transform.is_equal_approx(other_pose), "Ordinary middle drag must rotate only the 1/2 selected original dish.")
		check(camera.global_transform.is_equal_approx(view) and camera.fov == fov, "Dish rotation must not turn or zoom the camera.")
		var pose: Transform3D = selected.global_transform
		wheel(true, 10)
		wheel(false, 10)
		tap(&"game_return")
		await ticks()
		check(selected.global_transform.is_equal_approx(pose), "Ordinary wheel and Q must not change dish distance, rotation or source.")
		check_near(selected)
		check(registry.find_occupied_slot(selected.instance_id) == null and selected.location == DishBody.Location.HELD, "Rotation must not restore occupancy or release the held physics body.")
		before = selected.basis
		drag(MOUSE_BUTTON_RIGHT, Vector2(20, 10))
		check(selected.basis.is_equal_approx(before) and camera.fov == fov, "Ordinary right mouse must not rotate a held dish or zoom the view.")
		await pose_at(Vector3(0, 0.03, 1.4), 180, 0)
		# Switching the selection interrupts the old middle hold.
		button(MOUSE_BUTTON_MIDDLE, true)
		tap(&"game_tool_sponge" if side == 0 else &"game_tool_none")
		before = other.basis
		motion(Vector2(640, 360), Vector2(50, 30))
		check(other.basis.is_equal_approx(before), "A selection change must require a fresh middle press before rotating the other hand.")
		button(MOUSE_BUTTON_MIDDLE, false)
		# Restore camera after ordinary look resumes on the interrupted drag.
		await pose_at(Vector3(0, 0.03, 1.4), 180, 0)
		view = camera.global_transform
	# Menu and focus cancel ordinary rotation and do not resume old holds.
	for focus_loss in [false, true]:
		button(MOUSE_BUTTON_MIDDLE, true)
		if focus_loss:
			router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		else:
			tap(&"game_menu")
		var before: Basis = carry.selected_dish.global_basis
		motion(Vector2.ZERO, Vector2(40, 40))
		check(carry.selected_dish.global_basis.is_equal_approx(before), "Blocked GUI/focus motion must not rotate a dish.")
		router.set_interface_open(false)
		motion(Vector2.ZERO, Vector2(3, 0))
		check(carry.selected_dish.global_basis.is_equal_approx(before), "Resume must not restore an old middle drag.")
		button(MOUSE_BUTTON_MIDDLE, false)
	# A nearby obstacle must stop rotation before the plate sweeps into it.
	await pose_at(Vector3(0, 0.03, 1.4), 180, 0)
	tap(&"game_tool_none")
	var item: HandItem = carry.get_selected_dish_item()
	item.rotation = Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
	await ticks()
	carry.set_physics_process(false)
	var obstruction: StaticBody3D = blocker(Vector3(-0.28, -0.22, -0.67), Vector3(0.04, 0.2, 0.015))
	await ticks()
	drag(MOUSE_BUTTON_MIDDLE, Vector2(150, 0))
	await ticks()
	check(PlacementRules._has_space(item, item.node.global_transform, camera, targeting.excluded_bodies), "Ordinary rotation must stop before actual obstacle penetration.")
	check_near(item.node)
	obstruction.free()
	carry.set_physics_process(true)
	await ticks()

func verify_close_controls() -> void:
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for dish_name in ["TrayPlate01", "TrayMug01"]:
			for tool_first in [false, true]:
				if not await pair(dish_name, kind, tool_first):
					return
				await pose_at(Vector3(0, 0.03, 1.0), 180, 0)
				var dish: DishBody = carry.held_dish
				var tool: CleaningTool = carry.held_tool()
				var item: HandItem = carry.get_selected_dish_item()
				var identity: int = dish.get_instance_id()
				var rid: RID = dish.get_rid()
				var player_pose: Transform3D = player.global_transform
				var view: Transform3D = camera.global_transform
				var fov: float = camera.fov
				tap(&"game_toggle_close")
				wheel(true)
				await wait_transition()
				check(is_equal_approx(item.close_distance, 0.45), "Wheel must be ignored during F transition.")
				for closer in [true, false, true]:
					wheel(closer, 30)
					await ticks()
					var limit: float = dish.close_min_distance if closer else dish.close_max_distance
					check(is_equal_approx(item.close_distance, limit) and is_equal_approx(-camera.to_local(dish.global_position).z, limit), "Real wheel pulses must clamp the actual dish position at its configured type limits.")
					check_view(player_pose, view, fov)
					# All orientations remain available where space allows, including the back.
					for turn in [Vector2(PI / 0.01, 0), Vector2(0, PI / 0.01), Vector2(-PI / 0.01, 0), Vector2(0, -PI / 0.01)]:
						drag(MOUSE_BUTTON_MIDDLE, turn)
						await ticks()
						check_near(dish)
						check_near(tool)
						check(is_equal_approx(-camera.to_local(dish.global_position).z, limit), "Rotation must retain the chosen close distance.")
						check(PlacementRules._has_space(item, dish.global_transform, camera, targeting.excluded_bodies), "Allowed close rotations must remain clear of the kitchen.")
					if closer:
						for angle in [Vector2(45, 30), Vector2(90, 45), Vector2(135, -45), Vector2(-90, -45)]:
							drag(MOUSE_BUTTON_MIDDLE, angle * (PI / 180.0 / 0.01))
							await ticks()
							var cursor: Vector2 = nearest_surface_cursor(dish)
							motion(cursor)
							await ticks()
							button(MOUSE_BUTTON_LEFT, true)
							motion(cursor + Vector2(0.01, 0.01))
							await ticks(1)
							check(carry.contact_active, "Rotated visible surfaces must remain usable at the closest distance.")
							check_near(dish)
							check_near(tool)
							button(MOUSE_BUTTON_LEFT, false)
					# Rotate back to the initial view and prove the back/inside is ray reachable.
					item.rotation = Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
					drag(MOUSE_BUTTON_MIDDLE, Vector2(0.001, 0))
					await ticks()
					var hit: Dictionary = held_surface()
					check(hit.get("collider") == dish, "The plate face or cup interior must be reachable at both distance limits.")
					if not hit.is_empty():
						check((hit.normal as Vector3).dot(dish.global_basis.y) > 0.8, "The default cup opening and plate face must expose the real inner/top surface.")
					drag(MOUSE_BUTTON_MIDDLE, Vector2(PI / 0.01, 0))
					await ticks()
					hit = held_surface()
					check(hit.get("collider") == dish and (hit.get("normal", Vector3.ZERO) as Vector3).dot(dish.global_basis.y) < -0.8, "Turning the dish over must expose its real back or outer bottom.")
					# Active poses at the limits must also clear the camera, including sprayers.
					var cursor: Vector2 = camera.unproject_position(hit.position) if not hit.is_empty() else camera.get_viewport().get_visible_rect().size * 0.5
					motion(cursor)
					await ticks()
					button(MOUSE_BUTTON_LEFT, true)
					motion(cursor + Vector2(0.1, 0.1))
					await ticks(1)
					check(carry.contact_active, "Both tools must still reach the turned dish at the distance limits.")
					check_near(tool)
					wheel(not closer)
					motion(camera.get_viewport().get_visible_rect().size * 0.5 + Vector2(12, 0))
					await ticks()
					check(not carry.contact_active, "Wheel adjustment must stop use and require a fresh left press.")
					button(MOUSE_BUTTON_LEFT, false)
				var distance: float = item.close_distance
				var before: Basis = dish.basis
				button(MOUSE_BUTTON_RIGHT, true)
				motion(Vector2(640, 360), Vector2(40, 30))
				button(MOUSE_BUTTON_RIGHT, false)
				check(dish.basis.is_equal_approx(before) and camera.global_transform.is_equal_approx(view), "Immersive right mouse must retain its accepted inactive behavior.")
				tap(&"game_toggle_close")
				wheel(true)
				await wait_transition()
				check(dish.basis.is_equal_approx(before) and is_equal_approx(item.close_distance, distance), "F exit must preserve the chosen angle/distance without carrying transition wheel input.")
				check_pair(dish, tool, 1 if tool_first else 0, identity, rid)
				tap(&"game_toggle_close")
				await wait_transition()
				check(is_equal_approx(-camera.to_local(dish.global_position).z, distance), "F re-entry must restore this hand item's chosen close distance.")
				print("MANIPULATION_CASE_OK: ", dish_name, " tool=", kind, " tool_first=", tool_first)

func verify_distance_obstacle() -> void:
	if not await pair("TrayPlate01", ToolState.Tool.SPONGE, false):
		return
	await pose_at(Vector3(0, 0.03, 1.0), 180, 0)
	tap(&"game_toggle_close")
	await wait_transition()
	var item: HandItem = carry.get_selected_dish_item()
	var obstruction: StaticBody3D = blocker(Vector3(0, -0.015, -0.38), Vector3(0.3, 0.3, 0.01))
	await ticks()
	wheel(true, 20)
	await ticks()
	check(item.close_distance > (item.node as DishBody).close_min_distance, "A real obstacle must stop zoom before the numeric minimum.")
	check_clear(item)
	var pose: Transform3D = item.node.global_transform
	tap(&"game_menu")
	wheel(false, 20)
	check(item.node.global_transform.is_equal_approx(pose), "Menu wheel input must not adjust the dish behind the interface.")
	router.set_interface_open(false)
	obstruction.free()
	await ticks()
	wheel(true, 20)
	await ticks()
	check(is_equal_approx(item.close_distance, (item.node as DishBody).close_min_distance), "Removing the obstacle must allow a fresh zoom to the configured minimum.")
	# A rotation arc can hit an obstacle even when its start is clear.
	wheel(false, 3)
	var turning_blocker: StaticBody3D = blocker(Vector3(0, -0.015, -0.34), Vector3(0.3, 0.3, 0.01))
	await ticks()
	messages.clear()
	drag(MOUSE_BUTTON_MIDDLE, Vector2(150, 0))
	await ticks()
	check_clear(item)
	check(not messages.is_empty() and messages.back().contains("旋转空间不足"), "A blocked rotation arc must stop and explain its spatial limit.")
	turning_blocker.free()

func verify_key_rotation_rates() -> void:
	if not await pair("TrayMug01", ToolState.Tool.SPONGE, true):
		return
	await pose_at(Vector3(0, 0.03, 1.0), 180, 0)
	tap(&"game_toggle_close")
	await wait_transition()
	var original_rate: int = Engine.physics_ticks_per_second
	for rate in [30, 120]:
		Engine.physics_ticks_per_second = rate
		var before: Basis = carry.held_dish.basis
		action(&"game_interact", true)
		await create_timer(0.2).timeout
		action(&"game_interact", false)
		var turn: Basis = carry.held_dish.basis * before.inverse()
		check(absf(atan2(turn.z.x, turn.z.z) + PI * 0.1) < 0.07, "Q/E rotation must use elapsed physics time at 30 and 120 Hz.")
		before = carry.held_dish.basis
		action(&"game_return", true)
		action(&"game_interact", true)
		await ticks(3)
		check(carry.held_dish.basis.is_equal_approx(before), "Opposing Q/E holds must cancel even at the distance boundaries.")
		action(&"game_return", false)
		action(&"game_interact", false)
	Engine.physics_ticks_per_second = original_rate

func verify() -> void:
	await verify_ordinary()
	await verify_close_controls()
	await verify_distance_obstacle()
	await verify_key_rotation_rates()
	game.free()
	if failures == 0:
		print("DISH_MANIPULATION_OK: selected rotation, type distances, all-face access, clipping, obstacles and interruptions.")
		quit(0)
	else:
		push_error("DISH_MANIPULATION_FAILED: %d check(s) failed." % failures)
		quit(1)
