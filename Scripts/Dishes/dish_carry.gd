class_name DishCarry
extends Node
## Two stable hand slots and immersive surface interaction for one dish + tool.

signal inventory_changed
signal message_requested(message: String)

const SURFACE_GAP: float = 0.004
const KEY_ROTATION_SPEED: float = PI * 0.5
const FREE_TOOL_DEPTH: float = 0.32

@export var input_path: NodePath
@export var targeting_path: NodePath
@export var slots_path: NodePath
@export var camera_path: NodePath
@export var anchor_path: NodePath
@export var right_anchor_path: NodePath
@export var close_anchor_path: NodePath
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var targeting: DishTargeting = get_node(targeting_path) as DishTargeting
@onready var registry: KitchenSlotRegistry = get_node(slots_path) as KitchenSlotRegistry
@onready var camera: Camera3D = get_node(camera_path) as Camera3D
@onready var anchor: Marker3D = get_node(anchor_path) as Marker3D
@onready var right_anchor: Marker3D = get_node(right_anchor_path) as Marker3D
@onready var close_anchor: Marker3D = get_node(close_anchor_path) as Marker3D

var hands: Array[HandItem] = [null, null]
## Bind matching authoritative states here when gameplay supplies them. No defaults.
var dish_states: Dictionary[StringName, DishState] = {}
var selected_dish_hand: int = -1
var selected_dish: DishBody:
	get:
		var item: HandItem = get_selected_dish_item()
		return item.node as DishBody if item != null else null
var contact_active: bool = false
var contact_point: Vector3
var contact_normal: Vector3
var contact_dish: DishBody
var held_dish: DishBody:
	get:
		for item in hands:
			if item != null and item.node is DishBody:
				return item.node as DishBody
		return null
var origin_slot_id: StringName:
	get:
		var item: HandItem = _dish_item()
		return item.origin_slot_id if item != null else &""

var _close_item: HandItem
var _using: bool = false
var _rotating: bool = false
var _rotation_axis: float = 0.0
var _cursor: Vector2
var _stroke_distance: float = 0.0
var _transition: Tween
var _world_use_time: float = 0.0
var _last_placement_frame: int = -1

func _ready() -> void:
	game_input.command_requested.connect(_on_command_requested)
	game_input.rotation_requested.connect(_on_rotation)
	game_input.rotation_axis_changed.connect(_on_rotation_axis_changed)
	game_input.tool_cursor_moved.connect(_on_cursor)
	game_input.mode_changed.connect(_on_mode_changed)

func free_hand() -> int:
	return 0 if hands[0] == null else (1 if hands[1] == null else -1)

func held_count() -> int:
	return int(hands[0] != null) + int(hands[1] != null)

func held_tool() -> CleaningTool:
	for item in hands:
		if item != null and item.node is CleaningTool:
			return item.node as CleaningTool
	return null

func _dish_item() -> HandItem:
	for item in hands:
		if item != null and item.node is DishBody:
			return item
	return null

func get_selected_dish_item() -> HandItem:
	if selected_dish_hand >= 0 and selected_dish_hand < hands.size():
		var item: HandItem = hands[selected_dish_hand]
		if item != null and item.node is DishBody:
			return item
	return null

func check_placement(slot: KitchenSlot, dish_state: DishState = null) -> PlacementResult:
	if game_input.interface_open or game_input.hand_mode != GameInput.HandMode.CARRYING:
		return PlacementResult.new(PlacementResult.Code.INPUT_BLOCKED)
	if dish_state == null and selected_dish != null:
		dish_state = dish_states.get(selected_dish.instance_id)
	var result: PlacementResult = PlacementRules.evaluate(get_selected_dish_item(), slot, registry, camera, dish_state, targeting.excluded_bodies, targeting.interaction_distance)
	result.hand_index = selected_dish_hand
	return result

