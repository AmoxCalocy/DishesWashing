extends SceneTree
## Import first, then: godot --headless --path . --script Tools/verify_dual_wield.gd
## Actual world pickup, stable hand assignment and immersive surface interactions.

var failures: int = 0
var game: Node3D
var player: PlayerController
var camera: Camera3D
var router: GameInput
var targeting: DishTargeting
var carry: DishCarry
var registry: KitchenSlotRegistry

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func action(name: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	root.push_input(event, true)

func tap(name: StringName) -> void:
	action(name, true)
	action(name, false)

func button(code: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = code
	event.pressed = pressed
	event.position = camera.get_viewport().get_visible_rect().size * 0.5
	root.push_input(event, true)

func click() -> void:
	button(MOUSE_BUTTON_LEFT, true)
	button(MOUSE_BUTTON_LEFT, false)

func motion(position: Vector2, relative: Vector2 = Vector2(10, 0)) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.relative = relative
	root.push_input(event, true)

func load_game() -> void:
	if game != null:
		game.free()
	game = (load("res://Scenes/kitchen-game.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(game)
	player = game.get_node("Player") as PlayerController
	camera = player.view_camera
	router = game.get_node("GameInput") as GameInput
	targeting = game.get_node("DishTargeting") as DishTargeting
	carry = game.get_node("DishCarry") as DishCarry
	registry = game.get_node("KitchenSlots") as KitchenSlotRegistry
	await ticks(8)
	router.set_interface_open(false)
	await stand(Vector3(0, 0.03, 0.8))

func stand(position: Vector3) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	camera.position = Vector3(0, 1.62, 0)
	camera.rotation = Vector3.ZERO
	await ticks()

func aim(node: Node3D) -> void:
	var point: Vector3 = node.global_position
	if node is CleaningTool:
		point += Vector3.UP * (0.015 if (node as CleaningTool).tool_kind == ToolState.Tool.SPONGE else -0.04)
	camera.look_at(point)
	await ticks()

func check_tool_in_view(tool: CleaningTool) -> void:
	var fits: bool = true
	var screen: Rect2 = camera.get_viewport().get_visible_rect()
	for child in tool.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		for vertex in mesh.mesh.get_faces():
			var point: Vector3 = mesh.to_global(vertex)
			if -camera.to_local(point).z <= camera.near or not screen.has_point(camera.unproject_position(point)):
				fits = false
	check(fits, "The freely moving tool must stay wholly visible, including at viewport edges.")

func check_sprayer_hose(tool: CleaningTool) -> void:
	var controller: Node3D = game.get_node("WorldCleaningTools") as Node3D
	var links: Array = controller.get("hose_links")
	var previous: Vector3 = (controller.get("hose_exit") as Node3D).global_position
	var connected: bool = true
	var round_links: bool = true
	for link: MeshInstance3D in links:
		var bottom: Vector3 = link.global_position - link.global_basis.y * 0.5
		var top: Vector3 = link.global_position + link.global_basis.y * 0.5
		connected = connected and bottom.distance_to(previous) < 0.00001
		round_links = round_links and absf(link.global_basis.x.length() - 1.0) < 0.00001 and absf(link.global_basis.z.length() - 1.0) < 0.00001
		previous = top
	var coupling := tool.find_child("Hose_Attach", true, false) as Node3D
	check(connected and previous.distance_to(coupling.global_position) < 0.00001, "Actual hose segment ends must meet continuously from the faucet to the sprayer coupling.")
	check(round_links, "Rotating a hose segment must preserve its round cross section.")

func verify() -> void:
	await load_game()
	var first := game.get_node("PlayableDishes/TrayPlate01") as DishBody
	var second := game.get_node("PlayableDishes/TrayMug01") as DishBody
	var third := game.get_node("PlayableDishes/TrayPlate02") as DishBody
	await aim(first)
	click()
	await aim(second)
	click()
	check(carry.held_count() == 2 and carry.hands[0].node == first and carry.hands[1].node == second, "The first dish must occupy the left hand and the second the right.")
	if carry.held_count() != 2:
		quit(1)
		return
	check(registry.find_occupied_slot(first.instance_id) == null and registry.find_occupied_slot(second.instance_id) == null, "Both held dishes must leave their source occupancy immediately.")
	await aim(third)
	click()
	check(carry.held_count() == 2 and registry.find_occupied_slot(third.instance_id) != null, "Full hands must reject a third pickup without losing it.")
	tap(&"game_toggle_close")
	check(router.hand_mode == GameInput.HandMode.CARRYING, "Two dishes must not enter immersive cleaning without a tool.")
	await stand(Vector3(0, 0.03, 2))
	check(camera.to_local(first.global_position).x < -0.15 and camera.to_local(second.global_position).x > 0.15, "Two dishes must remain visibly on opposite sides.")

	# Both pickup orders and both tools use the same original scene instances.
	for tool_kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for tool_first in [false, true]:
			await load_game()
			var dish := game.get_node("PlayableDishes/TrayMug01" if tool_first else "PlayableDishes/TrayPlate01") as DishBody
			var tool := game.find_child("SpongeTool" if tool_kind == ToolState.Tool.SPONGE else "SprayerTool", true, false) as CleaningTool
			var order: Array = [tool, dish] if tool_first else [dish, tool]
			for item in order:
				await aim(item)
				check(targeting.current_tool == tool if item == tool else targeting.current_dish == dish, "World tools and dishes must be selectable in either pickup order.")
				if item == tool:
					tap(&"game_interact")
				else:
					if carry.held_tool() != null:
						tap(&"game_interact")
					else:
						click()
				await ticks()
			check(carry.held_count() == 2 and carry.hands[0].node == order[0] and carry.hands[1].node == order[1], "Pickup order must assign stable hand slots regardless of item roles.")
			if carry.held_count() != 2:
				quit(1)
				return
			check(carry.held_tool() == tool and carry.held_dish == dish, "Immersive roles must identify the actual tool and dish in either hand.")
			await stand(Vector3(0, 0.03, 0.9))
			if tool_kind == ToolState.Tool.SPRAYER:
				check_sprayer_hose(tool)
				var nozzle := tool.find_child("Spray_Nozzle_Point", true, false) as Node3D
				check(camera.global_basis.y.dot(nozzle.global_position - tool.global_position) < -0.05, "A carried sprayer must show its body upright with its nozzle angled down.")
			var player_pose: Transform3D = player.global_transform
			var camera_pose: Transform3D = camera.global_transform
			var fov: float = camera.fov
			tap(&"game_toggle_close")
			check(router.hand_mode == GameInput.HandMode.TRANSITION, "F must start a guarded transition only for a dish + tool pair.")
			tap(&"game_toggle_close")
			action(&"game_move_forward", true)
			await ticks(18)
			check(router.hand_mode == GameInput.HandMode.CLOSE_UP, "The transition must complete in immersive mode.")
			if tool_kind == ToolState.Tool.SPRAYER:
				check_sprayer_hose(tool)
			check(player.global_transform.is_equal_approx(player_pose) and camera.global_transform.is_equal_approx(camera_pose) and camera.fov == fov, "Entering immersion must preserve player position, camera direction and FOV.")
			check(camera.to_local(dish.global_position).distance_to(Vector3(0, -0.015, -0.45)) < 0.001, "Only the same dish must move closer to the center.")
			var center: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
			motion(center)
			await ticks()
			check(router.target == GameInput.Target.DISH, "The immersive cursor must hit the held dish, independent of tool occlusion.")
			var free_point: Vector2 = center + Vector2(150, -80)
			motion(free_point)
			await ticks()
			check(camera.unproject_position(tool.global_position).distance_to(free_point) < 1.0 and not carry.contact_active, "Without left held the tool must follow the cursor freely instead of attaching to the dish.")
			check_tool_in_view(tool)
			if tool_kind == ToolState.Tool.SPRAYER:
				check_sprayer_hose(tool)
			motion(center)
			await ticks()
			button(MOUSE_BUTTON_LEFT, true)
			motion(center + Vector2(5, 0))
			await ticks(1)
			check(carry.contact_active, "Active mouse movement with left held must operate the tool on a real dish surface.")
			if tool_kind == ToolState.Tool.SPONGE:
				check(tool.global_basis.y.dot(carry.contact_normal) > 0.99, "The sponge must align to the actual surface normal.")
				check(tool.global_position.distance_to(carry.contact_point + carry.contact_normal * 0.001) < 0.001, "The sponge contact plane must follow the cursor surface point.")
				await ticks(2)
				check(not carry.contact_active, "Holding a stationary sponge must not count as a scrub.")
			else:
				var nozzle := tool.find_child("Spray_Nozzle_Point", true, false) as Node3D
				var aim_direction: Vector3 = (carry.contact_point - nozzle.global_position).normalized()
				check(nozzle.global_basis.y.dot(aim_direction) > 0.999, "The actual sprayer nozzle must aim at the surface point from its offset pose.")
			button(MOUSE_BUTTON_LEFT, false)
			motion(free_point)
			await ticks()
			check(camera.unproject_position(tool.global_position).distance_to(free_point) < 1.0 and not carry.contact_active, "Releasing left mouse must restore free movement instead of returning the tool to a hand anchor.")
			motion(center)
			await ticks()
			button(MOUSE_BUTTON_LEFT, true)
			motion(center + Vector2(5, 0))
			await ticks(1)
			var before: Basis = dish.basis
			button(MOUSE_BUTTON_RIGHT, true)
			motion(center, Vector2(30, 20))
			button(MOUSE_BUTTON_RIGHT, false)
			await ticks()
			check(dish.basis.is_equal_approx(before) and camera.global_transform.is_equal_approx(camera_pose), "Right dragging must not rotate a dish or turn the camera in immersion.")
			button(MOUSE_BUTTON_MIDDLE, true)
			motion(center, Vector2(30, 20))
			await ticks()
			var idle_pose: Transform3D = tool.global_transform
			check(not dish.basis.is_equal_approx(before) and camera.global_transform.is_equal_approx(camera_pose), "Middle dragging must rotate only the dish.")
			check(not carry.contact_active, "Rotation must stop cleaning.")
			button(MOUSE_BUTTON_MIDDLE, false)
			motion(center)
			await ticks()
			check(not carry.contact_active, "Releasing rotation must not resume an old left hold.")
			check(tool.global_transform.is_equal_approx(idle_pose), "Releasing middle drag must not attach the tool or send it back to a hand anchor.")
			for key in [&"game_return", &"game_interact"]:
				before = dish.basis
				action(key, true)
				await ticks(6)
				var turn: Basis = dish.basis * before.inverse()
				var angle: float = atan2(turn.z.x, turn.z.z)
				check(angle > 0.05 if key == &"game_return" else angle < -0.05, "Holding Q/E must rotate the dish left/right.")
				check(router.hand_mode == GameInput.HandMode.CLOSE_UP and carry.held_count() == 2 and camera.global_transform.is_equal_approx(camera_pose), "Q/E must keep immersion, both items and camera direction.")
				check(not carry.contact_active, "Keyboard rotation must stop cleaning.")
				action(key, false)
				before = dish.basis
				await ticks()
				check(dish.basis.is_equal_approx(before) and not carry.contact_active, "Releasing Q/E must stop rotation without resuming old tool use.")
				check(tool.global_transform.is_equal_approx(idle_pose), "Q/E rotation and release must leave the free tool independent of the dish angle.")
			action(&"game_interact", true)
			await ticks(70)
			action(&"game_interact", false)
			await ticks()
			check(tool.global_transform.is_equal_approx(idle_pose), "Turning the dish past a side-on angle must not snap the tool onto its surface.")
			button(MOUSE_BUTTON_LEFT, false)
			button(MOUSE_BUTTON_LEFT, true)
			motion(center + Vector2(2, 0))
			await ticks(1)
			action(&"game_interact", true)
			await ticks(1)
			before = dish.basis
			router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			await ticks()
			check(router.interface_open and not carry.contact_active and carry.held_count() == 2, "Focus loss must stop interaction and preserve both items.")
			(game.get_node("GameHUD/Menu/Center/Panel/Margin/Rows/Resume") as Button).pressed.emit()
			await ticks()
			check(router.hand_mode == GameInput.HandMode.CLOSE_UP and not carry.contact_active and dish.basis.is_equal_approx(before), "Resume must retain immersive mode without stale cleaning or keyboard rotation.")
			action(&"game_interact", false)
			motion(Vector2(1, 1))
			await ticks()
			check(router.target == GameInput.Target.NONE and not carry.contact_active, "Moving off the held dish must stop contact rather than operate on the background.")
			var size: Vector2 = camera.get_viewport().get_visible_rect().size
			for corner in [Vector2(1, 1), Vector2(size.x - 1, 1), size - Vector2.ONE, Vector2(1, size.y - 1)]:
				motion(corner)
				await ticks()
				check_tool_in_view(tool)
				check(not carry.contact_active and absf(camera.to_local(tool.global_position).x) > 0.1, "Off-dish tool movement must remain free and must not reset to a hand anchor.")
				if tool_kind == ToolState.Tool.SPRAYER:
					check_sprayer_hose(tool)
			var rotated: Basis = dish.basis
			tap(&"game_toggle_close")
			await ticks(18)
			check(router.hand_mode == GameInput.HandMode.CARRYING and carry.hands[0].node == order[0] and carry.hands[1].node == order[1], "F must restore the same two hand assignments.")
			check(dish.global_basis.is_equal_approx(rotated) and camera.global_transform.is_equal_approx(camera_pose), "Exiting must preserve the dish angle and original camera.")
			var tool_anchor: Marker3D = carry.anchor if tool_first else carry.right_anchor
			check(tool.global_position.distance_to(tool_anchor.global_position) < 0.001, "Only returning to carrying with F must restore the tool's original hand position.")
			tap(&"game_tool_none")
			await ticks()
			check(carry.held_count() == 2 and carry.held_tool() == tool, "Key 1 may select a dish but never return a held tool.")
			tap(&"game_interact")
			await ticks()
			check(carry.held_count() == 1 and carry.held_tool() == null and tool.get_parent() == tool.home_parent and tool.global_transform.is_equal_approx(tool.home_pose), "Returning a tool must restore the original instance and leave the other hand unchanged.")
			check(router.hand_mode == GameInput.HandMode.CARRYING, "E must leave a retained dish in ordinary carrying after returning its tool.")
			check(carry.hands[1 if tool_first else 0].node == dish, "A remaining dish must not switch hands when the tool is returned.")
	await load_game()
	var sponge := game.find_child("SpongeTool", true, false) as CleaningTool
	var sprayer := game.find_child("SprayerTool", true, false) as CleaningTool
	await aim(sponge)
	click()
	await aim(sprayer)
	click()
	await ticks()
	check(carry.held_count() == 1 and carry.held_tool() == sponge and sprayer.get_parent() == sprayer.home_parent, "A free second hand must not allow two cleaning tools at once.")
	tap(&"game_interact")
	check(carry.held_count() == 0 and sponge.get_parent() == sponge.home_parent and sprayer.get_parent() == sprayer.home_parent, "With a held tool, E must return that tool rather than pick up the aimed tool.")
	game.free()
	if failures == 0:
		print("DUAL_WIELD_OK: two stable hands, physical tool pickup, immersive transitions, rotation/contact and interruption recovery.")
		quit(0)
	else:
		push_error("DUAL_WIELD_FAILED: %d check(s) failed." % failures)
		quit(1)
