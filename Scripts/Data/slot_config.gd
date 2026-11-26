class_name SlotConfig
extends Resource
## slot_id matches the exported placement marker under fixture_path.

enum Kind { DIRTY_TRAY, TEMPORARY, DRAINING_RACK }

@export var slot_id: StringName
@export var display_name: String
@export var slot_kind: Kind = Kind.TEMPORARY
@export var accepted_dish_types: Array[StringName] = []
## Dish-local dimensions, including handles, before the slot rotation.
@export var maximum_dish_size: Vector3 = Vector3.ZERO
@export var fixture_path: NodePath
