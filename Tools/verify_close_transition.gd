extends "res://Tools/verify_dual_wield.gd"
## Import first, then: godot --headless --path . --script Tools/verify_close_transition.gd
## Step 15: real-scene F round trips, swept space and interruption recovery.

var messages: Array[String] = []

func pair(dish_name: String, kind: ToolState.Tool, tool_first: bool) -> bool:
	await load_game()
	messages.clear()
	carry.message_requested.connect(func(message: String) -> void: messages.append(message))
	var dish := game.get_node("PlayableDishes/" + dish_name) as DishBody
	var tool := game.find_child("SpongeTool" if kind == ToolState.Tool.SPONGE else "SprayerTool", true, false) as CleaningTool
	var order: Array = [tool, dish] if tool_first else [dish, tool]
	for node in order:
		await aim(node)
		tap(&"game_interact")
		await ticks()
	var ready: bool = carry.held_count() == 2 and carry.held_dish == dish and carry.held_tool() == tool
	check(ready, "The scene must supply the original dish/tool pair through world pickup.")
	check(carry.dish_states.is_empty(), "Production must not supply a default clean state.")
	var config := load("res://Resources/Examples/plate-config-example.tres" if dish.dish_type == &"plate" else "res://Resources/Examples/mug-config-example.tres") as DishConfig
	var state := DishState.new(dish.instance_id, config, &"")
	state.is_held = true
	state.detergent_applied = true
	for region: StainRegionState in state.stain_regions.values():
		region.remaining_amount = region.initial_amount * 0.37
		region.foam_amount = 0.42
	carry.dish_states[dish.instance_id] = state
	return ready

func pose_at(position: Vector3, yaw: float, pitch: float) -> void:
	await stand(position)
	player.rotation.y = deg_to_rad(yaw)
	camera.rotation.x = deg_to_rad(pitch)
	await ticks()

func check_pair(dish: DishBody, tool: CleaningTool, side: int, identity: int, rid: RID) -> void:
	check(carry.held_count() == 2 and carry.hands[side].node == dish and carry.hands[1 - side].node == tool, "F must preserve the same two hand assignments.")
	check(dish.get_instance_id() == identity and dish.get_rid() == rid and dish.location == DishBody.Location.HELD, "F must retain the original held identity and query body.")
	check(dish.motion_body.freeze and dish.motion_body.collision_layer == 0 and dish.motion_body.collision_mask == 0, "F must not release the held motion body into physics.")
	check(registry.find_occupied_slot(dish.instance_id) == null and targeting.excluded_bodies.has(rid) and targeting.excluded_bodies.has(tool.get_rid()), "F must preserve released source occupancy and both held exclusions.")
	var state: DishState = carry.dish_states[dish.instance_id]
	check(state.is_held and state.current_slot_id.is_empty() and state.detergent_applied, "F must preserve the injected authoritative position and detergent state.")
	for region: StainRegionState in state.stain_regions.values():
		check(region.remaining_amount == region.initial_amount * 0.37 and region.foam_amount == 0.42, "F must preserve each region's dirt and foam progress.")

func check_view(player_pose: Transform3D, camera_pose: Transform3D, fov: float) -> void:
	check(player.global_transform.is_equal_approx(player_pose) and camera.global_transform.is_equal_approx(camera_pose) and camera.fov == fov, "F, blocked WASD and cursor input must preserve the player's position, direction and FOV.")

func check_clear(item: HandItem) -> void:
	check(PlacementRules._has_space(item, item.node.global_transform, camera, targeting.excluded_bodies), "The moving dish must remain clear of actual environment geometry.")
	var facing: AABB = camera.global_transform.affine_inverse() * item.node.global_transform * item.bounds
	check(-facing.end.z > camera.near + 0.005, "Transition geometry must stay clear of the near plane.")

func wait_transition() -> void:
	var started: int = Time.get_ticks_msec()
	while router.hand_mode == GameInput.HandMode.TRANSITION and Time.get_ticks_msec() - started < 2000:
		await ticks(1)
		check_clear(carry.get_selected_dish_item())
	check(router.hand_mode != GameInput.HandMode.TRANSITION, "A guarded transition must finish without getting stuck.")

