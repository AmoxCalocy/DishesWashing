class_name KitchenSlotRegistry
extends Node3D
## Owns per-scene slot state. This is registration, not placement authorization.

@export var layout: KitchenLayoutConfig
@export var kitchen_path: NodePath
@export var dishes_path: NodePath
@export var temporary_surface_path: NodePath

var slots: Dictionary[StringName, KitchenSlot] = {}

func _ready() -> void:
	var kitchen: Node = get_node(kitchen_path)
	for config in layout.slots:
		assert(not config.slot_id.is_empty() and not slots.has(config.slot_id), "Slot IDs must be unique and nonempty.")
		var fixture: Node = kitchen.get_node(config.fixture_path)
		var marker := fixture.find_child(str(config.slot_id), true, false) as Node3D
		assert(marker != null, "Missing placement marker: " + str(config.slot_id))
		assert(not config.accepted_dish_types.is_empty(), "A slot needs compatible dish types.")
		slots[config.slot_id] = KitchenSlot.new(config, marker)
	var dish_ids: Array[StringName] = []
	for child in get_node(dishes_path).get_children():
		var dish := child as DishBody
		assert(dish != null and not dish_ids.has(dish.instance_id), "Initial dishes need unique identities.")
		dish_ids.append(dish.instance_id)
		assert(slots.has(dish.initial_slot_id), "Initial dish slot is not registered.")
		var slot: KitchenSlot = slots[dish.initial_slot_id]
		assert(slot.is_empty() and slot.accepts(dish.dish_type), "Initial slot must be empty and compatible.")
		slot.state.occupant_id = dish.instance_id
		dish.global_transform = slot.get_pose()

func find_temporary_slot(point: Vector3, collider: Node3D) -> KitchenSlot:
	# Require the real basin surface, not a proxy floating over an obstruction.
	if not get_node(temporary_surface_path).is_ancestor_of(collider):
		return null
	for slot: KitchenSlot in slots.values():
		if slot.config.slot_kind != SlotConfig.Kind.TEMPORARY or not slot.is_empty():
			continue
		var surface := slot.marker.get_node("SelectionSurface") as Node3D
		var offset: Vector3 = point - surface.global_position
		if absf(offset.y) < 0.006 and Vector2(offset.x, offset.z).length() <= 0.06:
			return slot
	return null
