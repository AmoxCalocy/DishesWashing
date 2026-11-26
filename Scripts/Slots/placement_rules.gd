class_name PlacementRules
extends RefCounted
## Shared query for future previews, confirmation and safe return. Never mutates state.

static func evaluate(item: HandItem, slot: KitchenSlot, registry: KitchenSlotRegistry, camera: Camera3D, dish_state: DishState = null, exclusions: Array[RID] = [], max_distance: float = 1.5) -> PlacementResult:
	if item == null or not item.node is DishBody:
		return PlacementResult.new(PlacementResult.Code.NO_DISH)
	if slot == null or registry.slots.get(slot.config.slot_id) != slot or not is_instance_valid(slot.marker):
		return PlacementResult.new(PlacementResult.Code.INVALID_SLOT)
	var dish := item.node as DishBody
	var result := PlacementResult.new(PlacementResult.Code.OK, slot.get_pose())
	result.dish_id = dish.instance_id
	result.slot_id = slot.config.slot_id
	if not slot.accepts(dish.dish_type):
		result.code = PlacementResult.Code.INCOMPATIBLE
	elif not slot.is_empty():
		result.code = PlacementResult.Code.OCCUPIED
	else:
		for registered: KitchenSlot in registry.slots.values():
			if registered.state.occupant_id == dish.instance_id:
				result.code = PlacementResult.Code.SOURCE_OCCUPIED
				break
	if not result.is_valid:
		return result
	var limit: Vector3 = slot.config.maximum_dish_size
	if limit.x <= 0.0 or limit.y <= 0.0 or limit.z <= 0.0:
		result.code = PlacementResult.Code.INVALID_SLOT
		return result
	if item.bounds.size.x > limit.x or item.bounds.size.y > limit.y or item.bounds.size.z > limit.z:
		result.code = PlacementResult.Code.TOO_LARGE
		return result
	var point: Vector3 = result.pose.origin
	if camera.global_position.distance_to(point) > max_distance:
		result.code = PlacementResult.Code.OUT_OF_RANGE
		return result
	var visible_exclusions: Array[RID] = exclusions.duplicate()
	if not visible_exclusions.has(dish.get_rid()):
		visible_exclusions.append(dish.get_rid())
	if not camera.is_position_in_frustum(point) or not _is_visible(point, camera, visible_exclusions, null):
		result.code = PlacementResult.Code.NOT_VISIBLE
		return result
	if dish_state != null and (dish_state.instance_id != dish.instance_id or dish_state.dish_type != dish.dish_type):
		result.code = PlacementResult.Code.STATE_MISMATCH
	elif slot.config.slot_kind == SlotConfig.Kind.DRAINING_RACK:
		if dish_state == null:
			result.code = PlacementResult.Code.MISSING_STATE
		elif not dish_state.meets_cleanliness_requirement():
			result.code = PlacementResult.Code.DIRTY
	if result.is_valid and not _has_space(item, result.pose, camera, exclusions):
		result.code = PlacementResult.Code.NO_SPACE
	return result

