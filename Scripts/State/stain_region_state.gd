class_name StainRegionState
extends RefCounted

var region_id: StringName
var stain_type: StainRegionConfig.Kind
var initial_amount: float
var remaining_amount: float
var foam_weight: float
var foam_amount: float = 0.0

func _init(config: StainRegionConfig) -> void:
	assert(config.initial_amount >= 0.0, "Initial stain amount must be nonnegative.")
	assert(config.foam_weight >= 0.0, "Foam weight must be nonnegative.")
	region_id = config.region_id
	stain_type = config.stain_type
	initial_amount = config.initial_amount
	remaining_amount = config.initial_amount
	foam_weight = config.foam_weight