func blocker(local_position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = MeshSurfaceCollision.ENVIRONMENT_LAYER
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	game.add_child(body)
	body.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, local_position)
	return body

func verify_round_trips() -> void:
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for case: Array in [["TrayPlate01", false], ["TrayPlate01", true], ["TrayMug01", false], ["TrayMug01", true]]:
			var tool_first: bool = case[1]
			if not await pair(case[0], kind, tool_first):
				return
			var dish: DishBody = carry.held_dish
			var tool: CleaningTool = carry.held_tool()
			var side: int = 1 if tool_first else 0
			var identity: int = dish.get_instance_id()
			var rid: RID = dish.get_rid()
			var source: Transform3D = carry.hands[side].origin_pose
			var stations: Array = [
				[Vector3(0, 0.03, 0.9), 0.0, 0.0, Vector2(230, -100)],
				[Vector3(-0.8, 0.03, 0.9), 35.0, -15.0, Vector2(-230, -100)],
				[Vector3(0.8, 0.03, 0.9), -35.0, -15.0, Vector2(230, 100)],
				[Vector3(0, 0.03, 0.9), 180.0, 20.0, Vector2(-230, 100)],
				[Vector3(0, 0.03, 1.0), 90.0, -25.0, Vector2(30, -20)],
			]
			for station in stations:
				await pose_at(station[0], station[1], station[2])
				var player_pose: Transform3D = player.global_transform
				var camera_pose: Transform3D = camera.global_transform
				var fov: float = camera.fov
				var start: Vector3 = dish.position
				action(&"game_move_forward", true)
				button(MOUSE_BUTTON_LEFT, true)
				tap(&"game_toggle_close")
				check(router.hand_mode == GameInput.HandMode.TRANSITION, "F must enter a guarded transition from each clear station and orientation.")
				if router.hand_mode != GameInput.HandMode.TRANSITION:
					action(&"game_move_forward", false)
					button(MOUSE_BUTTON_LEFT, false)
					continue
				var started: int = Time.get_ticks_msec()
				tap(&"game_toggle_close")
				tap(&"game_drop")
				tap(&"game_interact")
				await ticks(3)
				check(router.hand_mode == GameInput.HandMode.TRANSITION and not dish.position.is_equal_approx(start), "F must animate rather than teleport or accept repeated switches.")
				await wait_transition()
				check(Time.get_ticks_msec() - started >= 150 and Time.get_ticks_msec() - started < 700, "A normal F transition must last approximately 0.2 seconds.")
				check(router.hand_mode == GameInput.HandMode.CLOSE_UP and dish.get_parent() == camera, "Only the original dish must move into the close camera anchor.")
				check(camera.to_local(dish.global_position).distance_to(carry.close_anchor.position) < 0.001, "The close pose must follow the current camera rather than a world station.")
				check_pair(dish, tool, side, identity, rid)
				check_view(player_pose, camera_pose, fov)
				check(not carry.contact_active, "Entry must discard the old ordinary left hold.")
				for movement in GameInput.MOVE_ACTIONS:
					action(movement, true)
				motion(camera.get_viewport().get_visible_rect().size * 0.5 + station[3])
				await ticks()
				check_view(player_pose, camera_pose, fov)
				check_tool_in_view(tool)
				for rotation in [&"game_return", &"game_interact"]:
					action(rotation, true)
					await ticks(2)
					action(rotation, false)
					check(router.hand_mode == GameInput.HandMode.CLOSE_UP and carry.held_tool() == tool, "Q/E must rotate without exiting immersion or returning a tool.")
				var rotated: Basis = dish.basis
				tap(&"game_drop")
				tap(&"game_toggle_close")
				check(router.hand_mode == GameInput.HandMode.TRANSITION, "Only F must begin the return to ordinary carrying.")
				tap(&"game_toggle_close")
				tap(&"game_drop")
				await wait_transition()
				await ticks()
				check(router.hand_mode == GameInput.HandMode.CARRYING and dish.get_parent() == (carry.anchor if side == 0 else carry.right_anchor), "F must restore the original carry parent.")
				check(-camera.to_local(dish.global_position).z > 0.6 and -camera.to_local(tool.global_position).z > 0.6, "F must recover ordinary carry distances after free tools move to either side; held items must not block each other.")
				if station[1] in [0.0, 180.0]:
					check(dish.global_position.distance_to((carry.anchor if side == 0 else carry.right_anchor).global_position) < 0.001 and tool.global_position.distance_to((carry.right_anchor if side == 0 else carry.anchor).global_position) < 0.001, "In open space, F must restore both full anchors; near the rack, normal carry clearance may shorten the pose.")
				check(dish.basis.is_equal_approx(rotated) and carry.hands[side].origin_pose.is_equal_approx(source), "Round trips must retain the dish angle and actual pickup source.")
				check_pair(dish, tool, side, identity, rid)
				check_view(player_pose, camera_pose, fov)
				check(router.get_movement_vector() == Vector2.ZERO and not carry.contact_active, "Exit must not replay old movement or use intentions.")
				button(MOUSE_BUTTON_LEFT, false)
				motion(Vector2.ZERO, Vector2.ZERO)
				motion(Vector2.ZERO, Vector2(4, 0))
				check(not camera.global_transform.is_equal_approx(camera_pose), "Fresh mouse input must restore ordinary direct look.")
				action(&"game_move_back", false)
				action(&"game_move_back", true)
				await ticks(2)
				action(&"game_move_back", false)
				check(player.global_position.distance_to(player_pose.origin) > 0.02, "Fresh WASD must work after the F return.")
			print("CLOSE_STATIONS_OK: ", case[0], " tool=", kind, " tool_first=", tool_first)

