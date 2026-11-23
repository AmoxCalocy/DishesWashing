class_name DishState
extends RefCounted

var instance_id: StringName
var dish_type: StringName
var current_slot_id: StringName
var is_held: bool = false
var detergent_applied: bool = false
var stain_regions: Dictionary[StringName, StainRegionState] = {}

func _init(id: StringName, config: DishConfig, slot_id: StringName) -> void:
	instance_id = id
	dish_type = config.dish_type
	current_slot_id = slot_id
	for region_config in config.stain_regions:
		assert(not region_config.region_id.is_empty(), "Stain regions need an ID.")
		assert(not stain_regions.has(region_config.region_id), "Duplicate stain region ID.")
		stain_regions[region_config.region_id] = StainRegionState.new(region_config)
