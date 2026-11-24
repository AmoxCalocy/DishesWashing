extends SceneTree
## Import first, then: godot --headless --path . --script Tools/verify_dish_carry.gd
## Real mouse input, scene occupancy, camera clipping and mesh/obstacle probes.

var failures: int = 0
var kitchen: Node3D
var player: PlayerController
var camera: Camera3D
var router: GameInput
var targeting: DishTargeting
var registry: KitchenSlotRegistry
var carry: DishCarry

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func advance_ticks(count: int = 3) -> void:
	for _tick in count:
		await physics_frame
		await process_frame

func action(name: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	root.push_input(event, true)

func mouse_motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	root.push_input(event, true)

func click() -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = Vector2(400, 500)
		root.push_input(event, true)

func load_game() -> void:
	if kitchen != null:
		kitchen.free()
	kitchen = (load("res://Scenes/kitchen-game.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(kitchen)
	player = kitchen.get_node("Player") as PlayerController
	camera = player.view_camera
	router = kitchen.get_node("GameInput") as GameInput
	targeting = kitchen.get_node("DishTargeting") as DishTargeting
	registry = kitchen.get_node("KitchenSlots") as KitchenSlotRegistry
	carry = kitchen.get_node("DishCarry") as DishCarry
	await advance_ticks(8)
	router.set_interface_open(false)

func stand_at(position: Vector3, yaw: float = 0.0, pitch: float = 0.0) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO
	player.rotation.y = yaw
	camera.position = Vector3(0, 1.62, 0)
	camera.rotation = Vector3(pitch, 0, 0)
	await advance_ticks()

func aim_at(dish: DishBody) -> void:
	await stand_at(Vector3(dish.global_position.x, 0.03, 0.7))
	camera.look_at(dish.global_position)
	await advance_ticks()

func check_mesh(dish: DishBody, full_view: bool, obstacles: bool) -> void:
	var nearest_depth: float = INF
	var rightmost_x: float = -INF
	var highest_y: float = -INF
	var fits: bool = true
	var intersects: bool = false
	var screen: Rect2 = camera.get_viewport().get_visible_rect()
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = MeshSurfaceCollision.QUERY_MASK
	query.exclude = [dish.get_rid()]
	query.hit_back_faces = false
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	for node in dish.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var faces: PackedVector3Array = mesh.mesh.get_faces()
		for index in range(0, faces.size(), 3):
			var points: Array[Vector3] = [mesh.to_global(faces[index]), mesh.to_global(faces[index + 1]), mesh.to_global(faces[index + 2])]
			for edge in 3:
				var local: Vector3 = camera.to_local(points[edge])
				nearest_depth = minf(nearest_depth, -local.z)
				rightmost_x = maxf(rightmost_x, local.x)
				highest_y = maxf(highest_y, local.y)
				if full_view and not screen.has_point(camera.unproject_position(points[edge])):
					fits = false
				if obstacles and not intersects:
					query.from = points[edge]
					query.to = points[(edge + 1) % 3]
					intersects = not space.intersect_ray(query).is_empty()
	check(nearest_depth > camera.near + 0.005, "Held dish vertices must remain in front of the near plane.")
	if full_view:
		check(fits and rightmost_x < -0.03 and highest_y < -0.03, "Ordinary carrying must show the whole dish to the lower left of the crosshair in free space.")
	if obstacles:
		check(not intersects, "Held mesh edges must not cross the environment or other dishes.")

func verify() -> void:
	for dish_name in ["TrayPlate01", "TrayPlate02", "TrayMug01"]:
		var case_failures: int = failures
		await load_game()
		var dish := kitchen.get_node("PlayableDishes/" + dish_name) as DishBody
		var identity: StringName = dish.instance_id
		var source: KitchenSlot = registry.find_occupied_slot(identity)
		var source_pose: Transform3D = dish.global_transform
		await aim_at(dish)
		check(targeting.current_dish == dish, "The real crosshair must identify the dish before pickup.")
		# A stale cached target must not authorize an out-of-range pickup.
		camera.global_position += Vector3.BACK * 2.0
		click()
		check(carry.held_dish == null and source.state.occupant_id == identity, "Pickup must requery range instead of trusting the cached target.")
		await aim_at(dish)
		# Insufficient near carry space must reject without losing the dish or occupancy.
		var blocker := StaticBody3D.new()
		blocker.collision_layer = MeshSurfaceCollision.ENVIRONMENT_LAYER
		blocker.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.07, 0.3, 0.07)
		shape.shape = box
		blocker.add_child(shape)
		kitchen.add_child(blocker)
		blocker.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.1, 0, -0.1))
		await advance_ticks()
		click()
		check(carry.held_dish == null and source.state.occupant_id == identity and dish.global_transform.is_equal_approx(source_pose), "An obstructed carry pose must leave the original slot and dish intact.")
		blocker.free()
		await advance_ticks()
		# For the mug, initialize a later pickup from a temporary slot rather than its order origin.
		if dish.dish_type == &"mug":
			source.state.occupant_id = &""
			source = registry.slots[&"Sink_Mug_01"]
			source.state.occupant_id = identity
			dish.global_transform = source.get_pose()
			await aim_at(dish)
		click()
		check(carry.held_dish == dish and dish.instance_id == identity, "Pickup must carry the original dish instance without replacing its identity.")
		check(source.is_empty() and registry.find_occupied_slot(identity) == null, "The source slot must become empty immediately.")
		check(carry.origin_slot_id == source.config.slot_id, "Remember the current pickup origin, not initial_slot_id.")
		check(router.hand_mode == GameInput.HandMode.CARRYING and dish.get_parent() == carry.anchor, "Pickup must enter ordinary carrying at the player-camera anchor.")
		if carry.held_dish != dish:
			continue
		await advance_ticks()
		var label := kitchen.get_node("GameHUD/HandStatus") as Label
		check(label.visible and label.text.contains(dish.display_name), "The HUD must identify the held dish and its hand.")
		for index in 5:
			click()
			router.command_requested.emit(&"pickup_dish", true)
		check(carry.held_dish == dish and carry.origin_slot_id == source.config.slot_id, "Repeated pickup without a valid world target must preserve the held dish.")
		check(kitchen.get_node("PlayableDishes").get_child_count() == 2, "The held dish must leave its placed parent without generating a copy.")
		var occupied: int = 0
		for slot: KitchenSlot in registry.slots.values():
			if not slot.is_empty():
				occupied += 1
		check(occupied == 2, "Exactly two placed dishes must remain in the slot registry.")
		await stand_at(Vector3(0, 0.03, 2.0))
		check(camera.to_local(dish.global_position).distance_to(Vector3(-0.28, -0.22, -0.78)) < 0.001, "Free carrying must use the normal distant, lower-left anchor.")
		check_mesh(dish, true, false)
		mouse_motion(Vector2.ZERO)
		action(&"game_move_forward", true)
		mouse_motion(Vector2(-PI / 2.0 / player.look_sensitivity, 0))
		var start: Vector3 = player.global_position
		await advance_ticks(15)
		action(&"game_move_forward", false)
		check(player.global_position.x < start.x - 0.3, "Carrying must allow WASD and direct mouse look together.")
		check_mesh(dish, true, false)
		action(&"game_move_right", true)
		await advance_ticks(2)
		action(&"game_menu", true)
		action(&"game_menu", false)
		start = player.global_position
		await advance_ticks(4)
		check(player.global_position.distance_to(start) < 0.005 and carry.held_dish == dish and source.is_empty(), "Menus must stop movement without dropping or restoring the held dish.")
		check(not label.is_visible_in_tree(), "The carrying name must be hidden behind the menu.")
		(kitchen.get_node("GameHUD/Menu/Center/Panel/Margin/Rows/Resume") as Button).pressed.emit()
		await advance_ticks(4)
		check(player.global_position.distance_to(start) < 0.005 and carry.held_dish == dish, "Resume must preserve carrying without stale movement.")
		router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		check(router.interface_open and carry.held_dish == dish, "Focus return must wait for explicit resume and retain the held dish.")
		(kitchen.get_node("GameHUD/Menu/Center/Panel/Margin/Rows/Resume") as Button).pressed.emit()
		for command in [&"game_return", &"game_toggle_close"]:
			action(command, true)
			action(command, false)
		check(carry.held_dish == dish and source.is_empty() and router.hand_mode == GameInput.HandMode.CARRYING, "A lone dish must remain carried when Q/F has no valid tool pair.")
		var poses: Array = [
			[Vector3(0, 0.03, 0.63), 0.0, -50.0],
			[Vector3(0.88, 0.03, 0.63), 0.0, -50.0],
			[Vector3(-1, 0.03, 0.63), 0.0, -50.0],
			[Vector3(2.27, 0.03, -0.16), 0.0, 0.0],
			[Vector3(-2.27, 0.03, -0.16), 0.0, 0.0],
			[Vector3(2.27, 0.03, -0.16), -45.0, 0.0],
			[Vector3(-2.27, 0.03, -0.16), 45.0, 0.0],
			[Vector3(-1, 0.03, 0.63), 0.0, -80.0],
			[Vector3(2.27, 0.03, -0.16), -45.0, -80.0],
			[Vector3(2.27, 0.03, -0.16), -45.0, 80.0],
			[Vector3(0, 0.03, 2.0), 0.0, -80.0],
			[Vector3(0, 0.03, 2.0), 180.0, 80.0],
		]
		for pose in poses:
			await stand_at(pose[0], deg_to_rad(pose[1]), deg_to_rad(pose[2]))
			check_mesh(dish, false, true)
			check(carry.held_dish == dish and source.is_empty(), "Obstacle avoidance must not lose or place the dish.")
		await stand_at(Vector3(0, 0.03, 2.0))
		check(camera.to_local(dish.global_position).distance_to(Vector3(-0.28, -0.22, -0.78)) < 0.001, "The normal lower-left carry position must recover after leaving obstacles.")
		if failures == case_failures:
			print("CARRY_CASE_OK: ", dish_name)
	kitchen.free()
	var viewer := (load("res://Scenes/kitchen-demo.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(viewer)
	check(viewer.get_node_or_null("DishCarry") == null, "Pickup must remain isolated from the old viewer.")
	viewer.free()
	if failures == 0:
		print("DISH_CARRY_OK: original instance, single-dish cases, current-slot release/origin, walking/look, clipping, obstacles and interruption.")
		quit(0)
	else:
		push_error("DISH_CARRY_FAILED: %d check(s) failed." % failures)
		quit(1)
