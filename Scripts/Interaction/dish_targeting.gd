class_name DishTargeting
extends Node
## The first real surface blocks the ray, even when it is not an interactable dish.

signal target_changed(dish: DishBody)

@export var input_path: NodePath
@export var camera_path: NodePath
@export_range(0.1, 3.0, 0.1) var interaction_distance: float = 1.5
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var camera: Camera3D = get_node(camera_path) as Camera3D

var current_dish: DishBody

func _ready() -> void:
	game_input.mode_changed.connect(_on_mode_changed)

func _physics_process(_delta: float) -> void:
	_update_target(query_dish())

func query_dish() -> DishBody:
	if game_input.interface_open or game_input.hand_mode not in [GameInput.HandMode.EMPTY, GameInput.HandMode.SOAP_BOTTLE]:
		return null
	var center: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
	var origin: Vector3 = camera.project_ray_origin(center)
	var end: Vector3 = origin + camera.project_ray_normal(center) * interaction_distance
	var query := PhysicsRayQueryParameters3D.create(origin, end, MeshSurfaceCollision.QUERY_MASK)
	query.hit_back_faces = false
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") as DishBody

func _on_mode_changed() -> void:
	if game_input.interface_open or game_input.hand_mode not in [GameInput.HandMode.EMPTY, GameInput.HandMode.SOAP_BOTTLE]:
		_update_target(null)

func _update_target(dish: DishBody) -> void:
	var changed: bool = current_dish != dish
	current_dish = dish
	var kind: GameInput.Target = GameInput.Target.DISH if dish != null else GameInput.Target.NONE
	if game_input.target != kind:
		game_input.set_context(game_input.hand_mode, kind, game_input.selected_tool)
	if changed:
		target_changed.emit(current_dish)
