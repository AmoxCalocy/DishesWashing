extends SceneTree
## Import first, then: godot --headless --path . --script Tools/verify_kitchen_slots.gd
## Probes real dish meshes in all 13 poses; does not save scenes or user data.

var failures: int = 0
var kitchen: Node3D
var camera: Camera3D
var registry: KitchenSlotRegistry
var targeting: DishTargeting
var router: GameInput
var commands: Array[StringName] = []

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

func aim(from: Vector3, to: Vector3) -> void:
	camera.global_position = from
	var up: Vector3 = Vector3.FORWARD if absf((to - from).normalized().dot(Vector3.UP)) > 0.99 else Vector3.UP
	camera.look_at(to, up)

func ray(from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, exclude)
	query.hit_back_faces = false
	return kitchen.get_world_3d().direct_space_state.intersect_ray(query)

func send_primary() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"game_primary"
		event.pressed = pressed
		root.push_input(event, true)

func check_geometry(dish: DishBody, slot_id: StringName) -> void:
	var vertices: Dictionary[Vector3, bool] = {}
	var lowest: float = INF
	var intersects: bool = false
	var exclude: Array[RID] = [dish.get_rid()]
	for node in dish.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var faces: PackedVector3Array = mesh.mesh.get_faces()
		for index in range(0, faces.size(), 3):
			var points: Array[Vector3] = [mesh.to_global(faces[index]), mesh.to_global(faces[index + 1]), mesh.to_global(faces[index + 2])]
			for edge in 3:
				vertices[points[edge]] = true
				lowest = minf(lowest, points[edge].y)
				if not intersects:
					var hit: Dictionary = ray(points[edge], points[(edge + 1) % 3], MeshSurfaceCollision.QUERY_MASK, exclude)
					if not hit.is_empty():
						intersects = true
						check(false, "Dish surface intersects environment/another dish at %s: %s." % [slot_id, hit.position])
	var nearest_support: float = INF
	for point: Vector3 in vertices:
		if point.y > lowest + 0.00001:
			continue
		var hit: Dictionary = ray(point + Vector3.UP * 0.0001, point - Vector3.UP * 0.025, MeshSurfaceCollision.ENVIRONMENT_LAYER)
		if not hit.is_empty():
			nearest_support = minf(nearest_support, point.y - (hit.position as Vector3).y)
	check(nearest_support >= 0.0002 and nearest_support <= 0.001, "Slot %s needs real support approximately 0.5 mm below the dish, got %f m." % [slot_id, nearest_support])

