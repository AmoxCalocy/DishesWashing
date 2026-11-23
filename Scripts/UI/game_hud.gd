extends CanvasLayer

@export var input_path: NodePath
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var crosshair: Control = $Crosshair
@onready var menu: Control = $Menu
@onready var resume_button: Button = $Menu/Center/Panel/Margin/Rows/Resume

func _ready() -> void:
	game_input.mode_changed.connect(_refresh)
	resume_button.pressed.connect(_resume)
	_refresh()

func _refresh() -> void:
	crosshair.visible = not game_input.interface_open and game_input.hand_mode not in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]
	menu.visible = game_input.interface_open
	if menu.visible:
		resume_button.grab_focus()
	else:
		resume_button.release_focus()

func _resume() -> void:
	game_input.set_interface_open(false)
