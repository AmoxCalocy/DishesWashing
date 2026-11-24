extends CanvasLayer

@export var input_path: NodePath
@export var targeting_path: NodePath
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var crosshair: Control = $Crosshair
@onready var menu: Control = $Menu
@onready var resume_button: Button = $Menu/Center/Panel/Margin/Rows/Resume
@onready var target_name: Label = $Crosshair/TargetName

func _ready() -> void:
	game_input.mode_changed.connect(_refresh)
	resume_button.pressed.connect(_resume)
	if not targeting_path.is_empty():
		var targeting := get_node(targeting_path) as DishTargeting
		targeting.target_changed.connect(_show_target)
		targeting.slot_changed.connect(_show_slot)
	_refresh()

func _show_target(dish: DishBody) -> void:
	target_name.visible = dish != null
	target_name.text = dish.display_name if dish != null else ""

func _show_slot(slot: KitchenSlot) -> void:
	if slot != null:
		target_name.visible = true
		target_name.text = slot.config.display_name
	else:
		var targeting := get_node(targeting_path) as DishTargeting
		_show_target(targeting.current_dish)

func _refresh() -> void:
	crosshair.visible = not game_input.interface_open and game_input.hand_mode not in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]
	menu.visible = game_input.interface_open
	if menu.visible:
		resume_button.grab_focus()
	else:
		resume_button.release_focus()

func _resume() -> void:
	game_input.set_interface_open(false)
