class_name PlayerController
extends CharacterBody3D
## Walking and direct mouse look consume the filtered GameInput signals/state.
## Walk blockers use physics layer 5 (16), separate from future interaction rays.

const PITCH_LIMIT_DEGREES: float = 80.0

@export var input_path: NodePath
@export_range(0.1, 5.0, 0.1) var walk_speed: float = 1.6
@export var gravity: float = 9.8
@export_range(0.0001, 0.02, 0.0001) var look_sensitivity: float = 0.0025
@export_range(10.0, 90.0, 1.0) var zoom_fov_degrees: float = 35.0
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var view_camera: Camera3D = $ViewCamera

var _look_enabled: bool = false
var _discard_look_motion: bool = true
var _view_zoom_active: bool = false
var _normal_fov: float = 0.0

func _ready() -> void:
	game_input.look_requested.connect(_on_look_requested)
	game_input.mode_changed.connect(_on_input_mode_changed)
	game_input.command_requested.connect(_on_command_requested)
	_on_input_mode_changed()

func _on_command_requested(command: StringName, pressed: bool) -> void:
	if command != &"zoom_view":
		return
	if pressed and _look_enabled and not _view_zoom_active:
		_normal_fov = view_camera.fov
		_view_zoom_active = true
		view_camera.fov = minf(zoom_fov_degrees, _normal_fov)
	elif not pressed and _view_zoom_active:
		view_camera.fov = _normal_fov
		_view_zoom_active = false

func _on_input_mode_changed() -> void:
	var enabled: bool = not game_input.interface_open and game_input.hand_mode not in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]
	if enabled != _look_enabled:
		# No stored mouse delta survives a menu, focus loss or a distance transition.
		_discard_look_motion = true
	_look_enabled = enabled

func _on_look_requested(relative: Vector2) -> void:
	if not _look_enabled:
		return
	if _discard_look_motion:
		# Capturing the cursor can generate a warp event; discard the first packet.
		_discard_look_motion = false
		return
	rotation.y = wrapf(rotation.y - relative.x * look_sensitivity, -PI, PI)
	var pitch_limit: float = deg_to_rad(PITCH_LIMIT_DEGREES)
	view_camera.rotation.x = clampf(view_camera.rotation.x - relative.y * look_sensitivity, -pitch_limit, pitch_limit)

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = game_input.get_movement_vector()
	var forward: Vector3 = -view_camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = forward.cross(Vector3.UP)
	var direction: Vector3 = right * input_vector.x - forward * input_vector.y
	direction = direction.limit_length()
	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
