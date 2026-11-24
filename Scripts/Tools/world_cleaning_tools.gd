extends Node3D
## Wrap existing visuals after environment collision assembly, before targeting starts.

@export var kitchen_path: NodePath
var sprayer: CleaningTool
var hose: MeshInstance3D
var hose_shape: CollisionShape3D
var hose_exit: Node3D
var hose_links: Array[MeshInstance3D] = []

func _ready() -> void:
	var kitchen: Node = get_node(kitchen_path)
	var sponge := kitchen.get_node("Models/Sponge") as Node3D
	sponge.get_node("SurfaceCollision").free()
	_wrap(sponge, ToolState.Tool.SPONGE, "海绵")
	var faucet := kitchen.get_node("Models/Faucet") as Node3D
	var head := faucet.find_child("Spray_Head", true, false) as Node3D
	var occluder := faucet.get_node("SurfaceCollision") as StaticBody3D
	for mesh in head.find_children("*", "MeshInstance3D", true, false):
		occluder.get_node(str(mesh.name) + "Surface").free()
	sprayer = _wrap(head, ToolState.Tool.SPRAYER, "喷头")
	hose = faucet.find_child("Pullout_Hose", true, false) as MeshInstance3D
	hose_shape = occluder.get_node("Pullout_HoseSurface") as CollisionShape3D
	hose_exit = faucet.find_child("Hose_Exit", true, false) as Node3D
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.04, 0.05, 0.04)
	material.roughness = 0.8
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.0045
	cylinder.bottom_radius = 0.0045
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	cylinder.material = material
	for index in 16:
		var link := MeshInstance3D.new()
		link.name = "HoseLink%02d" % index
		link.mesh = cylinder
		link.visible = false
		add_child(link)
		hose_links.append(link)

func _wrap(visual: Node3D, kind: ToolState.Tool, label: String) -> CleaningTool:
	var parent := visual.get_parent() as Node3D
	var pose: Transform3D = visual.global_transform
	var tool := CleaningTool.new()
	tool.name = "SpongeTool" if kind == ToolState.Tool.SPONGE else "SprayerTool"
	tool.tool_kind = kind
	tool.display_name = label
	tool.home_parent = parent
	tool.home_pose = pose
	tool.collision_layer = MeshSurfaceCollision.TOOL_LAYER
	tool.collision_mask = 0
	parent.add_child(tool)
	tool.global_transform = pose
	visual.reparent(tool)
	MeshSurfaceCollision.add_shapes(tool, visual)
	return tool

func _physics_process(_delta: float) -> void:
	var pulled: bool = sprayer.get_parent() != sprayer.home_parent
	hose.visible = not pulled
	hose_shape.disabled = pulled
	for link in hose_links:
		link.visible = pulled
	if not pulled:
		return
	var start: Vector3 = hose_exit.global_position
	var end: Vector3 = (sprayer.find_child("Hose_Attach", true, false) as Node3D).global_position
	var first_control: Vector3 = start + Vector3.DOWN * 0.23
	var last_control: Vector3 = end + sprayer.global_basis.y.normalized() * 0.12
	for index in hose_links.size():
		var t0: float = float(index) / hose_links.size()
		var t1: float = float(index + 1) / hose_links.size()
		var a: Vector3 = start.bezier_interpolate(first_control, last_control, end, t0)
		var b: Vector3 = start.bezier_interpolate(first_control, last_control, end, t1)
		var link: MeshInstance3D = hose_links[index]
		var facing := Basis(Quaternion(Vector3.UP, (b - a).normalized()))
		# Cylinder height is local Y; world-axis scaling stretches tilted links.
		facing.y *= a.distance_to(b)
		link.global_transform = Transform3D(facing, a.lerp(b, 0.5))
