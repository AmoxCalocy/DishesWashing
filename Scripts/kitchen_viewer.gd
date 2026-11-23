extends Node3D
## Camera-only scene viewer. Dish interaction is implemented separately.

@onready var camera: Camera3D = $ViewCamera
@onready var view_name: Label = $ViewerOverlay/Panel/Margin/Rows/ViewName

var dragging := false
var preset := 1

func _ready() -> void:
	set_view(1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_view(number: int) -> void:
	preset = number
	camera.position = Vector3(0, 1.62, 1.18)
	camera.fov = 53.7
	var target := Vector3(0, 1.02, -.03)
	var title := "操作区"
	match number:
		2:
			camera.position = Vector3(.22, 2.35, 3.50)
			target = Vector3(0, 1.05, 0)
			camera.fov = 31.42
			title = "厨房全貌"
		3:
			target = Vector3(-.89, .96, .025)
			title = "待洗区"
		4:
			target = Vector3(.88, 1.06, .025)
			title = "沥水区"
	camera.look_at(target, Vector3.UP)
	view_name.text = title + "  ·  场景预览"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		dragging = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if dragging else Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and dragging:
		camera.rotation.y = clampf(camera.rotation.y - event.relative.x * .003, deg_to_rad(-60), deg_to_rad(60))
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * .003, deg_to_rad(-60), deg_to_rad(20))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				set_view(event.keycode - KEY_1 + 1)
			KEY_R:
				set_view(1)
			KEY_ESCAPE:
				dragging = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