func check_surface_placement(hit: Dictionary, dish_state: DishState = null) -> PlacementResult:
	if game_input.interface_open or game_input.hand_mode != GameInput.HandMode.CARRYING:
		return PlacementResult.new(PlacementResult.Code.INPUT_BLOCKED)
	if dish_state == null and selected_dish != null:
		dish_state = dish_states.get(selected_dish.instance_id)
	var result: PlacementResult = PlacementRules.evaluate_surface(get_selected_dish_item(), hit, registry, camera, dish_state, targeting.excluded_bodies, targeting.interaction_distance)
	result.hand_index = selected_dish_hand
	return result

func _place_dish() -> void:
	if game_input.hand_mode != GameInput.HandMode.CARRYING or _last_placement_frame == Engine.get_physics_frames():
		return
	var item: HandItem = get_selected_dish_item()
	if item == null:
		message_requested.emit("请先选择手中的餐具")
		return
	# Never authorize from the preview, cached input target, or an old result.
	var slot: KitchenSlot = targeting.query_placement_slot()
	var surface: Dictionary = targeting.query_placement_surface() if slot == null else {}
	if slot == null and surface.is_empty():
		message_requested.emit("请瞄准距离内可见的水槽或沥水架")
		return
	var decision: PlacementResult = check_placement(slot) if slot != null else check_surface_placement(surface)
	if not decision.is_valid:
		message_requested.emit(decision.get_reason())
		return
	var dish := item.node as DishBody
	# Commit one location and one hand synchronously. Snap the real body so its
	# visual and collision pose stay aligned; no intermediate flight or reservation.
	dish.reparent(registry.get_node(registry.dishes_path))
	dish.global_transform = decision.pose
	dish.location = DishBody.Location.REGISTERED if slot != null else DishBody.Location.BASIN
	dish.placement_bounds = item.bounds
	dish.support_dish_ids.assign(decision.support_dish_ids)
	if slot != null:
		slot.state.occupant_id = dish.instance_id
	_sync_dish_state(dish, decision.slot_id, false)
	hands[decision.hand_index] = null
	# Moved collision bodies reach direct-space queries on the next physics tick.
	# A duplicate request in this tick must not place the other hand through them.
	_last_placement_frame = Engine.get_physics_frames()
	_sync_inventory()

func _sync_dish_state(dish: DishBody, slot_id: StringName, is_held: bool) -> void:
	var state: DishState = dish_states.get(dish.instance_id)
	if state != null and state.instance_id == dish.instance_id and state.dish_type == dish.dish_type:
		state.current_slot_id = slot_id
		state.is_held = is_held

func _select_dish_hand(side: int) -> void:
	if game_input.hand_mode != GameInput.HandMode.CARRYING:
		return
	if hands[side] == null or not hands[side].node is DishBody:
		message_requested.emit("该手没有餐具")
		return
	selected_dish_hand = side
	inventory_changed.emit()

func _on_command_requested(command: StringName, pressed: bool) -> void:
	if command == &"use_tool":
		_using = pressed and not game_input.interface_open and game_input.hand_mode in [GameInput.HandMode.CARRYING, GameInput.HandMode.CLOSE_UP] and held_tool() != null
		_world_use_time = 0.0
		if not _using:
			_stop_contact()
			if _close_item == null:
				_position_idle_tool()
		return
	if command == &"rotate_dish":
		_rotating = pressed and game_input.hand_mode == GameInput.HandMode.CLOSE_UP
		if pressed:
			_using = false
			_stop_contact()
			_position_idle_tool()
		return
	if not pressed or game_input.interface_open or game_input.hand_mode == GameInput.HandMode.TRANSITION:
		return
	match command:
		&"pickup_dish", &"pickup_tool":
			_pickup(command)
		&"place_dish":
			_place_dish()
		&"toggle_close":
			if game_input.hand_mode == GameInput.HandMode.CLOSE_UP:
				_exit_close()
			else:
				_enter_close()
		&"return_tool":
			_return_tool()
		&"select_left_dish", &"select_right_dish":
			_select_dish_hand(0 if command == &"select_left_dish" else 1)

