class_name SlotState
extends RefCounted

var slot_id: StringName
var slot_kind: SlotConfig.Kind
var occupant_id: StringName = &""

func _init(config: SlotConfig) -> void:
	slot_id = config.slot_id
	slot_kind = config.slot_kind
