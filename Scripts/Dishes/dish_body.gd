class_name DishBody
extends StaticBody3D
## Identity belongs to this instance; shared GLB meshes contain no mutable progress.

@export var instance_id: StringName
@export var dish_type: StringName
@export var display_name: String

func _ready() -> void:
	assert(not instance_id.is_empty(), "A gameplay dish needs an independent instance ID.")
	collision_layer = MeshSurfaceCollision.DISH_LAYER
	collision_mask = 0
	MeshSurfaceCollision.add_shapes(self, $Model)
