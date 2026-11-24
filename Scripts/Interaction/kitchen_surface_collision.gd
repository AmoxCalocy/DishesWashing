extends Node
## Only the gameplay entry adds these occluders; walk blockers remain separate.

@export var visual_roots: Array[NodePath]

func _ready() -> void:
	for path in visual_roots:
		for child in get_node(path).get_children():
			var visual := child as Node3D
			if visual == null or not visual.is_visible_in_tree():
				continue
			var body := StaticBody3D.new()
			body.name = "SurfaceCollision"
			body.collision_layer = MeshSurfaceCollision.ENVIRONMENT_LAYER
			body.collision_mask = 0
			visual.add_child(body)
			MeshSurfaceCollision.add_shapes(body, visual)
