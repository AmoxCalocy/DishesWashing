class_name DishBody
extends StaticBody3D
## Identity belongs to this instance; shared GLB meshes contain no mutable progress.

enum Location { REGISTERED, HELD, WORLD }
const PHYSICS_LAYER: int = 32
static var _motion_shapes: Dictionary = {}

@export var instance_id: StringName
@export var initial_slot_id: StringName
@export var dish_type: StringName
@export var display_name: String
@export_range(0.25, 0.8, 0.01) var close_min_distance: float = 0.40
@export_range(0.25, 0.8, 0.01) var close_max_distance: float = 0.56

## The node's global_transform records a free position; it has no SlotState.
var location: Location = Location.REGISTERED
var motion_body: RigidBody3D

func _ready() -> void:
	assert(not instance_id.is_empty(), "A gameplay dish needs an independent instance ID.")
	collision_layer = MeshSurfaceCollision.DISH_LAYER
	collision_mask = 0
	MeshSurfaceCollision.add_shapes(self, $Model)
	_build_motion_body()

func _build_motion_body() -> void:
	# Keep exact triangle targeting on this original body. A separate convex body
	# handles gravity, without sealing the cup opening in the interaction mesh.
	motion_body = RigidBody3D.new()
	motion_body.name = "DishPhysics"
	motion_body.top_level = true
	motion_body.freeze = true
	motion_body.collision_layer = PHYSICS_LAYER
	motion_body.collision_mask = 0
	motion_body.mass = 0.35 if dish_type == &"plate" else 0.25
	motion_body.continuous_cd = true
	motion_body.linear_damp = 0.4
	motion_body.angular_damp = 1.0
	var material := PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.0
	motion_body.physics_material_override = material
	add_child(motion_body)
	var settings := MeshConvexDecompositionSettings.new()
	settings.max_convex_hulls = 32
	settings.max_concavity = 0.001
	settings.resolution = 100000
	settings.normalize_mesh = true
	for child in $Model.find_children("*", "MeshInstance3D", true, false):
		var source := child as MeshInstance3D
		if not _motion_shapes.has(source.mesh):
			var helper := MeshInstance3D.new()
			helper.mesh = source.mesh
			helper.create_multiple_convex_collisions(settings)
			var pieces: Array[Dictionary] = []
			for node in helper.find_children("*", "CollisionShape3D", true, false):
				node.shape.margin = 0.0002
				pieces.append({"shape": node.shape, "pose": node.transform})
			_motion_shapes[source.mesh] = pieces
			helper.free()
		for piece: Dictionary in _motion_shapes[source.mesh]:
			var shape := CollisionShape3D.new()
			shape.shape = piece.shape
			motion_body.add_child(shape)
			shape.transform = global_transform.affine_inverse() * source.global_transform * piece.pose

func _physics_process(_delta: float) -> void:
	if location == Location.WORLD:
		global_transform = motion_body.global_transform
	else:
		motion_body.global_transform = global_transform
		motion_body.collision_layer = 0 if location == Location.HELD else PHYSICS_LAYER

func release_with_gravity(pose: Transform3D) -> void:
	global_transform = pose
	location = Location.WORLD
	# Simulated bodies must not inherit notifications from the query body which
	# follows them. Keep the independent motion body beside the original dish.
	motion_body.reparent(get_parent())
	motion_body.global_transform = pose
	motion_body.linear_velocity = Vector3.ZERO
	motion_body.angular_velocity = Vector3.ZERO
	motion_body.collision_layer = PHYSICS_LAYER
	# Real kitchen/floor meshes, tools, other dishes and the player. The coarse
	# walking cabinet blocker must not seal the basin for physical dishes.
	motion_body.collision_mask = MeshSurfaceCollision.ENVIRONMENT_LAYER | 8 | PHYSICS_LAYER | 2
	motion_body.freeze = false
	motion_body.sleeping = false

func stop_motion() -> void:
	motion_body.freeze = true
	motion_body.linear_velocity = Vector3.ZERO
	motion_body.angular_velocity = Vector3.ZERO
	motion_body.collision_layer = 0
	motion_body.collision_mask = 0
	if motion_body.get_parent() != self:
		motion_body.reparent(self)

func _exit_tree() -> void:
	if is_instance_valid(motion_body) and motion_body.get_parent() != self:
		motion_body.queue_free()
