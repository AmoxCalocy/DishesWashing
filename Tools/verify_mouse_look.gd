extends SceneTree
## Import first, then run:
## godot --headless --path . --script Tools/verify_mouse_look.gd
## Real cursor capture and Alt+Tab still require the interactive F5 check.

var failures: int = 0
var kitchen: Node3D
var player: PlayerController
var router: GameInput

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func advance_ticks(count: int) -> void:
	for _index in range(count):
		await physics_frame
	await process_frame

func send_motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.position = Vector2(400, 500)
	root.push_input(event, true)

func send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	root.push_input(event, true)

func send_button(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = Vector2(400, 500)
	root.push_input(event, true)

func send_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)

func angles() -> Vector2:
	return Vector2(player.rotation.y, player.view_camera.rotation.x)

func zero_look() -> void:
	player.rotation = Vector3.ZERO
	player.view_camera.rotation = Vector3.ZERO

func check_capture_reset(context: String) -> void:
	var before: Vector2 = angles()
	send_motion(Vector2(50000, -50000))
	check(angles().is_equal_approx(before), "%s: first capture motion must not jump the camera." % context)

func verify() -> void:
	var packed := load("res://Scenes/kitchen-game.tscn") as PackedScene
	if packed == null:
		push_error("Could not load the gameplay scene.")
		quit(1)
		return
	kitchen = packed.instantiate() as Node3D
	root.add_child(kitchen)
	player = kitchen.get_node("Player") as PlayerController
	router = kitchen.get_node("GameInput") as GameInput
	await advance_ticks(8)
	check_capture_reset("Startup")
	var before: Vector2 = angles()
	var initial_position: Vector3 = player.global_position
	send_motion(Vector2(100, -40))
	check(absf(player.rotation.y - before.x + 0.25) < 0.00001, "Moving the mouse right must turn right without holding a button.")
	check(absf(player.view_camera.rotation.x - before.y - 0.1) < 0.00001, "Moving the mouse up must look up.")
	check(player.global_position.is_equal_approx(initial_position), "Looking must not move the player.")
	check(is_zero_approx(player.rotation.z) and is_zero_approx(player.view_camera.rotation.z), "Mouse look must not roll the view.")

	zero_look()
	send_motion(Vector2(PI / player.look_sensitivity, 0))
	check((-player.view_camera.global_basis.z).dot(Vector3.BACK) > 0.9999, "Horizontal look must allow turning around.")
	send_motion(Vector2(PI / player.look_sensitivity, 0))
	check((-player.view_camera.global_basis.z).dot(Vector3.FORWARD) > 0.9999, "Horizontal look must allow a full turn.")
	send_motion(Vector2(TAU * 3.0 / player.look_sensitivity, 0))
	check((-player.view_camera.global_basis.z).dot(Vector3.FORWARD) > 0.9999, "Horizontal look must support repeated full turns.")
	send_motion(Vector2(0, -100000))
	check(absf(player.view_camera.rotation.x - deg_to_rad(80.0)) < 0.00001, "Upward pitch must stop at 80 degrees.")
	send_motion(Vector2(0, -100000))
	check(absf(player.view_camera.rotation.x - deg_to_rad(80.0)) < 0.00001, "Pitch must not flip after repeated upward motion.")
	send_motion(Vector2(0, 100000))
	check(absf(player.view_camera.rotation.x + deg_to_rad(80.0)) < 0.00001, "Downward pitch must stop at -80 degrees.")

	zero_look()
	send_motion(Vector2(40, 20))
	var combined: Vector2 = angles()
	zero_look()
	send_motion(Vector2(20, 10))
	send_motion(Vector2(20, 10))
	check(angles().is_equal_approx(combined), "Splitting a mouse displacement must not change the total turn.")
	for mode in [GameInput.HandMode.EMPTY, GameInput.HandMode.CARRYING, GameInput.HandMode.SOAP_BOTTLE]:
		router.set_context(mode, GameInput.Target.NONE)
		zero_look()
		send_motion(Vector2(20, 0))
		check(absf(player.rotation.y + 0.05) < 0.00001, "Empty hands, carrying and soap must allow direct look.")
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE, ToolState.Tool.SPONGE)
	zero_look()
	send_motion(Vector2(20, 0))
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.DISH, ToolState.Tool.SPONGE)
	send_motion(Vector2(20, 0))
	check(absf(player.rotation.y + 0.1) < 0.00001, "Target/tool updates must not keep discarding valid look motion.")

	router.set_context(GameInput.HandMode.CARRYING, GameInput.Target.NONE)
	before = angles()
	send_button(MOUSE_BUTTON_MIDDLE, true)
	send_motion(Vector2(300, 200))
	check(angles().is_equal_approx(before), "Middle-button dish rotation must not turn the camera.")
	send_button(MOUSE_BUTTON_MIDDLE, false)
	send_motion(Vector2(20, 0))
	check(absf(player.rotation.y - before.x + 0.05) < 0.00001, "Releasing dish rotation must restore mouse look.")
	for mode in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]:
		router.set_context(mode, GameInput.Target.DISH, ToolState.Tool.SPONGE)
		before = angles()
		send_motion(Vector2(10000, 10000))
		check(angles().is_equal_approx(before), "Close-up and transitions must preserve the camera heading.")
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE)
	check_capture_reset("Leaving close-up/transition")
	send_motion(Vector2(20, 0))
	check(absf(player.rotation.y - before.x + 0.05) < 0.00001, "Leaving a locked mode must restore direct look after capture reset.")

	# Right mouse zooms eligible normal views; dishes rotate with middle drag.
	var normal_fov: float = player.view_camera.fov
	for mode in [GameInput.HandMode.EMPTY, GameInput.HandMode.SOAP_BOTTLE]:
		router.set_context(mode, GameInput.Target.NONE)
		var camera_position: Vector3 = player.view_camera.position
		var body_position: Vector3 = player.global_position
		send_button(MOUSE_BUTTON_RIGHT, true)
		check(player.view_camera.fov < normal_fov, "Holding right mouse must zoom the view when hands are empty or holding soap.")
		check(player.view_camera.position.is_equal_approx(camera_position) and player.global_position.is_equal_approx(body_position), "View zoom must not move the camera or player.")
		send_button(MOUSE_BUTTON_RIGHT, true)
		send_button(MOUSE_BUTTON_RIGHT, false)
		check(is_equal_approx(player.view_camera.fov, normal_fov), "Releasing right mouse must restore the original FOV, even after duplicate press events.")
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE)
	send_button(MOUSE_BUTTON_RIGHT, true)
	var zoomed_fov: float = player.view_camera.fov
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.FAUCET)
	check(is_equal_approx(player.view_camera.fov, zoomed_fov), "Updating the aimed target must not cancel a held zoom.")
	before = angles()
	send_motion(Vector2(20, 0))
	check(absf(player.rotation.y - before.x + 0.05) < 0.00001, "Mouse look must remain available while zooming.")
	router.set_interface_open(true)
	check(is_equal_approx(player.view_camera.fov, normal_fov), "Opening the menu must cancel view zoom.")
	router.set_interface_open(false)
	check(is_equal_approx(player.view_camera.fov, normal_fov), "Resuming must not restore an old held zoom.")
	send_button(MOUSE_BUTTON_RIGHT, false)
	send_button(MOUSE_BUTTON_RIGHT, true)
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(is_equal_approx(player.view_camera.fov, normal_fov), "Focus loss must restore the original FOV.")
	router.set_interface_open(false)
	send_button(MOUSE_BUTTON_RIGHT, false)
	check(is_equal_approx(player.view_camera.fov, normal_fov), "A stale right-button release must not change the restored FOV.")
	send_button(MOUSE_BUTTON_RIGHT, true)
	router.set_context(GameInput.HandMode.CARRYING, GameInput.Target.NONE)
	check(is_equal_approx(player.view_camera.fov, normal_fov), "Picking up a dish must end view zoom.")
	for mode in [GameInput.HandMode.CARRYING, GameInput.HandMode.CLOSE_UP]:
		router.set_context(mode, GameInput.Target.DISH)
		send_button(MOUSE_BUTTON_RIGHT, true)
		check(is_equal_approx(player.view_camera.fov, normal_fov), "Dish rotation must not zoom the camera.")
		send_button(MOUSE_BUTTON_RIGHT, false)
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE)

	# The same input events turn the actual player while physics is walking it.
	router.set_interface_open(true)
	router.set_interface_open(false)
	check_capture_reset("Gameplay resume")
	zero_look()
	player.global_position = Vector3(0, 0.03, 2.0)
	player.velocity = Vector3.ZERO
	await advance_ticks(8)
	send_action(&"game_move_forward", true)
	send_motion(Vector2(-PI / 2.0 / player.look_sensitivity, 0))
	var start: Vector3 = player.global_position
	await advance_ticks(15)
	var displacement: Vector3 = player.global_position - start
	var distance: float = player.walk_speed * 15.0 / Engine.physics_ticks_per_second
	check(displacement.distance_to(Vector3(-distance, 0, 0)) < 0.04, "Walking must immediately follow the mouse-controlled heading.")
	send_motion(Vector2(PI / 2.0 / player.look_sensitivity, 0))
	start = player.global_position
	await advance_ticks(15)
	displacement = player.global_position - start
	check(displacement.distance_to(Vector3(0, 0, -distance)) < 0.04, "Walking and looking must work at the same time.")

	send_action(&"game_menu", true)
	send_action(&"game_menu", false)
	check(router.interface_open, "Esc action must enter interface mode.")
	before = angles()
	start = player.global_position
	send_motion(Vector2(10000, 10000))
	await advance_ticks(8)
	check(angles().is_equal_approx(before) and player.global_position.distance_to(start) < 0.005, "Menus must stop both walking and looking.")
	var resume := kitchen.get_node("GameHUD/Menu/Center/Panel/Margin/Rows/Resume") as Button
	resume.pressed.emit()
	check(not router.interface_open, "The continue button must explicitly resume gameplay input.")
	check_capture_reset("Menu resume")
	await advance_ticks(4)
	check(player.global_position.distance_to(start) < 0.005, "Resuming must not restore the old movement input.")
	send_motion(Vector2(20, -10))
	check(angles().distance_to(before + Vector2(-0.05, 0.025)) < 0.00001, "Small mouse motion must work normally after menu resume.")
	send_action(&"game_move_forward", false)
	send_action(&"game_move_right", true)
	await advance_ticks(4)
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	before = angles()
	start = player.global_position
	send_motion(Vector2(-10000, 10000))
	await advance_ticks(8)
	check(angles().is_equal_approx(before) and player.global_position.distance_to(start) < 0.005, "Focus loss must stop both walking and looking.")
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(router.interface_open, "Focus return must wait for explicit gameplay resume.")
	send_motion(Vector2(10000, 10000))
	check(angles().is_equal_approx(before), "Returning focus must not apply unfocused mouse motion.")
	resume.pressed.emit()
	check_capture_reset("Focus resume")
	send_motion(Vector2(20, 0))
	check(absf(player.rotation.y - before.x + 0.05) < 0.00001, "Mouse look must recover after focus resume.")
	await advance_ticks(4)
	check(player.global_position.distance_to(start) < 0.005, "Focus resume must not restore held walking input.")
	kitchen.free()

	# The separately loaded viewer must still require right-drag and use its presets.
	var viewer_scene := load("res://Scenes/kitchen-demo.tscn") as PackedScene
	if viewer_scene == null:
		push_error("Could not load the viewer scene.")
		quit(1)
		return
	var viewer := viewer_scene.instantiate() as Node3D
	root.add_child(viewer)
	var viewer_camera := viewer.get_node("ViewCamera") as Camera3D
	var viewer_before: Basis = viewer_camera.basis
	send_motion(Vector2(30, 15))
	check(viewer_camera.basis.is_equal_approx(viewer_before), "The viewer must not use direct mouse look.")
	send_button(MOUSE_BUTTON_RIGHT, true)
	send_motion(Vector2(30, 15))
	check(not viewer_camera.basis.is_equal_approx(viewer_before), "The viewer must retain right-drag look.")
	viewer.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	viewer_before = viewer_camera.basis
	send_motion(Vector2(30, 15))
	check(not viewer.get("dragging") and viewer_camera.basis.is_equal_approx(viewer_before), "The viewer must release right-drag on focus loss.")
	send_key(KEY_4)
	check(viewer.get("preset") == 4, "Viewer preset keys must remain available.")
	send_key(KEY_R)
	check(viewer.get("preset") == 1, "Viewer R reset must remain available.")
	viewer.free()
	if failures == 0:
		print("MOUSE_LOOK_OK: direct look, hold-to-zoom, yaw/pitch limits, walking, mode/focus recovery and viewer regression.")
		quit(0)
	else:
		push_error("MOUSE_LOOK_FAILED: %d check(s) failed." % failures)
		quit(1)