func _pickup(command: StringName) -> void:
	if game_input.hand_mode not in [GameInput.HandMode.EMPTY, GameInput.HandMode.CARRYING]:
		return
	var side: int = free_hand()
	if side < 0:
		message_requested.emit("双手已满")
		return
	var node: Node3D = targeting.query_dish() if command == &"pickup_dish" else targeting.query_tool()
	if node == null:
		return
	if node is CleaningTool and held_tool() != null:
		message_requested.emit("请先归回手中的清洗工具")
		return
	var item := HandItem.new(node)
	if node is DishBody:
		var dish := node as DishBody
		for other in registry.get_node(registry.dishes_path).get_children():
			if other is DishBody and other.location == DishBody.Location.BASIN and other.support_dish_ids.has(dish.instance_id):
				message_requested.emit("请先拿走上面的餐具")
				return
		if dish.location == DishBody.Location.REGISTERED:
			var slot: KitchenSlot = registry.find_occupied_slot(dish.instance_id)
			if slot == null or not slot.accepts(dish.dish_type):
				return
			item.origin_slot_id = slot.config.slot_id
		elif dish.location == DishBody.Location.BASIN:
			for slot: KitchenSlot in registry.slots.values():
				if slot.state.occupant_id == dish.instance_id:
					return
		else:
			return
	if not _solve_pose(item, side):
		message_requested.emit("手边空间不足，请稍微后退")
		return
	if node is DishBody:
		if not item.origin_slot_id.is_empty():
			registry.slots[item.origin_slot_id].state.occupant_id = &""
		(node as DishBody).location = DishBody.Location.HELD
		(node as DishBody).support_dish_ids.clear()
		_sync_dish_state(node as DishBody, &"", true)
	hands[side] = item
	node.reparent(_anchor(side))
	node.global_transform = item.safe_pose
	_sync_inventory()

func _anchor(side: int) -> Marker3D:
	return anchor if side == 0 else right_anchor

func _sync_inventory() -> void:
	if get_selected_dish_item() == null:
		selected_dish_hand = -1
		for side in hands.size():
			if hands[side] != null and hands[side].node is DishBody:
				selected_dish_hand = side
				break
	targeting.excluded_bodies.clear()
	for item in hands:
		if item != null:
			targeting.excluded_bodies.append((item.node as CollisionObject3D).get_rid())
	game_input.carrying_dish = held_dish != null
	var tool: CleaningTool = held_tool()
	game_input.set_context(GameInput.HandMode.CARRYING if held_count() > 0 else GameInput.HandMode.EMPTY, GameInput.Target.NONE, tool.tool_kind if tool != null else ToolState.Tool.NONE)
	inventory_changed.emit()

func _physics_process(delta: float) -> void:
	if game_input.hand_mode == GameInput.HandMode.TRANSITION:
		return
	if _close_item != null:
		if _rotation_axis != 0.0 and not game_input.interface_open:
			_rotate_dish(Vector2(_rotation_axis * KEY_ROTATION_SPEED * delta, 0.0))
		_update_close()
		return
	for side in 2:
		var item: HandItem = hands[side]
		if item != null:
			_solve_pose(item, side)
			item.node.global_transform = item.safe_pose
	_update_world_tool(delta)

func _update_world_tool(delta: float) -> void:
	_stop_contact()
	if not _using or game_input.interface_open or game_input.hand_mode != GameInput.HandMode.CARRYING:
		return
	var tool: CleaningTool = held_tool()
	if tool == null:
		return
	if tool.tool_kind == ToolState.Tool.SPRAYER and camera.global_position.distance_to(tool.home_pose.origin) > 1.5:
		return
	# Requery the first world surface; held items never become world cleaning targets.
	var hit: Dictionary = targeting.query_surface()
	var dish := hit.get("collider") as DishBody
	if dish == null:
		return
	var pose: Transform3D = _surface_tool_pose(tool, hit.position, hit.normal)
	_world_use_time += delta
	if tool.tool_kind == ToolState.Tool.SPONGE:
		# Normal mode supplies the wiping motion while the player aims and walks.
		pose.basis = pose.basis * Basis(Vector3.UP, sin(_world_use_time * TAU * 3.0) * 0.14)
	var side: int = 0 if hands[0] != null and hands[0].node == tool else 1
	var item: HandItem = hands[side]
	if not _world_tool_pose_is_safe(item, dish, pose, hit.normal):
		return
	tool.global_transform = pose
	contact_dish = dish
	contact_point = hit.position
	contact_normal = hit.normal
	contact_active = true
	_set_compression(true)

