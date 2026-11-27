extends "res://Tools/verify_dish_manipulation.gd"
## Headless: godot --headless --path . --script Tools/verify_immersion_focus.gd
## Rendered QA/timing: godot --path . --script Tools/verify_immersion_focus.gd -- --capture

var focus: ImmersionFocus
var save_images: bool = false

func visual_layers() -> Dictionary:
	var result: Dictionary = {}
	for node: VisualInstance3D in game.find_children("*", "VisualInstance3D", true, false):
		result[node] = node.layers
	return result

func check_restored(before: Dictionary, mask: int) -> void:
	check(not focus.active and focus.focus_amount < 0.001 and camera.cull_mask == mask, "Leaving immersion must restore the original camera mask and clear focus.")
	check(not focus.background.visible and not focus.foreground.visible and focus.foreground_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Ordinary mode must stop the extra render pass and hide both overlays.")
	for node: VisualInstance3D in before:
		check(is_instance_valid(node) and node.layers == before[node], "Exit must restore every original mesh/light layer exactly.")

func resume_by_click() -> void:
	var resume := game.get_node("GameHUD/Menu/Center/Panel/Margin/Rows/Resume") as Button
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = resume.get_global_rect().get_center()
		root.push_input(event, true)
	await ticks()
	check(not router.interface_open, "The focus overlays must not intercept an actual resume-button click.")

func verify_focus_state() -> void:
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for tool_first in [false, true]:
			if not await pair("TrayMug01" if tool_first else "TrayPlate01", kind, tool_first):
				return
			focus = game.get_node("ImmersionFocus") as ImmersionFocus
			await pose_at(Vector3(0, 0.03, 0.9), 0, -15)
			var original_layers: Dictionary = visual_layers()
			var mask: int = camera.cull_mask
			var view: Transform3D = camera.global_transform
			var player_pose: Transform3D = player.global_transform
			var fov: float = camera.fov
			var dish: DishBody = carry.held_dish
			var tool: CleaningTool = carry.held_tool()
			var identity: int = dish.get_instance_id()
			var rid: RID = dish.get_rid()
			check_restored(original_layers, mask)
			check(focus.layer < (game.get_node("GameHUD") as CanvasLayer).layer and focus.background.mouse_filter == Control.MOUSE_FILTER_IGNORE and focus.foreground.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HUD and gameplay input must remain above non-interactive focus overlays.")
			tap(&"game_toggle_close")
			await ticks(3)
			check(focus.active and focus.focus_amount > 0.0 and focus.focus_amount < 1.0, "A successful F entry must fade focus in during the existing transition.")
			tap(&"game_toggle_close")
			tap(&"game_drop")
			await wait_transition()
			await ticks(2)
			check(focus.active and is_equal_approx(focus.focus_amount, 1.0), "Immersive focus must finish and persist without re-tweening on surface target changes.")
			check(focus.foreground_viewport.world_3d == camera.get_world_3d() and camera.get_viewport().get_camera_3d() == camera, "The transparent pass must share the same original world without stealing the player camera.")
			check(focus.foreground_camera.global_transform.is_equal_approx(view) and focus.foreground_camera.fov == fov and focus.foreground_camera.near == camera.near and focus.foreground_camera.far == camera.far, "The foreground camera must exactly match source projection and transform.")
			for item: HandItem in carry.hands:
				for mesh: GeometryInstance3D in item.node.find_children("*", "GeometryInstance3D", true, false):
					check(mesh.layers == ImmersionFocus.FOREGROUND_LAYER and (camera.cull_mask & mesh.layers) == 0, "Original held geometry must be omitted from the blur source and rendered sharply once.")
			for light: Light3D in game.find_children("*", "Light3D", true, false):
				check((light.layers & focus.foreground_camera.cull_mask) != 0, "Both passes must see the original scene lighting.")
			check_pair(dish, tool, 1 if tool_first else 0, identity, rid)
			check_view(player_pose, view, fov)
			var center: Vector2 = root.get_visible_rect().size * 0.5
			motion(center)
			await ticks()
			button(MOUSE_BUTTON_LEFT, true)
			motion(center + Vector2(2, 0))
			await ticks(1)
			check(carry.contact_active and carry.contact_dish == dish, "Visual layering must not alter the real held-dish ray or tool use.")
			button(MOUSE_BUTTON_LEFT, false)
			for focus_loss in [false, true]:
				if focus_loss:
					router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
				else:
					tap(&"game_menu")
				await ticks()
				check(focus.active and is_equal_approx(focus.focus_amount, 1.0), "Menus/focus loss must keep the immersive scene focused without consuming UI.")
				await resume_by_click()
				check(not carry.contact_active, "Resuming a focused view must not resume old use.")
			tap(&"game_toggle_close")
			await ticks(3)
			check(focus.active and focus.focus_amount > 0.0 and focus.focus_amount < 1.0, "F exit must fade background focus out during the return.")
			await wait_transition()
			await ticks(2)
			check_restored(original_layers, mask)
			check_pair(dish, tool, 1 if tool_first else 0, identity, rid)
			print("FOCUS_STATE_CASE_OK: ", kind, " tool_first=", tool_first)
	# Rejected entry must never change visual layers or enable the render pass.
	if not await pair("TrayPlate01", ToolState.Tool.SPONGE, false):
		return
	focus = game.get_node("ImmersionFocus") as ImmersionFocus
	await pose_at(Vector3(1.8, 0.03, -0.05), 0, 0)
	var original_layers: Dictionary = visual_layers()
	var mask: int = camera.cull_mask
	tap(&"game_toggle_close")
	await ticks()
	check(router.hand_mode == GameInput.HandMode.CARRYING, "The real wall fixture must reject F.")
	check_restored(original_layers, mask)
	await pose_at(Vector3(0, 0.03, 0.9), 0, -15)
	for entering in [true, false]:
		tap(&"game_toggle_close")
		await ticks(3)
		router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await wait_transition()
		await ticks(2)
		check(focus.active == entering, "Entry/exit focus interruptions must preserve the F destination.")
		await resume_by_click()
	check_restored(original_layers, mask)

func rendered_frame(filename: String = "") -> Image:
	await ticks(5)
	await RenderingServer.frame_post_draw
	var result: Image = root.get_texture().get_image()
	check(not result.is_empty(), "Graphics QA must read a real rendered frame.")
	if save_images and not filename.is_empty():
		check(result.save_png("res://Temp/step17-" + filename + ".png") == OK, "Focus preview must save successfully.")
	return result

func compare_rendered(name: String) -> void:
	focus.focus_amount = 1.0
	var blurred: Image = await rendered_frame(name + "-blur")
	focus.focus_amount = 0.0
	var sharp: Image = await rendered_frame(name + "-sharp")
	var foreground: Image = focus.foreground_viewport.get_texture().get_image()
	check(foreground.get_size() == blurred.get_size(), "The sharp pass must match actual captured render pixels.")
	if foreground.get_size() != blurred.get_size():
		return
	var changed: int = 0
	var background_count: int = 0
	var interior_count: int = 0
	var interior_error: float = 0.0
	for y in range(4, blurred.get_height() - 4, 4):
		for x in range(4, blurred.get_width() - 4, 4):
			var a: Color = blurred.get_pixel(x, y)
			var b: Color = sharp.get_pixel(x, y)
			var alpha: float = foreground.get_pixel(x, y).a
			var difference: float = absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
			if alpha < 0.001 and y < int(blurred.get_height() * 0.8):
				background_count += 1
				if difference > 0.02:
					changed += 1
			elif alpha > 0.999 and foreground.get_pixel(x - 3, y).a > 0.999 and foreground.get_pixel(x + 3, y).a > 0.999:
				interior_count += 1
				interior_error += difference
	check(background_count > 1000 and changed > background_count * 0.08, "Background blur must measurably change actual kitchen pixels at every tested view/distance.")
	check(interior_count > 100 and interior_error / maxf(interior_count, 1) < 0.006, "Opaque dish/tool interiors must remain as sharp and colored as the zero-blur reference.")
	# Compare with the actual single-pass baseline to catch missing lights or dark alpha.
	focus._deactivate()
	var native: Image = await rendered_frame()
	var native_error: float = 0.0
	var native_count: int = 0
	var alpha_error: float = 0.0
	var alpha_count: int = 0
	for y in range(4, native.get_height() - 4, 4):
		for x in range(4, native.get_width() - 4, 4):
			if foreground.get_pixel(x, y).a > 0.999 and foreground.get_pixel(x - 3, y).a > 0.999 and foreground.get_pixel(x + 3, y).a > 0.999:
				var a: Color = sharp.get_pixel(x, y)
				var b: Color = native.get_pixel(x, y)
				native_error += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
				native_count += 1
			elif foreground.get_pixel(x, y).a > 0.1 and foreground.get_pixel(x, y).a < 0.9 and is_equal_approx(foreground.get_pixel(x - 3, y).a, foreground.get_pixel(x + 3, y).a):
				var a: Color = sharp.get_pixel(x, y)
				var b: Color = native.get_pixel(x, y)
				alpha_error += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
				alpha_count += 1
	check(native_error / maxf(native_count, 1) < 0.025, "Layer compositing must preserve original foreground lighting/colors.")
	if name.begins_with("alpha-"):
		check(alpha_count > 100 and alpha_error / maxf(alpha_count, 1) < 0.025, "Transparent materials must preserve the native single-pass blend without darkened edges.")
	focus._activate()
	focus.focus_amount = 1.0
	print("FOCUS_PIXELS_OK: ", name, " changed=", changed, "/", background_count, " foreground_error=", interior_error / maxf(interior_count, 1), " native_error=", native_error / maxf(native_count, 1))

func verify_graphics() -> void:
	root.size = Vector2i(1280, 720)
	for kind in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		if not await pair("TrayPlate01" if kind == ToolState.Tool.SPONGE else "TrayMug01", kind, kind == ToolState.Tool.SPRAYER):
			return
		focus = game.get_node("ImmersionFocus") as ImmersionFocus
		for station: Array in [[-0.8, 30.0], [0.0, 0.0], [0.8, -30.0]]:
			await pose_at(Vector3(station[0], 0.03, 0.9), station[1], -15)
			var view: Transform3D = camera.global_transform
			tap(&"game_toggle_close")
			await wait_transition()
			await ticks(12)
			check(focus.active, "Graphics fixtures must enter immersion at all three task views.")
			for closer in [true, false]:
				wheel(closer, 20)
				motion(root.get_visible_rect().size * Vector2(0.25, 0.35))
				await ticks()
				check(camera.global_transform.is_equal_approx(view), "Rendering blur must never change the task view.")
				await compare_rendered("%s-%s-%s" % [kind, station[0], "near" if closer else "far"])
			tap(&"game_toggle_close")
			await wait_transition()
			await ticks(3)
			check(not focus.active, "Leaving each graphics fixture must release render layers.")
	await verify_alpha_and_resize()
	await measure_render_cost()

func verify_alpha_and_resize() -> void:
	if not await pair("TrayMug01", ToolState.Tool.SPONGE, false):
		return
	focus = game.get_node("ImmersionFocus") as ImmersionFocus
	await pose_at(Vector3(0, 0.03, 0.9), 0, -15)
	var probe := MeshInstance3D.new()
	probe.name = "AlphaProbe"
	probe.mesh = QuadMesh.new()
	(probe.mesh as QuadMesh).size = Vector2(0.12, 0.10)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.2, 0.6, 0.9, 0.4)
	probe.material_override = material
	carry.held_dish.add_child(probe)
	tap(&"game_toggle_close")
	await wait_transition()
	await ticks(8)
	# Make the real handle aperture face the camera; it must contain background alpha.
	drag(MOUSE_BUTTON_MIDDLE, Vector2(0, PI / 2.0 / 0.01))
	probe.global_transform = Transform3D(camera.global_basis, camera.to_global(Vector3(-0.13, 0.07, -0.45)))
	motion(root.get_visible_rect().size * Vector2(0.85, 0.25))
	await ticks()
	for resolution in [Vector2i(1024, 768), Vector2i(1920, 1080)]:
		root.size = resolution
		await ticks(8)
		motion(root.get_visible_rect().size * Vector2(0.85, 0.2))
		await ticks(3)
		await compare_rendered("alpha-%s" % resolution.x)
		check(focus.foreground_viewport.size == root.get_texture().get_image().get_size(), "The sharp pass must match actual render pixels after resizing, including aspect ratio.")
		var image: Image = focus.foreground_viewport.get_texture().get_image()
		var point: Vector2 = focus.foreground_camera.unproject_position(carry.held_dish.to_global(Vector3(0.06, 0, 0)))
		check(image.get_pixelv(Vector2i(point)).a < 0.01, "The real cup handle aperture must stay transparent in the sharp pass.")
	probe.queue_free()
	await ticks()

func measure_render_cost() -> void:
	root.size = Vector2i(1920, 1080)
	var vsync: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await ticks(10)
	var source_rid: RID = root.get_viewport_rid()
	var sharp_rid: RID = focus.foreground_viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(source_rid, true)
	RenderingServer.viewport_set_measure_render_time(sharp_rid, true)
	var results: Dictionary = {}
	for enabled in [false, true]:
		if enabled:
			focus._activate()
			focus.focus_amount = 1.0
		else:
			focus._deactivate()
		await ticks(15)
		var cpu: float = 0.0
		var gpu: float = 0.0
		for frame in 30:
			await RenderingServer.frame_post_draw
			cpu += RenderingServer.get_frame_setup_time_cpu() + RenderingServer.viewport_get_measured_render_time_cpu(source_rid)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(source_rid)
			if enabled:
				cpu += RenderingServer.viewport_get_measured_render_time_cpu(sharp_rid)
				gpu += RenderingServer.viewport_get_measured_render_time_gpu(sharp_rid)
		results["focused" if enabled else "native"] = {"cpu_render_ms": cpu / 30.0, "gpu_render_ms": gpu / 30.0, "samples": 30}
	print("FOCUS_RENDER_TIMING_1080P: ", JSON.stringify(results), " (render work only, not full-game FPS)")
	if save_images:
		var file := FileAccess.open("res://Temp/step17-render-timing.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(results, "\t"))
	RenderingServer.viewport_set_measure_render_time(source_rid, false)
	RenderingServer.viewport_set_measure_render_time(sharp_rid, false)
	DisplayServer.window_set_vsync_mode(vsync)

func verify() -> void:
	save_images = OS.get_cmdline_user_args().has("--capture")
	await verify_focus_state()
	if DisplayServer.get_name() != "headless":
		await verify_graphics()
	else:
		print("FOCUS_GRAPHICS_SKIPPED: headless checks state/layers/input only.")
	game.free()
	await ticks()
	var viewer := (load("res://Scenes/kitchen-demo.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(viewer)
	await ticks()
	check(viewer.get_node_or_null("ImmersionFocus") == null, "The generated F6 viewer must remain isolated from gameplay focus.")
	viewer.free()
	await ticks()
	if failures == 0:
		print("IMMERSION_FOCUS_OK: focus transitions, original nodes/view, render layers, interruption and cleanup.")
		quit(0)
	else:
		push_error("IMMERSION_FOCUS_FAILED: %d check(s) failed." % failures)
		quit(1)
