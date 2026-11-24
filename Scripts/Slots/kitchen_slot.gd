class_name KitchenSlot
extends RefCounted
## The marker supplies a complete dish-root pose; no extra half-height is added.

var config: SlotConfig
var state: SlotState
var marker: Node3D

func _init(slot_config: SlotConfig, placement_marker: Node3D) -> void:
	config = slot_config
	state = SlotState.new(config)
	marker = placement_marker

func get_pose() -> Transform3D:
	return marker.global_transform

func accepts(dish_type: StringName) -> bool:
	return config.accepted_dish_types.has(dish_type)

func is_empty() -> bool:
	return state.occupant_id.is_empty()
