extends "res://Tools/verify_placement_rules.gd"
## Import first, then: godot --headless --path . --script Tools/verify_placement_preview.gd
## Real free basin positions, rack snapping, shared rules and visual-only copies.

var preview: PlacementPreview
var hint: Label

func prepare() -> void:
	await load_game()
	preview = game.get_node("PlacementPreview") as PlacementPreview
	hint = game.get_node("GameHUD/Crosshair/PlacementHint") as Label

func basin_hit(at: Vector2) -> Dictionary:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, 0.8, at.y), Vector3(at.x, 0.55, at.y), MeshSurfaceCollision.QUERY_MASK, targeting.excluded_bodies)
	return camera.get_world_3d().direct_space_state.intersect_ray(ray)

func look_at_basin(at: Vector2) -> void:
	var hit: Dictionary = basin_hit(at)
	check(not hit.is_empty(), "The test point needs a real interior basin surface.")
	if hit.is_empty():
		return
	await stand(Vector3(at.x, 0.03, 0.65))
	camera.look_at(hit.position)
	await ticks(6)

func look_at_slot(slot: KitchenSlot) -> void:
	var point: Vector3 = slot.get_pose().origin
	await stand(Vector3(point.x, 0.03, 0.9))
	camera.look_at(point)
	await ticks(6)

func expect_preview(code: PlacementResult.Code, context: String, slot: KitchenSlot = null) -> void:
	check(preview.visible and preview.result != null and preview.current_slot == slot, context + ": show the intended preview.")
	if preview.result == null:
		return
	expect_code(preview.result, code, context)
	var expected: PlacementResult
	var state: DishState = carry.dish_states.get(carry.selected_dish.instance_id)
	if slot != null:
		check(preview.current_surface.is_empty() and preview.global_transform.is_equal_approx(slot.get_pose()), "Only rack targets copy a complete fixed marker pose.")
		expected = carry.check_placement(slot, state)
	else:
		check(not preview.current_surface.is_empty() and preview.result.slot_id.is_empty(), "Free basin positions must not use or invent an occupied slot.")
		if preview.current_surface.is_empty():
			return
		var hit: Dictionary = targeting.query_placement_surface()
		check(not hit.is_empty() and Vector2(preview.global_position.x, preview.global_position.z).distance_to(Vector2(hit.position.x, hit.position.z)) < 0.00002, "Free positions must follow the actual crosshair hit without snapping to a preset point.")
		check(router.target in [GameInput.Target.PLACEMENT_SURFACE, GameInput.Target.STACKABLE_DISH] and targeting.current_slot == null, "Free placement needs its own input context, with no fixed temporary slot.")
		expected = carry.check_surface_placement(hit, state)
	check(preview.result.code == expected.code and preview.result.dish_id == expected.dish_id and preview.result.hand_index == expected.hand_index and preview.result.pose.is_equal_approx(expected.pose), "The selected hand and current shared rules must determine the whole preview.")
	check(hint.visible and hint.text == preview.result.get_reason(), "HUD must explain the same decision as the preview.")
	var color: Color = (preview.get_child(0).material_override as StandardMaterial3D).albedo_color
	check(color == (PlacementPreview.VALID_COLOR if preview.result.is_valid else PlacementPreview.INVALID_COLOR), "Valid/invalid previews need distinct colors plus text.")

func expect_hidden(context: String) -> void:
	check(not preview.visible and preview.current_slot == null and preview.current_surface.is_empty() and preview.result == null and not hint.visible, context)

