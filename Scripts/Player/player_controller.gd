class_name PlayerController
extends CharacterBody3D
## Movement only. Mouse look is connected in implementation step 7.
## Walk blockers use physics layer 5 (16), separate from future interaction rays.

@export var input_path: NodePath
@export_range(0.1, 5.0, 0.1) var walk_speed: float = 1.6
@export var gravity: float = 9.8
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var view_camera: Camera3D = $ViewCamera

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
