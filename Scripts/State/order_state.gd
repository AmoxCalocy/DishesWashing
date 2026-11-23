class_name OrderState
extends RefCounted
## Construct a new instance for each order attempt; never mutate the source resources.

var order_id: StringName
var dishes: Dictionary[StringName, DishState] = {}
var slots: Dictionary[StringName, SlotState] = {}
var tools: ToolState

func _init(config: OrderConfig, layout: KitchenLayoutConfig) -> void:
	order_id = config.order_id
	tools = ToolState.new()
	for slot_config in layout.slots:
		assert(not slot_config.slot_id.is_empty(), "Slots need an ID.")
		assert(not slots.has(slot_config.slot_id), "Duplicate slot ID.")
		slots[slot_config.slot_id] = SlotState.new(slot_config)
	for item in config.items:
		assert(not item.instance_id.is_empty(), "Order items need an instance ID.")
		assert(not dishes.has(item.instance_id), "Duplicate dish instance ID.")
		assert(slots.has(item.initial_slot_id), "Initial slot is missing from the layout.")
		var slot: SlotState = slots[item.initial_slot_id]
		assert(slot.occupant_id.is_empty(), "Initial slot is already occupied.")
		var dish := DishState.new(item.instance_id, item.dish, item.initial_slot_id)
		dishes[item.instance_id] = dish
		slot.occupant_id = dish.instance_id
