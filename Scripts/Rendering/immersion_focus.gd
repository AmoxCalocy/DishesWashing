class_name ImmersionFocus
extends CanvasLayer
## Blur the world without feeding held silhouettes into the blur kernel.
## A transparent camera renders the same held nodes, not duplicate dish identities.

const FOREGROUND_LAYER: int = 1 << 19
const LIGHT_LAYER: int = 1 << 18
const BLUR_SHADER: Shader = preload("res://Shaders/immersion_background_blur.gdshader")

@export var input_path: NodePath
@export var carry_path: NodePath
@export var camera_path: NodePath
@export var tools_path: NodePath
@export_range(0.0, 5.0, 0.1) var blur_lod: float = 3.2
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var carry: DishCarry = get_node(carry_path) as DishCarry
@onready var camera: Camera3D = get_node(camera_path) as Camera3D
@onready var tools: Node3D = get_node(tools_path) as Node3D

var background: ColorRect
var foreground: TextureRect
var foreground_viewport: SubViewport
var foreground_camera: Camera3D
var focus_amount: float = 0.0:
	set(value):
		focus_amount = value
		if background != null:
			(background.material as ShaderMaterial).set_shader_parameter(&"focus_amount", value)
var active: bool = false
var _requested: bool = false
var _last_mode: GameInput.HandMode = GameInput.HandMode.EMPTY
var _camera_mask: int
# Untyped keys allow cleanup after a held visual has already been freed.
var _mesh_layers: Dictionary = {}
var _light_layers: Dictionary = {}
var _fade: Tween

func _ready() -> void:
	layer = 1
	background = ColorRect.new()
	background.name = "BackgroundBlur"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = BLUR_SHADER
	material.set_shader_parameter(&"blur_lod", blur_lod)
	background.material = material
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foreground_viewport = SubViewport.new()
	foreground_viewport.name = "SharpViewport"
	foreground_viewport.transparent_bg = true
	foreground_viewport.gui_disable_input = true
	foreground_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(foreground_viewport)
	foreground_viewport.world_3d = camera.get_world_3d()
	foreground_camera = Camera3D.new()
	foreground_camera.name = "SharpCamera"
	foreground_camera.cull_mask = FOREGROUND_LAYER | LIGHT_LAYER
	foreground_viewport.add_child(foreground_camera)
	foreground_camera.current = true
	foreground = TextureRect.new()
	foreground.name = "SharpItems"
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foreground.texture = foreground_viewport.get_texture()
	foreground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var composite := CanvasItemMaterial.new()
	composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	foreground.material = composite
	add_child(foreground)
	foreground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.hide()
	foreground.hide()
	game_input.mode_changed.connect(_on_context_changed)
	carry.inventory_changed.connect(_on_context_changed)
	RenderingServer.frame_pre_draw.connect(_sync_view)
	_on_context_changed()

func _on_context_changed() -> void:
	var mode: GameInput.HandMode = game_input.hand_mode
	var pair: bool = carry.held_dish != null and carry.held_tool() != null
	var requested: bool = _requested
	if mode == GameInput.HandMode.CLOSE_UP:
		requested = pair
	elif mode == GameInput.HandMode.TRANSITION:
		if _last_mode == GameInput.HandMode.CARRYING:
			requested = pair
		elif _last_mode == GameInput.HandMode.CLOSE_UP:
			requested = false
	else:
		requested = false
	_last_mode = mode
	if requested == _requested:
		return
	_requested = requested
	if _fade != null and _fade.is_running():
		_fade.kill()
	if requested and not active:
		_activate()
	_fade = create_tween()
	_fade.tween_property(self, "focus_amount", 1.0 if requested else 0.0, 0.2)
	if not requested:
		_fade.finished.connect(_deactivate)

func _activate() -> void:
	_camera_mask = camera.cull_mask
	# Cameras cull the light instances too, not only their affected meshes.
	for light: Light3D in get_parent().find_children("*", "Light3D", true, false):
		_light_layers[light] = light.layers
		light.layers |= LIGHT_LAYER
	for item: HandItem in carry.hands:
		if item != null:
			for mesh: GeometryInstance3D in item.node.find_children("*", "GeometryInstance3D", true, false):
				_include_mesh(mesh)
	if carry.held_tool().tool_kind == ToolState.Tool.SPRAYER:
		for link: MeshInstance3D in tools.get("hose_links"):
			_include_mesh(link)
	camera.cull_mask = _camera_mask & ~FOREGROUND_LAYER
	active = true
	_sync_view()
	foreground_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	background.show()
	foreground.show()

func _include_mesh(mesh: GeometryInstance3D) -> void:
	_mesh_layers[mesh] = mesh.layers
	mesh.layers = FOREGROUND_LAYER

func _sync_view() -> void:
	if not active:
		return
	var source: Viewport = camera.get_viewport()
	# Window texture.get_size() applies stretch twice in Compatibility; derive
	# render pixels from the logical viewport and its final canvas transform.
	var pixels := Vector2i(source.get_visible_rect().size * source.get_stretch_transform().get_scale())
	foreground_viewport.size = pixels.max(Vector2i.ONE)
	foreground_viewport.msaa_3d = source.msaa_3d
	foreground_camera.global_transform = camera.global_transform
	foreground_camera.projection = camera.projection
	foreground_camera.keep_aspect = camera.keep_aspect
	foreground_camera.fov = camera.fov
	foreground_camera.size = camera.size
	foreground_camera.frustum_offset = camera.frustum_offset
	foreground_camera.h_offset = camera.h_offset
	foreground_camera.v_offset = camera.v_offset
	foreground_camera.near = camera.near
	foreground_camera.far = camera.far

func _deactivate() -> void:
	if not active:
		return
	for mesh in _mesh_layers:
		if is_instance_valid(mesh):
			mesh.layers = _mesh_layers[mesh]
	_mesh_layers.clear()
	for light in _light_layers:
		if is_instance_valid(light):
			light.layers = _light_layers[light]
	_light_layers.clear()
	if is_instance_valid(camera):
		camera.cull_mask = _camera_mask
	active = false
	foreground_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	background.hide()
	foreground.hide()

func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync_view):
		RenderingServer.frame_pre_draw.disconnect(_sync_view)
	_deactivate()