func check_free_geometry() -> void:
	# Independent real-mesh edge rays and support gaps, not another rules call.
	var item: HandItem = carry.get_selected_dish_item()
	var pose: Transform3D = preview.global_transform
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var faces: PackedVector3Array = item.get_placement_faces()
	var clear: bool = true
	for index in range(0, faces.size(), 3):
		for edge in 3:
			var ray := PhysicsRayQueryParameters3D.create(pose * faces[index + edge], pose * faces[index + (edge + 1) % 3], MeshSurfaceCollision.QUERY_MASK, targeting.excluded_bodies)
			if not space.intersect_ray(ray).is_empty():
				clear = false
	check(clear, "The free preview's formal surface must not intersect the basin, drain, wall or another dish.")
	var gap: float = INF
	for local_point in item.get_support_points():
		var point: Vector3 = pose * local_point
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.0001, point - Vector3.UP * 0.025, MeshSurfaceCollision.QUERY_MASK, targeting.excluded_bodies)
		var hit: Dictionary = space.intersect_ray(ray)
		if registry.is_basin_hit(hit):
			gap = minf(gap, point.y - (hit.position as Vector3).y)
	check(gap >= 0.0002 and gap <= 0.001, "Free preview must rest about 0.5 mm above actual support, rather than hover at the old marker height.")

