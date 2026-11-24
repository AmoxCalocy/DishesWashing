extends SceneTree
## Import first, then: godot --headless --path . --script Tools/verify_dish_targeting.gd
## Uses real meshes and physics; leaves scenes, resources and saves unchanged.

var failures: int = 0
var kitchen: Node3D
var camera: Camera3D
var targeting: DishTargeting
var router: GameInput

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

func ray(from: Vector3, to: Vector3, mask: int = MeshSurfaceCollision.QUERY_MASK) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.hit_back_faces = false
	return kitchen.get_world_3d().direct_space_state.intersect_ray(query)

func aim(from: Vector3, to: Vector3) -> void:
	camera.global_position = from
	var direction: Vector3 = (to - from).normalized()
	var up: Vector3 = Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > 0.99 else Vector3.UP
	camera.look_at(to, up)

func check_surface(body: DishBody, from: Vector3, to: Vector3, point: Vector3, normal: Vector3, message: String) -> void:
	var hit: Dictionary = ray(body.to_global(from), body.to_global(to), MeshSurfaceCollision.DISH_LAYER)
	check(hit.get("collider") == body, message + " must hit this dish.")
	if hit.is_empty():
		return
	check(body.to_local(hit.position).distance_to(point) < 0.001, message + " must hit the real surface, not a filled opening.")
	check((body.global_basis.inverse() * (hit.normal as Vector3)).dot(normal) > 0.98, message + " must return the outward surface normal.")

