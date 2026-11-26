class_name KitchenSlotRegistry
extends Node3D
## Owns per-scene slot state. This is registration, not placement authorization.

@export var layout: KitchenLayoutConfig
@export var kitchen_path: NodePath
@export var dishes_path: NodePath
@export var basin_path: NodePath

var slots: Dictionary[StringName, KitchenSlot] = {}

func _ready() -> void:
	var kitchen: Node = get_node(kitchen_path)
	for config in layout.slots:
		assert(not config.slot_id.is_empty() and not slots.has(config.slot_id), "Slot IDs must be unique and nonempty.")
		var fixture: Node = kitchen.get_node(config.fixture_path)
		var marker := fixture.find_child(str(config.slot_id), true, false) as Node3D
		assert(marker != null, "Missing placement marker: " + str(config.slot_id))
		assert(not config.accepted_dish_types.is_empty(), "A slot needs compatible dish types.")
		slots[config.slot_id] = KitchenSlot.new(config, marker)
	var dish_ids: Array[StringName] = []
	for child in get_node(dishes_path).get_children():
		var dish := child as DishBody
		assert(dish != null and not dish_ids.has(dish.instance_id), "Initial dishes need unique identities.")
		dish_ids.append(dish.instance_id)
		assert(slots.has(dish.initial_slot_id), "Initial dish slot is not registered.")
		var slot: KitchenSlot = slots[dish.initial_slot_id]
		assert(slot.is_empty() and slot.accepts(dish.dish_type), "Initial slot must be empty and compatible.")
		slot.state.occupant_id = dish.instance_id
		dish.global_transform = slot.get_pose()

func find_occupied_slot(dish_id: StringName) -> KitchenSlot:
	if dish_id.is_empty():
		return null
	var found: KitchenSlot
	for slot: KitchenSlot in slots.values():
		if slot.state.occupant_id != dish_id:
			continue
		if found != null:
			return null
		found = slot
	return found

func is_basin_hit(hit: Dictionary) -> bool:
	var body := hit.get("collider") as CollisionObject3D
	var basin := get_node(basin_path) as Node3D
	if body == null or not basin.is_ancestor_of(body) or not hit.has("shape"):
		return false
	# The same body also contains the countertop; only real interior meshes count.
	var owner := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D
	if owner == null or owner.name not in [&"Sink_BasinSurface", &"Drain_Flange_And_OutletSurface", &"Drain_StrainerSurface"]:
		return false
	var rim := basin.find_child("Countertop_Surface", true, false) as Node3D
	return (hit.position as Vector3).y < rim.global_position.y - 0.02

func is_basin_support(hit: Dictionary) -> bool:
	var dish := hit.get("collider") as DishBody
	return is_basin_hit(hit) or (dish != null and dish.location == DishBody.Location.BASIN and dish.get_parent() == get_node(dishes_path))

func find_placement_slot(camera: Camera3D, first_hit: Dictionary, exclusions: Array[RID], max_distance: float) -> KitchenSlot:
	# Select near the actual crosshair ray, without adding phantom slot colliders.
	if first_hit.get("collider") is DishBody or first_hit.get("collider") is CleaningTool:
		return null
	var center: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
	var origin: Vector3 = camera.project_ray_origin(center)
	var direction: Vector3 = camera.project_ray_normal(center)
	var first_depth: float = INF if first_hit.is_empty() else ((first_hit.position as Vector3) - origin).dot(direction)
	var best: KitchenSlot
	var best_score: float = INF
	var best_depth: float = INF
	for slot: KitchenSlot in slots.values():
		# Tray markers only initialize the order. Only the rack has fixed targets.
		if slot.config.slot_kind != SlotConfig.Kind.DRAINING_RACK:
			continue
		var point: Vector3 = slot.get_pose().origin
		var offset: Vector3 = point - origin
		var depth: float = offset.dot(direction)
		if depth <= camera.near or offset.length() > max_distance or not camera.is_position_in_frustum(point):
			continue
		var miss: float = (offset - direction * depth).length()
		if miss > 0.035:
			continue
		if first_depth < depth - 0.002:
			continue
		# Also check the marker itself when its aim radius straddles an obstruction.
		var ray := PhysicsRayQueryParameters3D.create(origin, point, MeshSurfaceCollision.QUERY_MASK, exclusions)
		ray.hit_back_faces = true
		ray.hit_from_inside = true
		var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			continue
		var score: float = miss / depth
		if score < best_score or (is_equal_approx(score, best_score) and depth < best_depth):
			best = slot
			best_score = score
			best_depth = depth
	return best
