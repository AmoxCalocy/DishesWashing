extends SceneTree
## Assemble reusable GLB instances into an editable Godot scene.
## Run after imports: godot --headless --path . --script Tools/build_kitchen_demo.gd

var scene_root: Node3D

func _initialize() -> void:
	call_deferred("build")

func owned(node: Node, name: String, parent: Node = null) -> Node:
	if parent == null:
		parent = scene_root
	node.name = name
	parent.add_child(node)
	node.owner = scene_root
	return node

func asset(path: String, name: String, position: Vector3, parent: Node = null) -> Node3D:
	var packed := load("res://Assets/" + path) as PackedScene
	assert(packed != null, path)
	var instance := packed.instantiate() as Node3D
	owned(instance, name, parent)
	instance.position = position
	return instance

func dish(path: String, name: String, fixture: Node3D, slot: String, parent: Node3D) -> void:
	var pose := fixture.find_child(slot, true, false) as Node3D
	assert(pose != null, slot)
	var instance := asset(path, name, Vector3.ZERO, parent)
	instance.global_transform = pose.global_transform

func build() -> void:
	scene_root = Node3D.new()
	scene_root.name = "KitchenDemo"
	root.add_child(scene_root)
	scene_root.set_script(load("res://Scripts/kitchen_viewer.gd"))
	var models := owned(Node3D.new(), "Models") as Node3D
	asset("Scenes/kitchen-room-shell.glb", "RoomShell", Vector3.ZERO, models)
	asset("Kitchen/sink-countertop.glb", "SinkCountertop", Vector3(0, .90, 0), models)
	asset("Kitchen/faucet-pullout.glb", "Faucet", Vector3(.16, .90, -.32), models)
	asset("Tools/soap-dispenser.glb", "SoapDispenser", Vector3(.535, .90, -.26), models)
	asset("Tools/sponge-standard.glb", "Sponge", Vector3(-.30, .9285, -.17), models)
	var rack := asset("Kitchen/dish-rack.glb", "DishRack", Vector3(.88, .90, -.035), models)
	var tray := asset("Kitchen/dirty-tray.glb", "DirtyTray", Vector3(-.89, .90, .025), models)
	asset("Kitchen/order-clipboard.glb", "OrderClipboard", Vector3(1.2205, 1.24, -.398), models)
	var dishes := owned(Node3D.new(), "Dishes") as Node3D
	dish("Dishes/plate-standard.glb", "TrayPlate01", tray, "Dirty_Plate_01", dishes)
	dish("Dishes/plate-standard.glb", "TrayPlate02", tray, "Dirty_Plate_02", dishes)
	dish("Dishes/mug-standard.glb", "TrayMug01", tray, "Dirty_Mug_01", dishes)
	for index in [1, 3, 5]:
		dish("Dishes/plate-standard.glb", "RackPlate%02d" % index, rack, "Rack_Slot_%02d" % index, dishes)
	dish("Dishes/mug-standard.glb", "RackMug01", rack, "Rack_Cup_Slot_01", dishes)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(.40, .57, .69)
	sky_material.sky_horizon_color = Color(.83, .85, .81)
	sky_material.ground_bottom_color = Color(.31, .27, .22)
	sky_material.ground_horizon_color = Color(.66, .68, .61)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.background_energy_multiplier = .6
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = .35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := owned(WorldEnvironment.new(), "WorldEnvironment") as WorldEnvironment
	world.environment = environment
	var sun := owned(DirectionalLight3D.new(), "SoftDaylight") as DirectionalLight3D
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color(1, .97, .90)
	sun.light_energy = .4
	sun.shadow_enabled = true
	sun.shadow_bias = .1
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 8
	var fill := owned(OmniLight3D.new(), "FrontFill") as OmniLight3D
	fill.position = Vector3(-1.0, 2.35, 1.0)
	fill.omni_range = 5
	fill.omni_attenuation = 1.5
	fill.light_color = Color(.88, .93, 1)
	fill.light_energy = .18
	var camera := owned(Camera3D.new(), "ViewCamera") as Camera3D
	camera.position = Vector3(0, 1.62, 1.18)
	camera.look_at(Vector3(0, 1.02, -.03))
	camera.fov = 53.7
	camera.near = .05
	camera.far = 50
	camera.current = true

	var overlay := owned(CanvasLayer.new(), "ViewerOverlay") as CanvasLayer
	var panel := owned(PanelContainer.new(), "Panel", overlay) as PanelContainer
	panel.position = Vector2(22, 20)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.08, .12, .11, .86)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var margin := owned(MarginContainer.new(), "Margin", panel) as MarginContainer
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 14)
	var rows := owned(VBoxContainer.new(), "Rows", margin) as VBoxContainer
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 5)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	for spec in [["ViewName", "操作区  ·  场景预览", 20], ["Controls", "右键拖动环顾  ·  1 操作区  2 全貌  3 待洗区  4 沥水区  ·  R 复位", 16]]:
		var label := owned(Label.new(), spec[0], rows) as Label
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = spec[1]
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", spec[2])
		label.add_theme_color_override("font_color", Color(.93, .92, .84))

	var packed := PackedScene.new()
	assert(packed.pack(scene_root) == OK)
	DirAccess.make_dir_recursive_absolute("res://Scenes")
	assert(ResourceSaver.save(packed, "res://Scenes/kitchen-demo.tscn") == OK)
	print("KITCHEN_SCENE_SAVED 8 fixtures, 5 plates, 2 mugs, camera and lighting")
	quit(0)