func verify_space() -> void:
	if not await pair("TrayPlate01", ToolState.Tool.SPONGE, false):
		return
	await pose_at(Vector3(0, 0.03, 1.2), 180, 0)
	var dish: DishBody = carry.held_dish
	var item: HandItem = carry.get_selected_dish_item()
	var pose: Transform3D = dish.global_transform
	for point in [carry.close_anchor.position, Vector3(-0.224, -0.179, -0.70)]:
		# Sync a newly arrived obstacle before the next carry solve or F input.
		carry.set_physics_process(false)
		var obstruction: StaticBody3D = blocker(point, Vector3.ONE * 0.018)
		await ticks()
		carry.set_physics_process(true)
		check_clear(item)
		messages.clear()
		tap(&"game_toggle_close")
		check(router.hand_mode == GameInput.HandMode.CARRYING and dish.global_transform.is_equal_approx(pose), "Blocked destination or travel space must reject F without moving or dropping either item.")
		check(not messages.is_empty() and messages.back().contains("空间不足"), "Blocked F must explain the space restriction.")
		# Do not let a failed rejection cascade into the next fixture.
		await wait_transition()
		obstruction.free()
		await ticks()
		if router.hand_mode == GameInput.HandMode.CLOSE_UP:
			tap(&"game_toggle_close")
			await wait_transition()
		pose = dish.global_transform
	# The side aisle is walkable, but the real kitchen back wall blocks F.
	await pose_at(Vector3(1.8, 0.03, -0.05), 0, 0)
	tap(&"game_toggle_close")
	check(router.hand_mode == GameInput.HandMode.CARRYING, "Actual kitchen wall geometry must block an unsafe close space.")
	await pose_at(Vector3(0, 0.03, 1.2), 180, 0)
	tap(&"game_toggle_close")
	await wait_transition()
	check(router.hand_mode == GameInput.HandMode.CLOSE_UP, "Moving clear must allow a fresh F entry after rejection.")
	# A new world obstruction at the near carry start must not reuse a stale pose.
	var obstruction: StaticBody3D = blocker(Vector3(0, 0, -0.09), Vector3(0.5, 0.5, 0.03))
	await ticks()
	pose = dish.global_transform
	messages.clear()
	tap(&"game_toggle_close")
	check(router.hand_mode == GameInput.HandMode.CLOSE_UP and dish.global_transform.is_equal_approx(pose), "An obstructed carry return must keep the dish in immersion instead of using a stale safe pose.")
	check(not messages.is_empty() and messages.back().contains("空间不足"), "A blocked return must explain why it retains immersion.")
	obstruction.free()
	await ticks()
	tap(&"game_toggle_close")
	await wait_transition()
	check(router.hand_mode == GameInput.HandMode.CARRYING, "Removing the return obstruction must allow F to recover.")
	# Sprayers retain their separate home-distance requirement.
	if not await pair("TrayMug01", ToolState.Tool.SPRAYER, true):
		return
	await pose_at(Vector3(0, 0.03, 2.0), 180, 0)
	pose = carry.held_dish.global_transform
	messages.clear()
	tap(&"game_toggle_close")
	check(router.hand_mode == GameInput.HandMode.CARRYING and carry.held_dish.global_transform.is_equal_approx(pose), "Out-of-range sprayers must refuse F without relocating the player or held dish.")
	check(not messages.is_empty() and messages.back().contains("靠近水槽"), "Sprayer range rejection must give the existing home-distance reason.")