func _world_tool_pose_is_safe(item: HandItem, dish: DishBody, pose: Transform3D, normal: Vector3) -> bool:
	var camera_bounds: AABB = (camera.global_transform.affine_inverse() * pose) * item.bounds
	if camera_bounds.end.z > -camera.near - SURFACE_GAP:
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = item.clearance_shape
	query.transform = pose * Transform3D(Basis.IDENTITY, item.bounds.get_center())
	query.collision_mask = MeshSurfaceCollision.QUERY_MASK
	query.exclude = [(item.node as CollisionObject3D).get_rid(), dish.get_rid()]
	query.margin = SURFACE_GAP
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	var start: Transform3D = Transform3D(pose.basis, item.safe_pose.origin) * Transform3D(Basis.IDENTITY, item.bounds.get_center())
	query.transform = start
	query.motion = pose.origin - item.safe_pose.origin
	if space.cast_motion(query)[0] >= 1.0:
		return true
	# Reach over the container rim before descending onto the visible surface.
	var approach: Transform3D = pose
	approach.origin += normal * maxf(item.bounds.size.length(), 0.12)
	if dish.location == DishBody.Location.BASIN:
		var rim := registry.get_node(registry.basin_path).find_child("Countertop_Surface", true, false) as Node3D
		approach.origin.y = maxf(approach.origin.y, rim.global_position.y + maxf(item.bounds.size.length(), 0.12))
	query.motion = approach.origin - item.safe_pose.origin
	if space.cast_motion(query)[0] < 1.0:
		if dish.location != DishBody.Location.BASIN:
			return false
		# A low sprayer cannot turn to its contact orientation beside the counter.
		# Lift in its safe carry orientation, check rotation clearance, then cross.
		var raised: Transform3D = item.safe_pose
		raised.origin.y = maxf(raised.origin.y, approach.origin.y)
		query.transform = item.safe_pose * Transform3D(Basis.IDENTITY, item.bounds.get_center())
		query.motion = raised.origin - item.safe_pose.origin
		if space.cast_motion(query)[0] < 1.0:
			return false
		var rotation_clearance := SphereShape3D.new()
		rotation_clearance.radius = item.bounds.size.length() * 0.5 + item.bounds.get_center().length() + SURFACE_GAP
		query.shape = rotation_clearance
		query.transform = Transform3D(Basis.IDENTITY, raised.origin)
		if not space.intersect_shape(query, 1).is_empty():
			return false
		query.shape = item.clearance_shape
		query.transform = Transform3D(pose.basis, raised.origin) * Transform3D(Basis.IDENTITY, item.bounds.get_center())
		query.motion = approach.origin - raised.origin
		if space.cast_motion(query)[0] < 1.0:
			return false
	query.transform = approach * Transform3D(Basis.IDENTITY, item.bounds.get_center())
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.motion = pose.origin - approach.origin
	return space.cast_motion(query)[0] >= 1.0

func _solve_pose(item: HandItem, side: int) -> bool:
	var facing: AABB = Transform3D(item.rotation, Vector3.ZERO) * item.bounds
	var distance: float = camera.near + facing.end.z + 0.015
	var start: Vector3 = camera.to_global(Vector3(0, 0, -distance))
	var basis: Basis = camera.global_basis * item.rotation
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = item.clearance_shape
	query.transform = Transform3D(basis, start) * Transform3D(Basis.IDENTITY, item.bounds.get_center())
	query.collision_mask = MeshSurfaceCollision.QUERY_MASK
	query.exclude = [(item.node as CollisionObject3D).get_rid()]
	query.margin = SURFACE_GAP
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.motion = _anchor(side).global_position - start
	var fraction: float = space.cast_motion(query)[0]
	item.safe_pose = Transform3D(basis, start + query.motion * fraction)
	return true

