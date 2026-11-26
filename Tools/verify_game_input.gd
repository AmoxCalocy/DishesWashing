extends SceneTree
## Import first, then run:
## godot --headless --path . --script Tools/verify_game_input.gd

var failures: int = 0
var viewport: SubViewport
var router: GameInput
var commands: Array[StringName] = []
var releases: Array[StringName] = []
var looks: Array[Vector2] = []
var rotations: Array[Vector2] = []
var rotation_axes: Array[float] = []
var cursors: Array[Vector2] = []
var ui_clicks: int = 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func send_key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	viewport.push_input(event, true)

func tap_key(code: Key) -> void:
	send_key(code, true)
	send_key(code, false)

func send_button(button: MouseButton, pressed: bool, position: Vector2 = Vector2(400, 500)) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	event.global_position = position
	if pressed and button == MOUSE_BUTTON_LEFT:
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	elif pressed and button == MOUSE_BUTTON_RIGHT:
		event.button_mask = MOUSE_BUTTON_MASK_RIGHT
	elif pressed and button == MOUSE_BUTTON_MIDDLE:
		event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	viewport.push_input(event, true)

func send_motion() -> void:
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(3, -2)
	event.position = Vector2(80, 90)
	viewport.push_input(event, true)

func expect_primary(mode: GameInput.HandMode, target: GameInput.Target, tool: ToolState.Tool, expected: StringName) -> void:
	router.set_context(mode, target, tool)
	commands.clear()
	releases.clear()
	send_button(MOUSE_BUTTON_LEFT, true)
	send_button(MOUSE_BUTTON_LEFT, true)
	var expected_commands: Array[StringName] = []
	if not expected.is_empty():
		expected_commands.append(expected)
	check(commands == expected_commands, "Primary input must resolve to exactly one intention: %s." % expected)
	send_button(MOUSE_BUTTON_LEFT, false)
	if expected in [&"wet_sponge", &"use_tool"]:
		check(releases == [expected], "Continuous input must release its original intention.")
	else:
		check(releases.is_empty(), "A one-shot intention must not repeat on release.")

