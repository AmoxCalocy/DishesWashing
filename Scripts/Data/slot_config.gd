class_name SlotConfig
extends Resource
## slot_id matches the exported placement marker under fixture_path.

enum Kind { DIRTY_TRAY, TEMPORARY, DRAINING_RACK }

@export var slot_id: StringName
@export var slot_kind: Kind = Kind.TEMPORARY
@export var accepted_dish_types: Array[StringName] = []
@export var fixture_path: NodePath