func verify() -> void:
	var packed := load("res://Scenes/kitchen-game.tscn") as PackedScene
	if packed == null:
		push_error("Could not load the gameplay scene.")
		quit(1)
		return
	kitchen = packed.instantiate() as Node3D
	root.add_child(kitchen)
	camera = kitchen.get_node("Player/ViewCamera") as Camera3D
	targeting = kitchen.get_node("DishTargeting") as DishTargeting
	router = kitchen.get_node("GameInput") as GameInput
	await advance_ticks(8)
	router.set_interface_open(false)
	# Freeze movement while positioning the real camera for deterministic ray checks.
	kitchen.get_node("Player").set_physics_process(false)
	var plate_1 := kitchen.get_node("PlayableDishes/TrayPlate01") as DishBody
	var plate_2 := kitchen.get_node("PlayableDishes/TrayPlate02") as DishBody
	var mug := kitchen.get_node("PlayableDishes/TrayMug01") as DishBody
	var dishes: Array[DishBody] = [plate_1, plate_2, mug]
	check(kitchen.get_node("PlayableDishes").get_child_count() == 3, "There must be exactly two playable plates and one mug.")
	var ids: Array[StringName] = []
	var label := kitchen.get_node("GameHUD/Crosshair/TargetName") as Label
	for dish in dishes:
		check(not dish.instance_id.is_empty() and not ids.has(dish.instance_id), "Each dish must have its own nonempty identity.")
		ids.append(dish.instance_id)
		var original := kitchen.get_node("Dishes/" + str(dish.name)) as Node3D
		check(not original.visible and original.global_transform.is_equal_approx(dish.global_transform), "Replace only the original tray visual, preserving its complete pose.")
		check(original.find_children("*", "CollisionObject3D", true, false).is_empty(), "Hidden source visuals must not leave duplicate colliders.")
		aim(Vector3(dish.position.x, 1.62, 0.63), dish.global_position)
		await advance_ticks()
		check(targeting.current_dish == dish and router.target == GameInput.Target.DISH, "The crosshair must independently identify " + str(dish.instance_id))
		check(label.visible and label.text == dish.display_name, "The HUD must show the identified dish name.")
	check(plate_1.dish_type == &"plate" and plate_2.dish_type == &"plate" and mug.dish_type == &"mug", "Plate and mug types must remain distinct.")

	# Actual front/back, cup floor/walls and handle aperture, not bounding volumes.
	check_surface(plate_1, Vector3(0, 0.1, 0), Vector3(0, -0.1, 0), Vector3(0, -0.002, 0), Vector3.UP, "Plate front")
	check_surface(plate_1, Vector3(0, -0.1, 0), Vector3(0, 0.1, 0), Vector3(0, -0.006, 0), Vector3.DOWN, "Plate back")
	check_surface(mug, Vector3(0, 0.2, 0), Vector3(0, -0.1, 0), Vector3(0, -0.0425, 0), Vector3.UP, "Open cup floor")
	check_surface(mug, Vector3.ZERO, Vector3(0, 0, -0.1), Vector3(0, 0, -0.0395), Vector3.BACK, "Cup inner wall")
	check_surface(mug, Vector3(0, -0.2, 0), Vector3(0, 0.1, 0), Vector3(0, -0.0485, 0), Vector3.DOWN, "Cup underside")
	check(ray(mug.to_global(Vector3(0.06, 0, 0.1)), mug.to_global(Vector3(0.06, 0, -0.1)), MeshSurfaceCollision.DISH_LAYER).is_empty(), "The cup handle aperture must remain open.")
	check_surface(mug, Vector3(0.15, 0.0015, 0), Vector3(-1, 0.0015, 0), Vector3(0.08575, 0.0015, 0), Vector3.RIGHT, "Cup handle exterior")

	# Rotation/translation must carry the same triangles and the same identity.
	var mug_pose: Transform3D = mug.global_transform
	mug.global_position = Vector3(0, 1.3, 0.6)
	mug.rotation_degrees = Vector3(50, 35, -15)
	await advance_ticks()
	check_surface(mug, Vector3(0, 0.2, 0), Vector3(0, -0.1, 0), Vector3(0, -0.0425, 0), Vector3.UP, "Transformed cup floor")
	check(mug.instance_id == ids[2], "Transforming a dish must not replace its identity.")
	mug.global_transform = mug_pose
	await advance_ticks()

	# Rack slots and tray/sink interiors are real open geometry.
	var rack := kitchen.get_node("Models/DishRack") as Node3D
	check(ray(rack.to_global(Vector3(-0.1095, 0.12, 0.3)), rack.to_global(Vector3(-0.1095, 0.12, -0.3))).is_empty(), "An empty rack slot must not be sealed by a hull.")
	var hit: Dictionary = ray(rack.to_global(Vector3(-0.1095, 0.25, 0)), rack.to_global(Vector3(-0.1095, 0, 0)))
	check(not hit.is_empty() and absf(rack.to_local(hit.get("position", Vector3.INF)).y - 0.036) < 0.001, "A ray through an empty rack slot must reach its actual supporting slat.")
	var tray := kitchen.get_node("Models/DirtyTray") as Node3D
	hit = ray(tray.to_global(Vector3(0.25, 0.2, -0.15)), tray.to_global(Vector3(0.25, 0, -0.15)))
	check(not hit.is_empty() and absf(tray.to_local(hit.get("position", Vector3.INF)).y - 0.012) < 0.001, "Tray opening must expose the actual floor below its rim.")
	hit = ray(Vector3(0.2, 1.2, 0.1), Vector3(0.2, -0.3, 0.1))
	check(not hit.is_empty() and hit.position.y < 0.88 and hit.position.y > 0.5, "The sink opening must reach its basin rather than the coarse cabinet blocker.")

	# Ordinary environment and decorative dishes block rays without being selectable.
	for point in [Vector3(0.4, 0.9, 0.3), Vector3(-0.64, 0.912, -0.125), Vector3(0.6975, 1.1, -0.035)]:
		aim(point + Vector3(0.1, 0.4, 0.4), point)
		await advance_ticks()
		check(targeting.current_dish == null and router.target == GameInput.Target.NONE and not label.visible, "Environment and rack decorations must not be mistaken for a task dish.")

	# Move a dish behind real cabinet/wall surfaces to prove first-hit occlusion.
	var plate_pose: Transform3D = plate_1.global_transform
	for point in [Vector3(0, 0.3, 0), Vector3(0, 1.3, -0.7)]:
		plate_1.global_position = point
		aim(Vector3(0, 1.62, 0.63), point)
		await advance_ticks()
		hit = ray(camera.global_position, point)
		check(not hit.is_empty() and hit.get("collider") != plate_1, "A real environment surface must block the hidden dish.")
		check(targeting.current_dish == null and targeting.query_dish() == null and router.target == GameInput.Target.NONE, "Hidden dishes must never become pickup targets.")
	plate_1.global_position = mug.global_position + Vector3.UP * 0.16
	aim(mug.global_position + Vector3.UP * 0.4, mug.global_position)
	await advance_ticks()
	check(targeting.current_dish == plate_1, "A foreground dish must prevent selecting the dish behind it.")
	plate_1.global_transform = plate_pose
	await advance_ticks()

	# The same aim goes out of reach immediately, and zoom cannot extend reach.
	aim(plate_1.global_position + Vector3.UP * (targeting.interaction_distance - 0.01), plate_1.global_position)
	await advance_ticks()
	check(targeting.current_dish == plate_1, "A visible surface just inside interaction range must be selected.")
	aim(plate_1.global_position + Vector3.UP * (targeting.interaction_distance + 0.01), plate_1.global_position)
	await advance_ticks()
	check(targeting.current_dish == null and router.target == GameInput.Target.NONE, "Walking out of range must clear the target.")
	var fov: float = camera.fov
	camera.fov = 35.0
	check(targeting.query_dish() == null, "View zoom must not extend interaction range.")
	camera.fov = fov

	# Player and walk-only proxy layers cannot cover up a visible dish.
	aim(plate_1.global_position + Vector3.UP * 0.5, plate_1.global_position)
	var probe := StaticBody3D.new()
	probe.collision_layer = 2 | 16
	probe.collision_mask = 0
	var probe_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	probe_shape.shape = box
	probe.add_child(probe_shape)
	kitchen.add_child(probe)
	probe.global_position = plate_1.global_position + Vector3.UP * 0.25
	await advance_ticks()
	check(targeting.current_dish == plate_1, "Target rays must exclude player layer 2 and walk blocker layer 5.")
	probe.free()

	router.set_interface_open(true)
	check(targeting.current_dish == null and not label.visible, "Opening a menu must immediately clear the crosshair target.")
	router.set_interface_open(false)
	await advance_ticks()
	check(targeting.current_dish == plate_1, "Resuming must query the visible target again.")
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(targeting.current_dish == null and not label.visible, "Focus loss must clear stale target feedback.")
	kitchen.free()

	var viewer := (load("res://Scenes/kitchen-demo.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(viewer)
	check(viewer.find_children("*", "CollisionObject3D", true, false).is_empty(), "Gameplay colliders must not leak into the original viewer.")
	check((viewer.get_node("Dishes/TrayPlate01") as Node3D).visible, "The original viewer must retain all display dishes.")
	viewer.free()
	if failures == 0:
		print("DISH_TARGETING_OK: independent IDs, real surfaces, cup/rack/tray openings, range, occlusion and viewer isolation.")
		quit(0)
	else:
		push_error("DISH_TARGETING_FAILED: %d check(s) failed." % failures)
		quit(1)
