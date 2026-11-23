class_name DishState
extends RefCounted

const REQUIRED_CLEANLINESS: float = 0.95

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

## Returns the actual 0..1 value; foam does not count as dirt.
func get_cleanliness() -> float:
	var initial_total: float = 0.0
	var remaining_total: float = 0.0
	for region: StainRegionState in stain_regions.values():
		initial_total += region.initial_amount
		remaining_total += clampf(region.remaining_amount, 0.0, region.initial_amount)
	if initial_total == 0.0:
		return 1.0
	return clampf(1.0 - remaining_total / initial_total, 0.0, 1.0)

## Rounded for display only; never use this integer to authorize placement.
func get_cleanliness_percent() -> int:
	return roundi(get_cleanliness() * 100.0)

## Only the cleanliness requirement, not a complete slot-placement check.
func meets_cleanliness_requirement() -> bool:
	return get_cleanliness() >= REQUIRED_CLEANLINESS
