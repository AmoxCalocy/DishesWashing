class_name PlacementResult
extends RefCounted
## Read-only query output; a successful check never reserves or places anything.

enum Code { OK, NO_DISH, INPUT_BLOCKED, INVALID_SLOT, INCOMPATIBLE, OCCUPIED, SOURCE_OCCUPIED, TOO_LARGE, OUT_OF_RANGE, NOT_VISIBLE, MISSING_STATE, STATE_MISMATCH, DIRTY, NO_SPACE, INVALID_SURFACE, UNSUPPORTED }

var code: Code
var pose: Transform3D
var dish_id: StringName
var slot_id: StringName
var hand_index: int = -1
var support_dish_ids: Array[StringName] = []
var is_valid: bool:
	get:
		return code == Code.OK

func _init(result_code: Code, target_pose: Transform3D = Transform3D.IDENTITY) -> void:
	code = result_code
	pose = target_pose

func get_reason() -> String:
	match code:
		Code.OK: return "可以叠放" if not support_dish_ids.is_empty() else "可以放置"
		Code.NO_DISH: return "请先选择手中的餐具"
		Code.INPUT_BLOCKED: return "当前状态不能放置"
		Code.INVALID_SLOT: return "目标槽位无效"
		Code.INCOMPATIBLE: return "餐具类型不兼容"
		Code.OCCUPIED: return "目标槽位已被占用"
		Code.SOURCE_OCCUPIED: return "餐具仍占用其他槽位"
		Code.TOO_LARGE: return "餐具尺寸超出槽位范围"
		Code.OUT_OF_RANGE: return "请靠近目标槽位"
		Code.NOT_VISIBLE: return "目标槽位不可见或被遮挡"
		Code.MISSING_STATE: return "无法确认餐具清洁度"
		Code.STATE_MISMATCH: return "餐具清洁状态与实例不匹配"
		Code.DIRTY: return "清洁度须达到实际 95% 才能入架"
		Code.NO_SPACE: return "目标位置空间不足"
		Code.INVALID_SURFACE: return "请瞄准水槽内部"
		Code.UNSUPPORTED: return "底部支撑不足，请选择较平坦的位置"
	return "目标槽位无效"
