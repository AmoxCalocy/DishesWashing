class_name GameInput
extends Node
## Routes unhandled events into intentions; consumers validate and perform gameplay.
## Context targets must come from a later distance/visibility-aware world query.

signal command_requested(command: StringName, pressed: bool)
signal movement_changed(direction: Vector2)
signal look_requested(relative: Vector2)
signal rotation_requested(relative: Vector2)
signal rotation_axis_changed(axis: float)
signal tool_cursor_moved(position: Vector2)
signal mode_changed

enum HandMode { EMPTY, CARRYING, CLOSE_UP, SOAP_BOTTLE, TRANSITION }
enum Target { NONE, DISH, SLOT, FAUCET, SOAP_BOTTLE, ORDER_BOARD, WATER_STREAM, CLEANING_TOOL }

const MOVE_ACTIONS: Array[StringName] = [
	&"game_move_left", &"game_move_right", &"game_move_forward", &"game_move_back",
]
const BUTTON_ACTIONS: Array[StringName] = [
	&"game_primary", &"game_rotate", &"game_rotate_close", &"game_toggle_close", &"game_interact",
	&"game_tool_none", &"game_tool_sponge", &"game_tool_sprayer",
	&"game_return", &"game_drop", &"game_orders", &"game_zoom_in", &"game_zoom_out",
]

var hand_mode: HandMode = HandMode.EMPTY
var target: Target = Target.NONE
var selected_tool: ToolState.Tool = ToolState.Tool.NONE
var interface_open: bool = false
var carrying_dish: bool = true
var _held: Dictionary[StringName, bool] = {}
var _primary_command: StringName = &""
var _rotating: bool = false
var _zooming_view: bool = false

func _ready() -> void:
	_update_mouse_mode()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_interface_open(true)

func set_interface_open(value: bool) -> void:
	interface_open = value
	_clear_held()
	_update_mouse_mode()
	mode_changed.emit()

func set_context(mode: HandMode, new_target: Target, tool: ToolState.Tool = ToolState.Tool.NONE) -> void:
	if hand_mode != mode:
		_clear_held()
	elif selected_tool != tool or (target != new_target and not (hand_mode == HandMode.CARRYING and _primary_command == &"use_tool")):
		_release_primary()
	hand_mode = mode
	target = new_target
	selected_tool = tool
	_update_mouse_mode()
	mode_changed.emit()

func get_movement_vector() -> Vector2:
	if interface_open or hand_mode in [HandMode.CLOSE_UP, HandMode.TRANSITION]:
		return Vector2.ZERO
	return Vector2(
		float(_held.has(&"game_move_right")) - float(_held.has(&"game_move_left")),
		float(_held.has(&"game_move_back")) - float(_held.has(&"game_move_forward"))
	).limit_length()