func verify() -> void:
	var keys: Dictionary[StringName, int] = {
		&"game_move_forward": KEY_W, &"game_move_back": KEY_S,
		&"game_move_left": KEY_A, &"game_move_right": KEY_D,
		&"game_toggle_close": KEY_F, &"game_interact": KEY_E,
		&"game_tool_none": KEY_1, &"game_tool_sponge": KEY_2,
		&"game_tool_sprayer": KEY_3, &"game_return": KEY_Q,
		&"game_orders": KEY_TAB, &"game_menu": KEY_ESCAPE,
	}
	for action in keys:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		check(events.size() == 1 and events[0] is InputEventKey, "Missing or duplicate key binding: %s." % action)
		if events.size() == 1 and events[0] is InputEventKey:
			check((events[0] as InputEventKey).physical_keycode == keys[action], "Wrong physical key: %s." % action)
	var buttons: Dictionary[StringName, int] = {
		&"game_primary": MOUSE_BUTTON_LEFT, &"game_rotate": MOUSE_BUTTON_RIGHT,
		&"game_rotate_close": MOUSE_BUTTON_MIDDLE,
		&"game_zoom_in": MOUSE_BUTTON_WHEEL_UP, &"game_zoom_out": MOUSE_BUTTON_WHEEL_DOWN,
	}
	for action in buttons:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		check(events.size() == 1 and events[0] is InputEventMouseButton, "Missing or duplicate mouse binding: %s." % action)
		if events.size() == 1 and events[0] is InputEventMouseButton:
			check((events[0] as InputEventMouseButton).button_index == buttons[action], "Wrong mouse button: %s." % action)

	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 600)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	router = GameInput.new()
	router.name = "GameInput"
	viewport.add_child(router)
	router.command_requested.connect(func(command: StringName, pressed: bool) -> void:
		if pressed:
			commands.append(command)
		else:
			releases.append(command)
	)
	router.look_requested.connect(func(value: Vector2) -> void: looks.append(value))
	router.rotation_requested.connect(func(value: Vector2) -> void: rotations.append(value))
	router.rotation_axis_changed.connect(func(value: float) -> void: rotation_axes.append(value))
	router.tool_cursor_moved.connect(func(value: Vector2) -> void: cursors.append(value))
	await process_frame

	var directions: Dictionary[int, Vector2] = {
		KEY_W: Vector2(0, -1), KEY_S: Vector2(0, 1),
		KEY_A: Vector2(-1, 0), KEY_D: Vector2(1, 0),
	}
	for code in directions:
		send_key(code, true)
		check(router.get_movement_vector() == directions[code], "Incorrect WASD direction.")
		send_key(code, false)
		check(router.get_movement_vector() == Vector2.ZERO, "Movement key release was lost.")
	send_key(KEY_W, true)
	send_key(KEY_D, true)
	check(is_equal_approx(router.get_movement_vector().length(), 1.0), "Diagonal input must be normalized.")
	router.set_interface_open(true)
	check(router.get_movement_vector() == Vector2.ZERO, "Opening UI must clear held movement.")
	router.set_interface_open(false)
	check(router.get_movement_vector() == Vector2.ZERO, "Closing UI must not restore stale movement.")
	send_key(KEY_W, false)
	send_key(KEY_D, false)
	send_key(KEY_W, true)
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE, ToolState.Tool.SPONGE)
	check(router.get_movement_vector() == Vector2(0, -1), "Changing tool selection must not lose a held movement key.")
	send_key(KEY_W, false)

	expect_primary(GameInput.HandMode.EMPTY, GameInput.Target.DISH, ToolState.Tool.NONE, &"pickup_dish")
	expect_primary(GameInput.HandMode.EMPTY, GameInput.Target.WATER_STREAM, ToolState.Tool.SPONGE, &"wet_sponge")
	expect_primary(GameInput.HandMode.CARRYING, GameInput.Target.SLOT, ToolState.Tool.NONE, &"place_dish")
	expect_primary(GameInput.HandMode.CARRYING, GameInput.Target.PLACEMENT_SURFACE, ToolState.Tool.NONE, &"place_dish")
	expect_primary(GameInput.HandMode.CARRYING, GameInput.Target.STACKABLE_DISH, ToolState.Tool.NONE, &"place_dish")
	expect_primary(GameInput.HandMode.CLOSE_UP, GameInput.Target.DISH, ToolState.Tool.SPONGE, &"use_tool")
	expect_primary(GameInput.HandMode.SOAP_BOTTLE, GameInput.Target.DISH, ToolState.Tool.NONE, &"pump_soap")
	expect_primary(GameInput.HandMode.EMPTY, GameInput.Target.NONE, ToolState.Tool.NONE, &"")
	expect_primary(GameInput.HandMode.EMPTY, GameInput.Target.WATER_STREAM, ToolState.Tool.NONE, &"")
	expect_primary(GameInput.HandMode.CARRYING, GameInput.Target.DISH, ToolState.Tool.NONE, &"pickup_dish")
	for tool in [ToolState.Tool.SPONGE, ToolState.Tool.SPRAYER]:
		for target in [GameInput.Target.DISH, GameInput.Target.STACKABLE_DISH, GameInput.Target.NONE, GameInput.Target.CLEANING_TOOL]:
			expect_primary(GameInput.HandMode.CARRYING, target, tool, &"use_tool")
		for target in [GameInput.Target.SLOT, GameInput.Target.PLACEMENT_SURFACE]:
			expect_primary(GameInput.HandMode.CARRYING, target, tool, &"place_dish")
			router.carrying_dish = false
			expect_primary(GameInput.HandMode.CARRYING, target, tool, &"use_tool")
			router.carrying_dish = true
	expect_primary(GameInput.HandMode.EMPTY, GameInput.Target.CLEANING_TOOL, ToolState.Tool.NONE, &"pickup_tool")
	expect_primary(GameInput.HandMode.CARRYING, GameInput.Target.CLEANING_TOOL, ToolState.Tool.NONE, &"pickup_tool")
	expect_primary(GameInput.HandMode.CLOSE_UP, GameInput.Target.DISH, ToolState.Tool.NONE, &"")
	expect_primary(GameInput.HandMode.SOAP_BOTTLE, GameInput.Target.NONE, ToolState.Tool.NONE, &"")

	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.FAUCET)
	commands.clear()
	send_key(KEY_E, true)
	send_key(KEY_E, true, true)
	send_key(KEY_E, false)
	check(commands == [&"toggle_faucet"], "Holding E must not repeatedly toggle the faucet.")
	for mode in [GameInput.HandMode.CARRYING, GameInput.HandMode.CLOSE_UP]:
		router.set_context(mode, GameInput.Target.CLEANING_TOOL, ToolState.Tool.SPONGE)
		commands.clear()
		rotation_axes.clear()
		send_key(KEY_E, true)
		send_key(KEY_E, true, true)
		send_key(KEY_E, false)
		if mode == GameInput.HandMode.CARRYING:
			check(commands == [&"return_tool"], "E with a held tool must request its return once in ordinary carrying.")
		else:
			check(commands.is_empty() and rotation_axes == [1.0, 0.0], "E in close-up must rotate right until released without returning the tool.")
	router.set_context(GameInput.HandMode.CARRYING, GameInput.Target.SOAP_BOTTLE)
	commands.clear()
	tap_key(KEY_E)
	check(commands.is_empty(), "A carried dish must block picking up soap.")
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.SOAP_BOTTLE)
	tap_key(KEY_E)
	check(commands == [&"pickup_soap"], "Empty hands must allow picking up soap.")
	router.set_context(GameInput.HandMode.CARRYING, GameInput.Target.ORDER_BOARD)
	commands.clear()
	tap_key(KEY_E)
	check(commands == [&"show_orders"], "Aimed interaction with the order board must emit only its own command.")
	for mode in [GameInput.HandMode.CARRYING, GameInput.HandMode.CLOSE_UP, GameInput.HandMode.SOAP_BOTTLE]:
		router.set_context(mode, GameInput.Target.NONE)
		commands.clear()
		rotation_axes.clear()
		tap_key(KEY_Q)
		if mode == GameInput.HandMode.CLOSE_UP:
			check(commands.is_empty() and rotation_axes == [-1.0, 0.0], "Q in close-up must rotate left without leaving close-up.")
		else:
			var expected: StringName = &"return_dish" if mode == GameInput.HandMode.CARRYING else &"return_soap"
			check(commands == [expected], "Q outside close-up must preserve its held-item intention.")
	commands.clear()
	tap_key(KEY_F)
	tap_key(KEY_1)
	tap_key(KEY_2)
	tap_key(KEY_3)
	check(commands.is_empty(), "Holding soap must block close-up and other tools.")
	router.set_context(GameInput.HandMode.CARRYING, GameInput.Target.NONE)
	commands.clear()
	for code in [KEY_1, KEY_2, KEY_3, KEY_F, KEY_TAB, KEY_4, KEY_R]:
		tap_key(code)
	check(commands == [&"select_left_dish", &"select_right_dish", &"game_tool_sprayer", &"toggle_close", &"show_orders"], "Carrying 1/2 must select dish hands; other game keys emit intentions, never viewer commands.")

	send_motion()
	check(looks == [Vector2(3, -2)], "Mouse look must not require the right button.")
	send_button(MOUSE_BUTTON_RIGHT, true)
	send_motion()
	send_button(MOUSE_BUTTON_RIGHT, false)
	check(rotations == [Vector2(3, -2)] and looks.size() == 1, "Dish rotation must replace look input.")
	router.set_context(GameInput.HandMode.CLOSE_UP, GameInput.Target.DISH, ToolState.Tool.SPONGE)
	send_key(KEY_Q, true)
	send_key(KEY_E, true)
	check(router.get_dish_rotation_axis() == 0.0, "Opposing rotation keys must cancel.")
	send_key(KEY_Q, false)
	check(router.get_dish_rotation_axis() == 1.0, "Releasing Q must preserve a held E rotation.")
	send_key(KEY_E, false)
	send_motion()
	check(cursors == [Vector2(80, 90)] and looks.size() == 1, "Close-up motion must address the tool cursor, not look.")
	commands.clear()
	releases.clear()
	send_button(MOUSE_BUTTON_LEFT, true)
	send_button(MOUSE_BUTTON_RIGHT, true)
	send_motion()
	send_button(MOUSE_BUTTON_RIGHT, false)
	check(commands == [&"use_tool"] and releases.is_empty() and rotations.size() == 1, "Right mouse must not rotate, zoom or cancel tool use in close-up.")
	send_button(MOUSE_BUTTON_MIDDLE, true)
	send_motion()
	check(commands == [&"use_tool", &"rotate_dish"] and releases == [&"use_tool"] and rotations.size() == 2, "Middle drag must rotate the dish and interrupt tool use.")
	check(cursors.back() == Vector2(80, 90) and looks.size() == 1, "Middle dragging must keep the tool cursor moving without turning the camera.")
	send_button(MOUSE_BUTTON_RIGHT, true)
	send_button(MOUSE_BUTTON_RIGHT, false)
	send_motion()
	check(rotations.size() == 3, "An unrelated right-button release must not end a held middle drag.")
	router.set_interface_open(true)
	router.set_interface_open(false)
	send_button(MOUSE_BUTTON_MIDDLE, false)
	send_button(MOUSE_BUTTON_LEFT, false)
	send_motion()
	check(rotations.size() == 3 and releases == [&"use_tool", &"rotate_dish"], "Opening UI must clear middle rotation; resuming and stale releases must not restart it.")
	commands.clear()
	send_button(MOUSE_BUTTON_WHEEL_UP, true)
	send_button(MOUSE_BUTTON_WHEEL_UP, true)
	send_button(MOUSE_BUTTON_WHEEL_DOWN, true)
	check(commands == [&"game_zoom_in", &"game_zoom_in", &"game_zoom_out"], "Every close-up wheel pulse must be routed.")
	send_button(MOUSE_BUTTON_LEFT, true)
	releases.clear()
	send_key(KEY_Q, true)
	check(releases == [&"use_tool"], "Starting keyboard rotation must stop tool use immediately.")
	router.set_interface_open(true)
	check(releases == [&"use_tool"], "Opening UI must stop continuous tool use.")
	router.set_interface_open(false)
	check(router.get_dish_rotation_axis() == 0.0, "Resuming must not restore a held rotation key.")
	send_button(MOUSE_BUTTON_LEFT, false)
	check(releases == [&"use_tool"], "A stale release must not create a second action.")
	router.set_context(GameInput.HandMode.TRANSITION, GameInput.Target.DISH)
	commands.clear()
	send_key(KEY_W, true)
	send_button(MOUSE_BUTTON_LEFT, true)
	tap_key(KEY_F)
	send_motion()
	check(commands.is_empty() and looks.size() == 1 and router.get_movement_vector() == Vector2.ZERO, "Transitions must block movement, look and interactions.")
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE)
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(router.interface_open, "Focus loss must release gameplay input into interface mode.")
	router.set_interface_open(false)
	check(router.get_movement_vector() == Vector2.ZERO, "Focus recovery must start without held movement.")

	var hud_scene := load("res://Scenes/game-hud.tscn") as PackedScene
	if hud_scene == null:
		push_error("Could not load the game HUD.")
		quit(1)
		return
	var hud := hud_scene.instantiate()
	hud.set("input_path", NodePath("../GameInput"))
	viewport.add_child(hud)
	await process_frame
	var crosshair := hud.get_node("Crosshair") as Control
	var dot := hud.get_node("Crosshair/Outline") as Control
	check(crosshair.visible and dot.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The crosshair must be visible and not intercept input.")
	check(dot.get_global_rect().get_center().distance_to(Vector2(400, 300)) < 0.1, "Crosshair must be at the viewport center.")
	tap_key(KEY_ESCAPE)
	await process_frame
	check(router.interface_open and not crosshair.visible, "Esc must open UI and hide the crosshair.")
	commands.clear()
	tap_key(KEY_E)
	send_button(MOUSE_BUTTON_LEFT, true, Vector2(5, 5))
	send_button(MOUSE_BUTTON_LEFT, false, Vector2(5, 5))
	check(commands.is_empty(), "The open interface must block world commands.")
	var resume := hud.get_node("Menu/Center/Panel/Margin/Rows/Resume") as Button
	var resume_point: Vector2 = resume.get_global_rect().get_center()
	send_button(MOUSE_BUTTON_LEFT, true, resume_point)
	send_button(MOUSE_BUTTON_LEFT, false, resume_point)
	check(not router.interface_open and commands.is_empty(), "Resume click must close UI without becoming a world action.")

	# A GUI control consumes a click even when gameplay routing itself is enabled.
	router.set_context(GameInput.HandMode.CLOSE_UP, GameInput.Target.DISH, ToolState.Tool.SPONGE)
	var button := Button.new()
	button.position = Vector2(20, 20)
	button.size = Vector2(140, 60)
	button.text = "Input check"
	button.pressed.connect(func() -> void: ui_clicks += 1)
	viewport.add_child(button)
	await process_frame
	commands.clear()
	send_button(MOUSE_BUTTON_LEFT, true, Vector2(40, 40))
	send_button(MOUSE_BUTTON_LEFT, false, Vector2(40, 40))
	check(ui_clicks == 1 and commands.is_empty(), "GUI-consumed clicks must never reach world input.")
	send_button(MOUSE_BUTTON_LEFT, true)
	send_button(MOUSE_BUTTON_LEFT, false)
	check(commands == [&"use_tool"], "An unhandled click outside GUI must still reach gameplay routing.")
	viewport.free()
	if failures == 0:
		print("GAME_INPUT_OK: bindings, context routing, mouse modes, crosshair and GUI consumption.")
		quit(0)
	else:
		push_error("GAME_INPUT_FAILED: %d check(s) failed." % failures)
		quit(1)
