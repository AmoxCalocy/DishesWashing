class_name StainRegionConfig
extends Resource
## Shared starting data. Cleaning progress belongs to StainRegionState.

enum Kind { FOOD_RESIDUE, OIL }

@export var region_id: StringName
@export var stain_type: Kind = Kind.FOOD_RESIDUE
@export var initial_amount: float = 1.0
@export var foam_weight: float = 1.0
