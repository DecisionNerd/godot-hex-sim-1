class_name PlotState
extends RefCounted

var crop_id: String = ""
var growth_days: int = 0
var tended: bool = false


func clear() -> void:
	crop_id = ""
	growth_days = 0
	tended = false


func is_empty() -> bool:
	return crop_id.is_empty()


func is_mature(crop: CropDefinition) -> bool:
	return not is_empty() and growth_days >= crop.grow_days
