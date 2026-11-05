extends ItemInstance
class_name ForkItem

func on_stage_start() -> TriggerResult:
	var result = TriggerResult.new(0.0, 0.0, "+1 Lượt Bỏ bài!")
	
	result.custom_effects["add_discards"] = 1
	result.triggered = true
	
	return result
