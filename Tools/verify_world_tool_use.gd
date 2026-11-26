extends "res://Tools/verify_dual_wield.gd"
## Import first, then: godot --headless --path . --script Tools/verify_world_tool_use.gd
## Ordinary cleaning uses a held tool and first-hit world surfaces, without F.

func verify() -> void:
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		await load_game()
		var dish := game.get_node("PlayableDishes/TrayPlate01") as DishBody
		var mug := game.get_node("PlayableDishes/TrayMug01") as DishBody
		var tool := game.find_child("SpongeTool" if kind == ToolState.Tool.SPONGE else "SprayerTool", true, false) as CleaningTool
		await aim(tool)
		tap(&"game_interact")
		await ticks(12)
		check(carry.held_tool() == tool, "The original world tool must be held before cleaning.")
		await aim(dish)
		var source: KitchenSlot = registry.find_occupied_slot(dish.instance_id)
		var dish_pose: Transform3D = dish.global_transform
		var camera_pose: Transform3D = camera.global_transform
		button(MOUSE_BUTTON_LEFT, true)
		await ticks(4)
		check(carry.contact_active and carry.contact_dish == dish, "Holding left mouse must operate a tool on a placed dish without entering immersion.")
		check(carry.held_count() == 1 and source.state.occupant_id == dish.instance_id and dish.global_transform.is_equal_approx(dish_pose), "Tool use must never pick up, move or release the aimed dish's occupancy.")
		check(router.hand_mode == GameInput.HandMode.CARRYING and camera.global_transform.is_equal_approx(camera_pose), "Ordinary operation must preserve the camera and carrying mode.")
		var before: Basis = tool.global_basis
		await ticks(4)
		check(carry.contact_active, "An ordinary held tool must keep operating while the button is held.")
		if kind == ToolState.Tool.SPONGE:
			check(tool.global_basis.y.dot(carry.contact_normal) > 0.99 and not tool.global_basis.is_equal_approx(before), "The sponge must visibly scrub tangent to the actual surface.")
		else:
			var nozzle := tool.find_child("Spray_Nozzle_Point", true, false) as Node3D
			check(nozzle.global_basis.y.dot((carry.contact_point - nozzle.global_position).normalized()) > 0.999, "The real sprayer nozzle must aim at the world contact.")
			check_sprayer_hose(tool)
		action(&"game_move_right", true)
		var player_start: Vector3 = player.global_position
		await ticks(2)
		action(&"game_move_right", false)
		check(player.global_position.x > player_start.x, "WASD must remain available while using a tool in ordinary mode.")
		motion(Vector2(640, 360), Vector2(1, 0))
		motion(Vector2(640, 360), Vector2(2, 0))
		check(not camera.global_transform.is_equal_approx(camera_pose), "Mouse motion during tool use must still aim the camera.")
		await aim(mug)
		await ticks()
		check(carry.contact_active and carry.contact_dish == mug, "A held use button must follow the first newly aimed dish, including its cup interior.")
		camera.look_at(camera.global_position + Vector3.FORWARD)
		await ticks()
		check(not carry.contact_active, "Aiming off dishes must stop contact without operating on the environment.")
		await aim(dish)
		await ticks()
		check(carry.contact_active, "Sweeping back to a real dish while holding the button must resume contact without another click.")
		button(MOUSE_BUTTON_LEFT, false)
		await ticks()
		check(not carry.contact_active and tool.global_transform.is_equal_approx(carry.hands[0].safe_pose), "Releasing use must restore the same hand's safe carry pose.")
		# The first environment surface must occlude cleaning even with stale HUD data.
		var blocker := StaticBody3D.new()
		blocker.collision_layer = MeshSurfaceCollision.ENVIRONMENT_LAYER
		blocker.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.3, 0.3, 0.03)
		shape.shape = box
		blocker.add_child(shape)
		game.add_child(blocker)
		blocker.global_transform = Transform3D(camera.global_basis, camera.global_position + (dish.global_position - camera.global_position) * 0.5)
		await ticks()
		button(MOUSE_BUTTON_LEFT, true)
		await ticks()
		check(not carry.contact_active, "A foreground environment surface must block world cleaning.")
		blocker.free()
		await ticks()
		check(carry.contact_active, "Removing an occluder must restore a still-held world tool use.")
		# UI and focus clear the use intention, rather than resuming a stale hold.
		for focus_loss in [false, true]:
			if focus_loss:
				router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			else:
				tap(&"game_menu")
			await ticks()
			check(not carry.contact_active and router.interface_open, "Menus and focus loss must immediately stop ordinary tool contact.")
			router.set_interface_open(false)
			await ticks()
			check(not carry.contact_active, "Closing an interface must not resume old left-button use.")
			button(MOUSE_BUTTON_LEFT, false)
			button(MOUSE_BUTTON_LEFT, true)
			await ticks()
			check(carry.contact_active, "A fresh left press after resuming must operate normally.")
		button(MOUSE_BUTTON_LEFT, false)
		await stand(Vector3(0, 0.03, 2.2))
		await aim(dish)
		button(MOUSE_BUTTON_LEFT, true)
		await ticks()
		check(not carry.contact_active, "A dish beyond world interaction range must not receive tool contact.")
		button(MOUSE_BUTTON_LEFT, false)
		await stand(Vector3(0, 0.03, 0.8))
		await aim(dish)
		button(MOUSE_BUTTON_LEFT, true)
		await ticks()
		tap(&"game_interact")
		button(MOUSE_BUTTON_LEFT, false)
		await ticks()
		check(carry.held_count() == 2 and carry.hands[0].node == tool and carry.hands[1].node == dish, "E must pick up a targeted dish into the free hand while retaining the tool's hand.")
		tap(&"game_toggle_close")
		await ticks(18)
		check(router.hand_mode == GameInput.HandMode.CLOSE_UP and not carry.contact_active, "F must still enter immersive mode and clear ordinary use.")
		tap(&"game_toggle_close")
		await ticks(18)
		check(router.hand_mode == GameInput.HandMode.CARRYING, "F must still restore ordinary carrying.")
		# A tool in the right hand must also operate without moving the left dish.
		await load_game()
		dish = game.get_node("PlayableDishes/TrayPlate01") as DishBody
		mug = game.get_node("PlayableDishes/TrayMug01") as DishBody
		tool = game.find_child("SpongeTool" if kind == ToolState.Tool.SPONGE else "SprayerTool", true, false) as CleaningTool
		await aim(dish)
		click()
		await aim(tool)
		tap(&"game_interact")
		await ticks(12)
		await aim(mug)
		button(MOUSE_BUTTON_LEFT, true)
		await ticks()
		check(carry.contact_active and carry.contact_dish == mug and carry.hands[0].node == dish and carry.hands[1].node == tool, "Right-hand tools must clean world dishes while the left-hand dish keeps its identity and hand.")
		button(MOUSE_BUTTON_LEFT, false)
	game.free()
	if failures == 0:
		print("WORLD_TOOL_USE_OK: world contact, continuous aiming, movement, occlusion, interruption and F coexistence.")
		quit(0)
	else:
		push_error("WORLD_TOOL_USE_FAILED: %d check(s) failed." % failures)
		quit(1)
