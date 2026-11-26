class_name DishTargeting
extends Node
## The first real surface blocks the ray, even when it is not an interactable dish.

signal target_changed(dish: DishBody)
signal slot_changed(slot: KitchenSlot)
signal tool_changed(tool: CleaningTool)
signal placement_surface_changed(active: bool)

@export var input_path: NodePath
@export var camera_path: NodePath
@export var slots_path: NodePath
@export_range(0.1, 3.0, 0.1) var interaction_distance: float = 1.5
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var camera: Camera3D = get_node(camera_path) as Camera3D
@onready var registry: KitchenSlotRegistry = get_node(slots_path) as KitchenSlotRegistry

var current_dish: DishBody
var current_slot: KitchenSlot
var current_tool: CleaningTool
var current_placement_surface: Dictionary = {}
var excluded_bodies: Array[RID] = []

func _ready() -> void:
	game_input.mode_changed.connect(_on_mode_changed)

func _physics_process(_delta: float) -> void:
	if game_input.hand_mode in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]:
		_update_target(null, null, null, false)
		return
	var hit: Dictionary = _query_surface()
	var dish := hit.get("collider") as DishBody
	var tool := hit.get("collider") as CleaningTool
	var slot: KitchenSlot
	var surface: Dictionary = {}
	if dish == null and tool == null and not game_input.interface_open and game_input.hand_mode == GameInput.HandMode.CARRYING and game_input.carrying_dish:
		slot = registry.find_placement_slot(camera, hit, excluded_bodies, interaction_distance)
		if slot == null and registry.is_basin_hit(hit):
			surface = hit
	_update_target(dish, slot, tool, true, surface)

func query_dish() -> DishBody:
	return _query_surface().get("collider") as DishBody

func query_tool() -> CleaningTool:
	return _query_surface().get("collider") as CleaningTool

func query_surface() -> Dictionary:
	return _query_surface()

func query_placement_slot() -> KitchenSlot:
	if game_input.interface_open or game_input.hand_mode != GameInput.HandMode.CARRYING or not game_input.carrying_dish:
		return null
	return registry.find_placement_slot(camera, _query_surface(), excluded_bodies, interaction_distance)

func query_placement_surface() -> Dictionary:
	if game_input.interface_open or game_input.hand_mode != GameInput.HandMode.CARRYING or not game_input.carrying_dish:
		return {}
	var hit: Dictionary = _query_surface()
	return hit if registry.is_basin_hit(hit) else {}

func _query_surface() -> Dictionary:
	if game_input.interface_open or game_input.hand_mode not in [GameInput.HandMode.EMPTY, GameInput.HandMode.CARRYING, GameInput.HandMode.SOAP_BOTTLE]:
		return {}
	var center: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
	var origin: Vector3 = camera.project_ray_origin(center)
	var end: Vector3 = origin + camera.project_ray_normal(center) * interaction_distance
	var query := PhysicsRayQueryParameters3D.create(origin, end, MeshSurfaceCollision.QUERY_MASK)
	query.hit_back_faces = false
	query.exclude = excluded_bodies
	return camera.get_world_3d().direct_space_state.intersect_ray(query)

func _on_mode_changed() -> void:
	if game_input.hand_mode in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]:
		_update_target(null, null, null, false)
		return
	if game_input.interface_open or game_input.hand_mode not in [GameInput.HandMode.EMPTY, GameInput.HandMode.CARRYING, GameInput.HandMode.SOAP_BOTTLE]:
		_update_target(null)

func _update_target(dish: DishBody, slot: KitchenSlot = null, tool: CleaningTool = null, route: bool = true, surface: Dictionary = {}) -> void:
	var changed: bool = current_dish != dish
	var slot_has_changed: bool = current_slot != slot
	var tool_has_changed: bool = current_tool != tool
	var surface_has_changed: bool = current_placement_surface.is_empty() != surface.is_empty()
	current_dish = dish
	current_slot = slot
	current_tool = tool
	current_placement_surface = surface
	var kind: GameInput.Target = GameInput.Target.DISH if dish != null else GameInput.Target.NONE
	if slot != null:
		kind = GameInput.Target.SLOT
	if tool != null:
		kind = GameInput.Target.CLEANING_TOOL
	if not surface.is_empty():
		kind = GameInput.Target.PLACEMENT_SURFACE
	if route and game_input.target != kind:
		game_input.set_context(game_input.hand_mode, kind, game_input.selected_tool)
	if changed:
		target_changed.emit(current_dish)
	if slot_has_changed:
		slot_changed.emit(current_slot)
	if tool_has_changed:
		tool_changed.emit(current_tool)
	if surface_has_changed:
		placement_surface_changed.emit(not surface.is_empty())