func verify() -> void:
	var packed := load("res://Scenes/kitchen-game.tscn") as PackedScene
	kitchen = packed.instantiate() as Node3D
	root.add_child(kitchen)
	registry = kitchen.get_node("KitchenSlots") as KitchenSlotRegistry
	targeting = kitchen.get_node("DishTargeting") as DishTargeting
	router = kitchen.get_node("GameInput") as GameInput
	camera = kitchen.get_node("Player/ViewCamera") as Camera3D
	await advance_ticks(8)
	router.set_interface_open(false)
	kitchen.get_node("Player").set_physics_process(false)
	router.command_requested.connect(func(command: StringName, pressed: bool) -> void:
		if pressed:
			commands.append(command)
	)
	check(registry.slots.size() == 13, "Register all 3 tray, 8 rack and 2 temporary slots.")
	var kinds: Array[int] = [0, 0, 0]
	var initial_dishes: Dictionary[StringName, DishBody] = {}
	for child in kitchen.get_node("PlayableDishes").get_children():
		var dish := child as DishBody
		initial_dishes[dish.initial_slot_id] = dish
	for slot: KitchenSlot in registry.slots.values():
		kinds[slot.config.slot_kind] += 1
		check(not slot.config.display_name.is_empty(), "Each registered slot needs a display name.")
		var type: StringName = &"mug" if "Mug" in str(slot.config.slot_id) or "Cup" in str(slot.config.slot_id) else &"plate"
		check(slot.accepts(type) and not slot.accepts(&"bowl"), "Compatible types must match the plate/mug fixture at " + str(slot.config.slot_id))
		check(slot.config.accepted_dish_types.size() == 1, "MVP slots have one compatible type.")
		if initial_dishes.has(slot.config.slot_id):
			var dish: DishBody = initial_dishes[slot.config.slot_id]
			check(slot.state.occupant_id == dish.instance_id and dish.global_transform.is_equal_approx(slot.get_pose()), "Initial occupancy and the full dish-root marker pose must agree.")
		else:
			check(slot.is_empty(), "Rack and temporary slots must start empty.")
		if slot.config.slot_kind != SlotConfig.Kind.TEMPORARY:
			var fixture: Node = kitchen.get_node(slot.config.fixture_path)
			var marker := fixture.find_child(str(slot.config.slot_id), true, false) as Node3D
			check(slot.marker == marker and slot.get_pose().is_equal_approx(marker.global_transform), "Use the original asset marker without another half-height offset.")
		if str(slot.config.slot_id).begins_with("Rack_Slot_"):
			check(absf(slot.get_pose().basis.y.dot(Vector3.RIGHT)) > 0.99, "Rack plates must retain their vertical orientation.")
		elif str(slot.config.slot_id).begins_with("Rack_Cup_"):
			check(slot.get_pose().basis.y.dot(Vector3.UP) < -0.99, "Rack cups must retain their inverted orientation.")
	check(kinds == [3, 2, 8], "Slot categories must be 3 tray, 2 temporary and 8 rack.")
	for child in kitchen.get_node("Dishes").get_children():
		check(not (child as Node3D).visible and child.find_children("*", "CollisionObject3D", true, false).is_empty(), "Display dishes must not occupy or obstruct gameplay slots.")

	# Resources can be shared; slot state and occupancy must remain per scene.
	var second := packed.instantiate() as Node3D
	root.add_child(second)
	var second_registry := second.get_node("KitchenSlots") as KitchenSlotRegistry
	check(registry.layout == second_registry.layout, "The immutable layout should remain reusable.")
	var temp: KitchenSlot = registry.slots[&"Sink_Plate_01"]
	temp.state.occupant_id = &"isolation_probe"
	check(second_registry.slots[&"Sink_Plate_01"].is_empty() and registry.slots[&"Sink_Mug_01"].is_empty(), "Changing one occupant must not affect other slots or another scene.")
	temp.state.occupant_id = &""
	second.free()

	# Fill every pose simultaneously with the formal meshes for real intersection checks.
	var probes: Array[DishBody] = []
	var all_dishes: Dictionary[StringName, DishBody] = initial_dishes.duplicate()
	for slot: KitchenSlot in registry.slots.values():
		if all_dishes.has(slot.config.slot_id):
			continue
		var type: StringName = slot.config.accepted_dish_types[0]
		var dish := (load("res://Scenes/Dishes/%s.tscn" % type) as PackedScene).instantiate() as DishBody
		dish.instance_id = StringName("geometry_" + str(slot.config.slot_id))
		kitchen.add_child(dish)
		dish.global_transform = slot.get_pose()
		probes.append(dish)
		all_dishes[slot.config.slot_id] = dish
	await advance_ticks()
	for slot_id: StringName in all_dishes:
		check_geometry(all_dishes[slot_id], slot_id)
	for dish in probes:
		dish.free()
	await advance_ticks()

	var label := kitchen.get_node("GameHUD/Crosshair/TargetName") as Label
	for slot_id: StringName in [&"Sink_Plate_01", &"Sink_Mug_01"]:
		var slot: KitchenSlot = registry.slots[slot_id]
		var surface := slot.marker.get_node("SelectionSurface") as Node3D
		var eye := Vector3(slot.get_pose().origin.x, 1.62, 0.63)
		aim(eye, surface.global_position)
		await advance_ticks()
		check(targeting.current_slot == slot and targeting.current_dish == null and router.target == GameInput.Target.SLOT, "A nearby player must be able to select " + str(slot_id))
		check(label.visible and label.text == slot.config.display_name, "The crosshair must name the selected temporary slot.")
		commands.clear()
		send_primary()
		check(commands.is_empty() and slot.is_empty(), "Empty-hand slot selection must not implement placement or pickup early.")
		slot.state.occupant_id = &"occupied_probe"
		await advance_ticks()
		check(targeting.current_slot == null and not label.visible, "An occupied temporary slot must not remain selected.")
		slot.state.occupant_id = &""
		await advance_ticks()
		router.set_interface_open(true)
		check(targeting.current_slot == null and not label.visible, "Menu opening must immediately clear slot feedback.")
		router.set_interface_open(false)
		await advance_ticks()
		check(targeting.current_slot == slot, "Resume must reacquire the slot rather than retain stale input.")
		aim(surface.global_position + Vector3.UP * (targeting.interaction_distance + 0.02), surface.global_position)
		await advance_ticks()
		check(targeting.current_slot == null and not label.visible, "A temporary slot beyond reach cannot be selected.")
		aim(eye, surface.global_position)
		var blocker := StaticBody3D.new()
		blocker.collision_layer = MeshSurfaceCollision.ENVIRONMENT_LAYER
		blocker.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3.ONE * 0.12
		shape.shape = box
		blocker.add_child(shape)
		kitchen.add_child(blocker)
		blocker.global_position = eye.lerp(surface.global_position, 0.5)
		await advance_ticks()
		check(targeting.current_slot == null and not label.visible, "An obstruction must block slot selection.")
		blocker.free()
		await advance_ticks()

	# Put real dishes in the two temporary poses, then use the actual soap input route.
	for pair in [[&"Dirty_Plate_01", &"Sink_Plate_01"], [&"Dirty_Mug_01", &"Sink_Mug_01"]]:
		var source: KitchenSlot = registry.slots[pair[0]]
		var destination: KitchenSlot = registry.slots[pair[1]]
		var dish: DishBody = initial_dishes[pair[0]]
		source.state.occupant_id = &""
		destination.state.occupant_id = dish.instance_id
		dish.global_transform = destination.get_pose()
		router.set_context(GameInput.HandMode.SOAP_BOTTLE, GameInput.Target.NONE)
		aim(Vector3(dish.global_position.x, 1.62, 0.63), dish.global_position)
		await advance_ticks()
		check(targeting.current_dish == dish and targeting.current_slot == null and label.text == dish.display_name, "A placed plate/mug must remain visible to soap aiming, with the dish taking priority.")
		commands.clear()
		send_primary()
		check(commands == [&"pump_soap"], "Soap input must resolve to the placed dish; this does not implement pump execution.")
		dish.global_transform = source.get_pose()
		source.state.occupant_id = dish.instance_id
		destination.state.occupant_id = &""
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE)
	await advance_ticks()
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(targeting.current_slot == null and not label.visible, "Focus loss must clear any target feedback.")
	kitchen.free()

	var viewer := (load("res://Scenes/kitchen-demo.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(viewer)
	check(viewer.get_node_or_null("KitchenSlots") == null, "The viewer must not register gameplay slots.")
	check((viewer.get_node("Dishes/RackPlate01") as Node3D).visible and (viewer.get_node("Dishes/RackMug01") as Node3D).visible, "The original viewer must keep its rack display.")
	viewer.free()
	if failures == 0:
		print("KITCHEN_SLOTS_OK: 13 poses, independent occupancy, real support/intersections, temporary targets and soap aiming.")
		quit(0)
	else:
		push_error("KITCHEN_SLOTS_FAILED: %d check(s) failed." % failures)
		quit(1)
