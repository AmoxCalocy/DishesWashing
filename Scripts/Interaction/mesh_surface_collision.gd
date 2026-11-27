class_name MeshSurfaceCollision
extends RefCounted
## Query-only triangles preserve openings and the imported meshes' local poses.

const DISH_LAYER: int = 1
const ENVIRONMENT_LAYER: int = 4
const TOOL_LAYER: int = 8
const QUERY_MASK: int = DISH_LAYER | ENVIRONMENT_LAYER | TOOL_LAYER
# Millimetre bevels need larger local coordinates; 10x also keeps Jolt's
# transformed short-ray queries accurate without extreme local magnitudes.
# The reciprocal shape scale keeps all visible/world dimensions in metres.
const SHAPE_COORDINATE_SCALE: float = 10.0

static func add_shapes(body: StaticBody3D, visual: Node3D) -> void:
	for node in visual.find_children("*", "MeshInstance3D", true, false):
		var surface := node as MeshInstance3D
		if surface.mesh == null or not surface.is_visible_in_tree():
			continue
		var shape := CollisionShape3D.new()
		shape.name = str(surface.name) + "Surface"
		var faces: PackedVector3Array = surface.mesh.get_faces()
		for index in faces.size():
			faces[index] *= SHAPE_COORDINATE_SCALE
		var triangles := ConcavePolygonShape3D.new()
		triangles.set_faces(faces)
		shape.shape = triangles
		body.add_child(shape)
		var pose: Transform3D = body.global_transform.affine_inverse() * surface.global_transform
		pose.basis = pose.basis.scaled(Vector3.ONE / SHAPE_COORDINATE_SCALE)
		shape.transform = pose
