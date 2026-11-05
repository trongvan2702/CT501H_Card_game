extends ItemInstance
class_name FatigueBoss

func _init(i_data: ItemData = null) -> void:
	super(i_data)
	is_boss_modifier = true

func on_stage_start() -> TriggerResult:
	var result = TriggerResult.new(0.0, 0.0, "")
	
	result.custom_effects["add_plays"] = -1
	result.triggered = true
	return result