func get_dish_rotation_axis() -> float:
	if interface_open or hand_mode != HandMode.CLOSE_UP:
		return 0.0
	return float(_held.has(&"game_interact")) - float(_held.has(&"game_return"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed(&"game_menu"):
		set_interface_open(not interface_open)
		get_viewport().set_input_as_handled()
		return
	if interface_open or hand_mode == HandMode.TRANSITION:
		return
	if event is InputEventMouseMotion:
		if _rotating:
			rotation_requested.emit(event.relative)
			if hand_mode == HandMode.CLOSE_UP:
				tool_cursor_moved.emit(event.position)
		elif hand_mode == HandMode.CLOSE_UP:
			tool_cursor_moved.emit(event.position)
		else:
			look_requested.emit(event.relative)
		get_viewport().set_input_as_handled()
		return
	for action in MOVE_ACTIONS:
		if event.is_action(action):
			_record_button(action, event.is_pressed())
			movement_changed.emit(get_movement_vector())
			get_viewport().set_input_as_handled()
			return
	for action in BUTTON_ACTIONS:
		if event.is_action(action):
			# Wheel events are pulses and may arrive without a matching release.
			var wheel: bool = action in [&"game_zoom_in", &"game_zoom_out"]
			if wheel or _held.has(action) != event.is_pressed():
				if not wheel:
					_record_button(action, event.is_pressed())
				_dispatch(action, event.is_pressed())
			get_viewport().set_input_as_handled()
			return

func _dispatch(action: StringName, pressed: bool) -> void:
	if action == &"game_primary":
		if not pressed:
			_release_primary()
		elif not _rotating and get_dish_rotation_axis() == 0.0:
			var command: StringName = _resolve_primary()
			if not command.is_empty():
				if command in [&"wet_sponge", &"use_tool"]:
					_primary_command = command
				command_requested.emit(command, true)
		return
	if action in [&"game_rotate", &"game_rotate_close"]:
		if action == &"game_rotate_close" and (hand_mode == HandMode.CLOSE_UP or (hand_mode == HandMode.CARRYING and carrying_dish)):
			_rotating = pressed
			if pressed:
				_release_primary()
			command_requested.emit(&"rotate_dish", pressed)
		elif action == &"game_rotate" and (hand_mode in [HandMode.EMPTY, HandMode.SOAP_BOTTLE] or (hand_mode == HandMode.CARRYING and not carrying_dish)):
			_zooming_view = pressed
			command_requested.emit(&"zoom_view", pressed)
		return
	if hand_mode == HandMode.CLOSE_UP and action in [&"game_return", &"game_interact"]:
		if pressed:
			_release_primary()
		rotation_axis_changed.emit(get_dish_rotation_axis())
		return
	if not pressed:
		return
	match action:
		&"game_orders":
			command_requested.emit(&"show_orders", true)
		&"game_toggle_close":
			if hand_mode in [HandMode.CARRYING, HandMode.CLOSE_UP]:
				command_requested.emit(&"toggle_close", true)
		&"game_interact":
			if hand_mode == HandMode.CARRYING and selected_tool != ToolState.Tool.NONE and target == Target.DISH and not carrying_dish:
				_release_primary()
				command_requested.emit(&"pickup_dish", true)
			elif hand_mode == HandMode.CARRYING and selected_tool != ToolState.Tool.NONE:
				_release_primary()
				command_requested.emit(&"return_tool", true)
			elif hand_mode in [HandMode.EMPTY, HandMode.CARRYING]:
				match target:
					Target.DISH:
						command_requested.emit(&"pickup_dish", true)
					Target.CLEANING_TOOL:
						command_requested.emit(&"pickup_tool", true)
					Target.FAUCET:
						command_requested.emit(&"toggle_faucet", true)
					Target.ORDER_BOARD:
						command_requested.emit(&"show_orders", true)
					Target.SOAP_BOTTLE:
						if hand_mode == HandMode.EMPTY:
							command_requested.emit(&"pickup_soap", true)
		&"game_return":
			pass # Q is rotation in immersion only; ordinary return is removed.
		&"game_drop":
			if hand_mode == HandMode.CARRYING and carrying_dish:
				_release_primary()
				_release_rotation()
				command_requested.emit(&"drop_dish", true)
		&"game_tool_none", &"game_tool_sponge", &"game_tool_sprayer":
			if hand_mode != HandMode.SOAP_BOTTLE:
				_release_primary()
				if hand_mode == HandMode.CARRYING and carrying_dish and action != &"game_tool_sprayer":
					_release_rotation()
					command_requested.emit(&"select_left_dish" if action == &"game_tool_none" else &"select_right_dish", true)
				else:
					command_requested.emit(action, true)
		&"game_zoom_in", &"game_zoom_out":
			if hand_mode == HandMode.CLOSE_UP:
				_release_primary()
				command_requested.emit(action, true)

func _resolve_primary() -> StringName:
	match hand_mode:
		HandMode.EMPTY:
			if target == Target.CLEANING_TOOL:
				return &"pickup_tool"
			if target == Target.WATER_STREAM and selected_tool == ToolState.Tool.SPONGE:
				return &"wet_sponge"
			if target == Target.DISH:
				return &"pickup_dish"
		HandMode.CARRYING:
			if selected_tool != ToolState.Tool.NONE:
				return &"use_tool"
			if target == Target.DISH:
				return &"pickup_dish"
			if target == Target.CLEANING_TOOL:
				return &"pickup_tool"
		HandMode.CLOSE_UP:
			if target == Target.DISH and selected_tool != ToolState.Tool.NONE:
				return &"use_tool"
		HandMode.SOAP_BOTTLE:
			if target == Target.DISH:
				return &"pump_soap"
	return &""

func _record_button(action: StringName, pressed: bool) -> void:
	if pressed:
		_held[action] = true
	else:
		_held.erase(action)

func _release_primary() -> void:
	if not _primary_command.is_empty():
		var previous: StringName = _primary_command
		_primary_command = &""
		command_requested.emit(previous, false)

func _release_rotation() -> void:
	if _rotating:
		_rotating = false
		command_requested.emit(&"rotate_dish", false)

func _clear_held() -> void:
	_held.clear()
	rotation_axis_changed.emit(0.0)
	_release_primary()
	_release_rotation()
	if _zooming_view:
		_zooming_view = false
		command_requested.emit(&"zoom_view", false)
	movement_changed.emit(Vector2.ZERO)

func _update_mouse_mode() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if interface_open or hand_mode == HandMode.CLOSE_UP else Input.MOUSE_MODE_CAPTURED
