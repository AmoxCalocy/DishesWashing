class_name CleaningTool
extends StaticBody3D
## A single physical tool moves between its home and a hand; no visual copies.

var tool_kind: ToolState.Tool
var display_name: String
var home_parent: Node3D
var home_pose: Transform3D

func can_return(origin: Vector3, exclusions: Array[RID]) -> bool:
	var point: Vector3 = home_pose.origin + Vector3.UP * (0.02 if tool_kind == ToolState.Tool.SPONGE else -0.04)
	if origin.distance_to(point) > 1.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, point, MeshSurfaceCollision.QUERY_MASK, exclusions)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (hit.position as Vector3).distance_to(point) < 0.025