func verify() -> void:
	await prepare()
	check(registry.slots.size() == 11 and not registry.slots.has(&"Sink_Plate_01") and not registry.slots.has(&"Sink_Mug_01") and registry.get_child_count() == 0, "Production basin fixed slots and visible markers must be removed.")
	var at := Vector2(-0.22, 0.025)
	await look_at_basin(at)
	expect_hidden("Empty hands must not display a dish preview.")
	var plate := game.get_node("PlayableDishes/TrayPlate01") as DishBody
	var mug := game.get_node("PlayableDishes/TrayMug01") as DishBody
	await stand(Vector3(0, 0.03, 0.8))
	await aim(plate)
	click()
	await look_at_basin(at)
	expect_preview(PlacementResult.Code.OK, "Free plate position")
	check_free_geometry()
	var original_mesh := plate.find_child("Plate_Surface", true, false) as MeshInstance3D
	check(preview.get_child(0).mesh == original_mesh.mesh and original_mesh.material_override == null, "Ghosts reuse formal meshes without changing real materials.")
	check(preview.find_children("*", "CollisionObject3D", true, false).is_empty() and preview.find_children("*", "CollisionShape3D", true, false).is_empty(), "Ghosts must have no physics or query bodies.")
	var real_hit: Dictionary = targeting.query_surface()
	preview.visible = false
	var hidden_hit: Dictionary = targeting.query_surface()
	preview.visible = true
	check(real_hit.get("collider") == hidden_hit.get("collider") and real_hit.get("position") == hidden_hit.get("position") and targeting.query_dish() == null, "A preview must never change ray hits or become a pickup target.")
	var held_pose: Transform3D = plate.global_transform
	tap(&"game_return")
	check(carry.held_count() == 1 and plate.global_transform.is_equal_approx(held_pose), "Preview and the unimplemented Q return must not move the real dish.")
	for x: float in [-0.25, -0.18, -0.12, 0.12, 0.18, 0.25]:
		for z: float in [-0.025, 0.04, 0.08]:
			await look_at_basin(Vector2(x, z))
			expect_preview(PlacementResult.Code.OK, "Arbitrary basin plate point " + str(Vector2(x, z)))
	check(registry.slots[&"Dirty_Plate_01"].is_empty() and not registry.slots[&"Dirty_Plate_02"].is_empty() and not registry.slots[&"Dirty_Mug_01"].is_empty(), "Free previews must not change any dish occupancy after pickup.")
	await look_at_basin(at + Vector2(0.011, 0.007))
	expect_preview(PlacementResult.Code.OK, "Small cursor movements must produce a different continuous position")
	check(Vector2(preview.global_position.x, preview.global_position.z).distance_to(at) > 0.01, "Do not quantize positions or silently reuse the old two points.")
	# The same basin point supports both dish types; no separate plate/cup zone.
	await stand(Vector3(0, 0.03, 0.8))
	await aim(mug)
	click()
	await look_at_basin(at)
	expect_preview(PlacementResult.Code.OK, "The first selected dish remains selected after the second pickup")
	tap(&"game_tool_sponge")
	await ticks()
	expect_preview(PlacementResult.Code.OK, "The right-hand mug uses the same free point")
	check(preview.result.dish_id == mug.instance_id and preview.get_child_count() == 2, "Key 2 must preview the actual mug including its handle.")
	check_free_geometry()
	for x: float in [-0.25, -0.12, 0.12, 0.25]:
		for z: float in [-0.025, 0.04, 0.08]:
			await look_at_basin(Vector2(x, z))
			expect_preview(PlacementResult.Code.OK, "Arbitrary basin mug point " + str(Vector2(x, z)))
	var rack: KitchenSlot = registry.slots[&"Rack_Cup_Slot_01"]
	await look_at_slot(rack)
	expect_preview(PlacementResult.Code.MISSING_STATE, "Unknown cleanliness cannot authorize rack placement", rack)
	var state: DishState = make_state(mug)
	carry.dish_states[mug.instance_id] = state
	await ticks()
	expect_preview(PlacementResult.Code.OK, "Known 95 percent state injected only by the test", rack)
	check(preview.global_basis.y.dot(Vector3.UP) < -0.99, "Fixed cup rack slots retain their inverted pose.")
	state.stain_regions[&"known_stain"].remaining_amount = 51.0
	await ticks()
	expect_preview(PlacementResult.Code.DIRTY, "Actual 94.9 percent remains invalid", rack)
	state.stain_regions[&"known_stain"].remaining_amount = 50.0
	state.stain_regions[&"known_stain"].foam_amount = 1.0
	rack.state.occupant_id = &"late_occupant"
	await ticks()
	expect_preview(PlacementResult.Code.OCCUPIED, "Rack occupancy changes are immediate", rack)
	rack.state.occupant_id = &""
	carry.dish_states[plate.instance_id] = make_state(plate)
	for slot: KitchenSlot in registry.slots.values():
		if slot.config.slot_kind != SlotConfig.Kind.DRAINING_RACK:
			continue
		tap(&"game_tool_sponge" if slot.accepts(&"mug") else &"game_tool_none")
		await look_at_slot(slot)
		expect_preview(PlacementResult.Code.OK, "All eight fixed rack positions", slot)
		check(slot.is_empty(), "Previewing a rack slot must not reserve it.")
	tap(&"game_tool_sponge")
	await look_at_slot(registry.slots[&"Rack_Slot_01"])
	expect_preview(PlacementResult.Code.INCOMPATIBLE, "Rack slots retain their dish type restrictions", registry.slots[&"Rack_Slot_01"])
	# Tray markers initialize dishes but are no longer fixed preview targets.
	await look_at_slot(registry.slots[&"Dirty_Plate_01"])
	expect_hidden("Only the rack has fixed placement targets.")
	tap(&"game_tool_none")
	await look_at_basin(at)
	var point: Vector3 = targeting.query_placement_surface().position
	var prior_hit: Dictionary = targeting.query_placement_surface()
	var wall: StaticBody3D = make_blocker(camera.global_position.lerp(point, 0.5), Vector3.ONE * 0.2)
	await ticks()
	expect_hidden("A cabinet or wall must block free placement behind it.")
	expect_code(carry.check_surface_placement(prior_hit), PlacementResult.Code.NOT_VISIBLE, "An old valid surface hit cannot bypass a new occluder")
	wall.free()
	await ticks()
	var foreground := (load("res://Scenes/Dishes/plate.tscn") as PackedScene).instantiate() as DishBody
	foreground.instance_id = &"preview_occluding_dish"
	game.add_child(foreground)
	foreground.global_transform = Transform3D(camera.global_basis * Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), camera.global_position.lerp(point, 0.5))
	await ticks()
	expect_hidden("A real foreground dish must take priority over a hidden basin surface.")
	check(targeting.current_dish == foreground and targeting.current_slot == null, "The first real dish remains the world target.")
	foreground.free()
	await ticks()
	var obstacle: StaticBody3D = make_blocker(preview.global_transform * Vector3(0.085, 0, 0), Vector3.ONE * 0.02)
	await ticks()
	expect_preview(PlacementResult.Code.NO_SPACE, "Off-ray intersections invalidate the actual final mesh")
	obstacle.free()
	await ticks()
	expect_preview(PlacementResult.Code.OK, "Removing an obstruction restores the free preview")
	var spare := game.get_node("PlayableDishes/TrayPlate02") as DishBody
	var spare_pose: Transform3D = spare.global_transform
	spare.global_transform = preview.global_transform
	spare.global_position.x += 0.18
	await ticks()
	expect_preview(PlacementResult.Code.NO_SPACE, "A registered dish outside basin placement must not become a stack support")
	spare.global_transform = spare_pose
	await ticks()
	await look_at_basin(Vector2(-0.25, -0.08))
	expect_preview(PlacementResult.Code.NO_SPACE, "A plate cannot intersect the rising back wall")
	await look_at_basin(Vector2(-0.25, -0.19))
	expect_preview(PlacementResult.Code.UNSUPPORTED, "A steep interior wall is not stable bottom support")
	await look_at_basin(at)
	prior_hit = targeting.query_placement_surface()
	await stand(Vector3(at.x, 0.03, 2.2))
	camera.look_at(point)
	await ticks()
	expect_hidden("Walking beyond reach must hide the preview.")
	expect_code(carry.check_surface_placement(prior_hit), PlacementResult.Code.OUT_OF_RANGE, "Shared free rules retain interaction range")
	await look_at_basin(at)
	camera.look_at(camera.global_position + Vector3.FORWARD)
	await ticks()
	expect_hidden("Looking away must clear the free position.")
	await look_at_basin(at)
	router.set_interface_open(true)
	expect_hidden("Opening UI clears the preview immediately.")
	expect_code(carry.check_surface_placement(prior_hit), PlacementResult.Code.INPUT_BLOCKED, "UI blocks shared free placement checks")
	router.set_interface_open(false)
	await ticks()
	expect_preview(PlacementResult.Code.OK, "Resume reacquires the current free position")
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect_hidden("Focus loss clears the preview immediately.")
	router.set_interface_open(false)
	await ticks()
	expect_preview(PlacementResult.Code.OK, "Focus recovery queries again")
	await prepare()
	plate = game.get_node("PlayableDishes/TrayPlate01") as DishBody
	await aim(plate)
	click()
	var tool := game.find_child("SpongeTool", true, false) as CleaningTool
	await aim(tool)
	tap(&"game_interact")
	await look_at_basin(at)
	expect_preview(PlacementResult.Code.OK, "Both held dish and tool are excluded from free surface queries")
	tap(&"game_toggle_close")
	expect_hidden("F transition clears world preview immediately.")
	await ticks(18)
	expect_hidden("Immersion owns its own surface targeting.")
	check(router.hand_mode == GameInput.HandMode.CLOSE_UP, "Free placement must preserve F immersion.")
	tap(&"game_toggle_close")
	await ticks(18)
	await look_at_basin(at)
	expect_preview(PlacementResult.Code.OK, "F restores free basin targeting")
	game.free()
	var viewer := (load("res://Scenes/kitchen-demo.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(viewer)
	check(viewer.get_node_or_null("PlacementPreview") == null and viewer.get_node_or_null("KitchenSlots") == null, "The asset viewer remains unchanged.")
	viewer.free()
	if failures == 0:
		print("PLACEMENT_PREVIEW_OK: continuous free basin poses, real support/space, 8 fixed rack targets, selected formal meshes, occlusion, no reservations and F recovery.")
		quit(0)
	else:
		push_error("PLACEMENT_PREVIEW_FAILED: %d check(s) failed." % failures)
		quit(1)
