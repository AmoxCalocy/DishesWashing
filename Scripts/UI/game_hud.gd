extends CanvasLayer

@export var input_path: NodePath
@export var targeting_path: NodePath
@export var carry_path: NodePath
@export var preview_path: NodePath
@onready var game_input: GameInput = get_node(input_path) as GameInput
@onready var crosshair: Control = $Crosshair
@onready var menu: Control = $Menu
@onready var resume_button: Button = $Menu/Center/Panel/Margin/Rows/Resume
@onready var target_name: Label = $Crosshair/TargetName
@onready var carry: DishCarry = get_node(carry_path) as DishCarry if not carry_path.is_empty() else null
@onready var hand_status: Label = $HandStatus
@onready var hand_hint: Label = $HandHint
@onready var placement_hint: Label = $Crosshair/PlacementHint

func _ready() -> void:
	game_input.mode_changed.connect(_refresh)
	resume_button.pressed.connect(_resume)
	if not targeting_path.is_empty():
		var targeting := get_node(targeting_path) as DishTargeting
		targeting.target_changed.connect(_show_target)
		targeting.slot_changed.connect(_show_slot)
		targeting.tool_changed.connect(_show_tool)
		targeting.placement_surface_changed.connect(_show_surface)
	if carry != null:
		carry.inventory_changed.connect(_refresh_inventory)
		carry.message_requested.connect(_show_message)
	if not preview_path.is_empty():
		(get_node(preview_path) as PlacementPreview).preview_changed.connect(_show_preview)
	_refresh()

func _show_preview(_slot: KitchenSlot, result: PlacementResult) -> void:
	placement_hint.visible = result != null
	if result != null:
		placement_hint.text = result.get_reason()
		placement_hint.modulate = Color(0.45, 1.0, 0.65) if result.is_valid else Color(1.0, 0.6, 0.5)

func _show_surface(active: bool) -> void:
	if active:
		target_name.visible = true
		var dish: DishBody = (get_node(targeting_path) as DishTargeting).current_dish
		target_name.text = dish.display_name + " · 左键叠放 · E 拿取" if dish != null else "水槽 · 自由放置"
	else:
		_show_tool((get_node(targeting_path) as DishTargeting).current_tool)

func _show_target(dish: DishBody) -> void:
	target_name.visible = dish != null
	target_name.text = dish.display_name if dish != null else ""
	if dish != null and carry != null and carry.held_tool() != null:
		target_name.text += " · 按住左键操作" + (" · E 拿取" if carry.free_hand() >= 0 else "")
	elif dish != null and game_input.target == GameInput.Target.STACKABLE_DISH:
		target_name.text += " · 左键叠放 · E 拿取"

func _show_slot(slot: KitchenSlot) -> void:
	if slot != null:
		target_name.visible = true
		target_name.text = slot.config.display_name
	else:
		var targeting := get_node(targeting_path) as DishTargeting
		_show_target(targeting.current_dish)

func _show_tool(tool: CleaningTool) -> void:
	if tool != null:
		target_name.visible = true
		target_name.text = tool.display_name + " · E 归回手中工具" if carry != null and carry.held_tool() != null else "左键 / E 拿取" + tool.display_name
	else:
		var targeting := get_node(targeting_path) as DishTargeting
		_show_target(targeting.current_dish)
		if targeting.current_slot != null:
			_show_slot(targeting.current_slot)

func _show_message(message: String) -> void:
	hand_hint.text = message

func _refresh_inventory() -> void:
	hand_status.visible = carry != null and not game_input.interface_open
	hand_hint.visible = hand_status.visible
	if carry == null:
		return
	var names: Array[String] = []
	for item in carry.hands:
		names.append(str(item.node.get("display_name")) if item != null else "空")
	if carry.selected_dish != null:
		names[carry.selected_dish_hand] += "（当前）"
	hand_status.text = "左手：%s    右手：%s" % names
	if game_input.hand_mode == GameInput.HandMode.CLOSE_UP:
		hand_hint.text = ("左键按住操作喷头" if game_input.selected_tool == ToolState.Tool.SPRAYER else "左键按住并移动擦洗") + " · 中键拖动或 Q / E 左右旋转 · F 返回搬运"
	elif game_input.hand_mode == GameInput.HandMode.TRANSITION:
		hand_hint.text = "正在切换视角"
	elif carry.held_dish != null and carry.held_tool() != null:
		hand_hint.text = "左键放到水槽／架位 · 按住左键操作已放置餐具 · F 沉浸 · E 归回工具"
	elif carry.held_tool() != null:
		hand_hint.text = "按住左键操作餐具 · WASD 移动 / 鼠标瞄准 · E 拿取目标餐具，移开后 E 归回工具"
	elif carry.free_hand() < 0:
		hand_hint.text = "1 选择左手餐具 · 2 选择右手餐具 · 左键放下／叠放 · E 拿取"
	elif carry.selected_dish != null:
		hand_hint.text = "水槽／架位左键放下 · 水槽内餐具左键叠放、E 拿取"
	else:
		hand_hint.text = "瞄准餐具或清洗工具，左键拿取" + (" · E 归回工具" if carry.held_tool() != null else "")

func _refresh() -> void:
	crosshair.visible = not game_input.interface_open and game_input.hand_mode not in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]
	menu.visible = game_input.interface_open
	_refresh_inventory()
	if menu.visible:
		resume_button.grab_focus()
	else:
		resume_button.release_focus()

func _resume() -> void:
	game_input.set_interface_open(false)
