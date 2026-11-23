class_name OrderConfig
extends Resource

@export var order_id: StringName
@export var display_name: String
@export var items: Array[OrderItemConfig] = []
@export var base_reward: int = 0
@export var first_completion_bonus: int = 0
