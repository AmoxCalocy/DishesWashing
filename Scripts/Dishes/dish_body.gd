class_name DishBody
extends StaticBody3D
## Identity belongs to this instance; shared GLB meshes contain no mutable progress.

enum Location { REGISTERED, BASIN, HELD }

@export var instance_id: StringName
@export var initial_slot_id: StringName
@export var dish_type: StringName
@export var display_name: String

## The node's global_transform records a free position; it has no SlotState.
var location: Location = Location.REGISTERED
var placement_bounds: AABB
var support_dish_ids: Array[StringName] = []

func _ready() -> void:
	assert(not instance_id.is_empty(), "A gameplay dish needs an independent instance ID.")
	collision_layer = MeshSurfaceCollision.DISH_LAYER
	collision_mask = 0
	MeshSurfaceCollision.add_shapes(self, $Model)
