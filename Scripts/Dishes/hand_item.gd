class_name HandItem
extends RefCounted
## Per-hand identity, original slot and carry clearance; shared meshes stay unchanged.

var node: Node3D
var origin_slot_id: StringName
var rotation: Basis
var bounds: AABB
var clearance_shape: BoxShape3D
var safe_pose: Transform3D
var _placement_faces: PackedVector3Array

func _init(item_node: Node3D) -> void:
	node = item_node
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