static func evaluate_surface(item: HandItem, hit: Dictionary, registry: KitchenSlotRegistry, camera: Camera3D, dish_state: DishState = null, exclusions: Array[RID] = [], max_distance: float = 1.5) -> PlacementResult:
	if item == null or not item.node is DishBody:
		return PlacementResult.new(PlacementResult.Code.NO_DISH)
	if not registry.is_basin_hit(hit):
		return PlacementResult.new(PlacementResult.Code.INVALID_SURFACE)
	var dish := item.node as DishBody
	var point: Vector3 = hit.position
	var result := PlacementResult.new(PlacementResult.Code.OK, Transform3D(Basis.IDENTITY, point + Vector3.UP * (0.0005 - item.bounds.position.y)))
	result.dish_id = dish.instance_id
	for slot: KitchenSlot in registry.slots.values():
		if slot.state.occupant_id == dish.instance_id:
			result.code = PlacementResult.Code.SOURCE_OCCUPIED
			return result
	if camera.global_position.distance_to(point) > max_distance:
		result.code = PlacementResult.Code.OUT_OF_RANGE
		return result
	var visible_exclusions: Array[RID] = exclusions.duplicate()
	if not visible_exclusions.has(dish.get_rid()):
		visible_exclusions.append(dish.get_rid())
	if not camera.is_position_in_frustum(point) or not _is_visible(point, camera, visible_exclusions, registry.get_node(registry.basin_path) as Node3D):
		result.code = PlacementResult.Code.NOT_VISIBLE
		return result
	if dish_state != null and (dish_state.instance_id != dish.instance_id or dish_state.dish_type != dish.dish_type):
		result.code = PlacementResult.Code.STATE_MISMATCH
		return result
	# Settle on real bottom-ring support. Shallow floor slopes may tilt the dish;
	# walls and unsupported footprints remain invalid instead of lifting it away.
	var normal: Vector3 = hit.normal
	if normal.dot(Vector3.UP) < 0.95:
		result.code = PlacementResult.Code.UNSUPPORTED
		return result
	result.pose.basis = Basis(Quaternion(Vector3.UP, normal))
	var height: float = -INF
	var supports: PackedVector2Array
	for local_point in item.get_support_points():
		var offset: Vector3 = result.pose.basis * local_point
		var at: Vector3 = point + Vector3(offset.x, 0, offset.z)
		var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.04, at - Vector3.UP * 0.04, MeshSurfaceCollision.QUERY_MASK, visible_exclusions)
		var support: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(ray)
		if not registry.is_basin_hit(support) or (support.normal as Vector3).dot(Vector3.UP) < 0.95:
			continue
		supports.append(Vector2(offset.x, offset.z))
		height = maxf(height, (support.position as Vector3).y - offset.y + 0.0005)
	# Drain openings may remove individual contacts; the remaining contacts must
	# surround the dish centre rather than supporting only one side of its base.
	if supports.size() < 3 or not Geometry2D.is_point_in_polygon(Vector2.ZERO, Geometry2D.convex_hull(supports)):
		result.code = PlacementResult.Code.UNSUPPORTED
		return result
	result.pose.origin.y = height
	if not _has_space(item, result.pose, camera, visible_exclusions):
		result.code = PlacementResult.Code.NO_SPACE
	return result

static func _is_visible(point: Vector3, camera: Camera3D, exclusions: Array[RID], basin: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, point, MeshSurfaceCollision.QUERY_MASK, exclusions)
	query.hit_back_faces = true
	query.hit_from_inside = true
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	# A free-placement aim point is on the real basin surface itself.
	return hit.is_empty() or (basin != null and basin.is_ancestor_of(hit.collider) and (hit.position as Vector3).distance_to(point) <= 0.002)

static func _has_space(item: HandItem, pose: Transform3D, camera: Camera3D, exclusions: Array[RID] = []) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = item.clearance_shape
	query.transform = pose * Transform3D(Basis.IDENTITY, item.bounds.get_center())
	query.collision_mask = MeshSurfaceCollision.QUERY_MASK
	var space_exclusions: Array[RID] = exclusions.duplicate()
	if not space_exclusions.has((item.node as CollisionObject3D).get_rid()):
		space_exclusions.append((item.node as CollisionObject3D).get_rid())
	query.exclude = space_exclusions
	# Slot support gaps are about 0.5 mm; carry's 4 mm margin cannot be reused.
	query.margin = 0.0
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	if space.intersect_shape(query, 1).is_empty():
		return true
	# A broad box may cross empty cup/rack openings. Query thin prisms around
	# actual triangles, including obstacles which fit between their edges.
	query.transform = pose
	for triangle in item.get_placement_shapes():
		query.shape = triangle
		if not space.intersect_shape(query, 1).is_empty():
			return false
	return true
