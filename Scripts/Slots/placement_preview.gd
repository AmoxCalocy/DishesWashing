class_name PlacementPreview
extends Node3D
## Visual-only world preview; its cached result never authorizes a later action.

signal preview_changed(slot: KitchenSlot, result: PlacementResult)

const VALID_COLOR: Color = Color(0.15, 0.95, 0.45, 0.45)
const INVALID_COLOR: Color = Color(1.0, 0.2, 0.12, 0.45)

@export var carry_path: NodePath
@onready var carry: DishCarry = get_node(carry_path) as DishCarry

## Bind references to authoritative runtime states when gameplay provides them.
## The current scene leaves this empty; verification may inject known states.
var dish_states: Dictionary[StringName, DishState] = {}
var current_slot: KitchenSlot
var current_surface: Dictionary = {}
var result: PlacementResult
var _source_dish: DishBody
var _material: StandardMaterial3D

func _ready() -> void:
	visible = false
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	carry.game_input.mode_changed.connect(_on_mode_changed)

func _physics_process(_delta: float) -> void:
	if not _enabled():
		_clear()
		return
	var slot: KitchenSlot = carry.targeting.query_placement_slot()
	var surface: Dictionary = carry.targeting.query_placement_surface() if slot == null else {}
	if slot == null and surface.is_empty():
		_clear()
		return
	var dish: DishBody = carry.selected_dish
	var next: PlacementResult = carry.check_placement(slot, dish_states.get(dish.instance_id)) if slot != null else carry.check_surface_placement(surface, dish_states.get(dish.instance_id))
	var changed: bool = current_slot != slot or result == null or result.code != next.code or result.dish_id != next.dish_id or result.hand_index != next.hand_index or not result.pose.is_equal_approx(next.pose)
	if not is_instance_valid(_source_dish) or _source_dish != dish:
		_rebuild(dish)
	current_slot = slot
	current_surface = surface
	result = next
	global_transform = result.pose
	_material.albedo_color = VALID_COLOR if result.is_valid else INVALID_COLOR
	visible = true
	if changed:
		preview_changed.emit(current_slot, result)

func _enabled() -> bool:
	return not carry.game_input.interface_open and carry.game_input.hand_mode == GameInput.HandMode.CARRYING and carry.selected_dish != null

func _on_mode_changed() -> void:
	if not _enabled():
		_clear()

func _clear() -> void:
	var changed: bool = current_slot != null or result != null
	visible = false
	current_slot = null
	current_surface = {}
	result = null
	if changed:
		preview_changed.emit(null, null)

func _rebuild(dish: DishBody) -> void:
	for child in get_children():
		child.free()
	_source_dish = dish
	# Copy only visual mesh nodes, never the DishBody, scripts or collision shapes.
	for child in dish.find_children("*", "MeshInstance3D", true, false):
		var source := child as MeshInstance3D
		if not source.is_visible_in_tree() or source.mesh == null:
			continue
		var ghost := MeshInstance3D.new()
		ghost.mesh = source.mesh
		ghost.material_override = _material
		ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ghost)
		ghost.transform = dish.global_transform.affine_inverse() * source.global_transform