func _enter_close() -> void:
	var item: HandItem = _dish_item()
	var tool: CleaningTool = held_tool()
	if item == null or tool == null:
		message_requested.emit("请同时拿着一件餐具和清洗工具")
		return
	if tool.tool_kind == ToolState.Tool.SPRAYER and camera.global_position.distance_to(tool.home_pose.origin) > 1.5:
		message_requested.emit("请靠近水槽使用喷头")
		return
	var sphere := SphereShape3D.new()
	sphere.radius = item.bounds.size.length() * 0.5 + item.bounds.get_center().length() + 0.13
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, close_anchor.global_position)
	query.collision_mask = MeshSurfaceCollision.QUERY_MASK
	query.exclude = targeting.excluded_bodies
	if not camera.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		message_requested.emit("前方清洗空间不足，请稍微后退")
		return
	_close_item = item
	_using = false
	_rotating = false
	_stop_contact()
	game_input.set_context(GameInput.HandMode.TRANSITION, GameInput.Target.NONE, tool.tool_kind)
	item.node.reparent(camera)
	_transition = create_tween()
	_transition.tween_property(item.node, "transform", Transform3D(item.rotation, close_anchor.position), 0.2)
	_transition.finished.connect(func() -> void:
		_cursor = camera.get_viewport().get_visible_rect().size * 0.5
		camera.get_viewport().warp_mouse(_cursor)
		game_input.set_context(GameInput.HandMode.CLOSE_UP, GameInput.Target.NONE, tool.tool_kind)
	)

func _exit_close() -> void:
	if _close_item == null:
		return
	_using = false
	_rotating = false
	_stop_contact()
	_position_idle_tool(true)
	if _transition != null and _transition.is_running():
		_transition.kill()
	var item: HandItem = _close_item
	var side: int = hands.find(item)
	_solve_pose(item, side)
	var local_pose: Transform3D = camera.global_transform.affine_inverse() * item.safe_pose
	game_input.set_context(GameInput.HandMode.TRANSITION, GameInput.Target.NONE, game_input.selected_tool)
	_transition = create_tween()
	_transition.tween_property(item.node, "transform", local_pose, 0.2)
	_transition.finished.connect(_finish_exit)

func _finish_exit() -> void:
	var side: int = hands.find(_close_item)
	_close_item.node.reparent(_anchor(side))
	_close_item = null
	_sync_inventory()

func _on_cursor(position: Vector2) -> void:
	_stroke_distance += minf(_cursor.distance_to(position), 100.0)
	_cursor = position

func _on_rotation(relative: Vector2) -> void:
	if _close_item == null or not _rotating or game_input.interface_open:
		return
	_rotate_dish(relative * 0.01)

func _on_rotation_axis_changed(axis: float) -> void:
	_rotation_axis = axis
	if axis != 0.0:
		_using = false
		_stop_contact()
		_position_idle_tool()

func _rotate_dish(angles: Vector2) -> void:
	_close_item.rotation = (Basis(Vector3.UP, -angles.x) * Basis(Vector3.RIGHT, -angles.y) * _close_item.rotation).orthonormalized()
	_close_item.node.transform = Transform3D(_close_item.rotation, close_anchor.position)

func _on_mode_changed() -> void:
	if game_input.interface_open:
		_using = false
		_rotating = false
		_stop_contact()
		_position_idle_tool()

