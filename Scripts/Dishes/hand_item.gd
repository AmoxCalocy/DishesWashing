class_name HandItem
extends RefCounted
## Per-hand identity, original slot and carry clearance; shared meshes stay unchanged.

var node: Node3D
var origin_slot_id: StringName
var origin_kind: DishBody.Location = DishBody.Location.REGISTERED
var origin_pose: Transform3D
var rotation: Basis
var bounds: AABB
var clearance_shape: BoxShape3D
var safe_pose: Transform3D
var _placement_faces: PackedVector3Array
var _placement_shapes: Array[ConvexPolygonShape3D] = []

func _init(item_node: Node3D) -> void:
	node = item_node
	origin_pose = node.global_transform
	if node is DishBody:
		origin_kind = (node as DishBody).location
	rotation = Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
	if node is CleaningTool and (node as CleaningTool).tool_kind == ToolState.Tool.SPONGE:
		rotation = rotation.inverse()
	elif node is CleaningTool and (node as CleaningTool).tool_kind == ToolState.Tool.SPRAYER:
		rotation = Basis(Vector3.RIGHT, deg_to_rad(25.0))
	var first: bool = true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var local_pose: Transform3D = node.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = local_pose * mesh.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	clearance_shape = BoxShape3D.new()
	clearance_shape.size = bounds.size
	clearance_shape.margin = 0.0

func get_placement_faces() -> PackedVector3Array:
	if _placement_faces.is_empty():
		for child in node.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			if not mesh.is_visible_in_tree() or mesh.mesh == null:
				continue
			var local_pose: Transform3D = node.global_transform.affine_inverse() * mesh.global_transform
			for point in mesh.mesh.get_faces():
				_placement_faces.append(local_pose * point)
	return _placement_faces

func get_placement_shapes() -> Array[ConvexPolygonShape3D]:
	if _placement_shapes.is_empty():
		var faces: PackedVector3Array = get_placement_faces()
		for index in range(0, faces.size(), 3):
			var a: Vector3 = faces[index]
			var b: Vector3 = faces[index + 1]
			var c: Vector3 = faces[index + 2]
			var normal: Vector3 = (b - a).cross(c - a).normalized() * 0.00001
			if normal == Vector3.ZERO:
				continue
			var triangle := ConvexPolygonShape3D.new()
			triangle.margin = 0.0
			triangle.points = PackedVector3Array([a + normal, b + normal, c + normal, a - normal, b - normal, c - normal])
			_placement_shapes.append(triangle)
	return _placement_shapes