func verify_interruptions() -> void:
	if not await pair("TrayMug01", ToolState.Tool.SPONGE, true):
		return
	await pose_at(Vector3(0, 0.03, 1.2), 180, 0)
	var dish: DishBody = carry.held_dish
	var tool: CleaningTool = carry.held_tool()
	for focus_loss in [false, true]:
		for entering in [true, false]:
			var player_pose: Transform3D = player.global_transform
			var camera_pose: Transform3D = camera.global_transform
			var fov: float = camera.fov
			tap(&"game_toggle_close")
			await ticks(3)
			check(router.hand_mode == GameInput.HandMode.TRANSITION, "Interruption fixtures must run during both entry and exit.")
			if focus_loss:
				router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			else:
				tap(&"game_menu")
			check(router.interface_open, "Esc/focus interruption must open the interface during F.")
			var menu_cursor := Vector2(40, 40)
			if DisplayServer.get_name() != "headless":
				root.warp_mouse(menu_cursor)
			tap(&"game_toggle_close")
			tap(&"game_drop")
			action(&"game_move_forward", true)
			button(MOUSE_BUTTON_LEFT, true)
			button(MOUSE_BUTTON_MIDDLE, true)
			action(&"game_interact", true)
			await wait_transition()
			check(router.hand_mode == (GameInput.HandMode.CLOSE_UP if entering else GameInput.HandMode.CARRYING), "Input interruption must preserve the in-flight F destination; full freezing belongs to step 18.")
			check(router.interface_open and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Completing F behind a menu must keep interface control and a visible cursor.")
			if DisplayServer.get_name() != "headless":
				check(root.get_mouse_position().distance_to(menu_cursor) < 1.0, "Finishing F behind an interface must not warp the menu cursor back to the dish.")
			check_pair(dish, tool, 1, dish.get_instance_id(), dish.get_rid())
			check_view(player_pose, camera_pose, fov)
			var rotation: Basis = dish.global_basis
			(game.get_node("GameHUD/Menu/Center/Panel/Margin/Rows/Resume") as Button).pressed.emit()
			await ticks()
			check(not carry.contact_active and router.get_movement_vector() == Vector2.ZERO and dish.global_basis.is_equal_approx(rotation), "Resume must not replay blocked movement, left use or rotation.")
			check_view(player_pose, camera_pose, fov)
			if DisplayServer.get_name() != "headless":
				check(Input.mouse_mode == (Input.MOUSE_MODE_VISIBLE if entering else Input.MOUSE_MODE_CAPTURED), "Resume must restore mouse ownership for the resulting mode.")
			button(MOUSE_BUTTON_LEFT, false)
			button(MOUSE_BUTTON_MIDDLE, false)
			action(&"game_interact", false)

func verify() -> void:
	await verify_round_trips()
	await verify_space()
	await verify_interruptions()
	game.free()
	if failures == 0:
		print("CLOSE_TRANSITION_OK: multi-station F, original hands/view, blocked space and interruption recovery.")
		quit(0)
	else:
		push_error("CLOSE_TRANSITION_FAILED: %d check(s) failed." % failures)
		quit(1)