func _update_close() -> void:
	if _rotating or _rotation_axis != 0.0 or game_input.interface_open:
		_stop_contact()
		_position_idle_tool()
		return
	var tool: CleaningTool = held_tool()
	var from: Vector3 = camera.project_ray_origin(_cursor)
	var query := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(_cursor) * 1.5, MeshSurfaceCollision.DISH_LAYER)
	query.hit_back_faces = false
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	var valid: bool = hit.get("collider") == _close_item.node
	var target: GameInput.Target = GameInput.Target.DISH if valid else GameInput.Target.NONE
	if game_input.target != target:
		game_input.set_context(GameInput.HandMode.CLOSE_UP, target, tool.tool_kind)
	if not valid or not _using:
		_stop_contact()
		_position_idle_tool()
		return
	contact_point = hit.position
	contact_normal = hit.normal
	contact_dish = _close_item.node as DishBody
	contact_active = _using and (tool.tool_kind == ToolState.Tool.SPRAYER or _stroke_distance > 0.0)
	_stroke_distance = 0.0
	tool.global_transform = _surface_tool_pose(tool, contact_point, contact_normal)
	_set_compression(contact_active)

func _surface_tool_pose(tool: CleaningTool, point: Vector3, normal: Vector3) -> Transform3D:
	var offset: Vector3 = normal * 0.001
	if tool.tool_kind == ToolState.Tool.SPRAYER:
		var side: float = -1.0 if hands[0] != null and hands[0].node == tool else 1.0
		offset = normal * 0.12 + camera.global_basis.x.slide(normal) * side * 0.12 + camera.global_basis.y.slide(normal) * 0.04
	var y: Vector3 = offset.normalized()
	var x: Vector3 = camera.global_basis.x.slide(y).normalized()
	if x.length_squared() < 0.01:
		x = camera.global_basis.y.slide(y).normalized()
	return Transform3D(Basis(x, y, x.cross(y).normalized()), point + offset)

func _set_compression(active: bool) -> void:
	var tool: CleaningTool = held_tool()
	if tool != null and tool.tool_kind == ToolState.Tool.SPONGE:
		var foam := tool.find_child("Sponge_Foam", true, false) as MeshInstance3D
		foam.set_blend_shape_value(0, 0.65 if active else 0.0)

func _stop_contact() -> void:
	contact_active = false
	contact_dish = null
	_stroke_distance = 0.0
	_set_compression(false)

func _position_idle_tool(carry_pose: bool = false) -> void:
	for side in 2:
		var item: HandItem = hands[side]
		if item != null and item.node is CleaningTool:
			if _close_item != null and not carry_pose:
				_position_free_tool(item)
			else:
				_solve_pose(item, side)
				item.node.global_transform = item.safe_pose

func _position_free_tool(item: HandItem) -> void:
	# A camera-facing plane keeps idle movement independent of the dish surface.
	var facing: Basis = item.rotation if (item.node as CleaningTool).tool_kind == ToolState.Tool.SPRAYER else Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
	var bounds: AABB = Transform3D(facing, Vector3.ZERO) * item.bounds
	var depth: float = maxf(FREE_TOOL_DEPTH, camera.near + bounds.end.z + 0.015)
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var nearest_depth: float = depth - bounds.end.z
	var bottom_left: Vector3 = camera.to_local(camera.project_position(Vector2(0, viewport_size.y), nearest_depth))
	var top_right: Vector3 = camera.to_local(camera.project_position(Vector2(viewport_size.x, 0), nearest_depth))
	var point: Vector3 = camera.to_local(camera.project_position(_cursor, depth))
	point.x = clampf(point.x, bottom_left.x - bounds.position.x + SURFACE_GAP, top_right.x - bounds.end.x - SURFACE_GAP)
	point.y = clampf(point.y, bottom_left.y - bounds.position.y + SURFACE_GAP, top_right.y - bounds.end.y - SURFACE_GAP)
	item.node.global_transform = camera.global_transform * Transform3D(facing, point)

func _return_tool() -> void:
	if game_input.hand_mode != GameInput.HandMode.CARRYING:
		return
	var tool: CleaningTool = held_tool()
	if tool == null:
		return
	if not tool.can_return(camera.global_position, targeting.excluded_bodies):
		message_requested.emit("请靠近并看得到工具原位再归回")
		return
	for side in 2:
		if hands[side] != null and hands[side].node == tool:
			hands[side] = null
	tool.reparent(tool.home_parent)
	tool.global_transform = tool.home_pose
	_sync_inventory()
